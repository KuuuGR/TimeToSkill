//
//  StaticCircleBackground.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//
import SwiftUI

struct StaticCircleBackground: View {
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            Circle()
                .fill(AppColors.primary.opacity(0.08))
                .frame(width: 300)
                .blur(radius: 30)
                .offset(x: 100, y: -150)
        }
    }
}
