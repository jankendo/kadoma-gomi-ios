import SwiftUI

struct WasteGuideView: View {
    @EnvironmentObject private var store: MasterStore

    private var householdCategories: [WasteCategory] {
        categoryIds(["burnable", "plastic_container", "bottles_cans", "paper_cloth", "small_items", "pet_bottle"])
    }

    private var specialCategories: [WasteCategory] {
        categoryIds(["bulky", "hazardous_note", "recycle_law"])
    }

    var body: some View {
        NavigationStack {
            AppScreen {
                WasteGuideHeader()
                WasteGuideGridSection(
                    title: "家庭ごみ",
                    subtitle: "収集日に出す主な分別です",
                    categories: householdCategories,
                    items: store.master.itemDictionary
                )
                WasteGuideGridSection(
                    title: "申込・確認が必要なもの",
                    subtitle: "予約や公式確認が必要な品目です",
                    categories: specialCategories,
                    items: store.master.itemDictionary
                )
            }
            .navigationTitle("ごみ分別")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.header, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func categoryIds(_ ids: [String]) -> [WasteCategory] {
        ids.compactMap { id in
            store.master.categories.first { $0.id == id }
        }
    }
}

private struct WasteGuideHeader: View {
    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: AppIcon.guide)
                .font(.title2.weight(.semibold))
                .frame(width: 52, height: 52)
                .background(AppColor.backgroundTop, in: Circle())
                .foregroundStyle(AppColor.appTint)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("種類から調べる")
                    .font(AppTypography.heroTitle)
                    .foregroundStyle(AppColor.text)
                Text("ごみの種類を選ぶと、出し方・代表品目・注意点を確認できます。")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .appCard()
    }
}

