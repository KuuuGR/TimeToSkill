//
//  SupportDeveloperView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 07/04/2025.
//

import SwiftUI

struct SupportDeveloperView: View {
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "heart.circle.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(AppColors.tertiary)

            LText(key: "support_title")
                .font(.title)
                .multilineTextAlignment(.center)
                .foregroundColor(AppColors.primary)

            LText(key: "support_description")
                .multilineTextAlignment(.center)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Button(action: openPayPal) {
                Label { Text(verbatim: L10n.string("support_button")) } icon: { Image(systemName: "link") }
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
        .navigationTitle(Text(verbatim: L10n.string("support_nav_title")))
    }

    private func openPayPal() {
        guard let url = URL(string: "https://www.paypal.me/etaosin") else { return }
        openURL(url)
    }
}

