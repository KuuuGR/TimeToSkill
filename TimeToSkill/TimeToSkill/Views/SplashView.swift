//
//  SplashView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

/// Displays app logo for 2 seconds, then navigates to MainView
struct SplashView: View {
    @State private var isActive = false
    
    var body: some View {
        if isActive {
            MainView()
        } else {
            Image("app_logo")  // Replace with your asset
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isActive = true
                    }
                }
        }
    }
}
