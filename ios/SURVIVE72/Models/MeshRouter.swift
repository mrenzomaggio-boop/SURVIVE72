import Foundation

/// What happened to a packet handed to the router.
enum MeshReceiveResult: Equatable {
    /// Already seen: ignored, so packets never loop.
    case duplicate
    /// Broken, tampered with, or expired: dropped and never relayed.
    case rejected
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

    // MARK: Housekeeping

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

    /// Drops the oldest packets when over capacity; SOS packets go last.
    private mutating func enforceCapacity() {
        guard packets.count > capacity else { return }
        let dropOrder = packets.values.sorted {
            if $0.isSOS != $1.isSOS { return !$0.isSOS }
            if $0.createdAt != $1.createdAt { return $0.createdAt < $1.createdAt }
            return $0.id.uuidString < $1.id.uuidString
        }
        for packet in dropOrder.prefix(packets.count - capacity) {
            packets[packet.id] = nil
        }
    }
}
