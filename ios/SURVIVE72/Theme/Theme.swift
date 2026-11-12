import Observation
import SwiftUI

/// Live display options read by `Theme`. Views that use the theme colors
/// update by themselves when a value changes.
@Observable
final class ThemeOptions {
    static let shared = ThemeOptions()
    /// Brighter secondary text and stronger borders.
    var highContrast = true
}

/// Visual tokens for a high-contrast interface that stays readable under stress:
/// pure black background, near-white text, one strong accent, large tap targets.
enum Theme {
    // MARK: Colors
    static let background = Color.black
    static let surface = Color(red: 0.10, green: 0.10, blue: 0.10)
    static var surfaceBorder: Color { Color(white: ThemeOptions.shared.highContrast ? 0.75 : 0.30) }
    static let textPrimary = Color.white
    static var textSecondary: Color { Color(white: ThemeOptions.shared.highContrast ? 0.95 : 0.68) }
    /// Safety yellow: ~15:1 contrast on black.
    static let accent = Color(red: 1.0, green: 0.84, blue: 0.0)
    /// Alert red, kept bright enough for contrast on black.
    static let danger = Color(red: 1.0, green: 0.27, blue: 0.23)
    static let ok = Color(red: 0.30, green: 0.90, blue: 0.45)

    // MARK: Metrics
    /// Larger than Apple's 44 pt minimum: easier to hit with gloves or shaking hands.
    static let minTapHeight: CGFloat = 120
    static let cornerRadius: CGFloat = 14
    static var borderWidth: CGFloat { ThemeOptions.shared.highContrast ? 3 : 1.5 }
    static let spacing: CGFloat = 12
}
