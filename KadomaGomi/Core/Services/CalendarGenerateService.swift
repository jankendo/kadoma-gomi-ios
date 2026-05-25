import Foundation

struct CalendarGenerateService {
    func generateEvents(master: MunicipalityMaster, areaId: String, from startDate: Date, to endDate: Date) -> [CollectionEvent] {
        guard let area = master.areas.first(where: { $0.id == areaId }) else { return [] }

        var events: [CollectionEvent] = []
        var date = Calendar.kadoma.startOfDay(for: startDate)
        let end = Calendar.kadoma.startOfDay(for: endDate)

        while date < end {
            for rule in area.schedules where dateMatches(rule: rule, date: date) {
                events.append(CollectionEvent(
                    date: date,
                    areaId: areaId,
                    categoryId: rule.categoryId,
                    note: nil,
                    requiresReservation: rule.categoryId == "bulky"
                ))
            }
            guard let next = Calendar.kadoma.date(byAdding: .day, value: 1, to: date) else { break }
            date = next
        }

        return applyExceptions(area.exceptions, to: events, areaId: areaId)
    }

    func weekOfMonth(for date: Date) -> Int {
        let day = Calendar.kadoma.component(.day, from: date)
        return ((day - 1) / 7) + 1
    }

    func weekdayNumber(for date: Date) -> Int {
        let appleWeekday = Calendar.kadoma.component(.weekday, from: date)
        return ((appleWeekday + 5) % 7) + 1
    }

    private func dateMatches(rule: ScheduleRule, date: Date) -> Bool {
        guard
            let validFrom = KadomaDateFormatter.dayKey.date(from: rule.validFrom),
            let validTo = KadomaDateFormatter.dayKey.date(from: rule.validTo)
        else {
            return false
        }

        let day = Calendar.kadoma.startOfDay(for: date)
        guard day >= validFrom && day <= validTo else { return false }

        switch rule.recurrenceType {
        case .weekly:
            return rule.weekdays?.contains(weekdayNumber(for: day)) ?? false
        case .monthlyNthWeekday:
            return (rule.weekdays?.contains(weekdayNumber(for: day)) ?? false)
                && (rule.weekOfMonth?.contains(weekOfMonth(for: day)) ?? false)
        case .specificDates:
            return rule.specificDates?.contains(KadomaDateFormatter.dayKey.string(from: day)) ?? false
        }
    }

    private func applyExceptions(_ exceptions: [CollectionException], to events: [CollectionEvent], areaId: String) -> [CollectionEvent] {
        var updated = events

        for exception in exceptions where exception.areaId == areaId {
            guard let date = KadomaDateFormatter.dayKey.date(from: exception.date) else { continue }
            switch exception.action {
            case .cancel:
                updated.removeAll {
                    Calendar.kadoma.isDate($0.date, inSameDayAs: date)
                        && $0.areaId == exception.areaId
                        && $0.categoryId == exception.categoryId
                }
            case .add:
                updated.append(CollectionEvent(
                    date: Calendar.kadoma.startOfDay(for: date),
                    areaId: exception.areaId,
                    categoryId: exception.categoryId,
                    note: exception.reason,
                    requiresReservation: exception.categoryId == "bulky"
                ))
            case .note:
                updated = updated.map { event in
                    guard Calendar.kadoma.isDate(event.date, inSameDayAs: date), event.categoryId == exception.categoryId else {
                        return event
                    }
                    return CollectionEvent(
                        date: event.date,
                        areaId: event.areaId,
                        categoryId: event.categoryId,
                        note: exception.reason,
                        requiresReservation: event.requiresReservation
                    )
                }
            }
        }

        return Array(Set(updated))
    }
}

