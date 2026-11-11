import Foundation
import Observation

/// The only things SURVIVE MEDICAL saves: local preferences.
struct MedicalPreferences: Codable, Equatable {
    var favoriteIDs: [String] = []
    var lastCategory: String?
}

/// SURVIVE MEDICAL preferences: bookmarked entries and last selected category.
/// Saved as JSON in `UserDefaults` on every change. No network, location or
/// permissions; no health data is stored.
@Observable
final class MedicalStore {
    static let storageKey = "survive72.medical.preferences.v1"

    private(set) var preferences: MedicalPreferences

    private let defaults: UserDefaults
    private let key: String
    private let validIDs: Set<String>

    init(
        defaults: UserDefaults = .standard,
        key: String = MedicalStore.storageKey,
        validIDs: Set<String> = MedicalLibraryContent.ids
    ) {
        self.defaults = defaults
        self.key = key
        self.validIDs = validIDs
        if let saved = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(MedicalPreferences.self, from: saved) {
            // Drop anything that is no longer valid instead of crashing.
            var cleaned = MedicalPreferences()
            var seen = Set<String>()
            cleaned.favoriteIDs = decoded.favoriteIDs.filter { validIDs.contains($0) && seen.insert($0).inserted }
            if let raw = decoded.lastCategory, MedicalCategory(rawValue: raw) != nil {
                cleaned.lastCategory = raw
            }
            preferences = cleaned
        } else {
            preferences = MedicalPreferences()
        }
    }

    // MARK: Favorites

    var favoriteIDs: [String] { preferences.favoriteIDs }

    func isFavorite(_ id: MedicalEntry.ID) -> Bool {
        preferences.favoriteIDs.contains(id)
    }

    /// Bookmarks or removes the bookmark of an entry. Unknown ids are ignored.
    func setFavorite(_ favorite: Bool, for id: MedicalEntry.ID) {
        guard validIDs.contains(id), favorite != isFavorite(id) else { return }
        if favorite {
            preferences.favoriteIDs.append(id)
        } else {
            preferences.favoriteIDs.removeAll { $0 == id }
        }
        save()
    }

    func toggleFavorite(_ id: MedicalEntry.ID) {
        setFavorite(!isFavorite(id), for: id)
    }

    // MARK: Category

    /// Last category chosen in the list (nil = All).
    var lastCategory: MedicalCategory? {
        preferences.lastCategory.flatMap(MedicalCategory.init(rawValue:))
    }

    func setLastCategory(_ category: MedicalCategory?) {
        guard category?.rawValue != preferences.lastCategory else { return }
        preferences.lastCategory = category?.rawValue
        save()
    }

    // MARK: Reset

    /// Erases the Medical preferences from memory and from the device.
    func reset() {
        preferences = MedicalPreferences()
        defaults.removeObject(forKey: key)
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(preferences) else { return }
        defaults.set(encoded, forKey: key)
    }
}
