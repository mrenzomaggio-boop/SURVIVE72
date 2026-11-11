import SwiftUI

/// Large, high-contrast tile for one Home section.
struct SectionTile: View {
    let section: AppSection

    private var borderColor: Color {
        section.isEmergency ? Theme.danger : Theme.surfaceBorder
    }

    private var iconColor: Color {
        section.isEmergency ? Theme.danger : Theme.accent
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: section.systemImage)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(iconColor)
                .accessibilityHidden(true)

            Spacer(minLength: 0)

            Text(section.title)
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)

            Text(section.subtitle)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .lineLimit(2)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: Theme.minTapHeight, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(borderColor, lineWidth: section.isEmergency ? 3 : Theme.borderWidth)
        )
        .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(section.title), \(section.subtitle)")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    SectionTile(section: .alert)
        .padding()
        .background(Theme.background)
}
