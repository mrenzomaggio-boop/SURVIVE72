import Foundation
import Observation

/// What the user follows on the alert board.
struct OfficialAlertPreferences: Codable, Equatable {
    /// ISO country codes, e.g. ["IT"].
    var countries: Set<String>
    /// Also show large disasters in the rest of the world.
    var showsWorld: Bool = true

    init(countries: Set<String>, showsWorld: Bool = true) {
        self.countries = countries
        self.showsWorld = showsWorld
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        countries = c.value(Set<String>.self, forKey: .countries, default: [])
        showsWorld = c.value(Bool.self, forKey: .showsWorld, default: true)
    }

    /// The country of the iPhone, or Italy.
    static var initial: OfficialAlertPreferences {
        let region = Locale.current.region?.identifier ?? "IT"
        let country = OfficialAlertCountries.codes.contains(region) ? region : "IT"
        return OfficialAlertPreferences(countries: [country])
    }
}

/// Countries with official alerts in the feed (Meteoalarm, plus INGV for Italy).
enum OfficialAlertCountries {
    static let codes: [String] = [
        "AT", "BA", "BE", "BG", "CH", "CY", "CZ", "DE", "DK", "EE", "ES", "FI", "FR", "GB", "GR", "HR", "HU",
        "IE", "IL", "IS", "IT", "LT", "LU", "LV", "MD", "ME", "MK", "MT", "NL", "NO", "PL", "PT", "RO", "RS",
        "SE", "SI", "SK", "UA",
    ]

    static func name(_ code: String) -> String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }

    /// Codes sorted by their name in the user's language.
    static var sorted: [String] {
        codes.sorted { name($0).localizedCaseInsensitiveCompare(name($1)) == .orderedAscending }
    }
}

/// Official alerts kept on this phone.
///
/// They come from the internet when there is a connection, and from nearby
/// phones through the phone-to-phone network when there is not. Every alert
/// is checked against the feed's signature before it is kept or passed on.
@Observable
final class OfficialAlertStore {
    static let feedURL = URL(string: "https://github.com/mrenzomaggio-boop/survive72-maps/releases/download/alerts/official-alerts.json")!
    static let preferencesKey = "survive72.officialAlerts.preferences.v1"
    static let fileName = "official-alerts.v1.json"
    /// Alerts kept at most; the ones closest to expiry go first.
    static let capacity = 400
    /// Minimum time between two downloads.
    static let refreshInterval: TimeInterval = 10 * 60

    enum Origin: Equatable {
        case internet
        case nearbyPhone
    }

    private(set) var alerts: [String: OfficialAlert] = [:]
    private(set) var preferences: OfficialAlertPreferences
    /// When alerts last arrived, and from where.
    private(set) var lastUpdate: Date?
    private(set) var lastOrigin: Origin?
    private(set) var isRefreshing = false
    /// True when the last download did not work (no internet, server down).
    private(set) var lastDownloadFailed = false

    private let fileURL: URL?
    private let defaults: UserDefaults
    private let now: () -> Date
    private let notifier: MeshNotifier?
    private let key: Data
    private let download: (URL) async throws -> Data
    private var lastAttempt: Date?

    init(fileURL: URL? = OfficialAlertStore.defaultFileURL(),
         defaults: UserDefaults = .standard,
         now: @escaping () -> Date = Date.init,
         notifier: MeshNotifier? = nil,
         key: Data = OfficialAlert.publicKey,
         download: @escaping (URL) async throws -> Data = OfficialAlertStore.urlSessionDownload) {
        self.fileURL = fileURL
        self.defaults = defaults
        self.now = now
        self.notifier = notifier
        self.key = key
        self.download = download
        preferences = LocalStorage.load(OfficialAlertPreferences.self, key: OfficialAlertStore.preferencesKey,
                                        from: defaults) ?? .initial

        if let fileURL, let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode(OfficialAlertFeed.self, from: data) {
            let current = now()
            for alert in saved.alerts where alert.isValid(at: current, key: key) {
                alerts[alert.id] = alert
            }
            if saved.generatedAt > 0 {
                lastUpdate = Date(timeIntervalSince1970: TimeInterval(saved.generatedAt))
            }
        }
    }

    static func defaultFileURL() -> URL? {
        guard let folder = try? FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        else { return nil }
        return folder.appendingPathComponent(fileName)
    }

