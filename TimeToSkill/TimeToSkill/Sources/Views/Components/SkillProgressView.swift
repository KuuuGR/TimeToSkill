//
//  SkillProgressView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

/// Horizontal progress bar for a single skill
struct SkillProgressView: View {
    @Bindable var skill: Skill
    var isActive: Bool
    var onToggleTimer: () -> Void
    var onShowOptions: () -> Void

    /// Determines the color based on current learning stage
    internal var progressColor: Color {
        switch skill.hours {
        case ..<0:
            return .trueGray
        case 0..<21:
            return .success
        case 21..<100:
            return .infoDark
        case 100..<1000:
            return .warningDark
        case 1000..<10000:
            return .danger
        case 10000..<100000:
            return .purple
        default:
            return .black
        }
    }

    /// Computes cumulative progress within the current stage
    private var stageProgress: Double {
        let hours = skill.hours
        
        // Guard against NaN and infinite values
        guard hours.isFinite && !hours.isNaN else {
            return 0
        }
        
        switch hours {
        case ..<0:
            return 0
        case 0..<21:
            return hours / 21
        case 21..<100:
            return hours / 100
        case 100..<1000:
            return hours / 1000
        case 1000..<10000:
            return hours / 10000
        case 10000..<100000:
            return hours / 100000
        default:
            return 1
        }
    }

    /// Converts hours into human-friendly label
    private var formattedTimeLabel: String {
        let absHours = abs(skill.hours)
        let hours = Int(absHours)
        let minutes = Int((absHours - Double(hours)) * 60)
        let sign = skill.hours < 0 ? "-" : ""
        return "\(sign)\(hours)h \(minutes)m"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text(skill.name)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .lineLimit(1)
                    .truncationMode(.tail)

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

            // Time label
            Text(formattedTimeLabel)
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
