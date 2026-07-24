import Foundation

/// Pure helpers for Tracked Time cards (Phase 03A). Read-only math — no persistence.
enum TrackedTimeCalculation {
    /// Sum of committed session durations in hours for entries with `createdAt >= cutoff`.
    static func committedHours(
        sessions: [(createdAt: Date, durationMinutes: Double)],
        since cutoff: Date
    ) -> Double {
        let minutes = sessions
            .filter { $0.createdAt >= cutoff }
            .reduce(0.0) { $0 + max(0, $1.durationMinutes) }
        let hours = minutes / 60.0
        guard hours.isFinite && !hours.isNaN else { return 0 }
        return hours
    }

    /// Lifetime total from persisted `Skill.hours`.
    static func lifetimeHours(_ skillHours: [Double]) -> Double {
        let total = skillHours.reduce(0, +)
        guard total.isFinite && !total.isNaN else { return 0 }
        return total
    }

    /// Period as percent of lifetime. Explicit zero-lifetime handling; no artificial floors.
    static func percentageLabel(periodHours: Double, lifetimeHours: Double) -> String {
        guard periodHours.isFinite, !periodHours.isNaN,
              lifetimeHours.isFinite, !lifetimeHours.isNaN,
              lifetimeHours > 0 else {
            return "0%"
        }
        let percentage = periodHours / lifetimeHours * 100
        guard percentage.isFinite && !percentage.isNaN else {
            return "0%"
        }
        let capped = min(percentage, 100)
        return String(format: "%.0f%%", capped)
    }

    static func cutoffDate(daysAgo days: Int, from now: Date = Date(), calendar: Calendar = .current) -> Date? {
        calendar.date(byAdding: .day, value: -days, to: now)
    }
}
