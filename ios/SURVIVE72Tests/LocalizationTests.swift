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
        XCTAssertEqual(try italian("NOT YET REVIEWED BY A DOCTOR"), "NON ANCORA RIVISTO DA UN MEDICO")
        XCTAssertEqual(try italian("OFFICIAL SOURCE"), "FONTE UFFICIALE")
        XCTAssertEqual(try italian("In an emergency, call 112 straight away."),
                       "In caso di emergenza chiama subito il 112.")
        XCTAssertEqual(try italian("SOS - I need help."), "SOS - Ho bisogno di aiuto.")
    }

    func testSourceCreditKeepsTheWordingRequiredByTheLicence() throws {
        XCTAssertEqual(
            try italian("Source: Io non rischio. Dipartimento della Protezione Civile - Presidenza del Consiglio dei Ministri."),
            "Fonte: Io non rischio. Dipartimento della Protezione Civile - Presidenza del Consiglio dei Ministri.")
    }

    func testContentSectionsAreTranslated() throws {
        XCTAssertEqual(try italian("Earthquake: what to do"), "Terremoto: cosa fare")
        XCTAssertEqual(try italian("Severe bleeding"), "Emorragia grave")
        XCTAssertEqual(try italian("Emergency frequencies (Italy)"), "Frequenze di emergenza (Italia)")
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

/// Home layout: Alert has its own banner and every other section is in the
/// grid exactly once, so no section can disappear from Home. Downloads was
/// removed from Home on purpose: offline map areas are downloaded in Maps.
final class HomeLayoutTests: XCTestCase {
    func testEverySectionIsReachableFromHomeOnce() {
        let shown = [AppSection.alert] + HomeView.gridSections + HomeView.bottomSections
        XCTAssertEqual(shown.count, Set(shown).count)
        XCTAssertEqual(Set(shown), Set(AppSection.allCases).subtracting([.downloads]))
    }

    func testHomeTextsAreTranslated() throws {
        let path = try XCTUnwrap(Bundle.main.path(forResource: "it", ofType: "lproj"))
        let bundle = try XCTUnwrap(Bundle(path: path))
        XCTAssertEqual(bundle.localizedString(forKey: "Ready for the first 72 hours", value: nil, table: nil),
                       "Pronto per le prime 72 ore")
        XCTAssertEqual(bundle.localizedString(forKey: "Alert and SOS", value: nil, table: nil), "Allerta e SOS")
    }
}
