//
//  ExemplarySkill.swift
//  TimeToSkill
//
//  Created by admin on 10/04/2025.
//

import Foundation
import SwiftData

/// Represents an exemplary skill achievement that users can self-evaluate
@Model
final class ExemplarySkill {
    @Attribute(.unique) var id: UUID
    var title: String
    var skillDescription: String
    var imageName: String
    var category: String
    var difficultyLevel: Int // 1-3 stars
    var userRating: Int? // 1-3 stars (user's self-evaluation)
    var obtainedAt: Date?
    var verificationCode: String? // The password-like code used for verification
    var isObtained: Bool
    // var achievementHistory: [AchievementRecord] = [] // Track all achievement evaluations - temporarily disabled
    
    init(
        id: UUID = UUID(),
        title: String,
        skillDescription: String,
        imageName: String,
        category: String,
        difficultyLevel: Int,
        userRating: Int? = nil,
        obtainedAt: Date? = nil,
        verificationCode: String? = nil,
        isObtained: Bool = false
    ) {
        self.id = id
        self.title = title
        self.skillDescription = skillDescription
        self.imageName = imageName
        self.category = category
        self.difficultyLevel = max(1, min(3, difficultyLevel))
        self.userRating = userRating
        self.obtainedAt = obtainedAt
        self.verificationCode = verificationCode
        self.isObtained = isObtained
        // self.achievementHistory = [] // temporarily disabled
    }
}

/// Represents a single achievement evaluation record
struct AchievementRecord: Codable {
    let stars: Int // 0-3 stars
    let achievedAt: Date
    let verificationCode: String
    
    init(stars: Int, achievedAt: Date = Date(), verificationCode: String) {
        self.stars = max(0, min(3, stars))
        self.achievedAt = achievedAt
        self.verificationCode = verificationCode
    }
}

/// Constants for the exemplary skills system
struct ExemplarySkillConstants {
    static let verificationCodeLength = 12
    static let dailyEvaluationLimit = 5
    static let allowedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}|;:,.<>?"
}
