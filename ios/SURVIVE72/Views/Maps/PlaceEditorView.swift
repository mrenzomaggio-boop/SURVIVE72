import SwiftUI
import UIKit

/// Sheet to add or edit a saved place. Coordinates are typed in decimal
/// degrees and checked before saving.
struct PlaceEditorView: View {
    /// nil = add a new place.
    let place: SavedPlace?
    /// Returns true when the store accepted the values.
    let onSave: (_ name: String, _ latitude: Double, _ longitude: Double, _ note: String) -> Bool

    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var latitude = ""
    @State private var longitude = ""
    @State private var note = ""
    @State private var showErrors = false

    private var errors: [PlaceValidationError] {
        CoordinateValidator.validate(name: name, latitude: latitude, longitude: longitude)
    }

    private var preview: (lat: Double, lon: Double)? {
        guard errors.isEmpty,
              let lat = CoordinateValidator.parse(latitude),
              let lon = CoordinateValidator.parse(longitude) else { return nil }
        return (lat, lon)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    field(String(localized: "Name (required)"), text: $name, prompt: String(localized: "e.g. Meeting point"), keyboard: .default)
                    field(String(localized: "Latitude (-90 to 90)"), text: $latitude, prompt: String(localized: "e.g. 45.4642"),
                          keyboard: .numbersAndPunctuation)
                    field(String(localized: "Longitude (-180 to 180)"), text: $longitude, prompt: String(localized: "e.g. 9.1900"),
                          keyboard: .numbersAndPunctuation)
                    field(String(localized: "Note"), text: $note, prompt: String(localized: "Optional"), keyboard: .default)

                    if let p = preview {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(localized: "Decimal: ") + CoordinateFormat.decimal(latitude: p.lat, longitude: p.lon))
                            Text(String(localized: "DMS: ") + CoordinateFormat.dms(latitude: p.lat, longitude: p.lon))
                        }
                        .font(.body.monospacedDigit().weight(.semibold))
                        .foregroundStyle(Theme.ok)
                    }

                    if showErrors && !errors.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(errors, id: \.self) { error in
                                Label(error.message, systemImage: "exclamationmark.triangle.fill")
                            }
                        }
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.danger)
                        .accessibilityElement(children: .combine)
                    }

                    Text(String(localized: "Saved only on this device. The app does not read your location."))
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(place == nil ? String(localized: "Add place") : String(localized: "Edit place"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                        .font(.headline)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) { save() }
                        .font(.headline.weight(.heavy))
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Theme.accent)
        .onAppear {
            if let place {
                name = place.name
                latitude = CoordinateFormat.decimal(place.latitude)
                longitude = CoordinateFormat.decimal(place.longitude)
                note = place.note
            }
        }
    }

    private func save() {
        guard let p = preview, onSave(name, p.lat, p.lon, note) else {
            showErrors = true
            return
        }
        dismiss()
    }

    private func field(_ label: String, text: Binding<String>, prompt: String,
                       keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
            TextField(prompt, text: text)
                .keyboardType(keyboard)
                .textInputAutocapitalization(keyboard == .default ? .sentences : .never)
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
