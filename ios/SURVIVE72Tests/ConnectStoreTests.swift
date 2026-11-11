import XCTest
@testable import SURVIVE72

/// Persistence, queue, ordering and SOS tests for SURVIVE CONNECT.
/// Each test uses its own throwaway UserDefaults suite and a fixed clock.
final class ConnectStoreTests: XCTestCase {
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var clock: Date!

    override func setUp() {
        super.setUp()
        suiteName = "SURVIVE72Tests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suiteName)
        clock = Date(timeIntervalSince1970: 1_900_000_000)
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suiteName)
        defaults = nil
        suiteName = nil
        clock = nil
        super.tearDown()
    }

    private func makeStore() -> ConnectStore {
        ConnectStore(defaults: defaults, now: { [unowned self] in self.clock })
    }

    // MARK: Initial state

    func testNewStoreStartsWithDemoConversations() {
        let store = makeStore()
        XCTAssertEqual(store.data, ConnectDemoContent.initialData())
        XCTAssertEqual(store.conversations.first?.id, ConnectDemoContent.sosConversationID)
        XCTAssertFalse(store.history(in: "family").isEmpty)
        XCTAssertTrue(store.queue.isEmpty)
        XCTAssertNil(defaults.object(forKey: ConnectStore.storageKey))
    }

    func testDemoDataIsDeterministic() {
        XCTAssertEqual(ConnectDemoContent.initialData(), ConnectDemoContent.initialData())
    }

    func testUnreadableSavedDataStartsFromDemo() {
        defaults.set(Data("not json".utf8), forKey: ConnectStore.storageKey)
        XCTAssertEqual(makeStore().data, ConnectDemoContent.initialData())
    }

    // MARK: Compose

    func testSendTrimsAndQueuesOutgoingMessage() throws {
        let store = makeStore()
        let message = try XCTUnwrap(store.send("  On my way  ", to: "family"))
        XCTAssertEqual(message.text, "On my way")
        XCTAssertTrue(message.isOutgoing)
        XCTAssertFalse(message.isSOS)
        XCTAssertEqual(message.state, .queued)
        XCTAssertEqual(message.createdAt, clock)
        XCTAssertEqual(store.queue.map(\.id), [message.id])
    }

    func testEmptyMessageIsRejected() {
        let store = makeStore()
        XCTAssertNil(store.send("   \n ", to: "family"))
        XCTAssertTrue(store.queue.isEmpty)
        XCTAssertNil(defaults.object(forKey: ConnectStore.storageKey))
    }

    func testUnknownConversationIsRejected() {
        let store = makeStore()
        XCTAssertNil(store.send("Hello", to: "nobody"))
        XCTAssertTrue(store.queue.isEmpty)
    }

    // MARK: Order

    func testNewMessagesAppearLastInHistory() throws {
        let store = makeStore()
        let before = store.history(in: "family").count
        let first = try XCTUnwrap(store.send("First", to: "family"))
        clock = clock.addingTimeInterval(-3600) // a clock going back must not reorder the chat
        let second = try XCTUnwrap(store.send("Second", to: "family"))

        let history = store.history(in: "family")
        XCTAssertEqual(history.count, before + 2)
        XCTAssertEqual(history.suffix(2).map(\.id), [first.id, second.id])
    }

    func testHistoryOnlyContainsItsConversation() {
        let store = makeStore()
        store.send("Hello neighbours", to: "neighbours")
        XCTAssertTrue(store.history(in: "family").allSatisfy { $0.conversationID == "family" })
        XCTAssertEqual(store.lastMessage(in: "neighbours")?.text, "Hello neighbours")
    }

    func testHistorySequenceIsStrictlyIncreasing() {
        let store = makeStore()
        store.send("A", to: "team")
        store.send("B", to: "team")
        let sequences = store.history(in: "team").map(\.sequence)
        XCTAssertEqual(sequences, sequences.sorted())
        XCTAssertEqual(Set(sequences).count, sequences.count)
    }

    // MARK: Queue

    func testQueueIsFirstInFirstOut() throws {
        let store = makeStore()
        let a = try XCTUnwrap(store.send("A", to: "family"))
        let b = try XCTUnwrap(store.send("B", to: "team"))
        let c = try XCTUnwrap(store.send("C", to: "family"))
        XCTAssertEqual(store.queue.map(\.id), [a.id, b.id, c.id])
    }

    func testSimulateNextDeliveredHandlesHeadOfQueue() throws {
        let store = makeStore()
        let a = try XCTUnwrap(store.send("A", to: "family"))
        let b = try XCTUnwrap(store.send("B", to: "family"))

        let handled = try XCTUnwrap(store.simulateNext(.delivered))
        XCTAssertEqual(handled.id, a.id)
        XCTAssertEqual(handled.state, .delivered)
        XCTAssertEqual(store.queue.map(\.id), [b.id])
    }

    func testSimulateNextFailedMarksFailed() throws {
        let store = makeStore()
        let failedBefore = store.failedCount
        let a = try XCTUnwrap(store.send("A", to: "family"))

        XCTAssertEqual(store.simulateNext(.failed)?.id, a.id)
        XCTAssertEqual(store.lastMessage(in: "family")?.state, .failed)
        XCTAssertEqual(store.failedCount, failedBefore + 1)
        XCTAssertTrue(store.queue.isEmpty)
    }

    func testSimulateOnEmptyQueueDoesNothing() {
        let store = makeStore()
        XCTAssertNil(store.simulateNext(.delivered))
        XCTAssertEqual(store.data, ConnectDemoContent.initialData())
    }

    func testSimulateOnlyAppliesToQueuedMessages() throws {
        let store = makeStore()
        let a = try XCTUnwrap(store.send("A", to: "family"))
        store.simulate(a.id, .delivered)
        XCTAssertNil(store.simulate(a.id, .failed))
        XCTAssertEqual(store.lastMessage(in: "family")?.state, .delivered)
    }

    func testRetryPutsFailedMessageAtEndOfQueue() throws {
        let store = makeStore()
        let a = try XCTUnwrap(store.send("A", to: "family"))
        let b = try XCTUnwrap(store.send("B", to: "family"))
        store.simulateNext(.failed) // A fails

        store.retry(a.id)
        XCTAssertEqual(store.queue.map(\.id), [b.id, a.id])
        // The chat position does not change.
        XCTAssertEqual(store.history(in: "family").suffix(2).map(\.id), [a.id, b.id])
    }

    func testRetryIgnoresMessagesThatDidNotFail() throws {
        let store = makeStore()
        let a = try XCTUnwrap(store.send("A", to: "family"))
        let order = a.queueOrder
        store.retry(a.id)
        XCTAssertEqual(store.queue.first?.queueOrder, order)
    }

    func testDemoFailedMessageCanBeRetried() throws {
        let store = makeStore()
        let failed = try XCTUnwrap(store.data.messages.first { $0.state == .failed })
        store.retry(failed.id)
        XCTAssertEqual(store.queue.map(\.id), [failed.id])
    }

    // MARK: SOS

    func testSOSTextDefaultsAndCanBeEdited() {
        let store = makeStore()
        XCTAssertEqual(store.sosText, ConnectStatus.defaultSOSText)
        XCTAssertFalse(store.isSOSTextEdited)

        store.setSOSText("Need water at the school")
        XCTAssertEqual(store.sosText, "Need water at the school")
        XCTAssertTrue(store.isSOSTextEdited)

        store.restoreDefaultSOSText()
        XCTAssertEqual(store.sosText, ConnectStatus.defaultSOSText)
        XCTAssertFalse(store.isSOSTextEdited)
    }

    func testEditingBackToDefaultClearsDraft() {
        let store = makeStore()
        store.setSOSText("Changed")
        store.setSOSText(ConnectStatus.defaultSOSText)
        XCTAssertFalse(store.isSOSTextEdited)
    }

    func testQueuedSOSGoesToSOSConversationWithPriority() throws {
        let store = makeStore()
        let a = try XCTUnwrap(store.send("A", to: "family"))
        let b = try XCTUnwrap(store.send("B", to: "team"))
        store.setSOSText("Help at the bridge")
        let sos = try XCTUnwrap(store.queueSOS())

        XCTAssertTrue(sos.isSOS)
        XCTAssertEqual(sos.text, "Help at the bridge")
        XCTAssertEqual(sos.conversationID, ConnectDemoContent.sosConversationID)
        XCTAssertEqual(sos.state, .queued)
        XCTAssertEqual(store.queue.map(\.id), [sos.id, a.id, b.id])
        XCTAssertEqual(store.simulateNext(.delivered)?.id, sos.id)
    }

    func testSeveralSOSMessagesKeepTheirOrder() throws {
        let store = makeStore()
        let normal = try XCTUnwrap(store.send("A", to: "family"))
        let first = try XCTUnwrap(store.queueSOS())
        let second = try XCTUnwrap(store.queueSOS())
        XCTAssertEqual(store.queue.map(\.id), [first.id, second.id, normal.id])
    }

    func testRetriedSOSStaysAheadOfNormalMessages() throws {
        let store = makeStore()
        let sos = try XCTUnwrap(store.queueSOS())
        store.simulateNext(.failed)
        let normal = try XCTUnwrap(store.send("A", to: "family"))
        store.retry(sos.id)
        XCTAssertEqual(store.queue.map(\.id), [sos.id, normal.id])
    }

    func testEmptySOSIsNotQueued() {
        let store = makeStore()
        store.setSOSText("   ")
        XCTAssertNil(store.queueSOS())
        XCTAssertTrue(store.queue.isEmpty)
    }

    // MARK: Persistence

    func testMessagesStatesAndSOSDraftAreSavedAndReloaded() throws {
        let store = makeStore()
        let a = try XCTUnwrap(store.send("A", to: "family"))
        let b = try XCTUnwrap(store.send("B", to: "family"))
        store.simulate(a.id, .delivered)
        store.setSOSText("Saved SOS")
        let sos = try XCTUnwrap(store.queueSOS())

        let reopened = makeStore()
        XCTAssertEqual(reopened.data, store.data)
        XCTAssertEqual(reopened.queue.map(\.id), [sos.id, b.id])
        XCTAssertEqual(reopened.lastMessage(in: "family")?.id, b.id)
        XCTAssertEqual(reopened.history(in: "family").first { $0.id == a.id }?.state, .delivered)
        XCTAssertEqual(reopened.sosText, "Saved SOS")
    }

    func testOrderCounterSurvivesReload() throws {
        let store = makeStore()
        let a = try XCTUnwrap(store.send("A", to: "family"))
        let b = try XCTUnwrap(makeStore().send("B", to: "family"))
        XCTAssertGreaterThan(b.sequence, a.sequence)
    }

    func testDataIsSavedAsJSONUnderVersionedKey() throws {
        makeStore().send("A", to: "family")
        let raw = try XCTUnwrap(defaults.data(forKey: ConnectStore.storageKey))
        let decoded = try JSONDecoder().decode(ConnectData.self, from: raw)
        XCTAssertEqual(decoded.messages.last?.text, "A")
    }

    // MARK: Reset

    func testResetRestoresDemoAndRemovesSavedData() {
        let store = makeStore()
        store.send("A", to: "family")
        store.setSOSText("Edited")
        store.queueSOS()

        store.reset()
        XCTAssertEqual(store.data, ConnectDemoContent.initialData())
        XCTAssertNil(defaults.object(forKey: ConnectStore.storageKey))
        XCTAssertEqual(makeStore().data, ConnectDemoContent.initialData())
    }

    func testLocalDataResetIncludesConnect() {
        XCTAssertTrue(LocalDataReset.storageKeys.contains(ConnectStore.storageKey))
    }

    // MARK: Status

    func testBannerText() {
        XCTAssertEqual(ConnectStatus.banner, "LOCAL DEMO · NOT TRANSMITTED")
    }
}
