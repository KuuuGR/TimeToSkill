//  MainView.swift
//  TimeToSkill
//

import SwiftUI

struct MainView: View {
    // Choose your preferred animation type here
    private let backgroundAnimation: BackgroundAnimationType = .staticCircle
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Configurable background
                AppBackground(animationType: backgroundAnimation)
                
                // Main content
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        Text("TimeToSkill")
                            .font(AppTypography.display)
                            .foregroundColor(AppColors.onSurface)
                            .padding(.top, 40)
                        
                        // Button Cards
                        VStack(spacing: 16) {
                            NavigationLink {
                                StartView()
                            } label: {
                                PrimaryButton(title: "Start Tracking") {}
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink {
                                TheoryView()
                            } label: {
                                SecondaryButton(title: "Learning Theory") {}
                            }
                            .buttonStyle(.plain)
                            
                            NavigationLink {
                                AboutView()
                            } label: {
                                SecondaryButton(title: "About App") {}
                            }
                            .buttonStyle(.plain)
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
                    .frame(maxWidth: .infinity)
                }
                
                // FAB Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FABButton(icon: "plus") {
                            // FAB action
                        }
                        .padding(20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .accentColor(AppColors.primary)
    }
}
