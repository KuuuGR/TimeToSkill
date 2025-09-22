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
    }
}

/// Constants for the exemplary skills system
struct ExemplarySkillConstants {
    static let verificationCodeLength = 12
    static let dailyEvaluationLimit = 5
    static let allowedCharacters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*()_+-=[]{}|;:,.<>?"
}
