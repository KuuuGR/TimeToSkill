import Foundation
import SwiftData

@Model
final class Counter {
    @Attribute(.unique) var id: UUID
    var title: String
    var category: String
    var value: Int // can be negative or positive
    var step: Int // signed per tap value
    private var thresholdsData: Data?
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
        self.createdAt = Date()
        self.updatedAt = Date()
        self.thresholds = thresholds
    }
    
    // Computed API for thresholds
    var thresholds: [Int] {
        get {
            guard let data = thresholdsData, let arr = try? JSONDecoder().decode([Int].self, from: data) else { return [] }
            return arr
        }
        set {
            let sorted = newValue.sorted()
            thresholdsData = try? JSONEncoder().encode(sorted)
        }
    }
    
    var currentStageMax: Int? {
        let limits = thresholds
        guard !limits.isEmpty else { return nil }
        for limit in limits { if value < limit { return limit } }
        return limits.last
    }
}
