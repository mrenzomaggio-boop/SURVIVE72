import SwiftUI

/// Measurement system chosen by the user.
enum UnitSystem: String, CaseIterable, Identifiable, Codable {
    case metric
    case imperial

    var id: String { rawValue }

    var title: String {
        switch self {
        case .metric: "Metric"
        case .imperial: "Imperial"
        }
    }
}

/// User preferences, saved on the device.
struct AppSettings: Codable, Equatable {
    var unitSystem: UnitSystem = .metric
    /// Bolder text everywhere on top of the high-contrast dark theme.
    var highContrast: Bool = true
    /// Fewer screen refreshes (e.g. stopwatch updates once per second).
    var batterySaver: Bool = false
}

extension AppSettings {
    /// Tolerant decoding: an unknown or missing value falls back to its default
    /// without resetting the other preferences.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let fallback = AppSettings()
        unitSystem = c.value(UnitSystem.self, forKey: .unitSystem, default: fallback.unitSystem)
        highContrast = c.value(Bool.self, forKey: .highContrast, default: fallback.highContrast)
        batterySaver = c.value(Bool.self, forKey: .batterySaver, default: fallback.batterySaver)
    }
}

/// Unit conversions used to show values in the chosen system.
enum UnitFormat {
    static func volume(liters: Double, in system: UnitSystem) -> String {
        switch system {
        case .metric:
            return "\(oneDecimal(liters)) L"
        case .imperial:
            return "\(oneDecimal(liters / 3.785_411_784)) gal"
        }
    }

    static func distance(kilometers: Double, in system: UnitSystem) -> String {
        switch system {
        case .metric:
            return "\(oneDecimal(kilometers)) km"
        case .imperial:
            return "\(oneDecimal(kilometers / 1.609_344)) mi"
        }
    }

    /// One decimal, dropping ".0" (4.0 -> "4", 1.06 -> "1.1").
    private static func oneDecimal(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded == rounded.rounded() {
            return String(Int(rounded))
        }
        return String(format: "%.1f", rounded)
    }
}

// MARK: - Environment

private struct BatterySaverKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// True when the user turned on battery saver in Settings.
    var batterySaverEnabled: Bool {
        get { self[BatterySaverKey.self] }
        set { self[BatterySaverKey.self] = newValue }
    }
}
