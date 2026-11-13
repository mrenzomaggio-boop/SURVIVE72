import SwiftUI
import UIKit

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
        case .maps: String(localized: "Offline map, places")
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

    /// Color of the section's icon on Home: each section is recognisable by
    /// color as well as by name.
    var tint: Color {
        func c(_ light: UInt32, _ dark: UInt32) -> Color {
            Theme.dynamic(light: Self.uiColor(light), dark: Self.uiColor(dark))
        }
        switch self {
        case .medical: return c(0xC92A2A, 0xFF8787)
        case .knowledge: return c(0x1D4E9E, 0x8FB8FF)
        case .connect: return c(0x2B8A3E, 0x69DB7C)
        case .radio: return c(0xD9480F, 0xFFB36B)
        case .maps: return c(0x7048E8, 0xB197FC)
        case .kit: return c(0x0C8599, 0x66D9E8)
        case .alert: return c(0xE8590C, 0xFFB36B)
        case .tools: return c(0x495057, 0xCED4DA)
        case .downloads: return c(0x1864AB, 0x74C0FC)
        case .settings: return c(0x495057, 0xCED4DA)
        }
    }

    private static func uiColor(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }

    /// Alert is visually emphasised so it can be found instantly.
    var isEmergency: Bool { self == .alert }
}
