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

    // Total hours (excluding active timers)
    var totalHours: Double {
        skills.reduce(0) { $0 + $1.hours }
    }

    // Number of skills
    var skillCount: Int {
        skills.count
    }

    // Count of active timers
    var activeTimers: Int {
        skills.filter { $0.activeStart != nil }.count
    }

    // Date of first tracked skill (based on lastUpdated)
    var firstSkillDate: Date? {
        skills.map(\.lastUpdated).min()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🧾 Summary")
                .font(.title2)
                .fontWeight(.semibold)

            HStack(spacing: 16) {
                StatCard(label: "Total Hours", value: formattedHours(totalHours))
                StatCard(label: "Skills", value: "\(skillCount)")
            }

            HStack(spacing: 16) {
                StatCard(label: "Active Timers", value: "\(activeTimers)")
                if let date = firstSkillDate {
                    StatCard(label: "First Tracked", value: formatted(date: date))
                } else {
                    StatCard(label: "First Tracked", value: "-")
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

struct StatCard: View {
    let label: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(AppColors.primary)
            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
        .shadow(radius: 2, y: 1)
    }
}
