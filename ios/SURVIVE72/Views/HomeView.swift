import SwiftUI

/// Home screen: a two-column grid with the ten SURVIVE 72 sections.
struct HomeView: View {
    private let columns = [
        GridItem(.flexible(), spacing: Theme.spacing),
        GridItem(.flexible(), spacing: Theme.spacing)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.spacing) {
                    OfflineBanner()

                    LazyVGrid(columns: columns, spacing: Theme.spacing) {
                        ForEach(AppSection.allCases) { section in
                            NavigationLink(value: section) {
                                SectionTile(section: section)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("SURVIVE 72")
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(for: AppSection.self) { section in
                SectionDetailView(section: section)
            }
        }
    }
}

/// Always-visible status line: the app works without connectivity.
private struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.ok)
                .accessibilityHidden(true)
            Text("OFFLINE READY · LOCAL DEMO DATA")
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.ok, lineWidth: Theme.borderWidth)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Offline ready. Showing local demo data.")
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
