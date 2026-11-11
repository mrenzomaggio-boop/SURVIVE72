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
        if let saved = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: saved) {
            settings = decoded
        } else {
            settings = AppSettings()
        }
    }

    func update(_ newValue: AppSettings) {
        settings = newValue
        if let encoded = try? JSONEncoder().encode(newValue) {
            defaults.set(encoded, forKey: key)
        }
    }

    /// Back to default preferences and nothing saved.
    func reset() {
        settings = AppSettings()
        defaults.removeObject(forKey: key)
    }
}

/// Erases every piece of SURVIVE 72 data kept on this device.
enum LocalDataReset {
    /// All `UserDefaults` keys written by the app.
    static let storageKeys = [
        KitChecklistStore.storageKey,
        AlertPlanStore.storageKey,
        SettingsStore.storageKey,
        DownloadsStore.storageKey
    ]

    static func perform(
        kit: KitChecklistStore,
        alert: AlertPlanStore,
        settings: SettingsStore,
        downloads: DownloadsStore,
        tools: ToolsState
    ) {
        kit.reset()
        alert.resetAll()
        settings.reset()
        downloads.reset()
        tools.stopwatch.reset()
        tools.sosSignal.stop()
    }
}
