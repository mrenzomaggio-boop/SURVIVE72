import Foundation

/// An offline content pack. Nothing is downloaded: bundled packs ship with the
/// app, the others can only be marked as prepared locally (simulated).
struct OfflinePack: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    /// Estimated size in megabytes.
    let sizeMB: Int
    /// Included in the app and always available.
    let isBundled: Bool
    /// Needed to be considered ready for the first 72 hours.
    let isRequired: Bool
}

enum OfflinePackStatus: Equatable {
    case bundled
    case prepared
    case notPrepared

    var label: String {
        switch self {
        case .bundled: String(localized: "INCLUDED")
        case .prepared: String(localized: "PREPARED")
        case .notPrepared: String(localized: "NOT PREPARED")
        }
    }

    var isAvailable: Bool { self != .notPrepared }
}

/// Totals shown at the top of Downloads.
struct DownloadsSummary: Equatable {
    let availableCount: Int
    let totalCount: Int
    let requiredReady: Int
    let requiredTotal: Int
    /// Space used by available packs, in MB.
    let usedMB: Int
    /// Extra space needed to prepare every missing pack, in MB.
    let missingMB: Int

    var isReady: Bool { requiredReady == requiredTotal }

    /// Share of required packs that are available, 0...100, rounded down.
    var readinessPercent: Int {
        guard requiredTotal > 0 else { return 100 }
        return requiredReady * 100 / requiredTotal
    }

    /// Whether the missing packs would fit in the given free space.
    func missingFits(freeBytes: Int64?) -> Bool? {
        guard let freeBytes else { return nil }
        return Int64(missingMB) * 1_000_000 <= freeBytes
    }
}

/// Readable sizes: "850 MB", "1.2 GB" (decimal units, like iOS Settings).
enum SizeFormat {
    static func megabytes(_ mb: Int) -> String {
        guard mb >= 1000 else { return "\(max(mb, 0)) MB" }
        let gb = (Double(mb) / 100).rounded(.down) / 10
        return gb == gb.rounded() ? "\(Int(gb)) GB" : String(format: "%.1f GB", gb)
    }

    static func bytes(_ bytes: Int64) -> String {
        megabytes(Int(bytes / 1_000_000))
    }
}

/// Built-in list of packs. Sizes are estimates for planning.
enum OfflinePackCatalog {
    static let packs: [OfflinePack] = [
        OfflinePack(id: "core.app", title: String(localized: "Core app"),
                    summary: String(localized: "Home, Kit, Alert and Tools. Already on this device."),
                    sizeMB: 12, isBundled: true, isRequired: true),
        OfflinePack(id: "core.knowledge", title: String(localized: "Knowledge library"),
                    summary: String(localized: "Demo articles marked TO BE VERIFIED."),
                    sizeMB: 2, isBundled: true, isRequired: true),
        OfflinePack(id: "core.radio", title: String(localized: "Radio guide"),
                    summary: String(localized: "General offline radio information."),
                    sizeMB: 1, isBundled: true, isRequired: false),
        OfflinePack(id: "region.map", title: String(localized: "Region map (demo)"),
                    summary: String(localized: "Placeholder for an offline map of your area."),
                    sizeMB: 850, isBundled: false, isRequired: true),
        OfflinePack(id: "guides.extended", title: String(localized: "Extended guides (demo)"),
                    summary: String(localized: "Placeholder for verified long-form guides."),
                    sizeMB: 120, isBundled: false, isRequired: false),
        OfflinePack(id: "audio.prompts", title: String(localized: "Voice prompts (demo)"),
                    summary: String(localized: "Placeholder for spoken instructions."),
                    sizeMB: 300, isBundled: false, isRequired: false)
    ]
}
