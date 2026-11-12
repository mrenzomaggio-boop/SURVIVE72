import SwiftUI
import UIKit

/// The alert board: public alerts that spread from phone to phone.
/// Anyone with the app can write here, so every alert is shown as unverified.
struct AlertBoardView: View {
    @Environment(MeshService.self) private var mesh
    @Environment(AlertPlanStore.self) private var planStore

    @State private var draft = ""
    @State private var isConfirmingSOS = false
    @State private var didFail = false
    @State private var didPublish = false

    var body: some View {
        let alerts = mesh.alerts

        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                MeshStatusCard()
                composerSection

                VStack(alignment: .leading, spacing: 12) {
                    MeshSectionHeader(title: String(localized: "Alerts"), systemImage: "megaphone.fill")
                    Text(String(localized: "Alerts are written by people, not by authorities, and are not verified. They disappear after 24 hours."))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    if alerts.isEmpty {
                        Text(String(localized: "No alerts on this phone yet."))
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    ForEach(alerts) { alert in
                        AlertBoardRow(alert: alert, isMine: alert.sender.code == mesh.myCode)
                    }
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) { MeshNoticeBanner() }
        .navigationTitle(String(localized: "Alert board"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .alert(String(localized: "Publish SOS?"), isPresented: $isConfirmingSOS) {
            Button(String(localized: "Publish SOS"), role: .destructive) { publish(isSOS: true) }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "Your SOS will be shown first on every phone it reaches. It does not call emergency services. Use it only for a real emergency."))
        }
    }

    // MARK: Composer

    private var composerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MeshSectionHeader(title: String(localized: "Write an alert"), systemImage: "square.and.pencil")

            TextField(String(localized: "What is happening and where"), text: $draft, axis: .vertical)
                .lineLimit(2...6)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(12)
                .frame(minHeight: 80, alignment: .top)
                .meshCardBackground()
                .accessibilityLabel(String(localized: "Alert text"))
                .onChange(of: draft) {
                    didFail = false
                    didPublish = false
                }

            if didFail {
                Text(String(localized: "The alert could not be published. It may be too long."))
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Theme.danger)
            }
            if didPublish {
                Text(mesh.isEnabled
                     ? String(localized: "Published. It spreads as phones with the app come in range.")
                     : String(localized: "Saved on this phone. Switch the network on to spread it."))
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Theme.ok)
                    .fixedSize(horizontal: false, vertical: true)
            }

            BigButton(title: String(localized: "Publish alert"), systemImage: "megaphone.fill", color: Theme.accent) {
                publish(isSOS: false)
            }
            .disabled(draft.trimmed.isEmpty)
            .opacity(draft.trimmed.isEmpty ? 0.5 : 1)

            BigButton(title: String(localized: "Publish as SOS"), systemImage: "sos.circle.fill", color: Theme.danger) {
                isConfirmingSOS = true
            }
            .disabled(draft.trimmed.isEmpty)
            .opacity(draft.trimmed.isEmpty ? 0.5 : 1)

            Button {
                draft = planStore.message
            } label: {
                Label(String(localized: "Use my SOS message"), systemImage: "doc.on.clipboard")
                    .font(.headline.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                    .frame(maxWidth: .infinity, minHeight: 48)
            }
            .buttonStyle(.plain)
            .accessibilityHint(String(localized: "Copies the SOS message from your plan into the text. Everyone who receives the alert can read it."))
        }
    }

    private func publish(isSOS: Bool) {
        do {
            try mesh.postAlert(draft, isSOS: isSOS)
            draft = ""
            didFail = false
            didPublish = true
            UIAccessibility.post(notification: .announcement, argument: String(localized: "Alert published."))
        } catch {
            didFail = true
        }
    }
}

private struct AlertBoardRow: View {
    let alert: MeshPacket
    let isMine: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                if alert.isSOS {
                    Text(String(localized: "SOS"))
                        .font(.caption.weight(.black))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.danger, in: Capsule())
                }
                Text(String(localized: "NOT VERIFIED"))
                    .font(.caption.weight(.black))
                    .foregroundStyle(Theme.background)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Theme.accent, in: Capsule())
                Spacer(minLength: 0)
            }

            Text(alert.alertText ?? "")
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(isMine
                 ? String(localized: "Written by you")
                 : String(localized: "From \(MeshDisplay.name(alert.sender.name)) · \(alert.sender.code)"))
                .font(.subheadline.weight(.heavy))
                .foregroundStyle(Theme.textSecondary)

            Text(detail)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(alert.isSOS ? Theme.danger : Theme.surfaceBorder,
                        lineWidth: alert.isSOS ? 3 : Theme.borderWidth)
        )
        .accessibilityElement(children: .combine)
    }

    private var detail: String {
        let time = alert.createdAt.formatted(date: .abbreviated, time: .shortened)
        if isMine || alert.hops <= 1 {
            return time
        }
        return time + " · " + MeshDisplay.relays(hops: alert.hops)
    }
}
