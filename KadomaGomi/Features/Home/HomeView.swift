import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: MasterStore
    @State private var updateStatus: HomeMasterUpdateStatus?

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
            GeometryReader { proxy in
                let noticeHeight: CGFloat = summary.requiresOfficialReview ? 52 : 0
                let headerHeight: CGFloat = min(112, max(84, proxy.size.height * 0.18))
                let updateHeight: CGFloat = updateStatus == nil ? 0 : 44
                let rowHeight = max(50, floor((proxy.size.height - headerHeight - noticeHeight - updateHeight) / 7))

                VStack(spacing: 0) {
                    HomeAreaHeader(
                        address: summary.addressText,
                        areaName: summary.areaName,
                        openSettings: openSettings
                    )
                    .frame(height: headerHeight)

                    if let updateStatus {
                        HomeUpdateStatusBar(status: updateStatus)
                            .frame(height: updateHeight)
                    }

                    SimpleWeekCollectionList(
                        days: weekDays,
                        rowHeight: rowHeight,
                        eventsProvider: store.events(on:),
                        categoryProvider: store.category(for:),
                        itemsProvider: items(for:)
                    )

                    Spacer(minLength: 0)

                    if summary.requiresOfficialReview {
                        HomeNoticeBar(text: summary.dataNotices.first?.body ?? "年末年始は収集日が変更される場合があります。公式情報も確認してください。")
                            .frame(height: noticeHeight)
                    }
                }
                .background(Color.white)
            }
            .background(Color.white.ignoresSafeArea())
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
                    Button {
                        Task { await refreshMasterFromHome() }
                    } label: {
                        if store.isSyncing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: AppIcon.update)
                        }
                    }
                    .disabled(store.isSyncing)
                    .accessibilityLabel(store.isSyncing ? "ごみ収集データを更新中" : "ごみ収集データを更新")
                }
            }
        }
    }

    private func items(for categoryId: String) -> [WasteItem] {
        store.master.itemDictionary.filter { $0.categoryId == categoryId }
    }

    @MainActor
    private func refreshMasterFromHome() async {
        let beforeVersion = store.master.version
        updateStatus = .loading("データを更新しています...")
        await store.refreshMaster()

        let message = store.syncMessage ?? ""
        if message.contains("失敗") || message.contains("正しくありません") {
            updateStatus = .failure("データを更新できませんでした。通信状況を確認して、もう一度お試しください。")
        } else if store.master.version != beforeVersion {
            updateStatus = .success("ごみ収集データを更新しました")
        } else if message.contains("最新") {
            updateStatus = .success("すでに最新のデータです")
        } else {
            updateStatus = .success(message.isEmpty ? "ごみ収集データを確認しました" : message)
        }
    }
}

private enum HomeMasterUpdateStatus: Equatable {
    case loading(String)
    case success(String)
    case failure(String)

    var text: String {
        switch self {
        case .loading(let text), .success(let text), .failure(let text):
            return text
        }
    }

    var iconName: String {
        switch self {
        case .loading:
            return AppIcon.update
        case .success:
            return AppIcon.success
        case .failure:
            return AppIcon.error
        }
    }

    var color: Color {
        switch self {
        case .loading:
            return AppColor.appTint
        case .success:
            return AppColor.success
        case .failure:
            return AppColor.error
        }
    }
}

private struct HomeAreaHeader: View {
    let address: String
    let areaName: String
    let openSettings: () -> Void

    var body: some View {
        Button(action: openSettings) {
            HStack(alignment: .center, spacing: AppSpacing.lg) {
                Image(systemName: AppIcon.district)
                    .font(.system(size: 28, weight: .semibold))
                    .frame(width: 52, height: 52)
                    .background(Color.white.opacity(0.76), in: Circle())
                    .foregroundStyle(AppColor.appTint)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("今週のあなたの地区の収集日")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppColor.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text("門真市 \(address)")
                        .font(.title2.weight(.bold))
                        .foregroundStyle(AppColor.text)
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                    Text(areaName)
                        .font(AppTypography.cardTitle)
                        .foregroundStyle(AppColor.secondaryText)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, AppSpacing.xl)
            .padding(.vertical, AppSpacing.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColor.backgroundTop)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityHint("地区設定を確認または変更できます。")
    }
}

private struct SimpleWeekCollectionList: View {
    let days: [Date]
    let rowHeight: CGFloat
    let eventsProvider: (Date) -> [CollectionEvent]
    let categoryProvider: (String) -> WasteCategory?
    let itemsProvider: (String) -> [WasteItem]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(days.enumerated()), id: \.element) { index, day in
                SimpleWeekCollectionRow(
                    date: day,
                    events: eventsProvider(day),
                    rowHeight: rowHeight,
                    categoryProvider: categoryProvider,
                    itemsProvider: itemsProvider
                )

                if index < days.count - 1 {
                    Divider()
                        .padding(.leading, AppSpacing.xl)
                }
            }
        }
        .background(Color.white)
    }
}

private struct SimpleWeekCollectionRow: View {
    let date: Date
    let events: [CollectionEvent]
    let rowHeight: CGFloat
    let categoryProvider: (String) -> WasteCategory?
    let itemsProvider: (String) -> [WasteItem]

    private var isToday: Bool {
        Calendar.kadoma.isDateInToday(date)
    }

