import SwiftUI

struct CollectionCalendarView: View {
    @EnvironmentObject private var store: MasterStore
    @State private var displayedMonth = Calendar.kadoma.startOfMonth(for: .now)

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let weekdays = ["月", "火", "水", "木", "金", "土", "日"]

    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                monthControls
                weekdayHeader
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(Array(monthCells.enumerated()), id: \.offset) { _, date in
                            if let date {
                                DayCell(date: date, events: store.events(on: date))
                            } else {
                                Color.clear
                                    .aspectRatio(0.78, contentMode: .fit)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("カレンダー")
        }
    }

    private var monthControls: some View {
        HStack {
            Button {
                displayedMonth = Calendar.kadoma.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(.bordered)

            Spacer()
            Text(KadomaDateFormatter.monthTitle.string(from: displayedMonth))
                .font(.title3.bold())
            Spacer()

            Button {
                displayedMonth = Calendar.kadoma.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
            } label: {
                Image(systemName: "chevron.right")
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.top)
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(weekdays, id: \.self) { weekday in
                Text(weekday)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal)
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

private struct DayCell: View {
    @EnvironmentObject private var store: MasterStore
    let date: Date
    let events: [CollectionEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(Calendar.kadoma.component(.day, from: date))")
                .font(.caption.bold())
                .foregroundStyle(Calendar.kadoma.isDateInToday(date) ? .white : .primary)
                .frame(width: 24, height: 24)
                .background(Calendar.kadoma.isDateInToday(date) ? Color.accentColor : .clear, in: Circle())

            ForEach(events.prefix(3)) { event in
                if let category = store.category(for: event.categoryId) {
                    Text(category.shortName)
                        .font(.caption2.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.55)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(hex: category.colorHex).opacity(0.14), in: RoundedRectangle(cornerRadius: 4))
                        .foregroundStyle(Color(hex: category.colorHex))
                }
            }

            Spacer(minLength: 0)
        }
        .padding(6)
        .aspectRatio(0.78, contentMode: .fit)
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

