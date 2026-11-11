import XCTest
@testable import SURVIVE72

/// Coordinate validation, parsing and decimal/DMS formatting.
final class CoordinateTests: XCTestCase {
    // MARK: Ranges

    func testLatitudeRangeIncludesLimits() {
        XCTAssertTrue(CoordinateValidator.isValidLatitude(-90))
        XCTAssertTrue(CoordinateValidator.isValidLatitude(0))
        XCTAssertTrue(CoordinateValidator.isValidLatitude(90))
        XCTAssertFalse(CoordinateValidator.isValidLatitude(90.000001))
        XCTAssertFalse(CoordinateValidator.isValidLatitude(-90.5))
        XCTAssertFalse(CoordinateValidator.isValidLatitude(.nan))
        XCTAssertFalse(CoordinateValidator.isValidLatitude(.infinity))
    }

    func testLongitudeRangeIncludesLimits() {
        XCTAssertTrue(CoordinateValidator.isValidLongitude(-180))
        XCTAssertTrue(CoordinateValidator.isValidLongitude(180))
        XCTAssertFalse(CoordinateValidator.isValidLongitude(180.1))
        XCTAssertFalse(CoordinateValidator.isValidLongitude(-181))
        XCTAssertFalse(CoordinateValidator.isValidLongitude(-.infinity))
    }

    // MARK: Parsing

    func testParseAcceptsDotCommaAndSign() {
        XCTAssertEqual(CoordinateValidator.parse("45.4642"), 45.4642)
        XCTAssertEqual(CoordinateValidator.parse(" 45,5 "), 45.5)
        XCTAssertEqual(CoordinateValidator.parse("-12.25"), -12.25)
        XCTAssertEqual(CoordinateValidator.parse("+9"), 9)
    }

    func testParseRejectsNonNumbers() {
        for text in ["", "   ", "abc", "45N", "1e5", "45.1.2", "--1", "nan", "inf", "٤٥"] {
            XCTAssertNil(CoordinateValidator.parse(text), text)
        }
    }

    // MARK: Validation

    func testValidInputHasNoErrors() {
        XCTAssertEqual(CoordinateValidator.validate(name: "Shelter", latitude: "45.46", longitude: "9.19"), [])
        XCTAssertEqual(CoordinateValidator.validate(name: "Pole", latitude: "-90", longitude: "180"), [])
    }

    func testValidationReportsEveryProblemInFieldOrder() {
        XCTAssertEqual(
            CoordinateValidator.validate(name: "  ", latitude: "x", longitude: "y"),
            [.emptyName, .invalidLatitude, .invalidLongitude]
        )
        XCTAssertEqual(
            CoordinateValidator.validate(name: "A", latitude: "91", longitude: "-180.5"),
            [.latitudeOutOfRange, .longitudeOutOfRange]
        )
    }

    func testEveryErrorHasAMessage() {
        for error in PlaceValidationError.allCases {
            XCTAssertFalse(error.message.isEmpty)
        }
    }

    // MARK: Decimal

    func testDecimalFormatUsesFiveDecimalsAndDot() {
        XCTAssertEqual(CoordinateFormat.decimal(45.4642), "45.46420")
        XCTAssertEqual(CoordinateFormat.decimal(-0.1), "-0.10000")
        XCTAssertEqual(CoordinateFormat.decimal(-0.000001), "0.00000")
        XCTAssertEqual(CoordinateFormat.decimal(latitude: 1, longitude: -2), "1.00000, -2.00000")
    }

    // MARK: DMS

    func testDMSOfKnownPoint() {
        // 45.4642 = 45° 27' 51.12"
        let lat = CoordinateFormat.dms(latitude: 45.4642)
        XCTAssertEqual(lat, DMSCoordinate(degrees: 45, minutes: 27, seconds: 51.1, hemisphere: "N"))
        XCTAssertEqual(lat.text, "45° 27′ 51.1″ N")

        // 9.19 = 9° 11' 24"
        XCTAssertEqual(CoordinateFormat.dms(longitude: 9.19).text, "9° 11′ 24.0″ E")
    }

    func testDMSHemispheres() {
        XCTAssertEqual(CoordinateFormat.dms(latitude: -33.8688).hemisphere, "S")
        XCTAssertEqual(CoordinateFormat.dms(longitude: -70.6693).hemisphere, "W")
        XCTAssertEqual(CoordinateFormat.dms(latitude: 0).hemisphere, "N")
        XCTAssertEqual(CoordinateFormat.dms(longitude: 0).hemisphere, "E")
    }

    func testDMSSouthWestValues() {
        // -33.8688 = 33° 52' 7.68" S
        XCTAssertEqual(CoordinateFormat.dms(latitude: -33.8688).text, "33° 52′ 07.7″ S")
        // -70.6693 = 70° 40' 9.48" W
        XCTAssertEqual(CoordinateFormat.dms(longitude: -70.6693).text, "70° 40′ 09.5″ W")
    }

    func testDMSRoundingCarriesOver() {
        // 10.99999 = 10° 59' 59.964" -> rounds to 11° 00' 00.0"
        XCTAssertEqual(CoordinateFormat.dms(latitude: 10.99999),
                       DMSCoordinate(degrees: 11, minutes: 0, seconds: 0, hemisphere: "N"))
        XCTAssertEqual(CoordinateFormat.dms(longitude: 179.999999).text, "180° 00′ 00.0″ E")
    }

    func testDMSLimits() {
        XCTAssertEqual(CoordinateFormat.dms(latitude: 90).text, "90° 00′ 00.0″ N")
        XCTAssertEqual(CoordinateFormat.dms(latitude: -90).text, "90° 00′ 00.0″ S")
        XCTAssertEqual(CoordinateFormat.dms(longitude: -180).text, "180° 00′ 00.0″ W")
    }

    func testTinyNegativeValueIsNotSouth() {
        XCTAssertEqual(CoordinateFormat.dms(latitude: -0.000001).text, "0° 00′ 00.0″ N")
    }

    func testDMSPair() {
        XCTAssertEqual(CoordinateFormat.dms(latitude: 45.4642, longitude: 9.19),
                       "45° 27′ 51.1″ N, 9° 11′ 24.0″ E")
    }

    func testDMSRoundTripWithinOneTenthOfSecond() {
        for value in stride(from: -90.0, through: 90.0, by: 7.123457) {
            let dms = CoordinateFormat.dms(latitude: value)
            let back = (Double(dms.degrees) + Double(dms.minutes) / 60 + dms.seconds / 3600)
                * (dms.hemisphere == "S" ? -1 : 1)
            XCTAssertEqual(back, value, accuracy: 0.05 / 3600 + 1e-9, "\(value)")
            XCTAssertLessThan(dms.minutes, 60)
            XCTAssertLessThan(dms.seconds, 60)
        }
    }
}