    private var weekday: Int {
        Calendar.kadoma.component(.weekday, from: date)
    }

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.lg) {
            Text(KadomaDateFormatter.displayDay.string(from: date))
                .font(.title2.weight(.bold))
                .foregroundStyle(dateColor)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(width: 118, alignment: .leading)

            if events.isEmpty {
                Text("収集なし")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppColor.tertiaryText)
                    .lineLimit(1)
                Spacer(minLength: 0)
            } else {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    ForEach(events) { event in
                        if let category = categoryProvider(event.categoryId) {
                            HomeCategoryLink(
                                category: category,
                                items: itemsProvider(category.id),
                                requiresReservation: event.requiresReservation
                            )
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, AppSpacing.xl)
        .frame(maxWidth: .infinity, minHeight: rowHeight, alignment: .center)
        .background(isToday ? AppColor.backgroundTop.opacity(0.55) : Color.white)
        .accessibilityElement(children: .contain)
    }

    private var dateColor: Color {
        if weekday == 1 {
            return AppColor.error
        }
        if weekday == 7 {
            return AppColor.subTint
        }
        return isToday ? AppColor.appTint : AppColor.text
    }

    private var accessibilityLabel: String {
        let dateText = KadomaDateFormatter.displayDay.string(from: date)
        guard !events.isEmpty else {
            return "\(dateText)、収集なし"
        }
        let names = events.compactMap { categoryProvider($0.categoryId)?.name }.joined(separator: "、")
        return "\(dateText)、\(names)の収集予定"
    }
}

private struct HomeCategoryLink: View {
    let category: WasteCategory
    let items: [WasteItem]
    let requiresReservation: Bool

    var body: some View {
        NavigationLink {
            WasteCategoryDetailView(category: category, items: items)
        } label: {
            HStack(spacing: AppSpacing.sm) {
                Text(category.shortName)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(AppColor.category(category))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                if requiresReservation {
                    Text("要予約")
                        .font(AppTypography.badge)
                        .foregroundStyle(AppColor.warning)
                }
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppColor.tertiaryText)
            }
            .contentShape(Rectangle())
            .frame(minHeight: 44, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.name)、詳細を開く")
    }
}

private struct HomeUpdateStatusBar: View {
    let status: HomeMasterUpdateStatus

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            if case .loading = status {
                ProgressView()
                    .scaleEffect(0.82)
            } else {
                Image(systemName: status.iconName)
                    .foregroundStyle(status.color)
                    .accessibilityHidden(true)
            }
            Text(status.text)
                .font(AppTypography.callout.weight(.semibold))
                .foregroundStyle(AppColor.text)
                .lineLimit(1)
                .minimumScaleFactor(0.82)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.lg)
        .background(status.color.opacity(0.10))
        .accessibilityElement(children: .combine)
    }
}

private struct HomeNoticeBar: View {
    let text: String

    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: AppIcon.warning)
                .foregroundStyle(AppColor.warning)
                .accessibilityHidden(true)
            Text(text)
                .font(AppTypography.callout)
                .foregroundStyle(AppColor.text)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.lg)
        .padding(.vertical, AppSpacing.md)
        .background(Color(hex: "#EFEFEF"))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Home Weekly Simple Default") {
    HomeView(openSearch: {}, openGuide: {}, openCalendar: {}, openSettings: {})
        .environmentObject(MasterStore())
}

#Preview("Home Weekly Simple Today Collection") {
    HomeView(
        openSearch: {},
        openGuide: {},
        openCalendar: {},
        openSettings: {},
        referenceDate: Calendar.kadoma.date(from: DateComponents(year: 2026, month: 5, day: 26)) ?? .now
    )
    .environmentObject(MasterStore())
}

#Preview("Home Weekly Simple No Collection") {
    HomeView(
        openSearch: {},
        openGuide: {},
        openCalendar: {},
        openSettings: {},
        referenceDate: Calendar.kadoma.date(from: DateComponents(year: 2026, month: 5, day: 31)) ?? .now
    )
    .environmentObject(MasterStore())
}

#Preview("Home Weekly Simple iPhone SE") {
    HomeView(openSearch: {}, openGuide: {}, openCalendar: {}, openSettings: {})
        .environmentObject(MasterStore())
        .previewLayout(.fixed(width: 320, height: 568))
}

#Preview("Home Weekly Simple Dynamic Type Large") {
    HomeView(openSearch: {}, openGuide: {}, openCalendar: {}, openSettings: {})
        .environmentObject(MasterStore())
        .environment(\.dynamicTypeSize, .accessibility2)
        .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Home Weekly Category Tap") {
    HomeView(openSearch: {}, openGuide: {}, openCalendar: {}, openSettings: {})
        .environmentObject(MasterStore())
        .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Home Master Updating") {
    HomeUpdateStatusBar(status: .loading("データを更新しています..."))
        .padding()
        .previewLayout(.sizeThatFits)
}

#Preview("Home Master Update Success") {
    HomeUpdateStatusBar(status: .success("ごみ収集データを更新しました"))
        .padding()
        .previewLayout(.sizeThatFits)
}

#Preview("Home Master Update Failure") {
    HomeUpdateStatusBar(status: .failure("データを更新できませんでした。通信状況を確認して、もう一度お試しください。"))
        .padding()
        .previewLayout(.sizeThatFits)
}

#Preview("Home iPhone SE") {
    HomeView(openSearch: {}, openGuide: {}, openCalendar: {}, openSettings: {})
        .environmentObject(MasterStore())
        .previewLayout(.fixed(width: 320, height: 568))
}
