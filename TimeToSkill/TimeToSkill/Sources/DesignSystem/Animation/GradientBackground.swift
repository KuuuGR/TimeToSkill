//
//  GradientBackground.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

// Sources/DesignSystem/Animation/GradientBackground.swift
import SwiftUI

public struct GradientBackground: View {
    @State private var start = UnitPoint(x: 0, y: 0)
    @State private var end = UnitPoint(x: 1, y: 1)
    
    let colors: [Color]
    let duration: Double
    
    public init(colors: [Color], duration: Double = 8.0) {
        self.colors = colors
        self.duration = duration
    }
    
    public var body: some View {
        LinearGradient(
            gradient: Gradient(colors: colors),
            startPoint: start,
            endPoint: end
        )
        .ignoresSafeArea()
        .onAppear {
            withAnimation(
                .easeInOut(duration: duration)
                .repeatForever(autoreverses: true)
            ) {
                start = UnitPoint(x: 1, y: 1)
                end = UnitPoint(x: 0, y: 0)
            }
        }
    }
}

struct GradientBackground_Previews: PreviewProvider {
    static var previews: some View {
        GradientBackground(colors: [
            AppColors.primary.opacity(0.3),
            AppColors.secondary.opacity(0.2),
            AppColors.surface.opacity(0.5)
        ])
    }
}