private struct WasteGuideGridSection: View {
    let title: String
    let subtitle: String
    let categories: [WasteCategory]
    let items: [WasteItem]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            Text(title)
                .font(AppTypography.sectionTitle)
                .foregroundStyle(AppColor.text)
            Text(subtitle)
                .font(AppTypography.callout)
                .foregroundStyle(AppColor.secondaryText)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.md) {
                ForEach(categories) { category in
                    NavigationLink {
                        WasteCategoryDetailView(
                            category: category,
                            items: items.filter { $0.categoryId == category.id }
                        )
                    } label: {
                        WasteCategoryGuideCard(
                            category: category,
                            itemCount: items.filter { $0.categoryId == category.id }.count
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, AppSpacing.sm)
    }
}

struct WasteGuideOverviewSection: View {
    let categories: [WasteCategory]
    let items: [WasteItem]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("分別ガイド", subtitle: "種類ごとの出し方を確認できます", systemImage: AppIcon.guide)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: AppSpacing.sm)], alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(categories) { category in
                    NavigationLink {
                        WasteCategoryDetailView(
                            category: category,
                            items: items.filter { $0.categoryId == category.id }
                        )
                    } label: {
                        WasteCategoryGuideCard(category: category, itemCount: items.filter { $0.categoryId == category.id }.count)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

struct WasteCategoryDetailView: View {
    let category: WasteCategory
    let items: [WasteItem]
    @Environment(\.openURL) private var openURL

    var body: some View {
        AppScreen {
            CategoryHeroCard(category: category)
            DisposalStepsList(steps: category.guideSteps, tint: AppColor.category(category))
            CategoryExamplesView(category: category)
            CategoryWarningSection(category: category)
            CategoryItemList(category: category, items: items)
            GuideSourceLink(title: category.sourceTitle ?? "門真市公式情報", urlText: category.sourceUrl)
        }
        .navigationTitle(category.guideDisplayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColor.header, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct WasteItemDetailView: View {
    let item: WasteItem
    let category: WasteCategory?
    let relatedItems: [WasteItem]

    var body: some View {
        AppScreen {
            ItemHeroCard(item: item, category: category)
            DisposalStepsList(steps: item.detailSteps.isEmpty ? category?.guideSteps ?? [] : item.detailSteps, tint: AppColor.category(category))
            ItemPreparationChecklist(item: item)
            ItemWarningSection(item: item, category: category)
            RelatedItemsSection(category: category, items: relatedItems)
            GuideSourceLink(title: item.sourceTitleText, urlText: item.sourceUrl ?? category?.sourceUrl)
        }
        .navigationTitle(item.primaryName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(AppColor.header, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

struct WasteCategoryGuideCard: View {
    let category: WasteCategory
    let itemCount: Int

    var body: some View {
        VStack(alignment: .center, spacing: AppSpacing.sm) {
            WasteSymbol(category: category, size: 72)
            Text(category.guideDisplayName)
                .font(AppTypography.cardTitle)
                .foregroundStyle(AppColor.text)
                .multilineTextAlignment(.center)
                .lineLimit(2)
            Text(category.guideSummary)
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
            Text("\(itemCount)品目")
                .font(AppTypography.badge)
                .foregroundStyle(AppColor.secondaryText)
        }
        .padding(AppSpacing.lg)
        .frame(maxWidth: .infinity, minHeight: 178, alignment: .top)
        .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(AppColor.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityHint("カテゴリの詳しい出し方を開きます。")
    }
}

struct CategoryHeroCard: View {
    let category: WasteCategory

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                WasteSymbol(category: category, size: 62)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(category.guideDisplayName)
                        .font(AppTypography.heroTitle)
                    Text(category.guideDescription)
                        .font(AppTypography.callout.weight(.semibold))
                        .foregroundStyle(AppColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            Text(category.guideSummary)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.text)
                .fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.sm) { categoryBadges }
                VStack(alignment: .leading, spacing: AppSpacing.xs) { categoryBadges }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(AppColor.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var categoryBadges: some View {
        AppBadge(category.collectionMethod ?? "収集方法を確認", color: AppColor.category(category), systemImage: AppIcon.bag)
        if category.reservationRequired {
            AppBadge("要予約", color: AppColor.warning, systemImage: AppIcon.reserve)
        }
        if category.categoryNeedsOfficialCheck {
            AppBadge("公式確認推奨", color: AppColor.official, systemImage: AppIcon.official)
        }
    }
}

struct DisposalStepsList: View {
    let steps: [String]
    let tint: Color

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("出す前にやること", subtitle: "迷わないよう順番に確認できます", systemImage: AppIcon.steps)
            if steps.isEmpty {
                AppStateView(kind: .empty, title: "手順は準備中です", message: "この品目は公式情報の確認が必要です。カテゴリ説明と公式ページを確認してください。")
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        DisposalStepRow(number: index + 1, text: step, tint: tint)
                    }
                }
            }
        }
    }
}

struct DisposalStepRow: View {
    let number: Int
    let text: String
    let tint: Color

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            ZStack {
                Circle().fill(tint)
                Text("\(number)")
                    .font(AppTypography.badge)
                    .foregroundStyle(.white)
            }
            .frame(width: 32, height: 32)
            .accessibilityHidden(true)

            Image(systemName: actionIcon(for: text))
                .font(.headline.weight(.bold))
                .frame(width: 34, height: 34)
                .background(AppColor.backgroundTop, in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                .foregroundStyle(tint)
                .accessibilityHidden(true)

            Text(text)
                .font(AppTypography.body)
                .foregroundStyle(AppColor.text)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(tint.opacity(0.16), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(number)番、\(text)")
    }

    private func actionIcon(for text: String) -> String {
        if text.contains("洗") || text.contains("すす") || text.contains("水") {
            return AppIcon.rinse
        }
        if text.contains("外") || text.contains("はが") || text.contains("ふた") || text.contains("ラベル") {
            return AppIcon.remove
        }
        if text.contains("しば") || text.contains("束") {
            return AppIcon.bundle
        }
        if text.contains("予約") || text.contains("申し込") {
            return AppIcon.reserve
        }
        if text.contains("分け") || text.contains("種類") {
            return AppIcon.separate
        }
        if text.contains("確認") {
            return AppIcon.officialCheck
        }
        return AppIcon.success
    }
}

struct CategoryExamplesView: View {
    let category: WasteCategory

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("代表例", subtitle: "この種類でよく出るもの", systemImage: AppIcon.examples)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: AppSpacing.sm)], alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(category.guideExamples, id: \.self) { example in
                    AppBadge(example, color: AppColor.category(category), systemImage: category.guideIconName)
                }
            }
        }
        .appCard()
    }
}

private struct CategoryWarningSection: View {
    let category: WasteCategory

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("注意点", subtitle: "出す前にここだけ確認", systemImage: AppIcon.warning)
            ForEach(category.guideWarnings, id: \.self) { warning in
                GuideWarningBox(text: warning, color: category.categoryNeedsOfficialCheck ? AppColor.official : AppColor.warning)
            }
        }
    }
}

