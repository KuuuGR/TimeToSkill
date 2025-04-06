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
                .scaleEffect(circleScale)
                .animation(
                    .easeInOut(duration: 8).repeatForever(),
                    value: circleScale
                )
                .onAppear {
                    circleScale = 1.2
                }
                .blur(radius: 20)
                .offset(x: 50, y: -100) // Position it nicely
        }
    }
}
