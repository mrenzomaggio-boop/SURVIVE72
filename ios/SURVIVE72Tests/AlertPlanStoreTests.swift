import XCTest
@testable import SURVIVE72

/// Persistence, edit and delete tests for SURVIVE ALERT.
/// Each test uses its own throwaway UserDefaults suite.
final class AlertPlanStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        suiteName = "SURVIVE72Tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        super.tearDown()
    }

    private func makeStore() -> AlertPlanStore {
        AlertPlanStore(defaults: defaults)
    }

    // MARK: Initial state

    func testNewStoreIsEmpty() {
        let store = makeStore()
        XCTAssertEqual(store.data, AlertPlanData())
        XCTAssertTrue(store.contacts.isEmpty)
        XCTAssertFalse(store.isMessageEdited)
    }

    func testUnreadableSavedDataStartsEmpty() {
        defaults.set(Data("not json".utf8), forKey: AlertPlanStore.storageKey)
        XCTAssertEqual(makeStore().data, AlertPlanData())
    }

    // MARK: Plan

    func testPlanIsSavedAndReloaded() {
        let store = makeStore()
        store.updatePlan(PersonalPlan(name: "Ada", meetingPoint: "Town hall", note: "Bring keys"))

        let reopened = makeStore()
        XCTAssertEqual(reopened.plan, PersonalPlan(name: "Ada", meetingPoint: "Town hall", note: "Bring keys"))
    }

    func testPlanIsSavedAsJSONUnderVersionedKey() throws {
        makeStore().updatePlan(PersonalPlan(name: "Ada"))
        let raw = try XCTUnwrap(defaults.data(forKey: AlertPlanStore.storageKey))
        let decoded = try JSONDecoder().decode(AlertPlanData.self, from: raw)
        XCTAssertEqual(decoded.plan.name, "Ada")
    }

    // MARK: Add

    func testAddContactIsSavedAndTrimmed() throws {
        let store = makeStore()
        let added = try XCTUnwrap(store.addContact(name: "  Bea ", phone: " 123 ", relationship: " Sister "))
        XCTAssertEqual(added.name, "Bea")
        XCTAssertEqual(added.phone, "123")
        XCTAssertEqual(added.relationship, "Sister")

        let reopened = makeStore()
        XCTAssertEqual(reopened.contacts, [added])
    }

    func testAddContactWithEmptyNameIsRejected() {
        let store = makeStore()
        XCTAssertNil(store.addContact(name: "   ", phone: "123", relationship: ""))
        XCTAssertTrue(store.contacts.isEmpty)
        XCTAssertNil(defaults.data(forKey: AlertPlanStore.storageKey))
    }

    func testContactsKeepInsertionOrder() {
        let store = makeStore()
        store.addContact(name: "A", phone: "", relationship: "")
        store.addContact(name: "B", phone: "", relationship: "")
        store.addContact(name: "C", phone: "", relationship: "")
        XCTAssertEqual(makeStore().contacts.map(\.name), ["A", "B", "C"])
    }

    // MARK: Edit

    func testUpdateContactIsSaved() throws {
        let store = makeStore()
        var contact = try XCTUnwrap(store.addContact(name: "Bea", phone: "123", relationship: "Sister"))
        contact.phone = " 456 "
        contact.relationship = "Friend"
        store.updateContact(contact)

        let reloaded = try XCTUnwrap(makeStore().contacts.first)
        XCTAssertEqual(reloaded.id, contact.id)
        XCTAssertEqual(reloaded.phone, "456")
        XCTAssertEqual(reloaded.relationship, "Friend")
    }

    func testUpdateWithEmptyNameIsIgnored() throws {
        let store = makeStore()
        var contact = try XCTUnwrap(store.addContact(name: "Bea", phone: "123", relationship: ""))
        contact.name = "  "
        store.updateContact(contact)
        XCTAssertEqual(makeStore().contacts.first?.name, "Bea")
    }

    func testUpdateUnknownContactIsIgnored() {
        let store = makeStore()
        store.addContact(name: "Bea", phone: "", relationship: "")
        store.updateContact(EmergencyContact(name: "Ghost", phone: "", relationship: ""))
        XCTAssertEqual(makeStore().contacts.map(\.name), ["Bea"])
    }

    // MARK: Delete

    func testDeleteContactIsSaved() throws {
        let store = makeStore()
        let first = try XCTUnwrap(store.addContact(name: "A", phone: "", relationship: ""))
        store.addContact(name: "B", phone: "", relationship: "")

        store.deleteContact(id: first.id)

        XCTAssertEqual(store.contacts.map(\.name), ["B"])
        XCTAssertEqual(makeStore().contacts.map(\.name), ["B"])
    }

    func testDeleteUnknownContactChangesNothing() {
        let store = makeStore()
        store.addContact(name: "A", phone: "", relationship: "")
        store.deleteContact(id: UUID())
        XCTAssertEqual(makeStore().contacts.count, 1)
    }

    // MARK: SOS message in the store

    func testMessageFollowsPlanUntilEdited() {
        let store = makeStore()
        store.updatePlan(PersonalPlan(name: "Ada"))
        XCTAssertTrue(store.message.contains("Name: Ada"))

        store.updatePlan(PersonalPlan(name: "Ada Lovelace"))
        XCTAssertTrue(store.message.contains("Name: Ada Lovelace"))
        XCTAssertFalse(store.isMessageEdited)
    }

    func testEditedMessageIsSavedAndKeptWhenPlanChanges() {
        let store = makeStore()
        store.setMessage("Custom SOS text")
        store.updatePlan(PersonalPlan(name: "Ada"))

        let reopened = makeStore()
        XCTAssertTrue(reopened.isMessageEdited)
        XCTAssertEqual(reopened.message, "Custom SOS text")
    }

    func testRegenerateDropsTheEditedText() {
        let store = makeStore()
        store.updatePlan(PersonalPlan(name: "Ada"))
        store.setMessage("Custom SOS text")

        store.regenerateMessage()

        XCTAssertFalse(store.isMessageEdited)
        XCTAssertEqual(store.message, store.generatedMessage)
        XCTAssertFalse(makeStore().isMessageEdited)
    }

    func testSettingTheGeneratedTextIsNotAnEdit() {
        let store = makeStore()
        store.updatePlan(PersonalPlan(name: "Ada"))
        store.setMessage(store.generatedMessage)
        XCTAssertFalse(store.isMessageEdited)
    }
}
