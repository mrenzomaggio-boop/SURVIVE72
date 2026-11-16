import CryptoKit
import Foundation

/// An official alert: a weather warning, an earthquake or a large disaster,
/// taken from public sources (Meteoalarm, INGV, GDACS) and signed by the
/// SURVIVE 72 feed. People cannot write one: the signature is checked on
/// every phone, also when the alert arrives from a nearby phone.
///
/// The feed is made by the "Official alerts" workflow of
/// mrenzomaggio-boop/survive72-maps (folder `alerts`).
struct OfficialAlert: Codable, Hashable, Identifiable {
    enum Severity: String, Codable, CaseIterable, Comparable {
        case moderate, severe, extreme

        var rank: Int {
            switch self {
            case .moderate: 1
            case .severe: 2
            case .extreme: 3
            }
        }

        static func < (lhs: Severity, rhs: Severity) -> Bool { lhs.rank < rhs.rank }
    }

    /// Public key of the feed (Ed25519, raw 32 bytes).
    static let publicKey = Data(base64Encoded: "ClFHF5jd/xxZGPyGQhzEx0LoGNAoqHaeHERL1vnOGnQ=")!
    /// Country value for disasters outside the followed countries.
    static let world = "WORLD"
    /// Small tolerance for phones whose clocks are not set exactly.
    static let clockTolerance: TimeInterval = 10 * 60
    static let maxLifetime: TimeInterval = 10 * 24 * 60 * 60

    let id: String
    /// "meteoalarm", "ingv" or "gdacs".
    let source: String
    /// "weather", "earthquake", "flood", "cyclone", "volcano", "fire", ...
    let kind: String
    /// ISO country code (e.g. "IT"), or `world`.
    let country: String
    let severity: Severity
    let title: String
    let detail: String
    let area: String
    let link: String
    /// Seconds since 1970, as in the feed (whole numbers keep the signed bytes exact).
    let issuedAt: Int64
    let startsAt: Int64
    let expiresAt: Int64
    let signature: Data

    var issuedDate: Date { Date(timeIntervalSince1970: TimeInterval(issuedAt)) }
    var startDate: Date { Date(timeIntervalSince1970: TimeInterval(startsAt)) }
    var expiryDate: Date { Date(timeIntervalSince1970: TimeInterval(expiresAt)) }

    func isExpired(at now: Date) -> Bool { now >= expiryDate }

    /// Name of the source shown under the alert.
    var sourceName: String {
        switch source {
        case "meteoalarm": "Meteoalarm"
        case "ingv": "INGV"
        case "gdacs": "GDACS"
        default: source
        }
    }

    var systemImage: String {
        switch kind {
        case "earthquake": "waveform.path.ecg"
        case "flood": "water.waves"
        case "cyclone": "hurricane"
        case "volcano": "mountain.2.fill"
        case "fire": "flame.fill"
        case "tsunami": "water.waves.and.arrow.up"
        case "drought": "sun.max.fill"
        case "weather": "cloud.bolt.rain.fill"
        default: "exclamationmark.triangle.fill"
        }
    }

    /// Short tag sent in greetings ("I already have this one"): first 9 bytes
    /// of the SHA-256 of the id, base64, so a greeting stays small.
    var shortTag: String { OfficialAlert.shortTag(for: id) }

    static func shortTag(for id: String) -> String {
        Data(SHA256.hash(data: Data(id.utf8)).prefix(9)).base64EncodedString()
    }

    /// Stable id for the notification of this alert.
    var noticeID: UUID {
        let bytes = Array(SHA256.hash(data: Data(("official:" + id).utf8)).prefix(16))
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }

    // MARK: Validate

    /// Checks limits, times and signature. An alert that fails is dropped and never passed on.
    func isValid(at now: Date, key: Data = OfficialAlert.publicKey) -> Bool {
        guard !id.isEmpty, id.utf8.count <= 400, source.utf8.count <= 40, kind.utf8.count <= 40,
              country.utf8.count <= 10, !title.isEmpty, title.utf8.count <= 800,
              detail.utf8.count <= 4_000, area.utf8.count <= 1_600, link.utf8.count <= 1_200
        else { return false }
        guard startsAt >= issuedAt, expiresAt > startsAt, expiresAt > issuedAt,
              TimeInterval(expiresAt - issuedAt) <= OfficialAlert.maxLifetime,
              issuedDate <= now.addingTimeInterval(OfficialAlert.clockTolerance),
              !isExpired(at: now)
        else { return false }
        guard let publicKey = try? Curve25519.Signing.PublicKey(rawRepresentation: key) else { return false }
        return publicKey.isValidSignature(signature, for: signedBytes)
    }

    /// Fixed, length-prefixed layout of every signed field. Must match
    /// `signedBytes` in alerts/sign.js of survive72-maps.
    var signedBytes: Data {
        var data = Data("survive72.official.alert.v1".utf8)
        func append(_ text: String) {
            let field = Data(text.utf8)
            var length = UInt32(field.count).bigEndian
            withUnsafeBytes(of: &length) { data.append(contentsOf: $0) }
            data.append(field)
        }
        for field in [id, source, kind, country, severity.rawValue, title, detail, area, link,
                      String(issuedAt), String(startsAt), String(expiresAt)] {
            append(field)
        }
        return data
    }
}

/// The file published by the feed.
struct OfficialAlertFeed: Codable {
    let version: Int
    let generatedAt: Int64
    let alerts: [OfficialAlert]

    init(version: Int = 1, generatedAt: Int64, alerts: [OfficialAlert]) {
        self.version = version
        self.generatedAt = generatedAt
        self.alerts = alerts
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        version = c.value(Int.self, forKey: .version, default: 1)
        generatedAt = c.value(Int64.self, forKey: .generatedAt, default: 0)
        // One alert this version cannot read does not lose the others.
        alerts = c.lossyArray(OfficialAlert.self, forKey: .alerts)
    }
}
