//
//  BrandMark.swift
//  TimeToSkill
//
//  Small reusable brand element: the brand symbol plus (optionally) the app
//  wordmark. Shared by the splash screen, the iOS hero and the macOS sidebar so
//  the brand is presented consistently on both platforms.
//

import SwiftUI

struct BrandMark: View {
    /// Which brand symbol is drawn next to the wordmark.
    enum Symbol {
        /// The raster app icon artwork.
        case artwork
        /// An arbitrary Unicode glyph drawn inside a thin accent circle.
        ///
        /// Used on the macOS sidebar, where the marker is small enough that
        /// the raster artwork reads as a smudge. Plain text glyphs take the
        /// accent tint; colour emoji would ignore it.
        case glyph(String)
    }

    /// Edge length of the marker. Keep it small - this is a brand marker, not a hero image.
    var size: CGFloat = 28
    var showsWordmark: Bool = true
    var wordmarkFont: Font = .headline
    var wordmarkColor: Color = AppColors.onSurface
    var cornerRadiusRatio: CGFloat = 0.24
    /// Draws a thin accent-coloured edge around the icon. Turn it off on
    /// surfaces where the artwork should float on its own (e.g. About).
    /// Only applies to `Symbol.artwork`.
    var showsBorder: Bool = true
    /// Which symbol to draw. Defaults to the app icon artwork.
    var symbol: Symbol = .artwork

    /// U+AA5C CHAM PUNCTUATION SPIRAL (꩜), drawn on the macOS sidebar.
    static let sidebarGlyph = "\u{AA5C}"

    private var cornerRadius: CGFloat { size * cornerRadiusRatio }

    var body: some View {
        HStack(spacing: max(6, size * 0.28)) {
            symbolView
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

    // MARK: - Symbols

    @ViewBuilder
    private var symbolView: some View {
        switch symbol {
        case .artwork:
            artwork
        case .glyph(let glyph):
            glyphMark(glyph)
        }
    }

    private var artwork: some View {
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
    }

    /// Flat fallback mark: a single glyph inside a thin accent circle. Reads
    /// far better than the scaled-down raster artwork at sidebar sizes.
    private func glyphMark(_ glyph: String) -> some View {
        Text(glyph)
            .font(.system(size: size * 0.62))
            .foregroundColor(AppColors.accent)
            .frame(width: size, height: size)
            .background(Circle().fill(AppColors.accent.opacity(0.12)))
            .overlay(Circle().strokeBorder(AppColors.accent.opacity(0.35), lineWidth: 1))
    }
}

#Preview {
    VStack(spacing: 24) {
        BrandMark(size: 28)
        BrandMark(size: 56, showsWordmark: false)
        BrandMark(size: 32, wordmarkFont: .title2.bold())
        BrandMark(size: 26, wordmarkFont: .headline, symbol: .glyph(BrandMark.sidebarGlyph))
        BrandMark(size: 56, showsWordmark: false, symbol: .glyph(BrandMark.sidebarGlyph))
    }
    .padding()
}
