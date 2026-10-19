//
//  CrystalProgressBar.swift
//  TimeToSkill
//
//  Glass progress fill. The palette follows the existing hour-stage colors.
//  It is not a reward and it does not change because a crystal was earned.
//

import SwiftUI

enum CrystalPalette: Equatable {
    case emerald
    case sapphire
    case amber
    case crimson
    case arcane

    /// Hour bands. Arcane is the multi-hue crystal and comes before crimson,
    /// matching the palette order sapphire, amber, arcane, crimson.
    /// An earlier mapping followed the old red-then-purple stage colors and
    /// put those two crystals on the wrong thresholds.
    static func forHours(_ hours: Double) -> CrystalPalette? {
        guard hours.isFinite, !hours.isNaN, hours >= 0 else { return nil }
        switch hours {
        case 0..<21: return .emerald
        case 21..<100: return .sapphire
        case 100..<1000: return .amber
        case 1000..<10000: return .arcane
        default: return .crimson
        }
    }

    /// Palette order used when a value crosses its own thresholds.
    static let ordered: [CrystalPalette] = [.emerald, .sapphire, .amber, .arcane, .crimson]

    var gradient: LinearGradient {
        LinearGradient(colors: gemColors, startPoint: .top, endPoint: .bottom)
    }

    /// Shared gem colors for progress bars and theory-threshold crystals.
    var gemColors: [Color] {
        switch self {
        case .emerald:
            return [Color(hex: "#D8FFE8"), Color(hex: "#5DDB8A"), Color(hex: "#14924A"), Color(hex: "#0C3D24")]
        case .sapphire:
            return [Color(hex: "#A5E5FF"), Color(hex: "#48B9F0"), Color(hex: "#1677CB"), Color(hex: "#10406F")]
        case .amber:
            return [Color(hex: "#FFF0B0"), Color(hex: "#F6CB65"), Color(hex: "#C58A27"), Color(hex: "#694419")]
        case .crimson:
            return [Color(hex: "#FFD1D4"), Color(hex: "#FF777C"), Color(hex: "#D72D4A"), Color(hex: "#76192F")]
        case .arcane:
            return [Color(hex: "#F5D9FF"), Color(hex: "#BCA1FF"), Color(hex: "#7D6BE7"), Color(hex: "#4D9ED7"), Color(hex: "#3B4B8C")]
        }
    }
}

/// Fill length for one track. Crossing a color threshold does not shorten the fill.
enum ProgressFill {
    static let hourMarks: [Double] = [0, 21, 100, 1_000, 10_000, 100_000]

    static func fraction(value: Double, marks: [Double] = hourMarks) -> Double {
        guard value.isFinite, !value.isNaN, marks.count >= 2 else { return 0 }
        let lower = marks[0]
        let upper = marks[marks.count - 1]
        if value <= lower { return 0 }
        if value >= upper { return 1 }
        let segments = Double(marks.count - 1)
        for index in 0..<(marks.count - 1) {
            let start = marks[index]
            let end = marks[index + 1]
            if value <= end {
                let span = end - start
                let local = span > 0 ? (value - start) / span : 0
                return (Double(index) + local) / segments
            }
        }
        return 1
    }

    static func bandIndex(value: Double, marks: [Double]) -> Int {
        guard marks.count >= 2 else { return 0 }
        if value <= marks[0] { return 0 }
        for index in 0..<(marks.count - 1) where value < marks[index + 1] {
            return index
        }
        return marks.count - 2
    }
}

struct CrystalProgressBar: View {
    var progress: Double
    var hours: Double
    /// When set, the gem color comes from the caller instead of the hour band.
    var paletteOverride: CrystalPalette? = nil
    var height: CGFloat = 12
    var animated: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var clamped: Double {
        guard progress.isFinite, !progress.isNaN else { return 0 }
        return min(max(progress, 0), 1)
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width * CGFloat(clamped)
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.black.opacity(0.34), Color.primary.opacity(0.08)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                if width > 0.5, let palette = paletteOverride ?? CrystalPalette.forHours(hours) {
                    Capsule()
                        .fill(palette.gradient)
                        .frame(width: width)
                        .overlay(alignment: .top) {
                            LinearGradient(
                                colors: [Color.white.opacity(0.55), Color.white.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: max(2, height * 0.38))
                            .padding(.horizontal, 1)
                            .padding(.top, 1)
                            .allowsHitTesting(false)
                        }
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.white.opacity(0.38), lineWidth: 0.6)
                        )
                }
            }
            .overlay(
                Capsule()
                    .stroke(Color.primary.opacity(0.28), lineWidth: 0.7)
            )
            .animation(animated && !reduceMotion ? .easeInOut(duration: 0.45) : nil, value: clamped)
        }
        .frame(height: height)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(LocalizedStringKey("catalog_progress")))
        .accessibilityValue(Text("\(Int((clamped * 100).rounded()))%"))
    }
}
