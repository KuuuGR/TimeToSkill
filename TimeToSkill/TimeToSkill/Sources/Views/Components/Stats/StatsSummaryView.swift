//
//  StatsSummaryView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 10/04/2025.
//

import SwiftUI
import SwiftData

/// Summary block with total hours, skill count, active timers, and first session date
struct StatsSummaryView: View {
    let skills: [Skill]
    @Query private var entries: [TimeIntervalEntry]

    var totalHours: Double {
        skills.reduce(0) { $0 + $1.hours }
    }

    var skillCount: Int {
        skills.count
    }

    var activeTimers: Int {
        skills.filter { $0.activeStart != nil }.count
    }

    var firstSessionDate: Date? {
        StatsSessionActivity.firstSessionDate(createdAtDates: entries.map(\.createdAt))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            LText(key: "stats_summary_title")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                StatCard(
                    label: L10n.string("stats_total_hours"),
                    value: formattedHours(totalHours)
                )
                StatCard(
                    label: L10n.string("stats_skill_count"),
                    value: "\(skillCount)"
                )
            }

            HStack(spacing: 16) {
                StatCard(
                    label: L10n.string("stats_active_timers"),
                    value: "\(activeTimers)"
                )
                if let date = firstSessionDate {
                    StatCard(
                        label: L10n.string("stats_first_tracked"),
                        value: formatted(date: date)
                    )
                } else {
                    StatCard(
                        label: L10n.string("stats_first_tracked"),
                        value: "—"
                    )
                }
            }
        }
    }

    private func formatted(date: Date) -> String {
        L10n.mediumDate(date)
    }

    private func formattedHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
}
