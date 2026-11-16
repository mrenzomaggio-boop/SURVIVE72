import CryptoKit
import XCTest
@testable import SURVIVE72

/// Signed official alerts made with a test key.
enum OfficialAlertFixtures {
    static let signingKey = Curve25519.Signing.PrivateKey()
    static var publicKey: Data { signingKey.publicKey.rawRepresentation }

    static func alert(_ id: String, country: String = "IT", source: String = "meteoalarm",
                      severity: OfficialAlert.Severity = .severe, issuedAt: Date,
                      lifetime: TimeInterval = 12 * 60 * 60, title: String = "Allerta vento",
                      key: Curve25519.Signing.PrivateKey = OfficialAlertFixtures.signingKey) -> OfficialAlert {
        let issued = Int64(issuedAt.timeIntervalSince1970)
        func make(_ signature: Data) -> OfficialAlert {
            OfficialAlert(id: id, source: source, kind: "weather", country: country, severity: severity,
                          title: title, detail: "Raffiche forti.", area: "Liguria", link: "https://meteoalarm.org",
                          issuedAt: issued, startsAt: issued, expiresAt: issued + Int64(lifetime), signature: signature)
        }
        let unsigned = make(Data())
        return make(try! key.signature(for: unsigned.signedBytes))
    }

    static func feed(_ alerts: [OfficialAlert], at date: Date) -> Data {
        try! JSONEncoder().encode(OfficialAlertFeed(generatedAt: Int64(date.timeIntervalSince1970), alerts: alerts))
    }
}

final class OfficialAlertTests: XCTestCase {
    private typealias F = OfficialAlertFixtures
    private var clock = Date(timeIntervalSince1970: 1_800_000_000)
    private var suites: [String] = []
    private var files: [URL] = []

    override func tearDown() {
        for suite in suites { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        for file in files { try? FileManager.default.removeItem(at: file) }
        suites = []
        files = []
        super.tearDown()
    }

    private func makeStore(fileURL: URL? = nil, notifier: MeshNotifier? = nil,
                           countries: Set<String> = ["IT"],
                           download: @escaping (URL) async throws -> Data = { _ in throw URLError(.notConnectedToInternet) })
        -> OfficialAlertStore {
        let suite = "SURVIVE72Tests.official.\(UUID().uuidString)"
        suites.append(suite)
        let defaults = UserDefaults(suiteName: suite)!
        LocalStorage.save(OfficialAlertPreferences(countries: countries), key: OfficialAlertStore.preferencesKey,
                          to: defaults)
        return OfficialAlertStore(fileURL: fileURL, defaults: defaults, now: { [unowned self] in self.clock },
                                  notifier: notifier, key: F.publicKey, download: download)
    }

    private func tempFile() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("official-\(UUID().uuidString).json")
        files.append(url)
        return url
    }

    // MARK: Signature

