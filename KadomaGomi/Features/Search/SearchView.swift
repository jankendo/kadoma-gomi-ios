import SwiftUI

struct SearchView: View {
    @EnvironmentObject private var store: MasterStore
    @State private var query = ""
    @State private var selectedCategoryId: String?

    init(initialQuery: String = "", initialCategoryId: String? = nil) {
        _query = State(initialValue: initialQuery)
        _selectedCategoryId = State(initialValue: initialCategoryId)
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
                SearchHeroCard(query: $query)
                SearchIntroCard()
                CategoryFilterSection(
                    categories: visibleCategories,
                    selectedCategoryId: $selectedCategoryId,
                    categoryColor: { AppColor.category($0) }
                )
                SearchResultsSection(
                    query: query,
                    selectedCategory: selectedCategoryId.flatMap(store.category(for:)),
                    items: searchedItems,
                    categoryProvider: store.category(for:),
                    clearSearch: clearSearch
                )
            }
            .navigationTitle("分別検索")
            .toolbarBackground(AppColor.backgroundTop, for: .navigationBar)
            .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .automatic), prompt: "例: フライパン、ペット、PET")
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
        }
    }

    private func clearSearch() {
        query = ""
        selectedCategoryId = nil
    }
}

private struct SearchHeroCard: View {
    @Binding var query: String
    private let examples = ["ペットボトル", "スプレー缶", "段ボール", "モバイルバッテリー"]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: AppIcon.search)
                    .font(.title2.weight(.heavy))
                    .frame(width: 54, height: 54)
                    .background(AppColor.softMint, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                    .foregroundStyle(AppColor.appTint)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("何を捨てたいですか？")
                        .font(AppTypography.heroTitle)
                    Text("ひらがな・カタカナ・略語でも探せます")
                        .font(AppTypography.callout.weight(.semibold))
                        .foregroundStyle(AppColor.secondaryText)
                }
            }

            HStack(spacing: AppSpacing.sm) {
                Image(systemName: AppIcon.search)
                    .foregroundStyle(AppColor.appTint)
                TextField("例: ペット、PET、ダンボール", text: $query)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.search)
            }
            .padding(AppSpacing.md)
            .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(AppColor.appTint.opacity(0.25), lineWidth: 1)
            )
            .minimumTapTarget()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(examples, id: \.self) { example in
                        Button(example) {
                            query = example
                        }
                        .font(AppTypography.badge)
                        .padding(.horizontal, AppSpacing.md)
                        .padding(.vertical, AppSpacing.sm)
                        .background(AppColor.appTint.opacity(0.12), in: Capsule())
                        .foregroundStyle(AppColor.appTint)
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .padding(AppSpacing.lg)
        .background(
            LinearGradient(colors: [AppColor.softBlue.opacity(0.75), AppColor.cardBackground], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .stroke(AppColor.subTint.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: AppShadow.cardColor, radius: AppShadow.floatingRadius, x: 0, y: AppShadow.floatingY)
    }
}

private struct SearchIntroCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("検索のコツ", subtitle: "正式名が分からなくても大丈夫です", systemImage: AppIcon.officialCheck)
            Text("迷いやすい品目は、カテゴリ名だけでなく出し方の注意も表示します。最終判断に迷う場合は公式情報を確認してください。")
                .font(AppTypography.callout)
                .foregroundStyle(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCard()
    }
}

private struct CategoryFilterSection: View {
    let categories: [WasteCategory]
    @Binding var selectedCategoryId: String?
    let categoryColor: (WasteCategory) -> Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("カテゴリで絞り込み", subtitle: selectedCategoryId == nil ? "すべて表示中" : "選択中のカテゴリだけ表示", systemImage: "line.3.horizontal.decrease.circle")
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    CategoryFilterChip(title: "すべて", color: AppColor.appTint, isSelected: selectedCategoryId == nil) {
                        selectedCategoryId = nil
                    }
                    ForEach(categories) { category in
                        CategoryFilterChip(title: category.shortName, color: categoryColor(category), isSelected: selectedCategoryId == category.id) {
                            selectedCategoryId = category.id
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
    }
}

private struct SearchResultsSection: View {
    let query: String
    let selectedCategory: WasteCategory?
    let items: [WasteItem]
    let categoryProvider: (String) -> WasteCategory?
    let clearSearch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader(
                query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "よく使う品目" : "検索結果",
                subtitle: resultSubtitle,
                systemImage: "list.bullet.rectangle"
            )

