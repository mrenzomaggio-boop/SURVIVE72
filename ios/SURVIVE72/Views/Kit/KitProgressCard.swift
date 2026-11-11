import SwiftUI

/// Big overall progress summary shown at the top of SURVIVE KIT.
struct KitProgressCard: View {
    let title: String
    let progress: KitProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title.uppercased())
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Text(progress.isComplete ? "READY" : "IN PROGRESS")
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Theme.background)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(progress.isComplete ? Theme.ok : Theme.accent, in: Capsule())
            }

            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(progress.percent)%")
                    .font(.system(size: 56, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
                    .minimumScaleFactor(0.6)
                Text("\(progress.checked) of \(progress.total) packed")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
            }

            KitProgressBar(fraction: progress.fraction, isComplete: progress.isComplete)
                .frame(height: 16)
        }
        .padding(16)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(progress.isComplete ? Theme.ok : Theme.accent, lineWidth: 3)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Overall kit progress")
        .accessibilityValue(progress.accessibilityDescription)
    }
}

/// Solid, high-contrast progress bar (no thin system track).
struct KitProgressBar: View {
    let fraction: Double
    let isComplete: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(white: 0.25))
                Capsule()
                    .fill(isComplete ? Theme.ok : Theme.accent)
                    .frame(width: proxy.size.width * min(max(fraction, 0), 1))
            }
        }
        .accessibilityHidden(true)
    }
}
