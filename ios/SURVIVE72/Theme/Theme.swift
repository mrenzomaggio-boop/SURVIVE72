import Observation
import SwiftUI
import UIKit

/// Live display options read by `Theme`. Views that use the theme colors
/// update by themselves when a value changes.
@Observable
final class ThemeOptions {
    static let shared = ThemeOptions()
    /// Darker (day) or brighter (night) secondary text and stronger borders.
    var highContrast = true
}

/// Visual tokens of the "civic" look chosen by the user:
/// - Day: light blue-grey background, white cards, navy text, orange accent.
/// - Night: navy background, dark-blue cards, near-white text, orange accent.
/// The app follows the iPhone's light/dark setting. Text stays large and
/// the emergency button stands out in both modes.
enum Theme {
    /// A color with one value for light mode and one for dark mode.
    static func dynamic(light: UIColor, dark: UIColor) -> Color {
        Color(UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }

    private static func rgb(_ hex: UInt32) -> UIColor {
        UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                green: CGFloat((hex >> 8) & 0xFF) / 255,
                blue: CGFloat(hex & 0xFF) / 255,
                alpha: 1)
    }

    // MARK: Colors
    static let background = dynamic(light: rgb(0xF3F6FA), dark: rgb(0x0F1B2D))
    static let surface = dynamic(light: rgb(0xFFFFFF), dark: rgb(0x172741))
    static var surfaceBorder: Color {
        ThemeOptions.shared.highContrast
            ? dynamic(light: rgb(0x9AA9BF), dark: rgb(0x4A6488))
            : dynamic(light: rgb(0xDBE3EE), dark: rgb(0x24395A))
    }
    static let textPrimary = dynamic(light: rgb(0x13294B), dark: rgb(0xEAF1FB))
    static var textSecondary: Color {
        ThemeOptions.shared.highContrast
            ? dynamic(light: rgb(0x3D4C66), dark: rgb(0xC9D6E8))
            : dynamic(light: rgb(0x5B6B85), dark: rgb(0x9FB2CC))
    }
    /// Civil-protection orange: main buttons, selected chips, pictogram tiles.
    static let accent = dynamic(light: rgb(0xE8590C), dark: rgb(0xEC6A1E))
    /// Second end of the SOS gradient.
    static let accentSoft = dynamic(light: rgb(0xF08C00), dark: rgb(0xF59F00))
    /// Text and icons drawn on top of accent, danger or ok fills.
    static let onAccent = Color.white
    /// Blue used for links and secondary highlights.
    static let info = dynamic(light: rgb(0x1D4E9E), dark: rgb(0x8FB8FF))
    static let danger = dynamic(light: rgb(0xC92A2A), dark: rgb(0xE03131))
    static let ok = dynamic(light: rgb(0x2B8A3E), dark: rgb(0x2F9E44))

    // MARK: Metrics
    /// Larger than Apple's 44 pt minimum: easier to hit with gloves or shaking hands.
    static let minTapHeight: CGFloat = 104
    static let cornerRadius: CGFloat = 18
    static var borderWidth: CGFloat { ThemeOptions.shared.highContrast ? 1.5 : 1 }
    static let spacing: CGFloat = 12
}
