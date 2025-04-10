//
//  TrackedTimeView.swift
//  TimeToSkill
//
//  Created by admin on 10/04/2025.
//

import SwiftUI

/// Shows how much time was tracked in the past week, month, and in total
struct TrackedTimeView: View {
    let skills: [Skill]

    var totalHours: Double {
        max(skills.reduce(0) { $0 + $1.hours }, 0.01) // prevent division by zero
    }

    var weekHours: Double {
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        return skills
            .filter { $0.lastUpdated >= weekAgo }
            .reduce(0) { $0 + $1.hours }
    }

    var monthHours: Double {
        let monthAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return skills
            .filter { $0.lastUpdated >= monthAgo }
            .reduce(0) { $0 + $1.hours }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📅 Tracked Time")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                StatCard(
                    label: "This Week",
                    value: String(format: "%.1f h", weekHours),
                    subtext: String(format: "%.0f%%", (weekHours / totalHours) * 100),
                    color: .success
                )

                StatCard(
                    label: "This Month",
                    value: String(format: "%.1f h", monthHours),
                    subtext: String(format: "%.0f%%", (monthHours / totalHours) * 100),
                    color: .info
                )
            }

            StatCard(
                label: "Total",
                value: String(format: "%.1f h", totalHours),
                subtext: "100%",
                color: .gold
            )
            .frame(maxWidth: .infinity)
        }
    }
}
