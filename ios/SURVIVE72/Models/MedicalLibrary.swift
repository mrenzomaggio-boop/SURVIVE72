import Foundation

/// Local, in-memory search and filtering over the bundled medical entries.
/// No network and no index on disk.
struct MedicalLibrary {
    /// Shown in the Medical list and in every entry page.
    static let emergencyNotice = String(localized: "For immediate danger, contact local emergency services when available.")

    let entries: [MedicalEntry]

    init(entries: [MedicalEntry] = MedicalLibraryContent.entries) {
        self.entries = entries
    }

    /// Returns the entries that match both the category (nil = all) and the query.
    ///
    /// - The query is split into words; every word must appear in the title,
    ///   summary or keywords (AND search).
    /// - Matching ignores case and accents.
    /// - An empty or whitespace-only query matches everything.
    /// - The original order of the entries is preserved.
    func search(_ query: String, in category: MedicalCategory? = nil) -> [MedicalEntry] {
        let terms = Self.terms(from: query)
        return entries.filter { entry in
            if let category, entry.category != category { return false }
            guard !terms.isEmpty else { return true }
            let text = Self.normalize(entry.searchableText)
            return terms.allSatisfy { text.contains($0) }
        }
    }

    /// Number of entries in a category (nil = all), ignoring any query.
    func count(in category: MedicalCategory?) -> Int {
        guard let category else { return entries.count }
        return entries.filter { $0.category == category }.count
    }

    static func terms(from query: String) -> [String] {
        normalize(query)
            .split(whereSeparator: { $0.isWhitespace })
            .map(String.init)
    }

    static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
