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
                .accessibilityLabel("Category: \(article.category.title)")

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

                ForEach(Array(article.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                    Text(paragraph)
                        .font(.body)
                        .foregroundStyle(Theme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(article.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

/// High-contrast "TO BE VERIFIED" marker.
struct VerificationBadge: View {
    let status: VerificationStatus
    var large = false

    var body: some View {
        Label(status.label, systemImage: "exclamationmark.triangle.fill")
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
