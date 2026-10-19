//
//  SkillCrystalBadge.swift
//  TimeToSkill
//
//  Reward shown only when an exemplary skill has been obtained.
//  It is not a progress bar and it does not encode hours or percent.
//

import SwiftUI

struct SkillCrystalBadge: View {
    var compact: Bool = false
    /// Hour-band crystal. Nil keeps the gold reward gem used on an obtained skill.
    var palette: CrystalPalette? = nil
    var accessibilityKey: LocalizedStringKey = "catalog_crystal_reward"

    var body: some View {
        CrystalGem(colors: palette?.gemColors ?? Self.rewardColors)
            .frame(width: compact ? 12 : 18, height: compact ? 16 : 24)
            .accessibilityLabel(Text(accessibilityKey))
    }

    private static let rewardColors = [
        Color(hex: "#FFF6D8"),
        Color(hex: "#F6CB65"),
        Color(hex: "#C58A27"),
        Color(hex: "#694419")
    ]
}

private struct CrystalGem: View {
    var colors: [Color]

    var body: some View {
        GemShape()
            .fill(
                LinearGradient(
                    colors: colors,
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(alignment: .top) {
                GemShape()
                    .fill(Color.white.opacity(0.45))
                    .frame(height: 7)
                    .mask(
                        LinearGradient(colors: [.white, .clear], startPoint: .top, endPoint: .bottom)
                    )
            }
            .overlay(
                GemShape()
                    .stroke(Color.white.opacity(0.55), lineWidth: 0.6)
            )
    }
}

private struct GemShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.38))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.38))
        path.closeSubpath()
        return path
    }
}
