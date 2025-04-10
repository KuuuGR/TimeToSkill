//
//  TrackedTimeView.swift
//  TimeToSkill
//
//  Created by admin on 10/04/2025.
//

/// View to show tracked time for Week / Month / Total using Picker
import SwiftUI

struct TrackedTimeView: View {
    let skills: [Skill]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📅 Tracked Time")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                StatCard(
                    label: "Week",
                    value: String(format: "%.1f h", trackedHours(forDays: 7)),
                    subtext: percentageLabel(for: trackedHours(forDays: 7)),
                    color: .success
                )

                StatCard(
                    label: "Month",
                    value: String(format: "%.1f h", trackedHours(forDays: 30)),
                    subtext: percentageLabel(for: trackedHours(forDays: 30)),
                    color: .info
                )
            }

            HStack(spacing: 16) {
                StatCard(
                    label: "Total",
                    value: String(format: "%.1f h", totalHours),
                    subtext: "100%",
                    color: .gold
                )
            }
        }
    }
    

    private func trackedHours(forDays days: Int) -> Double {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        return skills
            .filter { $0.lastUpdated >= cutoffDate }
            .reduce(0) { $0 + $1.hours }
    }

    private var totalHours: Double {
        max(skills.reduce(0) { $0 + $1.hours }, 0.01)
    }

    private func percentageLabel(for hours: Double) -> String {
        let percentage = hours / totalHours * 100
        return String(format: "%.0f%%", percentage)
    }
}

