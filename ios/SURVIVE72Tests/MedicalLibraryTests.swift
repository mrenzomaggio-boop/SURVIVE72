import XCTest
@testable import SURVIVE72

/// Search, filters and content safety checks for SURVIVE MEDICAL.
final class MedicalLibraryTests: XCTestCase {
    private let library = MedicalLibrary()

    private let sample = MedicalLibrary(entries: [
        MedicalEntry(id: "a", category: .injuries, title: "Brûlures", summary: "Card one.",
                     steps: ["Press firmly."], keywords: ["alpha"]),
        MedicalEntry(id: "b", category: .environment, title: "Heat", summary: "Card two.",
                     steps: ["Move to shade."], keywords: ["Café", "beta"]),
        MedicalEntry(id: "c", category: .injuries, title: "Wounds", summary: "Card three.",
                     steps: ["Cover the wound."], keywords: ["beta"])
    ])

    // MARK: Search

    func testSearchMatchesTitle() {
        XCTAssertEqual(library.search("burns").map(\.id), ["medical.burns"])
    }

    func testSearchMatchesKeywords() {
        XCTAssertEqual(sample.search("alpha").map(\.id), ["a"])
        XCTAssertEqual(sample.search("beta").map(\.id), ["b", "c"])
    }

    func testSearchMatchesSummary() {
        XCTAssertEqual(sample.search("three").map(\.id), ["c"])
    }

    func testSearchMatchesSteps() {
        XCTAssertEqual(sample.search("shade").map(\.id), ["b"])
        XCTAssertEqual(library.search("tourniquet").map(\.id), ["medical.bleeding"])
    }

    func testSearchWithNoMatchIsEmpty() {
        XCTAssertTrue(library.search("zzzz-no-such-topic").isEmpty)
        XCTAssertTrue(sample.search("gamma").isEmpty)
    }

    func testSearchIgnoresCase() {
        XCTAssertEqual(sample.search("WOUNDS").map(\.id), ["c"])
        XCTAssertEqual(library.search("HEATSTROKE").map(\.id), ["medical.heatstroke"])
    }

    func testSearchIgnoresDiacritics() {
        XCTAssertEqual(sample.search("brulures").map(\.id), ["a"])
        XCTAssertEqual(sample.search("cafe").map(\.id), ["b"])
        XCTAssertEqual(sample.search("CAFÉ").map(\.id), ["b"])
    }

    func testAllWordsMustMatch() {
        XCTAssertEqual(sample.search("beta heat").map(\.id), ["b"])
        XCTAssertTrue(sample.search("beta alpha").isEmpty)
    }

    func testEmptyQueryReturnsEverythingInOrder() {
        XCTAssertEqual(library.search("").map(\.id), MedicalLibraryContent.entries.map(\.id))
        XCTAssertEqual(library.search("   \n").count, MedicalLibraryContent.entries.count)
    }

    // MARK: Filters

    func testCategoryFilter() {
        let results = library.search("", in: .injuries)
        XCTAssertFalse(results.isEmpty)
        XCTAssertTrue(results.allSatisfy { $0.category == .injuries })
        XCTAssertEqual(results.count, library.count(in: .injuries))
    }

    func testCategoryFilterCombinedWithSearch() {
        XCTAssertEqual(sample.search("beta", in: .injuries).map(\.id), ["c"])
        XCTAssertEqual(sample.search("beta", in: .environment).map(\.id), ["b"])
        XCTAssertTrue(sample.search("alpha", in: .environment).isEmpty)
        XCTAssertEqual(library.search("temperature", in: .environment).count, 2)
        XCTAssertTrue(library.search("burns", in: .environment).isEmpty)
    }

    func testAllCategoriesFilter() {
        XCTAssertEqual(library.search("", in: nil).count, library.count(in: nil))
        XCTAssertEqual(library.count(in: nil), MedicalLibraryContent.entries.count)
        let perCategory = MedicalCategory.allCases.map { library.count(in: $0) }.reduce(0, +)
        XCTAssertEqual(perCategory, library.count(in: nil))
    }

    func testEveryCategoryHasEntries() {
        for category in MedicalCategory.allCases {
            XCTAssertGreaterThan(library.count(in: category), 0, category.rawValue)
        }
    }

    // MARK: Content

    func testEveryEntryIsMarkedNotReviewedByADoctor() {
        XCTAssertFalse(MedicalLibraryContent.entries.isEmpty)
        for entry in MedicalLibraryContent.entries {
            XCTAssertTrue(entry.requiresVerification, entry.id)
            XCTAssertEqual(entry.status, .notReviewedByDoctor, entry.id)
            XCTAssertEqual(entry.status.label, "NOT YET REVIEWED BY A DOCTOR")
        }
    }

    func testEveryEntryHasStepsAndPointsTo112() {
        for entry in MedicalLibraryContent.entries {
            XCTAssertFalse(entry.steps.isEmpty, entry.id)
            XCTAssertTrue(entry.steps.contains { $0.contains("112") }, "\(entry.id) never mentions 112")
        }
    }

    func testEntryIDsAreUnique() {
        XCTAssertEqual(MedicalLibraryContent.ids.count, MedicalLibraryContent.entries.count)
    }

    func testEmergencyNoticeAndDisclaimer() {
        XCTAssertEqual(MedicalLibrary.emergencyNotice, "In an emergency, call 112 straight away.")
        XCTAssertTrue(MedicalLibrary.disclaimer.contains("do not replace a doctor"))
        XCTAssertTrue(MedicalLibrary.disclaimer.contains("European Resuscitation Council 2025"))
        XCTAssertTrue(MedicalLibrary.disclaimer.contains("accepts no liability"))
    }
}
