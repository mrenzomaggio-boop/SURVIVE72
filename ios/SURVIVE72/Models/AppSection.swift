import SwiftUI

/// The ten top-level sections shown on the Home screen.
enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case connect
    case maps
    case knowledge
    case medical
    case kit
    case radio
    case alert
    case tools
    case downloads
    case settings

    var id: String { rawValue }

    var title: String {
        switch self {
        case .connect: "Connect"
        case .maps: "Maps"
        case .knowledge: "Knowledge"
        case .medical: "Medical"
        case .kit: "Kit"
        case .radio: "Radio"
        case .alert: "Alert"
        case .tools: "Tools"
        case .downloads: "Downloads"
        case .settings: "Settings"
        }
    }

    var subtitle: String {
        switch self {
        case .connect: "Nearby devices"
        case .maps: "Offline maps"
        case .knowledge: "Offline library"
        case .medical: "First aid"
        case .kit: "72-hour checklist"
        case .radio: "Offline guide"
        case .alert: "SOS plan"
        case .tools: "Stopwatch, SOS light"
        case .downloads: "Offline packs"
        case .settings: "Preferences"
        }
    }

    /// SF Symbols available on iOS 17.
    var systemImage: String {
        switch self {
        case .connect: "point.3.connected.trianglepath.dotted"
        case .maps: "map.fill"
        case .knowledge: "book.closed.fill"
        case .medical: "cross.case.fill"
        case .kit: "backpack.fill"
        case .radio: "antenna.radiowaves.left.and.right"
        case .alert: "exclamationmark.triangle.fill"
        case .tools: "wrench.and.screwdriver.fill"
        case .downloads: "arrow.down.circle.fill"
        case .settings: "gearshape.fill"
        }
    }

    /// Alert is visually emphasised so it can be found instantly.
    var isEmergency: Bool { self == .alert }
}
