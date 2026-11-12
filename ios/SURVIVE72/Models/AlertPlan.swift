import Foundation

/// A person to reach in an emergency. Stored only on this device.
/// The phone number is plain text: the app never calls or texts it.
struct EmergencyContact: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var name: String
    var phone: String
    var relationship: String
}

/// The user's personal emergency plan.
struct PersonalPlan: Codable, Equatable {
    var name: String = ""
    var meetingPoint: String = ""
    var note: String = ""
}

/// Everything SURVIVE ALERT saves, in one value.
struct AlertPlanData: Codable, Equatable {
    var plan = PersonalPlan()
    var contacts: [EmergencyContact] = []
    /// The user's edited SOS text. `nil` means "use the generated message".
    var messageDraft: String?
}

// MARK: - Tolerant decoding
// Hand-written so a missing or damaged field never loses the rest of the plan.

extension EmergencyContact {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.value(UUID.self, forKey: .id, default: UUID())
        name = try c.decode(String.self, forKey: .name)
        phone = c.value(String.self, forKey: .phone, default: "")
        relationship = c.value(String.self, forKey: .relationship, default: "")
    }
}

extension PersonalPlan {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = c.value(String.self, forKey: .name, default: "")
        meetingPoint = c.value(String.self, forKey: .meetingPoint, default: "")
        note = c.value(String.self, forKey: .note, default: "")
    }
}

extension AlertPlanData {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        plan = c.value(PersonalPlan.self, forKey: .plan, default: PersonalPlan())
        contacts = c.lossyArray(EmergencyContact.self, forKey: .contacts)
        messageDraft = c.optionalValue(String.self, forKey: .messageDraft)
    }
}

/// Fixed status line shown on every Alert screen.
enum AlertStatus {
    static let notSent = "NOT SENT · NO EMERGENCY SERVICE CONTACTED"
}
