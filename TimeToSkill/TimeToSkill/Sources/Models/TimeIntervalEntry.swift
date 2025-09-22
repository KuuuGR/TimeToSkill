import Foundation
import SwiftData

enum TimeIntervalSource: String, Codable {
    case timer
    case manual
}

@Model
final class TimeIntervalEntry {
    @Attribute(.unique) var id: UUID
    var skillId: UUID
    var durationMinutes: Double // positive minutes
    var createdAt: Date
    var sourceRaw: String
    
    var source: TimeIntervalSource {
        get { TimeIntervalSource(rawValue: sourceRaw) ?? .timer }
        set { sourceRaw = newValue.rawValue }
    }
    
    init(id: UUID = UUID(), skillId: UUID, durationMinutes: Double, createdAt: Date = Date(), source: TimeIntervalSource) {
        self.id = id
        self.skillId = skillId
        self.durationMinutes = max(0, durationMinutes)
        self.createdAt = createdAt
        self.sourceRaw = source.rawValue
    }
}
