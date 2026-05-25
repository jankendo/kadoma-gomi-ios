import Foundation

struct DayCollectionSummary: Identifiable, Hashable {
    let date: Date
    let events: [CollectionEvent]
    let notices: [Notice]
    let reviewRules: [SpecialExceptionRule]

    var id: String {
        KadomaDateFormatter.dayKey.string(from: date)
    }

    var hasCollection: Bool {
        !events.isEmpty
    }

    var needsOfficialReview: Bool {
        !reviewRules.isEmpty || notices.contains { $0.confidence != "confirmed" }
    }
}

struct AreaCollectionSummary: Hashable {
    let areaId: String
    let areaName: String
    let addressText: String
    let masterVersion: String
    let sourceUpdatedAt: String
    let today: DayCollectionSummary
    let tomorrow: DayCollectionSummary
    let nextEvents: [CollectionEvent]
    let dataNotices: [Notice]

    var requiresOfficialReview: Bool {
        today.needsOfficialReview || tomorrow.needsOfficialReview || !dataNotices.isEmpty
    }
}

struct GarbageSummaryProvider {
    let master: MunicipalityMaster
    let settings: UserSettings
    let calendarService: CalendarGenerateService

    init(master: MunicipalityMaster, settings: UserSettings, calendarService: CalendarGenerateService = CalendarGenerateService()) {
        self.master = master
        self.settings = settings
        self.calendarService = calendarService
    }

    func areaSummary(referenceDate: Date = .now, nextLimit: Int = 7) -> AreaCollectionSummary {
        let today = Calendar.kadoma.startOfDay(for: referenceDate)
        let tomorrow = Calendar.kadoma.date(byAdding: .day, value: 1, to: today) ?? today
        let area = master.areas.first { $0.id == settings.areaId }
        let todayEvents = events(on: today)
        let tomorrowEvents = events(on: tomorrow)
        let nextEvents = Array(events(from: today, days: 45).filter { $0.date >= today }.prefix(nextLimit))
        let notices = activeNotices(around: today)

        return AreaCollectionSummary(
            areaId: settings.areaId,
            areaName: area?.name ?? "\(settings.areaId)地区",
            addressText: settings.addressText,
            masterVersion: master.version,
            sourceUpdatedAt: master.sourceUpdatedAt,
            today: DayCollectionSummary(
                date: today,
                events: todayEvents,
                notices: notices,
                reviewRules: activeReviewRules(on: today)
            ),
            tomorrow: DayCollectionSummary(
                date: tomorrow,
                events: tomorrowEvents,
                notices: activeNotices(around: tomorrow),
                reviewRules: activeReviewRules(on: tomorrow)
            ),
            nextEvents: nextEvents,
            dataNotices: notices
        )
    }

    func events(on date: Date) -> [CollectionEvent] {
        let start = Calendar.kadoma.startOfDay(for: date)
        let end = Calendar.kadoma.date(byAdding: .day, value: 1, to: start) ?? start
        return sortedEvents(
            calendarService.generateEvents(master: master, areaId: settings.areaId, from: start, to: end)
        )
    }

    func events(from start: Date, days: Int) -> [CollectionEvent] {
        let startDay = Calendar.kadoma.startOfDay(for: start)
        let end = Calendar.kadoma.date(byAdding: .day, value: days, to: startDay) ?? startDay
        return sortedEvents(
            calendarService.generateEvents(master: master, areaId: settings.areaId, from: startDay, to: end)
        )
    }

    func activeNotices(around date: Date) -> [Notice] {
        let month = Calendar.kadoma.component(.month, from: date)
        return master.notices.filter { notice in
            notice.monthHints.isEmpty || notice.monthHints.contains(month)
        }
    }

    func activeReviewRules(on date: Date) -> [SpecialExceptionRule] {
        let dayKey = KadomaDateFormatter.dayKey.string(from: date)
        return (master.exceptionRules ?? []).filter { rule in
            rule.areaIds.contains(settings.areaId)
                && rule.dateFrom <= dayKey
                && dayKey <= rule.dateTo
                && rule.confidence != "confirmed"
        }
    }

    private func sortedEvents(_ events: [CollectionEvent]) -> [CollectionEvent] {
        events.sorted {
            if $0.date == $1.date {
                return eventSortKey($0) < eventSortKey($1)
            }
            return $0.date < $1.date
        }
    }

    private func eventSortKey(_ event: CollectionEvent) -> String {
        let order = [
            "burnable": "00",
            "plastic_container": "10",
            "bottles_cans": "20",
            "paper_cloth": "30",
            "small_items": "40",
            "pet_bottle": "50",
            "bulky": "60"
        ]
        return order[event.categoryId, default: "99"] + event.categoryId
    }
}
