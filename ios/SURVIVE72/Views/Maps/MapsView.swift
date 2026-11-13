import SwiftUI

/// SURVIVE MAPS: the offline map, saved places typed by hand, and
/// compass/position placeholders.
struct MapsView: View {
    @Environment(MapsStore.self) private var store

    @State private var isAddingPlace = false
    @State private var editingPlace: SavedPlace?
    @State private var placePendingDeletion: SavedPlace?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                OpenMapCard()

                placesSection
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

/// Big entry to the offline map, with how many areas are on the device.
private struct OpenMapCard: View {
    @Environment(OfflineMapStore.self) private var mapStore

    var body: some View {
        NavigationLink {
            OfflineMapScreen()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "map.fill")
                    .font(.system(size: 34, weight: .bold))
                    .foregroundStyle(Theme.onAccent)
                    .frame(width: 64, height: 64)
                    .background(Theme.onAccent.opacity(0.18), in: RoundedRectangle(cornerRadius: 14))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "Open the map"))
                        .font(.title2.weight(.heavy))
                    Text(mapStore.downloadedRegions.isEmpty
                         ? String(localized: "Works without internet once an area is downloaded")
                         : String(localized: "Areas on this iPhone: \(mapStore.downloadedRegions.count)"))
                        .font(.subheadline.weight(.semibold))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(Theme.onAccent)
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.onAccent)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
            .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        }
        .buttonStyle(.plain)
    }
}

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
    .environment(OfflineMapStore())
}
