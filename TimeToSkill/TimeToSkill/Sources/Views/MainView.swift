//
//  MainView.swift
//  TimeToSkill
//

import SwiftUI

struct MainView: View {
    @State private var selectedQuote: Quote? = nil
    @State private var showStats = false

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
                                Label {
                                    Text(LocalizedStringKey("main_manage_trackers"))
                                        .font(AppTypography.headline)
                                } icon: {
                                    Image(systemName: "bolt.fill")
                                        .font(.headline)
                                }
                            }
                            .buttonStyle(
                                FancyButtonStyle(
                                    background: .gold,
                                    gradientEnd: .darkGold,
                                    cornerRadius: 18,
                                    shadow: .black.opacity(0.25),
                                    shadowRadius: 10
                                )
                            )
                            
                            Spacer().frame(height: 12)

                            NavigationLink(destination: TheoryView()) {
                                Text(LocalizedStringKey("main_learning_theory"))
                            }
                            .buttonStyle(FancyButtonStyle(background: .mdbBlue, gradientEnd: .info))

                            NavigationLink(destination: AboutView()) {
                                Text(LocalizedStringKey("main_about_app"))
                            }
                            .buttonStyle(FancyButtonStyle(background: .mdbBlue, gradientEnd: .infoDark))
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
                        FABButton(
                            icon: "chart.bar.fill",
                            action: { showStats = true },
                            backgroundColor: Color.warningDark,
                            size: 64
                        )
                        .sheet(isPresented: $showStats) {
                            StatsView()
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
