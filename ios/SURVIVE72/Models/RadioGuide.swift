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
        case .basics: String(localized: "Basics")
        case .equipment: String(localized: "Equipment")
        case .listening: String(localized: "Listening")
        case .power: String(localized: "Power")
        case .rules: String(localized: "Rules")
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

/// Whether and how a frequency may be used to transmit in Italy.
enum TransmitRule: String, Hashable {
    case listenOnly
    case licenceFree
    case cbAuthorisation
    case amateurLicence
    case marineCertificate

    var label: String {
        switch self {
        case .listenOnly: String(localized: "Listen only")
        case .licenceFree: String(localized: "Transmitting allowed without a licence")
        case .cbAuthorisation: String(localized: "Transmitting needs the CB general authorisation")
        case .amateurLicence: String(localized: "Transmitting needs an amateur radio licence")
        case .marineCertificate: String(localized: "Transmitting needs a marine radio certificate")
        }
    }

    var canTransmitFreely: Bool { self == .licenceFree }
}

/// One frequency worth listening to in an emergency in Italy. The app only
/// shows the list: it never tunes, receives or transmits anything.
struct RadioFrequency: Identifiable, Hashable {
    let id: String
    let name: String
    /// Written exactly as on a radio display, e.g. "103.3 MHz FM".
    let frequency: String
    let use: String
    let rule: TransmitRule
}

/// Official live stream, opened in the browser or the broadcaster's app.
/// The app never plays audio itself.
struct RadioStream: Identifiable, Hashable {
    let id: String
    let name: String
    let detail: String
    let url: URL
}

enum RadioFrequencyContent {
    static let notice = String(localized: "Listening is always allowed. Transmitting needs a licence or authorisation, except with PMR446 walkie-talkies. This app never transmits.")

    static let frequencies: [RadioFrequency] = [
        RadioFrequency(id: "rai.isoradio", name: "Rai Isoradio", frequency: "103.3 MHz FM",
                       use: String(localized: "Traffic and emergency information, covers the motorway network."),
                       rule: .listenOnly),
        RadioFrequency(id: "rai.radio1", name: "Rai Radio 1", frequency: String(localized: "FM, varies by area"),
                       use: String(localized: "National news and official announcements during emergencies. Look up your local frequency now and write it in your kit."),
                       rule: .listenOnly),
        RadioFrequency(id: "cb.9", name: String(localized: "CB channel 9"), frequency: "27.065 MHz",
                       use: String(localized: "Emergency channel for CB radios."),
                       rule: .cbAuthorisation),
        RadioFrequency(id: "pmr.8-16", name: String(localized: "PMR446 channel 8, tone 16"), frequency: "446.09375 MHz",
                       use: String(localized: "Informal European convention for calls for help between walkie-talkies. Not an official channel."),
                       rule: .licenceFree),
        RadioFrequency(id: "pmr.1", name: String(localized: "PMR446 channel 1"), frequency: "446.00625 MHz",
                       use: String(localized: "The channel most used by low-cost walkie-talkies."),
                       rule: .licenceFree),
        RadioFrequency(id: "ham.vhf", name: String(localized: "Amateur radio VHF"), frequency: "145.500 MHz FM",
                       use: String(localized: "Amateur radio calling frequency, also used by emergency networks."),
                       rule: .amateurLicence),
        RadioFrequency(id: "ham.uhf", name: String(localized: "Amateur radio UHF"), frequency: "433.500 MHz FM",
                       use: String(localized: "Amateur radio UHF calling frequency."),
                       rule: .amateurLicence),
        RadioFrequency(id: "marine.16", name: String(localized: "Marine VHF channel 16"), frequency: "156.800 MHz",
                       use: String(localized: "Distress and calling at sea, monitored by the Coast Guard."),
                       rule: .marineCertificate)
    ]

