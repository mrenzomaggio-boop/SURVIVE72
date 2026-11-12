import Foundation

/// Placeholder entries of SURVIVE MEDICAL. Each one only names a neutral topic
/// and says what verified content will later cover. There are no diagnoses,
/// dosages, procedures, treatment steps or medical advice here.
enum MedicalLibraryContent {
    private static func placeholder(_ topic: String) -> String {
        String(localized: "Placeholder. Verified content reviewed by qualified professionals will later cover general information about \(topic). Nothing here is medical advice.")
    }

    static let entries: [MedicalEntry] = [
        MedicalEntry(id: "medical.preparedness.overview", category: .preparedness,
                     title: String(localized: "Health preparedness overview"),
                     summary: placeholder(String(localized: "planning ahead for health needs in an emergency")),
                     keywords: [String(localized: "planning"), String(localized: "household"), String(localized: "readiness")]),
        MedicalEntry(id: "medical.preparedness.training", category: .preparedness,
                     title: String(localized: "Training and courses"),
                     summary: placeholder(String(localized: "finding recognised first aid training")),
                     keywords: [String(localized: "course"), String(localized: "learning"), String(localized: "certification")]),
        MedicalEntry(id: "medical.injuries.wounds", category: .injuries,
                     title: String(localized: "Cuts and wounds"),
                     summary: placeholder(String(localized: "this topic")),
                     keywords: [String(localized: "cut"), String(localized: "wound"), String(localized: "skin")]),
        MedicalEntry(id: "medical.injuries.burns", category: .injuries,
                     title: String(localized: "Burns"),
                     summary: placeholder(String(localized: "this topic")),
                     keywords: [String(localized: "burn"), String(localized: "skin")]),
        MedicalEntry(id: "medical.injuries.sprains", category: .injuries,
                     title: String(localized: "Sprains and fractures"),
                     summary: placeholder(String(localized: "this topic")),
                     keywords: [String(localized: "bone"), String(localized: "joint"), String(localized: "fracture")]),
        MedicalEntry(id: "medical.environment.heat", category: .environment,
                     title: String(localized: "Heat exposure"),
                     summary: placeholder(String(localized: "this topic")),
                     keywords: [String(localized: "hot weather"), String(localized: "temperature"), String(localized: "sun")]),
        MedicalEntry(id: "medical.environment.cold", category: .environment,
                     title: String(localized: "Cold exposure"),
                     summary: placeholder(String(localized: "this topic")),
                     keywords: [String(localized: "cold weather"), String(localized: "temperature"), String(localized: "winter")]),
        MedicalEntry(id: "medical.illness.hydration", category: .illness,
                     title: String(localized: "Hydration"),
                     summary: placeholder(String(localized: "this topic")),
                     keywords: [String(localized: "water"), String(localized: "fluids")]),
        MedicalEntry(id: "medical.illness.hygiene", category: .illness,
                     title: String(localized: "Hygiene and sanitation"),
                     summary: placeholder(String(localized: "this topic")),
                     keywords: [String(localized: "cleanliness"), String(localized: "sanitation"), String(localized: "hands")]),
        MedicalEntry(id: "medical.supplies.kit", category: .supplies,
                     title: String(localized: "First aid kit contents"),
                     summary: placeholder(String(localized: "what a household first aid kit may include")),
                     keywords: [String(localized: "kit"), String(localized: "supplies"), String(localized: "box")]),
        MedicalEntry(id: "medical.supplies.storage", category: .supplies,
                     title: String(localized: "Storing medical supplies"),
                     summary: placeholder(String(localized: "keeping supplies organised and checking expiry dates")),
                     keywords: [String(localized: "storage"), String(localized: "expiry"), String(localized: "organisation")]),
        MedicalEntry(id: "medical.records.personal", category: .records,
                     title: String(localized: "Personal health information"),
                     summary: placeholder(String(localized: "keeping your own health information ready on paper")),
                     keywords: [String(localized: "documents"), String(localized: "records"), String(localized: "paper")])
    ]

    static let ids: Set<String> = Set(entries.map(\.id))
}
