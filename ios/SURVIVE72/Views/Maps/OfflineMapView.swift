import CoreLocation
import MapLibre
import SwiftUI

/// The offline map: downloaded areas, the saved places and the iPhone's
/// position (GPS works without internet).
struct OfflineMapScreen: View {
    @Environment(OfflineMapStore.self) private var mapStore
    @Environment(MapsStore.self) private var mapsStore
    @Environment(\.colorScheme) private var colorScheme

    @State private var styleURL: URL?
    @State private var followUser = false
    @State private var styleFailed = false

    private var styleKey: String {
        (colorScheme == .dark ? "dark" : "light") + ":" + mapStore.downloadedRegions.map(\.id).joined(separator: ",")
    }

    var body: some View {
        Group {
            if mapStore.downloadedRegions.isEmpty {
                NoMapAreasView()
            } else if let styleURL, let first = mapStore.downloadedRegions.first {
                MapLibreMapView(styleURL: styleURL, start: first, places: mapsStore.places,
                                followUser: $followUser)
                    .ignoresSafeArea(edges: .bottom)
                    .overlay(alignment: .bottomTrailing) { locateButton }
                    .overlay(alignment: .bottomLeading) { attribution }
            } else if styleFailed {
                Label(String(localized: "The map could not be opened."), systemImage: "exclamationmark.triangle.fill")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Theme.danger)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(String(localized: "Map"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    MapDownloadsView()
                } label: {
                    Label(String(localized: "Map areas"), systemImage: "arrow.down.circle")
                }
            }
        }
        .task(id: styleKey) { buildStyle() }
    }

    private var locateButton: some View {
        Button {
            followUser = true
        } label: {
            Image(systemName: followUser ? "location.fill" : "location")
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.onAccent)
                .frame(width: 60, height: 60)
                .background(Theme.accent, in: Circle())
                .shadow(radius: 3)
        }
        .padding(20)
        .accessibilityLabel(String(localized: "Show my position"))
    }

    private var attribution: some View {
        Text(verbatim: "© OpenStreetMap · Protomaps")
            .font(.caption2.weight(.semibold))
            .foregroundStyle(Theme.textPrimary)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Theme.surface.opacity(0.85), in: Capsule())
            .padding(.leading, 8)
            .padding(.bottom, 28)
    }

    private func buildStyle() {
        guard let resources = OfflineMapStyle.resourcesURL else {
            styleFailed = true
            return
        }
        let dark = colorScheme == .dark
        let regions = mapStore.downloadedRegions.map { (id: $0.id, file: mapStore.fileURL(for: $0)) }
        do {
            let data = try OfflineMapStyle.build(regions: regions, dark: dark, resources: resources)
            let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            // A new name each time, so the map reloads the style.
            let url = caches.appendingPathComponent("offline-style-\(UUID().uuidString).json")
            try data.write(to: url, options: .atomic)
            if let old = styleURL { try? FileManager.default.removeItem(at: old) }
            styleURL = url
            styleFailed = false
        } catch {
            styleFailed = true
        }
    }
}

/// Shown when no area is on the device yet.
private struct NoMapAreasView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Image(systemName: "map.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                Text(String(localized: "No map on this iPhone yet"))
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(String(localized: "Download your area once, on Wi-Fi. Then the map works without internet, with your position from GPS."))
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                NavigationLink {
                    MapDownloadsView()
                } label: {
                    Label(String(localized: "Choose areas to download"), systemImage: "arrow.down.circle.fill")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(Theme.onAccent)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                }
                .buttonStyle(.plain)
            }
            .padding(16)
        }
    }
}

// MARK: - MapLibre

/// Wraps MapLibre's map view for SwiftUI.
private struct MapLibreMapView: UIViewRepresentable {
    let styleURL: URL
    let start: MapRegion
    let places: [SavedPlace]
    @Binding var followUser: Bool

    func makeCoordinator() -> Coordinator { Coordinator(followUser: $followUser) }

    func makeUIView(context: Context) -> MLNMapView {
        let view = MLNMapView(frame: .zero, styleURL: styleURL)
        view.delegate = context.coordinator
        view.logoView.isHidden = true
        view.showsUserLocation = true
        view.minimumZoomLevel = 2
        view.maximumZoomLevel = 18
        view.setCenter(CLLocationCoordinate2D(latitude: start.centerLatitude, longitude: start.centerLongitude),
                       zoomLevel: start.fittingZoom, animated: false)
        context.coordinator.currentStyle = styleURL
        context.coordinator.sync(places: places, on: view)
        return view
    }

    func updateUIView(_ view: MLNMapView, context: Context) {
        context.coordinator.followUser = $followUser
        if context.coordinator.currentStyle != styleURL {
            context.coordinator.currentStyle = styleURL
            view.styleURL = styleURL
        }
        context.coordinator.sync(places: places, on: view)
        if followUser, view.userTrackingMode == .none {
            view.setUserTrackingMode(.follow, animated: true, completionHandler: nil)
        }
    }

    final class Coordinator: NSObject, MLNMapViewDelegate {
        var followUser: Binding<Bool>
        var currentStyle: URL?
        private var shownPlaces: [SavedPlace] = []

