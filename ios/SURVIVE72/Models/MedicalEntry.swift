import Foundation

/// Topics of the SURVIVE MEDICAL offline library.
enum MedicalCategory: String, CaseIterable, Identifiable, Hashable {
    case preparedness
    case injuries
    case environment
    case illness
    case supplies
    case records

    var id: String { rawValue }

    var title: String {
        switch self {
        case .preparedness: "Preparedness"
        case .injuries: "Injuries"
        case .environment: "Environment"
        case .illness: "Illness"
        case .supplies: "Supplies"
        case .records: "Records"
        }
    }

    /// SF Symbols available on iOS 17.
    var systemImage: String {
        switch self {
        case .preparedness: "checklist"
        case .injuries: "bandage.fill"
        case .environment: "thermometer.medium"
        case .illness: "heart.text.square.fill"
        case .supplies: "cross.case.fill"
        case .records: "doc.text.fill"
        }
    }
}

/// Review state of a medical entry. Nothing shipped today is verified.
enum MedicalVerificationStatus: String, Hashable {
    case verifiedContentRequired

    var label: String {
        switch self {
        case .verifiedContentRequired: "VERIFIED CONTENT REQUIRED"
        }
    }

    var requiresVerification: Bool {
        switch self {
        case .verifiedContentRequired: true
        }
    }
}

/// One placeholder entry of the medical library, bundled with the app.
/// It holds a neutral topic title and a description of what verified content
/// will later cover: no diagnoses, dosages, procedures or advice.
struct MedicalEntry: Identifiable, Hashable {
    let id: String
    let category: MedicalCategory
    let title: String
    let summary: String
    let keywords: [String]
    var status: MedicalVerificationStatus = .verifiedContentRequired

    var requiresVerification: Bool { status.requiresVerification }

    /// Text used by local search: title, summary and keywords.
    var searchableText: String {
        ([title, summary] + keywords).joined(separator: " ")
    }
}
