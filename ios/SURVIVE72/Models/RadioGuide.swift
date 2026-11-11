import Foundation

/// Topics of the offline radio guide.
enum RadioTopic: String, CaseIterable, Identifiable, Hashable {
    case basics
    case equipment
    case listening
    case power
    case rules

    var id: String { rawValue }

    var title: String {
        switch self {
        case .basics: "Basics"
        case .equipment: "Equipment"
        case .listening: "Listening"
        case .power: "Power"
        case .rules: "Rules"
        }
    }

    var systemImage: String {
        switch self {
        case .basics: "info.circle.fill"
        case .equipment: "radio.fill"
        case .listening: "ear.fill"
        case .power: "battery.75percent"
        case .rules: "checkmark.shield.fill"
        }
    }
}

/// One informational entry. General guidance only: no frequencies, no
/// transmitting procedures, and the app never accesses a radio.
struct RadioGuideEntry: Identifiable, Hashable {
    let id: String
    let topic: RadioTopic
    let title: String
    let summary: String
    let points: [String]

    var searchableText: String {
        ([title, summary] + points).joined(separator: " ")
    }
}

/// Search and topic filter over the guide (same rules as Knowledge:
/// case- and accent-insensitive, every word must match, order preserved).
struct RadioGuide {
    let entries: [RadioGuideEntry]

    init(entries: [RadioGuideEntry] = RadioGuideContent.entries) {
        self.entries = entries
    }

    func filter(_ query: String, topic: RadioTopic? = nil) -> [RadioGuideEntry] {
        let terms = KnowledgeLibrary.terms(from: query)
        return entries.filter { entry in
            if let topic, entry.topic != topic { return false }
            guard !terms.isEmpty else { return true }
            let text = KnowledgeLibrary.normalize(entry.searchableText)
            return terms.allSatisfy { text.contains($0) }
        }
    }

    func count(in topic: RadioTopic?) -> Int {
        guard let topic else { return entries.count }
        return entries.filter { $0.topic == topic }.count
    }
}

enum RadioGuideContent {
    static let entries: [RadioGuideEntry] = [
        RadioGuideEntry(
            id: "basics.why", topic: .basics,
            title: "Why a radio matters",
            summary: "Broadcast radio can keep working when phone and internet networks are down.",
            points: ["Authorities often share updates on public broadcast stations.",
                     "A receiver only listens: it does not need a network or an account.",
                     "Check which local stations carry emergency information before you need them."]),
        RadioGuideEntry(
            id: "basics.receive", topic: .basics,
            title: "Receiving versus transmitting",
            summary: "Listening is open to everyone; transmitting usually needs a licence.",
            points: ["This app never transmits and never accesses radio hardware.",
                     "Rules for transmitting differ by country: check your national regulator."]),
        RadioGuideEntry(
            id: "equipment.receiver", topic: .equipment,
            title: "Choosing a receiver",
            summary: "A simple portable receiver is enough to follow official updates.",
            points: ["Prefer models with more than one power option.",
                     "An earphone socket helps you listen quietly.",
                     "Keep the user manual with the radio."]),
        RadioGuideEntry(
            id: "equipment.storage", topic: .equipment,
            title: "Storing the radio",
            summary: "Keep the radio in your kit, protected from water and knocks.",
            points: ["Use a sealed bag or box.",
                     "Test it every few months together with your kit."]),
        RadioGuideEntry(
            id: "listening.routine", topic: .listening,
            title: "Listening routine",
            summary: "Listen at regular times instead of all day to save power.",
            points: ["Follow the schedule announced by local authorities, if any.",
                     "Write down key information on paper.",
                     "Share updates with your group at the meeting point."]),
        RadioGuideEntry(
            id: "listening.reception", topic: .listening,
            title: "Improving reception",
            summary: "Position matters more than volume.",
            points: ["Try near a window or outdoors.",
                     "Extend the antenna fully and change its angle slowly.",
                     "Move away from electrical devices that cause noise."]),
        RadioGuideEntry(
            id: "power.batteries", topic: .power,
            title: "Batteries",
            summary: "Spare batteries are part of your emergency kit.",
            points: ["Store spares matching your radio.",
                     "Remove batteries during long storage to avoid leaks.",
                     "Note the date when you replace them."]),
        RadioGuideEntry(
            id: "power.crank", topic: .power,
            title: "Hand-crank and solar",
            summary: "Alternative power keeps the radio usable when batteries run out.",
            points: ["Practise using the crank before an emergency.",
                     "Solar panels charge slowly: leave them in direct light."]),
        RadioGuideEntry(
            id: "rules.respect", topic: .rules,
            title: "Respect official sources",
            summary: "Official information comes first.",
            points: ["Do not spread unconfirmed information heard on the radio.",
                     "Follow instructions from local authorities."])
    ]
}
