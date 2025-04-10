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
        skills.reduce(0) { $0 + $1.hours }
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
                StatCard(label: "This Week", value: String(format: "%.1f", weekHours))
                StatCard(label: "This Month", value: String(format: "%.1f", monthHours))
            }

            StatCard(label: "Total", value: String(format: "%.1f", totalHours))
                .frame(maxWidth: .infinity)
        }
    }
}
