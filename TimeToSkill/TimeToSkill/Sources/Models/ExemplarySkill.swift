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
    // Catalog identity
    var catalogID: String? // Stable id for catalog items; nil for user-created
    var isUserCreated: Bool = false
    var isDeprecated: Bool = false
    
    // Catalog fields (safe to update by seeder)
    var title: String
    var skillDescription: String
    var imageName: String
    var category: String
    var difficultyLevel: Int // 1-10
    var oneStarDescription: String = ""
    var twoStarDescription: String = ""
    var threeStarDescription: String = ""
    
    // User fields (never overwritten by seeder)
    var userRating: Int? // 1-3 stars (user's self-evaluation)
    var obtainedAt: Date?
    var verificationCode: String? // The password-like code used for verification
    var isObtained: Bool
    var achievementHistory: [AchievementRecord] = [] // Track all evaluations
    
    init(
        id: UUID = UUID(),
        catalogID: String? = nil,
        isUserCreated: Bool = false,
        isDeprecated: Bool = false,
        title: String,
        skillDescription: String,
        imageName: String,
        category: String,
        difficultyLevel: Int,
        oneStarDescription: String = "",
        twoStarDescription: String = "",
        threeStarDescription: String = "",
        userRating: Int? = nil,
        obtainedAt: Date? = nil,
        verificationCode: String? = nil,
        isObtained: Bool = false
    ) {
        self.id = id
        self.catalogID = catalogID
        self.isUserCreated = isUserCreated
        self.isDeprecated = isDeprecated
        self.title = title
        self.skillDescription = skillDescription
        self.imageName = imageName
        self.category = category
        self.difficultyLevel = max(1, min(10, difficultyLevel))
        self.userRating = userRating
        self.obtainedAt = obtainedAt
        self.verificationCode = verificationCode
        self.isObtained = isObtained
        self.achievementHistory = []
        self.oneStarDescription = oneStarDescription
        self.twoStarDescription = twoStarDescription
        self.threeStarDescription = threeStarDescription
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
