import SwiftUI

/// A private conversation with one person. Messages are encrypted for the
/// recipient and carried by other phones until they arrive.
struct MeshConversationView: View {
    @Environment(MeshService.self) private var mesh
    let code: String

    @State private var draft = ""
    @State private var didFail = false
    @State private var isConfirmingBlock = false
    @Environment(\.openURL) private var openURL

    private var card: MeshCard? { mesh.card(for: code) }

    var body: some View {
        let messages = mesh.messages(with: code)

        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header

                    if messages.isEmpty {
                        Text(String(localized: "No messages yet. Your message leaves when another phone with the app is in range, and is passed on from phone to phone."))
                            .font(.body)
                            .foregroundStyle(Theme.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    ForEach(messages) { message in
                        MeshBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding(16)
            }
            .onChange(of: messages.count, initial: true) {
                if let last = messages.last { proxy.scrollTo(last.id, anchor: .bottom) }
            }
        }
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if mesh.isBlocked(code) { blockedBar } else { composer }
        }
        .navigationTitle(MeshDisplay.name(card?.name ?? ""))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if mesh.isBlocked(code) {
                        Button(String(localized: "Unblock this person"), systemImage: "hand.raised.slash") {
                            mesh.unblock(code)
                        }
                    } else {
                        Button(String(localized: "Block this person"), systemImage: "hand.raised.fill", role: .destructive) {
                            isConfirmingBlock = true
                        }
                    }
                    Button(String(localized: "Report"), systemImage: "exclamationmark.bubble") {
                        report()
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3.weight(.bold))
                }
                .accessibilityLabel(String(localized: "Block or report"))
            }
        }
        .confirmationDialog(String(localized: "Block this person?"), isPresented: $isConfirmingBlock,
                            titleVisibility: .visible) {
            Button(String(localized: "Block"), role: .destructive) { mesh.block(code) }
            Button(String(localized: "Block and report"), role: .destructive) {
                mesh.block(code)
                report()
            }
            Button(String(localized: "Cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "You will no longer see their messages or get notifications from them. You can unblock them in Connect."))
        }
    }

    private func report() {
        if let url = MeshService.reportURL(for: code, name: MeshDisplay.name(card?.name ?? "")) {
            openURL(url)
        }
    }

    private var blockedBar: some View {
        VStack(spacing: 8) {
            Text(String(localized: "You blocked this person."))
                .font(.headline.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Button(String(localized: "Unblock")) { mesh.unblock(code) }
                .font(.headline.weight(.heavy))
                .foregroundStyle(Theme.accent)
                .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(Theme.background)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(String(localized: "Security code: \(code)"))
                .font(.subheadline.weight(.heavy).monospaced())
                .foregroundStyle(Theme.textPrimary)
            Text(String(localized: "Only this person can read your messages. Identity is not verified: if in doubt, compare the security code in person."))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .meshCardBackground()
        .accessibilityElement(children: .combine)
    }

    private var composer: some View {
        VStack(alignment: .leading, spacing: 6) {
            if didFail {
                Text(String(localized: "The message could not be sent. It may be too long."))
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Theme.danger)
            }
            HStack(alignment: .bottom, spacing: 10) {
                TextField(String(localized: "Message"), text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(12)
                    .frame(minHeight: 52)
                    .meshCardBackground()
                    .accessibilityLabel(String(localized: "Message text"))

                Button(action: send) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(canSend ? Theme.accent : Theme.surfaceBorder)
                        .frame(width: 56, height: 56)
                        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .accessibilityLabel(String(localized: "Send message"))
                .accessibilityHint(String(localized: "The message is passed from phone to phone until it reaches this person. Delivery is not guaranteed."))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.background)
    }

    private var canSend: Bool { card != nil && !draft.trimmed.isEmpty }

    private func send() {
        guard let card else { return }
        do {
            try mesh.send(draft, to: card)
            draft = ""
            didFail = false
        } catch {
            didFail = true
        }
    }
}

private struct MeshBubble: View {
    let message: MeshChatMessage

    var body: some View {
        HStack {
            if message.isOutgoing { Spacer(minLength: 40) }
            VStack(alignment: message.isOutgoing ? .trailing : .leading, spacing: 6) {
                Text(message.text)
                    .font(.body)
                    .foregroundStyle(Theme.textPrimary)
                    .multilineTextAlignment(.leading)
                Text(caption)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(12)
            .background(message.isOutgoing ? Theme.surface : Theme.background,
                        in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(message.isOutgoing ? Theme.accent : Theme.surfaceBorder, lineWidth: Theme.borderWidth)
            )
            .accessibilityElement(children: .combine)
            if !message.isOutgoing { Spacer(minLength: 40) }
        }
    }

    private var caption: String {
        let time = message.date.formatted(date: .abbreviated, time: .shortened)
        if message.isOutgoing {
            return String(localized: "\(time) · on its way, delivery not confirmed")
        }
        return message.hops <= 1
            ? String(localized: "\(time) · received directly")
            : time + " · " + MeshDisplay.relays(hops: message.hops)
    }
}
