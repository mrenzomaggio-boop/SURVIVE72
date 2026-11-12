import Foundation

/// A place saved by the user. Coordinates are typed in by hand:
/// the app never reads the device location.
struct SavedPlace: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var latitude: Double
    var longitude: Double
    var note: String = ""
}

extension SavedPlace {
    /// Tolerant decoding: only name and coordinates are required.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.value(UUID.self, forKey: .id, default: UUID())
        name = try c.decode(String.self, forKey: .name)
        latitude = try c.decode(Double.self, forKey: .latitude)
        longitude = try c.decode(Double.self, forKey: .longitude)
        note = c.value(String.self, forKey: .note, default: "")
    }
}

/// Why a place cannot be saved.
enum PlaceValidationError: Error, Equatable, CaseIterable {
    case emptyName
    case invalidLatitude
    case latitudeOutOfRange
    case invalidLongitude
    case longitudeOutOfRange

    var message: String {
        switch self {
        case .emptyName: String(localized: "Enter a name.")
        case .invalidLatitude: String(localized: "Latitude must be a decimal number, e.g. 45.4642.")
        case .latitudeOutOfRange: String(localized: "Latitude must be between -90 and 90.")
        case .invalidLongitude: String(localized: "Longitude must be a decimal number, e.g. 9.19.")
        case .longitudeOutOfRange: String(localized: "Longitude must be between -180 and 180.")
        }
    }
}

/// Coordinate checks. Pure functions, no location services.
enum CoordinateValidator {
    static let latitudeRange: ClosedRange<Double> = -90...90
    static let longitudeRange: ClosedRange<Double> = -180...180

    static func isValidLatitude(_ value: Double) -> Bool {
        value.isFinite && latitudeRange.contains(value)
    }

    static func isValidLongitude(_ value: Double) -> Bool {
        value.isFinite && longitudeRange.contains(value)
    }

    /// Reads a decimal number typed by the user. Accepts "." or "," as the
    /// decimal separator and an optional sign. Returns nil for anything else.
    static func parse(_ text: String) -> Double? {
        let cleaned = text.trimmed.replacingOccurrences(of: ",", with: ".")
        guard !cleaned.isEmpty,
              cleaned.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == "." || $0 == "-" || $0 == "+") }),
              let value = Double(cleaned), value.isFinite else { return nil }
        return value
    }

    /// Every problem with the typed values, in field order. Empty = valid.
    static func validate(name: String, latitude: String, longitude: String) -> [PlaceValidationError] {
        var errors: [PlaceValidationError] = []
        if name.trimmed.isEmpty { errors.append(.emptyName) }
        if let lat = parse(latitude) {
            if !isValidLatitude(lat) { errors.append(.latitudeOutOfRange) }
        } else {
            errors.append(.invalidLatitude)
        }
        if let lon = parse(longitude) {
            if !isValidLongitude(lon) { errors.append(.longitudeOutOfRange) }
        } else {
            errors.append(.invalidLongitude)
        }
        return errors
    }
}

/// Degrees, minutes and seconds of one coordinate.
struct DMSCoordinate: Equatable {
    let degrees: Int
    let minutes: Int
    /// Rounded to one decimal.
    let seconds: Double
    let hemisphere: Character

    /// e.g. 45° 27′ 51.1″ N
    var text: String {
        "\(degrees)° \(String(format: "%02ld", minutes))′ \(String(format: "%04.1f", seconds))″ \(hemisphere)"
    }
}

/// Coordinate display in decimal degrees and DMS.
enum CoordinateFormat {
    /// Signed decimal degrees with five decimals (about 1 m), e.g. "45.46420".
    static func decimal(_ value: Double) -> String {
        let text = String(format: "%.5f", value)
        // Avoid "-0.00000" for tiny negative values.
        return text == "-0.00000" ? "0.00000" : text
    }

    static func decimal(latitude: Double, longitude: Double) -> String {
        "\(decimal(latitude)), \(decimal(longitude))"
    }

    static func dms(latitude value: Double) -> DMSCoordinate {
        dms(value, positive: "N", negative: "S")
    }

    static func dms(longitude value: Double) -> DMSCoordinate {
        dms(value, positive: "E", negative: "W")
    }

    static func dms(latitude: Double, longitude: Double) -> String {
        "\(dms(latitude: latitude).text), \(dms(longitude: longitude).text)"
    }

    private static func dms(_ value: Double, positive: Character, negative: Character) -> DMSCoordinate {
        // Work in tenths of a second so rounding carries into minutes and degrees
        // (59.96″ becomes 0.0″ of the next minute, never 60.0″).
        let tenths = Int((abs(value) * 36_000).rounded())
        let degrees = tenths / 36_000
        let minutes = (tenths % 36_000) / 600
        let seconds = Double(tenths % 600) / 10
        let hemisphere = (value < 0 && tenths > 0) ? negative : positive
        return DMSCoordinate(degrees: degrees, minutes: minutes, seconds: seconds, hemisphere: hemisphere)
    }
}
