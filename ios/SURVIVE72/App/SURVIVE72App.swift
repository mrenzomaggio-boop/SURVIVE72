import SwiftUI

/// Entry point of SURVIVE 72.
///
/// The app is offline-first. SURVIVE KIT and SURVIVE ALERT keep their data on
/// the device with `UserDefaults`; SURVIVE KNOWLEDGE ships its articles in the
/// app bundle; every other section still shows local demo data
/// (see `DemoContent`). No networking, Bluetooth, location, maps or hardware
/// access is implemented yet.
@main
struct SURVIVE72App: App {
    @State private var kitStore = KitChecklistStore()
    @State private var alertStore = AlertPlanStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(kitStore)
                .environment(alertStore)
                // High-contrast dark UI: readable at night, saves battery on OLED.
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}
