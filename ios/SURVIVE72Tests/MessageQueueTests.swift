import XCTest
@testable import SURVIVE72

/// Pure queue rules: SOS first, then first in first out; chat history order.
final class MessageQueueTests: XCTestCase {
    private func message(_ text: String, order: Int, sequence: Int? = nil, sos: Bool = false,
                         state: MessageDeliveryState = .queued, conversation: String = "c") -> ConnectMessage {
        ConnectMessage(conversationID: conversation, text: text, isOutgoing: true, isSOS: sos,
                       createdAt: Date(timeIntervalSince1970: 0), sequence: sequence ?? order,
                       queueOrder: order, state: state)
    }

    func testOnlyQueuedMessagesAreInTheQueue() {
        let messages = [
            message("delivered", order: 1, state: .delivered),
            message("failed", order: 2, state: .failed),
            message("queued", order: 3)
        ]
        XCTAssertEqual(MessageQueue.ordered(messages).map(\.text), ["queued"])
    }

    func testQueueOrderIgnoresArrayOrder() {
        let messages = [message("third", order: 3), message("first", order: 1), message("second", order: 2)]
        XCTAssertEqual(MessageQueue.ordered(messages).map(\.text), ["first", "second", "third"])
    }

    func testSOSComesFirst() {
        let messages = [message("old", order: 1), message("sos", order: 5, sos: true), message("new", order: 2)]
        XCTAssertEqual(MessageQueue.ordered(messages).map(\.text), ["sos", "old", "new"])
        XCTAssertEqual(MessageQueue.next(in: messages)?.text, "sos")
    }

    func testEmptyQueueHasNoNext() {
        XCTAssertNil(MessageQueue.next(in: []))
        XCTAssertNil(MessageQueue.next(in: [message("done", order: 1, state: .delivered)]))
    }

    func testHistoryUsesSequenceNotQueueOrder() {
        let messages = [
            message("b", order: 9, sequence: 2),
            message("a", order: 10, sequence: 1),
            message("other", order: 1, sequence: 0, conversation: "x")
        ]
        XCTAssertEqual(MessageQueue.history(messages, in: "c").map(\.text), ["a", "b"])
    }

    func testCountByState() {
        let messages = [
            message("a", order: 1, state: .failed),
            message("b", order: 2, state: .failed),
            message("c", order: 3)
        ]
        XCTAssertEqual(MessageQueue.count(.failed, in: messages), 2)
        XCTAssertEqual(MessageQueue.count(.queued, in: messages), 1)
        XCTAssertEqual(MessageQueue.count(.delivered, in: messages), 0)
    }

    func testStateLabelsSaySimulated() {
        XCTAssertEqual(MessageDeliveryState.queued.label, "Queued")
        XCTAssertTrue(MessageDeliveryState.delivered.label.contains("simulated"))
        XCTAssertTrue(MessageDeliveryState.failed.label.contains("simulated"))
    }
}
