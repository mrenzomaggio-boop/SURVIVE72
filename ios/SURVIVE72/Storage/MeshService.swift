import Foundation
import Observation

/// What the user chose to show on the mesh.
struct MeshProfile: Codable, Equatable {
    /// Nickname shown next to the user's alerts and messages.
    var name: String = ""
    /// Optional phone number other people can use to find this user.
    /// Only its fingerprint is shared (see `MeshPhone`).
    var phone: String = ""
    /// The radio link is off until the user switches it on.
    var isEnabled: Bool = false
    /// Server proof that `phone` was verified by SMS on this phone.
    var phoneProof: MeshPhoneProof?

    init(name: String = "", phone: String = "", isEnabled: Bool = false) {
        self.name = name
        self.phone = phone
        self.isEnabled = isEnabled
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.value(String.self, forKey: .name, default: "")
        phone = c.value(String.self, forKey: .phone, default: "")
        isEnabled = c.value(Bool.self, forKey: .isEnabled, default: false)
        phoneProof = try? c.decodeIfPresent(MeshPhoneProof.self, forKey: .phoneProof)
    }
}

/// A private message written on this phone, kept so the user can read it back
/// (the travelling copy is encrypted for the recipient).
struct MeshSentMessage: Codable, Equatable, Identifiable {
    let id: UUID
    let recipientCode: String
    let text: String
    let createdAt: Date
}

/// One line of a private conversation.
struct MeshChatMessage: Identifiable, Equatable {
    let id: UUID
    let text: String
    let isOutgoing: Bool
    let date: Date
    /// Phones the message passed through before arriving (incoming only).
    let hops: Int
}

/// Everything the mesh keeps on disk, in one file.
struct MeshSavedState: Codable, Equatable {
    var packets: [MeshPacket] = []
    var sent: [MeshSentMessage] = []
    var contacts: [MeshCard] = []

    init(packets: [MeshPacket] = [], sent: [MeshSentMessage] = [], contacts: [MeshCard] = []) {
        self.packets = packets
        self.sent = sent
        self.contacts = contacts
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        packets = c.lossyArray(MeshPacket.self, forKey: .packets)
        sent = c.lossyArray(MeshSentMessage.self, forKey: .sent)
        contacts = c.lossyArray(MeshCard.self, forKey: .contacts)
    }
}

/// The phone-to-phone network of SURVIVE 72.
///
/// It owns the user's identity, the packets kept on this phone and the link
/// to nearby phones. Alerts spread to every phone that can be reached, hop by
/// hop; private messages travel the same way but only the recipient can read
/// them. No internet and no server are involved.
@Observable
final class MeshService: MeshTransportDelegate {
    static let profileKey = "survive72.mesh.profile.v1"
    static let stateFileName = "mesh-state.v1.json"

    private(set) var profile: MeshProfile
    private(set) var identity: MeshIdentity
    private(set) var router: MeshRouter
    private(set) var sent: [MeshSentMessage]
    /// People this phone has written to or heard from, by code.
    private(set) var contacts: [String: MeshCard]
    /// Phones connected right now.
    private(set) var nearbyCount = 0
    /// Who is on each connected phone (from its signed hello), by peer token.
    private(set) var nearbyCodes: [String: String] = [:]

    private let transport: MeshTransport
    private let keyStore: MeshKeyStore
    private let defaults: UserDefaults
    private let stateURL: URL?
    private let now: () -> Date
    /// Key that signs verified phone numbers (see `MeshPhoneProof`).
    let phoneServerKey: Data?

