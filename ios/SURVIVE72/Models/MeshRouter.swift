import Foundation

/// What happened to a packet handed to the router.
enum MeshReceiveResult: Equatable {
    /// Already seen: ignored, so packets never loop.
    case duplicate
    /// Broken, tampered with, or expired: dropped and never relayed.
    case rejected
    /// Valid, but the sender went over the limits for SOS, alerts or votes:
    /// dropped and never relayed.
    case limited
    /// New and valid. `isForMe` is true for alerts and for private messages
    /// addressed to this phone; `willRelay` is true if it will be passed on.
    case accepted(isForMe: Bool, willRelay: Bool)
}

/// Store-and-forward core of the mesh. It decides what to keep, what to show
/// and what to pass to the next phone. Pure logic: no radio, no clock, no disk.
///
/// How a message travels: every phone keeps the valid packets it has seen and
/// offers them to each phone it meets, until they expire or run out of hops.
/// A private message keeps hopping until it reaches its recipient; relaying
/// phones carry it but cannot read it.
struct MeshRouter {
    /// Most packets kept for relaying. Oldest non-SOS packets are dropped first.
    static let defaultCapacity = 500

    let myCode: String
    let capacity: Int

    /// Valid packets kept on this phone, by id.
    private(set) var packets: [UUID: MeshPacket] = [:]
    /// Ids seen recently, with their expiry, so dropped packets are not accepted again.
    private(set) var seen: [UUID: Date] = [:]

    /// Limits per person, checked by every phone on its own, so a person
    /// cannot flood the network with SOS or alerts.
    /// At most one SOS and one alert per person per day.
    static let limitWindow: TimeInterval = 24 * 60 * 60
    static let votesPerHour = 30

    init(myCode: String, capacity: Int = MeshRouter.defaultCapacity) {
        self.myCode = myCode
        self.capacity = max(1, capacity)
    }

    // MARK: In

    /// A packet written on this phone.
    @discardableResult
    mutating func submit(_ packet: MeshPacket, now: Date) -> MeshReceiveResult {
        receive(packet, now: now)
    }

    /// A packet received from a nearby phone (or written here).
    @discardableResult
    mutating func receive(_ packet: MeshPacket, now: Date) -> MeshReceiveResult {
        prune(now: now)
        if seen[packet.id] != nil { return .duplicate }
        guard packet.isValid(at: now), !packet.isExpired(at: now) else { return .rejected }

        seen[packet.id] = packet.expiresAt
        if exceedsLimit(packet) { return .limited }
        let isForMe = isAddressedToMe(packet)
        // A private message that reached its recipient stops here.
        let willRelay = packet.canRelay(at: now) && !(packet.kind == .direct && isForMe)
        if isForMe || willRelay {
            packets[packet.id] = packet
            enforceCapacity()
        }
        return .accepted(isForMe: isForMe, willRelay: willRelay && packets[packet.id] != nil)
    }

    // MARK: Out

    /// Packets to hand to a phone that already has `known` ids: SOS first, then oldest first.
    /// Each one is the relayed copy, with one more hop.
    func packetsToSend(excluding known: Set<UUID> = [], now: Date) -> [MeshPacket] {
        packets.values
            .filter { !known.contains($0.id) && shouldRelay($0, now: now) }
            .sorted(by: MeshRouter.sendOrder)
            .map { $0.relayed() }
    }

    /// Ids this phone already has, sent to a peer so it does not send them again.
    func knownIDs(now: Date) -> Set<UUID> {
        Set(seen.filter { $0.value > now }.keys)
    }

    // MARK: Read

    /// Alerts for the board: SOS first, then newest first.
    func alerts(now: Date) -> [MeshPacket] {
        packets.values
            .filter { $0.kind == .alert && !$0.isExpired(at: now) }
            .sorted {
                if $0.isSOS != $1.isSOS { return $0.isSOS }
                if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
                return $0.id.uuidString < $1.id.uuidString
            }
    }

    /// Private packets addressed to this phone, oldest first.
    func inbox(now: Date) -> [MeshPacket] {
        packets.values
            .filter { $0.kind == .direct && $0.recipientCode == myCode && !$0.isExpired(at: now) }
            .sorted(by: MeshRouter.sendOrder)
    }

    /// Everyone whose packets reached this phone, by code. Used to pick a recipient.
    var knownCards: [String: MeshCard] {
        var cards: [String: MeshCard] = [:]
        for packet in packets.values.sorted(by: { $0.createdAt < $1.createdAt }) {
            cards[packet.sender.code] = packet.sender
        }
        cards[myCode] = nil
        return cards
    }

