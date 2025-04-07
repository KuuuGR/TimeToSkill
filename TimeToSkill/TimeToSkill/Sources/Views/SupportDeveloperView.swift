//
//  SupportDeveloperView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 07/04/2025.
//

import SwiftUI

struct SupportDeveloperView: View {
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(AppColors.tertiary)

            Text(LocalizedStringKey("support_title"))
                .font(.title)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.primary)

            Text(LocalizedStringKey("support_description"))
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button(action: openPayPal) {
                Label(LocalizedStringKey("support_button"), systemImage: "link")
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.top, 40)
        .navigationTitle(LocalizedStringKey("support_nav_title"))
    }

    private func openPayPal() {
        guard let url = URL(string: "https://www.paypal.me/etaosin") else { return }
        UIApplication.shared.open(url)
    }
}

