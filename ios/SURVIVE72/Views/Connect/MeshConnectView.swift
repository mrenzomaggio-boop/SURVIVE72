import SwiftUI
import UIKit

/// SURVIVE CONNECT: private messages that travel from phone to phone until
/// they reach the recipient. People are found by phone number.
struct MeshConnectView: View {
    @Environment(MeshService.self) private var mesh

    @State private var isEditingProfile = false
    @State private var searchNumber = ""
    @State private var searchResults: [MeshCard] = []
    @State private var didSearch = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                MeshStatusCard()
                profileSection
                searchSection
                conversationsSection
                peopleSection
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) { MeshNoticeBanner() }
        .navigationTitle(String(localized: "Connect"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .sheet(isPresented: $isEditingProfile) {
            MeshProfileEditor(name: mesh.profile.name, phone: mesh.profile.phone) { name, phone in
                mesh.updateProfile(name: name, phone: phone)
            }
        }
    }

    // MARK: Profile

    private var profileSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MeshSectionHeader(title: String(localized: "Your profile"), systemImage: "person.crop.circle.fill")
            VStack(alignment: .leading, spacing: 6) {
                Text(mesh.profile.name.isEmpty ? String(localized: "No nickname yet") : mesh.profile.name)
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(mesh.profile.phone.isEmpty
                     ? String(localized: "No phone number: people cannot find you by number.")
                     : String(localized: "Findable by number: \(mesh.profile.phone)"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(String(localized: "Security code: \(mesh.myCode)"))
                    .font(.subheadline.weight(.semibold).monospaced())
                    .foregroundStyle(Theme.textSecondary)
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .meshCardBackground()
            .accessibilityElement(children: .combine)

            BigButton(title: String(localized: "Edit profile"), systemImage: "pencil", color: Theme.accent) {
                isEditingProfile = true
            }
        }
    }

    // MARK: Search by nickname or phone number

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            MeshSectionHeader(title: String(localized: "Find a person"), systemImage: "magnifyingglass")
            TextField(String(localized: "Nickname or phone number"), text: $searchNumber)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit(search)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(12)
                .frame(minHeight: 52)
                .meshCardBackground()
                .accessibilityLabel(String(localized: "Nickname or phone number to find"))
                .onChange(of: searchNumber) { didSearch = false }

            BigButton(title: String(localized: "Search"), systemImage: "magnifyingglass", color: Theme.accent,
                      action: search)
            .disabled(searchNumber.trimmed.isEmpty)
            .opacity(searchNumber.trimmed.isEmpty ? 0.5 : 1)

            if didSearch {
                if searchResults.isEmpty {
                    Text(String(localized: "Nobody with this nickname or number has been seen on the network yet. They must have the app and have been in range of the network at least once."))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    if let tag = MeshPhone.tag(for: searchNumber),
                       searchResults.filter({ $0.phoneTag == tag }).count > 1 {
                        Label(String(localized: "More than one person declares this number. Numbers are not verified: check the security code with the person."),
                              systemImage: "exclamationmark.triangle.fill")
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(Theme.danger)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    ForEach(searchResults, id: \.code) { card in
                        personLink(card)
                    }
                }
            }
        }
    }

    private func search() {
        guard !searchNumber.trimmed.isEmpty else { return }
        searchResults = mesh.people(matching: searchNumber)
        didSearch = true
    }

    // MARK: Conversations

    private var conversationsSection: some View {
        let codes = mesh.conversationCodes
        return VStack(alignment: .leading, spacing: 12) {
            MeshSectionHeader(title: String(localized: "Conversations"),
                              systemImage: "bubble.left.and.bubble.right.fill")
            if codes.isEmpty {
                Text(String(localized: "No private messages yet."))
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
            }
            ForEach(codes, id: \.self) { code in
                NavigationLink {
                    MeshConversationView(code: code)
                } label: {
                    MeshPersonRow(name: mesh.card(for: code)?.name ?? "", code: code,
                                  detail: mesh.messages(with: code).last?.text)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: People

    private var peopleSection: some View {
        let people = mesh.reachablePeople
        return VStack(alignment: .leading, spacing: 12) {
            MeshSectionHeader(title: String(localized: "People seen on the network"),
                              systemImage: "person.2.fill")
            if people.isEmpty {
                Text(String(localized: "Nobody yet. People appear here when their phone is near yours, or when their alerts or messages reach this phone."))
                    .font(.body)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            ForEach(people, id: \.code) { card in
                personLink(card)
            }
        }
    }

    private func personLink(_ card: MeshCard) -> some View {
        NavigationLink {
            MeshConversationView(code: card.code)
        } label: {
            MeshPersonRow(name: card.name, code: card.code,
                          detail: mesh.nearbyPeopleCodes.contains(card.code)
                              ? String(localized: "Near you now · \(card.code)") : nil)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared pieces

extension View {
    /// Standard card look used by the mesh screens.
    func meshCardBackground() -> some View {
        self
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius)
                    .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth)
            )
    }
}

/// Name shown for a person: their nickname, or a fixed text when they have none.
enum MeshDisplay {
    static func name(_ name: String) -> String {
        name.isEmpty ? String(localized: "No nickname") : name
    }

    /// "passed through 2 phones", from the number of hops a packet made.
    static func relays(hops: Int) -> String {
        let phones = max(hops - 1, 1)
        return phones == 1
            ? String(localized: "passed through 1 phone")
            : String(localized: "passed through \(phones) phones")
    }
}

/// Always-visible reminder of what the phone-to-phone network is and is not.
struct MeshNoticeBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3.weight(.bold))
                .accessibilityHidden(true)
            Text(String(localized: "PHONE-TO-PHONE NETWORK · NOT AN EMERGENCY SERVICE"))
                .font(.subheadline.weight(.black))
                .minimumScaleFactor(0.7)
                .lineLimit(2)
        }
        .foregroundStyle(Theme.onAccent)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.accent)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(localized: "Phone-to-phone network. It is not an emergency service: delivery is not guaranteed."))
    }
}

