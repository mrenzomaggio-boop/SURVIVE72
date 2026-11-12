import XCTest
@testable import SURVIVE72

/// Mesh core: identities, signed packets, encryption and hop-by-hop routing.
/// Phones are simulated by handing packets from one router to another.
final class MeshTests: XCTestCase {
    private let t0 = Date(timeIntervalSince1970: 1_800_000_000)
    private func at(_ seconds: TimeInterval) -> Date { t0.addingTimeInterval(seconds) }

    private let ada = MeshIdentity(name: "Ada")
    private let bob = MeshIdentity(name: "Bob")
    private let cy = MeshIdentity(name: "Cy")

    /// Hands everything `from` would send to `to`, like two phones meeting.
    @discardableResult
    private func meet(_ from: MeshRouter, _ to: inout MeshRouter, now: Date) -> [MeshReceiveResult] {
        from.packetsToSend(excluding: to.knownIDs(now: now), now: now).map { to.receive($0, now: now) }
    }

    // MARK: Identity

    func testCodeIsStableShortAndDifferentPerIdentity() {
        XCTAssertEqual(ada.code, ada.card.code)
        XCTAssertEqual(ada.code.count, 9)
        XCTAssertEqual(Array(ada.code)[4], "-")
        XCTAssertNotEqual(ada.code, bob.code)
    }

    func testIdentityCanBeRestoredFromSavedKeys() throws {
        let restored = try XCTUnwrap(MeshIdentity(name: "Ada", signingKey: ada.signingKeyData,
                                                  agreementKey: ada.agreementKeyData))
        XCTAssertEqual(restored.card, ada.card)
        XCTAssertNil(MeshIdentity(name: "Ada", signingKey: Data([1, 2, 3]), agreementKey: Data()))
    }

    func testTypedCodesAreNormalized() {
        XCTAssertEqual(MeshCode.normalized("7k4p 2qxm"), "7K4P-2QXM")
        XCTAssertEqual(MeshCode.normalized("oIl0-0000"), "0110-0000")
        XCTAssertNil(MeshCode.normalized("123"))
        XCTAssertEqual(MeshCode.normalized(ada.code), ada.code)
    }

    // MARK: Phone numbers

    func testPhoneNumbersAreNormalized() {
        XCTAssertEqual(MeshPhone.normalized("333 123 4567"), "+393331234567")
        XCTAssertEqual(MeshPhone.normalized("+39 333-123.4567"), "+393331234567")
        XCTAssertEqual(MeshPhone.normalized("0039 (333) 1234567"), "+393331234567")
        XCTAssertEqual(MeshPhone.normalized("06 1234567"), "+39061234567")
        XCTAssertEqual(MeshPhone.normalized("+44 7700 900123"), "+447700900123")
        XCTAssertNil(MeshPhone.normalized("12"))
        XCTAssertNil(MeshPhone.normalized("hello"))
        XCTAssertNil(MeshPhone.normalized("+39+333123456"))
    }

    func testPhoneTagHidesTheNumberAndMatchesEveryWayOfWritingIt() throws {
        let tag = try XCTUnwrap(MeshPhone.tag(for: "333 123 4567"))
        XCTAssertEqual(tag, MeshPhone.tag(for: "+393331234567"))
        XCTAssertNotEqual(tag, MeshPhone.tag(for: "333 123 4568"))
        XCTAssertFalse(tag.contains("3331234567"))
        XCTAssertTrue(MeshPhone.isWellFormedTag(tag))
        XCTAssertNil(MeshPhone.tag(for: "x"))
    }

    func testPersonIsFoundByPhoneNumberAcrossTheMesh() throws {
        let dana = MeshIdentity(name: "Dana", phone: "333 123 4567")
        var a = MeshRouter(myCode: dana.code)
        var b = MeshRouter(myCode: bob.code)
        var c = MeshRouter(myCode: cy.code)
        a.submit(try MeshPacket.alert("I am fine", isSOS: false, from: dana, now: t0), now: t0)
        meet(a, &b, now: t0)
        meet(b, &c, now: t0)

        // Cy never met Dana, but finds her by number and can write to her.
        let found = c.cards(forPhone: "+39 333 1234567")
        XCTAssertEqual(found.map { $0.name }, ["Dana"])
        XCTAssertTrue(c.cards(forPhone: "333 000 0000").isEmpty)
        XCTAssertTrue(a.cards(forPhone: "333 123 4567").isEmpty)   // not herself

        let recipient = try XCTUnwrap(found.first)
        let reply = try MeshPacket.direct("Where are you?", to: recipient, from: cy, now: t0)
        c.submit(reply, now: t0)
        meet(c, &b, now: t0)
        meet(b, &a, now: t0)
        XCTAssertEqual(a.inbox(now: t0).first?.directText(for: dana), "Where are you?")
    }

