import SwiftUI

/// Compass and position placeholders. Both need real sensors (magnetometer,
/// GPS) that cannot be tested in the simulator, so nothing here reads a
/// sensor or asks for permissions yet.
struct SensorPlaceholderView: View {
    enum Kind: String, Hashable {
        case compass
        case position

        var title: String {
            switch self {
            case .compass: "Compass"
            case .position: "Current position"
            }
        }

        var systemImage: String {
            switch self {
            case .compass: "location.north.line.fill"
            case .position: "location.slash.fill"
            }
        }

        var explanation: String {
            switch self {
            case .compass:
                "The compass uses the magnetometer. It will be enabled after it has been tested on a real iPhone. This version reads no sensor."
            case .position:
                "Your position needs GPS and location permission. It will be enabled after it has been tested on a real iPhone. This version never reads your location: type coordinates in Saved places instead."
            }
        }
    }

    static let requirement = "REQUIRES PHYSICAL-DEVICE TEST"

    let kind: Kind

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Label(SensorPlaceholderView.requirement, systemImage: "iphone.gen3")
                    .font(.headline.weight(.black))
                    .foregroundStyle(Theme.background)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Theme.accent, in: Capsule())

                Image(systemName: kind.systemImage)
                    .font(.system(size: 96, weight: .bold))
                    .foregroundStyle(Theme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .accessibilityHidden(true)

                Text("\(kind.title) not available yet")
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(kind.explanation)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(kind.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SensorPlaceholderView(kind: .compass)
    }
    .preferredColorScheme(.dark)
}
