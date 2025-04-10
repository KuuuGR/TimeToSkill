//
//  ActivityLogView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 10/04/2025.
//

import SwiftUI

/// Displays recently edited skills with hours and date
struct ActivityLogView: View {
    let skills: [Skill]

    var recentSkills: [Skill] {
        Array(
            skills
                .sorted(by: { $0.lastUpdated > $1.lastUpdated })
                .prefix(3)
        )
    }

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📅 Activity Log")
                .font(.title2)
                .fontWeight(.semibold)

            ForEach(recentSkills, id: \.id) { skill in
                VStack(alignment: .leading, spacing: 4) {
                    Text(skill.name)
                        .font(.headline)

                    HStack {
                        Text("\(formattedTime(skill.hours))")
                        Spacer()
                        Text(dateFormatter.string(from: skill.lastUpdated))
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                .padding(.vertical, 4)
            }

            if recentSkills.isEmpty {
                Text("No recent activity.")
                    .foregroundColor(.secondary)
                    .font(.footnote)
            }
        }
    }

    private func formattedTime(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
}
