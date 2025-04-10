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
            .map { $0 } // Convert from ArraySlice to Array
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("🏆 Top Skills")
                .font(.title2)
                .fontWeight(.semibold)

            if topSkills.isEmpty {
                Text("No skills yet. Start tracking to see your top skills here!")
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

/// Compact progress bar used in Top Skills
struct ProgressBarCompact: View {
    let hours: Double

    var progressColor: Color {
        switch hours {
        case ..<0: return .trueGray
        case 0..<21: return .success
        case 21..<100: return .infoDark
        case 100..<1000: return .warningDark
        case 1000..<10000: return .danger
        default: return .dangerDark
        }
    }

    var progress: Double {
        switch hours {
        case ..<0: return 0
        case 0..<21: return hours / 21
        case 21..<100: return (hours - 21) / (100 - 21)
        case 100..<1000: return (hours - 100) / (1000 - 100)
        case 1000..<10000: return (hours - 1000) / (10000 - 1000)
        default: return 1
        }
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .frame(height: 10)
                    .foregroundColor(.gray.opacity(0.15))

                Capsule()
                    .frame(
                        width: geo.size.width * CGFloat(min(progress, 1)),
                        height: 10
                    )
                    .foregroundColor(progressColor)
                    .animation(.easeInOut(duration: 0.5), value: hours)
            }
        }
        .frame(height: 10)
    }
}
