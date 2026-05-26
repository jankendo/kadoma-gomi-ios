import SwiftUI

struct CollectionCalendarView: View {
    @EnvironmentObject private var store: MasterStore
    @State private var displayedMonth: Date
    @State private var selectedDate: Date

    private let weekdays = ["日", "月", "火", "水", "木", "金", "土"]

    init(initialMonth: Date = Calendar.kadoma.startOfMonth(for: .now), selectedDate: Date = .now) {
        _displayedMonth = State(initialValue: Calendar.kadoma.startOfMonth(for: initialMonth))
        _selectedDate = State(initialValue: Calendar.kadoma.startOfDay(for: selectedDate))
    }

    private var reviewSummary: AreaCollectionSummary {
        store.collectionSummary(referenceDate: displayedMonth)
    }

    private var monthNeedsReview: Bool {
        reviewSummary.today.needsOfficialReview
    }

    private var monthCells: [Date?] {
        let first = Calendar.kadoma.startOfMonth(for: displayedMonth)
        guard let range = Calendar.kadoma.range(of: .day, in: .month, for: first) else { return [] }
        let weekday = Calendar.kadoma.component(.weekday, from: first)
        let prefix = Array<Date?>(repeating: nil, count: weekday - 1)
        let dates = range.compactMap { day -> Date? in
            Calendar.kadoma.date(byAdding: .day, value: day - 1, to: first)
        }
        let rawCells = prefix + dates
        let rowCount = Int(ceil(Double(rawCells.count) / 7.0))
        return rawCells + Array<Date?>(repeating: nil, count: max(0, rowCount * 7 - rawCells.count))
    }

    private var rowCount: Int {
        max(5, monthCells.count / 7)
    }

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let noticeHeight: CGFloat = monthNeedsReview ? 34 : 0
                let reservedHeight: CGFloat = 58 + 78 + 34 + noticeHeight + CGFloat(max(0, rowCount - 1)) * 1
                let cellHeight = max(44, floor((proxy.size.height - reservedHeight) / CGFloat(rowCount)))

                VStack(spacing: 0) {
                    CalendarRuleStrip()
                        .frame(height: 58)

                    CalendarMonthOnlyHeader(
                        displayedMonth: displayedMonth,
                        areaName: store.currentArea?.name ?? "\(store.settings.areaId)地区",
                        movePrevious: { moveMonth(-1) },
                        moveNext: { moveMonth(1) },
                        moveToday: moveToday
                    )
                    .frame(height: 78)

                    if monthNeedsReview {
                        CalendarCompactNotice(text: reviewSummary.today.reviewRules.first?.title ?? "年末年始は公式情報も確認")
                            .frame(height: noticeHeight)
                    }

                    CalendarFullMonthGrid(
                        weekdays: weekdays,
                        monthCells: monthCells,
                        selectedDate: $selectedDate,
                        cellHeight: cellHeight,
                        eventsProvider: store.events(on:),
                        categoryProvider: store.category(for:),
                        itemsProvider: items(for:)
                    )
                    .simultaneousGesture(monthSwipeGesture)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                }
                .background(Color.white)
            }
            .navigationTitle("収集日カレンダー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppColor.header, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func moveMonth(_ value: Int) {
        guard let nextMonth = Calendar.kadoma.date(byAdding: .month, value: value, to: displayedMonth) else { return }
        withAnimation(.easeOut(duration: 0.18)) {
            displayedMonth = Calendar.kadoma.startOfMonth(for: nextMonth)
            selectedDate = displayedMonth
        }
    }

    private func moveToday() {
        withAnimation(.easeOut(duration: 0.18)) {
            displayedMonth = Calendar.kadoma.startOfMonth(for: .now)
            selectedDate = Calendar.kadoma.startOfDay(for: .now)
        }
    }

    private func items(for categoryId: String) -> [WasteItem] {
        store.master.itemDictionary.filter { $0.categoryId == categoryId }
    }

    private var monthSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 28, coordinateSpace: .local)
            .onEnded { value in
                let width = value.translation.width
                let height = value.translation.height
                guard abs(width) > 72, abs(width) > abs(height) * 1.35 else { return }
                moveMonth(width < 0 ? 1 : -1)
            }
    }
}

