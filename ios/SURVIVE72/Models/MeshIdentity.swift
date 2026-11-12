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

    /// Short code derived from the signing key, e.g. "7K4P-2QXM".
    /// Two people compare it to be sure they are talking to each other.
    var code: String { MeshCode.code(for: signingKey) }

    /// True when both keys have the expected size.
    var isWellFormed: Bool {
        signingKey.count == 32 && agreementKey.count == 32
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
    private let signing: Curve25519.Signing.PrivateKey
    private let agreement: Curve25519.KeyAgreement.PrivateKey

    /// Creates a brand new identity with fresh keys.
    init(name: String) {
        self.name = name
        signing = Curve25519.Signing.PrivateKey()
        agreement = Curve25519.KeyAgreement.PrivateKey()
    }

    /// Restores an identity from its saved private keys. Nil if they are damaged.
    init?(name: String, signingKey: Data, agreementKey: Data) {
        guard let signing = try? Curve25519.Signing.PrivateKey(rawRepresentation: signingKey),
              let agreement = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: agreementKey)
        else { return nil }
        self.name = name
        self.signing = signing
        self.agreement = agreement
    }

    /// Private keys, to be stored only in the device Keychain.
    var signingKeyData: Data { signing.rawRepresentation }
    var agreementKeyData: Data { agreement.rawRepresentation }

    var card: MeshCard {
        MeshCard(name: name,
                 signingKey: signing.publicKey.rawRepresentation,
                 agreementKey: agreement.publicKey.rawRepresentation)
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
