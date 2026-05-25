import Foundation
import UserNotifications

struct NotificationService {
    func reschedule(events: [CollectionEvent], categories: [WasteCategory], settings: UserSettings) async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else { return }

        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix("gomi_") })

        var scheduledCount = 0
        for event in events where scheduledCount < 60 {
            guard event.categoryId != "bulky", let category = categories.first(where: { $0.id == event.categoryId }) else {
                continue
            }

            if settings.previousNightNotificationEnabled && category.defaultPreviousNightNotification {
                try await addNotification(
                    id: "\(event.id)_previous",
                    date: previousDay(for: event.date, hour: settings.previousNightHour),
                    title: "明日は「\(category.name)」の日です",
                    body: notificationBody(for: category, prefix: "朝9時までに出してください。")
                )
                scheduledCount += 1
            }

            if settings.morningNotificationEnabled && category.defaultMorningNotification && scheduledCount < 60 {
                try await addNotification(
                    id: "\(event.id)_morning",
                    date: sameDay(for: event.date, hour: settings.morningHour, minute: settings.morningMinute),
                    title: "今日は「\(category.name)」の日です",
                    body: notificationBody(for: category, prefix: "朝9時までです。")
                )
                scheduledCount += 1
            }
        }
    }

    private func addNotification(id: String, date: Date, title: String, body: String) async throws {
        guard date > .now else { return }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = Calendar.kadoma.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        components.calendar = .kadoma
        components.timeZone = Calendar.kadoma.timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "gomi_\(id)", content: content, trigger: trigger))
    }

    private func previousDay(for date: Date, hour: Int) -> Date {
        let previous = Calendar.kadoma.date(byAdding: .day, value: -1, to: date) ?? date
        return Calendar.kadoma.date(bySettingHour: hour, minute: 0, second: 0, of: previous) ?? previous
    }

    private func sameDay(for date: Date, hour: Int, minute: Int) -> Date {
        Calendar.kadoma.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }

    private func notificationBody(for category: WasteCategory, prefix: String) -> String {
        if let firstNote = category.notes.first {
            return "\(prefix)\n\(firstNote)"
        }
        return prefix
    }
}