    /// Same vector as alerts/test/vector.json in survive72-maps, signed by the
    /// feed's code: the two sides lay out the signed bytes the same way.
    func testAlertSignedByTheFeedVerifies() throws {
        let json = #"""
        {"id":"meteoalarm:abc","source":"meteoalarm","kind":"weather","country":"IT","severity":"severe",
         "title":"Allerta arancione · piogge","detail":"Città: più di 100 mm…","area":"Liguria",
         "link":"https://meteoalarm.org","issuedAt":1794826800,"startsAt":1794855600,"expiresAt":1794898800,
         "signature":"qhIco/XCfK3CHcTfbpfc4D1ExVRsNIAEQbSlC9Ik+BvI+zLjC+0VkLHu7twtWk37jEGmh2m3jXzFDCKEi1MJDA=="}
        """#
        let key = try XCTUnwrap(Data(base64Encoded: "6kpsY+KcUgq+9VB7Ey7F+ZVHdq6+vnuSQh7qaRRG0iw="))
        let alert = try JSONDecoder().decode(OfficialAlert.self, from: Data(json.utf8))
        let during = Date(timeIntervalSince1970: 1_794_830_000)
        XCTAssertTrue(alert.isValid(at: during, key: key))
        XCTAssertFalse(alert.isValid(at: Date(timeIntervalSince1970: 1_794_898_800), key: key), "expired")
        XCTAssertFalse(alert.isValid(at: during, key: F.publicKey), "another key")

        let changed = try JSONDecoder().decode(OfficialAlert.self,
                                               from: Data(json.replacingOccurrences(of: "\"severe\"", with: "\"extreme\"").utf8))
        XCTAssertFalse(changed.isValid(at: during, key: key), "changed after signing")
    }

    func testAlertsFromAnotherKeyOrWithBadTimesAreRefused() {
        let other = Curve25519.Signing.PrivateKey()
        XCTAssertTrue(F.alert("a", issuedAt: clock).isValid(at: clock, key: F.publicKey))
        XCTAssertFalse(F.alert("a", issuedAt: clock, key: other).isValid(at: clock, key: F.publicKey))
        XCTAssertFalse(F.alert("b", issuedAt: clock.addingTimeInterval(3600)).isValid(at: clock, key: F.publicKey),
                       "from the future")
        XCTAssertFalse(F.alert("c", issuedAt: clock, lifetime: 11 * 24 * 3600).isValid(at: clock, key: F.publicKey),
                       "lives too long")
    }

    // MARK: Store

    func testBoardShowsFollowedCountriesStrongestFirst() throws {
        let store = makeStore()
        let feed = F.feed([
            F.alert("it-old", severity: .severe, issuedAt: clock.addingTimeInterval(-7200)),
            F.alert("it-new", severity: .severe, issuedAt: clock.addingTimeInterval(-60)),
            F.alert("it-red", severity: .extreme, issuedAt: clock.addingTimeInterval(-9000)),
            F.alert("de", country: "DE", issuedAt: clock),
            F.alert("world", country: "WORLD", source: "gdacs", issuedAt: clock),
            F.alert("fake", issuedAt: clock, key: Curve25519.Signing.PrivateKey()),
        ], at: clock)
        try store.receiveFeed(feed)

        XCTAssertEqual(store.alerts.count, 5, "the forged one is dropped")
        XCTAssertEqual(store.visible.map(\.id), ["it-red", "world", "it-new", "it-old"])
        store.setShowsWorld(false)
        XCTAssertEqual(store.visible.map(\.id), ["it-red", "it-new", "it-old"])
        store.setFollowed("DE", true)
        XCTAssertEqual(Set(store.visible.map(\.id)), ["it-red", "it-new", "it-old", "de"])
        XCTAssertEqual(store.lastOrigin, .internet)

        // A newer feed replaces the old one: ended alerts disappear.
        try store.receiveFeed(F.feed([F.alert("it-new", issuedAt: clock.addingTimeInterval(-60))], at: clock))
        XCTAssertEqual(store.alerts.keys.sorted(), ["it-new"])

        // Expired alerts leave the board.
        clock = clock.addingTimeInterval(13 * 3600)
        XCTAssertTrue(store.visible.isEmpty)
    }

    func testAlertsSurviveARelaunch() throws {
        let url = tempFile()
        let store = makeStore(fileURL: url)
        try store.receiveFeed(F.feed([F.alert("a", issuedAt: clock)], at: clock))
        let again = makeStore(fileURL: url)
        XCTAssertEqual(again.alerts.keys.sorted(), ["a"])
        XCTAssertEqual(again.lastUpdate, clock)
    }

    @MainActor
    func testRefreshDownloadsTheFeedAndSurvivesNoInternet() async {
        var online = true
        let feed = F.feed([F.alert("a", issuedAt: clock)], at: clock)
        let store = makeStore(download: { url in
            XCTAssertEqual(url, OfficialAlertStore.feedURL)
            guard online else { throw URLError(.notConnectedToInternet) }
            return feed
        })
        await store.refresh()
        XCTAssertEqual(store.alerts.keys.sorted(), ["a"])
        XCTAssertFalse(store.lastDownloadFailed)

        online = false
        await store.refresh(force: true)
        XCTAssertTrue(store.lastDownloadFailed)
        XCTAssertEqual(store.alerts.keys.sorted(), ["a"], "kept without internet")
    }

    func testOnlyNewStrongRecentFollowedAlertsAreNotified() throws {
        let notifier = RecordingMeshNotifier()
        let store = makeStore(notifier: notifier)
        try store.receiveFeed(F.feed([
            F.alert("red", severity: .extreme, issuedAt: clock),
            F.alert("orange", severity: .severe, issuedAt: clock),
            F.alert("yellow", severity: .moderate, issuedAt: clock),
            F.alert("old", severity: .severe, issuedAt: clock.addingTimeInterval(-13 * 3600), lifetime: 20 * 3600),
            F.alert("de", country: "DE", severity: .extreme, issuedAt: clock),
        ], at: clock))
        XCTAssertEqual(notifier.notices.count, 2)
        XCTAssertEqual(notifier.notices.first?.isSOS, true, "red is urgent")
        XCTAssertEqual(notifier.notices.first?.body, "Allerta vento · Liguria")

        // The same alerts again: nothing new.
        try store.receiveFeed(F.feed(store.alerts.values.map { $0 }, at: clock))
        XCTAssertEqual(notifier.notices.count, 2)
    }

    func testPhoneToPhoneExchangeSendsOnlyWhatIsMissing() {
        let a = makeStore()
        let b = makeStore()
        let one = F.alert("one", issuedAt: clock)
        let two = F.alert("two", issuedAt: clock)
        XCTAssertEqual(a.receiveFromNearby([one, two, F.alert("x", issuedAt: clock, key: Curve25519.Signing.PrivateKey())]), 2)
        XCTAssertEqual(a.lastOrigin, .nearbyPhone)
        b.receiveFromNearby([one])

        let missing = a.alertsMissing(from: Set(b.knownTags()))
        XCTAssertEqual(missing.map(\.id), ["two"])
        XCTAssertEqual(b.receiveFromNearby(missing), 1)
        XCTAssertEqual(b.receiveFromNearby(missing), 0, "already there")
    }
}
