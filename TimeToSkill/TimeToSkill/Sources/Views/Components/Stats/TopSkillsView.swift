//
//  TopSkillsView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 10/04/2025.
//

import SwiftUI

/// Displays the top 3 skills with the highest number of hours
struct TopSkillsView: View {
    let skills: [Skill]

    var topSkills: [Skill] {
        skills
            .sorted(by: { $0.hours > $1.hours })
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(LocalizedStringKey("stats_top_skills_title"))
                .font(.title2)
                .fontWeight(.semibold)

            if topSkills.isEmpty {
                Text(LocalizedStringKey("stats_top_skills_empty_msg"))
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(topSkills) { skill in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(skill.name)
                                .font(.headline)
                                .foregroundColor(AppColors.onSurface)

                            Spacer()

                            Text(formattedHours(skill.hours))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        ProgressBarCompact(hours: skill.hours)
                    }
                }
            }
        }
    }

    private func formattedHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }
}
