//
//  MainView.swift
//  TimeToSkill
//
//  Platform dispatcher. macOS gets native sidebar navigation (`MacRootView`),
//  iPhone/iPad keep the mobile home (`HomeView`). Both surfaces host the same
//  destination views, so no feature, model or persistence code is duplicated.
//

import SwiftUI

struct MainView: View {
    var body: some View {
        #if os(macOS)
        MacRootView()
        #else
        HomeView()
        #endif
    }
}
