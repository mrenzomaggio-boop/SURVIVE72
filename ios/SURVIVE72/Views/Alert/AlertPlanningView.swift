import SwiftUI
import UIKit

/// SURVIVE ALERT: local emergency plan, contacts and an SOS message to copy.
/// Nothing is ever sent: no network, SMS, calls or location.
struct AlertPlanningView: View {
    @Environment(AlertPlanStore.self) private var store

    @State private var editingContact: EmergencyContact?
    @State private var isAddingContact = false
    @State private var contactPendingDeletion: EmergencyContact?
    @State private var didCopy = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                planSection
                contactsSection
                messageSection
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        // Pinned under the navigation bar so it is visible at all times.
        .safeAreaInset(edge: .top, spacing: 0) {
            NotSentBanner()
        }
        .navigationTitle("Alert")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isAddingContact) {
            ContactEditorView(contact: nil) { name, phone, relationship in
                _ = store.addContact(name: name, phone: phone, relationship: relationship)
            }
        }
        .sheet(item: $editingContact) { contact in
            ContactEditorView(contact: contact) { name, phone, relationship in
                var updated = contact
                updated.name = name
                updated.phone = phone
                updated.relationship = relationship
                store.updateContact(updated)
            }
        }
        .alert(
            "Delete contact?",
            isPresented: Binding(
                get: { contactPendingDeletion != nil },
                set: { if !$0 { contactPendingDeletion = nil } }
            ),
            presenting: contactPendingDeletion
        ) { contact in
            Button("Delete", role: .destructive) {
                store.deleteContact(id: contact.id)
            }
            Button("Cancel", role: .cancel) {}
        } message: { contact in
            Text("\(contact.name) will be removed from this device.")
        }
    }

    // MARK: Plan

    private var planSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Personal plan", systemImage: "person.text.rectangle.fill")
            LabeledField(label: "Your name", text: planBinding(\.name), prompt: "Name")
            LabeledField(label: "Meeting point", text: planBinding(\.meetingPoint),
                         prompt: "Where your group meets")
            LabeledField(label: "Note", text: planBinding(\.note),
                         prompt: "Anything others should know", multiline: true)
        }
    }

    private func planBinding(_ keyPath: WritableKeyPath<PersonalPlan, String>) -> Binding<String> {
        Binding(
            get: { store.plan[keyPath: keyPath] },
            set: { newValue in
                var plan = store.plan
                plan[keyPath: keyPath] = newValue
                store.updatePlan(plan)
            }
        )
    }

    // MARK: Contacts

    private var contactsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Emergency contacts", systemImage: "person.2.fill",
                          trailing: "\(store.contacts.count)")

            if store.contacts.isEmpty {
                Text("No contacts yet. Contacts are saved only on this device.")
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
            }

            ForEach(store.contacts) { contact in
                ContactRow(
                    contact: contact,
                    onEdit: { editingContact = contact },
                    onDelete: { contactPendingDeletion = contact }
                )
            }

            BigButton(title: "Add contact", systemImage: "plus.circle.fill", color: Theme.accent) {
                isAddingContact = true
            }
        }
    }

    // MARK: SOS message

    private var messageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "SOS message", systemImage: "text.bubble.fill")

            Text(store.isMessageEdited
                 ? "Edited by you. Tap Regenerate to rebuild it from your plan and contacts."
                 : "Generated from your plan and contacts. You can edit it.")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            TextEditor(text: Binding(
                get: { store.message },
                set: { store.setMessage($0) }
            ))
            .font(.body.monospaced())
            .foregroundStyle(Theme.textPrimary)
            .scrollContentBackground(.hidden)
            .padding(10)
            .frame(minHeight: 200)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth)
            )
            .accessibilityLabel("SOS message text")

            BigButton(title: didCopy ? "Copied · not sent" : "Copy SOS message",
                      systemImage: didCopy ? "checkmark.circle.fill" : "doc.on.doc.fill",
                      color: didCopy ? Theme.ok : Theme.accent) {
                UIPasteboard.general.string = store.message
                didCopy = true
                UIAccessibility.post(notification: .announcement,
                                     argument: "SOS message copied. Not sent.")
            }
            .accessibilityHint("Copies the text only. Nothing is sent and no one is contacted.")
            .sensoryFeedback(.success, trigger: didCopy)

            if store.isMessageEdited {
                BigButton(title: "Regenerate from plan", systemImage: "arrow.clockwise",
                          color: Theme.textPrimary) {
                    store.regenerateMessage()
                }
            }
        }
        .onChange(of: store.message) { didCopy = false }
    }
}

// MARK: - Building blocks

/// Permanent red status bar: nothing is sent, nobody is contacted.
struct NotSentBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "xmark.octagon.fill")
                .font(.title3.weight(.bold))
                .accessibilityHidden(true)
            Text(AlertStatus.notSent)
                .font(.subheadline.weight(.black))
                .minimumScaleFactor(0.7)
                .lineLimit(2)
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.danger.opacity(0.35))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.danger).frame(height: 3)
        }
        .background(Theme.background)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Not sent. No emergency service contacted.")
        .accessibilityAddTraits(.isStaticText)
    }
}

private struct SectionHeader: View {
    let title: String
    let systemImage: String
    var trailing: String?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title.uppercased())
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.title3.weight(.heavy).monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct LabeledField: View {
    let label: String
    @Binding var text: String
    let prompt: String
    var multiline = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
            TextField(prompt, text: $text, axis: multiline ? .vertical : .horizontal)
                .lineLimit(multiline ? 2...6 : 1...1)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(12)
                .frame(minHeight: 52)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth)
                )
                .accessibilityLabel(label)
        }
    }
}

private struct ContactRow: View {
    let contact: EmergencyContact
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(contact.name)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                if !contact.relationship.isEmpty {
                    Text(contact.relationship)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                }
                if !contact.phone.isEmpty {
                    Text(contact.phone)
                        .font(.body.monospacedDigit())
                        .foregroundStyle(Theme.textPrimary)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 8)
            iconButton("pencil", label: "Edit \(contact.name)", color: Theme.accent, action: onEdit)
            iconButton("trash.fill", label: "Delete \(contact.name)", color: Theme.danger, action: onDelete)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth)
        )
    }

    private func iconButton(_ systemImage: String, label: String, color: Color,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
                .frame(width: 52, height: 52)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: Theme.borderWidth))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct BigButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.title3.weight(.heavy))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, minHeight: 60)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(color, lineWidth: Theme.borderWidth)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        AlertPlanningView()
    }
    .environment(AlertPlanStore(defaults: UserDefaults(suiteName: "preview.alert")!))
    .preferredColorScheme(.dark)
}
