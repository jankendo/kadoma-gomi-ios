import SwiftUI

struct CollectionCalendarView: View {
    @EnvironmentObject private var store: MasterStore
    @State private var displayedMonth: Date
    @State private var selectedDate: Date
    @State private var displayMode: CalendarDisplayMode = .month

    private let weekdays = ["月", "火", "水", "木", "金", "土", "日"]

    init(initialMonth: Date = Calendar.kadoma.startOfMonth(for: .now), selectedDate: Date = .now) {
        _displayedMonth = State(initialValue: Calendar.kadoma.startOfMonth(for: initialMonth))
        _selectedDate = State(initialValue: Calendar.kadoma.startOfDay(for: selectedDate))
    }

    private var reviewSummary: AreaCollectionSummary {
        store.collectionSummary(referenceDate: displayedMonth)
    }

    private var selectedEvents: [CollectionEvent] {
        store.events(on: selectedDate)
    }

    var body: some View {
        NavigationStack {
            AppScreen {
                CalendarMonthHeader(
                    displayedMonth: $displayedMonth,
                    selectedDate: $selectedDate,
                    displayMode: $displayMode,
                    areaName: store.currentArea?.name ?? "\(store.settings.areaId)地区"
                )

                SpecialRuleNoticeCard(summary: reviewSummary)

                CalendarLegendView(categories: visibleCategories)

                if displayMode == .month {
                    CalendarMonthView(
                        weekdays: weekdays,
                        monthCells: monthCells,
                        selectedDate: $selectedDate,
                        eventsProvider: store.events(on:),
                        categoryProvider: store.category(for:)
                    )
                    SelectedDaySummaryCard(
                        date: selectedDate,
                        events: selectedEvents,
                        categoryProvider: store.category(for:)
                    )
                } else {
                    CollectionEventList(
                        title: "直近30日の予定",
                        events: store.events(from: .now, days: 30),
                        categoryProvider: store.category(for:)
                    )
                }
            }
            .navigationTitle("収集日カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.header, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var visibleCategories: [WasteCategory] {
        store.master.categories.filter { $0.id != "recycle_law" && $0.id != "hazardous_note" }
    }

    private var monthCells: [Date?] {
        let first = Calendar.kadoma.startOfMonth(for: displayedMonth)
        guard let range = Calendar.kadoma.range(of: .day, in: .month, for: first) else { return [] }
        let weekday = CalendarGenerateService().weekdayNumber(for: first)
        let prefix = Array<Date?>(repeating: nil, count: weekday - 1)
        let dates = range.compactMap { day -> Date? in
            Calendar.kadoma.date(byAdding: .day, value: day - 1, to: first)
        }
        return prefix + dates
    }
}

private enum CalendarDisplayMode: String, CaseIterable, Identifiable {
    case month = "月"
    case list = "リスト"

    var id: String { rawValue }
}

private struct CalendarMonthHeader: View {
    @Binding var displayedMonth: Date
    @Binding var selectedDate: Date
    @Binding var displayMode: CalendarDisplayMode
    let areaName: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack(alignment: .firstTextBaseline, spacing: AppSpacing.md) {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text(KadomaDateFormatter.monthTitle.string(from: displayedMonth))
                        .font(AppTypography.screenTitle)
                    Text("\(areaName)の収集予定")
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.secondaryText)
                }

                Spacer(minLength: 0)

                Button {
                    displayedMonth = Calendar.kadoma.startOfMonth(for: .now)
                    selectedDate = Calendar.kadoma.startOfDay(for: .now)
                } label: {
                    Label("今日", systemImage: AppIcon.today)
                        .font(AppTypography.compactTitle)
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
            }

            HStack(spacing: AppSpacing.md) {
                Button {
                    moveMonth(-1)
                } label: {
                    Label("前月", systemImage: "chevron.left")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .accessibilityLabel("前の月")

                Spacer(minLength: 0)

                Button {
                    moveMonth(1)
                } label: {
                    Label("次月", systemImage: "chevron.right")
                }
                .buttonStyle(.bordered)
                .controlSize(.regular)
                .accessibilityLabel("次の月")
            }

            Picker("表示", selection: $displayMode) {
                ForEach(CalendarDisplayMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text("日付を選ぶと、その日の分別種類と出し方の要点を下に表示します。")
                .font(AppTypography.callout)
                .foregroundStyle(AppColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .appCard()
        .accessibilityElement(children: .combine)
    }

    private func moveMonth(_ value: Int) {
        guard let nextMonth = Calendar.kadoma.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        displayedMonth = Calendar.kadoma.startOfMonth(for: nextMonth)
        selectedDate = displayedMonth
    }
}

private struct SpecialRuleNoticeCard: View {
    let summary: AreaCollectionSummary

    var body: some View {
        HStack(alignment: .top, spacing: AppSpacing.md) {
            Image(systemName: summary.today.needsOfficialReview ? AppIcon.warning : AppIcon.shield)
                .font(.headline.weight(.semibold))
                .frame(width: 40, height: 40)
                .background(summary.today.needsOfficialReview ? AppColor.softYellow : AppColor.backgroundTop, in: Circle())
                .foregroundStyle(summary.today.needsOfficialReview ? AppColor.warning : AppColor.success)

            VStack(alignment: .leading, spacing: AppSpacing.xs) {
                Text(summary.today.needsOfficialReview ? "この月は公式情報も確認" : "通常ルールで表示中")
                    .font(AppTypography.cardTitle)
                Text(summary.today.needsOfficialReview ? (summary.today.reviewRules.first?.description ?? "12月・1月は収集日が変わる場合があります。") : "災害時や臨時変更は通常曜日から変わる場合があります。最新マスタと公式情報を確認してください。")
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColor.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .appCard()
        .accessibilityElement(children: .combine)
    }
}

private struct CalendarLegendView: View {
    let categories: [WasteCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("凡例", subtitle: "アイコンと短い名前で見分けます", systemImage: "list.bullet")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: AppSpacing.sm)], alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(categories) { category in
                    AppBadge(category.shortName, color: AppColor.category(category), systemImage: category.symbolName)
                }
            }
        }
        .appCard()
    }
}

private struct CalendarMonthView: View {
    let weekdays: [String]
    let monthCells: [Date?]
    @Binding var selectedDate: Date
    let eventsProvider: (Date) -> [CollectionEvent]
    let categoryProvider: (String) -> WasteCategory?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    var body: some View {
        VStack(spacing: AppSpacing.sm) {
            LazyVGrid(columns: columns, spacing: AppSpacing.xs) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(AppTypography.compactTitle)
                        .foregroundStyle(weekday == "土" ? AppColor.subTint : (weekday == "日" ? AppColor.error : AppColor.secondaryText))
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(AppColor.backgroundTop.opacity(0.55), in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
                }
            }

            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        CalendarDayCell(
                            date: date,
                            events: eventsProvider(date),
                            isSelected: Calendar.kadoma.isDate(date, inSameDayAs: selectedDate),
                            categoryProvider: categoryProvider
                        ) {
                            selectedDate = Calendar.kadoma.startOfDay(for: date)
                        }
                    } else {
                        Color.clear
                            .frame(minHeight: 88)
                    }
                }
            }
        }
        .appCard()
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let events: [CollectionEvent]
    let isSelected: Bool
    let categoryProvider: (String) -> WasteCategory?
    let select: () -> Void

    private var isToday: Bool {
        Calendar.kadoma.isDateInToday(date)
    }

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 2) {
                    Text("\(Calendar.kadoma.component(.day, from: date))")
                        .font(AppTypography.compactTitle)
                        .foregroundStyle(isToday ? .white : AppColor.text)
                        .frame(width: 26, height: 26)
                        .background(isToday ? AppColor.appTint : Color.clear, in: Circle())
                    Spacer(minLength: 0)
                    if events.count > 2 {
                        Text("+\(events.count - 2)")
                            .font(AppTypography.tinyBadge)
                            .foregroundStyle(AppColor.tertiaryText)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    ForEach(events.prefix(2)) { event in
                        if let category = categoryProvider(event.categoryId) {
                            CollectionDayChip(category: category)
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(5)
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .background(isSelected ? AppColor.backgroundTop : AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                    .stroke(isSelected ? AppColor.appTint : (isToday ? AppColor.appTint : AppColor.separator.opacity(0.55)), lineWidth: isSelected || isToday ? 2 : 0.7)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("選ぶと下にその日の予定を表示します。")
    }

    private var accessibilityLabel: String {
        let dateText = KadomaDateFormatter.displayDay.string(from: date)
        guard !events.isEmpty else { return "\(dateText)、収集予定なし" }
        let names = events.compactMap { categoryProvider($0.categoryId)?.name }.joined(separator: "、")
        return "\(dateText)、\(names)"
    }
}

private struct CollectionDayChip: View {
    let category: WasteCategory

    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: category.symbolName)
                .font(.system(size: 8, weight: .semibold))
            Text(category.shortName)
                .font(.system(size: 9, weight: .bold))
                .lineLimit(1)
                .minimumScaleFactor(0.70)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColor.categoryBackground(category), in: RoundedRectangle(cornerRadius: 5, style: .continuous))
        .foregroundStyle(AppColor.category(category))
    }
}

