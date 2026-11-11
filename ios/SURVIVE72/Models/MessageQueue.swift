import Foundation

/// Pure queue rules for SURVIVE CONNECT.
/// SOS messages always go first; otherwise first in, first out.
enum MessageQueue {
    /// Queued messages in the order they would be handled.
    static func ordered(_ messages: [ConnectMessage]) -> [ConnectMessage] {
        messages
            .filter { $0.state == .queued }
            .sorted { lhs, rhs in
                if lhs.isSOS != rhs.isSOS { return lhs.isSOS }
                return lhs.queueOrder < rhs.queueOrder
            }
    }

    /// The next message the simulation would handle.
    static func next(in messages: [ConnectMessage]) -> ConnectMessage? {
        ordered(messages).first
    }

    /// Messages of one conversation in chat order (oldest first).
    static func history(_ messages: [ConnectMessage], in conversationID: ConnectConversation.ID) -> [ConnectMessage] {
        messages
            .filter { $0.conversationID == conversationID }
            .sorted { $0.sequence < $1.sequence }
    }

    static func count(_ state: MessageDeliveryState, in messages: [ConnectMessage]) -> Int {
        messages.filter { $0.state == state }.count
    }
}
