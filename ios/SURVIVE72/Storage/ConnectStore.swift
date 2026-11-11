import Foundation
import Observation

/// SURVIVE CONNECT state: demo conversations, message history, the local
/// queue and the SOS draft. Saved as JSON in `UserDefaults` on every change.
/// No Bluetooth, Wi-Fi, network or location: nothing is ever transmitted.
@Observable
final class ConnectStore {
    static let storageKey = "survive72.connect.data.v1"

    private(set) var data: ConnectData

    private let defaults: UserDefaults
    private let key: String
    private let now: () -> Date

    init(defaults: UserDefaults = .standard, key: String = ConnectStore.storageKey,
         now: @escaping () -> Date = Date.init) {
        self.defaults = defaults
        self.key = key
        self.now = now
        if let saved = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(ConnectData.self, from: saved) {
            data = decoded
        } else {
            // Missing or unreadable data: start from the demo conversations.
            data = ConnectDemoContent.initialData()
        }
    }

    // MARK: Read

    var conversations: [ConnectConversation] { data.conversations }

    func conversation(_ id: ConnectConversation.ID) -> ConnectConversation? {
        data.conversations.first { $0.id == id }
    }

    func history(in conversationID: ConnectConversation.ID) -> [ConnectMessage] {
        MessageQueue.history(data.messages, in: conversationID)
    }

    func lastMessage(in conversationID: ConnectConversation.ID) -> ConnectMessage? {
        history(in: conversationID).last
    }

    /// Queued messages in handling order: SOS first, then oldest first.
    var queue: [ConnectMessage] { MessageQueue.ordered(data.messages) }

    var failedCount: Int { MessageQueue.count(.failed, in: data.messages) }

    // MARK: Compose

    /// Adds an outgoing message to the history and the queue.
    /// Returns nil (and saves nothing) for empty text or an unknown conversation.
    @discardableResult
    func send(_ text: String, to conversationID: ConnectConversation.ID) -> ConnectMessage? {
        enqueue(text, to: conversationID, isSOS: false)
    }

    // MARK: SOS

    var sosText: String { data.sosDraft ?? ConnectStatus.defaultSOSText }

    var isSOSTextEdited: Bool { data.sosDraft != nil }

    /// Stores the edited SOS text. Editing back to the default clears the draft.
    func setSOSText(_ text: String) {
        data.sosDraft = (text == ConnectStatus.defaultSOSText) ? nil : text
        save()
    }

    func restoreDefaultSOSText() {
        data.sosDraft = nil
        save()
    }

    /// Queues the SOS text as a priority message in the local SOS conversation.
    /// Nothing is sent. Returns nil if the text is empty.
    @discardableResult
    func queueSOS() -> ConnectMessage? {
        enqueue(sosText, to: ConnectDemoContent.sosConversationID, isSOS: true)
    }

    // MARK: Simulated queue

    /// Marks the next message in the queue as delivered or failed (simulated).
    @discardableResult
    func simulateNext(_ outcome: SimulatedOutcome) -> ConnectMessage? {
        guard let next = MessageQueue.next(in: data.messages) else { return nil }
        return simulate(next.id, outcome)
    }

    /// Marks one queued message as delivered or failed (simulated).
    @discardableResult
    func simulate(_ id: ConnectMessage.ID, _ outcome: SimulatedOutcome) -> ConnectMessage? {
        guard let index = data.messages.firstIndex(where: { $0.id == id }),
              data.messages[index].state == .queued else { return nil }
        data.messages[index].state = outcome.state
        save()
        return data.messages[index]
    }

    /// Puts a failed message back at the end of the queue (SOS stays ahead).
    func retry(_ id: ConnectMessage.ID) {
        guard let index = data.messages.firstIndex(where: { $0.id == id }),
              data.messages[index].state == .failed else { return }
        data.messages[index].state = .queued
        data.messages[index].queueOrder = takeOrder()
        save()
    }

    /// Back to the demo conversations, nothing saved.
    func reset() {
        data = ConnectDemoContent.initialData()
        defaults.removeObject(forKey: key)
    }

    // MARK: Private

    private func enqueue(_ text: String, to conversationID: ConnectConversation.ID,
                         isSOS: Bool) -> ConnectMessage? {
        let cleaned = text.trimmed
        guard !cleaned.isEmpty, conversation(conversationID) != nil else { return nil }
        let order = takeOrder()
        let message = ConnectMessage(
            conversationID: conversationID, text: cleaned, isOutgoing: true, isSOS: isSOS,
            createdAt: now(), sequence: order, queueOrder: order, state: .queued
        )
        data.messages.append(message)
        save()
        return message
    }

    private func takeOrder() -> Int {
        let order = data.nextOrder
        data.nextOrder += 1
        return order
    }

    private func save() {
        guard let encoded = try? JSONEncoder().encode(data) else { return }
        defaults.set(encoded, forKey: key)
    }
}
