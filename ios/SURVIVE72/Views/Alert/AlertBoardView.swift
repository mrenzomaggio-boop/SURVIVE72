import SwiftUI

/// The alert board: official alerts only (weather warnings, earthquakes,
/// large disasters). Nobody can write here. Alerts are downloaded when there
/// is internet and passed from phone to phone when there is not.
struct AlertBoardView: View {
    @Environment(OfficialAlertStore.self) private var store
    @Environment(MeshService.self) private var mesh

    @State private var isChoosingCountries = false

    var body: some View {
        let alerts = store.visible

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                sourceCard

                VStack(alignment: .leading, spacing: 12) {
                    MeshSectionHeader(title: String(localized: "Official alerts"), systemImage: "checkmark.shield.fill")

                    Button {
                        isChoosingCountries = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "globe.europe.africa.fill")
                                .font(.title3.weight(.bold))
                                .foregroundStyle(Theme.accent)
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(localized: "Countries you follow"))
                                    .font(.subheadline.weight(.heavy))
                                    .foregroundStyle(Theme.textSecondary)
                                Text(followedText)
                                    .font(.headline.weight(.heavy))
                                    .foregroundStyle(Theme.textPrimary)
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer(minLength: 0)
                            Text(String(localized: "Change"))
                                .font(.headline.weight(.heavy))
                                .foregroundStyle(Theme.accent)
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, minHeight: 60, alignment: .leading)
                        .meshCardBackground()
                        .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    }
                    .buttonStyle(.plain)

                    if alerts.isEmpty {
                        Text(store.lastUpdate == nil
                             ? String(localized: "No alerts on this phone yet. Connect to the internet once, or stay near a phone with the app and the network on.")
                             : String(localized: "No official alerts right now for the places you follow."))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(alerts) { alert in
                        OfficialAlertRow(alert: alert)
                    }
                }

                MeshStatusCard()
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .refreshable { await store.refresh(force: true) }
        .navigationTitle(String(localized: "Alert board"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isChoosingCountries) {
            OfficialAlertCountriesView()
                .environment(store)
        }
        .task {
            store.requestNotificationPermission()
            await store.refresh()
        }
    }

    private var followedText: String {
        var names = store.preferences.countries.map(OfficialAlertCountries.name).sorted()
        if store.preferences.showsWorld { names.append(String(localized: "large disasters worldwide")) }
        return names.isEmpty ? String(localized: "None") : names.joined(separator: ", ")
    }

    // MARK: Source and freshness

    private var sourceCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(String(localized: "Only official alerts appear here: weather warnings of the national weather services (Meteoalarm), earthquakes (INGV) and large disasters (GDACS). Nobody can write on this board, and every alert is checked with a digital signature."))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 10) {
                if store.isRefreshing {
                    ProgressView()
                } else {
                    Image(systemName: store.lastOrigin == .nearbyPhone ? "antenna.radiowaves.left.and.right" : "arrow.down.circle.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(store.lastUpdate == nil ? Theme.textSecondary : Theme.ok)
                        .accessibilityHidden(true)
                }
                Text(freshnessText)
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
            }

            if store.lastDownloadFailed {
                Text(mesh.isEnabled
                     ? String(localized: "No internet: new alerts can still arrive from nearby phones.")
                     : String(localized: "No internet. Switch on the network between nearby phones to receive alerts from them."))
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Theme.accent)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button {
                Task { await store.refresh(force: true) }
            } label: {
                Label(String(localized: "Update now"), systemImage: "arrow.clockwise")
                    .font(.headline.weight(.heavy))
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.bordered)
            .tint(Theme.accent)
            .disabled(store.isRefreshing)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .meshCardBackground()
    }

    private var freshnessText: String {
        guard let date = store.lastUpdate else { return String(localized: "Never updated") }
        let time = date.formatted(date: .abbreviated, time: .shortened)
        return store.lastOrigin == .nearbyPhone
            ? String(localized: "Updated \(time), from a nearby phone")
            : String(localized: "Updated \(time)")
    }
}

/// One official alert, coloured by how serious it is.
private struct OfficialAlertRow: View {
    let alert: OfficialAlert
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text(severityLabel)
                    .font(.caption.weight(.black))
                    .foregroundStyle(alert.severity == .moderate ? Color.black : Color.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(severityColor, in: Capsule())
                Text(placeLabel)
                    .font(.caption.weight(.black))
                    .foregroundStyle(Theme.textSecondary)
                Spacer(minLength: 0)
                Image(systemName: alert.systemImage)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(severityColor)
                    .accessibilityHidden(true)
            }

            Text(alert.title)
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            if !alert.area.isEmpty {
                Text(alert.area)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(isExpanded ? nil : 2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(timeText)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(Theme.textSecondary)

            if isExpanded, !alert.detail.isEmpty {
                Text(alert.detail)
                    .font(.body.weight(.medium))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack(spacing: 16) {
                if !alert.detail.isEmpty || alert.area.count > 80 {
                    Button(isExpanded ? String(localized: "Less") : String(localized: "Details")) {
                        isExpanded.toggle()
                    }
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Theme.accent)
                }
                if let url = URL(string: alert.link), url.scheme == "https" {
                    Link(destination: url) {
                        Label(String(localized: "Source: \(alert.sourceName)"), systemImage: "arrow.up.right.square")
                            .font(.subheadline.weight(.heavy))
                    }
                    .foregroundStyle(Theme.info)
                } else {
                    Text(String(localized: "Source: \(alert.sourceName)"))
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(severityColor, lineWidth: alert.severity == .extreme ? 4 : 2)
        )
        .accessibilityElement(children: .contain)
    }

    private var severityColor: Color {
        switch alert.severity {
        case .extreme: Theme.danger
        case .severe: Color(red: 0.96, green: 0.45, blue: 0.0)
        case .moderate: Color(red: 0.98, green: 0.80, blue: 0.10)
        }
    }

    private var severityLabel: String {
        switch alert.severity {
        case .extreme: String(localized: "RED")
        case .severe: String(localized: "ORANGE")
        case .moderate: String(localized: "YELLOW")
        }
    }

    private var placeLabel: String {
        alert.country == OfficialAlert.world
            ? String(localized: "World")
            : OfficialAlertCountries.name(alert.country)
    }

    private var timeText: String {
        let start = alert.startDate.formatted(date: .abbreviated, time: .shortened)
        let end = alert.expiryDate.formatted(date: .abbreviated, time: .shortened)
        return String(localized: "From \(start) to \(end)")
    }
}

/// Which countries to follow, and whether to see large disasters worldwide.
struct OfficialAlertCountriesView: View {
    @Environment(OfficialAlertStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle(isOn: Binding(get: { store.preferences.showsWorld }, set: { store.setShowsWorld($0) })) {
                        Text(String(localized: "Large disasters worldwide"))
                            .font(.headline.weight(.heavy))
                    }
                    .tint(Theme.ok)
                } footer: {
                    Text(String(localized: "Floods, cyclones, strong earthquakes and eruptions anywhere in the world (GDACS)."))
                }
                Section(String(localized: "Countries")) {
                    ForEach(OfficialAlertCountries.sorted, id: \.self) { code in
                        Toggle(isOn: Binding(get: { store.preferences.countries.contains(code) },
                                             set: { store.setFollowed(code, $0) })) {
                            Text(OfficialAlertCountries.name(code))
                                .font(.headline.weight(.semibold))
                        }
                        .tint(Theme.ok)
                    }
                }
            }
            .navigationTitle(String(localized: "Countries you follow"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Done")) { dismiss() }
                }
            }
        }
    }
}
