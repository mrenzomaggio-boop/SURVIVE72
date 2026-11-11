import XCTest
@testable import SURVIVE72

/// Offline pack status, persistence, readiness and space calculations.
final class DownloadsStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    private let packs = [
        OfflinePack(id: "core", title: "Core", summary: "", sizeMB: 10, isBundled: true, isRequired: true),
        OfflinePack(id: "map", title: "Map", summary: "", sizeMB: 800, isBundled: false, isRequired: true),
        OfflinePack(id: "extra", title: "Extra", summary: "", sizeMB: 200, isBundled: false, isRequired: false)
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

    private func makeStore() -> DownloadsStore {
        DownloadsStore(packs: packs, defaults: defaults)
    }

    // MARK: Status and persistence

    func testInitialStatus() {
        let store = makeStore()
        XCTAssertEqual(store.status(of: packs[0]), .bundled)
        XCTAssertEqual(store.status(of: packs[1]), .notPrepared)
        XCTAssertEqual(store.status(of: packs[2]), .notPrepared)
    }

    func testPreparedPackPersists() {
        makeStore().setPrepared(true, for: packs[1])
        XCTAssertEqual(makeStore().status(of: packs[1]), .prepared)
    }

    func testUnmarkPersists() {
        let store = makeStore()
        store.setPrepared(true, for: packs[1])
        store.setPrepared(false, for: packs[1])
        XCTAssertEqual(makeStore().status(of: packs[1]), .notPrepared)
    }

    func testBundledPackCannotChange() {
        let store = makeStore()
        store.setPrepared(false, for: packs[0])
        store.setPrepared(true, for: packs[0])
        XCTAssertEqual(store.status(of: packs[0]), .bundled)
        XCTAssertNil(defaults.object(forKey: DownloadsStore.storageKey))
    }

    func testUnknownAndBundledSavedIDsAreIgnored() {
        defaults.set(["map", "core", "gone"], forKey: DownloadsStore.storageKey)
        XCTAssertEqual(makeStore().preparedIDs, ["map"])
    }

    func testResetClearsPreparedPacks() {
        let store = makeStore()
        store.setPrepared(true, for: packs[1])
        store.reset()
        XCTAssertTrue(store.preparedIDs.isEmpty)
        XCTAssertNil(defaults.object(forKey: DownloadsStore.storageKey))
    }

    // MARK: Summary

    func testSummaryWithOnlyBundledPacks() {
        let summary = makeStore().summary
        XCTAssertEqual(summary, DownloadsSummary(availableCount: 1, totalCount: 3,
                                                 requiredReady: 1, requiredTotal: 2,
                                                 usedMB: 10, missingMB: 1000))
        XCTAssertEqual(summary.readinessPercent, 50)
        XCTAssertFalse(summary.isReady)
    }

    func testSummaryWhenRequiredPacksArePrepared() {
        let store = makeStore()
        store.setPrepared(true, for: packs[1])
        let summary = store.summary
        XCTAssertEqual(summary.usedMB, 810)
        XCTAssertEqual(summary.missingMB, 200)
        XCTAssertEqual(summary.readinessPercent, 100)
        XCTAssertTrue(summary.isReady)
    }

    func testReadinessWithNoRequiredPacksIsComplete() {
        let summary = DownloadsSummary(availableCount: 0, totalCount: 0, requiredReady: 0,
                                       requiredTotal: 0, usedMB: 0, missingMB: 0)
        XCTAssertEqual(summary.readinessPercent, 100)
        XCTAssertTrue(summary.isReady)
    }

    func testReadinessRoundsDown() {
        let summary = DownloadsSummary(availableCount: 1, totalCount: 3, requiredReady: 1,
                                       requiredTotal: 3, usedMB: 0, missingMB: 0)
        XCTAssertEqual(summary.readinessPercent, 33)
    }

    func testMissingSpaceFits() {
        let summary = makeStore().summary // 1000 MB missing
        XCTAssertEqual(summary.missingFits(freeBytes: 1_000_000_000), true)
        XCTAssertEqual(summary.missingFits(freeBytes: 999_999_999), false)
        XCTAssertNil(summary.missingFits(freeBytes: nil))
    }

    // MARK: Sizes

    func testSizeFormatting() {
        XCTAssertEqual(SizeFormat.megabytes(0), "0 MB")
        XCTAssertEqual(SizeFormat.megabytes(850), "850 MB")
        XCTAssertEqual(SizeFormat.megabytes(1000), "1 GB")
        XCTAssertEqual(SizeFormat.megabytes(1250), "1.2 GB")
        XCTAssertEqual(SizeFormat.megabytes(-5), "0 MB")
        XCTAssertEqual(SizeFormat.bytes(64_000_000_000), "64 GB")
    }

    func testBuiltInCatalogIsConsistent() {
        let catalog = OfflinePackCatalog.packs
        XCTAssertEqual(Set(catalog.map(\.id)).count, catalog.count)
        XCTAssertTrue(catalog.allSatisfy { $0.sizeMB > 0 })
        XCTAssertTrue(catalog.contains { $0.isBundled })
    }
}
