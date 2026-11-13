import SwiftUI

/// Home screen ("civic" look): brand header, readiness line, the big Alert
/// banner, then the other sections in a three-column grid.
struct HomeView: View {
    @Environment(KitChecklistStore.self) private var kitStore
    @Environment(MeshService.self) private var mesh

    private let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    /// Most used first; Alert has its own banner above the grid.
    static let gridSections: [AppSection] = [
        .medical, .knowledge, .connect, .radio, .maps, .kit
    ]

    /// Last row, two wider tiles. Offline map downloads live inside Maps.
    static let bottomSections: [AppSection] = [.tools, .settings]

    private let bottomColumns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    header

                    NavigationLink(value: AppSection.alert) {
                        AlertBanner()
                    }
                    .buttonStyle(.plain)

                    LazyVGrid(columns: columns, spacing: 10) {
                        ForEach(Self.gridSections) { section in
                            NavigationLink(value: section) {
                                SectionTile(section: section)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    LazyVGrid(columns: bottomColumns, spacing: 10) {
                        ForEach(Self.bottomSections) { section in
                            NavigationLink(value: section) {
                                SectionTile(section: section)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.top, -6)

                    OfflineBanner()
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(String(localized: "SURVIVE 72"))
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(for: AppSection.self) { section in
                destination(for: section)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            (Text(verbatim: "SURVIVE ").foregroundStyle(Theme.textPrimary)
             + Text(verbatim: "72").foregroundStyle(Theme.accent))
                .font(.system(size: 34, weight: .black, design: .rounded))
                .accessibilityLabel("SURVIVE 72")
                .accessibilityAddTraits(.isHeader)
            Text(String(localized: "Ready for the first 72 hours"))
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Text(statusLine)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(.top, 8)
    }

    private var statusLine: String {
        let kit = kitStore.totalProgress
        let kitText = String(localized: "Kit: \(kit.checked) of \(kit.total) items")
        guard mesh.profile.isEnabled else { return kitText }
        return kitText + " · " + String(localized: "Phones nearby: \(mesh.nearbyCount)")
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

/// Small reassurance line: the app works without connectivity.
private struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(Theme.ok)
                .accessibilityHidden(true)
            Text(String(localized: "Works without internet"))
                .foregroundStyle(Theme.textSecondary)
        }
        .font(.subheadline.weight(.bold))
        .frame(maxWidth: .infinity)
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
}
