import XCTest
@testable import SURVIVE72

/// The mesh service end to end, with fake radios: phones are "near" each
/// other when the test links their transports.
final class MeshServiceTests: XCTestCase {
    /// In-memory radio. `link` connects two of them and delivers data at once.
    private final class FakeTransport: MeshTransport {
        weak var delegate: MeshTransportDelegate?
        let token = UUID().uuidString
        private(set) var isStarted = false
        private var links: [String: FakeTransport] = [:]

        var connectedPeers: [String] { Array(links.keys) }

        func start() { isStarted = true }

        func stop() {
            isStarted = false
            for other in Array(links.values) { FakeTransport.unlink(self, other) }
        }

        func send(_ data: Data, to peer: String) {
            guard let other = links[peer] else { return }
            other.delegate?.meshTransport(didReceive: data, from: token)
        }

        static func link(_ a: FakeTransport, _ b: FakeTransport) {
            guard a.isStarted, b.isStarted else { return }
            a.links[b.token] = b
            b.links[a.token] = a
            a.delegate?.meshTransport(peerConnected: b.token)
            b.delegate?.meshTransport(peerConnected: a.token)
        }

        static func unlink(_ a: FakeTransport, _ b: FakeTransport) {
            a.links[b.token] = nil
            b.links[a.token] = nil
            a.delegate?.meshTransport(peerDisconnected: b.token)
            b.delegate?.meshTransport(peerDisconnected: a.token)
        }
    }

    private struct Phone {
        let service: MeshService
        let radio: FakeTransport
        let keys: InMemoryMeshKeyStore
        let defaults: UserDefaults
        let stateURL: URL
    }

    private var suites: [String] = []
    private var files: [URL] = []
    private var clock = Date(timeIntervalSince1970: 1_800_000_000)

    override func tearDown() {
        for suite in suites { UserDefaults(suiteName: suite)?.removePersistentDomain(forName: suite) }
        for file in files { try? FileManager.default.removeItem(at: file) }
        suites = []
        files = []
        super.tearDown()
    }

    private func makePhone(name: String, phone: String = "", enabled: Bool = true) -> Phone {
        let suite = "SURVIVE72Tests.mesh.\(UUID().uuidString)"
        suites.append(suite)
        let defaults = UserDefaults(suiteName: suite)!
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("mesh-\(UUID().uuidString).json")
        files.append(url)
        let radio = FakeTransport()
        let keys = InMemoryMeshKeyStore()
        let service = MeshService(transport: radio, keyStore: keys, defaults: defaults,
                                  stateURL: url, now: { [unowned self] in self.clock })
        service.updateProfile(name: name, phone: phone)
        service.setEnabled(enabled)
        return Phone(service: service, radio: radio, keys: keys, defaults: defaults, stateURL: url)
    }

    /// A second launch of the same phone: same keys, same saved files.
    private func relaunch(_ phone: Phone) -> Phone {
        let radio = FakeTransport()
        let service = MeshService(transport: radio, keyStore: phone.keys, defaults: phone.defaults,
                                  stateURL: phone.stateURL, now: { [unowned self] in self.clock })
        return Phone(service: service, radio: radio, keys: phone.keys, defaults: phone.defaults,
                     stateURL: phone.stateURL)
    }

    // MARK: Profile

    func testLinkIsOffUntilSwitchedOn() {
        let phone = makePhone(name: "Ada", enabled: false)
        XCTAssertFalse(phone.service.isEnabled)
        XCTAssertFalse(phone.radio.isStarted)

        phone.service.setEnabled(true)
        XCTAssertTrue(phone.radio.isStarted)
        phone.service.setEnabled(false)
        XCTAssertFalse(phone.radio.isStarted)
    }

    func testProfileAndIdentitySurviveARelaunch() {
        let phone = makePhone(name: "  Ada  ", phone: "333 123 4567")
        let again = relaunch(phone)

        XCTAssertEqual(again.service.profile.name, "Ada")
        XCTAssertEqual(again.service.myCode, phone.service.myCode)
        XCTAssertEqual(again.service.identity.card, phone.service.identity.card)
        XCTAssertNotNil(again.service.identity.phoneTag)
        XCTAssertTrue(again.radio.isStarted)
    }

