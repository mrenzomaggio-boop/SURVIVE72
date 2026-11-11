import SwiftUI
import UIKit

/// Sheet to add a new emergency contact or edit an existing one.
struct ContactEditorView: View {
    /// nil = add a new contact.
    let contact: EmergencyContact?
    let onSave: (_ name: String, _ phone: String, _ relationship: String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var phone = ""
    @State private var relationship = ""

    private var canSave: Bool { !name.trimmed.isEmpty }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    field("Name (required)", text: $name, prompt: "Full name")
                    field("Phone", text: $phone, prompt: "Phone number", keyboard: .phonePad)
                    field("Relationship", text: $relationship, prompt: "e.g. Sister, Neighbour")

                    Text("Saved only on this device. The app never calls or texts this number.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(contact == nil ? "Add contact" : "Edit contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .font(.headline)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(name, phone, relationship)
                        dismiss()
                    }
                    .font(.headline.weight(.heavy))
                    .disabled(!canSave)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
        .onAppear {
            if let contact {
                name = contact.name
                phone = contact.phone
                relationship = contact.relationship
            }
        }
    }

    private func field(_ label: String, text: Binding<String>, prompt: String,
                       keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
            TextField(prompt, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .phonePad ? .never : .words)
                .autocorrectionDisabled()
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