        init(followUser: Binding<Bool>) {
            self.followUser = followUser
        }

        func sync(places: [SavedPlace], on view: MLNMapView) {
            guard places != shownPlaces else { return }
            shownPlaces = places
            if let old = view.annotations { view.removeAnnotations(old) }
            let pins = places.map { place -> MLNPointAnnotation in
                let pin = MLNPointAnnotation()
                pin.coordinate = CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude)
                pin.title = place.name
                pin.subtitle = place.note.isEmpty ? nil : place.note
                return pin
            }
            view.addAnnotations(pins)
        }

        func mapView(_ mapView: MLNMapView, annotationCanShowCallout annotation: MLNAnnotation) -> Bool {
            true
        }

        func mapView(_ mapView: MLNMapView, didChange mode: MLNUserTrackingMode, animated: Bool) {
            if mode == .none, followUser.wrappedValue {
                followUser.wrappedValue = false
            }
        }
    }
}

// MARK: - Downloads

/// List of the areas that can be downloaded, with their state.
struct MapDownloadsView: View {
    @Environment(OfflineMapStore.self) private var store
    @State private var regionPendingDeletion: MapRegion?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                summary
                if !store.canDownload {
                    Label(String(localized: "Map files are not online yet: downloads will be switched on in a next version."),
                          systemImage: "clock.fill")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                            .stroke(Theme.accent, lineWidth: Theme.borderWidth))
                }
                group(String(localized: "Italian regions"), regions: store.regions.filter { !$0.isCountry })
                group(String(localized: "Whole countries"), regions: store.regions.filter(\.isCountry))
                Text(String(localized: "Map data © OpenStreetMap contributors, ODbL licence. Map style by Protomaps."))
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(String(localized: "Map areas"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear { store.refresh() }
        .alert(
            String(localized: "Delete map area?"),
            isPresented: Binding(
                get: { regionPendingDeletion != nil },
                set: { if !$0 { regionPendingDeletion = nil } }
            ),
            presenting: regionPendingDeletion
        ) { region in
            Button(String(localized: "Delete"), role: .destructive) { store.delete(region) }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: { region in
            Text(String(localized: "\(region.title) will be removed from this iPhone. You can download it again later."))
        }
    }

    private var summary: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(String(localized: "Download your area once, on Wi-Fi. Then the map works without internet, with your position from GPS."))
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
            Text(String(localized: "On this iPhone: \(store.downloadedRegions.count) areas · \(SizeFormat.bytes(store.usedBytes))"))
                .font(.subheadline.weight(.bold).monospacedDigit())
                .foregroundStyle(Theme.textSecondary)
        }
    }

    private func group(_ title: String, regions: [MapRegion]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
                .accessibilityAddTraits(.isHeader)
            ForEach(regions.sorted { $0.title.localizedCompare($1.title) == .orderedAscending }) { region in
                MapRegionRow(region: region, state: store.state(of: region), canDownload: store.canDownload,
                             onDownload: { store.download(region) },
                             onCancel: { store.cancel(region) },
                             onDelete: { regionPendingDeletion = region })
            }
        }
    }
}

private struct MapRegionRow: View {
    let region: MapRegion
    let state: MapDownloadState
    let canDownload: Bool
    let onDownload: () -> Void
    let onCancel: () -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(region.title)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                Spacer(minLength: 8)
                Text(sizeText)
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }
            if case .downloading(let fraction) = state {
                ProgressView(value: fraction)
                    .tint(Theme.accent)
                    .accessibilityLabel(String(localized: "Downloading \(Int(fraction * 100)) percent"))
            }
            if state == .failed {
                Text(String(localized: "Download failed. Check the connection and try again."))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.danger)
            }
            actionButton
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
            .stroke(state.isDownloaded ? Theme.ok : Theme.surfaceBorder, lineWidth: Theme.borderWidth))
    }

    private var sizeText: String {
        if case .downloaded(let bytes) = state { return SizeFormat.bytes(bytes) }
        return String(localized: "about \(SizeFormat.megabytes(region.estimatedMB))")
    }

    @ViewBuilder
    private var actionButton: some View {
        switch state {
        case .downloaded:
            rowButton(String(localized: "Downloaded · Delete"), systemImage: "checkmark.circle.fill",
                      color: Theme.ok, action: onDelete)
                .accessibilityLabel(String(localized: "Delete \(region.title)"))
        case .downloading:
            rowButton(String(localized: "Stop"), systemImage: "xmark.circle.fill", color: Theme.danger, action: onCancel)
        case .notDownloaded, .failed:
            rowButton(String(localized: "Download"), systemImage: "arrow.down.circle.fill",
                      color: canDownload ? Theme.accent : Theme.textSecondary, action: onDownload)
                .disabled(!canDownload)
                .accessibilityLabel(String(localized: "Download \(region.title)"))
        }
    }

    private func rowButton(_ title: String, systemImage: String, color: Color,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.heavy))
                .foregroundStyle(color)
                .frame(maxWidth: .infinity, minHeight: 48)
                .background(Theme.background, in: RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(color, lineWidth: Theme.borderWidth))
        }
        .buttonStyle(.plain)
    }
}
