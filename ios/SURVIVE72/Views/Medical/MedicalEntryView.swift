import SwiftUI

/// Detail page of one medical placeholder entry.
struct MedicalEntryView: View {
    let entry: MedicalEntry

    @Environment(MedicalStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MedicalEmergencyNotice()

                HStack(spacing: 10) {
                    Image(systemName: entry.category.systemImage)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text(entry.category.title.uppercased())
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Theme.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "Category: \(entry.category.title)"))

                Text(entry.title)
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                MedicalVerificationBadge(status: entry.status, large: true)

                Text(entry.summary)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                favoriteButton
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var favoriteButton: some View {
        let isFavorite = store.isFavorite(entry.id)
        return Button {
            store.toggleFavorite(entry.id)
        } label: {
            Label(isFavorite ? String(localized: "Bookmarked") : String(localized: "Bookmark"),
                  systemImage: isFavorite ? "star.fill" : "star")
                .font(.title3.weight(.heavy))
                .foregroundStyle(isFavorite ? Theme.background : Theme.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(isFavorite ? Theme.accent : Theme.surface,
                            in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(isFavorite ? Theme.accent : Theme.surfaceBorder,
                            lineWidth: Theme.borderWidth))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isFavorite ? .isSelected : [])
        .accessibilityHint(String(localized: "Saved only on this device."))
    }
}

/// High-contrast "VERIFIED CONTENT REQUIRED" marker.
struct MedicalVerificationBadge: View {
    let status: MedicalVerificationStatus
    var large = false

    var body: some View {
        Label(status.label, systemImage: "exclamationmark.triangle.fill")
            .font(large ? .headline.weight(.black) : .caption.weight(.heavy))
            .foregroundStyle(Theme.background)
            .padding(.horizontal, large ? 12 : 8)
            .padding(.vertical, large ? 8 : 3)
            .background(Theme.accent, in: Capsule())
            .accessibilityLabel(status.label.capitalized)
    }
}

/// Always-visible emergency line shown on every Medical screen.
struct MedicalEmergencyNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.octagon.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.danger)
                .accessibilityHidden(true)
            Text(MedicalLibrary.emergencyNotice)
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.danger, lineWidth: Theme.borderWidth)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        MedicalEntryView(entry: MedicalLibraryContent.entries[0])
    }
    .environment(MedicalStore(defaults: UserDefaults(suiteName: "preview.medical")!))
    .preferredColorScheme(.dark)
}
