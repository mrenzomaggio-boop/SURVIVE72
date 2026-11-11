import Foundation

/// Local, in-memory search and filtering over the bundled articles.
/// No network and no index on disk: the data set is small and ships with the app.
struct KnowledgeLibrary {
    let articles: [KnowledgeArticle]

    init(articles: [KnowledgeArticle] = KnowledgeLibraryContent.articles) {
        self.articles = articles
    }

    /// Returns the articles that match both the category (nil = all) and the query.
    ///
    /// - The query is split into words; every word must appear in the title,
    ///   summary or body (AND search).
    /// - Matching ignores case and accents ("cafe" finds "Café").
    /// - An empty or whitespace-only query matches everything.
    /// - The original order of the articles is preserved.
    func search(_ query: String, in category: KnowledgeCategory? = nil) -> [KnowledgeArticle] {
        let terms = Self.terms(from: query)
        return articles.filter { article in
            if let category, article.category != category { return false }
            guard !terms.isEmpty else { return true }
            let text = Self.normalize(article.searchableText)
            return terms.allSatisfy { text.contains($0) }
        }
    }

    /// Number of articles in a category (nil = all), ignoring any query.
    func count(in category: KnowledgeCategory?) -> Int {
        guard let category else { return articles.count }
        return articles.filter { $0.category == category }.count
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
