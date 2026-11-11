import Foundation
import Observation

/// Local state of offline packs. Only the IDs of packs marked as prepared are
/// saved in `UserDefaults`. No network: marking a pack does not download it.
@Observable
final class DownloadsStore {
    static let storageKey = "survive72.downloads.preparedPackIDs.v1"

    let packs: [OfflinePack]
    private(set) var preparedIDs: Set<String>

    private let defaults: UserDefaults
    private let key: String

    init(
        packs: [OfflinePack] = OfflinePackCatalog.packs,
        defaults: UserDefaults = .standard,
        key: String = DownloadsStore.storageKey
    ) {
        self.packs = packs
        self.defaults = defaults
        self.key = key
        let preparable = Set(packs.filter { !$0.isBundled }.map(\.id))
        let saved = Set(defaults.stringArray(forKey: key) ?? [])
        preparedIDs = saved.intersection(preparable)
    }

    func status(of pack: OfflinePack) -> OfflinePackStatus {
        if pack.isBundled { return .bundled }
        return preparedIDs.contains(pack.id) ? .prepared : .notPrepared
    }

    /// Marks a non-bundled pack as prepared or not. Bundled packs cannot change.
    func setPrepared(_ prepared: Bool, for pack: OfflinePack) {
        guard !pack.isBundled, packs.contains(where: { $0.id == pack.id }) else { return }
        if prepared {
            preparedIDs.insert(pack.id)
        } else {
            preparedIDs.remove(pack.id)
        }
        defaults.set(preparedIDs.sorted(), forKey: key)
    }

    var summary: DownloadsSummary {
        let available = packs.filter { status(of: $0).isAvailable }
        let missing = packs.filter { !status(of: $0).isAvailable }
        let required = packs.filter(\.isRequired)
        return DownloadsSummary(
            availableCount: available.count,
            totalCount: packs.count,
            requiredReady: required.filter { status(of: $0).isAvailable }.count,
            requiredTotal: required.count,
            usedMB: available.reduce(0) { $0 + $1.sizeMB },
            missingMB: missing.reduce(0) { $0 + $1.sizeMB }
        )
    }

    func reset() {
        preparedIDs.removeAll()
        defaults.removeObject(forKey: key)
    }

    /// Free space on the device, read locally (no permission needed). nil if unknown.
    static func deviceFreeBytes() -> Int64? {
        let url = URL(fileURLWithPath: NSHomeDirectory())
        let values = try? url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        return values?.volumeAvailableCapacityForImportantUsage
    }
}
