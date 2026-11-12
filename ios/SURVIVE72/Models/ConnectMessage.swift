import Foundation

/// Simulated delivery state of a message. Nothing is ever transmitted:
/// "delivered" and "failed" are set by the user with the simulation buttons.
enum MessageDeliveryState: String, Codable, CaseIterable {
    case queued
    case delivered
    case failed

    var label: String {
        switch self {
        case .queued: "Queued"
        case .delivered: "Delivered (simulated)"
        case .failed: "Failed (simulated)"
        }
    }
}

/// A local demo conversation.
struct ConnectConversation: Identifiable, Codable, Hashable {
    let id: String
    var title: String
    var subtitle: String
}

/// One chat message, stored only on this device.
struct ConnectMessage: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var conversationID: ConnectConversation.ID
    var text: String
    var isOutgoing: Bool
    var isSOS: Bool = false
    var createdAt: Date
    /// Chat order: increases with every new message and never changes.
    var sequence: Int
    /// Queue order: set when the message enters the queue (again, after a retry).
    var queueOrder: Int
    var state: MessageDeliveryState
}

/// Everything SURVIVE CONNECT saves, in one value.
struct ConnectData: Codable, Equatable {
    var conversations: [ConnectConversation]
    var messages: [ConnectMessage]
    /// The user's edited SOS text. `nil` means "use the default text".
    var sosDraft: String?
    /// Next value for `sequence` and `queueOrder`.
    var nextOrder: Int
}

// MARK: - Tolerant decoding
// Hand-written so a missing or damaged field never loses the message history.

extension ConnectConversation {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        title = c.value(String.self, forKey: .title, default: "")
        subtitle = c.value(String.self, forKey: .subtitle, default: "")
    }
}

extension ConnectMessage {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = c.value(UUID.self, forKey: .id, default: UUID())
        conversationID = try c.decode(String.self, forKey: .conversationID)
        text = try c.decode(String.self, forKey: .text)
        isOutgoing = c.value(Bool.self, forKey: .isOutgoing, default: true)
        isSOS = c.value(Bool.self, forKey: .isSOS, default: false)
        createdAt = c.value(Date.self, forKey: .createdAt, default: Date(timeIntervalSince1970: 0))
        let savedSequence = c.value(Int.self, forKey: .sequence, default: 0)
        sequence = savedSequence
        queueOrder = c.value(Int.self, forKey: .queueOrder, default: savedSequence)
        state = c.value(MessageDeliveryState.self, forKey: .state, default: .queued)
    }
}

extension ConnectData {
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let decodedConversations = c.lossyArray(ConnectConversation.self, forKey: .conversations)
        conversations = decodedConversations.isEmpty ? ConnectDemoContent.conversations : decodedConversations
        let savedMessages = c.lossyArray(ConnectMessage.self, forKey: .messages)
        messages = savedMessages
        sosDraft = c.optionalValue(String.self, forKey: .sosDraft)
        // Never reuse an order already taken by a saved message.
        let highestUsed = savedMessages.map { max($0.sequence, $0.queueOrder) }.max() ?? -1
        nextOrder = max(c.value(Int.self, forKey: .nextOrder, default: 0), highestUsed + 1)
    }
}

/// Outcome chosen by the user when simulating the queue.
enum SimulatedOutcome {
    case delivered
    case failed

    var state: MessageDeliveryState {
        switch self {
        case .delivered: .delivered
        case .failed: .failed
        }
    }
}

/// Fixed texts shown on every Connect screen.
enum ConnectStatus {
    static let banner = "LOCAL DEMO · NOT TRANSMITTED"
    static let defaultSOSText = "SOS - I need help. Please come to our meeting point."
}
