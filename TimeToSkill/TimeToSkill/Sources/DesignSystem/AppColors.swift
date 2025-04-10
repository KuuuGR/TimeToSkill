//
//  AppColors.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

// MARK: - Color Extension with Bootstrap / MDB Colors + Hex Support

extension Color {
    // Base app-specific colors
    static let timeDigit = Color.white
    static let smallBlue = Color(red: 0.0, green: 0.67, blue: 1.0)    // #00AAFF
    static let orange = Color(red: 1.0, green: 0.56, blue: 0.0)       // #FF8F00
    static let green = Color(red: 0.27, green: 1.0, blue: 0.34)       // #45FF57
    static let warmYellow = Color(red: 1.0, green: 0.75, blue: 0.13)  // #FFC021
    static let gold = Color(hex: "#D4AF37")                           // True gold
    static let darkGold = Color(hex: "#B29600")                      // Slightly darker gold
    static let trueGray = Color.gray.opacity(0.6)                    // Neutral for negatives

    // Bootstrap Colors
    static let danger = Color(hex: "#ff4444")       // Light red
    static let dangerDark = Color(hex: "#cc0000")   // Strong red
    static let warning = Color(hex: "#ffbb33")      // Light orange
    static let warningDark = Color(hex: "#ff8800")  // Deep orange
    static let success = Color(hex: "#00c851")      // Bright green
    static let successDark = Color(hex: "#007e33")  // Dark green
    static let info = Color(hex: "#33b5e5")         // Sky blue
    static let infoDark = Color(hex: "#0099cc")     // Deep blue

    // Material Design (MDB) Colors
    static let mdbTeal = Color(hex: "#00bfa5")
    static let mdbBlue = Color(hex: "#4285f4")
    static let mdbPurple = Color(hex: "#9c27b0")

    // Helper: initialize color from hex string
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int = UInt64()
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: // RGB (24-bit)
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (255, 255, 0) // fallback = yellow
        }
        self.init(
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0
        )
    }
}

// MARK: - App Semantic Colors

struct AppColors {
    static let primary = Color.smallBlue
    static let secondary = Color.orange
    static let tertiary = Color.green

    static let background = Color(.systemBackground)
    static let surface = Color(.systemGray6)

    static let onPrimary = Color.white
    static let onSecondary = Color.black
    static let onSurface = Color.primary

    static let error = Color.dangerDark
}
