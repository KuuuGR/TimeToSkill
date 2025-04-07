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

    internal var progressColor: Color {
        switch skill.hours {
        case ..<21: return .green.opacity(0.7)
        case 21..<100: return .orange.opacity(0.7)
        default: return .red.opacity(0.7)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Editable name
            TextField("Skill Name", text: $skill.name)
                .font(.headline)
                .multilineTextAlignment(.center)

            // Animated progress vial
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .frame(height: 25)
                        .foregroundColor(.gray.opacity(0.15))

                    Capsule()
                        .frame(
                            width: geo.size.width * CGFloat(min(skill.hours / 1000, 1)),
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

            Text("\(skill.hours, specifier: "%.1f") hours")
                .font(.caption)
                .accessibilityIdentifier("SkillProgressLabel")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}
