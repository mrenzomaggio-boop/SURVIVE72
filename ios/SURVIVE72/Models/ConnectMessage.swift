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
