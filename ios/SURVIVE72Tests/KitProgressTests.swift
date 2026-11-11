import XCTest
@testable import SURVIVE72

/// Progress math, both on `KitProgress` alone and through the store.
final class KitProgressTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    private let sampleItems = [
        KitItem(id: "w1", category: .water, title: "W1", detail: ""),
        KitItem(id: "w2", category: .water, title: "W2", detail: ""),
        KitItem(id: "f1", category: .food, title: "F1", detail: ""),
        KitItem(id: "f2", category: .food, title: "F2", detail: ""),
        KitItem(id: "f3", category: .food, title: "F3", detail: ""),
        KitItem(id: "g1", category: .gear, title: "G1", detail: "")
    ]

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
        KitChecklistStore(items: sampleItems, defaults: defaults)
    }

    // MARK: KitProgress

    func testEmptyProgressIsZeroAndNotComplete() {
        let progress = KitProgress(checked: 0, total: 0)
        XCTAssertEqual(progress.fraction, 0)
        XCTAssertEqual(progress.percent, 0)
        XCTAssertFalse(progress.isComplete)
    }

    func testPercentRoundsDown() {
        XCTAssertEqual(KitProgress(checked: 1, total: 3).percent, 33)
        XCTAssertEqual(KitProgress(checked: 2, total: 3).percent, 66)
        XCTAssertEqual(KitProgress(checked: 23, total: 24).percent, 95)
        XCTAssertEqual(KitProgress(checked: 24, total: 24).percent, 100)
    }

    func testFractionAndCompletion() {
        XCTAssertEqual(KitProgress(checked: 1, total: 4).fraction, 0.25, accuracy: 0.0001)
        XCTAssertTrue(KitProgress(checked: 4, total: 4).isComplete)
        XCTAssertFalse(KitProgress(checked: 3, total: 4).isComplete)
    }

    func testLabelsForUIAndVoiceOver() {
        let progress = KitProgress(checked: 5, total: 20)
        XCTAssertEqual(progress.shortLabel, "5/20")
        XCTAssertEqual(progress.accessibilityDescription, "5 of 20 items packed, 25 percent")
        XCTAssertEqual(
            KitProgress(checked: 0, total: 1).accessibilityDescription,
            "0 of 1 item packed, 0 percent"
        )
    }

    // MARK: Store progress

    func testTotalProgressCountsAllCategories() {
        let store = makeStore()
        store.setChecked(true, for: sampleItems[0]) // w1
        store.setChecked(true, for: sampleItems[2]) // f1
        store.setChecked(true, for: sampleItems[5]) // g1

        XCTAssertEqual(store.totalProgress, KitProgress(checked: 3, total: 6))
        XCTAssertEqual(store.totalProgress.percent, 50)
    }

    func testProgressPerCategory() {
        let store = makeStore()
        store.setChecked(true, for: sampleItems[0]) // w1
        store.setChecked(true, for: sampleItems[1]) // w2
        store.setChecked(true, for: sampleItems[3]) // f2

        XCTAssertEqual(store.progress(for: .water), KitProgress(checked: 2, total: 2))
        XCTAssertTrue(store.progress(for: .water).isComplete)
        XCTAssertEqual(store.progress(for: .food), KitProgress(checked: 1, total: 3))
        XCTAssertEqual(store.progress(for: .gear), KitProgress(checked: 0, total: 1))
        XCTAssertEqual(store.progress(for: .health), KitProgress(checked: 0, total: 0))
    }

    func testProgressSurvivesReopenAndReset() {
        let store = makeStore()
        store.setChecked(true, for: sampleItems[2])
        store.setChecked(true, for: sampleItems[4])

        let reopened = makeStore()
        XCTAssertEqual(reopened.progress(for: .food), KitProgress(checked: 2, total: 3))

        reopened.reset()
        XCTAssertEqual(reopened.totalProgress, KitProgress(checked: 0, total: 6))
        XCTAssertEqual(makeStore().totalProgress.checked, 0)
    }
}
