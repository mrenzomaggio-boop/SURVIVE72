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

/// Fixed status line shown on every Alert screen.
enum AlertStatus {
    static let notSent = "NOT SENT · NO EMERGENCY SERVICE CONTACTED"
}