    func testTwoIdentitiesClaimingOneNumberAreBothReported() throws {
        let real = MeshIdentity(name: "Dana", phone: "3331234567")
        let other = MeshIdentity(name: "Not Dana", phone: "3331234567")
        var b = MeshRouter(myCode: bob.code)
        b.receive(try MeshPacket.alert("First", isSOS: false, from: real, now: t0).relayed(), now: at(5))
        b.receive(try MeshPacket.alert("Second", isSOS: false, from: other, now: at(5)).relayed(), now: at(5))

        XCTAssertEqual(b.cards(forPhone: "3331234567").map { $0.name }, ["Dana", "Not Dana"])
    }

    func testPhoneTagCannotBeChangedByARelay() throws {
        let packet = try MeshPacket.alert("Hi", isSOS: false, from: ada, now: t0)
        var card = packet.sender
        card.phoneTag = MeshPhone.tag(for: "3331234567")
        let altered = MeshPacket(id: packet.id, kind: .alert, sender: card, recipientCode: nil,
                                 isSOS: false, createdAt: packet.createdAt, expiresAt: packet.expiresAt,
                                 hopLimit: packet.hopLimit, payload: packet.payload,
                                 signature: packet.signature, hops: 0)
        XCTAssertFalse(altered.isValid(at: t0))
    }

    // MARK: Packets

    func testAlertIsSignedAndReadable() throws {
        let packet = try MeshPacket.alert("  Bridge closed  ", isSOS: false, from: ada, now: t0)
        XCTAssertTrue(packet.isValid(at: t0))
        XCTAssertEqual(packet.alertText, "Bridge closed")
        XCTAssertEqual(packet.sender.name, "Ada")
        XCTAssertEqual(packet.hops, 0)
    }

    func testPacketSurvivesJSONRoundTrip() throws {
        let packet = try MeshPacket.alert("Hello", isSOS: true, from: ada, now: at(0.7))
        let decoded = try JSONDecoder().decode(MeshPacket.self, from: JSONEncoder().encode(packet))
        XCTAssertEqual(decoded, packet)
        XCTAssertTrue(decoded.isValid(at: t0))
    }

    func testTamperedPacketIsInvalid() throws {
        let packet = try MeshPacket.alert("Water at the school", isSOS: false, from: ada, now: t0)
        var json = try XCTUnwrap(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(packet)) as? [String: Any])

        json["payload"] = Data("Water at the bridge".utf8).base64EncodedString()
        let changedText = try JSONDecoder().decode(
            MeshPacket.self, from: JSONSerialization.data(withJSONObject: json))
        XCTAssertFalse(changedText.isValid(at: t0))