            if items.isEmpty {
                AppStateView(
                    kind: .empty,
                    title: "該当する品目が見つかりません",
                    message: "短い名前、ひらがな、カタカナでも試せます。例: ペット、PET、カン、ダンボール。迷う場合は公式ページで最新情報を確認してください。",
                    actionTitle: "検索条件をクリア",
                    action: clearSearch
                )
            } else {
                VStack(spacing: AppSpacing.md) {
                    ForEach(items.prefix(40)) { item in
                        WasteItemResultCard(item: item, category: categoryProvider(item.categoryId))
                    }
                }
            }
        }
    }

    private var resultSubtitle: String {
        let categoryText = selectedCategory?.name ?? "全カテゴリ"
        if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "\(categoryText)から、日常で迷いやすい品目を表示"
        }
        return "\(categoryText)で\(items.count)件"
    }
}

private struct WasteItemResultCard: View {
    let item: WasteItem
    let category: WasteCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                WasteSymbol(category: category, size: 44)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(item.primaryName)
                        .font(AppTypography.cardTitle)
                    if let category {
                        AppBadge(category.name, color: AppColor.category(category), systemImage: category.symbolName)
                    }
                }
                Spacer(minLength: 0)
            }

            Text(item.disposalGuide ?? item.notes)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.text)
                .fixedSize(horizontal: false, vertical: true)

            if item.hazardFlag || item.oversizedFlag || item.needsOfficialCheck {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: AppSpacing.sm) {
                        statusBadges
                    }
                    VStack(alignment: .leading, spacing: AppSpacing.xs) {
                        statusBadges
                    }
                }
            }

            if let category {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("出し方")
                        .font(AppTypography.badge)
                        .foregroundStyle(AppColor.secondaryText)
                    Text(category.disposalRule)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            if let firstWarning = item.warnings?.first {
                Text(firstWarning)
                    .font(AppTypography.callout.weight(.semibold))
                    .foregroundStyle(item.hazardFlag ? AppColor.error : AppColor.warning)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !item.searchAliases.isEmpty {
                Text("関連: \(item.searchAliases.prefix(6).joined(separator: " / "))")
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.tertiaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

        }
        .padding(AppSpacing.lg)
        .background(
            LinearGradient(colors: [AppColor.cardBackground, AppColor.categoryBackground(category).opacity(0.65)], startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.xl, style: .continuous)
                .stroke(AppColor.category(category).opacity(0.22), lineWidth: 1)
        )
        .shadow(color: AppColor.category(category).opacity(0.10), radius: 14, x: 0, y: 6)
        .accessibilityElement(children: .combine)
        .accessibilityHint("品目のカテゴリ、出し方、注意を確認できます。")
    }

    @ViewBuilder
    private var statusBadges: some View {
        if item.hazardFlag {
            AppBadge("注意品目", color: AppColor.error, systemImage: AppIcon.warning)
        }
        if item.oversizedFlag {
            AppBadge("粗大候補", color: AppColor.warning, systemImage: AppIcon.bulky)
        }
        if item.needsOfficialCheck {
            AppBadge("公式確認推奨", color: AppColor.official, systemImage: AppIcon.official)
        }
    }
}

#Preview {
    SearchView()
        .environmentObject(MasterStore())
}

#Preview("Search Light Dynamic Type") {
    SearchView()
        .environmentObject(MasterStore())
        .environment(\.dynamicTypeSize, .accessibility2)
        .previewLayout(.fixed(width: 430, height: 932))
}

#Preview("Search Hazard Result") {
    SearchView(initialQuery: "スプレー缶")
        .environmentObject(MasterStore())
        .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Search No Result") {
    SearchView(initialQuery: "これは存在しない品目")
        .environmentObject(MasterStore())
        .previewLayout(.fixed(width: 393, height: 852))
}