    init(transport: MeshTransport = MultipeerTransport(),
         keyStore: MeshKeyStore = KeychainMeshKeyStore(),
         defaults: UserDefaults = .standard,
         stateURL: URL? = MeshService.defaultStateURL(),
         now: @escaping () -> Date = Date.init,
         phoneServerKey: Data? = MeshPhoneProof.serverKey) {
        self.transport = transport
        self.keyStore = keyStore
        self.defaults = defaults
        self.stateURL = stateURL
        self.now = now
        self.phoneServerKey = phoneServerKey

        let profile = LocalStorage.load(MeshProfile.self, key: MeshService.profileKey, from: defaults)
            ?? MeshProfile()
        self.profile = profile
        let identity = MeshService.loadOrCreateIdentity(profile: profile, keyStore: keyStore)
        self.identity = identity

        let saved = MeshService.loadState(from: stateURL)
        var router = MeshRouter(myCode: identity.code)
        let current = now()
        for packet in saved.packets { router.receive(packet, now: current) }
        self.router = router
        sent = saved.sent
        var contacts: [String: MeshCard] = [:]
        for card in saved.contacts where card.isWellFormed { contacts[card.code] = card }
        self.contacts = contacts

        transport.delegate = self
        if profile.isEnabled { transport.start() }
    }

    static func defaultStateURL() -> URL? {
        guard let folder = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        else { return nil }
        return folder.appendingPathComponent(stateFileName)
    }

    // MARK: Profile and link

    var isEnabled: Bool { profile.isEnabled }
    var myCode: String { identity.code }

    /// Saves nickname and phone number. The keys, and so the code, stay the same.
    func updateProfile(name: String, phone: String) {
        profile.name = String(name.trimmed.prefix(40))
        let newPhone = MeshPhone.normalized(phone) == nil ? "" : phone.trimmed
        if MeshPhone.tag(for: newPhone) != MeshPhone.tag(for: profile.phone) {
            // Another number must be verified again.
            profile.phoneProof = nil
            identity.phoneProof = nil
        }
        profile.phone = newPhone
        identity.name = profile.name
        identity.phoneTag = MeshPhone.tag(for: profile.phone)
        saveProfile()
        // Nearby phones learn the new nickname at once.
        for peer in transport.connectedPeers { sendHello(to: peer) }
    }

    /// True when the number in the profile was verified by SMS and the proof is still valid.
    var isPhoneVerified: Bool {
        identity.card.hasVerifiedPhone(now: now(), serverKey: phoneServerKey)
    }

    /// Stores the server's proof for the number in the profile. Returns false
    /// (and keeps nothing) if the proof is not for this number and this phone.
    @discardableResult
    func applyPhoneProof(_ proof: MeshPhoneProof) -> Bool {
        guard let tag = MeshPhone.tag(for: profile.phone), proof.phoneTag == tag,
              proof.isValid(for: identity.card.signingKey, now: now(), serverKey: phoneServerKey)
        else { return false }
        profile.phoneProof = proof
        identity.phoneProof = proof
        saveProfile()
        for peer in transport.connectedPeers { sendHello(to: peer) }
        return true
    }

    /// Switches the link to nearby phones on or off.
    func setEnabled(_ enabled: Bool) {
        guard enabled != profile.isEnabled else { return }
        profile.isEnabled = enabled
        saveProfile()
        if enabled {
            transport.start()
        } else {
            transport.stop()
            nearbyCount = 0
            nearbyCodes = [:]
        }
    }

    /// iOS closes the link while the app is in the background: start it again.
    func appBecameActive() {
        guard profile.isEnabled else { return }
        transport.stop()
        transport.start()
        nearbyCount = transport.connectedPeers.count
        nearbyCodes = nearbyCodes.filter { transport.connectedPeers.contains($0.key) }
    }

    // MARK: Write

    /// Publishes a public alert on the board of every phone that can be reached.
    @discardableResult
    func postAlert(_ text: String, isSOS: Bool) throws -> MeshPacket {
        let packet = try MeshPacket.alert(text, isSOS: isSOS, from: identity, now: now())
        accept(packet, from: nil)
        return packet
    }

