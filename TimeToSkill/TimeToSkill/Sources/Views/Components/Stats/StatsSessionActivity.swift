import Foundation

/// Pure helpers for Activity Log + First Session (Phase 03B). Read-only — no persistence.
enum StatsSessionActivity {
    struct SessionRow: Equatable {
        let id: UUID
        let skillId: UUID
        let skillName: String
        let durationMinutes: Double
        let createdAt: Date
    }

    /// Latest committed sessions only (timer + manual). No running timers.
    static func recentSessions(
        entries: [(id: UUID, skillId: UUID, durationMinutes: Double, createdAt: Date)],
        skillNames: [UUID: String],
        limit: Int = 5
    ) -> [SessionRow] {
        guard limit > 0 else { return [] }
        return entries
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(limit)
            .map { entry in
                SessionRow(
                    id: entry.id,
                    skillId: entry.skillId,
                    skillName: skillNames[entry.skillId] ?? "—",
                    durationMinutes: max(0, entry.durationMinutes),
                    createdAt: entry.createdAt
                )
            }
    }

    /// Earliest committed session timestamp, if any.
    static func firstSessionDate(
        createdAtDates: [Date]
    ) -> Date? {
        createdAtDates.min()
    }

    static func formattedDuration(minutes: Double) -> String {
        let safe = minutes.isFinite && !minutes.isNaN ? max(0, minutes) : 0
        let totalMinutes = Int(safe)
        let h = totalMinutes / 60
        let m = totalMinutes % 60
        return "\(h)h \(m)m"
    }
}
