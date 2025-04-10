//
//  FABButton.swift
//  TimeToSkill
//

import SwiftUI

struct FABButton: View {
    let icon: String
    let action: () -> Void
    var backgroundColor: Color = AppColors.primary
    var size: CGFloat = 56
    var animatePulse: Bool = false

    @State private var animatedOnce = false
    @State private var isAnimating = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title.weight(.bold))
                .foregroundColor(AppColors.onPrimary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    backgroundColor.opacity(0.95),
                                    backgroundColor.opacity(0.7)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .scaleEffect(isAnimating ? 1.25 : 1.0)
                .opacity(isAnimating ? 0.6 : 0.3)
                .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .onAppear {
            // Run a one-time gentle animation
            if animatePulse && !animatedOnce {
                animatedOnce = true
                withAnimation(.easeInOut(duration: 1.0)) {
                    isAnimating = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut(duration: 0.6)) {
                        isAnimating = false
                    }
                }
            }
        }
    }
}
