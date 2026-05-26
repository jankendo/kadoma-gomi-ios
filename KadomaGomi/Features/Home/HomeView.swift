import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: MasterStore

    let openSearch: () -> Void
    let openGuide: () -> Void
    let openCalendar: () -> Void
    let openSettings: () -> Void
    let referenceDate: Date

    private var summary: AreaCollectionSummary {
        store.collectionSummary(referenceDate: referenceDate, nextLimit: 7)
    }

    private var weekDays: [Date] {
        let start = Calendar.kadoma.startOfDay(for: referenceDate)
        return (0..<7).compactMap { Calendar.kadoma.date(byAdding: .day, value: $0, to: start) }
    }

    init(
        openSearch: @escaping () -> Void,
        openGuide: @escaping () -> Void,
        openCalendar: @escaping () -> Void,
        openSettings: @escaping () -> Void,
        referenceDate: Date = .now
    ) {
        self.openSearch = openSearch
        self.openGuide = openGuide
        self.openCalendar = openCalendar
        self.openSettings = openSettings
        self.referenceDate = referenceDate
    }

    var body: some View {
        NavigationStack {
            AppScreen {
                HomeDistrictBand(
                    address: summary.addressText,
                    areaName: summary.areaName,
                    sourceUpdatedAt: summary.sourceUpdatedAt,
                    openSettings: openSettings
                )

                TodayCollectionSummaryCard(
                    summary: summary,
                    categoryProvider: store.category(for:),
                    openGuide: openGuide,
                    openSearch: openSearch
                )

                WeeklyCollectionList(
                    days: weekDays,
                    eventsProvider: store.events(on:),
                    categoryProvider: store.category(for:)
                )

                HomeQuickLinks(
                    openSearch: openSearch,
                    openGuide: openGuide,
                    openCalendar: openCalendar,
                    openSettings: openSettings
                )

                YearEndNoticeSection(notices: summary.dataNotices)
                DataStatusSection(store: store)
            }
            .navigationTitle("門真市ごみアプリ")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.header, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: openSettings) {
                        Image(systemName: AppIcon.info)
                    }
                    .accessibilityLabel("アプリ情報と設定を開く")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: openSettings) {
                        Image(systemName: AppIcon.update)
                    }
                    .accessibilityLabel("データ更新設定を開く")
                }
            }
        }
    }
}

private struct HomeDistrictBand: View {
    let address: String
    let areaName: String
    let sourceUpdatedAt: String
    let openSettings: () -> Void

    var body: some View {
        Button(action: openSettings) {
            HStack(alignment: .center, spacing: AppSpacing.md) {
                Image(systemName: AppIcon.district)
                    .font(.title2.weight(.semibold))
                    .frame(width: 54, height: 54)
                    .background(.white.opacity(0.75), in: Circle())
                    .foregroundStyle(AppColor.appTint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("今週のあなたの地区の収集日")
                        .font(AppTypography.sectionTitle)
                        .foregroundStyle(AppColor.secondaryText)
                    Text("門真市 \(address) / \(areaName)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppColor.text)
                        .lineLimit(2)
                    Text("公式更新 \(sourceUpdatedAt)")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.secondaryText)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(AppColor.tertiaryText)
            }
            .padding(AppSpacing.lg)
            .background(AppColor.backgroundTop, in: RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityHint("地区設定を確認または変更できます。")
    }
}

private struct TodayCollectionSummaryCard: View {
    let summary: AreaCollectionSummary
    let categoryProvider: (String) -> WasteCategory?
    let openGuide: () -> Void
    let openSearch: () -> Void

    private var targetEvents: [CollectionEvent] {
        if summary.today.hasCollection {
            return summary.today.events
        }
        return Array(summary.nextEvents.prefix(1))
    }

    private var headline: String {
        if summary.today.hasCollection {
            return "今日は\(eventNames)の日"
        }
        return "今日は収集予定なし"
    }

    private var eventNames: String {
        summary.today.events
            .compactMap { categoryProvider($0.categoryId)?.shortName }
            .joined(separator: "・")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: summary.today.hasCollection ? AppIcon.today : "checkmark.seal.fill")
                    .font(.title2.weight(.bold))
                    .frame(width: 48, height: 48)
                    .background(summary.today.hasCollection ? AppColor.softYellow : AppColor.softMint, in: Circle())
                    .foregroundStyle(summary.today.hasCollection ? AppColor.accent : AppColor.success)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("今日")
                        .font(AppTypography.badge)
                        .foregroundStyle(AppColor.secondaryText)
                    Text(headline)
                        .font(AppTypography.heroTitle)
                        .foregroundStyle(AppColor.text)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(KadomaDateFormatter.displayDay.string(from: summary.today.date))
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.secondaryText)
                }
                Spacer(minLength: 0)
            }

