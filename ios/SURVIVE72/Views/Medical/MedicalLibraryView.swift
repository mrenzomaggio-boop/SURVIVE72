import SwiftUI

/// SURVIVE MEDICAL: offline first aid cards with local search and category
/// filters. Every card shows the 112 line, the disclaimer and its review state.
struct MedicalLibraryView: View {
    private let library = MedicalLibrary()

    @Environment(MedicalStore.self) private var store
    @State private var query = ""

    private var selectedCategory: Binding<MedicalCategory?> {
        Binding(
            get: { store.lastCategory },
            set: { store.setLastCategory($0) }
        )
    }

    private var results: [MedicalEntry] {
        library.search(query, in: store.lastCategory)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MedicalEmergencyNotice()
                MedicalDisclaimer()

                MedicalCategoryFilterBar(library: library, selected: selectedCategory)

                Text(resultsSummary)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityAddTraits(.updatesFrequently)

                if results.isEmpty {
                    EmptyMedicalResults()
                } else {
                    LazyVStack(spacing: Theme.spacing) {
                        ForEach(results) { entry in
                            NavigationLink(value: entry) {
                                MedicalEntryRow(entry: entry, isFavorite: store.isFavorite(entry.id))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(String(localized: "Medical"))
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "Search topics")
        )
        .autocorrectionDisabled()
        .navigationDestination(for: MedicalEntry.self) { entry in
            MedicalEntryView(entry: entry)
        }
        // The cards are not reviewed by a doctor: say so before the first use.
        .fullScreenCover(isPresented: Binding(get: { !store.hasAcceptedWarning }, set: { _ in })) {
            MedicalWarningView { store.acceptWarning() }
        }
    }

    private var resultsSummary: String {
        let scope = store.lastCategory?.title ?? String(localized: "all categories")
        return results.count == 1
            ? String(localized: "\(results.count) topic in \(scope)")
            : String(localized: "\(results.count) topics in \(scope)")
    }
}

/// Horizontal row of large filter chips: All + one per category.
private struct MedicalCategoryFilterBar: View {
    let library: MedicalLibrary
    @Binding var selected: MedicalCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                chip(title: String(localized: "All"), systemImage: "square.grid.2x2.fill",
                     count: library.count(in: nil), isSelected: selected == nil) {
                    selected = nil
                }
                ForEach(MedicalCategory.allCases) { category in
                    chip(title: category.title, systemImage: category.systemImage,
                         count: library.count(in: category), isSelected: selected == category) {
                        selected = category
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(
        title: String,
        systemImage: String,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.heavy))
                .foregroundStyle(isSelected ? Theme.onAccent : Theme.textPrimary)
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .background(isSelected ? Theme.accent : Theme.surface, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? Theme.accent : Theme.surfaceBorder,
                                          lineWidth: Theme.borderWidth))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "\(title) filter"))
        .accessibilityValue(count == 1 ? String(localized: "\(count) topic") : String(localized: "\(count) topics"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// One entry in the result list.
private struct MedicalEntryRow: View {
    let entry: MedicalEntry
    let isFavorite: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: entry.category.systemImage)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(entry.title)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(Theme.textPrimary)
                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.headline)
                            .foregroundStyle(Theme.accent)
                            .accessibilityHidden(true)
                    }
                }
                Text(entry.summary)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Text(entry.category.title.uppercased())
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Theme.textSecondary)
                    MedicalVerificationBadge(status: entry.status)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth)
        )
        .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isFavorite ? String(localized: "\(entry.title), bookmarked. \(entry.summary)") : "\(entry.title). \(entry.summary)")
        .accessibilityValue("\(entry.category.title), \(entry.status.label.lowercased())")
        .accessibilityAddTraits(.isButton)
    }
}

private struct EmptyMedicalResults: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
            Text(String(localized: "No topics found"))
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Text(String(localized: "Try another word or choose All."))
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        MedicalLibraryView()
    }
    .environment(MedicalStore(defaults: UserDefaults(suiteName: "preview.medical")!))
    .preferredColorScheme(.dark)
}

/// Shown before the first use of Medical: the cards are not reviewed by a doctor.
struct MedicalWarningView: View {
    let onAccept: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(Theme.danger)
                    .accessibilityHidden(true)

                Text(String(localized: "Before you use Medical"))
                    .font(.largeTitle.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                    .accessibilityAddTraits(.isHeader)

                VStack(alignment: .leading, spacing: 14) {
                    warningLine(String(localized: "These cards have not been reviewed by a doctor. They may contain mistakes or leave out important steps."))
                    warningLine(String(localized: "They do not replace a doctor, the emergency services or a first aid course."))
                    warningLine(String(localized: "In an emergency, call 112 first and follow what the operator tells you."))
                }

                MedicalDisclaimer()

                BigButton(title: String(localized: "I understand"), systemImage: "checkmark", color: Theme.accent) {
                    onAccept()
                }
            }
            .padding(20)
        }
        .background(Theme.background.ignoresSafeArea())
        .interactiveDismissDisabled()
    }

    private func warningLine(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "circle.fill")
                .font(.system(size: 8))
                .padding(.top, 8)
                .foregroundStyle(Theme.danger)
                .accessibilityHidden(true)
            Text(text)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
