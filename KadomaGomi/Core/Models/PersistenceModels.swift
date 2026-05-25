import Foundation
import SwiftData

@Model
final class UserPreference {
    @Attribute(.unique) var key: String
    var value: String
    var updatedAt: Date

    init(key: String, value: String, updatedAt: Date = .now) {
        self.key = key
        self.value = value
        self.updatedAt = updatedAt
    }
}

@Model
final class CachedCollectionEvent {
    @Attribute(.unique) var eventId: String
    var date: Date
    var areaId: String
    var categoryId: String
    var note: String?
    var requiresReservation: Bool

    init(event: CollectionEvent) {
        self.eventId = event.id
        self.date = event.date
        self.areaId = event.areaId
        self.categoryId = event.categoryId
        self.note = event.note
        self.requiresReservation = event.requiresReservation
    }
}

