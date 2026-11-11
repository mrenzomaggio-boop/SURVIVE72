import XCTest
@testable import SURVIVE72

/// Persistence tests: every test uses its own throwaway UserDefaults suite,
/// so nothing touches the real app data.
final class KitChecklistStoreTests: XCTestCase {
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

    private func makeStore() -> KitChecklistStore {
        KitChecklistStore(defaults: defaults)
    }

    private func item(_ id: String) -> KitItem {
        KitDefaults.items.first { $0.id == id }!
    }

    func testNewStoreStartsEmpty() {
        let store = makeStore()
        XCTAssertTrue(store.checkedIDs.isEmpty)
        XCTAssertEqual(store.totalProgress.checked, 0)
        XCTAssertEqual(store.totalProgress.total, KitDefaults.items.count)
    }

    func testToggleChecksAndUnchecks() {
        let store = makeStore()
        let water = item("water.drinking")

        store.toggle(water)
        XCTAssertTrue(store.isChecked(water))

        store.toggle(water)
        XCTAssertFalse(store.isChecked(water))
    }

    func testCheckedItemsPersistAcrossStoreInstances() {
        let first = makeStore()
        first.setChecked(true, for: item("water.drinking"))
        first.setChecked(true, for: item("documents.id"))

        // Simulates closing and reopening the app.
        let reopened = makeStore()
        XCTAssertEqual(reopened.checkedIDs, ["water.drinking", "documents.id"])
        XCTAssertTrue(reopened.isChecked(item("documents.id")))
        XCTAssertFalse(reopened.isChecked(item("food.energy")))
    }

    func testUncheckIsPersisted() {
        let first = makeStore()
        first.setChecked(true, for: item("gear.whistle"))
        first.setChecked(false, for: item("gear.whistle"))

        XCTAssertTrue(makeStore().checkedIDs.isEmpty)
    }

    func testStateIsSavedUnderVersionedKey() {
        let store = makeStore()
        store.setChecked(true, for: item("lighting.flashlight"))

        XCTAssertEqual(
            defaults.stringArray(forKey: KitChecklistStore.storageKey),
            ["lighting.flashlight"]
        )
    }

    func testResetClearsMemoryAndStorage() {
        let store = makeStore()
        store.setChecked(true, for: item("water.drinking"))
        store.setChecked(true, for: item("health.firstaid"))

        store.reset()

        XCTAssertTrue(store.checkedIDs.isEmpty)
        XCTAssertNil(defaults.object(forKey: KitChecklistStore.storageKey))
        XCTAssertTrue(makeStore().checkedIDs.isEmpty)
    }

    func testUnknownSavedIDsAreIgnored() {
        defaults.set(["water.drinking", "removed.item"], forKey: KitChecklistStore.storageKey)

        let store = makeStore()
        XCTAssertEqual(store.checkedIDs, ["water.drinking"])
        XCTAssertEqual(store.totalProgress.checked, 1)
    }

    func testItemsOutsideTheListCannotBeChecked() {
        let store = makeStore()
        let stranger = KitItem(id: "not.in.list", category: .gear, title: "X", detail: "")

        store.setChecked(true, for: stranger)

        XCTAssertTrue(store.checkedIDs.isEmpty)
        XCTAssertNil(defaults.object(forKey: KitChecklistStore.storageKey))
    }

    func testDefaultsCoverAllCategoriesWithUniqueIDs() {
        let ids = KitDefaults.items.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count, "Item IDs must be unique")
        for category in KitCategory.allCases {
            XCTAssertFalse(
                KitDefaults.items.filter { $0.category == category }.isEmpty,
                "\(category) has no default items"
            )
        }
    }
}