    /// Sends a private message. It is relayed by other phones until it reaches
    /// the recipient; nobody else can read it.
    @discardableResult
    func send(_ text: String, to recipient: MeshCard) throws -> MeshPacket {
        let packet = try MeshPacket.direct(text, to: recipient, from: identity, now: now())
        contacts[recipient.code] = recipient
        sent.append(MeshSentMessage(id: packet.id, recipientCode: recipient.code,
                                    text: text.trimmed, createdAt: packet.createdAt))
        accept(packet, from: nil)
        return packet
    }

    // MARK: Read

    /// The alert board: SOS first, then newest first.
    var alerts: [MeshPacket] { router.alerts(now: now()) }

    /// People who verified this phone number by SMS, among everyone seen so far.
    /// A number that was only typed in, not verified, finds nobody.
    func people(withPhone number: String) -> [MeshCard] {
        guard let tag = MeshPhone.tag(for: number) else { return [] }
        let current = now()
        var byCode: [String: MeshCard] = [:]
        let candidates = router.cards(forPhone: number) + contacts.values.filter { $0.phoneTag == tag }
        for card in candidates where card.code != myCode
            && card.hasVerifiedPhone(now: current, serverKey: phoneServerKey) {
            byCode[card.code] = card
        }
        return byCode.values.sorted { $0.code < $1.code }
    }

    /// People whose nickname contains the text (ignoring case and accents)
    /// and, when the text is a phone number, people who declared that number.
    func people(matching text: String) -> [MeshCard] {
        let query = text.trimmed
        guard !query.isEmpty else { return [] }
        var found = MeshPhone.normalized(query) == nil || query.contains(where: \.isLetter)
            ? [] : people(withPhone: query)
        let codes = Set(found.map(\.code))
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        found += reachablePeople.filter {
            !codes.contains($0.code) && $0.name.range(of: query, options: options) != nil
        }
        return found
    }

    /// Codes of the people on the phones connected right now.
    var nearbyPeopleCodes: Set<String> { Set(nearbyCodes.values) }

    /// Everyone this phone could write to: people next to it first, then by nickname.
    var reachablePeople: [MeshCard] {
        var all = router.knownCards
        // A card received directly is the newest one (e.g. after a nickname change).
        for (code, card) in contacts { all[code] = card }
        all[myCode] = nil
        let nearby = nearbyPeopleCodes
        return all.values.sorted {
            let aNear = nearby.contains($0.code), bNear = nearby.contains($1.code)
            if aNear != bNear { return aNear }
            let order = $0.name.localizedCaseInsensitiveCompare($1.name)
            return order != .orderedSame ? order == .orderedAscending : $0.code < $1.code
        }
    }

    func card(for code: String) -> MeshCard? {
        contacts[code] ?? router.knownCards[code]
    }

    /// Codes of the people with a private conversation, most recent first.
    var conversationCodes: [String] {
        var latest: [String: Date] = [:]
        for message in sent {
            latest[message.recipientCode] = max(latest[message.recipientCode] ?? .distantPast, message.createdAt)
        }
        for packet in router.inbox(now: now()) {
            let code = packet.sender.code
            latest[code] = max(latest[code] ?? .distantPast, packet.createdAt)
        }
        return latest.sorted { $0.value != $1.value ? $0.value > $1.value : $0.key < $1.key }.map { $0.key }
    }

    /// The private conversation with one person, oldest first.
    func messages(with code: String) -> [MeshChatMessage] {
        var result = sent.filter { $0.recipientCode == code }.map {
            MeshChatMessage(id: $0.id, text: $0.text, isOutgoing: true, date: $0.createdAt, hops: 0)
        }
        for packet in router.inbox(now: now()) where packet.sender.code == code {
            guard let text = packet.directText(for: identity) else { continue }
            result.append(MeshChatMessage(id: packet.id, text: text, isOutgoing: false,
                                          date: packet.createdAt, hops: packet.hops))
        }
        return result.sorted { $0.date != $1.date ? $0.date < $1.date : $0.id.uuidString < $1.id.uuidString }
    }

