import Foundation
import SwiftData

@Model
final class Counter {
    @Attribute(.unique) var id: UUID
    var title: String
    /// Optional emoji chosen from the shared picker. Empty means no symbol.
    var symbol: String = ""
    var category: String
    var value: Int // can be negative or positive
    var step: Int // signed per tap value
    private var thresholdsData: Data?
    var createdAt: Date
    var updatedAt: Date
    /// `manual` or `elapsedDays`. Existing rows stay manual.
    var kindRaw: String = CounterKind.manual.rawValue
    /// Start date for an elapsed-day counter. Unused by a manual counter.
    var anchorDay: Date? = nil
    
    init(
        id: UUID = UUID(),
        title: String,
        symbol: String = "",
        category: String = "General",
        value: Int = 0,
        step: Int = 1,
        thresholds: [Int] = []
    ) {
        self.id = id
        self.title = title
        self.symbol = symbol
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

    var kind: CounterKind {
        get { CounterKind(rawValue: kindRaw) ?? .manual }
        set { kindRaw = newValue.rawValue }
    }

    /// Recomputes an elapsed-day counter from its anchor and `now`.
    /// A manual counter, or one without an anchor, is left unchanged.
    /// Calling this twice with the same clock does not add the days again.
    @discardableResult
    func refreshFromAnchor(now: Date = .now, calendar: Calendar = .current) -> Bool {
        guard kind == .elapsedDays, let anchorDay else { return false }
        let start = calendar.startOfDay(for: anchorDay)
        let today = calendar.startOfDay(for: now)
        let days = calendar.dateComponents([.day], from: start, to: today).day ?? 0
        value = days
        updatedAt = now
        return true
    }

    /// Glass-bar fill for this counter. Zero and negative values leave an empty track.
    var barFraction: Double {
        let marks = [0.0] + thresholds.map(Double.init)
        guard marks.count >= 2 else { return 0 }
        return ProgressFill.fraction(value: Double(value), marks: marks)
    }

    var barPalette: CrystalPalette {
        let marks = [0.0] + thresholds.map(Double.init)
        let index = ProgressFill.bandIndex(value: Double(max(value, 0)), marks: marks)
        return CrystalPalette.ordered[min(index, CrystalPalette.ordered.count - 1)]
    }
}

enum CounterKind: String {
    case manual
    case elapsedDays
}
