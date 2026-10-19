//
//  TimeBudget.swift
//  TimeToSkill
//
//  A remaining-time balance. It can grow when time is added and shrink while
//  a countdown runs. It is not skill progress and it never writes to `Skill.hours`.
//

import Foundation
import SwiftData

enum TimeBalance {
    /// Seconds still available. A running countdown counts down from the stored
    /// value and stops at zero. Skill hours are not an input.
    static func remaining(storedSeconds: Int, activeStart: Date?, now: Date) -> Int {
        let stored = max(0, storedSeconds)
        guard let start = activeStart else { return stored }
        let elapsed = now.timeIntervalSince(start)
        guard elapsed.isFinite, !elapsed.isNaN, elapsed > 0 else { return stored }
        return max(0, stored - Int(elapsed))
    }
}

@Model
final class TimeBudget {
    @Attribute(.unique) var id: UUID
    var title: String
    var symbol: String = ""
    /// Seconds left when the countdown is stopped.
    var remainingSeconds: Int
    var activeStart: Date?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        symbol: String = "",
        remainingSeconds: Int = 0,
        activeStart: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.remainingSeconds = max(0, remainingSeconds)
        self.activeStart = activeStart
        self.updatedAt = Date()
    }

    func remaining(at now: Date = .now) -> Int {
        TimeBalance.remaining(storedSeconds: remainingSeconds, activeStart: activeStart, now: now)
    }

    func add(minutes: Int) {
        guard minutes > 0 else { return }
        remainingSeconds = remaining(at: .now) + minutes * 60
        activeStart = nil
        updatedAt = Date()
    }

    func toggle(at now: Date = .now) {
        if activeStart != nil {
            remainingSeconds = remaining(at: now)
            activeStart = nil
        } else if remaining(at: now) > 0 {
            remainingSeconds = remaining(at: now)
            activeStart = now
        }
        updatedAt = now
    }
}
