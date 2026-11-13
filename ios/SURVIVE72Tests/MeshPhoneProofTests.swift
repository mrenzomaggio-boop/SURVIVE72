import XCTest
@testable import SURVIVE72

/// The proof format shared with the server (firebase/functions/proof.js).
final class MeshPhoneProofTests: XCTestCase {
    // Fixed vector produced by firebase/functions/test/proof.test.js:
    // server seed = 32 × 0x07, mesh signing key = 32 × 0x09, number +393331234567.
    private let serverKey = Data(base64Encoded: "6kpsY+KcUgq+9VB7Ey7F+ZVHdq6+vnuSQh7qaRRG0iw=")!
    private let signingKey = Data(repeating: 9, count: 32)
    private let json = #"{"phoneTag":"f0dad71a7b040d8a110836942e5fd3e7","issuedAt":1800000000,"signature":"WyzOWhUt1B9zrZ8IJSrE5cWg6+K6Jx2K4606c2c9LwPwksC9m6txOJfxJYYq14kN2GE5FU6YE0ovF4FVS5ceAw=="}"#
    private let issued = Date(timeIntervalSince1970: 1_800_000_000)

    func testServerProofDecodesAndVerifies() throws {
        let proof = try JSONDecoder().decode(MeshPhoneProof.self, from: Data(json.utf8))
        XCTAssertEqual(proof.phoneTag, MeshPhone.tag(for: "+393331234567"))
        XCTAssertEqual(MeshPhone.tag(for: "333 123 4567"), proof.phoneTag)
        XCTAssertTrue(proof.isValid(for: signingKey, now: issued.addingTimeInterval(60), serverKey: serverKey))
    }

    func testProofIsBoundToKeyServerAndTime() throws {
        let proof = try JSONDecoder().decode(MeshPhoneProof.self, from: Data(json.utf8))
        let later = issued.addingTimeInterval(60)
        XCTAssertFalse(proof.isValid(for: Data(repeating: 8, count: 32), now: later, serverKey: serverKey))
        XCTAssertFalse(proof.isValid(for: signingKey, now: later, serverKey: Data(repeating: 1, count: 32)))
        XCTAssertFalse(proof.isValid(for: signingKey, now: later, serverKey: nil))
        XCTAssertFalse(proof.isValid(for: signingKey, now: issued.addingTimeInterval(MeshPhoneProof.lifetime + 1),
                                     serverKey: serverKey))
        XCTAssertFalse(proof.isValid(for: signingKey, now: issued.addingTimeInterval(-3600), serverKey: serverKey))
    }

    func testCardShowsAVerifiedNumberOnlyWithItsProof() throws {
        let proof = try JSONDecoder().decode(MeshPhoneProof.self, from: Data(json.utf8))
        var card = MeshCard(name: "Dana", signingKey: signingKey, agreementKey: Data(repeating: 3, count: 32),
                            phoneTag: proof.phoneTag)
        let later = issued.addingTimeInterval(60)
        XCTAssertFalse(card.hasVerifiedPhone(now: later, serverKey: serverKey))
        card.phoneProof = proof
        XCTAssertTrue(card.hasVerifiedPhone(now: later, serverKey: serverKey))
        card.phoneTag = MeshPhone.tag(for: "333 000 0000")
        XCTAssertFalse(card.hasVerifiedPhone(now: later, serverKey: serverKey))
    }
}
