import Foundation

/// A single local, demonstrative entry shown inside a section.
struct DemoItem: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let detail: String
}

/// Static, bundled demo data. Nothing here is fetched from the network and
/// nothing here is real operational or medical guidance.
enum DemoContent {
    static func items(for section: AppSection) -> [DemoItem] {
        switch section {
        case .connect:
            [
                DemoItem(title: "Demo device A", detail: "Placeholder peer. Bluetooth is not implemented yet."),
                DemoItem(title: "Demo device B", detail: "Placeholder peer. No real scanning is performed.")
            ]
        case .maps:
            [
                DemoItem(title: "Demo region", detail: "Offline map packs will appear here. No map or GPS yet."),
                DemoItem(title: "Saved point (demo)", detail: "Example waypoint, not linked to a real location.")
            ]
        case .knowledge:
            [
                DemoItem(title: "Water (demo)", detail: "Placeholder chapter. Verified content will be added later."),
                DemoItem(title: "Shelter (demo)", detail: "Placeholder chapter. Verified content will be added later."),
                DemoItem(title: "Fire (demo)", detail: "Placeholder chapter. Verified content will be added later.")
            ]
        case .medical:
            [
                DemoItem(title: "Placeholder topic 1", detail: "DEMO ONLY. Not medical advice. Reviewed content will replace this."),
                DemoItem(title: "Placeholder topic 2", detail: "DEMO ONLY. Not medical advice. Reviewed content will replace this.")
            ]
        case .kit:
            [
                DemoItem(title: "Water", detail: "Demo checklist item."),
                DemoItem(title: "Food", detail: "Demo checklist item."),
                DemoItem(title: "Light source", detail: "Demo checklist item."),
                DemoItem(title: "Documents", detail: "Demo checklist item.")
            ]
        case .radio:
            [
                DemoItem(title: "Channel 1 (demo)", detail: "Placeholder frequency list. No radio access."),
                DemoItem(title: "Channel 2 (demo)", detail: "Placeholder frequency list. No radio access.")
            ]
        case .alert:
            [
                DemoItem(title: "Visual signal (demo)", detail: "Screen and torch signals are not implemented yet."),
                DemoItem(title: "Sound signal (demo)", detail: "Audio signals are not implemented yet.")
            ]
        case .tools:
            [
                DemoItem(title: "Torch", detail: "Not implemented yet."),
                DemoItem(title: "Compass", detail: "Not implemented yet."),
                DemoItem(title: "Timer", detail: "Not implemented yet.")
            ]
        case .downloads:
            [
                DemoItem(title: "Core pack (demo)", detail: "Bundled with the app. Nothing is downloaded."),
                DemoItem(title: "Region pack (demo)", detail: "Placeholder. Downloads are not implemented yet.")
            ]
        case .settings:
            [
                DemoItem(title: "Mode", detail: "Offline. No account, no network."),
                DemoItem(title: "Theme", detail: "High contrast, dark."),
                DemoItem(title: "Version", detail: "0.1.0 (foundation)")
            ]
        }
    }
}
