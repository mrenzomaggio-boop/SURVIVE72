import XCTest
@testable import SURVIVE72

/// Persistence, edit, delete, areas and reset tests for SURVIVE MAPS.
/// Each test uses its own throwaway UserDefaults suite.
final class MapsStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "SURVIVE72Tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func makeStore() -> MapsStore {
        MapsStore(defaults: defaults)
    }

    // MARK: Initial state

    func testNewStoreIsEmpty() {
        let store = makeStore()
        XCTAssertEqual(store.data, MapsData())
        XCTAssertTrue(store.places.isEmpty)
        XCTAssertEqual(store.preparedCount, 0)
        XCTAssertTrue(store.areas.allSatisfy { store.status(of: $0) == .notPrepared })
    }

    func testUnreadableSavedDataStartsEmpty() {
        defaults.set(Data("not json".utf8), forKey: MapsStore.storageKey)
        XCTAssertEqual(makeStore().data, MapsData())
    }

    func testInvalidSavedValuesAreDroppedOnLoad() throws {
        let saved = MapsData(
            places: [
                SavedPlace(name: "Ok", latitude: 10, longitude: 20),
                SavedPlace(name: "Bad", latitude: 95, longitude: 20),
                SavedPlace(name: " ", latitude: 0, longitude: 0)
            ],
            preparedAreaIDs: ["area.home", "area.unknown"]
        )
        defaults.set(try JSONEncoder().encode(saved), forKey: MapsStore.storageKey)

        let store = makeStore()
        XCTAssertEqual(store.places.map(\.name), ["Ok"])
        XCTAssertEqual(store.data.preparedAreaIDs, ["area.home"])
    }

    // MARK: Add

    func testAddPlaceIsSavedTrimmedAndReloaded() throws {
        let store = makeStore()
        let place = try XCTUnwrap(store.addPlace(name: "  Shelter ", latitude: 45.4642,
                                                 longitude: 9.19, note: " Near school "))
        XCTAssertEqual(place.name, "Shelter")
        XCTAssertEqual(place.note, "Near school")

        let reopened = makeStore()
        XCTAssertEqual(reopened.places, [place])
    }

    func testAddKeepsInsertionOrder() {
        let store = makeStore()
        store.addPlace(name: "B", latitude: 1, longitude: 1)
        store.addPlace(name: "A", latitude: 2, longitude: 2)
        XCTAssertEqual(makeStore().places.map(\.name), ["B", "A"])
    }

    func testAddRejectsInvalidValues() {
        let store = makeStore()
        XCTAssertNil(store.addPlace(name: "", latitude: 0, longitude: 0))
        XCTAssertNil(store.addPlace(name: "North", latitude: 90.01, longitude: 0))
        XCTAssertNil(store.addPlace(name: "South", latitude: -91, longitude: 0))
        XCTAssertNil(store.addPlace(name: "East", latitude: 0, longitude: 180.5))
        XCTAssertNil(store.addPlace(name: "West", latitude: 0, longitude: -181))
        XCTAssertNil(store.addPlace(name: "NaN", latitude: .nan, longitude: 0))
        XCTAssertTrue(store.places.isEmpty)
        XCTAssertNil(defaults.object(forKey: MapsStore.storageKey))
    }

    func testAddAcceptsRangeLimits() {
        let store = makeStore()
        XCTAssertNotNil(store.addPlace(name: "Corner", latitude: -90, longitude: 180))
        XCTAssertNotNil(store.addPlace(name: "Corner 2", latitude: 90, longitude: -180))
    }

    // MARK: Edit

    func testUpdatePlaceIsSaved() throws {
        let store = makeStore()
        var place = try XCTUnwrap(store.addPlace(name: "Water", latitude: 1, longitude: 2))
        place.name = "Water point"
        place.latitude = -12.5
        place.note = "Spring"
        XCTAssertTrue(store.updatePlace(place))

        let reopened = makeStore()
        XCTAssertEqual(reopened.places.first?.name, "Water point")
        XCTAssertEqual(reopened.places.first?.latitude, -12.5)
        XCTAssertEqual(reopened.places.first?.note, "Spring")
    }

    func testInvalidUpdateIsIgnored() throws {
        let store = makeStore()
        let original = try XCTUnwrap(store.addPlace(name: "Water", latitude: 1, longitude: 2))
        var changed = original
        changed.longitude = 200
        XCTAssertFalse(store.updatePlace(changed))
        changed = original
        changed.name = "   "
        XCTAssertFalse(store.updatePlace(changed))
        XCTAssertEqual(makeStore().places, [original])
    }

    func testUpdateOfUnknownPlaceIsIgnored() {
        let store = makeStore()
        XCTAssertFalse(store.updatePlace(SavedPlace(name: "Ghost", latitude: 0, longitude: 0)))
        XCTAssertTrue(store.places.isEmpty)
    }

    // MARK: Delete

    func testDeletePlaceIsSaved() throws {
        let store = makeStore()
        let a = try XCTUnwrap(store.addPlace(name: "A", latitude: 1, longitude: 1))
        let b = try XCTUnwrap(store.addPlace(name: "B", latitude: 2, longitude: 2))
        store.deletePlace(id: a.id)
        XCTAssertEqual(makeStore().places, [b])
    }

    func testDeleteUnknownIdChangesNothing() throws {
        let store = makeStore()
        let a = try XCTUnwrap(store.addPlace(name: "A", latitude: 1, longitude: 1))
        store.deletePlace(id: UUID())
        XCTAssertEqual(makeStore().places, [a])
    }

    // MARK: Offline areas

    func testPreparedAreasAreSavedAndReloaded() throws {
        let store = makeStore()
        let area = try XCTUnwrap(store.areas.last)
        store.setPrepared(true, for: area)
        XCTAssertEqual(store.status(of: area), .prepared)

        let reopened = makeStore()
        XCTAssertEqual(reopened.status(of: area), .prepared)
        XCTAssertEqual(reopened.preparedCount, 1)

        reopened.setPrepared(false, for: area)
        XCTAssertEqual(makeStore().status(of: area), .notPrepared)
    }

    func testUnknownAreaIsIgnored() {
        let store = makeStore()
        store.setPrepared(true, for: OfflineArea(id: "area.fake", title: "Fake", summary: "", sizeMB: 1))
        XCTAssertEqual(store.preparedCount, 0)
        XCTAssertNil(defaults.object(forKey: MapsStore.storageKey))
    }

    func testAreaCatalogHasUniqueIDsAndLabels() {
        XCTAssertEqual(OfflineAreaCatalog.ids.count, OfflineAreaCatalog.all.count)
        XCTAssertEqual(OfflineAreaStatus.prepared.label, "Prepared")
        XCTAssertEqual(OfflineAreaStatus.notPrepared.label, "Not prepared")
    }

    // MARK: Reset

    func testResetErasesPlacesAndAreas() throws {
        let store = makeStore()
        store.addPlace(name: "A", latitude: 1, longitude: 1)
        store.setPrepared(true, for: try XCTUnwrap(store.areas.first))

        store.reset()
        XCTAssertEqual(store.data, MapsData())
        XCTAssertNil(defaults.object(forKey: MapsStore.storageKey))
        XCTAssertEqual(makeStore().data, MapsData())
    }

    func testLocalDataResetIncludesMaps() {
        XCTAssertTrue(LocalDataReset.storageKeys.contains(MapsStore.storageKey))
    }

    func testSensorPlaceholdersRequirePhysicalDeviceTest() {
        XCTAssertEqual(SensorPlaceholderView.requirement, "REQUIRES PHYSICAL-DEVICE TEST")
    }
}
