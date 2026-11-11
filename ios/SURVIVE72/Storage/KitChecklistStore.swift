import Foundation
import Observation

/// Holds the SURVIVE KIT checklist state and keeps it on the device with
/// `UserDefaults`. No network, no account, no permissions.
///
/// Only the IDs of checked items are stored, as a plain string array, so the
/// saved data stays tiny and survives app restarts and updates.
@Observable
final class KitChecklistStore {
    /// Versioned key: a future format change can migrate from v1.
    static let storageKey = "survive72.kit.checkedItemIDs.v1"

    let items: [KitItem]
    private(set) var checkedIDs: Set<String>

    private let defaults: UserDefaults
    private let key: String

    init(
        items: [KitItem] = KitDefaults.items,
        defaults: UserDefaults = .standard,
        key: String = KitChecklistStore.storageKey
    ) {
        self.items = items
        self.defaults = defaults
        self.key = key

        // Ignore IDs that no longer exist in the current item list.
        let knownIDs = Set(items.map(\.id))
        let saved = defaults.stringArray(forKey: key) ?? []
        self.checkedIDs = Set(saved).intersection(knownIDs)
    }

    // MARK: Queries

    func categoryItems(_ category: KitCategory) -> [KitItem] {
        items.filter { $0.category == category }
    }

    func isChecked(_ item: KitItem) -> Bool {
        checkedIDs.contains(item.id)
    }

    var totalProgress: KitProgress {
        KitProgress(checked: checkedIDs.count, total: items.count)
    }

    func progress(for category: KitCategory) -> KitProgress {
        let inCategory = categoryItems(category)
        let checked = inCategory.filter { checkedIDs.contains($0.id) }.count
        return KitProgress(checked: checked, total: inCategory.count)
    }

    // MARK: Mutations (each one is saved immediately)

    func toggle(_ item: KitItem) {
        setChecked(!isChecked(item), for: item)
    }

    func setChecked(_ checked: Bool, for item: KitItem) {
        guard items.contains(where: { $0.id == item.id }) else { return }
        if checked {
            checkedIDs.insert(item.id)
        } else {
            checkedIDs.remove(item.id)
        }
        save()
    }

    func reset() {
        checkedIDs.removeAll()
        defaults.removeObject(forKey: key)
    }

    private func save() {
        defaults.set(checkedIDs.sorted(), forKey: key)
    }
}
