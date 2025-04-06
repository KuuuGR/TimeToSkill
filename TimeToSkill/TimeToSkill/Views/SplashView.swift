//
//  SplashView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var scale: CGFloat = 0.5
    @State private var opacity = 0.0
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Dark background
            Color("Background")
                .ignoresSafeArea()
            
            // Logo with combined effects
            Image("app_logo")
                .resizable()
                .scaledToFit()
                .frame(width: calculateLogoSize())
                .opacity(opacity)
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotation))
                .onAppear {
                    // Sequence animations
                    withAnimation(.easeIn(duration: 0.5)) {
                        opacity = 1.0
                    }
                    
                    withAnimation(.interpolatingSpring(stiffness: 100, damping: 10).delay(0.3)) {
                        scale = 1.2  // Overshoot slightly
                    }
                    
                    withAnimation(.linear(duration: 1.5).delay(0.5)) {
                        rotation = 360
                        scale = 1.0  // Return to normal
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            isActive = true
                        }
                    }
                }
        }
    }
    
    private func calculateLogoSize() -> CGFloat {
        #if os(iOS)
        let screenSize = min(UIScreen.main.bounds.width, UIScreen.main.bounds.height)
        return screenSize * 0.7  // 70% of smallest screen dimension
        #else
        return 300  // Fallback for other platforms
        #endif
    }
}
