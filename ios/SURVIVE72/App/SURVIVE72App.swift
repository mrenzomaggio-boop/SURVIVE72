import SwiftUI

/// Entry point of SURVIVE 72.
///
/// The app is offline-first. SURVIVE KIT keeps its checklist on the device
/// with `UserDefaults`; every other section still shows local demo data
/// (see `DemoContent`). No networking, Bluetooth, location, maps or hardware
/// access is implemented yet.
@main
struct SURVIVE72App: App {
    @State private var kitStore = KitChecklistStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environment(kitStore)
                // High-contrast dark UI: readable at night, saves battery on OLED.
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}
