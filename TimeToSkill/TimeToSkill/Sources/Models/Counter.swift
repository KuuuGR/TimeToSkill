import Foundation
import SwiftData

@Model
final class Counter {
    @Attribute(.unique) var id: UUID
    var title: String
    var category: String
    var value: Int // can be negative or positive
    var step: Int // signed per tap value
    var thresholds: [Int]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        category: String = "General",
        value: Int = 0,
        step: Int = 1,
        thresholds: [Int] = []
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.value = value
        self.step = step // allow negative or positive
        self.thresholds = thresholds.sorted()
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    var currentStageMax: Int? {
        guard !thresholds.isEmpty else { return nil }
        for limit in thresholds { if value < limit { return limit } }
        return thresholds.last
    }
}
