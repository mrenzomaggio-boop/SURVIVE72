import XCTest
@testable import SURVIVE72

/// Search and filter tests for SURVIVE KNOWLEDGE.
final class KnowledgeLibraryTests: XCTestCase {
    private static func article(_ id: String, _ category: KnowledgeCategory, _ title: String,
                                _ summary: String, _ point: String) -> KnowledgeArticle {
        KnowledgeArticle(id: id, category: category, title: title, summary: summary,
                         sections: [KnowledgeSection(heading: "Before", points: [point])])
    }

    private let sample = [
        KnowledgeLibraryTests.article("a", .flood, "Rain Collection", "Gathering rainwater.", "Use clean containers."),
        KnowledgeLibraryTests.article("b", .flood, "Storing water", "Household reserves.", "Label every bottle."),
        KnowledgeLibraryTests.article("c", .earthquake, "Staying warm", "Blankets and layers.", "Café break by the stove."),
        KnowledgeLibraryTests.article("d", .tsunami, "Compass basics", "Orientation without GPS.", "Paper maps and bearings.")
    ]

    private var library: KnowledgeLibrary { KnowledgeLibrary(articles: sample) }
    private func ids(_ articles: [KnowledgeArticle]) -> [String] { articles.map(\.id) }

    // MARK: Search

    func testEmptyQueryReturnsAllInOriginalOrder() {
        XCTAssertEqual(ids(library.search("")), ["a", "b", "c", "d"])
    }

    func testWhitespaceOnlyQueryReturnsAll() {
        XCTAssertEqual(ids(library.search("   \n\t ")), ["a", "b", "c", "d"])
    }

    func testTitleMatchIgnoresCase() {
        XCTAssertEqual(ids(library.search("rain collection")), ["a"])
        XCTAssertEqual(ids(library.search("COMPASS")), ["d"])
    }

    func testMatchesSummaryAndBodyText() {
        XCTAssertEqual(ids(library.search("household")), ["b"])   // summary
        XCTAssertEqual(ids(library.search("bearings")), ["d"])    // body
        XCTAssertEqual(library.search("before").count, 4)          // section heading
    }

    func testMatchesPartialWords() {
        XCTAssertEqual(ids(library.search("contain")), ["a"])
    }

    func testIgnoresAccents() {
        XCTAssertEqual(ids(library.search("cafe")), ["c"])
        XCTAssertEqual(ids(library.search("CAFÉ")), ["c"])
    }

    func testAllWordsMustMatch() {
        XCTAssertEqual(ids(library.search("water label")), ["b"])
        XCTAssertEqual(ids(library.search("label compass")), [])
    }

    func testWordOrderAndExtraSpacesDoNotMatter() {
        XCTAssertEqual(ids(library.search("  bottle   storing ")), ["b"])
    }

    func testNoMatchReturnsEmpty() {
        XCTAssertTrue(library.search("helicopter").isEmpty)
    }

    // MARK: Category filter

    func testCategoryFilterWithoutQuery() {
        XCTAssertEqual(ids(library.search("", in: .flood)), ["a", "b"])
        XCTAssertEqual(ids(library.search("", in: .earthquake)), ["c"])
    }

    func testNilCategoryMeansAll() {
        XCTAssertEqual(library.search("", in: nil).count, 4)
    }

    func testCategoryWithNoArticlesIsEmpty() {
        XCTAssertTrue(library.search("", in: .preparedness).isEmpty)
    }

    func testCategoryAndQueryCombined() {
        XCTAssertEqual(ids(library.search("water", in: .flood)), ["a", "b"])
        XCTAssertEqual(ids(library.search("warm", in: .flood)), [])
        XCTAssertEqual(ids(library.search("warm", in: .earthquake)), ["c"])
    }

    func testCountsPerCategory() {
        XCTAssertEqual(library.count(in: nil), 4)
        XCTAssertEqual(library.count(in: .flood), 2)
        XCTAssertEqual(library.count(in: .preparedness), 0)
    }

    // MARK: Bundled content

    func testBundledContentCoversEveryCategoryWithUniqueIDs() {
        let articles = KnowledgeLibraryContent.articles
        XCTAssertEqual(Set(articles.map(\.id)).count, articles.count, "Article IDs must be unique")
        for category in KnowledgeCategory.allCases {
            XCTAssertFalse(KnowledgeLibrary().search("", in: category).isEmpty,
                           "\(category) has no articles")
        }
    }

    func testBundledContentCreditsTheOfficialSource() {
        for article in KnowledgeLibraryContent.articles {
            XCTAssertEqual(article.status, .officialSource, article.id)
            XCTAssertEqual(article.status.label, "OFFICIAL SOURCE")
            XCTAssertEqual(article.source, .ioNonRischio, article.id)
            XCTAssertFalse(article.sections.isEmpty, article.id)
            for section in article.sections {
                XCTAssertFalse(section.points.isEmpty, "\(article.id) / \(section.heading)")
            }
        }
    }

    func testCreditUsesTheWordingRequiredByTheLicence() {
        let source = ContentSource.ioNonRischio
        XCTAssertEqual(source.credit,
                       "Source: Io non rischio. Dipartimento della Protezione Civile - Presidenza del Consiglio dei Ministri.")
        XCTAssertTrue(source.licence.contains("CC BY 4.0"))
        XCTAssertTrue(source.licence.contains("Not written by SURVIVE 72"))
        XCTAssertEqual(source.url.host, "iononrischio.protezionecivile.gov.it")
    }

    func testBundledContentIsSearchable() {
        XCTAssertEqual(KnowledgeLibrary().search("tsunami").map(\.id), ["tsunami.what-to-do"])
        XCTAssertTrue(KnowledgeLibrary().search("load-bearing").map(\.id).contains("earthquake.what-to-do"))
    }
}