    static func urlSessionDownload(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 20)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return data
    }

    // MARK: Read

    /// The board: alerts for the followed countries (and the world, if chosen),
    /// strongest first, then newest.
    var visible: [OfficialAlert] {
        let current = now()
        return alerts.values
            .filter { !$0.isExpired(at: current) && isFollowed($0) }
            .sorted {
                if $0.severity != $1.severity { return $0.severity > $1.severity }
                if $0.issuedAt != $1.issuedAt { return $0.issuedAt > $1.issuedAt }
                return $0.id < $1.id
            }
    }

    func isFollowed(_ alert: OfficialAlert) -> Bool {
        if preferences.countries.contains(alert.country) { return true }
        // Disasters elsewhere: only the large ones (GDACS) when the world is followed.
        return preferences.showsWorld && alert.source == "gdacs"
    }

    // MARK: Preferences

    func setFollowed(_ country: String, _ isFollowed: Bool) {
        if isFollowed {
            preferences.countries.insert(country)
        } else {
            preferences.countries.remove(country)
        }
        LocalStorage.save(preferences, key: OfficialAlertStore.preferencesKey, to: defaults)
    }

    func setShowsWorld(_ shows: Bool) {
        preferences.showsWorld = shows
        LocalStorage.save(preferences, key: OfficialAlertStore.preferencesKey, to: defaults)
    }

    func requestNotificationPermission() {
        notifier?.requestPermission()
    }

    // MARK: Internet

    /// Downloads the feed, unless it was tried a short time ago (`force` skips that).
    /// Without internet nothing changes: alerts can still come from nearby phones.
    @MainActor
    func refresh(force: Bool = false) async {
        let current = now()
        if !force, let lastAttempt, current.timeIntervalSince(lastAttempt) < OfficialAlertStore.refreshInterval {
            return
        }
        guard !isRefreshing else { return }
        lastAttempt = current
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let data = try await download(OfficialAlertStore.feedURL)
            try receiveFeed(data)
            lastDownloadFailed = false
        } catch {
            lastDownloadFailed = true
        }
    }

    /// Takes a downloaded feed. It is the newest picture of the sources, so
    /// alerts no longer in it (ended or replaced) are removed.
    func receiveFeed(_ data: Data) throws {
        let feed = try JSONDecoder().decode(OfficialAlertFeed.self, from: data)
        let current = now()
        let valid = feed.alerts.filter { $0.isValid(at: current, key: key) }
        let fresh = valid.filter { alerts[$0.id] == nil }
        var updated: [String: OfficialAlert] = [:]
        for alert in valid { updated[alert.id] = alert }
        alerts = updated
        enforceCapacity()
        lastUpdate = feed.generatedAt > 0 ? Date(timeIntervalSince1970: TimeInterval(feed.generatedAt)) : current
        lastOrigin = .internet
        save(generatedAt: feed.generatedAt)
        notify(about: fresh)
    }

    // MARK: Phone to phone

    /// Short tags of the alerts on this phone, for the greeting to nearby phones.
    func knownTags() -> [String] {
        let current = now()
        return alerts.values.filter { !$0.isExpired(at: current) }.map(\.shortTag).sorted()
    }

    /// Alerts a nearby phone does not have yet.
    func alertsMissing(from tags: Set<String>) -> [OfficialAlert] {
        let current = now()
        return alerts.values
            .filter { !$0.isExpired(at: current) && !tags.contains($0.shortTag) }
            .sorted { $0.severity != $1.severity ? $0.severity > $1.severity : $0.issuedAt > $1.issuedAt }
    }

    /// Alerts from a nearby phone. Returns how many were new and valid.
    @discardableResult
    func receiveFromNearby(_ incoming: [OfficialAlert]) -> Int {
        let current = now()
        let fresh = incoming.filter { alerts[$0.id] == nil && $0.isValid(at: current, key: key) }
        guard !fresh.isEmpty else { return 0 }
        for alert in fresh { alerts[alert.id] = alert }
        enforceCapacity()
        lastUpdate = current
        lastOrigin = .nearbyPhone
        save(generatedAt: Int64(current.timeIntervalSince1970))
        notify(about: fresh)
        return fresh.count
    }

    // MARK: Private

    private func enforceCapacity() {
        let current = now()
        alerts = alerts.filter { !$0.value.isExpired(at: current) }
        guard alerts.count > OfficialAlertStore.capacity else { return }
        // Keep the strongest; among equals, the ones that last longer.
        let kept = alerts.values.sorted {
            $0.severity != $1.severity ? $0.severity > $1.severity : $0.expiresAt > $1.expiresAt
        }.prefix(OfficialAlertStore.capacity)
        alerts = Dictionary(uniqueKeysWithValues: kept.map { ($0.id, $0) })
    }

    /// A notification for new severe or extreme alerts in the followed places,
    /// issued in the last 12 hours. Older ones (e.g. on the first download) only
    /// appear on the board.
    private func notify(about fresh: [OfficialAlert]) {
        guard let notifier else { return }
        let recent = now().addingTimeInterval(-12 * 60 * 60)
        let worth = fresh
            .filter { $0.severity >= .severe && isFollowed($0) && $0.issuedDate >= recent }
            .sorted { $0.severity != $1.severity ? $0.severity > $1.severity : $0.issuedAt > $1.issuedAt }
        for alert in worth.prefix(3) {
            let body = alert.area.isEmpty ? alert.title : "\(alert.title) · \(alert.area)"
            notifier.post(MeshNotice(id: alert.noticeID, title: String(localized: "Official alert · \(alert.sourceName)"),
                                     body: body, isSOS: alert.severity == .extreme))
        }
        if worth.count > 3 {
            notifier.post(MeshNotice(id: UUID(), title: String(localized: "Official alerts"),
                                     body: String(localized: "\(worth.count - 3) more new alerts on the board."),
                                     isSOS: false))
        }
    }

    private func save(generatedAt: Int64) {
        guard let fileURL else { return }
        let feed = OfficialAlertFeed(generatedAt: generatedAt, alerts: Array(alerts.values))
        guard let data = try? JSONEncoder().encode(feed) else { return }
        try? data.write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
    }
}
