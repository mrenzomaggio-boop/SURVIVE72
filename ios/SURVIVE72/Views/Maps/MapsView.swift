import SwiftUI

/// SURVIVE MAPS: saved places typed by hand, demo offline areas, and
/// compass/position placeholders. No MapKit, GPS, network or permissions.
struct MapsView: View {
    @Environment(MapsStore.self) private var store

    @State private var isAddingPlace = false
    @State private var editingPlace: SavedPlace?
    @State private var placePendingDeletion: SavedPlace?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Label(String(localized: "No map, no GPS: coordinates are typed in by hand and stay on this device."),
                      systemImage: "location.slash.fill")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Theme.accent, lineWidth: Theme.borderWidth))

                placesSection
                areasSection
                sensorsSection
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(String(localized: "Maps"))
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isAddingPlace) {
            PlaceEditorView(place: nil) { name, latitude, longitude, note in
                store.addPlace(name: name, latitude: latitude, longitude: longitude, note: note) != nil
            }
        }
        .sheet(item: $editingPlace) { place in
            PlaceEditorView(place: place) { name, latitude, longitude, note in
                var updated = place
                updated.name = name
                updated.latitude = latitude
                updated.longitude = longitude
                updated.note = note
                return store.updatePlace(updated)
            }
        }
        .alert(
            String(localized: "Delete place?"),
            isPresented: Binding(
                get: { placePendingDeletion != nil },
                set: { if !$0 { placePendingDeletion = nil } }
            ),
            presenting: placePendingDeletion
        ) { place in
            Button(String(localized: "Delete"), role: .destructive) { store.deletePlace(id: place.id) }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: { place in
            Text(String(localized: "\(place.name) will be removed from this device."))
        }
    }

    // MARK: Places

    private var placesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MapsHeader(title: String(localized: "Saved places"), systemImage: "mappin.and.ellipse",
                       trailing: "\(store.places.count)")

            if store.places.isEmpty {
                Text(String(localized: "No places yet. Add a meeting point, shelter or water source with its coordinates."))
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
            }

            ForEach(store.places) { place in
                PlaceRow(place: place,
                         onEdit: { editingPlace = place },
                         onDelete: { placePendingDeletion = place })
            }

            BigButton(title: String(localized: "Add place"), systemImage: "plus.circle.fill", color: Theme.accent) {
                isAddingPlace = true
            }
        }
    }

    // MARK: Areas

    private var areasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MapsHeader(title: String(localized: "Offline areas"), systemImage: "square.dashed",
                       trailing: "\(store.preparedCount)/\(store.areas.count)")

            Text(String(localized: "Demo areas. Nothing is downloaded: marking an area only records it on this device."))
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            ForEach(store.areas) { area in
                AreaRow(area: area, status: store.status(of: area)) { prepared in
                    store.setPrepared(prepared, for: area)
                }
            }
        }
    }

    // MARK: Sensors

    private var sensorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MapsHeader(title: String(localized: "Compass and position"), systemImage: "location.north.circle.fill")
            NavigationLink {
                SensorPlaceholderView(kind: .compass)
            } label: {
                SensorRow(kind: .compass)
            }
            .buttonStyle(.plain)
            NavigationLink {
                SensorPlaceholderView(kind: .position)
            } label: {
                SensorRow(kind: .position)
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Building blocks

private struct MapsHeader: View {
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

private struct PlaceRow: View {
    let place: SavedPlace
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(place.name)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(CoordinateFormat.decimal(latitude: place.latitude, longitude: place.longitude))
                    .font(.body.monospacedDigit().weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .textSelection(.enabled)
                Text(CoordinateFormat.dms(latitude: place.latitude, longitude: place.longitude))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
                    .textSelection(.enabled)
                if !place.note.isEmpty {
                    Text(place.note)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            .accessibilityElement(children: .combine)
            Spacer(minLength: 8)
            VStack(spacing: 8) {
                iconButton("pencil", label: String(localized: "Edit \(place.name)"), color: Theme.accent, action: onEdit)
                iconButton("trash.fill", label: String(localized: "Delete \(place.name)"), color: Theme.danger, action: onDelete)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
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

private struct AreaRow: View {
    let area: OfflineArea
    let status: OfflineAreaStatus
    let onChange: (Bool) -> Void

    private var isPrepared: Bool { status == .prepared }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(area.title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(status.label.uppercased())
                    .font(.caption.weight(.black))
                    .foregroundStyle(Theme.onAccent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(isPrepared ? Theme.ok : Theme.accent, in: Capsule())
            }
            Text(area.summary)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Text(String(localized: "About \(SizeFormat.megabytes(area.sizeMB)) · estimate"))
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
            Button {
                onChange(!isPrepared)
            } label: {
                Label(isPrepared ? String(localized: "Mark not prepared") : String(localized: "Mark prepared"),
                      systemImage: isPrepared ? "xmark.circle" : "checkmark.circle.fill")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(isPrepared ? Theme.textPrimary : Theme.accent)
                    .frame(maxWidth: .infinity, minHeight: 52)
                    .background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10)
                        .stroke(isPrepared ? Theme.surfaceBorder : Theme.accent, lineWidth: Theme.borderWidth))
            }
            .buttonStyle(.plain)
            .accessibilityHint(String(localized: "Simulated. Nothing is downloaded."))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(isPrepared ? Theme.ok : Theme.surfaceBorder, lineWidth: Theme.borderWidth)
        )
    }
}

private struct SensorRow: View {
    let kind: SensorPlaceholderView.Kind

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: kind.systemImage)
                .font(.title.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
                .frame(width: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(kind.title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(SensorPlaceholderView.requirement)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Theme.accent)
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        MapsView()
    }
    .environment(MapsStore(defaults: UserDefaults(suiteName: "preview.maps")!))
    .preferredColorScheme(.dark)
}
