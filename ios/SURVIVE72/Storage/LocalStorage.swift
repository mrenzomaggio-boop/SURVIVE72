import Foundation

/// Reads and writes the app's JSON values in `UserDefaults` without ever
/// silently destroying what the user saved.
///
/// Rule for every persisted model: decode with `init(from:)` written by hand
/// using the tolerant helpers below, so that adding, removing or renaming a
/// field in a later version keeps the rest of the user's data.
enum LocalStorage {
    /// Suffix of the key that keeps saved bytes the app could not read.
    static let unreadableSuffix = ".unreadable"

    /// The saved value, or nil when nothing is saved or it cannot be read.
    ///
    /// Unreadable data is copied to `key + ".unreadable"` before returning nil,
    /// so the next save cannot overwrite the only copy and a later version can
    /// still recover it. An older backup is never replaced.
    static func load<T: Decodable>(_ type: T.Type, key: String, from defaults: UserDefaults) -> T? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            let backupKey = key + unreadableSuffix
            if defaults.object(forKey: backupKey) == nil {
                defaults.set(data, forKey: backupKey)
            }
            return nil
        }
    }

    static func save<T: Encodable>(_ value: T, key: String, to defaults: UserDefaults) {
        guard let encoded = try? JSONEncoder().encode(value) else { return }
        defaults.set(encoded, forKey: key)
    }

    /// Removes a value and any unreadable backup of it (used by the erase actions).
    static func remove(key: String, from defaults: UserDefaults) {
        defaults.removeObject(forKey: key)
        defaults.removeObject(forKey: key + unreadableSuffix)
    }
}

/// Decodes one array element, turning a failure into nil instead of an error.
private struct LossyElement<T: Decodable>: Decodable {
    let value: T?

    init(from decoder: Decoder) throws {
        value = try? T(from: decoder)
    }
}

extension KeyedDecodingContainer {
    /// The value for `key`, or `fallback` when it is missing or unreadable.
    func value<T: Decodable>(_ type: T.Type, forKey key: Key, default fallback: T) -> T {
        (try? decodeIfPresent(T.self, forKey: key)) ?? fallback
    }

    /// An optional value that is nil when missing or unreadable.
    func optionalValue<T: Decodable>(_ type: T.Type, forKey key: Key) -> T? {
        try? decodeIfPresent(T.self, forKey: key)
    }

    /// The readable elements of an array: one damaged element does not lose the others.
    func lossyArray<T: Decodable>(_ type: T.Type, forKey key: Key) -> [T] {
        guard let elements = try? decodeIfPresent([LossyElement<T>].self, forKey: key) else { return [] }
        return elements.compactMap(\.value)
    }
}
