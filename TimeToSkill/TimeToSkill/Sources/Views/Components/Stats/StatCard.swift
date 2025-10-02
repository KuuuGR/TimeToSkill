//
//  StatCard.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 10/04/2025.
//

import SwiftUI

struct StatCard: View {
    let label: String
    let value: String
    var subtext: String? = nil
    var color: Color = AppColors.primary

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            if let subtext = subtext {
                Text(subtext)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(label)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(AppColors.surface)
        .cornerRadius(12)
        .shadow(radius: 2, y: 1)
    }
}
