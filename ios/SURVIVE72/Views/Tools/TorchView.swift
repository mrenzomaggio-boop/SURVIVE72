import SwiftUI

/// Torch: switches the iPhone flash on and off. No camera access and no
/// permission: only the LED is used. It never switches on by itself.
struct TorchView: View {
    @Environment(ToolsState.self) private var tools
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        let torch = tools.torch

        VStack(spacing: 18) {
            Spacer(minLength: 0)

            Image(systemName: torch.isOn ? "flashlight.on.fill" : "flashlight.off.fill")
                .font(.system(size: 120, weight: .bold))
                .foregroundStyle(torch.isOn ? Theme.accent : Theme.textSecondary)
                .accessibilityHidden(true)

            Text(statusText(torch))
                .font(.largeTitle.weight(.black))
                .foregroundStyle(torch.isOn ? Theme.accent : Theme.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.updatesFrequently)

            if torch.didFail || !torch.isAvailable {
                Text(torch.isAvailable
                     ? String(localized: "The torch could not be switched. Close other apps using the camera and try again.")
                     : String(localized: "This device has no flash, or it cannot be used right now."))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.danger)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Text(String(localized: "Uses the iPhone flash only: no camera access, no permission. The torch switches off when you leave the app. It uses a lot of battery."))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)

            ToolButton(
                title: torch.isOn ? String(localized: "Turn torch off") : String(localized: "Turn torch on"),
                systemImage: torch.isOn ? "flashlight.off.fill" : "flashlight.on.fill",
                style: torch.isOn ? .destructive : .primary
            ) {
                torch.toggle()
            }
            .disabled(!torch.isAvailable)
            .opacity(torch.isAvailable ? 1 : 0.5)
        }
        .padding(16)
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(String(localized: "Torch"))
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.impact, trigger: torch.isOn)
        .onAppear { torch.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { torch.refresh() }
        }
    }

    private func statusText(_ torch: Torch) -> String {
        if !torch.isAvailable { return String(localized: "Torch not available") }
        return torch.isOn ? String(localized: "TORCH ON") : String(localized: "TORCH OFF")
    }
}

#Preview {
    NavigationStack {
        TorchView()
    }
    .environment(ToolsState())
    .preferredColorScheme(.dark)
}
