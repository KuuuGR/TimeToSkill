//
//  StatsSummaryView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 10/04/2025.
//

import SwiftUI

/// Summary block with total hours, skill count, active timers, and first skill date
struct StatsSummaryView: View {
    let skills: [Skill]

    var totalHours: Double {
        skills.reduce(0) { $0 + $1.hours }
    }

    var skillCount: Int {
        skills.count
    }

    var activeTimers: Int {
        skills.filter { $0.activeStart != nil }.count
    }

    var firstSkillDate: Date? {
        skills.map(\.lastUpdated).min()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey("stats_summary_title"))
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                StatCard(
                    label: NSLocalizedString("stats_total_hours", comment: ""),
                    value: formattedHours(totalHours)
                )
                StatCard(
                    label: NSLocalizedString("stats_skill_count", comment: ""),
                    value: "\(skillCount)"
                )
            }

            HStack(spacing: 16) {
                StatCard(
                    label: NSLocalizedString("stats_active_timers", comment: ""),
                    value: "\(activeTimers)"
                )
                if let date = firstSkillDate {
                    StatCard(
                        label: NSLocalizedString("stats_first_tracked", comment: ""),
                        value: formatted(date: date)
                    )
                } else {
                    StatCard(
                        label: NSLocalizedString("stats_first_tracked", comment: ""),
                        value: "-"
                    )
                }
            }
        }
    }

    private func formatted(date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private func formattedHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
}