    // MARK: Reset

    /// Erases identity, keys, messages and contacts, and switches the link off.
    func reset() {
        transport.stop()
        nearbyCount = 0
        nearbyCodes = [:]
        keyStore.delete()
        LocalStorage.remove(key: MeshService.profileKey, from: defaults)
        if let stateURL { try? FileManager.default.removeItem(at: stateURL) }
        profile = MeshProfile()
        identity = MeshService.loadOrCreateIdentity(profile: profile, keyStore: keyStore)
        router = MeshRouter(myCode: identity.code)
        sent = []
        contacts = [:]
    }

    // MARK: Transport events

    func meshTransport(peerConnected peer: String) {
        nearbyCount = transport.connectedPeers.count
        sendHello(to: peer)
    }

    func meshTransport(peerDisconnected peer: String) {
        nearbyCount = transport.connectedPeers.count
        nearbyCodes[peer] = nil
    }

    func meshTransport(didReceive data: Data, from peer: String) {
        guard let message = MeshWire.decoded(data) else { return }
        switch message {
        case .hello(let known, let card, let signature):
            if let card, let signature, card.isSigned(by: signature), card.code != myCode {
                nearbyCodes[peer] = card.code
                if contacts[card.code] != card {
                    contacts[card.code] = card
                    saveState()
                }
            }
            let missing = router.packetsToSend(excluding: Set(known), now: now())
            for batch in MeshWire.batches(missing) {
                if let data = batch.encoded() { transport.send(data, to: peer) }
            }
        case .packets(let packets):
            for packet in packets.prefix(MeshWire.batchSize * 2) {
                accept(packet, from: peer)
            }
        }
    }

    // MARK: Private

    private func sendHello(to peer: String) {
        let card = identity.card
        let known = Array(router.knownIDs(now: now()))
        let hello = MeshWire.hello(known: known, card: card, signature: try? identity.sign(card.signedBytes))
        if let data = hello.encoded() {
            transport.send(data, to: peer)
        }
    }

    /// Stores a new packet and passes it on to every other connected phone.
    private func accept(_ packet: MeshPacket, from source: String?) {
        let current = now()
        guard case .accepted(_, let willRelay) = router.receive(packet, now: current) else { return }
        if packet.sender.code != myCode {
            contacts[packet.sender.code] = packet.sender
        }
        saveState()
        guard willRelay, let data = MeshWire.packets([packet.relayed()]).encoded() else { return }
        for peer in transport.connectedPeers where peer != source {
            transport.send(data, to: peer)
        }
    }

    private static func loadOrCreateIdentity(profile: MeshProfile, keyStore: MeshKeyStore) -> MeshIdentity {
        let phone = profile.phone.isEmpty ? nil : profile.phone
        if let keys = keyStore.load(),
           var identity = MeshIdentity(name: profile.name, phone: phone,
                                       signingKey: keys.signing, agreementKey: keys.agreement) {
            identity.phoneProof = profile.phoneProof
            return identity
        }
        let identity = MeshIdentity(name: profile.name, phone: phone)
        keyStore.save(MeshKeys(signing: identity.signingKeyData, agreement: identity.agreementKeyData))
        return identity
    }

    private static func loadState(from url: URL?) -> MeshSavedState {
        guard let url, let data = try? Data(contentsOf: url),
              let state = try? JSONDecoder().decode(MeshSavedState.self, from: data)
        else { return MeshSavedState() }
        return state
    }

    private func saveProfile() {
        LocalStorage.save(profile, key: MeshService.profileKey, to: defaults)
    }

    private func saveState() {
        guard let stateURL else { return }
        let state = MeshSavedState(packets: Array(router.packets.values), sent: sent,
                                   contacts: Array(contacts.values))
        guard let data = try? JSONEncoder().encode(state) else { return }
        try? data.write(to: stateURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
