import SwiftUI

/// SURVIVE KNOWLEDGE: offline library with local search and category filters.
struct KnowledgeLibraryView: View {
    private let library = KnowledgeLibrary()

    @State private var query = ""
    @State private var selectedCategory: KnowledgeCategory?

    private var results: [KnowledgeArticle] {
        library.search(query, in: selectedCategory)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                DemoNotice()

                CategoryFilterBar(
                    library: library,
                    selected: $selectedCategory
                )

                Text(resultsSummary)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.textSecondary)
                    .accessibilityAddTraits(.updatesFrequently)

                if results.isEmpty {
                    EmptyResults()
                } else {
                    LazyVStack(spacing: Theme.spacing) {
                        ForEach(results) { article in
                            NavigationLink(value: article) {
                                KnowledgeArticleRow(article: article)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(16)
        }
        .background(Theme.background.ignoresSafeArea())
        .navigationTitle(String(localized: "Knowledge"))
        .navigationBarTitleDisplayMode(.large)
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: String(localized: "Search titles and text")
        )
        .autocorrectionDisabled()
        .navigationDestination(for: KnowledgeArticle.self) { article in
            KnowledgeArticleView(article: article)
        }
    }

    private var resultsSummary: String {
        let scope = selectedCategory?.title ?? String(localized: "all categories")
        return results.count == 1
            ? String(localized: "\(results.count) article in \(scope)")
            : String(localized: "\(results.count) articles in \(scope)")
    }
}

/// Horizontal row of large filter chips: All + one per category.
private struct CategoryFilterBar: View {
    let library: KnowledgeLibrary
    @Binding var selected: KnowledgeCategory?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                chip(title: String(localized: "All"), systemImage: "square.grid.2x2.fill",
                     count: library.count(in: nil), isSelected: selected == nil) {
                    selected = nil
                }
                ForEach(KnowledgeCategory.allCases) { category in
                    chip(title: category.title, systemImage: category.systemImage,
                         count: library.count(in: category), isSelected: selected == category) {
                        selected = category
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(
        title: String,
        systemImage: String,
        count: Int,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline.weight(.heavy))
                .foregroundStyle(isSelected ? Theme.background : Theme.textPrimary)
                .padding(.horizontal, 14)
                .frame(minHeight: 48)
                .background(isSelected ? Theme.accent : Theme.surface, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? Theme.accent : Theme.surfaceBorder,
                                          lineWidth: Theme.borderWidth))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "\(title) filter"))
        .accessibilityValue(count == 1 ? String(localized: "\(count) article") : String(localized: "\(count) articles"))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// One article in the result list.
private struct KnowledgeArticleRow: View {
    let article: KnowledgeArticle

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: article.category.systemImage)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Theme.accent)
                .frame(width: 36)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 6) {
                Text(article.title)
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Theme.textPrimary)
                Text(article.summary)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: 8) {
                    Text(article.category.title.uppercased())
                        .font(.caption.weight(.heavy))
                        .foregroundStyle(Theme.textSecondary)
                    VerificationBadge(status: article.status)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.headline.weight(.bold))
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 88, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.surfaceBorder, lineWidth: Theme.borderWidth)
        )
        .contentShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(article.title). \(article.summary)")
        .accessibilityValue("\(article.category.title), \(article.status.label.lowercased())")
        .accessibilityAddTraits(.isButton)
    }
}

/// Always-visible warning that the library is unreviewed demo content.
private struct DemoNotice: View {
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.title3.weight(.bold))
                .foregroundStyle(Theme.accent)
                .accessibilityHidden(true)
            Text(String(localized: "All articles are demo content marked TO BE VERIFIED. They are not instructions and not medical advice."))
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.accent, lineWidth: Theme.borderWidth)
        )
        .accessibilityElement(children: .combine)
    }
}

private struct EmptyResults: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 36, weight: .bold))
                .foregroundStyle(Theme.textSecondary)
                .accessibilityHidden(true)
            Text(String(localized: "No articles found"))
                .font(.title3.weight(.heavy))
                .foregroundStyle(Theme.textPrimary)
            Text(String(localized: "Try another word or choose All."))
                .font(.body)
                .foregroundStyle(Theme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        KnowledgeLibraryView()
    }
    .preferredColorScheme(.dark)
}
