import SwiftUI

/// Entry point of SURVIVE 72.
///
/// The app is offline-first. SURVIVE KIT, ALERT, CONNECT, MAPS, MEDICAL, DOWNLOADS and SETTINGS keep
/// their data on the device with `UserDefaults`; RADIO is a bundled guide; SURVIVE KNOWLEDGE ships its articles in the
/// app bundle; SURVIVE TOOLS keeps its stopwatch and SOS signal in memory and can switch the flash LED as a torch;
/// CONNECT is a local demo chat whose queue is only simulated; MAPS stores
/// places typed by hand; MEDICAL ships placeholder topics and saves only bookmarks and the
/// last category. ALERT shows official alerts (downloaded when online, passed
/// from phone to phone otherwise); CONNECT uses a phone-to-phone mesh over
/// Bluetooth and peer-to-peer Wi-Fi, off until the user switches it on.
/// MAPS also shows offline map areas downloaded once (OpenStreetMap) and the GPS position.
@main
struct SURVIVE72App: App {
    @State private var kitStore = KitChecklistStore()
    @State private var alertStore = AlertPlanStore()
    @State private var toolsState = ToolsState()
    @State private var settingsStore = SettingsStore()
    @State private var downloadsStore = DownloadsStore()
    @State private var connectStore = ConnectStore()
    @State private var mapsStore = MapsStore()
    @State private var offlineMapStore = OfflineMapStore()
    @State private var medicalStore = MedicalStore()
    @State private var officialAlerts: OfficialAlertStore
    @State private var meshService: MeshService
    @Environment(\.scenePhase) private var scenePhase
    @State private var wasInBackground = false

    init() {
        // One notifier for both: iOS keeps a single notification delegate.
        let notifier = LocalMeshNotifier()
        let official = OfficialAlertStore(notifier: notifier)
        _officialAlerts = State(initialValue: official)
        _meshService = State(initialValue: MeshService(notifier: notifier, official: official))
    }

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
                .environment(offlineMapStore)
                .environment(medicalStore)
                .environment(meshService)
                .environment(officialAlerts)
                // iOS closes the phone-to-phone link in the background: reopen it.
                // Only after a real trip to the background: a permission alert
                // also makes the app inactive for a moment, and restarting then
                // would drop a link that is just being set up.
                .onChange(of: scenePhase) { _, phase in
                    if phase == .background { wasInBackground = true }
                    if phase == .active, wasInBackground {
                        wasInBackground = false
                        meshService.appBecameActive()
                        Task { await officialAlerts.refresh() }
                    }
                }
                // A greeting lost while a link is being set up is sent again,
                // so waiting messages always find their way.
                // Official alerts are downloaded when there is internet (at most
                // every 10 minutes) and otherwise come from nearby phones.
                .task {
                    await officialAlerts.refresh()
                    while !Task.isCancelled {
                        try? await Task.sleep(for: .seconds(MeshService.helloInterval))
                        meshService.greetConnectedPeers()
                        await officialAlerts.refresh()
                    }
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
