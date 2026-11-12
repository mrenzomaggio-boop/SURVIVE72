import Foundation
import Observation

/// Preferences saved as JSON in `UserDefaults`.
@Observable
final class SettingsStore {
    static let storageKey = "survive72.settings.v1"

    private(set) var settings: AppSettings

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = SettingsStore.storageKey) {
        self.defaults = defaults
        self.key = key
        if let decoded = LocalStorage.load(AppSettings.self, key: key, from: defaults) {
            settings = decoded
        } else {
            settings = AppSettings()
        }
    }

    func update(_ newValue: AppSettings) {
        settings = newValue
        LocalStorage.save(newValue, key: key, to: defaults)
    }

    /// Back to default preferences and nothing saved.
    func reset() {
        settings = AppSettings()
        LocalStorage.remove(key: key, from: defaults)
    }
}

/// Erases every piece of SURVIVE 72 data kept on this device.
enum LocalDataReset {
    /// All `UserDefaults` keys written by the app.
    static let storageKeys = [
        KitChecklistStore.storageKey,
        AlertPlanStore.storageKey,
        SettingsStore.storageKey,
        DownloadsStore.storageKey,
        ConnectStore.storageKey,
        MapsStore.storageKey,
        MedicalStore.storageKey
    ]

    static func perform(
        kit: KitChecklistStore,
        alert: AlertPlanStore,
        settings: SettingsStore,
        downloads: DownloadsStore,
        connect: ConnectStore,
        maps: MapsStore,
        medical: MedicalStore,
        tools: ToolsState
    ) {
        kit.reset()
        alert.resetAll()
        settings.reset()
        downloads.reset()
        connect.reset()
        maps.reset()
        medical.reset()
        tools.stopwatch.reset()
        tools.sosSignal.stop()
    }
}
