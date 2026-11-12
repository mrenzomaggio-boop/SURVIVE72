import Foundation
import Security

/// The two private keys of a mesh identity.
struct MeshKeys: Equatable {
    let signing: Data
    let agreement: Data
}

/// Where the private keys live. A protocol so tests never touch the Keychain.
protocol MeshKeyStore {
    func load() -> MeshKeys?
    func save(_ keys: MeshKeys)
    func delete()
}

/// Keeps the keys in the device Keychain: they are not included in readable
/// backups and never leave this device.
struct KeychainMeshKeyStore: MeshKeyStore {
    private let service = "com.survive72.app.mesh"
    private let account = "identity.v1"

    private var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    func load() -> MeshKeys? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var item: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &item) == errSecSuccess,
              let data = item as? Data, data.count == 64 else { return nil }
        return MeshKeys(signing: Data(data.prefix(32)), agreement: Data(data.suffix(32)))
    }

    func save(_ keys: MeshKeys) {
        guard keys.signing.count == 32, keys.agreement.count == 32 else { return }
        delete()
        var query = baseQuery
        query[kSecValueData as String] = keys.signing + keys.agreement
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(query as CFDictionary, nil)
    }

    func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }
}

/// Keys kept only in memory (tests and previews).
final class InMemoryMeshKeyStore: MeshKeyStore {
    private var keys: MeshKeys?

    func load() -> MeshKeys? { keys }
    func save(_ keys: MeshKeys) { self.keys = keys }
    func delete() { keys = nil }
}
