import SwiftUI

/// Home tile for one section: a colored pictogram chip and the name, on a
/// white (day) or dark-blue (night) card.
struct SectionTile: View {
    let section: AppSection

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: section.systemImage)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(section.tint)
                .frame(width: 54, height: 54)
                .background(section.tint.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
                .accessibilityHidden(true)

            Text(section.title)
                .font(.headline.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, minHeight: Theme.minTapHeight)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.surfaceBorder.opacity(0.6), lineWidth: Theme.borderWidth)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 6, y: 2)
        .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(section.title), \(section.subtitle)")
        .accessibilityAddTraits(.isButton)
    }
}

/// Big orange banner that opens Alert: the emergency entry point, always at
/// the top of Home.
struct AlertBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: AppSection.alert.systemImage)
                .font(.system(size: 28, weight: .bold))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "Alert and SOS"))
                    .font(.title2.weight(.black))
                Text(AppSection.alert.subtitle)
                    .font(.subheadline.weight(.bold))
                    .opacity(0.95)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.headline.weight(.black))
                .frame(width: 40, height: 40)
                .background(Color.white.opacity(0.25), in: Circle())
                .accessibilityHidden(true)
        }
        .foregroundStyle(Theme.onAccent)
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .background(
            LinearGradient(colors: [Theme.accent, Theme.accentSoft],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 22)
        )
        .shadow(color: Theme.accent.opacity(0.3), radius: 10, y: 4)
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(String(localized: "Alert and SOS. \(AppSection.alert.subtitle)"))
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    VStack {
        AlertBanner()
        SectionTile(section: .medical)
    }
    .padding()
    .background(Theme.background)
}
