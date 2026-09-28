//
//  SplashView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//
//  Launch splash, ported from the ContextForge first-launch intro.
//  The layout, element order, spacing and fade-in choreography mirror
//  ContextForge; only the labels are TimeToSkill's.
//
//  Choreography (seconds):
//  1. Logo          0.0 - 0.8
//  2. "presents"    1.8 - 2.4
//  3. Title         3.4 - 4.0
//  4. Subtitle      5.2 - 5.8
//  5. Divider       6.8 - 7.2
//  6. Reflection    8.0 - 8.6
//  7. Main flow     12.0
//

import SwiftUI

struct SplashView: View {
    @State private var isActive = false

    // Fade-in progress for each element (0 = hidden, 1 = fully visible).
    @State private var logoOpacity: Double = 0
    @State private var presentsOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var subtitleOpacity: Double = 0
    @State private var dividerOpacity: Double = 0
    @State private var reflectionOpacity: Double = 0

    /// A single editorial reflection, chosen once per launch.
    private let reflection = SplashReflections.random()

    var body: some View {
        ZStack {
            // Dark background
            Color(red: 0.08, green: 0.08, blue: 0.1)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // 1. Logo
                Image("app_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 128, height: 152)
                    .opacity(logoOpacity)

                Spacer().frame(height: 16)

                // 2. "presents"
                Text("splash_presents")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .tracking(2)
                    .opacity(presentsOpacity)

                Spacer().frame(height: 24)

                // 3. App title
                Text("ab_app_name")
                    .font(.largeTitle.bold())
                    .foregroundColor(.primary)
                    .opacity(titleOpacity)

                Spacer().frame(height: 12)

                // 4. Subtitle
                Text("splash_tagline")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .opacity(subtitleOpacity)

                Spacer().frame(height: 24)

                // 5. Editorial divider
                Rectangle()
                    .fill(Color.primary.opacity(0.2))
                    .frame(width: 48, height: 1)
                    .opacity(dividerOpacity)

                Spacer().frame(height: 24)

                // 6. Reflection
                Text("\"\(reflection)\"")
                    .font(.subheadline)
                    .italic()
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 48)
                    .opacity(reflectionOpacity)
            }
            .onAppear(perform: playChoreography)
        }
        .modifier(SplashPresentation(isActive: $isActive))
    }

    /// Fades each element in over the same window ContextForge uses, then hands
    /// over to the main flow once the full 12s choreography has elapsed.
    private func playChoreography() {
        withAnimation(.linear(duration: 0.8)) { logoOpacity = 1 }
        withAnimation(.linear(duration: 0.6).delay(1.8)) { presentsOpacity = 1 }
        withAnimation(.linear(duration: 0.6).delay(3.4)) { titleOpacity = 1 }
        withAnimation(.linear(duration: 0.6).delay(5.2)) { subtitleOpacity = 1 }
        withAnimation(.linear(duration: 0.4).delay(6.8)) { dividerOpacity = 1 }
        withAnimation(.linear(duration: 0.6).delay(8.0)) { reflectionOpacity = 1 }

        DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) {
            withAnimation(.easeOut(duration: 0.4)) {
                isActive = true
            }
        }
    }
}

/// Editorial reflections shown on the splash screen.
///
/// Mirrors ContextForge's `ContextReflections`: a small set of philosophy
/// statements, stored as localization keys so they can be translated later.
private enum SplashReflections {
    private static let keys = [
        "splash_reflection_1",
        "splash_reflection_2",
        "splash_reflection_3",
        "splash_reflection_4",
        "splash_reflection_5",
    ]

    /// Returns a single reflection chosen at random.
    static func random() -> String {
        guard let key = keys.randomElement() else { return "" }
        return Bundle.main.localizedString(forKey: key, value: nil, table: nil)
    }
}

/// Presents the main flow with a full-screen cover on iOS; on macOS the splash
/// content is simply replaced by the main view.
private struct SplashPresentation: ViewModifier {
    @Binding var isActive: Bool

    func body(content: Content) -> some View {
        #if canImport(UIKit)
        content.fullScreenCover(isPresented: $isActive) {
            MainView()
        }
        #else
        Group {
            if isActive {
                MainView()
            } else {
                content
            }
        }
        #endif
    }
}
