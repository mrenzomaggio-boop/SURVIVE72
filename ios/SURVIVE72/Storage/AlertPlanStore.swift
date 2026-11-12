import Foundation
import Observation

/// SURVIVE ALERT state: personal plan, emergency contacts and SOS draft.
/// Saved as JSON in `UserDefaults` on every change. Nothing leaves the device:
/// no network, no SMS, no calls, no location.
@Observable
final class AlertPlanStore {
    static let storageKey = "survive72.alert.planData.v1"

    private(set) var data: AlertPlanData

    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = AlertPlanStore.storageKey) {
        self.defaults = defaults
        self.key = key
        if let decoded = LocalStorage.load(AlertPlanData.self, key: key, from: defaults) {
            self.data = decoded
        } else {
            // Missing or unreadable data: start empty instead of crashing.
            self.data = AlertPlanData()
        }
    }

    // MARK: Read

    var plan: PersonalPlan { data.plan }
    var contacts: [EmergencyContact] { data.contacts }

    /// SOS text generated from the current plan and contacts.
    var generatedMessage: String {
        SOSMessage.build(plan: data.plan, contacts: data.contacts)
    }

    /// What the user sees and copies: their edited draft, or the generated text.
    var message: String { data.messageDraft ?? generatedMessage }

    var isMessageEdited: Bool { data.messageDraft != nil }

    // MARK: Plan

    func updatePlan(_ plan: PersonalPlan) {
        data.plan = plan
        save()
    }

    // MARK: Contacts

    /// Adds a contact. Returns nil (and saves nothing) if the name is empty.
    @discardableResult
    func addContact(name: String, phone: String, relationship: String) -> EmergencyContact? {
        let contact = EmergencyContact(
            name: name.trimmed, phone: phone.trimmed, relationship: relationship.trimmed
        )
        guard !contact.name.isEmpty else { return nil }
        data.contacts.append(contact)
        save()
        return contact
    }

    /// Replaces the contact with the same id. Ignored if the id is unknown or the name is empty.
    func updateContact(_ contact: EmergencyContact) {
        guard let index = data.contacts.firstIndex(where: { $0.id == contact.id }) else { return }
        var cleaned = contact
        cleaned.name = contact.name.trimmed
        cleaned.phone = contact.phone.trimmed
        cleaned.relationship = contact.relationship.trimmed
        guard !cleaned.name.isEmpty else { return }
        data.contacts[index] = cleaned
        save()
    }

    func deleteContact(id: EmergencyContact.ID) {
        let before = data.contacts.count
        data.contacts.removeAll { $0.id == id }
        if data.contacts.count != before { save() }
    }

    // MARK: SOS message

    /// Stores the user's edited text. Editing back to the generated text clears the draft.
    func setMessage(_ text: String) {
        data.messageDraft = (text == generatedMessage) ? nil : text
        save()
    }

    /// Drops the edited text and goes back to the generated message.
    func regenerateMessage() {
        data.messageDraft = nil
        save()
    }

    /// Erases plan, contacts and SOS draft from memory and from the device.
    func resetAll() {
        data = AlertPlanData()
        LocalStorage.remove(key: key, from: defaults)
    }

    // MARK: Persistence

    private func save() {
        LocalStorage.save(data, key: key, to: defaults)
    }
}
