//  MainView.swift
//  TimeToSkill
//

import SwiftUI

struct MainView: View {
    // Background configuration
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
                            NavigationLink {
                                StartView()
                            } label: {
                                PrimaryButton(title: "Start Tracking") {}
                            }
                            
                            NavigationLink {
                                TheoryView()
                            } label: {
                                SecondaryButton(title: "Learning Theory") {}
                            }
                            
                            NavigationLink {
                                AboutView()
                            } label: {
                                SecondaryButton(title: "About App") {}
                            }
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
                
                // Floating Action Button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button(action: { print("FAB tapped") }) {
                            Image(systemName: "plus")
                                .font(.title.weight(.bold))
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(AppColors.primary)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.3), radius: 8, y: 4)
                        }
                        .padding(20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
    }
}
