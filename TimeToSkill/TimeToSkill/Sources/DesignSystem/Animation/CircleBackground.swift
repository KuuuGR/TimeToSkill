//
//  CircleBackground.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

struct CircleBackground: View {
    @State private var circleScale: CGFloat = 0.8
    private let baseColor = AppColors.primary.opacity(0.1)
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            Circle()
                .fill(baseColor)
                .scaleEffect(max(0.1, min(2.0, circleScale)))
                .animation(
                    .easeInOut(duration: 8).repeatForever(),
                    value: circleScale
                )
                .onAppear {
                    circleScale = 1.2
                    guard circleScale.isFinite && !circleScale.isNaN else { 
                        circleScale = 1.0
                        return
                    }
                }
                .blur(radius: 20)
                .offset(x: 50, y: -100) // Position it nicely
        }
    }
}