            if targetEvents.isEmpty {
                Text("次の収集予定は、下の一覧またはカレンダーで確認できます。")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.secondaryText)
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(targetEvents.prefix(2)) { event in
                        if let category = categoryProvider(event.categoryId) {
                            TodayCategoryGuideRow(category: category, showsDate: !summary.today.hasCollection, date: event.date)
                        }
                    }
                }
            }

            HStack(spacing: AppSpacing.sm) {
                Button(action: openGuide) {
                    Label("分別を見る", systemImage: AppIcon.guide)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(AppColor.appTint)

                Button(action: openSearch) {
                    Label("検索", systemImage: AppIcon.search)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
        .appCard()
        .accessibilityElement(children: .combine)
        .accessibilityHint("今日の収集予定と出し方の要点です。")
    }
}

private struct TodayCategoryGuideRow: View {
    let category: WasteCategory
    let showsDate: Bool
    let date: Date

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            WasteSymbol(category: category, size: 44)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                HStack(spacing: AppSpacing.sm) {
                    Text(category.name)
                        .font(AppTypography.cardTitle)
                    if category.reservationRequired {
                        AppBadge("要予約", color: AppColor.warning, systemImage: AppIcon.reserve)
                    }
                }
                if showsDate {
                    Text("次回: \(KadomaDateFormatter.displayDay.string(from: date))")
                        .font(AppTypography.footnote)
                        .foregroundStyle(AppColor.secondaryText)
                }
                Text(category.guideSummary)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                if let firstStep = category.guideSteps.first {
                    Text("まず: \(firstStep)")
                        .font(AppTypography.callout.weight(.semibold))
                        .foregroundStyle(AppColor.text)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(AppSpacing.md)
        .background(AppColor.elevatedCardBackground, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous)
                .stroke(AppColor.separator, lineWidth: 0.8)
        )
    }
}