    func testInvalidPhoneNumberIsNotKept() {
        let phone = makePhone(name: "Ada", phone: "abc")
        XCTAssertEqual(phone.service.profile.phone, "")
        XCTAssertNil(phone.service.identity.phoneTag)
    }

    // MARK: Alerts

    func testAlertReachesAPhoneThatNeverMetTheAuthor() throws {
        let ada = makePhone(name: "Ada")
        let bob = makePhone(name: "Bob")
        let cy = makePhone(name: "Cy")
        try ada.service.postAlert("Bridge closed", isSOS: false)

        FakeTransport.link(ada.radio, bob.radio)
        FakeTransport.unlink(ada.radio, bob.radio)
        XCTAssertTrue(cy.service.alerts.isEmpty)
        FakeTransport.link(bob.radio, cy.radio)

        let alert = try XCTUnwrap(cy.service.alerts.first)
        XCTAssertEqual(alert.alertText, "Bridge closed")
        XCTAssertEqual(alert.sender.name, "Ada")
        XCTAssertEqual(alert.hops, 2)
        XCTAssertEqual(cy.service.nearbyCount, 1)
    }

    func testNewAlertSpreadsAtOnceThroughAChainOfConnectedPhones() throws {
        let ada = makePhone(name: "Ada")
        let bob = makePhone(name: "Bob")
        let cy = makePhone(name: "Cy")
        FakeTransport.link(ada.radio, bob.radio)
        FakeTransport.link(bob.radio, cy.radio)

        try ada.service.postAlert("Help needed", isSOS: true)

        XCTAssertEqual(bob.service.alerts.map(\.alertText), ["Help needed"])
        XCTAssertEqual(cy.service.alerts.map(\.alertText), ["Help needed"])
        XCTAssertEqual(cy.service.alerts.first?.isSOS, true)
        // It came back to nobody twice.
        XCTAssertEqual(ada.service.alerts.count, 1)
    }

    func testGarbageFromTheRadioIsIgnored() {
        let ada = makePhone(name: "Ada")
        ada.service.meshTransport(didReceive: Data("not a packet".utf8), from: "someone")
        ada.service.meshTransport(didReceive: Data(), from: "someone")
        XCTAssertTrue(ada.service.alerts.isEmpty)
    }

    // MARK: Private messages

    func testPrivateMessageFindsItsRecipientByPhoneNumberThroughACarrier() throws {
        let ada = makePhone(name: "Ada")
        let bob = makePhone(name: "Bob")                       // carrier
        let dana = makePhone(name: "Dana", phone: "333 123 4567")

        // Dana showed up on the mesh once; Bob carried her alert to Ada.
        try dana.service.postAlert("Dana is here", isSOS: false)
        FakeTransport.link(dana.radio, bob.radio)
        FakeTransport.unlink(dana.radio, bob.radio)
        FakeTransport.link(bob.radio, ada.radio)

        let found = ada.service.people(withPhone: "+39 333 1234567")
        XCTAssertEqual(found.map { $0.name }, ["Dana"])
        let recipient = try XCTUnwrap(found.first)

        try ada.service.send("Are you safe?", to: recipient)
        XCTAssertTrue(bob.service.conversationCodes.isEmpty)   // the carrier sees nothing
        FakeTransport.unlink(bob.radio, ada.radio)
        FakeTransport.link(bob.radio, dana.radio)

        let received = dana.service.messages(with: ada.service.myCode)
        XCTAssertEqual(received.map(\.text), ["Are you safe?"])
        XCTAssertEqual(received.first?.isOutgoing, false)
        XCTAssertEqual(dana.service.conversationCodes, [ada.service.myCode])
        XCTAssertEqual(dana.service.card(for: ada.service.myCode)?.name, "Ada")

        let written = ada.service.messages(with: recipient.code)
        XCTAssertEqual(written.map(\.text), ["Are you safe?"])
        XCTAssertEqual(written.first?.isOutgoing, true)
    }

