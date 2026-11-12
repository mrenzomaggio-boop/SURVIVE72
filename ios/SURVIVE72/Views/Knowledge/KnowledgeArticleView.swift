import SwiftUI

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
                    VStack(alignment: .leading, spacing: 8) {
                        Text(section.heading)
                            .font(.title2.weight(.heavy))
                            .foregroundStyle(Theme.accent)
                            .accessibilityAddTraits(.isHeader)
                        ForEach(section.points, id: \.self) { point in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•").foregroundStyle(Theme.accent)
                                    .accessibilityHidden(true)
                                Text(point)
                                    .foregroundStyle(Theme.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .font(.body)
                        }
                    }
                    .padding(.top, 4)
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
            .foregroundStyle(Theme.background)
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
