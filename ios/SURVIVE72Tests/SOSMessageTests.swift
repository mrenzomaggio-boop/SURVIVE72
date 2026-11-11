import XCTest
@testable import SURVIVE72

/// SOS text generation. The message is only text to copy: it is never sent.
final class SOSMessageTests: XCTestCase {
    func testEmptyPlanGivesOnlyTheHeader() {
        XCTAssertEqual(SOSMessage.build(plan: PersonalPlan(), contacts: []), "SOS - I need help.")
    }

    func testFullMessageLayout() {
        let plan = PersonalPlan(name: "Ada", meetingPoint: "Town hall", note: "Bring the blue bag")
        let contacts = [
            EmergencyContact(name: "Bea", phone: "+39 123", relationship: "Sister"),
            EmergencyContact(name: "Carl", phone: "", relationship: ""),
            EmergencyContact(name: "Dan", phone: "555", relationship: "")
        ]

        let expected = """
        SOS - I need help.
        Name: Ada
        Meeting point: Town hall
        Note: Bring the blue bag

        Emergency contacts:
        - Bea (Sister): +39 123
        - Carl
        - Dan: 555
        """
        XCTAssertEqual(SOSMessage.build(plan: plan, contacts: contacts), expected)
    }

    func testEmptyFieldsAreLeftOut() {
        let message = SOSMessage.build(plan: PersonalPlan(name: "Ada", meetingPoint: "  ", note: ""),
                                       contacts: [])
        XCTAssertEqual(message, "SOS - I need help.\nName: Ada")
        XCTAssertFalse(message.contains("Meeting point"))
        XCTAssertFalse(message.contains("Note"))
        XCTAssertFalse(message.contains("Emergency contacts"))
    }

    func testValuesAreTrimmed() {
        let message = SOSMessage.build(plan: PersonalPlan(name: "  Ada \n"),
                                       contacts: [EmergencyContact(name: " Bea ", phone: " 1 ", relationship: " ")])
        XCTAssertEqual(message, "SOS - I need help.\nName: Ada\n\nEmergency contacts:\n- Bea: 1")
    }

    func testContactsWithoutNameAreSkipped() {
        let message = SOSMessage.build(plan: PersonalPlan(),
                                       contacts: [EmergencyContact(name: " ", phone: "999", relationship: "")])
        XCTAssertEqual(message, "SOS - I need help.")
    }

    func testStatusTextIsFixed() {
        XCTAssertEqual(AlertStatus.notSent, "NOT SENT · NO EMERGENCY SERVICE CONTACTED")
    }
}