    // MARK: People nearby and search

    func testPhonesNextToEachOtherSeeEachOtherAtOnce() {
        let ada = makePhone(name: "Ada")
        let bob = makePhone(name: "Bob")
        XCTAssertTrue(ada.service.reachablePeople.isEmpty)

        FakeTransport.link(ada.radio, bob.radio)
        XCTAssertEqual(ada.service.reachablePeople.map(\.name), ["Bob"])
        XCTAssertEqual(bob.service.reachablePeople.map(\.name), ["Ada"])
        XCTAssertEqual(ada.service.nearbyPeopleCodes, [bob.service.myCode])

        // A new nickname reaches the phone next to it straight away.
        bob.service.updateProfile(name: "Roberto", phone: "")
        XCTAssertEqual(ada.service.reachablePeople.map(\.name), ["Roberto"])
        XCTAssertEqual(ada.service.card(for: bob.service.myCode)?.name, "Roberto")

        // Out of range: no longer "near", still known, and still known after a relaunch.
        FakeTransport.unlink(ada.radio, bob.radio)
        XCTAssertTrue(ada.service.nearbyPeopleCodes.isEmpty)
        XCTAssertEqual(ada.service.reachablePeople.map(\.name), ["Roberto"])
        XCTAssertEqual(relaunch(ada).service.reachablePeople.map(\.name), ["Roberto"])
    }

    func testPeopleNearbyComeFirst() {
        let ada = makePhone(name: "Ada")
        let zoe = makePhone(name: "Zoe")
        let bob = makePhone(name: "Bob")
        FakeTransport.link(ada.radio, bob.radio)
        FakeTransport.unlink(ada.radio, bob.radio)
        FakeTransport.link(ada.radio, zoe.radio)
        XCTAssertEqual(ada.service.reachablePeople.map(\.name), ["Zoe", "Bob"])
    }

    func testCardWithSomeoneElsesCodeIsRefused() throws {
        let ada = makePhone(name: "Ada")
        let victim = MeshIdentity(name: "Bob")
        let thief = MeshIdentity(name: "Bob")
        // The thief hands out Bob's code with its own encryption key.
        let forged = MeshCard(name: "Bob", signingKey: victim.card.signingKey,
                              agreementKey: thief.card.agreementKey)
        let hello = MeshWire.hello(known: [], card: forged, signature: try thief.sign(forged.signedBytes))
        ada.service.meshTransport(didReceive: try XCTUnwrap(hello.encoded()), from: "peer")
        XCTAssertTrue(ada.service.reachablePeople.isEmpty)
        XCTAssertTrue(ada.service.nearbyPeopleCodes.isEmpty)

        let honest = MeshWire.hello(known: [], card: victim.card, signature: try victim.sign(victim.card.signedBytes))
        ada.service.meshTransport(didReceive: try XCTUnwrap(honest.encoded()), from: "peer")
        XCTAssertEqual(ada.service.reachablePeople.map(\.code), [victim.code])
    }

    func testSearchByNickname() {
        let ada = makePhone(name: "Ada")
        let mario = makePhone(name: "Mario Rossi")
        let nicolo = makePhone(name: "Nicolò")
        FakeTransport.link(ada.radio, mario.radio)
        FakeTransport.link(ada.radio, nicolo.radio)

        XCTAssertEqual(ada.service.people(matching: "mario").map(\.name), ["Mario Rossi"])
        XCTAssertEqual(ada.service.people(matching: "ROSSI ").map(\.name), ["Mario Rossi"])
        XCTAssertEqual(ada.service.people(matching: "nicolo").map(\.name), ["Nicolò"])
        XCTAssertTrue(ada.service.people(matching: "luigi").isEmpty)
        XCTAssertTrue(ada.service.people(matching: "Ada").isEmpty)   // not herself
        XCTAssertTrue(ada.service.people(matching: "  ").isEmpty)
    }

