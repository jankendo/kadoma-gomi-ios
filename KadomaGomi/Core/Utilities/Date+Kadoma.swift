import Foundation

extension Calendar {
    static var kadoma: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.timeZone = TimeZone(identifier: "Asia/Tokyo") ?? .current
        calendar.firstWeekday = 2
        return calendar
    }

    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}

enum KadomaDateFormatter {
    static let dayKey: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .kadoma
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = Calendar.kadoma.timeZone
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static let displayDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .kadoma
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = Calendar.kadoma.timeZone
        formatter.dateFormat = "M/d(E)"
        return formatter
    }()

    static let monthTitle: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .kadoma
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = Calendar.kadoma.timeZone
        formatter.dateFormat = "yyyy年M月"
        return formatter
    }()

    static let timestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .kadoma
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = Calendar.kadoma.timeZone
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter
    }()
}
