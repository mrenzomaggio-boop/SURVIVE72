import SwiftUI

/// Entry point of SURVIVE 72.
///
/// The app is offline-first: everything shown at this stage comes from
/// local, bundled demo data (see `DemoContent`). No networking, Bluetooth,
/// location, maps or hardware access is implemented yet.
@main
struct SURVIVE72App: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
                // High-contrast dark UI: readable at night, saves battery on OLED.
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
    }
}
