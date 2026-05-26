import Foundation
import UserNotifications

struct NotificationService {
    static let developerTestIdentifierPrefix = "dev-test-notification-"

    func reschedule(events: [CollectionEvent], categories: [WasteCategory], settings: UserSettings) async throws {
        let center = UNUserNotificationCenter.current()
        let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        guard granted else { return }

        let pending = await center.pendingNotificationRequests()
        center.removePendingNotificationRequests(withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix("gomi_") })

        for preview in previews(events: events, categories: categories, settings: settings, limit: 60) {
            try await addNotification(
                id: preview.id,
                date: preview.fireDate,
                title: preview.title,
                body: preview.body
            )
        }
    }

    func previews(events: [CollectionEvent], categories: [WasteCategory], settings: UserSettings, limit: Int = 60) -> [NotificationPreview] {
        var previews: [NotificationPreview] = []

        for event in events where previews.count < limit {
            guard event.categoryId != "bulky", let category = categories.first(where: { $0.id == event.categoryId }) else {
                continue
            }
            guard settings.notificationEnabled(for: event.categoryId) else {
                continue
            }

            if settings.previousNightNotificationEnabled && category.defaultPreviousNightNotification {
                previews.append(NotificationPreview(
                    id: "\(event.id)_previous",
                    eventDate: event.date,
                    fireDate: previousDay(for: event.date, hour: settings.previousNightHour),
                    categoryId: event.categoryId,
                    title: "明日は「\(category.name)」の収集予定です",
                    body: notificationBody(for: category, event: event, prefix: "朝9時までに出してください。"),
                    timing: .previousNight
                ))
            }

            if settings.morningNotificationEnabled && category.defaultMorningNotification && previews.count < limit {
                previews.append(NotificationPreview(
                    id: "\(event.id)_morning",
                    eventDate: event.date,
                    fireDate: sameDay(for: event.date, hour: settings.morningHour, minute: settings.morningMinute),
                    categoryId: event.categoryId,
                    title: "今日の朝は「\(category.name)」の収集予定です",
                    body: notificationBody(for: category, event: event, prefix: "朝9時までです。"),
                    timing: .sameMorning
                ))
            }
        }

        return previews
            .filter { $0.fireDate > .now }
            .sorted { $0.fireDate < $1.fireDate }
            .prefix(limit)
            .map { $0 }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    @discardableResult
    func requestAuthorization() async throws -> Bool {
        try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleDeveloperTestNotification(after seconds: TimeInterval) async throws {
        let granted = try await requestAuthorization()
        guard granted else { throw DeveloperNotificationTestError.permissionDenied }
        try await addIntervalNotification(
            identifier: "\(Self.developerTestIdentifierPrefix)\(Int(seconds))s-\(UUID().uuidString)",
            seconds: seconds,
            title: "通知テスト",
            body: "門真市ごみアプリのテスト通知です。"
        )
    }

    func scheduleDeveloperWasteSimulation(kind: DeveloperNotificationKind, categoryName: String) async throws {
        let granted = try await requestAuthorization()
        guard granted else { throw DeveloperNotificationTestError.permissionDenied }
        switch kind {
        case .tomorrow:
            try await addIntervalNotification(
                identifier: "\(Self.developerTestIdentifierPrefix)tomorrow-\(UUID().uuidString)",
                seconds: 5,
                title: "明日は\(categoryName)の収集予定です",
                body: "地区設定に基づく通知テストです。実際の収集日はアプリで確認してください。"
            )
        case .morning:
            try await addIntervalNotification(
                identifier: "\(Self.developerTestIdentifierPrefix)morning-\(UUID().uuidString)",
                seconds: 5,
                title: "今日は\(categoryName)の収集予定です",
                body: "収集日当日の朝を想定したテスト通知です。"
            )
        }
    }

    func pendingRequests() async -> [UNNotificationRequest] {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
    }

    func cancelDeveloperTestNotifications() async {
        let pending = await pendingRequests()
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: pending.map(\.identifier).filter { $0.hasPrefix(Self.developerTestIdentifierPrefix) }
        )
    }

    func cancelAllPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
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

    private func addIntervalNotification(identifier: String, seconds: TimeInterval, title: String, body: String) async throws {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, seconds), repeats: false)
        try await UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: identifier, content: content, trigger: trigger))
    }

    private func previousDay(for date: Date, hour: Int) -> Date {
        let previous = Calendar.kadoma.date(byAdding: .day, value: -1, to: date) ?? date
        return Calendar.kadoma.date(bySettingHour: hour, minute: 0, second: 0, of: previous) ?? previous
    }

    private func sameDay(for date: Date, hour: Int, minute: Int) -> Date {
        Calendar.kadoma.date(bySettingHour: hour, minute: minute, second: 0, of: date) ?? date
    }

    private func notificationBody(for category: WasteCategory, event: CollectionEvent, prefix: String) -> String {
        if let note = event.note {
            return "\(prefix)\n\(note)\n地区設定に基づく通知です。変更がある場合は公式情報も確認してください。"
        }
        if let firstNote = category.notes.first {
            return "\(prefix)\n\(firstNote)\n地区設定に基づく通知です。変更がある場合は公式情報も確認してください。"
        }
        return "\(prefix)\n地区設定に基づく通知です。変更がある場合は公式情報も確認してください。"
    }
}

enum DeveloperNotificationKind: Equatable {
    case tomorrow
    case morning
}

enum DeveloperNotificationTestError: LocalizedError {
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "通知が許可されていません。iOS設定または通知許可ボタンから許可してください。"
        }
    }
}
