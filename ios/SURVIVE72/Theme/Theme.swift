import SwiftUI

/// Visual tokens for a high-contrast interface that stays readable under stress:
/// pure black background, near-white text, one strong accent, large tap targets.
enum Theme {
    // MARK: Colors
    static let background = Color.black
    static let surface = Color(red: 0.10, green: 0.10, blue: 0.10)
    static let surfaceBorder = Color(white: 0.35)
    static let textPrimary = Color.white
    static let textSecondary = Color(white: 0.82)
    /// Safety yellow: ~15:1 contrast on black.
    static let accent = Color(red: 1.0, green: 0.84, blue: 0.0)
    /// Alert red, kept bright enough for contrast on black.
    static let danger = Color(red: 1.0, green: 0.27, blue: 0.23)
    static let ok = Color(red: 0.30, green: 0.90, blue: 0.45)

    // MARK: Metrics
    /// Larger than Apple's 44 pt minimum: easier to hit with gloves or shaking hands.
    static let minTapHeight: CGFloat = 120
    static let cornerRadius: CGFloat = 14
    static let borderWidth: CGFloat = 2
    static let spacing: CGFloat = 12
}
