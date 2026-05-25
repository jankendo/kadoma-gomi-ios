import SwiftUI

struct HomeTodayWasteGuideCard: View {
    let summary: AreaCollectionSummary
    let categories: [WasteCategory]
    let items: [WasteItem]
    let openSearch: () -> Void

    private var guideEvents: [CollectionEvent] {
        if !summary.today.events.isEmpty {
            return summary.today.events
        }
        if !summary.tomorrow.events.isEmpty {
            return summary.tomorrow.events
        }
        return Array(summary.nextEvents.prefix(1))
    }

    private var title: String {
        if !summary.today.events.isEmpty {
            return "今日の出し方"
        }
        if !summary.tomorrow.events.isEmpty {
            return "明日の準備"
        }
        return "次回に向けて確認"
    }

    private var subtitle: String {
        if !summary.today.events.isEmpty {
            return "出す前にここだけ確認"
        }
        if !summary.tomorrow.events.isEmpty {
            return "前日に準備しておくと安心です"
        }
        return "収集が近いごみの分け方です"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader(title, subtitle: subtitle, systemImage: AppIcon.guide)

            if guideEvents.isEmpty {
                AppStateView(
                    kind: .empty,
                    title: "出し方ガイドは検索から確認できます",
                    message: "今日・明日の収集予定がない日も、ごみ名で検索すると分別方法を確認できます。",
                    actionTitle: "ごみ名で検索",
                    action: openSearch
                )
            } else {
                VStack(spacing: AppSpacing.md) {
                    ForEach(guideEvents.prefix(2)) { event in
                        if let category = categories.first(where: { $0.id == event.categoryId }) {
                            HomeWasteGuideMiniCard(
                                event: event,
                                category: category,
                                examples: sampleExamples(for: category),
                                openSearch: openSearch
                            )
                        }
                    }

                    if guideEvents.count > 2 {
                        Text("ほか \(guideEvents.count - 2) 件はカレンダーまたは検索で確認できます。")
                            .font(AppTypography.footnote)
                            .foregroundStyle(AppColor.secondaryText)
                    }
                }
            }
        }
        .appCard()
    }

    private func sampleExamples(for category: WasteCategory) -> [String] {
        let itemNames = items
            .filter { $0.categoryId == category.id }
            .prefix(4)
            .map(\.primaryName)
        if !itemNames.isEmpty {
            return Array(itemNames)
        }
        return Array(category.guideExamples.prefix(4))
    }
}

private struct HomeWasteGuideMiniCard: View {
    let event: CollectionEvent
    let category: WasteCategory
    let examples: [String]
    let openSearch: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                WasteSymbol(category: category, size: 54)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("\(category.name)の収集予定です")
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColor.text)
                    Text(KadomaDateFormatter.displayDay.string(from: event.date))
                        .font(AppTypography.callout.weight(.semibold))
                        .foregroundStyle(AppColor.secondaryText)
                    Text(category.guideSummary)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }

            if !examples.isEmpty {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("代表例")
                        .font(AppTypography.badge)
                        .foregroundStyle(AppColor.secondaryText)
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: AppSpacing.xs) { exampleBadges }
                        VStack(alignment: .leading, spacing: AppSpacing.xs) { exampleBadges }
                    }
                }
            }

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("出し方")
                    .font(AppTypography.badge)
                    .foregroundStyle(AppColor.secondaryText)
                ForEach(category.guideSteps.prefix(4), id: \.self) { step in
                    HStack(alignment: .top, spacing: AppSpacing.xs) {
                        Image(systemName: AppIcon.success)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(AppColor.category(category))
                        Text(step)
                            .font(AppTypography.callout)
                            .foregroundStyle(AppColor.text)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            if let warning = category.guideWarnings.first {
                HStack(alignment: .top, spacing: AppSpacing.xs) {
                    Image(systemName: AppIcon.warning)
                        .foregroundStyle(AppColor.warning)
                    Text(warning)
                        .font(AppTypography.callout.weight(.semibold))
                        .foregroundStyle(AppColor.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(AppSpacing.md)
                .background(AppColor.warning.opacity(0.10), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
            }

            Button(action: openSearch) {
                Label("品目ごとの出し方を検索", systemImage: AppIcon.search)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .tint(AppColor.category(category))
        }
        .padding(AppSpacing.md)
        .background(AppColor.categoryBackground(category), in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                .stroke(AppColor.category(category).opacity(0.20), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityHint("今日または次回のごみの出し方です。")
    }

    @ViewBuilder
    private var exampleBadges: some View {
        ForEach(examples, id: \.self) { example in
            AppBadge(example, color: AppColor.category(category), systemImage: category.symbolName)
        }
    }
}

#Preview("Home Today Guide") {
    let store = MasterStore()
    HomeTodayWasteGuideCard(
        summary: store.collectionSummary(),
        categories: store.master.categories,
        items: store.master.itemDictionary,
        openSearch: {}
    )
    .padding()
    .background(AppColor.background)
}
