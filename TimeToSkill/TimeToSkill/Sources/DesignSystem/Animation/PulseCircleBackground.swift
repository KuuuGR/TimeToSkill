//
//  PulseCircleBackground.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

public struct PulseCircleBackground: View {
    @State private var scale: CGFloat = 0.95
    
    public var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            Circle()
                .fill(AppColors.primary.opacity(0.1))
                .scaleEffect(scale)
                .animation(
                    .easeInOut(duration: 8).repeatForever(),
                    value: scale
                )
                .onAppear { scale = 1.05 }
                .blur(radius: 25)
                .offset(x: 80, y: -120)
        }
    }
}
