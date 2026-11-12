import SwiftUI

/// SURVIVE RADIO: emergency frequencies to listen to, links to official live
/// streams and an offline guide with search and topic filters. No radio
/// access, no hardware, no audio played inside the app.
struct RadioGuideView: View {
    private let guide = RadioGuide()

    @State private var query = ""
    @State private var topic: RadioTopic?

    private var results: [RadioGuideEntry] { guide.filter(query, topic: topic) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label(RadioFrequencyContent.notice,
                      systemImage: "antenna.radiowaves.left.and.right.slash")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Theme.accent, lineWidth: Theme.borderWidth))

                if query.isEmpty && topic == nil {
                    sectionHeader(String(localized: "Emergency frequencies (Italy)"))
                    ForEach(RadioFrequencyContent.frequencies) { item in
                        RadioFrequencyCard(item: item)
                    }

                    sectionHeader(String(localized: "Listen online"))
                    ForEach(RadioFrequencyContent.streams) { stream in
                        RadioStreamLink(stream: stream)
                    }

                    sectionHeader(String(localized: "Radio guide"))
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        chip(String(localized: "All"), systemImage: "square.grid.2x2.fill",
                             count: guide.count(in: nil), selected: topic == nil) { topic = nil }
                        ForEach(RadioTopic.allCases) { item in
                            chip(item.title, systemImage: item.systemImage,
                                 count: guide.count(in: item), selected: topic == item) { topic = item }
                        }
                    }
                    .padding(.vertical, 2)
                }

                Text(results.count == 1 ? String(localized: "\(results.count) entry") : String(localized: "\(results.count) entries"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)

                if results.isEmpty {
                    Text(String(localized: "No entries found. Try another word or choose All."))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.vertical, 24)
                } else {
                    ForEach(results) { entry in
                        RadioEntryCard(entry: entry)
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(String(localized: "Radio"))
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: String(localized: "Search the radio guide"))
        .autocorrectionDisabled()
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title2.weight(.heavy))
            .foregroundStyle(Theme.textPrimary)
            .padding(.top, 4)
            .accessibilityAddTraits(.isHeader)
    }

    private func chip(_ title: String, systemImage: String, count: Int, selected: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.heavy))
                .foregroundStyle(selected ? Theme.onAccent : Theme.textPrimary)
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .background(selected ? Theme.accent : Theme.surface, in: Capsule())
                .overlay(Capsule().stroke(selected ? Theme.accent : Theme.surfaceBorder,
                                          lineWidth: Theme.borderWidth))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "\(title) filter"))
        .accessibilityValue(count == 1 ? String(localized: "\(count) entry") : String(localized: "\(count) entries"))
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

/// Entry shown in full: the guide is short, so no separate detail page.
private struct RadioEntryCard: View {
    let entry: RadioGuideEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(entry.topic.title.uppercased(), systemImage: entry.topic.systemImage)
                .font(.caption.weight(.heavy))
                .foregroundStyle(Theme.accent)
            Text(entry.title)
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Text(entry.summary)
                .font(.body.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            ForEach(entry.points, id: \.self) { point in
                HStack(alignment: .top, spacing: 8) {
                    Text("•").foregroundStyle(Theme.accent)
                    Text(point)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(.body)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
            .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth))
        .accessibilityElement(children: .combine)
    }
}

/// One frequency with its use and whether you may transmit on it.
private struct RadioFrequencyCard: View {
    let item: RadioFrequency

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.name)
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Text(item.frequency)
                .font(.title2.weight(.black).monospacedDigit())
                .foregroundStyle(Theme.accent)
            Text(item.use)
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Label(item.rule.label,
                  systemImage: item.rule.canTransmitFreely ? "checkmark.circle.fill" : "ear.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(item.rule.canTransmitFreely ? Theme.ok : Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
            .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth))
        .accessibilityElement(children: .combine)
    }
}

/// Large button that opens an official live stream outside the app.
private struct RadioStreamLink: View {
    let stream: RadioStream

    var body: some View {
        Link(destination: stream.url) {
            HStack(spacing: 14) {
                Image(systemName: "play.circle.fill")
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.accent)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(stream.name)
                        .font(.title3.weight(.heavy))
                        .foregroundStyle(Theme.textPrimary)
                    Text(stream.detail)
                        .font(.subheadline)
                        .foregroundStyle(Theme.textSecondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "arrow.up.right.square")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth))
        }
        .accessibilityHint(String(localized: "Opens outside the app. Needs internet."))
    }
}