private struct CalendarRuleStrip: View {
    var body: some View {
        HStack(spacing: AppSpacing.md) {
            Image(systemName: AppIcon.info)
                .font(.title3.weight(.semibold))
                .foregroundStyle(AppColor.appTint)
                .accessibilityHidden(true)
            Text("収集日当日の朝9時までに、分別して出してください。")
                .font(AppTypography.callout)
                .foregroundStyle(AppColor.text)
                .lineLimit(2)
                .minimumScaleFactor(0.82)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.lg)
        .background(AppColor.backgroundTop)
        .accessibilityElement(children: .combine)
    }
}

private struct CalendarMonthOnlyHeader: View {
    let displayedMonth: Date
    let areaName: String
    let movePrevious: () -> Void
    let moveNext: () -> Void
    let moveToday: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: AppSpacing.md) {
            Button(action: movePrevious) {
                Image(systemName: "chevron.left")
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("前の月")

            VStack(alignment: .leading, spacing: 2) {
                Text(KadomaDateFormatter.monthTitle.string(from: displayedMonth))
                    .font(.largeTitle.weight(.bold))
                    .foregroundStyle(AppColor.text)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Text(areaName)
                    .font(AppTypography.callout)
                    .foregroundStyle(AppColor.secondaryText)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)

            Button(action: moveToday) {
                Text("今日")
                    .font(AppTypography.compactTitle)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppColor.appTint)
            .accessibilityLabel("今月に戻る")

            Button(action: moveNext) {
                Image(systemName: "chevron.right")
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("次の月")
        }
        .padding(.horizontal, AppSpacing.lg)
        .background(Color.white)
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

private struct CalendarCompactNotice: View {
    let text: String

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: AppIcon.warning)
                .foregroundStyle(AppColor.warning)
                .accessibilityHidden(true)
            Text(text)
                .font(AppTypography.footnote.weight(.semibold))
                .foregroundStyle(AppColor.text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, AppSpacing.lg)
        .background(AppColor.softYellow)
        .accessibilityElement(children: .combine)
    }
}

private struct CalendarFullMonthGrid: View {
    let weekdays: [String]
    let monthCells: [Date?]
    @Binding var selectedDate: Date
    let cellHeight: CGFloat
    let eventsProvider: (Date) -> [CollectionEvent]
    let categoryProvider: (String) -> WasteCategory?
    let itemsProvider: (String) -> [WasteItem]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)

    var body: some View {
        VStack(spacing: 0) {
            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(weekdayColor(weekday))
                        .frame(maxWidth: .infinity, minHeight: 34)
                        .background(Color.white)
                        .overlay(Rectangle().stroke(AppColor.separator, lineWidth: 0.6))
                }
            }

            LazyVGrid(columns: columns, spacing: 0) {
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        CalendarMonthOnlyCell(
                            date: date,
                            events: eventsProvider(date),
                            isSelected: Calendar.kadoma.isDate(date, inSameDayAs: selectedDate),
                            cellHeight: cellHeight,
                            categoryProvider: categoryProvider,
                            itemsProvider: itemsProvider
                        ) {
                            selectedDate = Calendar.kadoma.startOfDay(for: date)
                        }
                    } else {
                        Color.white
                            .frame(maxWidth: .infinity, minHeight: cellHeight)
                            .overlay(Rectangle().stroke(AppColor.separator, lineWidth: 0.6))
                    }
                }
            }
        }
    }

    private func weekdayColor(_ weekday: String) -> Color {
        if weekday == "日" {
            return AppColor.error
        }
        if weekday == "土" {
            return AppColor.subTint
        }
        return AppColor.text
    }
}

private struct CalendarMonthOnlyCell: View {
    let date: Date
    let events: [CollectionEvent]
    let isSelected: Bool
    let cellHeight: CGFloat
    let categoryProvider: (String) -> WasteCategory?
    let itemsProvider: (String) -> [WasteItem]
    let select: () -> Void

    private var isToday: Bool {
        Calendar.kadoma.isDateInToday(date)
    }

    private var weekday: Int {
        Calendar.kadoma.component(.weekday, from: date)
    }

