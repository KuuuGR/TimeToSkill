//
//  AppBackground.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

struct AppBackground: View {
    let animationType: BackgroundAnimationType
    
    var body: some View {
        switch animationType {
        case .none:
            AppColors.background
                .ignoresSafeArea()
            
        case .circleBackground:
            CircleBackground()
            
        case .staticCircle:
            StaticCircleBackground()
            
        case .gentlePulse:
            PulseCircleBackground()
            
        case .animatedGradient:
            GradientBackground(colors: [
                AppColors.background,
                AppColors.primary.opacity(0.1)
            ], duration: 15.0)
        }
    }
}
