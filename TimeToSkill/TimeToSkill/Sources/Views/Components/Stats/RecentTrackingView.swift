//
//  RecentTrackingView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 10/04/2025.
//

import SwiftUI

/// Displays time tracked recently (last 7 and 30 days)
struct RecentTrackingView: View {
    let skills: [Skill]

    var last7DaysTotal: Double {
        totalHours(since: Calendar.current.date(byAdding: .day, value: -7, to: Date())!)
    }

    var last30DaysTotal: Double {
        totalHours(since: Calendar.current.date(byAdding: .day, value: -30, to: Date())!)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("⏳ Recent Tracking")
                .font(.title2)
                .fontWeight(.semibold)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Week")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formattedLabel(for: last7DaysTotal))
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("This Month")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(formattedLabel(for: last30DaysTotal))
                        .font(.headline)
                }
            }
        }
    }

    private func totalHours(since date: Date) -> Double {
        skills
            .filter { $0.lastUpdated >= date }
            .map(\.hours)
            .reduce(0, +)
    }

    private func formattedLabel(for hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
}
