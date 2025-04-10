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
            Text(LocalizedStringKey("activity_log_title"))
                .font(.title2)
                .fontWeight(.semibold)

            if recentSkills.isEmpty {
                Text(LocalizedStringKey("activity_log_empty_message"))
                    .foregroundColor(.secondary)
                    .font(.footnote)
                    .padding(.top, 8)
            } else {
                ForEach(recentSkills, id: \.id) { skill in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(skill.name)
                                .font(.headline)

                            Text(dateFormatter.string(from: skill.lastUpdated))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text(formattedTime(skill.hours))
                            .font(.subheadline)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                    }
                    .padding(12)
                    .background(AppColors.surface)
                    .cornerRadius(10)
                    .shadow(color: .black.opacity(0.05), radius: 2, y: 1)
                }
            }
        }
    }

    private func formattedTime(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
}
