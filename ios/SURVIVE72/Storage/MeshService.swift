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

    private let transport: MeshTransport
    private let keyStore: MeshKeyStore
    private let defaults: UserDefaults
    private let stateURL: URL?
    private let now: () -> Date

    init(transport: MeshTransport = MultipeerTransport(),
         keyStore: MeshKeyStore = KeychainMeshKeyStore(),
         defaults: UserDefaults = .standard,
         stateURL: URL? = MeshService.defaultStateURL(),
         now: @escaping () -> Date = Date.init) {
        self.transport = transport
        self.keyStore = keyStore
        self.defaults = defaults
        self.stateURL = stateURL
        self.now = now

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
        profile.phone = MeshPhone.normalized(phone) == nil ? "" : phone.trimmed
        identity.name = profile.name
        identity.phoneTag = MeshPhone.tag(for: profile.phone)
        saveProfile()
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
        }
    }

    /// iOS closes the link while the app is in the background: start it again.
    func appBecameActive() {
        guard profile.isEnabled else { return }
        transport.stop()
        transport.start()
        nearbyCount = transport.connectedPeers.count
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

    /// People who declared this phone number, among everyone seen so far.
    func people(withPhone number: String) -> [MeshCard] {
        guard let tag = MeshPhone.tag(for: number) else { return [] }
        var found = router.cards(forPhone: number)
        let known = Set(found.map(\.code))
        let saved = contacts.values
            .filter { $0.phoneTag == tag && !known.contains($0.code) && $0.code != myCode }
            .sorted { $0.code < $1.code }
        found.append(contentsOf: saved)
        return found
    }

    /// Everyone this phone could write to, by nickname.
    var reachablePeople: [MeshCard] {
        var all = contacts
        for (code, card) in router.knownCards { all[code] = card }
        all[myCode] = nil
        return all.values.sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
                || ($0.name == $1.name && $0.code < $1.code)
        }
    }

    func card(for code: String) -> MeshCard? {
        router.knownCards[code] ?? contacts[code]
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
        let known = Array(router.knownIDs(now: now()))
        if let data = MeshWire.hello(known: known).encoded() {
            transport.send(data, to: peer)
        }
    }

    func meshTransport(peerDisconnected peer: String) {
        nearbyCount = transport.connectedPeers.count
    }

    func meshTransport(didReceive data: Data, from peer: String) {
        guard let message = MeshWire.decoded(data) else { return }
        switch message {
        case .hello(let known):
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
           let identity = MeshIdentity(name: profile.name, phone: phone,
                                       signingKey: keys.signing, agreementKey: keys.agreement) {
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
