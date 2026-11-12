import SwiftUI

/// SURVIVE CONNECT: local demo chat, simulated message queue and priority SOS.
/// No Bluetooth, Wi-Fi, network, GPS or permissions: nothing is transmitted.
struct ConnectView: View {
    @Environment(ConnectStore.self) private var store

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                NavigationLink {
                    SOSComposerView()
                } label: {
                    SOSEntryCard(text: store.sosText)
                }
                .buttonStyle(.plain)

                queueSection
                conversationsSection
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) {
            LocalDemoBanner()
        }
        .navigationTitle(String(localized: "Connect"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: Queue

    private var queueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ConnectHeader(title: String(localized: "Message queue"), systemImage: "tray.full.fill",
                          trailing: "\(store.queue.count)")

            Text(store.queue.isEmpty
                 ? String(localized: "Queue is empty. \(store.failedCount) failed (simulated).")
                 : String(localized: "SOS goes first, then oldest first. Use the buttons to simulate the result. \(store.failedCount) failed (simulated)."))
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            ForEach(store.queue) { message in
                QueueRow(message: message,
                         conversationTitle: store.conversation(message.conversationID)?.title ?? "")
            }

            if !store.queue.isEmpty {
                HStack(spacing: 12) {
                    SmallActionButton(title: String(localized: "Simulate delivered"), systemImage: "checkmark.circle.fill",
                                      color: Theme.ok) {
                        store.simulateNext(.delivered)
                    }
                    SmallActionButton(title: String(localized: "Simulate failed"), systemImage: "xmark.circle.fill",
                                      color: Theme.danger) {
                        store.simulateNext(.failed)
                    }
                }
                .accessibilityHint(String(localized: "Applies to the first message in the queue. Nothing is transmitted."))
            }
        }
    }

    // MARK: Conversations

    private var conversationsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ConnectHeader(title: String(localized: "Conversations"), systemImage: "bubble.left.and.bubble.right.fill",
                          trailing: "\(store.conversations.count)")
            ForEach(store.conversations) { conversation in
                NavigationLink {
                    ConversationView(conversationID: conversation.id)
                } label: {
                    ConversationRow(conversation: conversation,
                                    lastMessage: store.lastMessage(in: conversation.id))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Building blocks

/// Permanent status bar on every Connect screen.
struct LocalDemoBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.title3.weight(.bold))
                .accessibilityHidden(true)
            Text(ConnectStatus.banner)
                .font(.subheadline.weight(.black))
                .minimumScaleFactor(0.7)
                .lineLimit(2)
        }
        .foregroundStyle(Theme.textPrimary)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accent.opacity(0.25))
        .overlay(alignment: .bottom) {
            Rectangle().fill(Theme.accent).frame(height: 3)
        }
        .background(Theme.background)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Local demo. Nothing is transmitted."))
        .accessibilityAddTraits(.isStaticText)
    }
}

struct ConnectHeader: View {
    let title: String
    let systemImage: String
    var trailing: String?

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title.uppercased())
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Spacer()
            if let trailing {
                Text(trailing)
                    .font(.title3.weight(.heavy).monospacedDigit())
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

struct SmallActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.heavy))
                .foregroundStyle(color)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
                .padding(.horizontal, 8)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(color, lineWidth: Theme.borderWidth)
                )
        }
        .buttonStyle(.plain)
    }
}

/// Colored label for a delivery state.
struct DeliveryStateLabel: View {
    let state: MessageDeliveryState

    var body: some View {
        Label(state.label, systemImage: icon)
            .font(.caption.weight(.heavy))
            .foregroundStyle(color)
    }

    private var icon: String {
        switch state {
        case .queued: "clock.fill"
        case .delivered: "checkmark.circle.fill"
        case .failed: "exclamationmark.triangle.fill"
        }
    }

    private var color: Color {
        switch state {
        case .queued: Theme.accent
        case .delivered: Theme.ok
        case .failed: Theme.danger
        }
    }
}

private struct SOSEntryCard: View {
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sos.circle.fill")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Theme.danger)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "PRIORITY SOS"))
                    .font(.title3.weight(.black))
                    .foregroundStyle(Theme.textPrimary)
                Text(text)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(2)
                Text(String(localized: "Local only · not transmitted"))
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(Theme.danger)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.danger, lineWidth: 3)
        )
        .accessibilityElement(children: .combine)
        .accessibilityHint(String(localized: "Edit and queue the SOS message. Nothing is transmitted."))
    }
}

private struct QueueRow: View {
    let message: ConnectMessage
    let conversationTitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if message.isSOS {
                    Text(String(localized: "SOS"))
                        .font(.caption.weight(.black))
                        .foregroundStyle(Theme.background)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Theme.danger, in: Capsule())
                }
                Text(conversationTitle)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
                Spacer()
                DeliveryStateLabel(state: message.state)
            }
            Text(message.text)
                .font(.body)
                .foregroundStyle(Theme.textPrimary)
                .lineLimit(3)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(message.isSOS ? Theme.danger : Theme.surfaceBorder, lineWidth: Theme.borderWidth)
        )
        .accessibilityElement(children: .combine)
    }
}

private struct ConversationRow: View {
    let conversation: ConnectConversation
    let lastMessage: ConnectMessage?

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(lastMessage?.text ?? conversation.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
                if let lastMessage, lastMessage.isOutgoing {
                    DeliveryStateLabel(state: lastMessage.state)
                }
            }
            Spacer(minLength: 8)
            Image(systemName: "chevron.right")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth)
        )
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        ConnectView()
    }
    .environment(ConnectStore(defaults: UserDefaults(suiteName: "preview.connect")!))
    .preferredColorScheme(.dark)
}
