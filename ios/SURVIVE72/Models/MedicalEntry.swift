import Foundation

/// Topics of the SURVIVE MEDICAL offline library.
enum MedicalCategory: String, CaseIterable, Identifiable, Hashable {
    case lifeThreatening
    case injuries
    case environment
    case illness

    var id: String { rawValue }

    var title: String {
        switch self {
        case .lifeThreatening: String(localized: "Life-threatening")
        case .injuries: String(localized: "Injuries")
        case .environment: String(localized: "Heat and cold")
        case .illness: String(localized: "Sudden illness")
        }
    }

    /// SF Symbols available on iOS 17.
    var systemImage: String {
        switch self {
        case .lifeThreatening: "heart.fill"
        case .injuries: "bandage.fill"
        case .environment: "thermometer.medium"
        case .illness: "heart.text.square.fill"
        }
    }
}

/// Review state of a medical card. The cards follow published guidelines but
/// have not yet been reviewed by a doctor, so they keep a visible warning.
enum MedicalVerificationStatus: String, Hashable {
    case notReviewedByDoctor

    var label: String {
        switch self {
        case .notReviewedByDoctor: String(localized: "NOT YET REVIEWED BY A DOCTOR")
        }
    }

    var requiresVerification: Bool {
        switch self {
        case .notReviewedByDoctor: true
        }
    }
}

/// One first aid card, bundled with the app. Written by SURVIVE 72 in plain
/// words following the ERC 2025 guidelines; it never replaces a doctor or a
/// first aid course, and every screen tells the reader to call 112.
struct MedicalEntry: Identifiable, Hashable {
    let id: String
    let category: MedicalCategory
    let title: String
    let summary: String
    let steps: [String]
    let keywords: [String]
    var status: MedicalVerificationStatus = .notReviewedByDoctor

    var requiresVerification: Bool { status.requiresVerification }

    /// Text used by local search: title, summary, steps and keywords.
    var searchableText: String {
        ([title, summary] + steps + keywords).joined(separator: " ")
    }
}
