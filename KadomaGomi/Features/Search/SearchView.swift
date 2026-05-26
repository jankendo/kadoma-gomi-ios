import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var store: MasterStore
    @State private var query = ""
    @State private var selectedCategoryId: String?

    init(initialQuery: String = "", initialCategoryId: String? = nil) {
        _query = State(initialValue: initialQuery)
        _selectedCategoryId = State(initialValue: initialCategoryId)
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var searchedItems: [WasteItem] {
        let base = store.searchItems(query: query)
        guard let selectedCategoryId else { return base }
        return base.filter { $0.categoryId == selectedCategoryId }
    }

    private var visibleCategories: [WasteCategory] {
        store.master.categories.filter { category in
            store.master.itemDictionary.contains { $0.categoryId == category.id }
        }
    }

    var body: some View {
        NavigationStack {
            AppScreen {
                SimpleSearchHeader(query: $query)
                SimpleCategoryFilter(
                    categories: visibleCategories,
                    selectedCategoryId: $selectedCategoryId
                )

                if trimmedQuery.isEmpty {
                    SearchEmptyInstruction(
                        examples: ["ペットボトル", "スプレー缶", "段ボール", "モバイルバッテリー"],
                        setQuery: { query = $0 }
                    )
                } else {
                    SimpleSearchResultsSection(
                        query: trimmedQuery,
                        selectedCategory: selectedCategoryId.flatMap(store.category(for:)),
                        items: searchedItems,
                        allItems: store.master.itemDictionary,
                        categoryProvider: store.category(for:),
                        clearSearch: clearSearch
                    )
                }
            }
            .navigationTitle("ごみ検索")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.header, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func clearSearch() {
        query = ""
        selectedCategoryId = nil
    }
}

private struct SimpleSearchHeader: View {
    @Binding var query: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text("分別方法を知りたい品目名を入力してください。")
                .font(.title3.weight(.bold))
                .foregroundStyle(AppColor.text)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: AppIcon.search)
                    .foregroundStyle(AppColor.secondaryText)
                TextField("例: フライパン、ペット、PET", text: $query)
                    .font(AppTypography.body)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
                if !query.isEmpty {
                    Button {
                        query = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(AppColor.tertiaryText)
                    }
                    .accessibilityLabel("検索語を消去")
                }
            }
            .padding(AppSpacing.md)
            .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                    .stroke(AppColor.separator, lineWidth: 1)
            )
            .minimumTapTarget()
        }
        .appCard()
    }
}

private struct SimpleCategoryFilter: View {
    let categories: [WasteCategory]
    @Binding var selectedCategoryId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("カテゴリで絞り込み")
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColor.text)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    CategoryFilterChip(title: "すべて", color: AppColor.appTint, isSelected: selectedCategoryId == nil) {
                        selectedCategoryId = nil
                    }
                    ForEach(categories) { category in
                        CategoryFilterChip(title: category.shortName, color: AppColor.category(category), isSelected: selectedCategoryId == category.id) {
                            selectedCategoryId = category.id
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct SearchEmptyInstruction: View {
    let examples: [String]
    let setQuery: (String) -> Void

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.lg) {
            Image(systemName: "magnifyingglass.circle")
                .font(.system(size: 72, weight: .regular))
                .foregroundStyle(AppColor.appTint)
                .accessibilityHidden(true)

            VStack(spacing: AppSpacing.sm) {
                Text("品目名を入力してください")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppColor.text)
                Text("ひらがな、カタカナ、略語でも検索できます。")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.secondaryText)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("よく探す例")
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColor.text)
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: AppSpacing.sm)], alignment: .leading, spacing: AppSpacing.sm) {
                    ForEach(examples, id: \.self) { example in
                        Button(example) {
                            setQuery(example)
                        }
                        .font(AppTypography.callout.weight(.semibold))
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .frame(maxWidth: .infinity)
                        .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                                .stroke(AppColor.separator, lineWidth: 1)
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.xl)
        .appCard()
        .accessibilityElement(children: .contain)
    }
}

private struct SimpleSearchResultsSection: View {
    let query: String
    let selectedCategory: WasteCategory?
    let items: [WasteItem]
    let allItems: [WasteItem]
    let categoryProvider: (String) -> WasteCategory?
    let clearSearch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("検索結果", subtitle: resultSubtitle, systemImage: "list.bullet")

            if items.isEmpty {
                AppStateView(
                    kind: .empty,
                    title: "該当する品目が見つかりません",
                    message: "短い名前や別の表記でも試してください。迷う場合は門真市公式情報も確認してください。",
                    actionTitle: "検索条件をクリア",
                    action: clearSearch
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(displayedItems.enumerated()), id: \.element.id) { index, item in
                        NavigationLink {
                            WasteItemDetailView(
                                item: item,
                                category: categoryProvider(item.categoryId),
                                relatedItems: relatedItems(for: item)
                            )
                        } label: {
                            SimpleWasteItemResultRow(item: item, category: categoryProvider(item.categoryId))
                        }
                        .buttonStyle(.plain)

                        if index < displayedItems.count - 1 {
                            Divider().padding(.leading, 66)
                        }
                    }
                }
                .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                        .stroke(AppColor.separator, lineWidth: 0.8)
                )
            }
        }
    }

    private var resultSubtitle: String {
        "\(selectedCategory?.name ?? "全カテゴリ")で\(items.count)件"
    }

    private var displayedItems: [WasteItem] {
        Array(items.prefix(40))
    }

    private func relatedItems(for item: WasteItem) -> [WasteItem] {
        allItems
            .filter { $0.categoryId == item.categoryId && $0.id != item.id }
            .prefix(8)
            .map { $0 }
    }
}

private struct SimpleWasteItemResultRow: View {
    let item: WasteItem
    let category: WasteCategory?

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            WasteSymbol(category: category, size: 46)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(item.primaryName)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColor.text)
                if let category {
                    Text(category.name)
                        .font(AppTypography.callout.weight(.semibold))
                        .foregroundStyle(AppColor.category(category))
                }
                Text(item.disposalGuide ?? item.notes)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColor.secondaryText)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.xs) { statusBadges }
                    VStack(alignment: .leading, spacing: AppSpacing.xs) { statusBadges }
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColor.tertiaryText)
        }
        .padding(AppSpacing.md)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityHint("詳しい出し方を開きます。")
    }

    @ViewBuilder
    private var statusBadges: some View {
        if item.hazardFlag {
            AppBadge("注意", color: AppColor.error, systemImage: AppIcon.warning)
        }
        if item.oversizedFlag {
            AppBadge("粗大候補", color: AppColor.warning, systemImage: AppIcon.bulky)
        }
        if item.needsOfficialCheck {
            AppBadge("公式確認", color: AppColor.official, systemImage: AppIcon.official)
        }
    }
}

#Preview("Search Simple Default") {
    SearchView()
        .environmentObject(MasterStore())
}

#Preview("Search Simple Result") {
    SearchView(initialQuery: "ペットボトル")
        .environmentObject(MasterStore())
        .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Search Simple Hazard Item") {
    SearchView(initialQuery: "スプレー缶")
        .environmentObject(MasterStore())
        .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Search Simple Dynamic Type Large") {
    SearchView(initialQuery: "段ボール")
        .environmentObject(MasterStore())
        .environment(\.dynamicTypeSize, .accessibility2)
        .previewLayout(.fixed(width: 393, height: 852))
}
