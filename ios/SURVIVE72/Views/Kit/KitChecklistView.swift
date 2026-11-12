import SwiftUI

/// SURVIVE KIT: local 72-hour checklist with overall and per-category progress.
struct KitChecklistView: View {
    @Environment(KitChecklistStore.self) private var store
    @State private var isConfirmingReset = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                KitProgressCard(
                    title: String(localized: "72-hour kit"),
                    progress: store.totalProgress
                )

                ForEach(KitCategory.allCases) { category in
                    categorySection(category)
                }

                resetButton
                    .padding(.top, 8)
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(String(localized: "Kit"))
        .navigationBarTitleDisplayMode(.large)
        .alert(String(localized: "Reset checklist?"), isPresented: $isConfirmingReset) {
            Button(String(localized: "Reset"), role: .destructive) {
                store.reset()
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "All items will be marked as not packed. This cannot be undone."))
        }
    }

    @ViewBuilder
    private func categorySection(_ category: KitCategory) -> some View {
        let progress = store.progress(for: category)

        VStack(alignment: .leading, spacing: 10) {
            KitCategoryHeader(category: category, progress: progress)

            ForEach(store.categoryItems(category)) { item in
                KitItemRow(
                    item: item,
                    isChecked: store.isChecked(item),
                    onToggle: { store.toggle(item) }
                )
            }
        }
    }

    private var resetButton: some View {
        Button(role: .destructive) {
            isConfirmingReset = true
        } label: {
            Label(String(localized: "Reset checklist"), systemImage: "arrow.counterclockwise")
                .font(.title3.weight(.heavy))
                .frame(maxWidth: .infinity, minHeight: 60)
        }
        .buttonStyle(.plain)
        .foregroundStyle(Theme.danger)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.danger, lineWidth: Theme.borderWidth)
        )
        .disabled(store.totalProgress.checked == 0)
        .opacity(store.totalProgress.checked == 0 ? 0.5 : 1)
        .accessibilityHint(String(localized: "Asks for confirmation, then clears every checked item."))
    }
}

/// Category title with its own progress, e.g. "Water 2/3".
private struct KitCategoryHeader: View {
    let category: KitCategory
    let progress: KitProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Image(systemName: category.systemImage)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Theme.accent)
                    .frame(width: 32)
                    .accessibilityHidden(true)
                Text(category.title.uppercased())
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                Spacer()
                Text(progress.shortLabel)
                    .font(.title3.weight(.heavy).monospacedDigit())
                    .foregroundStyle(progress.isComplete ? Theme.ok : Theme.textSecondary)
            }
            KitProgressBar(fraction: progress.fraction, isComplete: progress.isComplete)
                .frame(height: 8)
        }
        .padding(.top, 4)
        .accessibilityElement(children: .ignore)
        .accessibilityAddTraits(.isHeader)
        .accessibilityLabel(category.title)
        .accessibilityValue(progress.accessibilityDescription)
    }
}

#Preview {
    NavigationStack {
        KitChecklistView()
    }
    .environment(KitChecklistStore(defaults: UserDefaults(suiteName: "preview.kit")!))
    .preferredColorScheme(.dark)
}
