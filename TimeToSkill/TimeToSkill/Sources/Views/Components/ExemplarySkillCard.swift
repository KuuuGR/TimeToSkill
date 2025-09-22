//
//  ExemplarySkillCard.swift
//  TimeToSkill
//
//  Created by admin on 10/04/2025.
//

import SwiftUI

struct ExemplarySkillCard: View {
    let skill: ExemplarySkill
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Image with star ribbon overlay
                ZStack {
                    // Main image
                    Image(systemName: skill.imageName)
                        .font(.system(size: 40))
                        .foregroundColor(skill.isObtained ? .primary : .gray)
                        .frame(width: 80, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(skill.isObtained ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                        )
                    
                    // Star ribbon overlay
                    if skill.isObtained {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                StarRibbon(rating: skill.userRating ?? skill.difficultyLevel)
                                    .offset(x: 8, y: 8)
                            }
                        }
                    }
                }
                
                // Title
                Text(skill.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(skill.isObtained ? .primary : .secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                
                // Category badge
                Text(skill.category)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.secondary)
                    .cornerRadius(4)
            }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(skill.isObtained ? Color.blue.opacity(0.05) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(skill.isObtained ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct StarRibbon: View {
    let rating: Int
    
    var body: some View {
        ZStack {
            // Ribbon background
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.yellow.opacity(0.9))
                .frame(width: 24, height: 16)
            
            // Stars
            HStack(spacing: 2) {
                ForEach(1...3, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: 8))
                        .foregroundColor(star <= rating ? .orange : .gray)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ExemplarySkillCard(
            skill: ExemplarySkill(
                title: "Guitar Master",
                skillDescription: "Played guitar for 1000 hours",
                imageName: "guitars.fill",
                category: "Music",
                difficultyLevel: 3,
                userRating: 2,
                isObtained: true
            )
        ) {
            print("Tapped")
        }
        
        ExemplarySkillCard(
            skill: ExemplarySkill(
                title: "Language Learner",
                skillDescription: "Studied Spanish for 500 hours",
                imageName: "globe",
                category: "Language",
                difficultyLevel: 2,
                isObtained: false
            )
        ) {
            print("Tapped")
        }
    }
    .padding()
}
