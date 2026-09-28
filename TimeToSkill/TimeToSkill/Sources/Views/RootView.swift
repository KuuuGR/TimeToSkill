//
//  RootView.swift
//  TimeToSkill
//
//  The app's root view. It turns the persisted launch counter (`AppLaunch`)
//  into a concrete experience:
//
//   * the splash choreography plays on the 1st, 32nd, 64th and 128th launch;
//   * every other launch goes straight to the main flow;
//   * on the 16th and 256th launch the App Store is asked for a rating.
//
//  Review requests use StoreKit's SwiftUI action (`\.requestReview`), the API
//  Apple recommends instead of the deprecated `SKStoreReviewController`. The
//  request is made only after the main UI has had a moment to settle, never
//  during the splash or onboarding.
//

import SwiftUI
import StoreKit

struct RootView: View {
    @Environment(\.requestReview) private var requestReview

    /// Launch number for this process (1 = the very first launch).
    private let launchCount: Int

    @State private var isShowingSplash: Bool
    @State private var didRequestReview = false

    init(launchCount: Int = AppLaunch.currentCount()) {
        self.launchCount = launchCount
        _isShowingSplash = State(initialValue: AppLaunch.shouldShowSplash(onLaunch: launchCount))
    }

    var body: some View {
        Group {
            if isShowingSplash {
                SplashView(onFinish: finishSplash)
                    .transition(.opacity)
            } else {
                MainView()
                    .transition(.opacity)
            }
        }
        .onAppear(perform: handleAppear)
    }

    /// Fades the splash out and reveals the main flow.
    private func finishSplash() {
        withAnimation(.easeOut(duration: 0.4)) {
            isShowingSplash = false
        }
    }

    private func handleAppear() {
        guard !didRequestReview else { return }
        guard AppLaunch.shouldRequestReview(onLaunch: launchCount) else { return }
        didRequestReview = true
        // Let the main UI settle before interrupting the user with the prompt.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            requestReview()
        }
    }
}
