import CryptoKit
import Foundation

/// The public part of a mesh identity: what other phones learn about a user.
/// It carries no phone number, no location and no account.
struct MeshCard: Codable, Hashable {
    /// Name chosen by the user. It is not unique and not verified.
    var name: String
    /// Public key used to check that a packet really comes from this identity.
    let signingKey: Data
    /// Public key used to encrypt private messages for this identity.
    let agreementKey: Data
    /// Fingerprint of the user's phone number, if they chose to be findable by
    /// it. The number itself never travels. It is declared, not verified.
    var phoneTag: String? = nil
    /// Proof from the SURVIVE 72 server that the owner received an SMS on
    /// that number. Only cards with a valid proof can be found by number.
    var phoneProof: MeshPhoneProof? = nil

    /// Short code derived from the signing key, e.g. "7K4P-2QXM".
    /// Two people compare it to be sure they are talking to each other.
    var code: String { MeshCode.code(for: signingKey) }

    /// True when both keys have the expected size.
    var isWellFormed: Bool {
        signingKey.count == 32 && agreementKey.count == 32
            && (phoneTag.map(MeshPhone.isWellFormedTag) ?? true)
    }
}

extension MeshCard {
    /// Bytes signed by the owner when the card is handed to a nearby phone.
    var signedBytes: Data {
        var data = Data("survive72.mesh.card.v1".utf8)
        data.append(Data(name.utf8))
        data.append(0)
        data.append(signingKey)
        data.append(agreementKey)
        data.append(Data((phoneTag ?? "").utf8))
        return data
    }

    /// True when `signature` was made by the owner of this card's signing key,
    /// so nobody can hand out a card with someone else's code.
    func isSigned(by signature: Data) -> Bool {
        guard isWellFormed,
              let key = try? Curve25519.Signing.PublicKey(rawRepresentation: signingKey) else { return false }
        return key.isValidSignature(signature, for: signedBytes)
    }
}

extension MeshCard {
    /// True when the phone number on this card was verified by SMS: the
    /// server signed this number together with this card's key.
    func hasVerifiedPhone(now: Date, serverKey: Data? = MeshPhoneProof.serverKey) -> Bool {
        guard let phoneTag, let phoneProof, phoneProof.phoneTag == phoneTag else { return false }
        return phoneProof.isValid(for: signingKey, now: now, serverKey: serverKey)
    }
}

/// "The owner of this mesh key received an SMS on this number", signed once
/// by the SURVIVE 72 server when the number is verified. Any phone can check
/// it without internet, with the server's public key built into the app.
struct MeshPhoneProof: Codable, Hashable {
    /// Fingerprint of the verified number (see `MeshPhone.tag`).
    let phoneTag: String
    /// Seconds since 1970 when the server signed it.
    let issuedAt: Int64
    /// Ed25519 signature by the server over `signedBytes`.
    let signature: Data

    /// A verification is valid for one year, then the number must be verified again.
    static let lifetime: TimeInterval = 365 * 24 * 60 * 60

    /// Public key of the server that signs verified numbers. Nil until the
    /// server is online: until then nobody can be found by number.
    static let serverKey: Data? = nil

    /// Fixed, length-prefixed layout, the same one the server signs.
    static func signedBytes(phoneTag: String, signingKey: Data, issuedAt: Int64) -> Data {
        var data = Data("survive72.mesh.phone-proof.v1".utf8)
        func append(_ field: Data) {
            var length = UInt32(field.count).bigEndian
            withUnsafeBytes(of: &length) { data.append(contentsOf: $0) }
            data.append(field)
        }
        append(Data(phoneTag.utf8))
        append(signingKey)
        append(Data(String(issuedAt).utf8))
        return data
    }

    func isValid(for signingKey: Data, now: Date, serverKey: Data?) -> Bool {
        guard let serverKey, MeshPhone.isWellFormedTag(phoneTag),
              let key = try? Curve25519.Signing.PublicKey(rawRepresentation: serverKey) else { return false }
        let issued = Date(timeIntervalSince1970: TimeInterval(issuedAt))
        guard issued <= now.addingTimeInterval(MeshPacket.clockTolerance),
              now.timeIntervalSince(issued) <= MeshPhoneProof.lifetime else { return false }
        return key.isValidSignature(signature, for: MeshPhoneProof.signedBytes(
            phoneTag: phoneTag, signingKey: signingKey, issuedAt: issuedAt))
    }
}

/// Phone numbers as a way to find people on the mesh.
///
/// Only a fingerprint of the number is shared, so someone who already knows a
/// number can find its owner, while the number is not shown to everyone else.
/// The fingerprint slows down casual lookups; it is not strong secrecy, because
/// phone numbers can be guessed one by one.
enum MeshPhone {
    /// Country prefix used when a number is typed without one.
    static let defaultPrefix = "+39"

    /// International form with digits only after "+", e.g. "+393331234567".
    /// Nil if the text cannot be a phone number.
    static func normalized(_ text: String, defaultPrefix: String = MeshPhone.defaultPrefix) -> String? {
        var cleaned = String(text.filter { $0.isASCII && ($0.isNumber || $0 == "+") })
        if cleaned.hasPrefix("00") { cleaned = "+" + cleaned.dropFirst(2) }
        if !cleaned.hasPrefix("+") { cleaned = defaultPrefix + cleaned }
        let digits = cleaned.dropFirst()
        guard !digits.contains("+"), (8...15).contains(digits.count) else { return nil }
        return cleaned
    }

