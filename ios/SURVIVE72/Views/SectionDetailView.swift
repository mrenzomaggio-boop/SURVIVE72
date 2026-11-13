import SwiftUI

/// Placeholder screen for a section, filled with local demo items only.
struct SectionDetailView: View {
    let section: AppSection

    private var items: [DemoItem] { DemoContent.items(for: section) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacing) {
                HStack(spacing: 12) {
                    Image(systemName: section.systemImage)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(section.isEmergency ? Theme.danger : Theme.accent)
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(section.subtitle)
                            .font(.headline)
                            .foregroundStyle(Theme.textSecondary)
                        Text(String(localized: "DEMO · NOT YET IMPLEMENTED"))
                            .font(.caption.weight(.heavy))
                            .foregroundStyle(Theme.onAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Theme.accent, in: Capsule())
                    }
                }
                .padding(.bottom, 4)

                ForEach(items) { item in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.title)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                        Text(item.detail)
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth)
                    )
                    .accessibilityElement(children: .combine)
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(section.title)
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationStack {
        SectionDetailView(section: .medical)
    }
    .preferredColorScheme(.dark)
}
