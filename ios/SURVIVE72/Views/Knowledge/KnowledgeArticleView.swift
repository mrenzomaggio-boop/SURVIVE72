import SwiftUI
import UIKit

/// Detail page of one library article.
struct KnowledgeArticleView: View {
    let article: KnowledgeArticle

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 10) {
                    Image(systemName: article.category.systemImage)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Theme.accent)
                        .accessibilityHidden(true)
                    Text(article.category.title.uppercased())
                        .font(.headline.weight(.heavy))
                        .foregroundStyle(Theme.textSecondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(String(localized: "Category: \(article.category.title)"))

                Text(article.title)
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)

                VerificationBadge(status: article.status, large: true)

                Text(article.summary)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Array(article.sections.enumerated()), id: \.offset) { _, section in
                    VStack(alignment: .leading, spacing: 10) {
                        Label {
                            Text(section.heading)
                                .font(.title2.weight(.black))
                                .foregroundStyle(Theme.textPrimary)
                        } icon: {
                            Image(systemName: SymbolCheck.safe(section.symbol))
                                .font(.title2.weight(.bold))
                                .foregroundStyle(Theme.accent)
                        }
                        .accessibilityAddTraits(.isHeader)

                        ForEach(section.points, id: \.self) { point in
                            IllustratedRow(symbol: point.symbol, text: point.text)
                        }
                    }
                    .padding(.top, 8)
                }

                SourceCredit(source: article.source)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// Returns the symbol name if it exists on this system, otherwise a neutral
/// circle, so a wrong name never leaves an empty space.
enum SymbolCheck {
    static func safe(_ name: String) -> String {
        UIImage(systemName: name) == nil ? "circle.fill" : name
    }
}

/// Big pictogram tile next to a short instruction: one action per row, easy
/// to read at a glance. Optionally numbered.
struct IllustratedRow: View {
    let symbol: String
    let text: String
    var number: Int?

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack(alignment: .topLeading) {
                Image(systemName: SymbolCheck.safe(symbol))
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Theme.onAccent)
                    .frame(width: 64, height: 64)
                    .background(Theme.accent, in: RoundedRectangle(cornerRadius: 12))
                if let number {
                    Text("\(number)")
                        .font(.caption.weight(.black))
                        .foregroundStyle(Theme.accent)
                        .frame(width: 24, height: 24)
                        .background(Theme.background, in: Circle())
                        .overlay(Circle().stroke(Theme.accent, lineWidth: 2))
                        .offset(x: -8, y: -8)
                }
            }
            .accessibilityHidden(true)

            Text(text)
                .font(.title3.weight(.semibold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
            .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(number.map { String(localized: "Step \($0): \(text)") } ?? text)
    }
}

/// Mandatory credit of the source, with its licence and a link to the site.
struct SourceCredit: View {
    let source: ContentSource

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(source.credit)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
            Text(source.licence)
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            Link(destination: source.url) {
                Label(String(localized: "Open the official site"), systemImage: "safari.fill")
                    .font(.subheadline.weight(.heavy))
                    .foregroundStyle(Theme.accent)
                    .frame(minHeight: 44)
            }
        }
        .fixedSize(horizontal: false, vertical: true)
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius)
            .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth))
    }
}

/// High-contrast "OFFICIAL SOURCE" marker.
struct VerificationBadge: View {
    let status: VerificationStatus
    var large = false

    var body: some View {
        Label(status.label, systemImage: "checkmark.seal.fill")
            .font(large ? .headline.weight(.black) : .caption.weight(.heavy))
            .foregroundStyle(Theme.onAccent)
            .padding(.horizontal, large ? 12 : 8)
            .padding(.vertical, large ? 8 : 3)
            .background(Theme.accent, in: Capsule())
            .accessibilityLabel(status.label.capitalized)
    }
}

#Preview {
    NavigationStack {
        KnowledgeArticleView(article: KnowledgeLibraryContent.articles[0])
    }
    .preferredColorScheme(.dark)
}