struct MeshSectionHeader: View {
    let title: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.title2.weight(.bold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(title.uppercased())
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// On/off switch of the link to nearby phones, with the number connected now.
struct MeshStatusCard: View {
    @Environment(MeshService.self) private var mesh

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle(isOn: Binding(get: { mesh.isEnabled }, set: { mesh.setEnabled($0) })) {
                Text(String(localized: "Network between nearby phones"))
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
            }
            .tint(Theme.ok)
            .frame(minHeight: 44)

            Text(statusText)
                .font(.headline.weight(.heavy))
                .foregroundStyle(mesh.isEnabled && mesh.nearbyCount > 0 ? Theme.ok : Theme.textSecondary)

            Text(String(localized: "Uses Bluetooth and Wi-Fi between phones, without internet. It works while the app is open, with phones a few tens of metres away. iOS will ask for permission the first time."))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Theme.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .meshCardBackground()
    }

    private var statusText: String {
        guard mesh.isEnabled else { return String(localized: "OFF") }
        switch mesh.nearbyCount {
        case 0: return String(localized: "ON · no phone in range")
        case 1: return String(localized: "ON · 1 phone connected")
        default: return String(localized: "ON · \(mesh.nearbyCount) phones connected")
        }
    }
}

struct MeshPersonRow: View {
    let name: String
    let code: String
    let detail: String?

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(MeshDisplay.name(name))
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Text(detail ?? code)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .meshCardBackground()
        .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isButton)
    }
}

/// Sheet to edit nickname and phone number.
struct MeshProfileEditor: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var phone: String
    private let onSave: (String, String) -> Void

    init(name: String, phone: String, onSave: @escaping (String, String) -> Void) {
        _name = State(initialValue: name)
        _phone = State(initialValue: phone)
        self.onSave = onSave
    }

    private var phoneIsValid: Bool {
        phone.trimmed.isEmpty || MeshPhone.normalized(phone) != nil
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    field(String(localized: "Nickname"), text: $name,
                          prompt: String(localized: "How others see you"), keyboard: .default)
                    field(String(localized: "Phone number (optional)"), text: $phone,
                          prompt: String(localized: "e.g. 333 123 4567"), keyboard: .phonePad)

                    if !phoneIsValid {
                        Text(String(localized: "This does not look like a phone number."))
                            .font(.subheadline.weight(.heavy))
                            .foregroundStyle(Theme.danger)
                    }

                    Text(String(localized: "With a number, people who already know it can find you on the network. The number itself is not sent: only a fingerprint of it travels. It is not verified, and someone with technical skills could work it out. Leave it empty if you prefer."))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(16)
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle(String(localized: "Your profile"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(String(localized: "Cancel")) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(String(localized: "Save")) {
                        onSave(name, phone)
                        dismiss()
                    }
                    .disabled(!phoneIsValid)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func field(_ label: String, text: Binding<String>, prompt: String,
                       keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
            TextField(prompt, text: text)
                .keyboardType(keyboard)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .padding(12)
                .frame(minHeight: 52)
                .meshCardBackground()
                .accessibilityLabel(label)
        }
    }
}
