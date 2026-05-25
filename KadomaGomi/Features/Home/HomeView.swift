import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: MasterStore

    let openSearch: () -> Void
    let openCalendar: () -> Void
    let openSettings: () -> Void

    private var summary: AreaCollectionSummary {
        store.collectionSummary(nextLimit: 7)
    }

    var body: some View {
        NavigationStack {
            AppScreen {
                HomeHeaderView(
                    address: summary.addressText,
                    areaName: summary.areaName,
                    version: summary.masterVersion,
                    sourceUpdatedAt: summary.sourceUpdatedAt
                )

                CollectionEventCard(
                    title: "今日の収集予定",
                    date: summary.today.date,
                    events: summary.today.events,
                    categoryProvider: store.category(for:),
                    prominence: .primary
                )

                CollectionEventCard(
                    title: "明日の収集予定",
                    date: summary.tomorrow.date,
                    events: summary.tomorrow.events,
                    categoryProvider: store.category(for:),
                    prominence: .secondary
                )

                QuickActionGrid(
                    openSearch: openSearch,
                    openCalendar: openCalendar,
                    openSettings: openSettings
                )

                UpcomingEventsSection(events: summary.nextEvents, categoryProvider: store.category(for:))

                YearEndNoticeSection(notices: summary.dataNotices)

                DataStatusSection(store: store)
            }
            .navigationTitle("かどまごみナビ")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: openSettings) {
                        Image(systemName: AppIcon.settings)
                    }
                    .accessibilityLabel("設定を開く")
                }
            }
        }
    }
}

private struct HomeHeaderView: View {
    let address: String
    let areaName: String
    let version: String
    let sourceUpdatedAt: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: AppIcon.district)
                    .font(.title3.weight(.semibold))
                    .frame(width: 44, height: 44)
                    .background(AppColor.appTint.opacity(0.14), in: RoundedRectangle(cornerRadius: AppRadius.md, style: .continuous))
                    .foregroundStyle(AppColor.appTint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("門真市 \(address)")
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColor.text)
                    Text(areaName)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppColor.text)
                    Text("収集日の朝9時までに出してください")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.secondaryText)
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: AppSpacing.sm) {
                AppBadge("2026年度", color: AppColor.appTint)
                AppBadge("公式更新 \(sourceUpdatedAt)", color: AppColor.subTint, systemImage: AppIcon.official)
                AppBadge(version, color: AppColor.secondaryText)
            }
            .accessibilityElement(children: .combine)
        }
        .appCard()
        .accessibilityElement(children: .combine)
        .accessibilityHint("現在設定されている地区とマスタ更新日です。")
    }
}

private struct QuickActionGrid: View {
    let openSearch: () -> Void
    let openCalendar: () -> Void
    let openSettings: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("すぐ使う", subtitle: "迷ったらここから始められます", systemImage: "bolt.fill")
            QuickActionCard(
                title: "ごみ名で検索",
                subtitle: "品目名から捨て方を確認",
                systemImage: AppIcon.search,
                color: AppColor.appTint,
                action: openSearch
            )
            QuickActionCard(
                title: "月の予定を見る",
                subtitle: "収集日をカレンダーで確認",
                systemImage: AppIcon.calendar,
                color: AppColor.subTint,
                action: openCalendar
            )
            QuickActionCard(
                title: "通知と地区を確認",
                subtitle: "A-F地区・前日通知・マスタ更新",
                systemImage: AppIcon.notification,
                color: AppColor.warning,
                action: openSettings
            )
        }
    }
}

private struct UpcomingEventsSection: View {
    let events: [CollectionEvent]
    let categoryProvider: (String) -> WasteCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("次回の予定", subtitle: "直近7件を表示します", systemImage: AppIcon.calendar)
            if events.isEmpty {
                AppStateView(
                    kind: .empty,
                    title: "直近の予定がありません",
                    message: "地区設定またはマスタデータを確認してください。"
                )
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(events) { event in
                        CollectionEventRow(event: event, category: categoryProvider(event.categoryId), showsDate: true)
                    }
                }
            }
        }
    }
}

private struct YearEndNoticeSection: View {
    let notices: [Notice]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .top, spacing: AppSpacing.md) {
                Image(systemName: AppIcon.warning)
                    .font(.headline)
                    .frame(width: 36, height: 36)
                    .background(AppColor.warning.opacity(0.14), in: Circle())
                    .foregroundStyle(AppColor.warning)
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("12月・1月は公式情報を確認")
                        .font(AppTypography.cardTitle)
                    Text(noticeText)
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .appCard()
        .accessibilityElement(children: .combine)
    }

    private var noticeText: String {
        notices.first?.body ?? "年末年始は通常ルールから変更される可能性があります。アプリは例外マスタを優先しますが、最終確認は門真市公式ページで行ってください。"
    }
}

private struct DataStatusSection: View {
    @ObservedObject var store: MasterStore

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("データ更新", subtitle: "公式ページ監視とアプリ内マスタ更新に対応", systemImage: AppIcon.update)
            if store.isSyncing {
                AppStateView(kind: .loading, title: "更新を確認中", message: "manifestとmaster JSONを確認しています。")
            } else if let message = store.syncMessage {
                AppStateView(kind: message.contains("失敗") ? .error : .success, title: "更新結果", message: message)
            } else {
                Text("マスタ: \(store.master.version)\n最終公式更新日: \(store.master.sourceUpdatedAt)")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .appCard()
            }
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(MasterStore())
}

#Preview("Home iPhone SE") {
    HomeView(openSearch: {}, openCalendar: {}, openSettings: {})
        .environmentObject(MasterStore())
        .previewLayout(.fixed(width: 320, height: 568))
}

#Preview("Home Dark Large Type") {
    HomeView(openSearch: {}, openCalendar: {}, openSettings: {})
        .environmentObject(MasterStore())
        .preferredColorScheme(.dark)
        .environment(\.dynamicTypeSize, .accessibility2)
        .previewLayout(.fixed(width: 393, height: 852))
}
