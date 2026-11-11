import Foundation

/// Placeholder entries of SURVIVE MEDICAL. Each one only names a neutral topic
/// and says what verified content will later cover. There are no diagnoses,
/// dosages, procedures, treatment steps or medical advice here.
enum MedicalLibraryContent {
    private static func placeholder(_ topic: String) -> String {
        "Placeholder. Verified content reviewed by qualified professionals will later cover general information about \(topic). Nothing here is medical advice."
    }

    static let entries: [MedicalEntry] = [
        MedicalEntry(id: "medical.preparedness.overview", category: .preparedness,
                     title: "Health preparedness overview",
                     summary: placeholder("planning ahead for health needs in an emergency"),
                     keywords: ["planning", "household", "readiness"]),
        MedicalEntry(id: "medical.preparedness.training", category: .preparedness,
                     title: "Training and courses",
                     summary: placeholder("finding recognised first aid training"),
                     keywords: ["course", "learning", "certification"]),
        MedicalEntry(id: "medical.injuries.wounds", category: .injuries,
                     title: "Cuts and wounds",
                     summary: placeholder("this topic"),
                     keywords: ["cut", "wound", "skin"]),
        MedicalEntry(id: "medical.injuries.burns", category: .injuries,
                     title: "Burns",
                     summary: placeholder("this topic"),
                     keywords: ["burn", "skin"]),
        MedicalEntry(id: "medical.injuries.sprains", category: .injuries,
                     title: "Sprains and fractures",
                     summary: placeholder("this topic"),
                     keywords: ["bone", "joint", "fracture"]),
        MedicalEntry(id: "medical.environment.heat", category: .environment,
                     title: "Heat exposure",
                     summary: placeholder("this topic"),
                     keywords: ["hot weather", "temperature", "sun"]),
        MedicalEntry(id: "medical.environment.cold", category: .environment,
                     title: "Cold exposure",
                     summary: placeholder("this topic"),
                     keywords: ["cold weather", "temperature", "winter"]),
        MedicalEntry(id: "medical.illness.hydration", category: .illness,
                     title: "Hydration",
                     summary: placeholder("this topic"),
                     keywords: ["water", "fluids"]),
        MedicalEntry(id: "medical.illness.hygiene", category: .illness,
                     title: "Hygiene and sanitation",
                     summary: placeholder("this topic"),
                     keywords: ["cleanliness", "sanitation", "hands"]),
        MedicalEntry(id: "medical.supplies.kit", category: .supplies,
                     title: "First aid kit contents",
                     summary: placeholder("what a household first aid kit may include"),
                     keywords: ["kit", "supplies", "box"]),
        MedicalEntry(id: "medical.supplies.storage", category: .supplies,
                     title: "Storing medical supplies",
                     summary: placeholder("keeping supplies organised and checking expiry dates"),
                     keywords: ["storage", "expiry", "organisation"]),
        MedicalEntry(id: "medical.records.personal", category: .records,
                     title: "Personal health information",
                     summary: placeholder("keeping your own health information ready on paper"),
                     keywords: ["documents", "records", "paper"])
    ]

    static let ids: Set<String> = Set(entries.map(\.id))
}
