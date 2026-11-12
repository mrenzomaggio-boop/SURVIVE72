import XCTest
@testable import SURVIVE72

/// Radio guide filters and content rules.
final class RadioGuideTests: XCTestCase {
    private let sample = [
        RadioGuideEntry(id: "a", topic: .basics, title: "Why a radio", summary: "Networks down.",
                        points: ["Listen to public stations."]),
        RadioGuideEntry(id: "b", topic: .power, title: "Batteries", summary: "Spare batteries.",
                        points: ["Store spares."]),
        RadioGuideEntry(id: "c", topic: .power, title: "Hand-crank", summary: "Alternative power.",
                        points: ["Practise using the crank."])
    ]

    private var guide: RadioGuide { RadioGuide(entries: sample) }
    private func ids(_ entries: [RadioGuideEntry]) -> [String] { entries.map(\.id) }

    func testNoFilterReturnsAll() {
        XCTAssertEqual(ids(guide.filter("")), ["a", "b", "c"])
    }

    func testTopicFilter() {
        XCTAssertEqual(ids(guide.filter("", topic: .power)), ["b", "c"])
        XCTAssertEqual(ids(guide.filter("", topic: .basics)), ["a"])
        XCTAssertTrue(guide.filter("", topic: .rules).isEmpty)
    }

    func testSearchInTitleSummaryAndPoints() {
        XCTAssertEqual(ids(guide.filter("BATTERIES")), ["b"])
        XCTAssertEqual(ids(guide.filter("networks")), ["a"])
        XCTAssertEqual(ids(guide.filter("crank practise")), ["c"])
    }

    func testTopicAndSearchCombined() {
        XCTAssertEqual(ids(guide.filter("spare", topic: .power)), ["b"])
        XCTAssertTrue(guide.filter("spare", topic: .basics).isEmpty)
    }

    func testNoMatch() {
        XCTAssertTrue(guide.filter("satellite").isEmpty)
    }

    func testCounts() {
        XCTAssertEqual(guide.count(in: nil), 3)
        XCTAssertEqual(guide.count(in: .power), 2)
        XCTAssertEqual(guide.count(in: .equipment), 0)
    }

    // MARK: Bundled content

    func testEveryTopicHasEntriesAndIDsAreUnique() {
        let entries = RadioGuideContent.entries
        XCTAssertEqual(Set(entries.map(\.id)).count, entries.count)
        for topic in RadioTopic.allCases {
            XCTAssertGreaterThan(RadioGuide().count(in: topic), 0, "\(topic) has no entries")
        }
    }

    func testContentHasNoSpecificFrequencies() {
        let units = ["hz", "khz", "mhz", "ghz", "frequency", "frequencies", "channel"]
        for entry in RadioGuideContent.entries {
            let words = KnowledgeLibrary.normalize(entry.searchableText)
                .split(whereSeparator: { !$0.isLetter && !$0.isNumber })
                .map(String.init)
            for unit in units {
                XCTAssertFalse(words.contains(unit), "\(entry.id) mentions \(unit)")
            }
            XCTAssertNil(entry.searchableText.range(of: #"\d"#, options: .regularExpression),
                         "\(entry.id) contains a number")
        }
    }

    // MARK: Frequencies and streams

    func testFrequencyIDsAreUniqueAndFieldsFilled() {
        let items = RadioFrequencyContent.frequencies
        XCTAssertEqual(Set(items.map(\.id)).count, items.count)
        for item in items {
            XCTAssertFalse(item.name.isEmpty, item.id)
            XCTAssertFalse(item.frequency.isEmpty, item.id)
            XCTAssertFalse(item.use.isEmpty, item.id)
        }
    }

    func testKeyFrequencies() {
        let byID = Dictionary(uniqueKeysWithValues: RadioFrequencyContent.frequencies.map { ($0.id, $0) })
        XCTAssertEqual(byID["rai.isoradio"]?.frequency, "103.3 MHz FM")
        XCTAssertEqual(byID["cb.9"]?.frequency, "27.065 MHz")
        XCTAssertEqual(byID["ham.vhf"]?.frequency, "145.500 MHz FM")
        XCTAssertEqual(byID["marine.16"]?.frequency, "156.800 MHz")
    }

    func testOnlyPMR446IsLicenceFree() {
        for item in RadioFrequencyContent.frequencies {
            XCTAssertEqual(item.rule.canTransmitFreely, item.id.hasPrefix("pmr."), item.id)
        }
        XCTAssertTrue(RadioFrequencyContent.notice.contains("This app never transmits"))
    }

    func testStreamsUseOfficialHTTPSSites() {
        let allowedHosts: Set<String> = ["www.raiplaysound.it", "www.protezionecivile.gov.it"]
        XCTAssertFalse(RadioFrequencyContent.streams.isEmpty)
        for stream in RadioFrequencyContent.streams {
            XCTAssertEqual(stream.url.scheme, "https", stream.id)
            XCTAssertTrue(allowedHosts.contains(stream.url.host ?? ""), stream.id)
        }
    }
}
