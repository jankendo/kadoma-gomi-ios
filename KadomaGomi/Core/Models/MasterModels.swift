import Foundation

struct MunicipalityMaster: Codable {
    let municipalityCode: String
    let municipalityName: String
    let targetAddressPreset: String
    let defaultAreaId: String
    let fiscalYear: Int
    let version: String
    let sourceUpdatedAt: String
    let generatedAt: String
    let sourcePages: [SourcePage]
    let areas: [CollectionArea]
    let categories: [WasteCategory]
    let itemDictionary: [WasteItem]
    let notices: [Notice]
}

struct SourcePage: Codable, Identifiable, Hashable {
    var id: String { url }
    let title: String
    let url: String
    let updatedAt: String
}

struct CollectionArea: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let towns: [TownRule]
    let schedules: [ScheduleRule]
    let exceptions: [CollectionException]
}

struct TownRule: Codable, Identifiable, Hashable {
    var id: String { "\(townName)-\(areaId)" }
    let townName: String
    let areaId: String
    let blockRange: String?
}

struct ScheduleRule: Codable, Identifiable, Hashable {
    let id: String
    let categoryId: String
    let recurrenceType: RecurrenceType
    let weekdays: [Int]?
    let weekOfMonth: [Int]?
    let specificDates: [String]?
    let validFrom: String
    let validTo: String
}

enum RecurrenceType: String, Codable {
    case weekly
    case monthlyNthWeekday
    case specificDates
}

struct CollectionException: Codable, Identifiable, Hashable {
    var id: String { "\(date)-\(areaId)-\(categoryId)-\(action.rawValue)" }
    let date: String
    let areaId: String
    let categoryId: String
    let action: CollectionExceptionAction
    let reason: String
}

enum CollectionExceptionAction: String, Codable {
    case add
    case cancel
    case note
}

struct WasteCategory: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let shortName: String
    let symbolName: String
    let colorHex: String
    let disposalRule: String
    let notes: [String]
    let defaultPreviousNightNotification: Bool
    let defaultMorningNotification: Bool
}

struct WasteItem: Codable, Identifiable, Hashable {
    let id: String
    let names: [String]
    let categoryId: String
    let keywords: [String]
    let notes: String
    let source: String
    let confidence: Double
}

struct Notice: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let monthHints: [Int]
}

struct CollectionEvent: Identifiable, Hashable {
    let date: Date
    let areaId: String
    let categoryId: String
    let note: String?
    let requiresReservation: Bool

    var id: String {
        "\(KadomaDateFormatter.dayKey.string(from: date))-\(areaId)-\(categoryId)"
    }
}

struct UserSettings: Codable, Equatable {
    var addressText: String = "大倉町1-20"
    var areaId: String = "A"
    var previousNightNotificationEnabled: Bool = true
    var morningNotificationEnabled: Bool = true
    var yearEndNoticeEnabled: Bool = true
    var previousNightHour: Int = 20
    var morningHour: Int = 7
    var morningMinute: Int = 30
    var remoteManifestURL: String = "https://jankendo.github.io/kadoma-gomi-ios/manifest.json"
}

struct MasterManifest: Codable {
    let municipalityCode: String
    let latestVersion: String
    let fiscalYear: Int
    let masterUrl: String
    let sha256: String
    let sourceUpdatedAt: String
    let generatedAt: String
    let requiresReview: Bool
    let message: String
}

