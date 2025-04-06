//
//  StartView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI
import SwiftData

/// Shows skill vials with progress tracking
struct StartView: View {
    @Environment(\.modelContext) private var context
    @Query private var skills: [Skill]  // Auto-fetched from SwiftData
    
    @State private var activeTimer: Skill?
    @State private var startTime: Date?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(skills) { skill in
                    SkillProgressView(skill: skill,
                                    isActive: activeTimer == skill) {
                        toggleTimer(for: skill)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            if skills.isEmpty {
                // Add default skills on first launch
                context.insert(Skill(name: "Guitar"))
                context.insert(Skill(name: "Spanish"))
            }
        }
    }
    
    private func toggleTimer(for skill: Skill) {
        if activeTimer == skill {
            // Stop timer and save
            skill.hours += Date().timeIntervalSince(startTime ?? Date()) / 3600
            activeTimer = nil
        } else {
            // Start new session
            activeTimer = skill
            startTime = Date()
        }
    }
}