    static let streams: [RadioStream] = [
        RadioStream(id: "stream.radio1", name: "Rai Radio 1",
                    detail: String(localized: "Live on RaiPlay Sound"),
                    url: URL(string: "https://www.raiplaysound.it/radio1")!),
        RadioStream(id: "stream.isoradio", name: "Rai Isoradio",
                    detail: String(localized: "Live on RaiPlay Sound"),
                    url: URL(string: "https://www.raiplaysound.it/isoradio")!),
        RadioStream(id: "stream.protezionecivile", name: String(localized: "Civil Protection"),
                    detail: String(localized: "Official news and alerts"),
                    url: URL(string: "https://www.protezionecivile.gov.it")!)
    ]
}

/// One informational entry. General guidance only: no frequencies, no
/// transmitting procedures, and the app never accesses a radio. Frequencies
/// live in `RadioFrequencyContent`.
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
            title: String(localized: "Why a radio matters"),
            summary: String(localized: "Broadcast radio can keep working when phone and internet networks are down."),
            points: [String(localized: "Authorities often share updates on public broadcast stations."),
                     String(localized: "A receiver only listens: it does not need a network or an account."),
                     String(localized: "Check which local stations carry emergency information before you need them.")]),
        RadioGuideEntry(
            id: "basics.receive", topic: .basics,
            title: String(localized: "Receiving versus transmitting"),
            summary: String(localized: "Listening is open to everyone; transmitting usually needs a licence."),
            points: [String(localized: "This app never transmits and never accesses radio hardware."),
                     String(localized: "Rules for transmitting differ by country: check your national regulator.")]),
        RadioGuideEntry(
            id: "equipment.receiver", topic: .equipment,
            title: String(localized: "Choosing a receiver"),
            summary: String(localized: "A simple portable receiver is enough to follow official updates."),
            points: [String(localized: "Prefer models with more than one power option."),
                     String(localized: "An earphone socket helps you listen quietly."),
                     String(localized: "Keep the user manual with the radio.")]),
        RadioGuideEntry(
            id: "equipment.storage", topic: .equipment,
            title: String(localized: "Storing the radio"),
            summary: String(localized: "Keep the radio in your kit, protected from water and knocks."),
            points: [String(localized: "Use a sealed bag or box."),
                     String(localized: "Test it every few months together with your kit.")]),
        RadioGuideEntry(
            id: "listening.routine", topic: .listening,
            title: String(localized: "Listening routine"),
            summary: String(localized: "Listen at regular times instead of all day to save power."),
            points: [String(localized: "Follow the schedule announced by local authorities, if any."),
                     String(localized: "Write down key information on paper."),
                     String(localized: "Share updates with your group at the meeting point.")]),
        RadioGuideEntry(
            id: "listening.reception", topic: .listening,
            title: String(localized: "Improving reception"),
            summary: String(localized: "Position matters more than volume."),
            points: [String(localized: "Try near a window or outdoors."),
                     String(localized: "Extend the antenna fully and change its angle slowly."),
                     String(localized: "Move away from electrical devices that cause noise.")]),
        RadioGuideEntry(
            id: "power.batteries", topic: .power,
            title: String(localized: "Batteries"),
            summary: String(localized: "Spare batteries are part of your emergency kit."),
            points: [String(localized: "Store spares matching your radio."),
                     String(localized: "Remove batteries during long storage to avoid leaks."),
                     String(localized: "Note the date when you replace them.")]),
        RadioGuideEntry(
            id: "power.crank", topic: .power,
            title: String(localized: "Hand-crank and solar"),
            summary: String(localized: "Alternative power keeps the radio usable when batteries run out."),
            points: [String(localized: "Practise using the crank before an emergency."),
                     String(localized: "Solar panels charge slowly: leave them in direct light.")]),
        RadioGuideEntry(
            id: "rules.respect", topic: .rules,
            title: String(localized: "Respect official sources"),
            summary: String(localized: "Official information comes first."),
            points: [String(localized: "Do not spread unconfirmed information heard on the radio."),
                     String(localized: "Follow instructions from local authorities.")])
    ]
}
