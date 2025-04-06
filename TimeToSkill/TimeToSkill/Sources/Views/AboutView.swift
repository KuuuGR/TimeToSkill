//
//  AboutView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("TimeToSkill")
                .font(.title)
            Text("Version 1.0")
            Text("Created by [Your Name]")
            
            Button("Support") {
                // Add support action
            }
            .padding(.top)
        }
        .navigationTitle("About")
    }
}
