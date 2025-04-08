//
//  SkillProgressView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

/// Horizontal progress vial for a single skill
struct SkillProgressView: View {
    @Bindable var skill: Skill
    var isActive: Bool
    var onToggleTimer: () -> Void
    var onShowOptions: () -> Void  // 👈 new

    /// Determines the color based on current learning stage
    private var progressColor: Color {
        switch skill.hours {
        case ..<21: return AppColors.tertiary     // Green
        case ..<100: return AppColors.secondary   // Orange
        case ..<1000: return AppColors.primary    // Blue
        default: return AppColors.error           // Red
        }
    }

    /// Computes progress within the current stage
    private var stageProgress: Double {
        switch skill.hours {
        case ..<21:
            return skill.hours / 21
        case ..<100:
            return (skill.hours - 21) / (100 - 21)
        case ..<1000:
            return (skill.hours - 100) / (1000 - 100)
        default:
            return min((skill.hours - 1000) / (10000 - 1000), 1)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                TextField("Skill Name", text: $skill.name)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Button(action: onShowOptions) {
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90)) // ⋯ horizontally
                        .padding(.leading, 4)
                }
                .accessibilityIdentifier("OptionsButton_\(skill.id.hashValue)")
            }

            // Animated progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .frame(height: 25)
                        .foregroundColor(.gray.opacity(0.15))

                    Capsule()
                        .frame(
                            width: geo.size.width * CGFloat(min(stageProgress, 1)),
                            height: 25
                        )
                        .foregroundColor(progressColor)
                        .animation(.easeInOut(duration: 0.6), value: skill.hours)
                }
            }
            .frame(height: 25)

            // Timer button
            Button(action: onToggleTimer) {
                Text(isActive ? "Stop" : "Start")
                    .font(.subheadline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(isActive ? Color.red.opacity(0.2) : Color.blue.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier(isActive ? "StopButton_\(skill.id.hashValue)" : "StartButton_\(skill.id.hashValue)")

            let totalHours = skill.hours
            let hours = Int(totalHours)
            let minutes = Int((totalHours - Double(hours)) * 60)
            Text("\(hours) hours \(minutes) minutes")
                .font(.caption)
                .accessibilityIdentifier("SkillProgressLabel_\(skill.id.hashValue)")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
