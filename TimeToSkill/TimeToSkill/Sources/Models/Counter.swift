import Foundation
import SwiftData

@Model
final class Counter {
    @Attribute(.unique) var id: UUID
    var title: String
    var category: String
    var value: Int
    var step: Int // increment/decrement per tap
    var allowDecrement: Bool
    var thresholds: [Int] // e.g. [100, 200, 500, 10000, 30000, 3000000]
    var createdAt: Date
    var updatedAt: Date
    
    init(
        id: UUID = UUID(),
        title: String,
        category: String = "General",
        value: Int = 0,
        step: Int = 1,
        allowDecrement: Bool = true,
        thresholds: [Int] = []
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.value = max(0, value)
        self.step = max(1, step)
        self.allowDecrement = allowDecrement
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
