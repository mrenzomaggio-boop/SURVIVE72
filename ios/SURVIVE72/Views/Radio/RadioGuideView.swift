import SwiftUI

/// SURVIVE RADIO: offline information guide with search and topic filters.
/// No frequencies, no radio access, no hardware.
struct RadioGuideView: View {
    private let guide = RadioGuide()

    @State private var query = ""
    @State private var topic: RadioTopic?

    private var results: [RadioGuideEntry] { guide.filter(query, topic: topic) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Label("General information only. No frequencies, no radio access, nothing is transmitted.",
                      systemImage: "antenna.radiowaves.left.and.right.slash")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textPrimary)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Theme.accent, lineWidth: Theme.borderWidth))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        chip("All", systemImage: "square.grid.2x2.fill",
                             count: guide.count(in: nil), selected: topic == nil) { topic = nil }
                        ForEach(RadioTopic.allCases) { item in
                            chip(item.title, systemImage: item.systemImage,
                                 count: guide.count(in: item), selected: topic == item) { topic = item }
                        }
                    }
                    .padding(.vertical, 2)
                }

                Text("\(results.count) \(results.count == 1 ? "entry" : "entries")")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)

                if results.isEmpty {
                    Text("No entries found. Try another word or choose All.")
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
        .navigationTitle("Radio")
        .navigationBarTitleDisplayMode(.large)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: "Search the radio guide")
        .autocorrectionDisabled()
    }

    private func chip(_ title: String, systemImage: String, count: Int, selected: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.heavy))
                .foregroundStyle(selected ? Theme.background : Theme.textPrimary)
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .background(selected ? Theme.accent : Theme.surface, in: Capsule())
                .overlay(Capsule().stroke(selected ? Theme.accent : Theme.surfaceBorder,
                                          lineWidth: Theme.borderWidth))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(title) filter")
        .accessibilityValue("\(count) \(count == 1 ? "entry" : "entries")")
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