private struct CategoryItemList: View {
    let category: WasteCategory
    let items: [WasteItem]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("このカテゴリの品目", subtitle: "\(items.count)件から代表的なものを表示", systemImage: "list.bullet")
            if items.isEmpty {
                AppStateView(kind: .empty, title: "品目データがありません", message: "カテゴリ説明を確認し、迷う場合は公式情報をご確認ください。")
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(items.prefix(20)) { item in
                        NavigationLink {
                            WasteItemDetailView(
                                item: item,
                                category: category,
                                relatedItems: items.filter { $0.id != item.id }
                            )
                        } label: {
                            CompactWasteItemRow(item: item, category: category)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

private struct CompactWasteItemRow: View {
    let item: WasteItem
    let category: WasteCategory

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            WasteSymbol(category: category, size: 38)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(item.primaryName)
                    .font(AppTypography.cardTitle)
                    .foregroundStyle(AppColor.text)
                Text(item.disposalGuide ?? item.notes)
                    .font(AppTypography.footnote)
                    .foregroundStyle(AppColor.secondaryText)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(AppColor.tertiaryText)
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(AppColor.category(category).opacity(0.14), lineWidth: 1)
        )
    }
}

private struct ItemHeroCard: View {
    let item: WasteItem
    let category: WasteCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                WasteSymbol(category: category, size: 62)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(item.primaryName)
                        .font(AppTypography.heroTitle)
                    if let kana = item.kana {
                        Text(kana)
                            .font(AppTypography.callout.weight(.semibold))
                            .foregroundStyle(AppColor.secondaryText)
                    }
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

            ViewThatFits(in: .horizontal) {
                HStack(spacing: AppSpacing.sm) { itemBadges }
                VStack(alignment: .leading, spacing: AppSpacing.xs) { itemBadges }
            }
        }
        .padding(AppSpacing.lg)
        .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(AppColor.separator, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var itemBadges: some View {
        if item.hazardFlag {
            AppBadge("注意品目", color: AppColor.error, systemImage: AppIcon.warning)
        }
        if item.oversizedFlag {
            AppBadge("粗大候補", color: AppColor.warning, systemImage: AppIcon.bulky)
        }
        if item.reservationRequired {
            AppBadge("予約確認", color: AppColor.warning, systemImage: AppIcon.reserve)
        }
        if item.needsOfficialCheck {
            AppBadge("公式確認推奨", color: AppColor.official, systemImage: AppIcon.official)
        }
    }
}

private struct ItemPreparationChecklist: View {
    let item: WasteItem

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("分別チェック", subtitle: "この品目で迷いやすいポイント", systemImage: "checkmark.seal.fill")
            VStack(spacing: AppSpacing.sm) {
                if let preparation = item.preparationBeforeDisposal {
                    ChecklistLine(title: "出し方の要点", value: preparation, icon: AppIcon.info)
                }
                if let sizeRule = item.sizeRule, !sizeRule.isEmpty {
                    ChecklistLine(title: "サイズ", value: sizeRule, icon: "ruler.fill")
                }
                if let bundleRule = item.bundleRule, !bundleRule.isEmpty {
                    ChecklistLine(title: "まとめ方", value: bundleRule, icon: AppIcon.bundle)
                }
                if item.washingRequired == true {
                    ChecklistLine(title: "洗う", value: "中身を出し、軽く水洗いしてください。", icon: AppIcon.rinse)
                }
                if item.removeCapsLabels == true {
                    ChecklistLine(title: "外す", value: "キャップ・ラベル・ふたなどは外して分けます。", icon: AppIcon.remove)
                }
                if item.drainContents == true {
                    ChecklistLine(title: "中身", value: "中身を使い切る、または水分を切ってから出します。", icon: "drop.triangle.fill")
                }
                if item.separateMaterials == true {
                    ChecklistLine(title: "分ける", value: "素材や危険性が異なるものは分けて確認します。", icon: AppIcon.separate)
                }
            }
        }
    }
}

