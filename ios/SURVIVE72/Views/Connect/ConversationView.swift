import SwiftUI

/// One local demo conversation: history and message composer.
/// Sending only adds the message to the local queue.
struct ConversationView: View {
    let conversationID: ConnectConversation.ID

    @Environment(ConnectStore.self) private var store
    @State private var draft = ""
    @FocusState private var isComposerFocused: Bool

    private var messages: [ConnectMessage] { store.history(in: conversationID) }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    if messages.isEmpty {
                        Text("No messages yet. Messages stay on this device.")
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    ForEach(messages) { message in
                        MessageBubble(message: message) {
                            store.retry(message.id)
                        }
                        .id(message.id)
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onAppear { scrollToBottom(proxy) }
            .onChange(of: messages.count) { scrollToBottom(proxy) }
        }
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) {
            LocalDemoBanner()
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            composer
        }
        .navigationTitle(store.conversation(conversationID)?.title ?? "Conversation")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 10) {
            TextField("Message (local demo)", text: $draft, axis: .vertical)
                .lineLimit(1...4)
                .font(.title3)
                .foregroundStyle(Theme.textPrimary)
                .focused($isComposerFocused)
                .padding(12)
                .frame(minHeight: 52)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth)
                )
                .accessibilityLabel("Message text")

            Button {
                if store.send(draft, to: conversationID) != nil {
                    draft = ""
                }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(draft.trimmed.isEmpty ? Theme.surfaceBorder : Theme.accent)
                    .frame(width: 56, height: 56)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
            .buttonStyle(.plain)
            .disabled(draft.trimmed.isEmpty)
            .accessibilityLabel("Add to queue")
            .accessibilityHint("The message is queued on this device. Nothing is transmitted.")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.background)
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        guard let last = messages.last else { return }
        proxy.scrollTo(last.id, anchor: .bottom)
    }
}

private struct MessageBubble: View {
    let message: ConnectMessage
    let onRetry: () -> Void

    var body: some View {
        HStack {
            if message.isOutgoing { Spacer(minLength: 40) }
            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 6) {
                if message.isSOS {
                    Text("SOS · PRIORITY")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Theme.danger)
                }
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                HStack(spacing: 8) {
                    Text(message.createdAt, format: .dateTime.hour().minute())
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Theme.textSecondary)
                    if message.isOutgoing {
                        DeliveryStateLabel(state: message.state)
                    }
                }
                if message.isOutgoing && message.state == .failed {
                    Button("Retry (queue again)", action: onRetry)
                        .font(.subheadline.weight(.heavy))
                        .foregroundStyle(Theme.accent)
                        .frame(minHeight: 44)
                        .accessibilityHint("Puts the message back in the local queue.")
                }
            }
            .padding(12)
            .background(
                message.isOutgoing ? Theme.surface : Theme.background,
                in: RoundedRectangle(cornerRadius: Theme.cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(borderColor, lineWidth: Theme.borderWidth)
            )
            .accessibilityElement(children: .combine)
            if !message.isOutgoing { Spacer(minLength: 40) }
        }
    }

    private var borderColor: Color {
        if message.isSOS { return Theme.danger }
        return message.isOutgoing ? Theme.accent.opacity(0.6) : Theme.surfaceBorder
    }
}

#Preview {
    NavigationStack {
        ConversationView(conversationID: "family")
    }
    .environment(ConnectStore(defaults: UserDefaults(suiteName: "preview.connect")!))
    .preferredColorScheme(.dark)
}
