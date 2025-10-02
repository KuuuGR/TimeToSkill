//
//  FancyButtonStyle.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 10/04/2025.
//

import SwiftUI

struct FancyButtonStyle: ButtonStyle {
    var background: Color
    var gradientEnd: Color
    var cornerRadius: CGFloat = 14
    var shadow: Color = .black.opacity(0.1)
    var shadowRadius: CGFloat = 6

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .foregroundColor(AppColors.onPrimary)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [background, gradientEnd]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: shadow, radius: shadowRadius, x: 0, y: 4)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}
