import CryptoKit
import Foundation

/// What a mesh packet carries.
enum MeshPacketKind: String, Codable {
    /// Public message for the alert board: readable by every phone it reaches.
    case alert
    /// Private message: relayed by anyone, readable only by the recipient.
    case direct
}

/// One message travelling across the mesh, hop by hop.
///
/// Everything except `hops` is signed by the sender, so a relaying phone
/// cannot change the text, the author, the recipient or the expiry.
struct MeshPacket: Codable, Hashable, Identifiable {
    static let maxTextBytes = 1_000
    static let defaultHopLimit = 8
    /// Alerts and messages stop spreading after this time.
    static let defaultLifetime: TimeInterval = 24 * 60 * 60
    /// Small tolerance for phones whose clocks are not set exactly.
    static let clockTolerance: TimeInterval = 10 * 60

    let id: UUID
    let kind: MeshPacketKind
    let sender: MeshCard
    /// Code of the recipient, only for `.direct`.
    let recipientCode: String?
    let isSOS: Bool
    let createdAt: Date
    let expiresAt: Date
    /// How many times the packet may still be passed on when created.
    let hopLimit: Int
    /// UTF-8 text for `.alert`, encrypted bytes for `.direct`.
    let payload: Data
    let signature: Data
    /// Number of phones that passed the packet on. Not signed: it changes at every hop.
    var hops: Int

    // MARK: Create

    /// A public alert for the board.
    static func alert(_ text: String, isSOS: Bool, from identity: MeshIdentity, now: Date,
                      id: UUID = UUID(), hopLimit: Int = defaultHopLimit,
                      lifetime: TimeInterval = defaultLifetime) throws -> MeshPacket {
        let payload = try checkedText(text)
        return try make(id: id, kind: .alert, identity: identity, recipientCode: nil, isSOS: isSOS,
                        now: now, lifetime: lifetime, hopLimit: hopLimit, payload: payload)
    }

    /// A private message that only `recipient` can read.
    static func direct(_ text: String, to recipient: MeshCard, isSOS: Bool = false,
                       from identity: MeshIdentity, now: Date,
                       id: UUID = UUID(), hopLimit: Int = defaultHopLimit,
                       lifetime: TimeInterval = defaultLifetime) throws -> MeshPacket {
        let plain = try checkedText(text)
        guard let plainText = String(data: plain, encoding: .utf8) else { throw MeshError.unreadable }
        let sealed = try identity.seal(plainText, for: recipient, context: contextData(id))
        return try make(id: id, kind: .direct, identity: identity, recipientCode: recipient.code,
                        isSOS: isSOS, now: now, lifetime: lifetime, hopLimit: hopLimit, payload: sealed)
    }

    private static func checkedText(_ text: String) throws -> Data {
        let cleaned = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { throw MeshError.emptyText }
        let data = Data(cleaned.utf8)
        guard data.count <= maxTextBytes else { throw MeshError.textTooLong }
        return data
    }

    private static func make(id: UUID, kind: MeshPacketKind, identity: MeshIdentity,
                             recipientCode: String?, isSOS: Bool, now: Date,
                             lifetime: TimeInterval, hopLimit: Int, payload: Data) throws -> MeshPacket {
        // Whole seconds, so the signed bytes are identical after a JSON round trip.
        let created = Date(timeIntervalSince1970: now.timeIntervalSince1970.rounded(.down))
        let expires = created.addingTimeInterval(lifetime.rounded(.down))
        let card = identity.card
        let bytes = signedBytes(id: id, kind: kind, sender: card, recipientCode: recipientCode,
                                isSOS: isSOS, createdAt: created, expiresAt: expires,
                                hopLimit: hopLimit, payload: payload)
        return MeshPacket(id: id, kind: kind, sender: card, recipientCode: recipientCode,
                          isSOS: isSOS, createdAt: created, expiresAt: expires, hopLimit: hopLimit,
                          payload: payload, signature: try identity.sign(bytes), hops: 0)
    }

    // MARK: Read

    /// Text of a public alert. Nil for private packets.
    var alertText: String? {
        kind == .alert ? String(data: payload, encoding: .utf8) : nil
    }

    /// Text of a private message, if it was sent to `identity`.
    func directText(for identity: MeshIdentity) -> String? {
        guard kind == .direct, recipientCode == identity.code else { return nil }
        return try? identity.open(payload, from: sender, context: MeshPacket.contextData(id))
    }

    func isExpired(at now: Date) -> Bool { now >= expiresAt }

    /// True while the packet may still be passed to another phone.
    func canRelay(at now: Date) -> Bool { !isExpired(at: now) && hops < hopLimit }

    /// The copy handed to the next phone.
    func relayed() -> MeshPacket {
        var copy = self
        copy.hops += 1
        return copy
    }

    // MARK: Validate

    /// Checks shape, limits and signature. A packet that fails is dropped and never relayed.
    func isValid(at now: Date) -> Bool {
        guard sender.isWellFormed,
              sender.name.utf8.count <= 80,
              payload.count <= MeshPacket.maxTextBytes + 64, !payload.isEmpty,
              (0...MeshPacket.defaultHopLimit * 2).contains(hopLimit),
              (0...hopLimit).contains(hops),
              expiresAt > createdAt,
              expiresAt.timeIntervalSince(createdAt) <= MeshPacket.defaultLifetime * 7,
              createdAt <= now.addingTimeInterval(MeshPacket.clockTolerance)
        else { return false }
        switch kind {
        case .alert:
            guard recipientCode == nil, String(data: payload, encoding: .utf8) != nil else { return false }
        case .direct:
            guard let code = recipientCode, MeshCode.normalized(code) == code else { return false }
        }
        guard let key = try? Curve25519.Signing.PublicKey(rawRepresentation: sender.signingKey) else {
            return false
        }
        return key.isValidSignature(signature, for: MeshPacket.signedBytes(
            id: id, kind: kind, sender: sender, recipientCode: recipientCode, isSOS: isSOS,
            createdAt: createdAt, expiresAt: expiresAt, hopLimit: hopLimit, payload: payload))
    }

    // MARK: Signed bytes

    static func contextData(_ id: UUID) -> Data { Data(id.uuidString.utf8) }

    /// Fixed, length-prefixed layout of every signed field.
    static func signedBytes(id: UUID, kind: MeshPacketKind, sender: MeshCard, recipientCode: String?,
                            isSOS: Bool, createdAt: Date, expiresAt: Date, hopLimit: Int,
                            payload: Data) -> Data {
        var data = Data("survive72.mesh.packet.v1".utf8)
        func append(_ field: Data) {
            var length = UInt32(field.count).bigEndian
            withUnsafeBytes(of: &length) { data.append(contentsOf: $0) }
            data.append(field)
        }
        append(Data(id.uuidString.utf8))
        append(Data(kind.rawValue.utf8))
        append(Data(sender.name.utf8))
        append(sender.signingKey)
        append(sender.agreementKey)
        append(Data((sender.phoneTag ?? "").utf8))
        append(Data((recipientCode ?? "").utf8))
        append(Data([isSOS ? 1 : 0]))
        append(Data(String(Int64(createdAt.timeIntervalSince1970)).utf8))
        append(Data(String(Int64(expiresAt.timeIntervalSince1970)).utf8))
        append(Data(String(hopLimit).utf8))
        append(payload)
        return data
    }
}
