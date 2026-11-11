import Foundation
import Observation

/// Everything SURVIVE MAPS saves, in one value.
struct MapsData: Codable, Equatable {
    var places: [SavedPlace] = []
    var preparedAreaIDs: [String] = []
}

/// SURVIVE MAPS state: saved places and prepared demo areas.
/// Saved as JSON in `UserDefaults` on every change. No MapKit, GPS,
/// network or permissions.
@Observable
final class MapsStore {
    static let storageKey = "survive72.maps.data.v1"

    private(set) var data: MapsData

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = MapsStore.storageKey) {
        self.defaults = defaults
        self.key = key
        if let saved = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(MapsData.self, from: saved) {
            // Drop anything that is no longer valid instead of crashing.
            var cleaned = decoded
            cleaned.places = decoded.places.filter(MapsStore.isValid)
            cleaned.preparedAreaIDs = decoded.preparedAreaIDs.filter { OfflineAreaCatalog.ids.contains($0) }
            data = cleaned
        } else {
            data = MapsData()
        }
    }

    // MARK: Places

    var places: [SavedPlace] { data.places }

    /// Adds a place. Returns nil (and saves nothing) if the name is empty
    /// or a coordinate is out of range.
    @discardableResult
    func addPlace(name: String, latitude: Double, longitude: Double, note: String = "") -> SavedPlace? {
        let place = SavedPlace(name: name.trimmed, latitude: latitude, longitude: longitude, note: note.trimmed)
        guard MapsStore.isValid(place) else { return nil }
        data.places.append(place)
        save()
        return place
    }

    /// Replaces the place with the same id. Returns false if the id is unknown
    /// or the new values are invalid.
    @discardableResult
    func updatePlace(_ place: SavedPlace) -> Bool {
        guard let index = data.places.firstIndex(where: { $0.id == place.id }) else { return false }
        var cleaned = place
        cleaned.name = place.name.trimmed
        cleaned.note = place.note.trimmed
        guard MapsStore.isValid(cleaned) else { return false }
        data.places[index] = cleaned
        save()
        return true
    }

    func deletePlace(id: SavedPlace.ID) {
        let before = data.places.count
        data.places.removeAll { $0.id == id }
        if data.places.count != before { save() }
    }

    static func isValid(_ place: SavedPlace) -> Bool {
        !place.name.trimmed.isEmpty
            && CoordinateValidator.isValidLatitude(place.latitude)
            && CoordinateValidator.isValidLongitude(place.longitude)
    }

    // MARK: Offline areas

    var areas: [OfflineArea] { OfflineAreaCatalog.all }

    func status(of area: OfflineArea) -> OfflineAreaStatus {
        data.preparedAreaIDs.contains(area.id) ? .prepared : .notPrepared
    }

    var preparedCount: Int { data.preparedAreaIDs.count }

    /// Simulated: only records the choice on this device. Unknown areas are ignored.
    func setPrepared(_ prepared: Bool, for area: OfflineArea) {
        guard OfflineAreaCatalog.ids.contains(area.id) else { return }
        var ids = Set(data.preparedAreaIDs)
        if prepared { ids.insert(area.id) } else { ids.remove(area.id) }
        let sorted = ids.sorted()
        guard sorted != data.preparedAreaIDs else { return }
        data.preparedAreaIDs = sorted
        save()
    }

    // MARK: Reset

    /// Erases places and prepared areas from memory and from the device.
    func reset() {
        data = MapsData()
        defaults.removeObject(forKey: key)
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: key)
    }
}
