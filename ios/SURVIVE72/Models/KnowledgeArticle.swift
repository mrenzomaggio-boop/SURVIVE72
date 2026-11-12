import Foundation

/// Topics of the SURVIVE KNOWLEDGE offline library.
enum KnowledgeCategory: String, CaseIterable, Identifiable, Hashable {
    case earthquake
    case flood
    case tsunami
    case preparedness

    var id: String { rawValue }

    var title: String {
        switch self {
        case .earthquake: String(localized: "Earthquake")
        case .flood: String(localized: "Flood")
        case .tsunami: String(localized: "Tsunami")
        case .preparedness: String(localized: "Preparedness")
        }
    }

    /// SF Symbols available on iOS 17.
    var systemImage: String {
        switch self {
        case .earthquake: "waveform"
        case .flood: "cloud.heavyrain.fill"
        case .tsunami: "water.waves"
        case .preparedness: "backpack.fill"
        }
    }
}

/// Where an article comes from. Shipped articles are adapted from an official
/// public source and always show its credit.
enum VerificationStatus: String, Hashable {
    case officialSource

    var label: String {
        switch self {
        case .officialSource: String(localized: "OFFICIAL SOURCE")
        }
    }
}

/// Credit shown under an article. The text is fixed by the source's licence.
struct ContentSource: Hashable {
    let credit: String
    let licence: String
    let url: URL

    /// "Io non rischio" campaign of the Italian Civil Protection Department,
    /// published under CC BY 4.0 with this mandatory attribution.
    static let ioNonRischio = ContentSource(
        credit: String(localized: "Source: Io non rischio. Dipartimento della Protezione Civile - Presidenza del Consiglio dei Ministri."),
        licence: String(localized: "Adapted and summarised under the CC BY 4.0 licence. Not written by SURVIVE 72."),
        url: URL(string: "https://iononrischio.protezionecivile.gov.it")!)
}

/// One titled block of an article, such as "During" with its points.
struct KnowledgeSection: Hashable {
    let heading: String
    let points: [String]
}

/// One article of the library, bundled with the app.
struct KnowledgeArticle: Identifiable, Hashable {
    let id: String
    let category: KnowledgeCategory
    let title: String
    let summary: String
    let sections: [KnowledgeSection]
    var source: ContentSource = .ioNonRischio
    var status: VerificationStatus = .officialSource

    /// All searchable text, in one string.
    var searchableText: String {
        ([title, summary] + sections.flatMap { [$0.heading] + $0.points }).joined(separator: " ")
    }
}
