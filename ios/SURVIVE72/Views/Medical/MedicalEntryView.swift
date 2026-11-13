import SwiftUI
import UIKit

/// Detail page of one first aid card.
struct MedicalEntryView: View {
    let entry: MedicalEntry

    @Environment(MedicalStore.self) private var store
    @State private var showStepByStep = false

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

                Button {
                    showStepByStep = true
                } label: {
                    Label(String(localized: "Step by step, full screen"), systemImage: "rectangle.portrait.on.rectangle.portrait.angled.fill")
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(Theme.onAccent)
                        .frame(maxWidth: .infinity, minHeight: 60)
                        .background(Theme.accent, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                }
                .buttonStyle(.plain)
                .accessibilityHint(String(localized: "Shows one step at a time in very large text."))

                if entry.showsCompressionRhythm {
                    CompressionRhythmView()
                }

                ForEach(Array(entry.steps.enumerated()), id: \.offset) { index, step in
                    IllustratedRow(symbol: step.symbol, text: step.text, number: index + 1)
                }

                favoriteButton

                MedicalDisclaimer()
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showStepByStep) {
            MedicalStepByStepView(entry: entry)
        }
    }

    private var favoriteButton: some View {
        let isFavorite = store.isFavorite(entry.id)
        return Button {
            store.toggleFavorite(entry.id)
        } label: {
            Label(isFavorite ? String(localized: "Bookmarked") : String(localized: "Bookmark"),
                  systemImage: isFavorite ? "star.fill" : "star")
                .font(.title3.weight(.heavy))
                .foregroundStyle(isFavorite ? Theme.onAccent : Theme.textPrimary)
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

/// One step per page, huge pictogram and text, swipe or buttons to move.
/// Meant to be read at arm's length while helping someone.
struct MedicalStepByStepView: View {
    let entry: MedicalEntry

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(String(localized: "Step \(index + 1) of \(entry.steps.count)"))
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundStyle(Theme.textPrimary)
                }
                .accessibilityLabel(String(localized: "Close"))
            }

            TabView(selection: $index) {
                ForEach(Array(entry.steps.enumerated()), id: \.offset) { position, step in
                    VStack(spacing: 28) {
                        Spacer(minLength: 0)
                        Image(systemName: SymbolCheck.safe(step.symbol))
                            .font(.system(size: 110, weight: .bold))
                            .foregroundStyle(Theme.onAccent)
                            .frame(width: 200, height: 200)
                            .background(Theme.accent, in: RoundedRectangle(cornerRadius: 32))
                            .accessibilityHidden(true)
                        Text(step.text)
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(Theme.textPrimary)
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.6)
                            .fixedSize(horizontal: false, vertical: true)
                        if entry.showsCompressionRhythm && step.symbol == "hand.point.down.fill" {
                            CompressionRhythmView()
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, 8)
                    .tag(position)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            HStack(spacing: 12) {
                stepButton(String(localized: "Back"), systemImage: "chevron.left", enabled: index > 0) {
                    index -= 1
                }
                stepButton(String(localized: "Next"), systemImage: "chevron.right", enabled: index < entry.steps.count - 1) {
                    index += 1
                }
            }

            Text(MedicalLibrary.emergencyNotice)
                .font(.headline.weight(.heavy))
                .foregroundStyle(Theme.danger)
                .multilineTextAlignment(.center)
        }
        .padding(16)
        .background(Theme.background.ignoresSafeArea())
    }

    private func stepButton(_ title: String, systemImage: String, enabled: Bool,
                            action: @escaping () -> Void) -> some View {
        Button {
            withAnimation { action() }
        } label: {
            Label(title, systemImage: systemImage)
                .font(.title3.weight(.heavy))
                .foregroundStyle(enabled ? Theme.textPrimary : Theme.textSecondary)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(enabled ? Theme.accent : Theme.surfaceBorder, lineWidth: Theme.borderWidth))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

/// Animated guide for the chest-compression rhythm: a circle that "pushes"
/// 110 times a minute (inside the 100-120 range), with an optional vibration
/// on each beat. Nothing is recorded.
struct CompressionRhythmView: View {
    static let beatsPerMinute = 110.0

    @State private var running = false
    @State private var pressed = false
    @State private var timer: Timer?
    private let haptic = UIImpactFeedbackGenerator(style: .heavy)

    var body: some View {
        VStack(spacing: 12) {
            Text(String(localized: "Compression rhythm: 110 per minute"))
                .font(.headline.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            ZStack {
                Circle()
                    .stroke(Theme.surfaceBorder, lineWidth: 6)
                    .frame(width: 130, height: 130)
                Circle()
                    .fill(Theme.danger)
                    .frame(width: pressed ? 80 : 120, height: pressed ? 80 : 120)
                Text(String(localized: "PUSH"))
                    .font(.title2.weight(.black))
                    .foregroundStyle(Theme.textPrimary)
            }
            .frame(height: 140)
            .accessibilityHidden(true)

            Button {
                running ? stop() : start()
            } label: {
                Label(running ? String(localized: "Stop rhythm") : String(localized: "Start rhythm"),
                      systemImage: running ? "stop.fill" : "play.fill")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 56)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Theme.danger, lineWidth: Theme.borderWidth))
            }
            .buttonStyle(.plain)
            .accessibilityHint(String(localized: "Vibrates at the pace of chest compressions."))
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(Theme.surface.opacity(0.5), in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .onDisappear { stop() }
    }

    private func start() {
        running = true
        haptic.prepare()
        let interval = 60.0 / Self.beatsPerMinute
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in beat(interval) }
        }
    }

    @MainActor
    private func beat(_ interval: Double) {
        haptic.impactOccurred()
        withAnimation(.easeIn(duration: interval * 0.35)) { pressed = true }
        withAnimation(.easeOut(duration: interval * 0.5).delay(interval * 0.4)) { pressed = false }
    }

    private func stop() {
        timer?.invalidate()
        timer = nil
        running = false
        pressed = false
    }
}

/// Fixed disclaimer: sources, no liability, not a substitute for a doctor.
struct MedicalDisclaimer: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(MedicalLibrary.disclaimer)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.accent, lineWidth: Theme.borderWidth)
        )
        .accessibilityElement(children: .combine)
    }
}

/// High-contrast "NOT YET REVIEWED BY A DOCTOR" marker.
struct MedicalVerificationBadge: View {
    let status: MedicalVerificationStatus
    var large = false

    var body: some View {
        Label(status.label, systemImage: "exclamationmark.triangle.fill")
            .font(large ? .headline.weight(.black) : .caption.weight(.heavy))
            .foregroundStyle(Theme.onAccent)
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
