//
//  BrandMark.swift
//  TimeToSkill
//
//  Small reusable brand element: the app icon artwork plus (optionally) the app
//  wordmark. Shared by the splash screen, the iOS hero and the macOS sidebar so
//  the brand is presented consistently on both platforms.
//

import SwiftUI

struct BrandMark: View {
    /// Edge length of the icon. Keep it small - this is a brand marker, not a hero image.
    var size: CGFloat = 28
    var showsWordmark: Bool = true
    var wordmarkFont: Font = .headline
    var wordmarkColor: Color = AppColors.onSurface
    var cornerRadiusRatio: CGFloat = 0.24
    /// Draws a thin accent-coloured edge around the icon. Turn it off on
    /// surfaces where the artwork should float on its own (e.g. About).
    var showsBorder: Bool = true

    private var cornerRadius: CGFloat { size * cornerRadiusRatio }

    var body: some View {
        HStack(spacing: max(6, size * 0.28)) {
            Image("app_logo")
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .overlay(
                    Group {
                        if showsBorder {
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(AppColors.accent.opacity(0.35), lineWidth: 1)
                        }
                    }
                )
                .accessibilityHidden(true)

            if showsWordmark {
                Text("ab_app_name")
                    .font(wordmarkFont)
                    .foregroundColor(wordmarkColor)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("ab_app_name"))
    }
}

#Preview {
    VStack(spacing: 24) {
        BrandMark(size: 28)
        BrandMark(size: 56, showsWordmark: false)
        BrandMark(size: 32, wordmarkFont: .title2.bold())
    }
    .padding()
}
