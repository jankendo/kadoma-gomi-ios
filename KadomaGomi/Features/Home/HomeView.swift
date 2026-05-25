import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: MasterStore

    private var todayEvents: [CollectionEvent] { store.events(on: .now) }
    private var tomorrowEvents: [CollectionEvent] {
        guard let tomorrow = Calendar.kadoma.date(byAdding: .day, value: 1, to: .now) else { return [] }
        return store.events(on: tomorrow)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    locationHeader
                    DaySummaryCard(title: "今日", date: .now, events: todayEvents)
                    if let tomorrow = Calendar.kadoma.date(byAdding: .day, value: 1, to: .now) {
                        DaySummaryCard(title: "明日", date: tomorrow, events: tomorrowEvents)
                    }
                    upcomingSection
                    noticeSection
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("かどまごみナビ")
        }
    }

    private var locationHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("大倉町 / A地区")
                .font(.title2.bold())
            Text("収集日の朝9時までに出してください")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("次回")
                .font(.headline)
            ForEach(store.nextEvents(limit: 6)) { event in
                EventRow(event: event)
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }

    private var noticeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("年末年始は公式情報を確認", systemImage: "exclamationmark.triangle.fill")
                .font(.headline)
                .foregroundStyle(.orange)
            Text("12月・1月は通常ルールから変更される可能性があります。アプリは例外マスタを優先しますが、最終確認は門真市公式ページで行ってください。")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct DaySummaryCard: View {
    @EnvironmentObject private var store: MasterStore
    let title: String
    let date: Date
    let events: [CollectionEvent]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.headline)
                Text(KadomaDateFormatter.displayDay.string(from: date))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            if events.isEmpty {
                Text("出すごみはありません")
                    .font(.title3.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 10)
            } else {
                ForEach(events) { event in
                    EventRow(event: event)
                }
            }
        }
        .padding()
        .background(.background, in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct EventRow: View {
    @EnvironmentObject private var store: MasterStore
    let event: CollectionEvent

    var body: some View {
        let category = store.category(for: event.categoryId)
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: category?.symbolName ?? "trash.fill")
                .frame(width: 34, height: 34)
                .background(Color(hex: category?.colorHex ?? "#49656a").opacity(0.15), in: Circle())
                .foregroundStyle(Color(hex: category?.colorHex ?? "#49656a"))
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(category?.name ?? event.categoryId)
                        .font(.headline)
                    if event.requiresReservation {
                        Text("要予約")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.orange.opacity(0.15), in: Capsule())
                            .foregroundStyle(.orange)
                    }
                }
                Text(KadomaDateFormatter.displayDay.string(from: event.date))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(event.note ?? category?.disposalRule ?? "朝9時まで")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
    }
}

