import SwiftUI
import UIKit

/// On-screen SOS signal: the screen slowly shows ... --- ... in white on black.
/// It starts only when the user taps Start, and changes at most twice per second.
struct SOSSignalView: View {
    @Environment(ToolsState.self) private var tools

    var body: some View {
        let signal = tools.sosSignal

        VStack(spacing: 16) {
            if signal.isActive {
                TimelineView(.animation(minimumInterval: 0.1, paused: false)) { context in
                    let isOn = signal.isLightOn(at: context.date)
                    let letter = signal.currentLetter(at: context.date)
                    SignalPanel(isOn: isOn, letter: letter)
                }
            } else {
                IdlePanel()
            }

            ToolButton(
                title: signal.isActive ? "Stop SOS signal" : "Start SOS signal",
                systemImage: signal.isActive ? "stop.fill" : "play.fill",
                style: signal.isActive ? .destructive : .primary
            ) {
                if signal.isActive {
                    tools.sosSignal.stop()
                } else {
                    tools.sosSignal.start(at: .now)
                }
            }
            .accessibilityHint(signal.isActive
                ? "Stops the light pattern."
                : "Shows a slow SOS light pattern on this screen. Nothing is sent.")
        }
        .padding(16)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("SOS signal")
        .navigationBarTitleDisplayMode(.inline)
        // Keep the screen awake only while the signal is running.
        .onChange(of: signal.isActive, initial: true) { _, isActive in
            UIApplication.shared.isIdleTimerDisabled = isActive
        }
        .onDisappear {
            tools.sosSignal.stop()
            UIApplication.shared.isIdleTimerDisabled = false
        }
    }
}

private struct SignalPanel: View {
    let isOn: Bool
    let letter: Character?

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .fill(isOn ? Color.white : Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Theme.textPrimary, lineWidth: 3)
                )
            VStack(spacing: 8) {
                Text("SOS")
                    .font(.system(size: 96, weight: .black))
                Text(letter.map { "Signalling \($0)" } ?? "Pause")
                    .font(.title3.weight(.heavy))
            }
            .foregroundStyle(isOn ? Color.black : Color(white: 0.55))
        }
        // Short fade instead of a hard cut: softer on the eyes.
        .animation(.easeInOut(duration: 0.12), value: isOn)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("SOS signal running")
        .accessibilityValue("Slow light pattern, dot dot dot, dash dash dash, dot dot dot")
    }
}

private struct IdlePanel: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Image(systemName: "light.beacon.max.fill")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text("Visual SOS")
                .font(.largeTitle.weight(.black))
                .foregroundStyle(Theme.textPrimary)
            Text("Shows ... --- ... on the screen in white and black. Slow pattern: at most one flash per second, never starts by itself.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Text("Uses the screen only. No torch, no sound, nothing is sent.")
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth)
        )
    }
}

#Preview {
    NavigationStack {
        SOSSignalView()
    }
    .environment(ToolsState())
    .preferredColorScheme(.dark)
}
