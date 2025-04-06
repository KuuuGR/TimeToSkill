//
//  MainView.swift
//  TimeToSkill
//
//  Created by Grzegorz Kulesza on 06/04/2025.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                NavigationLink("Start", destination: StartView())
                NavigationLink("Theory", destination: TheoryView())
                NavigationLink("About", destination: AboutView())
            }
            .navigationTitle("TimeToSkill")
        }
    }
}
