import Foundation

/// A demo offline map area. Nothing is downloaded: an area can only be
/// marked as prepared on this device.
struct OfflineArea: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    /// Estimated size, for display only.
    let sizeMB: Int
}

enum OfflineAreaStatus: Equatable {
    case prepared
    case notPrepared

    var label: String {
        switch self {
        case .prepared: "Prepared"
        case .notPrepared: "Not prepared"
        }
    }
}

/// Bundled list of demo areas. Names are generic placeholders.
enum OfflineAreaCatalog {
    static let all: [OfflineArea] = [
        OfflineArea(id: "area.home", title: "Home district (demo)",
                    summary: "Streets around home. Placeholder area.", sizeMB: 45),
        OfflineArea(id: "area.city", title: "City centre (demo)",
                    summary: "Main roads and public buildings. Placeholder area.", sizeMB: 120),
        OfflineArea(id: "area.region", title: "Regional overview (demo)",
                    summary: "Low-detail overview of the region. Placeholder area.", sizeMB: 300),
        OfflineArea(id: "area.routes", title: "Evacuation routes (demo)",
                    summary: "Example routes only, not official. Placeholder area.", sizeMB: 15)
    ]

    static let ids = Set(all.map(\.id))
}
