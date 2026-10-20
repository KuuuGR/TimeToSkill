//
//  TrackedTimeView.swift
//  TimeToSkill
//
//  Created by admin on 10/04/2025.
//

import SwiftUI
import SwiftData

/// Tracked Time cards: rolling committed sessions (entries) + lifetime total (`Skill.hours`).
struct TrackedTimeView: View {
    let skills: [Skill]
    @Query private var entries: [TimeIntervalEntry]

    var body: some View {
        let lifetime = allTimeHours
        let last7 = committedHours(daysAgo: 7)
        let last30 = committedHours(daysAgo: 30)

        VStack(alignment: .leading, spacing: 16) {
            LText(key: "stats_tracked_time_title")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                StatCard(
                    label: L10n.string("stats_week_label"),
                    value: String(format: "%.1f h", last7),
                    subtext: TrackedTimeCalculation.percentageLabel(
                        periodHours: last7,
                        lifetimeHours: lifetime
                    ),
                    color: .success
                )

                StatCard(
                    label: L10n.string("stats_month_label"),
                    value: String(format: "%.1f h", last30),
                    subtext: TrackedTimeCalculation.percentageLabel(
                        periodHours: last30,
                        lifetimeHours: lifetime
                    ),
                    color: .info
                )
            }

            HStack(spacing: 16) {
                StatCard(
                    label: L10n.string("stats_total_label"),
                    value: String(format: "%.1f h", lifetime),
                    subtext: lifetime > 0 ? "100%" : "0%",
                    color: .gold
                )
            }
        }
    }

    /// Rolling window from `TimeIntervalEntry` only (timer + manual commits). Excludes active timers.
    private func committedHours(daysAgo days: Int) -> Double {
        guard let cutoff = TrackedTimeCalculation.cutoffDate(daysAgo: days) else { return 0 }
        let sessions = entries.map { ($0.createdAt, $0.durationMinutes) }
        return TrackedTimeCalculation.committedHours(sessions: sessions, since: cutoff)
    }

    /// All Time from persisted skill totals only.
    private var allTimeHours: Double {
        TrackedTimeCalculation.lifetimeHours(skills.map(\.hours))
    }
}
