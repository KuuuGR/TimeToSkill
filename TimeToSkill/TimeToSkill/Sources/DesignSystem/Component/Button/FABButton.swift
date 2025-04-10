//
//  FABButton.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

struct FABButton: View {
    let icon: String
    let action: () -> Void
    var backgroundColor: Color = AppColors.primary
    var size: CGFloat = 56

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title.weight(.bold))
                .foregroundColor(AppColors.onPrimary)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