    /// People who declared this phone number, oldest identity first.
    /// More than one result means someone may be using a number that is not theirs.
    func cards(forPhone number: String, defaultPrefix: String = MeshPhone.defaultPrefix) -> [MeshCard] {
        guard let tag = MeshPhone.tag(for: number, defaultPrefix: defaultPrefix) else { return [] }
        var firstSeen: [String: MeshPacket] = [:]
        for packet in packets.values where packet.sender.phoneTag == tag && packet.sender.code != myCode {
            let code = packet.sender.code
            if let known = firstSeen[code], known.createdAt <= packet.createdAt { continue }
            firstSeen[code] = packet
        }
        return firstSeen.values
            .sorted {
                if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
                return $0.sender.code < $1.sender.code
            }
            .map { $0.sender }
    }

    /// Votes about one alert: the latest vote of each person, by code.
    func votes(on alertID: UUID, now: Date) -> [String: Bool] {
        var latest: [String: MeshPacket] = [:]
        for packet in packets.values where packet.kind == .vote && !packet.isExpired(at: now) {
            guard let vote = packet.vote, vote.alertID == alertID else { continue }
            let code = packet.sender.code
            if let known = latest[code], known.createdAt >= packet.createdAt { continue }
            latest[code] = packet
        }
        return latest.compactMapValues { $0.vote?.confirms }
    }

    /// True if a new packet like this one from `sender` would go over the limits.
    /// Used before writing one, so the user is told instead of the network dropping it.
    func wouldExceedLimit(kind: MeshPacketKind, isSOS: Bool, sender: String, at date: Date) -> Bool {
        limitHit(kind: kind, isSOS: isSOS, sender: sender, createdAt: date, excluding: nil)
    }

    // MARK: Housekeeping

    /// Forgets every packet from a person. Used when the user hides someone.
    mutating func drop(from code: String) {
        packets = packets.filter { $0.value.sender.code != code }
    }

    /// Marks a packet as seen without keeping it, so it is not taken or offered again.
    mutating func ignore(_ packet: MeshPacket) {
        seen[packet.id] = packet.expiresAt
    }

    /// Forgets expired packets and ids.
    mutating func prune(now: Date) {
        packets = packets.filter { !$0.value.isExpired(at: now) }
        seen = seen.filter { $0.value > now }
    }

    /// Erases everything (used by "erase all local data").
    mutating func reset() {
        packets.removeAll()
        seen.removeAll()
    }

    // MARK: Private

    private func isAddressedToMe(_ packet: MeshPacket) -> Bool {
        switch packet.kind {
        case .alert: true
        case .direct: packet.recipientCode == myCode
        case .vote: true
        }
    }

    private func exceedsLimit(_ packet: MeshPacket) -> Bool {
        guard packet.kind != .direct else { return false }
        return limitHit(kind: packet.kind, isSOS: packet.isSOS, sender: packet.sender.code,
                        createdAt: packet.createdAt, excluding: packet.id)
    }

    /// Limits use the signed creation time, so every phone reaches the same verdict.
    private func limitHit(kind: MeshPacketKind, isSOS: Bool, sender: String, createdAt: Date,
                          excluding id: UUID?) -> Bool {
        let others = packets.values.filter {
            $0.sender.code == sender && $0.kind == kind && $0.id != id
        }
        func within(_ window: TimeInterval) -> [MeshPacket] {
            others.filter { abs($0.createdAt.timeIntervalSince(createdAt)) < window }
        }
        switch kind {
        case .direct:
            return false
        case .alert:
            return within(MeshRouter.limitWindow).contains { $0.isSOS == isSOS }
        case .vote:
            return within(60 * 60).count >= MeshRouter.votesPerHour
        }
    }

    private func shouldRelay(_ packet: MeshPacket, now: Date) -> Bool {
        packet.canRelay(at: now) && !(packet.kind == .direct && packet.recipientCode == myCode)
    }

    private static func sendOrder(_ a: MeshPacket, _ b: MeshPacket) -> Bool {
        if a.isSOS != b.isSOS { return a.isSOS }
        if a.createdAt != b.createdAt { return a.createdAt < b.createdAt }
        return a.id.uuidString < b.id.uuidString
    }

    /// Drops the oldest packets when over capacity: votes first, SOS last.
    private mutating func enforceCapacity() {
        guard packets.count > capacity else { return }
        let dropOrder = packets.values.sorted {
            let aVote = $0.kind == .vote, bVote = $1.kind == .vote
            if aVote != bVote { return aVote }
            if $0.isSOS != $1.isSOS { return !$0.isSOS }
            if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
            return $0.id.uuidString < $1.id.uuidString
        }
        for packet in dropOrder.prefix(packets.count - capacity) {
            packets[packet.id] = nil
        }
    }
}
