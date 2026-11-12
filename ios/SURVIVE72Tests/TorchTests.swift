import XCTest
@testable import SURVIVE72

/// Torch logic with a fake flash: no hardware is touched.
final class TorchTests: XCTestCase {
    private final class FakeDevice: TorchDevice {
        var hasTorch = true
        var isTorchOn = false
        var shouldFail = false
        private(set) var calls: [Bool] = []

        func setTorch(on: Bool) throws {
            calls.append(on)
            if shouldFail { throw TorchError.unavailable }
            isTorchOn = on
        }
    }

    func testStartsOffAndNeverSwitchesOnByItself() {
        let device = FakeDevice()
        let torch = Torch(device: device)
        XCTAssertFalse(torch.isOn)
        XCTAssertFalse(torch.didFail)
        XCTAssertTrue(device.calls.isEmpty)
    }

    func testToggleSwitchesOnAndOff() {
        let device = FakeDevice()
        let torch = Torch(device: device)

        torch.toggle()
        XCTAssertTrue(torch.isOn)
        XCTAssertTrue(device.isTorchOn)

        torch.toggle()
        XCTAssertFalse(torch.isOn)
        XCTAssertFalse(device.isTorchOn)
        XCTAssertEqual(device.calls, [true, false])
    }

    func testFailureIsReportedAndStateFollowsTheDevice() {
        let device = FakeDevice()
        device.shouldFail = true
        let torch = Torch(device: device)

        torch.set(on: true)
        XCTAssertFalse(torch.isOn)
        XCTAssertTrue(torch.didFail)

        device.shouldFail = false
        torch.set(on: true)
        XCTAssertTrue(torch.isOn)
        XCTAssertFalse(torch.didFail)
    }

    func testDeviceWithoutFlashIsUnavailable() {
        let device = FakeDevice()
        device.hasTorch = false
        let torch = Torch(device: device)

        XCTAssertFalse(torch.isAvailable)
        torch.set(on: true)
        XCTAssertFalse(torch.isOn)
        XCTAssertTrue(torch.didFail)
        XCTAssertTrue(device.calls.isEmpty)
    }

    func testRefreshShowsTheRealStateAfterTheSystemSwitchedItOff() {
        let device = FakeDevice()
        let torch = Torch(device: device)
        torch.set(on: true)

        device.isTorchOn = false   // e.g. the app went to the background
        torch.refresh()
        XCTAssertFalse(torch.isOn)
    }

    func testEraseAllSwitchesTheTorchOff() {
        let suite = "SURVIVE72Tests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let tools = ToolsState()
        XCTAssertFalse(tools.torch.isOn)
        LocalDataReset.perform(
            kit: KitChecklistStore(defaults: defaults), alert: AlertPlanStore(defaults: defaults),
            settings: SettingsStore(defaults: defaults), downloads: DownloadsStore(defaults: defaults),
            connect: ConnectStore(defaults: defaults), maps: MapsStore(defaults: defaults),
            medical: MedicalStore(defaults: defaults), tools: tools)
        XCTAssertFalse(tools.torch.isOn)
    }

    func testHighContrastChangesTheThemeValues() {
        let options = ThemeOptions.shared
        let original = options.highContrast
        defer { options.highContrast = original }

        options.highContrast = true
        let strongWidth = Theme.borderWidth
        options.highContrast = false
        XCTAssertLessThan(Theme.borderWidth, strongWidth)
    }
}
