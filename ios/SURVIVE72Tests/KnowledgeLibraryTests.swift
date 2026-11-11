import XCTest
@testable import SURVIVE72

/// Search and filter tests for SURVIVE KNOWLEDGE.
final class KnowledgeLibraryTests: XCTestCase {
    private let sample = [
        KnowledgeArticle(id: "a", category: .water, title: "Rain Collection",
                         summary: "Gathering rainwater.", paragraphs: ["Use clean containers."]),
        KnowledgeArticle(id: "b", category: .water, title: "Storing water",
                         summary: "Household reserves.", paragraphs: ["Label every bottle."]),
        KnowledgeArticle(id: "c", category: .fire, title: "Staying warm",
                         summary: "Blankets and layers.", paragraphs: ["Café break by the stove."]),
        KnowledgeArticle(id: "d", category: .navigation, title: "Compass basics",
                         summary: "Orientation without GPS.", paragraphs: ["Paper maps and bearings."])
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
        XCTAssertEqual(ids(library.search("", in: .water)), ["a", "b"])
        XCTAssertEqual(ids(library.search("", in: .fire)), ["c"])
    }

    func testNilCategoryMeansAll() {
        XCTAssertEqual(library.search("", in: nil).count, 4)
    }

    func testCategoryWithNoArticlesIsEmpty() {
        XCTAssertTrue(library.search("", in: .shelter).isEmpty)
    }

    func testCategoryAndQueryCombined() {
        XCTAssertEqual(ids(library.search("water", in: .water)), ["a", "b"])
        XCTAssertEqual(ids(library.search("warm", in: .water)), [])
        XCTAssertEqual(ids(library.search("warm", in: .fire)), ["c"])
    }

    func testCountsPerCategory() {
        XCTAssertEqual(library.count(in: nil), 4)
        XCTAssertEqual(library.count(in: .water), 2)
        XCTAssertEqual(library.count(in: .communication), 0)
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

    func testBundledContentIsAllMarkedToBeVerified() {
        for article in KnowledgeLibraryContent.articles {
            XCTAssertEqual(article.status, .toBeVerified, article.id)
            XCTAssertEqual(article.status.label, "TO BE VERIFIED")
        }
    }
}
