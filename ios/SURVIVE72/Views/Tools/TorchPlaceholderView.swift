import SwiftUI

/// Torch screen placeholder. The real torch needs the camera flash hardware,
/// which cannot be tested in the simulator, so nothing here touches hardware
/// or asks for permissions yet.
struct TorchPlaceholderView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Label(String(localized: "REQUIRES PHYSICAL-DEVICE TEST"), systemImage: "iphone.gen3")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Theme.background)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.accent, in: Capsule())

                Image(systemName: "flashlight.off.fill")
                    .font(.system(size: 96, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .accessibilityHidden(true)

                Text(String(localized: "Torch not available yet"))
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(String(localized: "The torch uses the camera flash. It will be enabled after it has been tested on a real iPhone. This version does not use the camera, the flash or any permission."))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(String(localized: "For light now, use the SOS screen signal or the iPhone Control Center."))
                    .font(.body.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                ToolButton(title: String(localized: "Torch disabled"), systemImage: "flashlight.off.fill", style: .secondary) {}
                    .disabled(true)
                    .opacity(0.5)
                    .accessibilityHint(String(localized: "Not available until tested on a physical device."))
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(String(localized: "Torch"))
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TorchPlaceholderView()
    }
    .preferredColorScheme(.dark)
}
