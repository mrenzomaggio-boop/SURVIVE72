import XCTest
@testable import SURVIVE72

/// Preferences persistence, unit formatting and full local data reset.
final class SettingsStoreTests: XCTestCase {
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

    // MARK: Preferences

    func testDefaults() {
        let settings = SettingsStore(defaults: defaults).settings
        XCTAssertEqual(settings.unitSystem, .metric)
        XCTAssertTrue(settings.highContrast)
        XCTAssertFalse(settings.batterySaver)
    }

    func testPreferencesPersistAcrossInstances() {
        let store = SettingsStore(defaults: defaults)
        store.update(AppSettings(unitSystem: .imperial, highContrast: false, batterySaver: true))

        let reopened = SettingsStore(defaults: defaults).settings
        XCTAssertEqual(reopened, AppSettings(unitSystem: .imperial, highContrast: false, batterySaver: true))
    }

    func testResetRestoresDefaultsAndClearsStorage() {
        let store = SettingsStore(defaults: defaults)
        store.update(AppSettings(unitSystem: .imperial, highContrast: false, batterySaver: true))
        store.reset()

        XCTAssertEqual(store.settings, AppSettings())
        XCTAssertNil(defaults.object(forKey: SettingsStore.storageKey))
        XCTAssertEqual(SettingsStore(defaults: defaults).settings, AppSettings())
    }

    func testUnreadableDataFallsBackToDefaults() {
        defaults.set(Data("broken".utf8), forKey: SettingsStore.storageKey)
        XCTAssertEqual(SettingsStore(defaults: defaults).settings, AppSettings())
    }

    // MARK: Units

    func testVolumeFormatting() {
        XCTAssertEqual(UnitFormat.volume(liters: 4, in: .metric), "4 L")
        XCTAssertEqual(UnitFormat.volume(liters: 4, in: .imperial), "1.1 gal")
        XCTAssertEqual(UnitFormat.volume(liters: 2.5, in: .metric), "2.5 L")
    }

    func testDistanceFormatting() {
        XCTAssertEqual(UnitFormat.distance(kilometers: 5, in: .metric), "5 km")
        XCTAssertEqual(UnitFormat.distance(kilometers: 5, in: .imperial), "3.1 mi")
        XCTAssertEqual(UnitFormat.distance(kilometers: 1.609344, in: .imperial), "1 mi")
    }

    // MARK: Erase all local data

    func testLocalDataResetClearsEveryModule() throws {
        let kit = KitChecklistStore(defaults: defaults)
        let alert = AlertPlanStore(defaults: defaults)
        let settings = SettingsStore(defaults: defaults)
        let downloads = DownloadsStore(defaults: defaults)
        let connect = ConnectStore(defaults: defaults)
        let tools = ToolsState()

        kit.toggle(try XCTUnwrap(kit.items.first))
        alert.addContact(name: "Bea", phone: "1", relationship: "")
        alert.updatePlan(PersonalPlan(name: "Ada"))
        settings.update(AppSettings(unitSystem: .imperial))
        downloads.setPrepared(true, for: try XCTUnwrap(downloads.packs.first { !$0.isBundled }))
        connect.send("Hello", to: "family")
        connect.setSOSText("Edited SOS")
        tools.stopwatch.start(at: Date())
        tools.sosSignal.start(at: Date())

        LocalDataReset.perform(kit: kit, alert: alert, settings: settings,
                               downloads: downloads, connect: connect, tools: tools)

        // In memory
        XCTAssertEqual(kit.totalProgress.checked, 0)
        XCTAssertEqual(alert.data, AlertPlanData())
        XCTAssertEqual(settings.settings, AppSettings())
        XCTAssertTrue(downloads.preparedIDs.isEmpty)
        XCTAssertEqual(connect.data, ConnectDemoContent.initialData())
        XCTAssertFalse(tools.stopwatch.isRunning)
        XCTAssertFalse(tools.sosSignal.isActive)

        // On the device
        for key in LocalDataReset.storageKeys {
            XCTAssertNil(defaults.object(forKey: key), key)
        }
        XCTAssertEqual(KitChecklistStore(defaults: defaults).totalProgress.checked, 0)
        XCTAssertTrue(AlertPlanStore(defaults: defaults).contacts.isEmpty)
    }

    func testStorageKeysAreUnique() {
        XCTAssertEqual(Set(LocalDataReset.storageKeys).count, LocalDataReset.storageKeys.count)
    }
}