        // Pretending to be someone else: the signature no longer matches the sender.
        let forged = MeshPacket(id: packet.id, kind: .alert, sender: bob.card, recipientCode: nil,
                                isSOS: false, createdAt: packet.createdAt, expiresAt: packet.expiresAt,
                                hopLimit: packet.hopLimit, payload: packet.payload,
                                signature: packet.signature, hops: 0)
        XCTAssertFalse(forged.isValid(at: t0))
    }

    func testEmptyAndOversizedTextAreRefused() {
        XCTAssertThrowsError(try MeshPacket.alert("   ", isSOS: false, from: ada, now: t0)) {
            XCTAssertEqual($0 as? MeshError, .emptyText)
        }
        let long = String(repeating: "a", count: MeshPacket.maxTextBytes + 1)
        XCTAssertThrowsError(try MeshPacket.alert(long, isSOS: false, from: ada, now: t0)) {
            XCTAssertEqual($0 as? MeshError, .textTooLong)
        }
    }

    func testPacketFromTheFutureIsInvalid() throws {
        let packet = try MeshPacket.alert("Later", isSOS: false, from: ada, now: at(3_600))
        XCTAssertFalse(packet.isValid(at: t0))
    }

    func testDirectMessageIsReadableOnlyByTheRecipient() throws {
        let packet = try MeshPacket.direct("Meet at the square", to: bob.card, from: ada, now: t0)
        XCTAssertTrue(packet.isValid(at: t0))
        XCTAssertEqual(packet.recipientCode, bob.code)
        XCTAssertNil(packet.alertText)
        XCTAssertEqual(packet.directText(for: bob), "Meet at the square")
        XCTAssertNil(packet.directText(for: cy))
        XCTAssertFalse(String(decoding: packet.payload, as: UTF8.self).contains("square"))
    }

    // MARK: Routing

    func testAlertHopsFromPhoneToPhone() throws {
        var a = MeshRouter(myCode: ada.code)
        var b = MeshRouter(myCode: bob.code)
        var c = MeshRouter(myCode: cy.code)

        let alert = try MeshPacket.alert("Road flooded", isSOS: false, from: ada, now: t0)
        XCTAssertEqual(a.submit(alert, now: t0), .accepted(isForMe: true, willRelay: true))

        // Ada meets Bob; later Bob meets Cy. Ada and Cy never meet.
        XCTAssertEqual(meet(a, &b, now: at(10)), [.accepted(isForMe: true, willRelay: true)])
        XCTAssertEqual(meet(b, &c, now: at(20)), [.accepted(isForMe: true, willRelay: true)])

        let onCy = try XCTUnwrap(c.alerts(now: at(20)).first)
        XCTAssertEqual(onCy.alertText, "Road flooded")
        XCTAssertEqual(onCy.sender.code, ada.code)
        XCTAssertEqual(onCy.hops, 2)
    }

    func testDuplicatesAreIgnoredSoPacketsNeverLoop() throws {
        var a = MeshRouter(myCode: ada.code)
        var b = MeshRouter(myCode: bob.code)
        a.submit(try MeshPacket.alert("Once", isSOS: false, from: ada, now: t0), now: t0)

        meet(a, &b, now: t0)
        XCTAssertTrue(meet(a, &b, now: t0).isEmpty)          // Bob already has it
        XCTAssertTrue(meet(b, &a, now: t0).isEmpty)          // and Ada does too
        let copy = try XCTUnwrap(a.packetsToSend(now: t0).first)
        XCTAssertEqual(b.receive(copy, now: t0), .duplicate)
        XCTAssertEqual(b.alerts(now: t0).count, 1)
    }

    func testPacketStopsAtItsHopLimit() throws {
        var a = MeshRouter(myCode: ada.code)
        var b = MeshRouter(myCode: bob.code)
        var c = MeshRouter(myCode: cy.code)
        a.submit(try MeshPacket.alert("Short range", isSOS: false, from: ada, now: t0, hopLimit: 1), now: t0)

        XCTAssertEqual(meet(a, &b, now: t0), [.accepted(isForMe: true, willRelay: false)])
        XCTAssertTrue(meet(b, &c, now: t0).isEmpty)
        XCTAssertTrue(c.alerts(now: t0).isEmpty)
    }

    func testExpiredPacketsAreDroppedAndNotRelayed() throws {
        var a = MeshRouter(myCode: ada.code)
        var b = MeshRouter(myCode: bob.code)
        let alert = try MeshPacket.alert("Brief", isSOS: false, from: ada, now: t0, lifetime: 60)
        a.submit(alert, now: t0)

        XCTAssertEqual(a.alerts(now: at(30)).count, 1)
        XCTAssertTrue(a.alerts(now: at(61)).isEmpty)
        XCTAssertTrue(meet(a, &b, now: at(61)).isEmpty)
        XCTAssertEqual(b.receive(alert.relayed(), now: at(61)), .rejected)
    }

    func testInvalidPacketIsRejectedAndNotStored() throws {
        var b = MeshRouter(myCode: bob.code)
        let good = try MeshPacket.alert("Real", isSOS: false, from: ada, now: t0)
        let forged = MeshPacket(id: UUID(), kind: .alert, sender: cy.card, recipientCode: nil,
                                isSOS: true, createdAt: good.createdAt, expiresAt: good.expiresAt,
                                hopLimit: good.hopLimit, payload: good.payload,
                                signature: good.signature, hops: 0)
        XCTAssertEqual(b.receive(forged, now: t0), .rejected)
        XCTAssertTrue(b.alerts(now: t0).isEmpty)
        XCTAssertTrue(b.packetsToSend(now: t0).isEmpty)
    }

    func testDirectMessageIsCarriedByOthersAndStopsAtTheRecipient() throws {
        var a = MeshRouter(myCode: ada.code)
        var b = MeshRouter(myCode: bob.code)   // carrier
        var c = MeshRouter(myCode: cy.code)    // recipient
        let message = try MeshPacket.direct("Are you safe?", to: cy.card, from: ada, now: t0)

        XCTAssertEqual(a.submit(message, now: t0), .accepted(isForMe: false, willRelay: true))
        XCTAssertEqual(meet(a, &b, now: t0), [.accepted(isForMe: false, willRelay: true)])
        XCTAssertTrue(b.inbox(now: t0).isEmpty)
        XCTAssertNil(b.packetsToSend(now: t0).first?.directText(for: bob))

        XCTAssertEqual(meet(b, &c, now: t0), [.accepted(isForMe: true, willRelay: false)])
        let delivered = try XCTUnwrap(c.inbox(now: t0).first)
        XCTAssertEqual(delivered.directText(for: cy), "Are you safe?")
        XCTAssertEqual(delivered.sender.code, ada.code)
        // The recipient does not pass its own private message on.
        XCTAssertTrue(c.packetsToSend(now: t0).isEmpty)
    }

    func testSOSIsSentFirstAndShownFirst() throws {
        var a = MeshRouter(myCode: ada.code)
        a.submit(try MeshPacket.alert("Old news", isSOS: false, from: ada, now: t0), now: t0)
        a.submit(try MeshPacket.alert("Newer news", isSOS: false, from: ada, now: at(10)), now: at(10))
        a.submit(try MeshPacket.alert("Help", isSOS: true, from: bob, now: at(20)), now: at(20))

        XCTAssertEqual(a.packetsToSend(now: at(20)).map(\.alertText), ["Help", "Old news", "Newer news"])
        XCTAssertEqual(a.alerts(now: at(20)).map(\.alertText), ["Help", "Newer news", "Old news"])
    }

    func testCapacityDropsOldestButKeepsSOS() throws {
        var a = MeshRouter(myCode: ada.code, capacity: 2)
        a.submit(try MeshPacket.alert("SOS", isSOS: true, from: bob, now: t0), now: t0)
        a.submit(try MeshPacket.alert("One", isSOS: false, from: ada, now: at(1)), now: at(1))
        a.submit(try MeshPacket.alert("Two", isSOS: false, from: ada, now: at(2)), now: at(2))

        XCTAssertEqual(Set(a.alerts(now: at(2)).compactMap(\.alertText)), ["SOS", "Two"])
        // A dropped packet is still remembered as seen.
        XCTAssertEqual(a.knownIDs(now: at(2)).count, 3)
    }

    func testKnownCardsListsOtherPeopleOnly() throws {
        var a = MeshRouter(myCode: ada.code)
        a.submit(try MeshPacket.alert("Mine", isSOS: false, from: ada, now: t0), now: t0)
        a.receive(try MeshPacket.alert("Bob here", isSOS: false, from: bob, now: t0).relayed(), now: t0)

        XCTAssertEqual(Array(a.knownCards.keys), [bob.code])
        XCTAssertEqual(a.knownCards[bob.code]?.name, "Bob")
    }

    func testResetErasesEverything() throws {
        var a = MeshRouter(myCode: ada.code)
        a.submit(try MeshPacket.alert("Gone", isSOS: false, from: ada, now: t0), now: t0)
        a.reset()
        XCTAssertTrue(a.alerts(now: t0).isEmpty)
        XCTAssertTrue(a.knownIDs(now: t0).isEmpty)
    }
}