    /// Fingerprint shared on the mesh for a phone number. Nil for an invalid number.
    static func tag(for text: String, defaultPrefix: String = MeshPhone.defaultPrefix) -> String? {
        guard let number = normalized(text, defaultPrefix: defaultPrefix) else { return nil }
        let digest = SHA256.hash(data: Data(("survive72.mesh.phone.v1:" + number).utf8))
        return digest.prefix(16).map { String(format: "%02x", $0) }.joined()
    }

    static func isWellFormedTag(_ tag: String) -> Bool {
        let hex = Set("0123456789abcdef")
        return tag.count == 32 && tag.allSatisfy { hex.contains($0) }
    }
}

/// Human-readable code for a public key: 8 characters, no look-alike letters.
enum MeshCode {
    private static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")

    static func code(for publicKey: Data) -> String {
        let digest = Array(SHA256.hash(data: publicKey))
        // 40 bits -> 8 characters of 5 bits each.
        var value: UInt64 = 0
        for byte in digest.prefix(5) { value = (value << 8) | UInt64(byte) }
        var characters: [Character] = []
        for index in (0..<8).reversed() {
            characters.append(alphabet[Int((value >> UInt64(index * 5)) & 0x1F)])
        }
        return String(characters.prefix(4)) + "-" + String(characters.suffix(4))
    }

    /// Canonical form of a typed code: upper case, look-alikes mapped, dash added.
    static func normalized(_ text: String) -> String? {
        let mapped = text.uppercased().compactMap { character -> Character? in
            switch character {
            case "O": return "0"
            case "I", "L": return "1"
            case "U": return "V"
            case "-", " ": return nil
            default: return character
            }
        }
        guard mapped.count == 8, mapped.allSatisfy({ alphabet.contains($0) }) else { return nil }
        return String(mapped.prefix(4)) + "-" + String(mapped.suffix(4))
    }
}

/// A user's mesh identity: the private keys never leave the device.
struct MeshIdentity {
    var name: String
    /// Set when the user chooses to be findable by phone number.
    var phoneTag: String?
    /// Set once the number has been verified by SMS.
    var phoneProof: MeshPhoneProof?
    private let signing: Curve25519.Signing.PrivateKey
    private let agreement: Curve25519.KeyAgreement.PrivateKey

    /// Creates a brand new identity with fresh keys.
    init(name: String, phone: String? = nil) {
        self.name = name
        phoneTag = phone.flatMap { MeshPhone.tag(for: $0) }
        signing = Curve25519.Signing.PrivateKey()
        agreement = Curve25519.KeyAgreement.PrivateKey()
    }

    /// Restores an identity from its saved private keys. Nil if they are damaged.
    init?(name: String, phone: String? = nil, signingKey: Data, agreementKey: Data) {
        guard let signing = try? Curve25519.Signing.PrivateKey(rawRepresentation: signingKey),
              let agreement = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: agreementKey)
        else { return nil }
        self.name = name
        phoneTag = phone.flatMap { MeshPhone.tag(for: $0) }
        self.signing = signing
        self.agreement = agreement
    }

    /// Private keys, to be stored only in the device Keychain.
    var signingKeyData: Data { signing.rawRepresentation }
    var agreementKeyData: Data { agreement.rawRepresentation }

    var card: MeshCard {
        MeshCard(name: name,
                 signingKey: signing.publicKey.rawRepresentation,
                 agreementKey: agreement.publicKey.rawRepresentation,
                 phoneTag: phoneTag,
                 phoneProof: phoneProof?.phoneTag == phoneTag ? phoneProof : nil)
    }

    var code: String { card.code }

    func sign(_ data: Data) throws -> Data {
        try signing.signature(for: data)
    }

    // MARK: Private messages

    /// Encrypts `text` so that only `recipient` can read it. `context` (the
    /// packet id) is bound to the message so it cannot be moved to another packet.
    func seal(_ text: String, for recipient: MeshCard, context: Data) throws -> Data {
        let key = try sharedKey(with: recipient.agreementKey, context: context)
        return try ChaChaPoly.seal(Data(text.utf8), using: key, authenticating: context).combined
    }

    /// Decrypts a private message sent by `sender` to this identity.
    func open(_ sealed: Data, from sender: MeshCard, context: Data) throws -> String {
        let key = try sharedKey(with: sender.agreementKey, context: context)
        let box = try ChaChaPoly.SealedBox(combined: sealed)
        let plain = try ChaChaPoly.open(box, using: key, authenticating: context)
        guard let text = String(data: plain, encoding: .utf8) else { throw MeshError.unreadable }
        return text
    }

    private func sharedKey(with publicKey: Data, context: Data) throws -> SymmetricKey {
        let peer = try Curve25519.KeyAgreement.PublicKey(rawRepresentation: publicKey)
        let secret = try agreement.sharedSecretFromKeyAgreement(with: peer)
        return secret.hkdfDerivedSymmetricKey(
            using: SHA256.self, salt: context,
            sharedInfo: Data("survive72.mesh.direct.v1".utf8), outputByteCount: 32)
    }
}

enum MeshError: Error, Equatable {
    case unreadable
    case emptyText
    case textTooLong
}
