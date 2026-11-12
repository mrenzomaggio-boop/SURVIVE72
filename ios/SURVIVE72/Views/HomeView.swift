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
            .navigationTitle(String(localized: "SURVIVE 72"))
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .navigationDestination(for: AppSection.self) { section in
                destination(for: section)
            }
        }
    }

    /// Every section opens its real module.
    @ViewBuilder
    private func destination(for section: AppSection) -> some View {
        switch section {
        case .connect:
            MeshConnectView()
        case .maps:
            MapsView()
        case .kit:
            KitChecklistView()
        case .knowledge:
            KnowledgeLibraryView()
        case .alert:
            AlertPlanningView()
        case .tools:
            ToolsView()
        case .radio:
            RadioGuideView()
        case .downloads:
            DownloadsView()
        case .medical:
            MedicalLibraryView()
        case .settings:
            SettingsView()
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
            Text(String(localized: "OFFLINE READY · NO INTERNET NEEDED"))
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
        .accessibilityLabel(String(localized: "Offline ready. No internet needed."))
    }
}

#Preview {
    HomeView()
        .environment(KitChecklistStore(defaults: UserDefaults(suiteName: "preview.home")!))
        .environment(AlertPlanStore(defaults: UserDefaults(suiteName: "preview.home")!))
        .environment(ToolsState())
        .environment(SettingsStore(defaults: UserDefaults(suiteName: "preview.home")!))
        .environment(DownloadsStore(defaults: UserDefaults(suiteName: "preview.home")!))
        .environment(ConnectStore(defaults: UserDefaults(suiteName: "preview.home")!))
        .environment(MapsStore(defaults: UserDefaults(suiteName: "preview.home")!))
        .environment(MedicalStore(defaults: UserDefaults(suiteName: "preview.home")!))
        .environment(MeshService(keyStore: InMemoryMeshKeyStore(),
                                 defaults: UserDefaults(suiteName: "preview.home")!, stateURL: nil))
        .preferredColorScheme(.dark)
}
