import Foundation

/// The six categories of the SURVIVE KIT 72-hour checklist.
enum KitCategory: String, CaseIterable, Identifiable, Codable, Hashable {
    case water
    case food
    case health
    case lighting
    case documents
    case gear

    var id: String { rawValue }

    var title: String {
        switch self {
        case .water: "Water"
        case .food: "Food"
        case .health: "Health"
        case .lighting: "Lighting"
        case .documents: "Documents"
        case .gear: "Gear"
        }
    }

    /// SF Symbols available on iOS 17.
    var systemImage: String {
        switch self {
        case .water: "drop.fill"
        case .food: "fork.knife"
        case .health: "cross.case.fill"
        case .lighting: "flashlight.on.fill"
        case .documents: "doc.text.fill"
        case .gear: "wrench.and.screwdriver.fill"
        }
    }
}

/// One checklist entry. `id` is a stable string so saved state survives
/// reordering or renaming of items in future versions.
struct KitItem: Identifiable, Hashable, Codable {
    let id: String
    let category: KitCategory
    let title: String
    let detail: String
}

/// Packed/total counter with derived values used by the UI and VoiceOver.
struct KitProgress: Equatable {
    let checked: Int
    let total: Int

    /// 0.0 ... 1.0. An empty list counts as 0, never NaN.
    var fraction: Double {
        guard total > 0 else { return 0 }
        return Double(checked) / Double(total)
    }

    /// Whole percent, rounded down so 100% only appears when everything is packed.
    var percent: Int {
        guard total > 0 else { return 0 }
        return (checked * 100) / total
    }

    var isComplete: Bool { total > 0 && checked == total }

    /// Short visual label, e.g. "5/24".
    var shortLabel: String { "\(checked)/\(total)" }

    /// Full sentence for VoiceOver, e.g. "5 of 24 items packed, 20 percent".
    var accessibilityDescription: String {
        let noun = total == 1 ? "item" : "items"
        return "\(checked) of \(total) \(noun) packed, \(percent) percent"
    }
}
