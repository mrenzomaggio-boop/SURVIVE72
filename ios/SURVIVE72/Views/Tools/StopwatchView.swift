import SwiftUI

/// Large, readable stopwatch with Start/Pause and Reset.
struct StopwatchView: View {
    @Environment(ToolsState.self) private var tools

    var body: some View {
        let stopwatch = tools.stopwatch

        VStack(spacing: 32) {
            Spacer(minLength: 0)

            // Refreshes 10 times per second, and only while running.
            TimelineView(.animation(minimumInterval: 0.1, paused: !stopwatch.isRunning)) { context in
                let elapsed = stopwatch.elapsed(at: context.date)
                Text(ElapsedTimeFormat.display(elapsed))
                    .font(.system(size: 76, weight: .black, design: .rounded).monospacedDigit())
                    .foregroundStyle(stopwatch.isRunning ? Theme.textPrimary : Theme.accent)
                    .minimumScaleFactor(0.4)
                    .lineLimit(1)
                    .accessibilityLabel("Elapsed time")
                    .accessibilityValue(ElapsedTimeFormat.spoken(elapsed))
            }
            .frame(maxWidth: .infinity)

            Text(stopwatch.isRunning ? "RUNNING" : (stopwatch.elapsed(at: .now) > 0 ? "PAUSED" : "READY"))
                .font(.headline.weight(.heavy))
                .foregroundStyle(Theme.textSecondary)

            Spacer(minLength: 0)

            VStack(spacing: Theme.spacing) {
                ToolButton(
                    title: stopwatch.isRunning ? "Pause" : (stopwatch.elapsed(at: .now) > 0 ? "Resume" : "Start"),
                    systemImage: stopwatch.isRunning ? "pause.fill" : "play.fill",
                    style: stopwatch.isRunning ? .secondary : .primary
                ) {
                    if stopwatch.isRunning {
                        tools.stopwatch.pause(at: .now)
                    } else {
                        tools.stopwatch.start(at: .now)
                    }
                }

                ToolButton(title: "Reset", systemImage: "arrow.counterclockwise", style: .destructive) {
                    tools.stopwatch.reset()
                }
                .disabled(stopwatch.elapsed(at: .now) == 0 && !stopwatch.isRunning)
                .opacity(stopwatch.elapsed(at: .now) == 0 && !stopwatch.isRunning ? 0.5 : 1)
            }
        }
        .padding(16)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle("Stopwatch")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.impact, trigger: stopwatch.isRunning)
    }
}

/// Full-width, 64 pt tall action button used by the tools.
struct ToolButton: View {
    enum Style { case primary, secondary, destructive }

    let title: String
    let systemImage: String
    let style: Style
    let action: () -> Void

    private var foreground: Color {
        switch style {
        case .primary: Theme.background
        case .secondary: Theme.textPrimary
        case .destructive: Theme.danger
        }
    }

    private var fill: Color {
        style == .primary ? Theme.accent : Theme.surface
    }

    private var border: Color {
        switch style {
        case .primary: Theme.accent
        case .secondary: Theme.textPrimary
        case .destructive: Theme.danger
        }
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.title2.weight(.heavy))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity, minHeight: 64)
                .background(fill, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(border, lineWidth: 3)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        StopwatchView()
    }
    .environment(ToolsState())
    .preferredColorScheme(.dark)
}