    func testUnknownPhoneNumberFindsNobody() {
        let ada = makePhone(name: "Ada", phone: "333 123 4567")
        XCTAssertTrue(ada.service.people(withPhone: "333 999 0000").isEmpty)
        XCTAssertTrue(ada.service.people(withPhone: "333 123 4567").isEmpty)   // not herself
        XCTAssertTrue(ada.service.people(withPhone: "x").isEmpty)
    }

    // MARK: Persistence and reset

    func testAlertsMessagesAndContactsSurviveARelaunch() throws {
        let ada = makePhone(name: "Ada")
        let bob = makePhone(name: "Bob", phone: "3331234567")
        FakeTransport.link(ada.radio, bob.radio)
        try bob.service.postAlert("Water at the school", isSOS: false)
        let bobCard = try XCTUnwrap(ada.service.people(withPhone: "3331234567").first)
        try ada.service.send("Thanks", to: bobCard)

        let again = relaunch(ada)
        XCTAssertEqual(again.service.alerts.map(\.alertText), ["Water at the school"])
        XCTAssertEqual(again.service.messages(with: bobCard.code).map(\.text), ["Thanks"])
        XCTAssertEqual(again.service.people(withPhone: "3331234567").map { $0.name }, ["Bob"])
    }

    func testExpiredAlertsDisappear() throws {
        let ada = makePhone(name: "Ada")
        try ada.service.postAlert("Old", isSOS: false)
        clock = clock.addingTimeInterval(MeshPacket.defaultLifetime + 1)
        XCTAssertTrue(ada.service.alerts.isEmpty)
        XCTAssertTrue(relaunch(ada).service.alerts.isEmpty)
    }

    func testResetErasesEverythingAndCreatesANewIdentity() throws {
        let ada = makePhone(name: "Ada", phone: "3331234567")
        let oldCode = ada.service.myCode
        try ada.service.postAlert("Something", isSOS: false)

        ada.service.reset()

        XCTAssertFalse(ada.service.isEnabled)
        XCTAssertFalse(ada.radio.isStarted)
        XCTAssertEqual(ada.service.profile, MeshProfile())
        XCTAssertTrue(ada.service.alerts.isEmpty)
        XCTAssertNotEqual(ada.service.myCode, oldCode)
        XCTAssertFalse(FileManager.default.fileExists(atPath: ada.stateURL.path))
        XCTAssertNil(ada.defaults.object(forKey: MeshService.profileKey))

        let again = relaunch(ada)
        XCTAssertTrue(again.service.alerts.isEmpty)
        XCTAssertEqual(again.service.myCode, ada.service.myCode)
    }

    // MARK: Wire format

    func testWireMessagesRoundTripAndAreSplitInBatches() throws {
        let identity = MeshIdentity(name: "Ada")
        let packets = try (0..<45).map {
            try MeshPacket.alert("Alert \($0)", isSOS: false, from: identity, now: clock)
        }
        let batches = MeshWire.batches(packets)
        XCTAssertEqual(batches.count, 3)

        let data = try XCTUnwrap(batches[0].encoded())
        XCTAssertEqual(MeshWire.decoded(data), batches[0])

        let hello = MeshWire.hello(known: [UUID(), UUID()])
        XCTAssertEqual(MeshWire.decoded(try XCTUnwrap(hello.encoded())), hello)
        let signed = MeshWire.hello(known: [], card: identity.card, signature: try identity.sign(identity.card.signedBytes))
        XCTAssertEqual(MeshWire.decoded(try XCTUnwrap(signed.encoded())), signed)
        // A hello from the previous version, without a card, is still understood.
        let id = UUID()
        let legacy = Data(#"{"hello":{"known":["\#(id.uuidString)"]}}"#.utf8)
        XCTAssertEqual(MeshWire.decoded(legacy), .hello(known: [id]))
        XCTAssertNil(MeshWire.decoded(Data(count: 600 * 1024)))
    }
}