private struct ChecklistLine: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: icon)
                .font(.headline.weight(.bold))
                .frame(width: 36, height: 36)
                .background(AppColor.softMint, in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                .foregroundStyle(AppColor.appTint)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(title)
                    .font(AppTypography.badge)
                    .foregroundStyle(AppColor.secondaryText)
                Text(value)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColor.text)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(AppColor.separator.opacity(0.55), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

private struct ItemWarningSection: View {
    let item: WasteItem
    let category: WasteCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("注意と確認", subtitle: "間違えやすいところ", systemImage: AppIcon.warning)
            if item.warnings?.isEmpty == false {
                ForEach(item.warnings ?? [], id: \.self) { warning in
                    GuideWarningBox(text: warning, color: item.hazardFlag ? AppColor.error : AppColor.warning)
                }
            }
            ForEach(category?.guideWarnings.prefix(2).map { $0 } ?? [], id: \.self) { warning in
                GuideWarningBox(text: warning, color: AppColor.warning)
            }
            if item.needsOfficialCheck {
                GuideWarningBox(text: "この品目は条件で分別が変わる可能性があります。最終判断は門真市公式情報を確認してください。", color: AppColor.official)
            }
        }
    }
}

private struct GuideWarningBox: View {
    let text: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.sm) {
            Image(systemName: AppIcon.warning)
                .foregroundStyle(color)
            Text(text)
                .font(AppTypography.callout.weight(.semibold))
                .foregroundStyle(AppColor.text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AppSpacing.md)
        .background(color.opacity(0.11), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(color.opacity(0.18), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
    }
}

private struct RelatedItemsSection: View {
    let category: WasteCategory?
    let items: [WasteItem]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("似た品目", subtitle: "同じカテゴリで確認できます", systemImage: "sparkles")
            if items.isEmpty {
                AppStateView(kind: .empty, title: "関連品目はありません", message: "検索画面から別の言葉でも探せます。")
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(items.prefix(6)) { item in
                        CompactWasteItemRow(item: item, category: category ?? fallbackCategory(for: item))
                    }
                }
            }
        }
    }

    private func fallbackCategory(for item: WasteItem) -> WasteCategory {
        WasteCategory(
            id: item.categoryId,
            name: item.categoryId,
            shortName: item.categoryId,
            symbolName: AppIcon.bag,
            colorHex: "#0A8F8A",
            disposalRule: item.disposalGuide ?? item.notes,
            notes: [],
            defaultPreviousNightNotification: false,
            defaultMorningNotification: false
        )
    }
}

private struct GuideSourceLink: View {
    let title: String
    let urlText: String?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            AppSectionHeader("公式情報", subtitle: "最終確認はこちら", systemImage: AppIcon.official)
            if let urlText, let url = URL(string: urlText) {
                Link(destination: url) {
                    HStack {
                        VStack(alignment: .leading, spacing: AppSpacing.xs) {
                            Text(title)
                                .font(AppTypography.cardTitle)
                                .foregroundStyle(AppColor.text)
                            Text(urlText)
                                .font(AppTypography.footnote)
                                .foregroundStyle(AppColor.secondaryText)
                                .lineLimit(2)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.up.right.square")
                            .foregroundStyle(AppColor.appTint)
                    }
                    .minimumTapTarget()
                }
            } else {
                AppStateView(kind: .empty, title: "公式リンク未設定", message: "この品目は公式確認が必要です。門真市公式サイトで最新情報をご確認ください。")
            }
        }
        .appCard()
    }
}

#Preview("Category Simple Grid") {
    WasteGuideView()
        .environmentObject(MasterStore())
        .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Category Simple Detail") {
    let store = MasterStore()
    NavigationStack {
        WasteCategoryDetailView(
            category: store.master.categories[0],
            items: store.master.itemDictionary.filter { $0.categoryId == store.master.categories[0].id }
        )
    }
}

#Preview("Item Detail Hazard") {
    let store = MasterStore()
    let item = store.master.itemDictionary.first { $0.primaryName.contains("スプレー") } ?? store.master.itemDictionary[0]
    NavigationStack {
        WasteItemDetailView(
            item: item,
            category: store.category(for: item.categoryId),
            relatedItems: store.master.itemDictionary.filter { $0.categoryId == item.categoryId && $0.id != item.id }
        )
    }
}
