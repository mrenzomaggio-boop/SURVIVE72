import SwiftUI

/// Entry point of SURVIVE 72.
///
/// The app is offline-first. SURVIVE KIT, ALERT, CONNECT, MAPS, MEDICAL, DOWNLOADS and SETTINGS keep
/// their data on the device with `UserDefaults`; RADIO is a bundled guide; SURVIVE KNOWLEDGE ships its articles in the
/// app bundle; SURVIVE TOOLS keeps its stopwatch and SOS signal in memory;
/// CONNECT is a local demo chat whose queue is only simulated; MAPS stores
/// places typed by hand; MEDICAL ships placeholder topics and saves only bookmarks and the
/// last category. No networking, Bluetooth,
/// Wi-Fi peer-to-peer, location, maps or hardware access is implemented yet.
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
                // Settings: bolder text in high-contrast mode, fewer refreshes in battery saver.
                .environment(\.legibilityWeight, settingsStore.settings.highContrast ? .bold : .regular)
                .environment(\.batterySaverEnabled, settingsStore.settings.batterySaver)
                // High-contrast dark UI: readable at night, saves battery on OLED.
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}
