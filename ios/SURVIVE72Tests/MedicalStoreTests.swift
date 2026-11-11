import XCTest
@testable import SURVIVE72

/// Preferences persistence and reset tests for SURVIVE MEDICAL.
/// Each test uses its own throwaway UserDefaults suite.
final class MedicalStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    private let burns = "medical.injuries.burns"
    private let hydration = "medical.illness.hydration"

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

    private func makeStore() -> MedicalStore {
        MedicalStore(defaults: defaults)
    }

    func testNewStoreIsEmpty() {
        let store = makeStore()
        XCTAssertEqual(store.preferences, MedicalPreferences())
        XCTAssertTrue(store.favoriteIDs.isEmpty)
        XCTAssertNil(store.lastCategory)
        XCTAssertNil(defaults.object(forKey: MedicalStore.storageKey))
    }

    func testStorageKey() {
        XCTAssertEqual(MedicalStore.storageKey, "survive72.medical.preferences.v1")
    }

    func testFavoritesAndCategoryPersistAcrossInstances() {
        let store = makeStore()
        store.toggleFavorite(burns)
        store.setFavorite(true, for: hydration)
        store.setLastCategory(.injuries)

        let reopened = makeStore()
        XCTAssertEqual(reopened.favoriteIDs, [burns, hydration])
        XCTAssertTrue(reopened.isFavorite(burns))
        XCTAssertEqual(reopened.lastCategory, .injuries)
    }

    func testRemovingFavoriteAndClearingCategoryPersist() {
        let store = makeStore()
        store.setFavorite(true, for: burns)
        store.setLastCategory(.records)
        store.toggleFavorite(burns)
        store.setLastCategory(nil)

        let reopened = makeStore()
        XCTAssertTrue(reopened.favoriteIDs.isEmpty)
        XCTAssertNil(reopened.lastCategory)
    }

    func testUnknownEntryCannotBeBookmarked() {
        let store = makeStore()
        store.setFavorite(true, for: "medical.unknown")
        XCTAssertTrue(store.favoriteIDs.isEmpty)
        XCTAssertNil(defaults.object(forKey: MedicalStore.storageKey))
    }

    func testCorruptedDataFallsBackToDefaults() {
        defaults.set(Data("not json".utf8), forKey: MedicalStore.storageKey)
        XCTAssertEqual(makeStore().preferences, MedicalPreferences())
    }

    func testInvalidSavedValuesAreDroppedOnLoad() throws {
        let saved = MedicalPreferences(
            favoriteIDs: [burns, "medical.unknown", burns, hydration],
            lastCategory: "not-a-category"
        )
        defaults.set(try JSONEncoder().encode(saved), forKey: MedicalStore.storageKey)

        let store = makeStore()
        XCTAssertEqual(store.favoriteIDs, [burns, hydration])
        XCTAssertNil(store.lastCategory)
    }

    func testResetClearsMemoryAndStorage() {
        let store = makeStore()
        store.setFavorite(true, for: burns)
        store.setLastCategory(.supplies)
        store.reset()

        XCTAssertEqual(store.preferences, MedicalPreferences())
        XCTAssertNil(defaults.object(forKey: MedicalStore.storageKey))
        XCTAssertEqual(makeStore().preferences, MedicalPreferences())
    }

    func testLocalDataResetIncludesMedical() {
        XCTAssertTrue(LocalDataReset.storageKeys.contains(MedicalStore.storageKey))
    }

    func testLocalDataResetClearsMedicalPreferences() {
        let medical = makeStore()
        medical.setFavorite(true, for: burns)
        medical.setLastCategory(.illness)

        LocalDataReset.perform(
            kit: KitChecklistStore(defaults: defaults),
            alert: AlertPlanStore(defaults: defaults),
            settings: SettingsStore(defaults: defaults),
            downloads: DownloadsStore(defaults: defaults),
            connect: ConnectStore(defaults: defaults),
            maps: MapsStore(defaults: defaults),
            medical: medical,
            tools: ToolsState()
        )

        XCTAssertEqual(medical.preferences, MedicalPreferences())
        XCTAssertNil(defaults.object(forKey: MedicalStore.storageKey))
        XCTAssertTrue(makeStore().favoriteIDs.isEmpty)
    }
}
