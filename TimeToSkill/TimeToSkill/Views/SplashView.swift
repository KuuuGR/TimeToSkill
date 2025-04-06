//
//  SplashView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var glowRadius: CGFloat = 0
    @State private var cornerRadius: CGFloat = 0 // For animation
    
    private var transparentGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                .white.opacity(0.2),
                .white.opacity(0.05),
                .clear
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.08, green: 0.08, blue: 0.1)
                .ignoresSafeArea()
            
            // Circular logo with effects
            Image("app_logo")
                .resizable()
                .scaledToFit()
                .frame(width: min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.8) // Smaller for circle
                .clipShape(Circle()) // Makes it perfectly round
                .overlay(
                    Circle() // Circular overlay for gradient
                        .fill(transparentGradient)
                )
                .scaleEffect(logoScale)
                .opacity(logoOpacity)
                .shadow(color: .white.opacity(0.3), radius: glowRadius)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        .scaleEffect(logoScale * 1.1) // Slightly larger than logo
                )
                .onAppear {
                    // Initial state
                    logoOpacity = 0.0
                    logoScale = 0.8
                    glowRadius = 0
                    cornerRadius = 0
                    
                    // Animation sequence
                    withAnimation(.easeInOut(duration: 0.8)) {
                        logoOpacity = 0.2
                        cornerRadius = 100 // Animate to circle
                    }
                    
                    withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                        logoScale = 1.0
                        glowRadius = 15 // Smaller glow for circle
                    }
                    
                    withAnimation(.easeIn(duration: 0.5).delay(1.8)) {
                        logoOpacity = 0.7
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.easeOut(duration: 0.4)) {
                            isActive = true
                        }
                    }
                }
        }
        .fullScreenCover(isPresented: $isActive) {
            MainView()
        }
    }
}
