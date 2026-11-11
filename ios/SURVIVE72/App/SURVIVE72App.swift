import SwiftUI

/// Entry point of SURVIVE 72.
///
/// The app is offline-first. SURVIVE KIT and SURVIVE ALERT keep their data on
/// the device with `UserDefaults`; SURVIVE KNOWLEDGE ships its articles in the
/// app bundle; SURVIVE TOOLS keeps its stopwatch and SOS signal in memory;
/// every other section still shows local demo data
/// (see `DemoContent`). No networking, Bluetooth, location, maps or hardware
/// access is implemented yet.
@main
struct SURVIVE72App: App {
    @State private var kitStore = KitChecklistStore()
    @State private var alertStore = AlertPlanStore()
    @State private var toolsState = ToolsState()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(kitStore)
                .environment(alertStore)
                .environment(toolsState)
                // High-contrast dark UI: readable at night, saves battery on OLED.
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}