    private var compact: Bool {
        cellHeight < 58
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text("\(Calendar.kadoma.component(.day, from: date))")
                .font(.title3.weight(.bold))
                .foregroundStyle(dateColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)

            Spacer(minLength: 0)

            VStack(alignment: .leading, spacing: 2) {
                ForEach(events.prefix(compact ? 1 : 2)) { event in
                    if let category = categoryProvider(event.categoryId) {
                        CalendarMiniWasteLabel(
                            category: category,
                            items: itemsProvider(category.id),
                            compact: compact
                        )
                    }
                }
                if events.count > (compact ? 1 : 2) {
                    Text("+\(events.count - (compact ? 1 : 2))")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppColor.secondaryText)
                }
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, minHeight: cellHeight, alignment: .topLeading)
        .background(isToday ? AppColor.backgroundTop.opacity(0.65) : Color.white)
        .overlay(
            Rectangle()
                .stroke(AppColor.separator, lineWidth: 0.6)
        )
        .overlay(
            Rectangle()
                .stroke(isToday ? AppColor.accent : (isSelected ? AppColor.appTint : Color.clear), lineWidth: isToday || isSelected ? 2.2 : 0)
                .padding(1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: select)
        .accessibilityElement(children: .contain)
    }

    private var dateColor: Color {
        if weekday == 1 {
            return AppColor.error
        }
        if weekday == 7 {
            return AppColor.subTint
        }
        return AppColor.text
    }

    private var accessibilityLabel: String {
        let dateText = KadomaDateFormatter.displayDay.string(from: date)
        guard !events.isEmpty else {
            return "\(dateText)、収集なし"
        }
        let names = events.compactMap { categoryProvider($0.categoryId)?.name }.joined(separator: "、")
        return "\(dateText)、\(names)"
    }
}

private struct CalendarMiniWasteLabel: View {
    let category: WasteCategory
    let items: [WasteItem]
    let compact: Bool

    var body: some View {
        NavigationLink {
            WasteCategoryDetailView(category: category, items: items)
        } label: {
            HStack(spacing: 2) {
                Image(systemName: category.symbolName)
                    .font(.system(size: compact ? 9 : 10, weight: .semibold))
                    .accessibilityHidden(true)
                if !compact {
                    Text(category.shortName)
                        .font(.system(size: 10, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(minHeight: compact ? 22 : 24, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppColor.category(category))
        .accessibilityLabel("\(category.name)、詳細を開く")
    }
}

#Preview("Calendar Full Month Only Default") {
    CollectionCalendarView()
        .environmentObject(MasterStore())
}

#Preview("Calendar Full Month Only iPhone SE") {
    CollectionCalendarView()
        .environmentObject(MasterStore())
        .previewLayout(.fixed(width: 320, height: 568))
}

#Preview("Calendar Full Month Only Dynamic Type Large") {
    CollectionCalendarView()
        .environmentObject(MasterStore())
        .environment(\.dynamicTypeSize, .accessibility2)
        .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Calendar Full Month Only Multiple Items") {
    CollectionCalendarView(
        initialMonth: Calendar.kadoma.date(from: DateComponents(year: 2026, month: 5, day: 1)) ?? .now,
        selectedDate: Calendar.kadoma.date(from: DateComponents(year: 2026, month: 5, day: 7)) ?? .now
    )
    .environmentObject(MasterStore())
    .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Calendar Full Month Only Year End Notice") {
    CollectionCalendarView(
        initialMonth: Calendar.kadoma.date(from: DateComponents(year: 2026, month: 12, day: 1)) ?? .now,
        selectedDate: Calendar.kadoma.date(from: DateComponents(year: 2026, month: 12, day: 28)) ?? .now
    )
    .environmentObject(MasterStore())
    .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Calendar Swipe Month Default") {
    CollectionCalendarView()
        .environmentObject(MasterStore())
        .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Calendar Swipe Month Next Month") {
    CollectionCalendarView(
        initialMonth: Calendar.kadoma.date(from: DateComponents(year: 2026, month: 6, day: 1)) ?? .now
    )
    .environmentObject(MasterStore())
    .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Calendar Swipe Month Previous Month") {
    CollectionCalendarView(
        initialMonth: Calendar.kadoma.date(from: DateComponents(year: 2026, month: 4, day: 1)) ?? .now
    )
    .environmentObject(MasterStore())
    .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Calendar Category Tap Preview") {
    CollectionCalendarView(
        initialMonth: Calendar.kadoma.date(from: DateComponents(year: 2026, month: 5, day: 1)) ?? .now,
        selectedDate: Calendar.kadoma.date(from: DateComponents(year: 2026, month: 5, day: 7)) ?? .now
    )
    .environmentObject(MasterStore())
    .previewLayout(.fixed(width: 393, height: 852))
}

#Preview("Calendar iPhone SE") {
    CollectionCalendarView()
        .environmentObject(MasterStore())
        .previewLayout(.fixed(width: 320, height: 568))
}
