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
    
    // Progress color based on hours
    internal var progressColor: Color {
        switch skill.hours {
        case ..<21: return .green.opacity(0.7)
        case 21..<100: return .orange.opacity(0.7)
        default: return .red.opacity(0.7)
        }
    }
    
    var body: some View {
        VStack {
            // Editable name
            TextField("Skill Name", text: $skill.name)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            // Progress vial
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .frame(width: geo.size.width)
                        .foregroundColor(.gray.opacity(0.2))
                    
                    Capsule()
                        .frame(
                            width: geo.size.width * CGFloat(min(skill.hours / 1000, 1)),
                            height: 25
                        )
                        .foregroundColor(progressColor)
                }
            }
            .frame(height: 25)
            
            // Timer button
            Button(action: onToggleTimer) {
                Text(isActive ? "Stop" : "Start")
                    .frame(width: 100)
            }
            .buttonStyle(.borderedProminent)
            
            Text("\(skill.hours, specifier: "%.1f") hours")
                .font(.caption)
        }
        .padding()
        .background(.regularMaterial)
        .cornerRadius(15)
    }
}
