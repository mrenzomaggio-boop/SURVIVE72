import SwiftUI

/// Entry point of SURVIVE 72.
///
/// The app is offline-first. SURVIVE KIT, ALERT, CONNECT, MAPS, MEDICAL, DOWNLOADS and SETTINGS keep
/// their data on the device with `UserDefaults`; RADIO is a bundled guide; SURVIVE KNOWLEDGE ships its articles in the
/// app bundle; SURVIVE TOOLS keeps its stopwatch and SOS signal in memory and can switch the flash LED as a torch;
/// CONNECT is a local demo chat whose queue is only simulated; MAPS stores
/// places typed by hand; MEDICAL ships placeholder topics and saves only bookmarks and the
/// last category. ALERT (board) and CONNECT use a phone-to-phone mesh over
/// Bluetooth and peer-to-peer Wi-Fi, off until the user switches it on.
/// No internet, server, location or maps are used.
@main
struct SURVIVE72App: App {
    @State private var kitStore = KitChecklistStore()
    @State private var alertStore = AlertPlanStore()
    @State private var toolsState = ToolsState()
    @State private var settingsStore = SettingsStore()
    @State private var downloadsStore = DownloadsStore()
    @State private var connectStore = ConnectStore()
    @State private var mapsStore = MapsStore()
    @State private var medicalStore = MedicalStore()
    @State private var meshService = MeshService()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(kitStore)
                .environment(alertStore)
                .environment(toolsState)
                .environment(settingsStore)
                .environment(downloadsStore)
                .environment(connectStore)
                .environment(mapsStore)
                .environment(medicalStore)
                .environment(meshService)
                // iOS closes the phone-to-phone link in the background: reopen it.
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active { meshService.appBecameActive() }
                }
                // Settings: brighter text and stronger borders in high-contrast mode, fewer refreshes in battery saver.
                .environment(\.legibilityWeight, settingsStore.settings.highContrast ? .bold : .regular)
                .onChange(of: settingsStore.settings.highContrast, initial: true) { _, isOn in
                    ThemeOptions.shared.highContrast = isOn
                }
                .environment(\.batterySaverEnabled, settingsStore.settings.batterySaver)
                // Day (light) and night (dark) looks follow the iPhone setting.
                .fontDesign(.rounded)
                .tint(Theme.accent)
        }
    }
}
