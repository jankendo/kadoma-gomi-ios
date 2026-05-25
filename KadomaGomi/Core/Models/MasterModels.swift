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
    let exceptionRules: [SpecialExceptionRule]?
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
    let sourceUrl: String?
    let confirmedAt: String?
    let confidence: String?
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
    let displayName: String?
    let kana: String?
    let aliases: [String]?
    let categoryId: String
    let keywords: [String]
    let notes: String
    let disposalGuide: String?
    let warnings: [String]?
    let isOversizedCandidate: Bool?
    let isHazardous: Bool?
    let requiresOfficialCheck: Bool?
    let source: String
    let sourceUrl: String?
    let confidence: Double
    let confidenceStatus: String?
    let updatedAt: String?

    var primaryName: String {
        displayName ?? names.first ?? id
    }

    var searchAliases: [String] {
        Array(Set((aliases ?? []) + Array(names.dropFirst()) + keywords + [kana].compactMap { $0 }))
    }

    var needsOfficialCheck: Bool {
        (requiresOfficialCheck ?? false) || confidence < 0.7 || confidenceStatus == "needs_review" || confidenceStatus == "estimated"
    }

    var hazardFlag: Bool {
        isHazardous ?? (categoryId == "hazardous_note")
    }

    var oversizedFlag: Bool {
        isOversizedCandidate ?? (categoryId == "bulky")
    }
}

struct Notice: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let monthHints: [Int]
    let sourceUrl: String?
    let confirmedAt: String?
    let confidence: String?
}

struct SpecialExceptionRule: Codable, Identifiable, Hashable {
    let id: String
    let areaIds: [String]
    let dateFrom: String
    let dateTo: String
    let type: String
    let affectedCategories: [String]
    let title: String
    let description: String
    let sourceUrl: String
    let confirmedAt: String
    let confidence: String
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

enum NotificationTiming: String, Hashable {
    case previousNight
    case sameMorning

    var label: String {
        switch self {
        case .previousNight:
            return "前日"
        case .sameMorning:
            return "当日朝"
        }
    }
}

struct NotificationPreview: Identifiable, Hashable {
    let id: String
    let eventDate: Date
    let fireDate: Date
    let categoryId: String
    let title: String
    let body: String
    let timing: NotificationTiming
}

struct UserSettings: Codable, Equatable {
    var addressText: String = "大倉町1-20"
    var areaId: String = "A"
    var hasCompletedOnboarding: Bool = false
    var previousNightNotificationEnabled: Bool = true
    var morningNotificationEnabled: Bool = true
    var yearEndNoticeEnabled: Bool = true
    var previousNightHour: Int = 20
    var morningHour: Int = 7
    var morningMinute: Int = 30
    var remoteManifestURL: String = "https://jankendo.github.io/kadoma-gomi-ios/manifest.json"
    var categoryNotificationOverrides: [String: Bool] = [:]
    var lastMasterCheckAt: String?
    var lastSuccessfulMasterRefreshAt: String?

    init() {}

    enum CodingKeys: String, CodingKey {
        case addressText
        case areaId
        case hasCompletedOnboarding
        case previousNightNotificationEnabled
        case morningNotificationEnabled
        case yearEndNoticeEnabled
        case previousNightHour
        case morningHour
        case morningMinute
        case remoteManifestURL
        case categoryNotificationOverrides
        case lastMasterCheckAt
        case lastSuccessfulMasterRefreshAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        addressText = try container.decodeIfPresent(String.self, forKey: .addressText) ?? "大倉町1-20"
        areaId = try container.decodeIfPresent(String.self, forKey: .areaId) ?? "A"
        hasCompletedOnboarding = try container.decodeIfPresent(Bool.self, forKey: .hasCompletedOnboarding) ?? false
        previousNightNotificationEnabled = try container.decodeIfPresent(Bool.self, forKey: .previousNightNotificationEnabled) ?? true
        morningNotificationEnabled = try container.decodeIfPresent(Bool.self, forKey: .morningNotificationEnabled) ?? true
        yearEndNoticeEnabled = try container.decodeIfPresent(Bool.self, forKey: .yearEndNoticeEnabled) ?? true
        previousNightHour = try container.decodeIfPresent(Int.self, forKey: .previousNightHour) ?? 20
        morningHour = try container.decodeIfPresent(Int.self, forKey: .morningHour) ?? 7
        morningMinute = try container.decodeIfPresent(Int.self, forKey: .morningMinute) ?? 30
        remoteManifestURL = try container.decodeIfPresent(String.self, forKey: .remoteManifestURL) ?? "https://jankendo.github.io/kadoma-gomi-ios/manifest.json"
        categoryNotificationOverrides = try container.decodeIfPresent([String: Bool].self, forKey: .categoryNotificationOverrides) ?? [:]
        lastMasterCheckAt = try container.decodeIfPresent(String.self, forKey: .lastMasterCheckAt)
        lastSuccessfulMasterRefreshAt = try container.decodeIfPresent(String.self, forKey: .lastSuccessfulMasterRefreshAt)
    }

    func notificationEnabled(for categoryId: String) -> Bool {
        categoryNotificationOverrides[categoryId] ?? true
    }
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
