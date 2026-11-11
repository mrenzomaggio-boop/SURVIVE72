import SwiftUI
import UIKit

/// Edit the local SOS text and put it at the front of the queue.
/// Nothing is transmitted and nobody is contacted.
struct SOSComposerView: View {
    @Environment(ConnectStore.self) private var store
    @State private var didQueue = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ConnectHeader(title: "SOS message", systemImage: "sos.circle.fill")

                Text("Priority message: it always goes ahead of other queued messages. "
                     + "It stays on this device and is never transmitted.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)

                TextEditor(text: Binding(
                    get: { store.sosText },
                    set: { store.setSOSText($0); didQueue = false }
                ))
                .font(.title3)
                .foregroundStyle(Theme.textPrimary)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(minHeight: 180)
                .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Theme.danger, lineWidth: Theme.borderWidth)
                )
                .accessibilityLabel("SOS message text")

                BigButton(title: didQueue ? "Queued · not transmitted" : "Queue SOS (priority)",
                          systemImage: didQueue ? "checkmark.circle.fill" : "sos",
                          color: didQueue ? Theme.ok : Theme.danger) {
                    if store.queueSOS() != nil {
                        didQueue = true
                        UIAccessibility.post(notification: .announcement,
                                             argument: "SOS queued locally. Not transmitted.")
                    }
                }
                .disabled(store.sosText.trimmed.isEmpty)
                .sensoryFeedback(.warning, trigger: didQueue)

                if store.isSOSTextEdited {
                    BigButton(title: "Restore default text", systemImage: "arrow.uturn.backward",
                              color: Theme.textPrimary) {
                        store.restoreDefaultSOSText()
                        didQueue = false
                    }
                }
            }
            .padding(16)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(Theme.background.ignoresSafeArea())
        .safeAreaInset(edge: .top, spacing: 0) {
            LocalDemoBanner()
        }
        .navigationTitle("SOS")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        SOSComposerView()
    }
    .environment(ConnectStore(defaults: UserDefaults(suiteName: "preview.connect")!))
    .preferredColorScheme(.dark)
}