private struct WeeklyCollectionList: View {
    let days: [Date]
    let eventsProvider: (Date) -> [CollectionEvent]
    let categoryProvider: (String) -> WasteCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("直近7日間", subtitle: "日付ごとに収集予定を確認できます", systemImage: AppIcon.calendar)
            VStack(spacing: 0) {
                ForEach(Array(days.enumerated()), id: \.element) { index, day in
                    WeeklyCollectionRow(
                        date: day,
                        events: eventsProvider(day),
                        categoryProvider: categoryProvider
                    )
                    if index < days.count - 1 {
                        Divider().padding(.leading, 92)
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

private struct WeeklyCollectionRow: View {
    let date: Date
    let events: [CollectionEvent]
    let categoryProvider: (String) -> WasteCategory?

    private var isToday: Bool {
        Calendar.kadoma.isDateInToday(date)
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            VStack(alignment: .leading, spacing: 2) {
                Text(KadomaDateFormatter.displayDay.string(from: date))
                    .font(.title3.weight(.bold))
                    .foregroundStyle(isToday ? AppColor.appTint : AppColor.text)
                if isToday {
                    Text("今日")
                        .font(AppTypography.badge)
                        .foregroundStyle(AppColor.appTint)
                }
            }
            .frame(width: 84, alignment: .leading)

            if events.isEmpty {
                Text("収集なし")
                    .font(AppTypography.body)
                    .foregroundStyle(AppColor.tertiaryText)
                Spacer(minLength: 0)
            } else {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    ForEach(events) { event in
                        if let category = categoryProvider(event.categoryId) {
                            HStack(spacing: AppSpacing.sm) {
                                Image(systemName: category.symbolName)
                                    .font(.headline.weight(.semibold))
                                    .frame(width: 28, height: 28)
                                    .foregroundStyle(AppColor.category(category))
                                    .accessibilityHidden(true)
                                Text(category.name)
                                    .font(.title3.weight(.bold))
                                    .foregroundStyle(AppColor.category(category))
                                if event.requiresReservation {
                                    AppBadge("要予約", color: AppColor.warning, systemImage: AppIcon.reserve)
                                }
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .accessibilityElement(children: .combine)
    }
}

private struct HomeQuickLinks: View {
    let openSearch: () -> Void
    let openGuide: () -> Void
    let openCalendar: () -> Void
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("よく使う機能", systemImage: "square.grid.2x2")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: AppSpacing.sm) {
                QuickActionCard(title: "ごみ検索", subtitle: "品目名で探す", systemImage: AppIcon.search, color: AppColor.appTint, action: openSearch)
                QuickActionCard(title: "ごみ分別", subtitle: "種類から確認", systemImage: AppIcon.guide, color: AppColor.subTint, action: openGuide)
                QuickActionCard(title: "カレンダー", subtitle: "月表示を見る", systemImage: AppIcon.calendar, color: AppColor.official, action: openCalendar)
                QuickActionCard(title: "地区・通知", subtitle: "設定を確認", systemImage: AppIcon.settings, color: AppColor.warning, action: openSettings)
            }
        }
    }
}

private struct YearEndNoticeSection: View {
    let notices: [Notice]

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: AppIcon.warning)
                .foregroundStyle(AppColor.warning)
            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text("年末年始は公式情報も確認")
                    .font(AppTypography.cardTitle)
                Text(noticeText)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(AppSpacing.md)
        .background(AppColor.softYellow, in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
        .accessibilityElement(children: .combine)
    }

    private var noticeText: String {
        notices.first?.body ?? "12月・1月は通常ルールから変わる場合があります。確定情報は門真市公式ページで確認してください。"
    }
}

private struct DataStatusSection: View {
    @ObservedObject var store: MasterStore

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            Text("データ")
                .font(AppTypography.badge)
                .foregroundStyle(AppColor.secondaryText)
            Text("マスタ \(store.master.version) / 公式更新 \(store.master.sourceUpdatedAt)")
                .font(AppTypography.footnote)
                .foregroundStyle(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, AppSpacing.sm)
    }
}

#Preview("Home Simple Default") {
    HomeView(openSearch: {}, openGuide: {}, openCalendar: {}, openSettings: {})
        .environmentObject(MasterStore())
}

#Preview("Home Simple iPhone SE") {
    HomeView(openSearch: {}, openGuide: {}, openCalendar: {}, openSettings: {})
        .environmentObject(MasterStore())
        .previewLayout(.fixed(width: 320, height: 568))
}

#Preview("Home Simple Dynamic Type Large") {
    HomeView(openSearch: {}, openGuide: {}, openCalendar: {}, openSettings: {})
        .environmentObject(MasterStore())
        .environment(\.dynamicTypeSize, .accessibility2)
        .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Home Simple Year End Notice") {
    HomeView(
        openSearch: {},
        openGuide: {},
        openCalendar: {},
        openSettings: {},
        referenceDate: Calendar.kadoma.date(from: DateComponents(year: 2026, month: 12, day: 15)) ?? .now
    )
    .environmentObject(MasterStore())
    .previewLayout(.fixed(width: 393, height: 852))
}
