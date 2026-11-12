import XCTest
@testable import SURVIVE72

/// The Italian string catalog is compiled into the app and covers key texts,
/// including plural and formatted ones. Tests run in English, so the English
/// texts used by the other tests are unchanged.
final class LocalizationTests: XCTestCase {
    private func italianBundle() throws -> Bundle {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "it", ofType: "lproj"),
                                 "it.lproj is missing from the app bundle")
        return try XCTUnwrap(Bundle(path: path))
    }

    private func italian(_ key: String) throws -> String {
        try italianBundle().localizedString(forKey: key, value: "MISSING", table: nil)
    }

    func testSectionTitlesAreTranslated() throws {
        XCTAssertEqual(try italian("Settings"), "Impostazioni")
        XCTAssertEqual(try italian("Tools"), "Strumenti")
        XCTAssertEqual(try italian("Maps"), "Mappe")
    }

    func testSafetyWordingIsTranslated() throws {
        XCTAssertEqual(try italian("NOT SENT · NO EMERGENCY SERVICE CONTACTED"),
                       "NON INVIATO · NESSUN SERVIZIO DI EMERGENZA CONTATTATO")
        XCTAssertEqual(try italian("LOCAL DEMO · NOT TRANSMITTED"), "DEMO LOCALE · NON TRASMESSO")
        XCTAssertEqual(try italian("VERIFIED CONTENT REQUIRED"), "SERVE CONTENUTO VERIFICATO")
        XCTAssertEqual(try italian("TO BE VERIFIED"), "DA VERIFICARE")
        XCTAssertEqual(try italian("SOS - I need help."), "SOS - Ho bisogno di aiuto.")
    }

    func testFormattedStringsKeepTheirArguments() throws {
        let format = try italian("%lld of %lld items packed, %lld percent")
        XCTAssertEqual(String(format: format, locale: Locale(identifier: "it"), 5, 20, 25),
                       "5 di 20 oggetti pronti, 25 per cento")

        let name = try italian("Name: %@")
        XCTAssertEqual(String(format: name, "Ada"), "Nome: Ada")
    }

    func testEnglishStaysTheDevelopmentLanguage() {
        XCTAssertEqual(Bundle.main.developmentLocalization, "en")
        XCTAssertEqual(AppSection.settings.title, "Settings")
    }
}
