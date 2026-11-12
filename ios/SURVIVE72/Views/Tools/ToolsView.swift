import SwiftUI

/// The tools available in SURVIVE TOOLS.
enum ToolKind: String, CaseIterable, Identifiable, Hashable {
    case stopwatch
    case sosSignal
    case torch

    var id: String { rawValue }

    var title: String {
        switch self {
        case .stopwatch: String(localized: "Stopwatch")
        case .sosSignal: String(localized: "SOS screen signal")
        case .torch: String(localized: "Torch")
        }
    }

    var subtitle: String {
        switch self {
        case .stopwatch: String(localized: "Start, pause and reset")
        case .sosSignal: String(localized: "Slow on-screen SOS light")
        case .torch: String(localized: "Uses the iPhone flash")
        }
    }

    var systemImage: String {
        switch self {
        case .stopwatch: "stopwatch.fill"
        case .sosSignal: "light.beacon.max.fill"
        case .torch: "flashlight.on.fill"
        }
    }
}

/// SURVIVE TOOLS: list of offline tools. No network, no permissions.
/// The torch only switches the flash LED.
struct ToolsView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: Theme.spacing) {
                ForEach(ToolKind.allCases) { tool in
                    NavigationLink(value: tool) {
                        ToolRow(tool: tool)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(String(localized: "Tools"))
        .navigationBarTitleDisplayMode(.large)
        .navigationDestination(for: ToolKind.self) { tool in
            switch tool {
            case .stopwatch: StopwatchView()
            case .sosSignal: SOSSignalView()
            case .torch: TorchView()
            }
        }
    }
}

private struct ToolRow: View {
    let tool: ToolKind

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: tool.systemImage)
                .font(.system(size: 30, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 44)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(tool.title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(tool.subtitle)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 84, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth)
        )
        .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(tool.title). \(tool.subtitle)")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NavigationStack {
        ToolsView()
    }
    .environment(ToolsState())
    .preferredColorScheme(.dark)
}
