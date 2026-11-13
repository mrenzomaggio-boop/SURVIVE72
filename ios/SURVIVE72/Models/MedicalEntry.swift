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

/// One numbered step of a card, with an SF Symbol drawn next to the text so
/// the action can be understood at a glance.
struct MedicalStep: Hashable {
    let symbol: String
    let text: String
}

/// One first aid card, bundled with the app. Written by SURVIVE 72 in plain
/// words following the ERC 2025 guidelines; it never replaces a doctor or a
/// first aid course, and every screen tells the reader to call 112.
struct MedicalEntry: Identifiable, Hashable {
    let id: String
    let category: MedicalCategory
    let title: String
    let summary: String
    let steps: [MedicalStep]
    let keywords: [String]
    /// Shows the animated chest-compression rhythm (100-120 per minute).
    var showsCompressionRhythm = false
    var status: MedicalVerificationStatus = .notReviewedByDoctor

    var requiresVerification: Bool { status.requiresVerification }

    /// Text used by local search: title, summary, steps and keywords.
    var searchableText: String {
        ([title, summary] + steps.map(\.text) + keywords).joined(separator: " ")
    }
}

/// A drawing of the key action of a card or article, from the asset catalog
/// (light and dark versions), with a description for VoiceOver.
struct Illustration: Hashable {
    let assetName: String
    let description: String
}

/// Which drawing goes with which card or article, by id.
enum IllustrationCatalog {
    static let byID: [String: Illustration] = [
        "medical.cardiac-arrest": Illustration(assetName: "illustration-cpr",
            description: String(localized: "A rescuer kneels next to a person lying on their back, arms straight, hands in the centre of the chest, pushing down.")),
        "medical.choking": Illustration(assetName: "illustration-choking",
            description: String(localized: "Standing behind a person who is bent forward, the rescuer supports the chest with one hand and gives back blows between the shoulder blades with the other.")),
        "medical.recovery-position": Illustration(assetName: "illustration-recovery",
            description: String(localized: "A person lying on their side, head tilted back, hand under the cheek, upper knee bent.")),
        "medical.bleeding": Illustration(assetName: "illustration-tourniquet",
            description: String(localized: "An arm with a wound; the tourniquet is tightened above the wound and a clock reminds you to write down the time.")),
        "medical.burns": Illustration(assetName: "illustration-burns",
            description: String(localized: "A burnt forearm under cool running tap water, with a timer.")),
        "medical.heatstroke": Illustration(assetName: "illustration-heatstroke",
            description: String(localized: "A person lying in the shade of a tree with legs raised, while a rescuer pours cool water on the neck.")),
        "medical.hypothermia": Illustration(assetName: "illustration-hypothermia",
            description: String(localized: "A person sitting in shelter, wrapped in a blanket, holding a warm drink.")),
        "medical.stroke": Illustration(assetName: "illustration-stroke",
            description: String(localized: "A face with one corner of the mouth drooping, next to a phone showing 112.")),
        "medical.anaphylaxis": Illustration(assetName: "illustration-anaphylaxis",
            description: String(localized: "A person sitting on the floor; the auto-injector is pressed against the outer side of the thigh.")),
        "earthquake.what-to-do": Illustration(assetName: "illustration-earthquake",
            description: String(localized: "During the shaking, a person kneels under a sturdy table, one arm protecting the head and neck, the other hand holding a table leg.")),
        "flood.what-to-do": Illustration(assetName: "illustration-flood",
            description: String(localized: "Cross-section of a house: the ground floor is flooded and the person has gone up to the floor above.")),
        "tsunami.what-to-do": Illustration(assetName: "illustration-tsunami",
            description: String(localized: "A wave comes in from the sea while a person runs up the hill to high ground.")),
        "preparedness.kit": Illustration(assetName: "illustration-kit",
            description: String(localized: "An emergency backpack with water, a torch, a first aid kit, a battery radio and documents.")),
    ]

    static func forID(_ id: String) -> Illustration? { byID[id] }
}
