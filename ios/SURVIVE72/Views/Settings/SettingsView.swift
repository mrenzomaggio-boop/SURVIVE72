import SwiftUI

/// SURVIVE SETTINGS: units, contrast, battery saver, privacy and local data reset.
struct SettingsView: View {
    @Environment(SettingsStore.self) private var settingsStore
    @Environment(KitChecklistStore.self) private var kitStore
    @Environment(AlertPlanStore.self) private var alertStore
    @Environment(DownloadsStore.self) private var downloadsStore
    @Environment(ConnectStore.self) private var connectStore
    @Environment(ToolsState.self) private var toolsState

    @State private var isConfirmingReset = false
    @State private var didReset = false

    private var settings: AppSettings { settingsStore.settings }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                unitsSection
                displaySection
                privacySection
                resetSection
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .alert("Erase all local data?", isPresented: $isConfirmingReset) {
            Button("Erase", role: .destructive) {
                LocalDataReset.perform(kit: kitStore, alert: alertStore, settings: settingsStore,
                                       downloads: downloadsStore, connect: connectStore, tools: toolsState)
                didReset = true
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Kit checklist, emergency plan and contacts, local chat and queue, prepared packs and preferences will be removed from this device. This cannot be undone.")
        }
    }

    // MARK: Units

    private var unitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsHeader(title: "Units", systemImage: "ruler.fill")
            HStack(spacing: 10) {
                ForEach(UnitSystem.allCases) { system in
                    let isSelected = settings.unitSystem == system
                    Button {
                        var updated = settings
                        updated.unitSystem = system
                        settingsStore.update(updated)
                    } label: {
                        Text(system.title)
                            .font(.title3.weight(.heavy))
                            .foregroundStyle(isSelected ? Theme.background : Theme.textPrimary)
                            .frame(maxWidth: .infinity, minHeight: 56)
                            .background(isSelected ? Theme.accent : Theme.surface,
                                        in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                .stroke(isSelected ? Theme.accent : Theme.surfaceBorder,
                                        lineWidth: Theme.borderWidth))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isSelected ? .isSelected : [])
                }
            }
            Text("Example: water per person per day \(UnitFormat.volume(liters: 4, in: settings.unitSystem)), 5 km = \(UnitFormat.distance(kilometers: 5, in: settings.unitSystem)).")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: Display and battery

    private var displaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsHeader(title: "Display and battery", systemImage: "circle.lefthalf.filled")
            SettingsToggle(
                title: "High contrast",
                detail: "Bolder text across the app, on top of the dark high-contrast theme.",
                isOn: binding(\.highContrast)
            )
            SettingsToggle(
                title: "Battery saver",
                detail: "Fewer screen updates: the stopwatch refreshes once per second.",
                isOn: binding(\.batterySaver)
            )
        }
    }

    private func binding(_ keyPath: WritableKeyPath<AppSettings, Bool>) -> Binding<Bool> {
        Binding(
            get: { settingsStore.settings[keyPath: keyPath] },
            set: { newValue in
                var updated = settingsStore.settings
                updated[keyPath: keyPath] = newValue
                settingsStore.update(updated)
            }
        )
    }

    // MARK: Privacy

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsHeader(title: "Privacy", systemImage: "lock.fill")
            VStack(alignment: .leading, spacing: 10) {
                PrivacyLine(text: "Everything stays on this device.")
                PrivacyLine(text: "No account, no network, no analytics, no permissions.")
                PrivacyLine(text: "Nothing is sent: SOS messages are only copied or queued locally.")
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth))

            Text("Stored now: \(kitStore.totalProgress.checked) kit items checked, \(alertStore.contacts.count) emergency contacts, \(downloadsStore.preparedIDs.count) packs marked prepared.")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
    }

    // MARK: Reset

    private var resetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SettingsHeader(title: "Local data", systemImage: "trash.fill")
            Button(role: .destructive) {
                isConfirmingReset = true
            } label: {
                Label(didReset ? "Local data erased" : "Erase all local data",
                      systemImage: didReset ? "checkmark.circle.fill" : "trash.fill")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(didReset ? Theme.ok : Theme.danger)
                    .frame(maxWidth: .infinity, minHeight: 60)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(didReset ? Theme.ok : Theme.danger, lineWidth: Theme.borderWidth))
            }
            .buttonStyle(.plain)
            .accessibilityHint("Asks for confirmation, then removes all SURVIVE 72 data from this device.")
        }
    }
}

private struct SettingsHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title.uppercased())
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct SettingsToggle: View {
    let title: String
    let detail: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .tint(Theme.ok)
        .padding(14)
        .frame(minHeight: 72)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
            .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth))
    }
}

private struct PrivacyLine: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "checkmark.shield.fill")
                .foregroundStyle(Theme.ok)
                .accessibilityHidden(true)
            Text(text)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
