import SwiftUI

struct CollectionCalendarView: View {
    @EnvironmentObject private var store: MasterStore
    @State private var displayedMonth = Calendar.kadoma.startOfMonth(for: .now)
    @State private var displayMode: CalendarDisplayMode = .month

    private let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.sm), count: 7)
    private let weekdays = ["月", "火", "水", "木", "金", "土", "日"]

    var body: some View {
        NavigationStack {
            AppScreen {
                CalendarHeader(displayedMonth: $displayedMonth, displayMode: $displayMode)
                CalendarLegend(categories: store.master.categories)

                if displayMode == .month {
                    monthGrid
                } else {
                    upcomingList
                }

                AppStateView(
                    kind: .empty,
                    title: "例外日はマスタを優先します",
                    message: "12月・1月や災害時は通常曜日から変わる場合があります。公式ページとアプリ内マスタ更新を確認してください。"
                )
            }
            .navigationTitle("カレンダー")
        }
    }

    private var monthGrid: some View {
        VStack(spacing: AppSpacing.sm) {
            LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                ForEach(weekdays, id: \.self) { weekday in
                    Text(weekday)
                        .font(AppTypography.badge)
                        .foregroundStyle(AppColor.secondaryText)
                        .frame(maxWidth: .infinity)
                        .accessibilityHidden(true)
                }
            }

            LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        CalendarDayCell(
                            date: date,
                            events: store.events(on: date),
                            categoryProvider: store.category(for:)
                        )
                    } else {
                        Color.clear
                            .aspectRatio(0.75, contentMode: .fit)
                    }
                }
            }
        }
    }

    private var upcomingList: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("直近30日", subtitle: "日付順に収集予定を表示します", systemImage: AppIcon.calendar)
            let events = store.events(from: .now, days: 30)
            if events.isEmpty {
                AppStateView(kind: .empty, title: "予定がありません", message: "地区設定またはマスタデータを確認してください。")
            } else {
                VStack(spacing: AppSpacing.sm) {
                    ForEach(events) { event in
                        CollectionEventRow(event: event, category: store.category(for: event.categoryId), showsDate: true)
                    }
                }
            }
        }
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

private struct CalendarHeader: View {
    @Binding var displayedMonth: Date
    @Binding var displayMode: CalendarDisplayMode

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            HStack {
                Button {
                    displayedMonth = Calendar.kadoma.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.left")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("前の月")

                Spacer()
                Text(KadomaDateFormatter.monthTitle.string(from: displayedMonth))
                    .font(AppTypography.sectionTitle)
                Spacer()

                Button {
                    displayedMonth = Calendar.kadoma.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                } label: {
                    Image(systemName: "chevron.right")
                }
                .buttonStyle(.bordered)
                .accessibilityLabel("次の月")
            }

            Picker("表示", selection: $displayMode) {
                ForEach(CalendarDisplayMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .appCard()
    }
}

private struct CalendarLegend: View {
    let categories: [WasteCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.md) {
            AppSectionHeader("凡例", subtitle: "色だけでなくラベルでも見分けられます", systemImage: "paintpalette.fill")
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: AppSpacing.sm)], alignment: .leading, spacing: AppSpacing.sm) {
                ForEach(categories.filter { $0.id != "recycle_law" && $0.id != "hazardous_note" }) { category in
                    AppBadge(category.shortName, color: AppColor.category(category), systemImage: category.symbolName)
                }
            }
        }
        .appCard()
    }
}

private struct CalendarDayCell: View {
    let date: Date
    let events: [CollectionEvent]
    let categoryProvider: (String) -> WasteCategory?

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.xs) {
            HStack {
                Text("\(Calendar.kadoma.component(.day, from: date))")
                    .font(AppTypography.badge)
                    .foregroundStyle(Calendar.kadoma.isDateInToday(date) ? .white : AppColor.text)
                    .frame(width: 26, height: 26)
                    .background(Calendar.kadoma.isDateInToday(date) ? AppColor.appTint : .clear, in: Circle())
                Spacer(minLength: 0)
            }

            ForEach(events.prefix(3)) { event in
                if let category = categoryProvider(event.categoryId) {
                    Text(category.shortName)
                        .font(.caption2.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColor.category(category).opacity(0.15), in: RoundedRectangle(cornerRadius: 4, style: .continuous))
                        .foregroundStyle(AppColor.category(category))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(6)
        .aspectRatio(0.75, contentMode: .fit)
        .background(AppColor.cardBackground, in: RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.sm, style: .continuous)
                .stroke(Calendar.kadoma.isDateInToday(date) ? AppColor.appTint : AppColor.separator.opacity(0.35), lineWidth: Calendar.kadoma.isDateInToday(date) ? 1.5 : 0.5)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let dateText = KadomaDateFormatter.displayDay.string(from: date)
        guard !events.isEmpty else { return "\(dateText)、収集予定なし" }
        let names = events.compactMap { categoryProvider($0.categoryId)?.name }.joined(separator: "、")
        return "\(dateText)、\(names)"
    }
}

#Preview {
    CollectionCalendarView()
        .environmentObject(MasterStore())
}

