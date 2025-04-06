//
//  AppColors.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

extension Color {
    // Base colors
    static let timeDigit = Color.white
    static let smallBlue = Color(red: 0.0, green: 0.67, blue: 1.0)    // #00AAFF
    static let orange = Color(red: 1.0, green: 0.56, blue: 0.0)       // #FF8F00
    static let green = Color(red: 0.27, green: 1.0, blue: 0.34)       // #45FF57
    static let warmYellow = Color(red: 1.0, green: 0.75, blue: 0.13)  // #FFC021
}

struct AppColors {
    // Semantic colors
    static let primary = Color.smallBlue
    static let secondary = Color.orange
    static let tertiary = Color.green
    
    // Backgrounds
    static let background = Color(.systemBackground)
    static let surface = Color(.systemGray6)
    
    // Text colors
    static let onPrimary = Color.white       // Text on primary buttons
    static let onSecondary = Color.black     // Text on secondary buttons
    static let onSurface = Color.primary     // Main text color
    
    // Feedback
    static let error = Color(red: 0.9, green: 0.2, blue: 0.2)
}
