//
//  TimeBudget.swift
//  TimeToSkill
//
//  A remaining-time balance that can grow or shrink while a direction is
//  active. Persistence stores a base value, a direction, and a timestamp so
//  the real elapsed time can be recovered after the app restarts. It is not
//  skill progress and never writes to `Skill.hours`.
//

import Foundation
import SwiftData

enum TimeBalanceDirection: Int, CaseIterable, Equatable {
    case stopped = 0
    case increasing = 1
    case decreasing = 2
}

enum TimeBalance {
    /// Seconds available right now from a persisted checkpoint.
    static func currentSeconds(
        storedSeconds: Int,
        direction: TimeBalanceDirection,
        activeStart: Date?,
        now: Date
    ) -> Int {
        let stored = max(0, storedSeconds)
        guard let start = activeStart, direction != .stopped else { return stored }
        let elapsed = now.timeIntervalSince(start)
        guard elapsed.isFinite, !elapsed.isNaN, elapsed > 0 else { return stored }
        let whole = Int(elapsed.rounded(.down))
        switch direction {
        case .increasing:
            let sum = stored.addingReportingOverflow(max(0, whole))
            return sum.overflow ? Int.max : max(0, sum.partialValue)
        case .decreasing:
            return max(0, stored - max(0, whole))
        case .stopped:
            return stored
        }
    }

    /// Legacy countdown helper kept for older call sites and tests.
    static func remaining(storedSeconds: Int, activeStart: Date?, now: Date) -> Int {
        currentSeconds(
            storedSeconds: storedSeconds,
            direction: activeStart == nil ? .stopped : .decreasing,
            activeStart: activeStart,
            now: now
        )
    }
}

@Model
final class TimeBudget {
    @Attribute(.unique) var id: UUID
    var title: String
    var symbol: String = ""
    /// Checkpoint seconds when the current direction began, or the resting value when stopped.
    var remainingSeconds: Int
    /// `TimeBalanceDirection.rawValue`. Missing/zero with a non-nil `activeStart` means decreasing (legacy).
    var directionRaw: Int = 0
    var activeStart: Date?
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        symbol: String = "",
        remainingSeconds: Int = 0,
        direction: TimeBalanceDirection = .stopped,
        activeStart: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.symbol = symbol
        self.remainingSeconds = max(0, remainingSeconds)
        self.directionRaw = direction.rawValue
        self.activeStart = direction == .stopped ? nil : activeStart
        self.updatedAt = Date()
    }

    var direction: TimeBalanceDirection {
        get {
            if let value = TimeBalanceDirection(rawValue: directionRaw) {
                if value == .stopped, activeStart != nil {
                    return .decreasing
                }
                return value
            }
            return activeStart != nil ? .decreasing : .stopped
        }
        set {
            directionRaw = newValue.rawValue
        }
    }

    func currentSeconds(at now: Date = .now) -> Int {
        TimeBalance.currentSeconds(
            storedSeconds: remainingSeconds,
            direction: direction,
            activeStart: activeStart,
            now: now
        )
    }

    /// Compatibility alias used by older views and tests.
    func remaining(at now: Date = .now) -> Int {
        currentSeconds(at: now)
    }

    func add(minutes: Int, at now: Date = .now) {
        guard minutes > 0 else { return }
        let next = currentSeconds(at: now)
        let sum = next.addingReportingOverflow(minutes * 60)
        remainingSeconds = sum.overflow ? Int.max : sum.partialValue
        if direction != .stopped {
            activeStart = now
        }
        updatedAt = now
    }

    func startIncreasing(at now: Date = .now) {
        remainingSeconds = currentSeconds(at: now)
        direction = .increasing
        activeStart = now
        updatedAt = now
    }

    func startDecreasing(at now: Date = .now) {
        remainingSeconds = currentSeconds(at: now)
        if remainingSeconds <= 0 {
            remainingSeconds = 0
            direction = .stopped
            activeStart = nil
        } else {
            direction = .decreasing
            activeStart = now
        }
        updatedAt = now
    }

    func stop(at now: Date = .now) {
        remainingSeconds = currentSeconds(at: now)
        direction = .stopped
        activeStart = nil
        updatedAt = now
    }

    /// Stops decreasing at zero. Returns `true` the moment the balance hits zero.
    @discardableResult
    func settle(at now: Date = .now) -> Bool {
        guard direction == .decreasing else { return false }
        if currentSeconds(at: now) > 0 { return false }
        remainingSeconds = 0
        direction = .stopped
        activeStart = nil
        updatedAt = now
        return true
    }

    /// Older single-button API: pause when running, otherwise start decreasing.
    func toggle(at now: Date = .now) {
        if direction != .stopped {
            stop(at: now)
        } else {
            startDecreasing(at: now)
        }
    }
}
