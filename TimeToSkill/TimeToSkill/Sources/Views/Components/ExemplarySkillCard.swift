//
//  ExemplarySkillCard.swift
//  TimeToSkill
//
//  Created by admin on 10/04/2025.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ExemplarySkillCard: View {
    let skill: ExemplarySkill
    let onTap: () -> Void
    
    private func loadUIImage() -> UIImage? {
        #if canImport(UIKit)
        let name = skill.imageName
        // If file exists at path, load from disk
        if FileManager.default.fileExists(atPath: name) {
            return UIImage(contentsOfFile: name)
        }
        // Else try asset image
        if let ui = UIImage(named: name) { return ui }
        return nil
        #else
        return nil
        #endif
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Image with star ribbon overlay
                ZStack {
                    // Main image: try file or asset first, fallback to SF Symbol
                    if let ui = loadUIImage() {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                            .saturation((skill.userRating ?? 0) == 0 ? 0 : 1)
                            .opacity((skill.userRating ?? 0) == 0 ? 0.6 : 1)
                            .frame(width: 80, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill((skill.userRating ?? 0) == 0 ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                            )
                    } else {
                        Image(systemName: UIImage(systemName: skill.imageName) != nil ? skill.imageName : "star.fill")
                            .font(.system(size: 40))
                            .foregroundColor((skill.userRating ?? 0) == 0 ? .gray : .primary)
                            .frame(width: 80, height: 80)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill((skill.userRating ?? 0) == 0 ? Color.gray.opacity(0.1) : Color.blue.opacity(0.1))
                            )
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
                
                // Star ribbon - positioned under the category
                if skill.isObtained {
                    StarRibbon(rating: max(0, min(3, skill.userRating ?? skill.difficultyLevel)))
                }
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
            // Ribbon background - more transparent
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.3))
                .frame(width: 44, height: 20)
            
            // Stars
            HStack(spacing: 3) {
                ForEach(1...3, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .font(.system(size: star == 2 ? 16 : 12)) // Center star (2) is bigger
                        .foregroundColor(star <= rating ? .yellow : .white.opacity(0.5))
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
