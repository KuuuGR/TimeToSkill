//  MainView.swift
//  TimeToSkill
//

import SwiftUI

struct MainView: View {
    @State private var selectedQuote: Quote? = nil

    private let backgroundAnimation: BackgroundAnimationType = .staticCircle

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground(animationType: backgroundAnimation)

                ScrollView {
                    VStack(spacing: 24) {
                        Text("TimeToSkill")
                            .font(AppTypography.display)
                            .foregroundColor(AppColors.onSurface)
                            .padding(.top, 40)

                        if let quote = selectedQuote {
                            VStack(alignment: .center, spacing: 4) {
                                Text("“\(quote.quote)”")
                                    .font(.subheadline)
                                    .italic()
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)

                                Text("- \(quote.author)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .transition(.opacity)
                        }

                        VStack(spacing: 16) {
                            NavigationLink(destination: StartView()) {
                                Text(LocalizedStringKey("main_manage_trackers"))
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
                            .accessibilityLabel("Manage Trackers")

                            NavigationLink(destination: TheoryView()) {
                                Text(LocalizedStringKey("main_learning_theory"))
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
                                Text(LocalizedStringKey("main_about_app"))
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
                            .accessibilityLabel("About App")
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
        .onAppear {
            let quotes = QuoteLoader.loadLocalizedQuotes()
            if let random = quotes.randomElement() {
                selectedQuote = random
            }
        }
    }
}
