import Foundation

/// Topics of the SURVIVE KNOWLEDGE offline library.
enum KnowledgeCategory: String, CaseIterable, Identifiable, Hashable {
    case water
    case shelter
    case fire
    case food
    case navigation
    case communication

    var id: String { rawValue }

    var title: String {
        switch self {
        case .water: "Water"
        case .shelter: "Shelter"
        case .fire: "Fire"
        case .food: "Food"
        case .navigation: "Navigation"
        case .communication: "Communication"
        }
    }

    /// SF Symbols available on iOS 17.
    var systemImage: String {
        switch self {
        case .water: "drop.fill"
        case .shelter: "house.fill"
        case .fire: "flame.fill"
        case .food: "fork.knife"
        case .navigation: "location.north.line.fill"
        case .communication: "antenna.radiowaves.left.and.right"
        }
    }
}

/// Review state of an article. Everything shipped today is unverified demo text.
enum VerificationStatus: String, Hashable {
    case toBeVerified

    var label: String {
        switch self {
        case .toBeVerified: "TO BE VERIFIED"
        }
    }
}

/// One article of the library, bundled with the app.
struct KnowledgeArticle: Identifiable, Hashable {
    let id: String
    let category: KnowledgeCategory
    let title: String
    let summary: String
    let paragraphs: [String]
    var status: VerificationStatus = .toBeVerified

    /// All searchable text, in one string.
    var searchableText: String {
        ([title, summary] + paragraphs).joined(separator: " ")
    }
}
