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
        case .connect: String(localized: "Connect")
        case .maps: String(localized: "Maps")
        case .knowledge: String(localized: "Knowledge")
        case .medical: String(localized: "Medical")
        case .kit: String(localized: "Kit")
        case .radio: String(localized: "Radio")
        case .alert: String(localized: "Alert")
        case .tools: String(localized: "Tools")
        case .downloads: String(localized: "Downloads")
        case .settings: String(localized: "Settings")
        }
    }

    var subtitle: String {
        switch self {
        case .connect: String(localized: "Phone-to-phone messages")
        case .maps: String(localized: "Places, offline areas")
        case .knowledge: String(localized: "Offline library")
        case .medical: String(localized: "First aid cards")
        case .kit: String(localized: "72-hour checklist")
        case .radio: String(localized: "Frequencies, guide")
        case .alert: String(localized: "Alert board, SOS plan")
        case .tools: String(localized: "Stopwatch, SOS light")
        case .downloads: String(localized: "Offline packs")
        case .settings: String(localized: "Preferences")
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
