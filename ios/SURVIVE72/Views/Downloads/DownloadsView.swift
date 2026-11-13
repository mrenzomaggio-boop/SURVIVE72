import SwiftUI

/// SURVIVE DOWNLOADS: local offline packs with status, readiness and space.
/// Nothing is downloaded: non-bundled packs can only be marked as prepared.
struct DownloadsView: View {
    @Environment(DownloadsStore.self) private var store
    @State private var freeBytes: Int64?

    var body: some View {
        let summary = store.summary

        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MapAreasLink()

                SummaryCard(summary: summary, freeBytes: freeBytes)

                Label(String(localized: "Content packs below are simulated: marking a pack only records it on this device."),
                      systemImage: "wifi.slash")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Theme.accent, lineWidth: Theme.borderWidth))

                ForEach(store.packs) { pack in
                    PackRow(pack: pack, status: store.status(of: pack)) { prepared in
                        store.setPrepared(prepared, for: pack)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(String(localized: "Downloads"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear { freeBytes = DownloadsStore.deviceFreeBytes() }
    }
}

/// Real downloads: the offline map areas.
private struct MapAreasLink: View {
    @Environment(OfflineMapStore.self) private var mapStore

    var body: some View {
        NavigationLink {
            MapDownloadsView()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "map.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.onAccent)
                    .frame(width: 56, height: 56)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Offline maps"))
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Text(String(localized: "On this iPhone: \(mapStore.downloadedRegions.count) areas · \(SizeFormat.bytes(mapStore.usedBytes))"))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.accent, lineWidth: Theme.borderWidth))
        }
        .buttonStyle(.plain)
    }
}

private struct SummaryCard: View {
    let summary: DownloadsSummary
    let freeBytes: Int64?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(summary.readinessPercent)%")
                    .font(.system(size: 52, weight: .black).monospacedDigit())
                    .foregroundStyle(Theme.textPrimary)
                Text(summary.isReady ? String(localized: "READY") : String(localized: "NOT READY"))
                    .font(.headline.weight(.black))
                    .foregroundStyle(Theme.onAccent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(summary.isReady ? Theme.ok : Theme.accent, in: Capsule())
            }
            Text(String(localized: "Required packs: \(summary.requiredReady) of \(summary.requiredTotal)"))
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text(String(localized: "Available: \(summary.availableCount) of \(summary.totalCount) · uses \(SizeFormat.megabytes(summary.usedMB))"))
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
            Text(spaceLine)
                .font(.body.weight(.semibold))
                .foregroundStyle(spaceColor)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
            .stroke(summary.isReady ? Theme.ok : Theme.accent, lineWidth: 3))
        .accessibilityElement(children: .combine)
    }

    private var spaceLine: String {
        let free = freeBytes.map { String(localized: "Free on device: \(SizeFormat.bytes($0)).") } ?? String(localized: "Free space unknown.")
        guard summary.missingMB > 0 else { return String(localized: "\(free) Nothing missing.") }
        let fits = summary.missingFits(freeBytes: freeBytes)
        let verdict = fits == false ? String(localized: " Not enough space.") : (fits == true ? String(localized: " Enough space.") : "")
        return String(localized: "\(free) Missing packs need \(SizeFormat.megabytes(summary.missingMB)).\(verdict)")
    }

    private var spaceColor: Color {
        summary.missingFits(freeBytes: freeBytes) == false ? Theme.danger : Theme.textSecondary
    }
}

private struct PackRow: View {
    let pack: OfflinePack
    let status: OfflinePackStatus
    let onToggle: (Bool) -> Void

    private var statusColor: Color {
        switch status {
        case .bundled, .prepared: Theme.ok
        case .notPrepared: Theme.accent
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pack.title)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Text(pack.summary)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Text(status.label)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Theme.onAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor, in: Capsule())
            }
            HStack {
                Text(pack.isRequired ? String(localized: "\(SizeFormat.megabytes(pack.sizeMB)) · required") : SizeFormat.megabytes(pack.sizeMB))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                if !pack.isBundled {
                    Button {
                        onToggle(status != .prepared)
                    } label: {
                        Text(status == .prepared ? String(localized: "Unmark") : String(localized: "Mark prepared"))
                            .font(.headline.weight(.heavy))
                            .foregroundStyle(status == .prepared ? Theme.textPrimary : Theme.onAccent)
                            .padding(.horizontal, 14)
                            .frame(minHeight: 48)
                            .background(status == .prepared ? Theme.surface : Theme.accent,
                                        in: RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10)
                                .stroke(Theme.accent, lineWidth: Theme.borderWidth))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(status == .prepared
                        ? String(localized: "Unmark \(pack.title)") : String(localized: "Mark \(pack.title) as prepared"))
                    .accessibilityHint(String(localized: "Local only. Nothing is downloaded."))
                }
            }
        }
        .padding(14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
            .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth))
    }
}