private struct SelectedDaySummaryCard: View {
    let date: Date
    let events: [CollectionEvent]
    let categoryProvider: (String) -> WasteCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: AppSpacing.xs) {
                    Text("選択日の予定")
                        .font(AppTypography.sectionTitle)
                    Text(KadomaDateFormatter.displayDay.string(from: date))
                        .font(AppTypography.callout)
                        .foregroundStyle(AppColor.secondaryText)
                }
                Spacer()
                if Calendar.kadoma.isDateInToday(date) {
                    AppBadge("今日", color: AppColor.appTint, systemImage: AppIcon.today)
                }
            }

            if events.isEmpty {
                AppStateView(kind: .empty, title: "この日は収集予定なし", message: "予定がない日も、年末年始や臨時変更は公式情報を確認してください。")
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(events) { event in
                        CollectionEventRow(event: event, category: categoryProvider(event.categoryId), showsDate: false)
                    }
                }
            }
        }
        .appCard()
    }
}

private struct CollectionEventList: View {
    let title: String
    let events: [CollectionEvent]
    let categoryProvider: (String) -> WasteCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader(title, subtitle: "日付順に収集予定を表示します", systemImage: AppIcon.calendar)
            if events.isEmpty {
                AppStateView(kind: .empty, title: "予定がありません", message: "地区設定またはマスタデータを確認してください。")
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

#Preview("Calendar Simple Default") {
    CollectionCalendarView()
        .environmentObject(MasterStore())
}

#Preview("Calendar Simple iPhone SE") {
    CollectionCalendarView()
        .environmentObject(MasterStore())
        .previewLayout(.fixed(width: 320, height: 568))
}

#Preview("Calendar Simple Dynamic Type Large") {
    CollectionCalendarView()
        .environmentObject(MasterStore())
        .environment(\.dynamicTypeSize, .accessibility2)
        .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Calendar Simple Year End Notice") {
    CollectionCalendarView(
        initialMonth: Calendar.kadoma.date(from: DateComponents(year: 2026, month: 12, day: 1)) ?? .now,
        selectedDate: Calendar.kadoma.date(from: DateComponents(year: 2026, month: 12, day: 28)) ?? .now
    )
    .environmentObject(MasterStore())
    .previewLayout(.fixed(width: 393, height: 852))
}
