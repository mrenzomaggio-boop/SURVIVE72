import Foundation

/// Builds the SOS text from the local plan and contacts.
/// Pure function: no network, no location, no side effects.
enum SOSMessage {
    static func build(plan: PersonalPlan, contacts: [EmergencyContact]) -> String {
        var lines = ["SOS - I need help."]

        let name = plan.name.trimmed
        let meetingPoint = plan.meetingPoint.trimmed
        let note = plan.note.trimmed

        if !name.isEmpty { lines.append("Name: \(name)") }
        if !meetingPoint.isEmpty { lines.append("Meeting point: \(meetingPoint)") }
        if !note.isEmpty { lines.append("Note: \(note)") }

        let listed = contacts.filter { !$0.name.trimmed.isEmpty }
        if !listed.isEmpty {
            lines.append("")
            lines.append("Emergency contacts:")
            for contact in listed {
                lines.append("- " + describe(contact))
            }
        }
        return lines.joined(separator: "\n")
    }

    private static func describe(_ contact: EmergencyContact) -> String {
        var text = contact.name.trimmed
        let relationship = contact.relationship.trimmed
        let phone = contact.phone.trimmed
        if !relationship.isEmpty { text += " (\(relationship))" }
        if !phone.isEmpty { text += ": \(phone)" }
        return text
    }
}

extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
}
