import Foundation

/// Bundled demo conversations for SURVIVE CONNECT. The people are fictional
/// and nothing here comes from a real device or network.
enum ConnectDemoContent {
    static let sosConversationID = "sos"

    static let conversations: [ConnectConversation] = [
        ConnectConversation(id: sosConversationID, title: String(localized: "SOS (local)"),
                            subtitle: String(localized: "Priority messages · never transmitted")),
        ConnectConversation(id: "family", title: String(localized: "Family (demo)"), subtitle: String(localized: "Demo group")),
        ConnectConversation(id: "neighbours", title: String(localized: "Neighbours (demo)"), subtitle: String(localized: "Demo group")),
        ConnectConversation(id: "team", title: String(localized: "Team leader (demo)"), subtitle: String(localized: "Demo contact"))
    ]

    /// Fixed reference date so the demo looks the same everywhere.
    static let referenceDate = Date(timeIntervalSince1970: 1_800_000_000)

    static func initialData() -> ConnectData {
        let seed: [(String, String, Bool, MessageDeliveryState)] = [
            ("family", String(localized: "Demo: Everyone ok? Reply when you can."), false, .delivered),
            ("family", String(localized: "Demo: All fine here. Water and food ready."), true, .delivered),
            ("family", String(localized: "Demo: Meet at the usual place if needed."), false, .delivered),
            ("neighbours", String(localized: "Demo: Power is out on our street."), false, .delivered),
            ("neighbours", String(localized: "Demo: We have spare blankets if anyone needs them."), true, .failed),
            ("team", String(localized: "Demo: Check-in at the agreed time."), false, .delivered)
        ]
        var messages: [ConnectMessage] = []
        for (index, entry) in seed.enumerated() {
            messages.append(ConnectMessage(
                // Fixed ids so the demo data is identical every time it is created.
                id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012ld", index + 1))!,
                conversationID: entry.0,
                text: entry.1,
                isOutgoing: entry.2,
                createdAt: referenceDate.addingTimeInterval(Double(index) * 300),
                sequence: index + 1,
                queueOrder: index + 1,
                state: entry.3
            ))
        }
        return ConnectData(conversations: conversations, messages: messages,
                           sosDraft: nil, nextOrder: seed.count + 1)
    }
}
