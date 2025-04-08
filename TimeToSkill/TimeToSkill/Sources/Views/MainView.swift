//  MainView.swift
//  TimeToSkill
//

import SwiftUI

struct MainView: View {
    private let backgroundAnimation: BackgroundAnimationType = .staticCircle

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AppBackground(animationType: backgroundAnimation)

                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        Text("TimeToSkill")
                            .font(AppTypography.display)
                            .foregroundColor(AppColors.onSurface)
                            .padding(.top, 40)

                        // Navigation Buttons
                        VStack(spacing: 16) {
                            NavigationLink(destination: StartView()) {
                                Text("Start Tracking")
                                    .font(AppTypography.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundColor(AppColors.onPrimary)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AppColors.primary)
                                            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                    )
                            }
                            .accessibilityLabel("Start Tracking")

                            NavigationLink(destination: TheoryView()) {
                                Text("Learning Theory")
                                    .font(AppTypography.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundColor(AppColors.onPrimary)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AppColors.secondary)
                                            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                    )
                            }
                            .accessibilityLabel("Learning Theory")

                            NavigationLink(destination: AboutView()) {
                                Text("About App")
                                    .font(AppTypography.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .foregroundColor(AppColors.onPrimary)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(AppColors.secondary)
                                            .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                                    )
                            }
                            .accessibilityLabel("About")
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppColors.surface.opacity(0.7))
                                .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 40)

                        Spacer()
                    }
                }

                // FAB
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FABButton(icon: "plus") {
                            print("FAB tapped") // Optional move to StartView in future
                        }
                        .padding(20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}
