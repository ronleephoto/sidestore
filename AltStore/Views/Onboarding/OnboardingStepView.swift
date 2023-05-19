//
//  OnboardingStepView.swift
//  SideStore
//
//  Created by Fabian Thies on 25.02.23.
//  Copyright © 2023 SideStore. All rights reserved.
//

import SwiftUI


struct OnboardingStep<Title: View, Hero: View, Content: View, Action: View> {

    @ViewBuilder
    var title: Title

    @ViewBuilder
    var hero: Hero

    @ViewBuilder
    var content: Content

    @ViewBuilder
    var action: Action
}


struct OnboardingStepView<Title: View, Hero: View, Content: View, Action: View>: View {

    @ViewBuilder
    var title: Title

    @ViewBuilder
    var hero: Hero

    @ViewBuilder
    var content: Content

    @ViewBuilder
    var action: Action

    var body: some View {
        VStack(spacing: 64) {
            self.title
                .font(.largeTitle.weight(.bold))
                .frame(maxWidth: .infinity, alignment: .leading)

            self.hero
                .frame(height: 150)

            self.content

            Spacer()

            self.action
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct OnboardingStepView_Previews: PreviewProvider {
    @State
    static var isWireGuardAppStorePageVisible = false

    static var previews: some View {
        OnboardingStepView(title: {
            VStack(alignment: .leading) {
                Text("Welcome to")
                Text("SideStore")
                    .foregroundColor(.accentColor)
            }
        }, hero: {
            AppIconsShowcase()
        }, content: {
            VStack(spacing: 16) {
                Text("Before you can start sideloading apps, there is some setup to do.")
                Text("The following setup will guide you through the steps one by one.")
                Text("You will need a computer (Windows, macOS, Linux) and your Apple ID.")
            }
        }, action: {
            SwiftUI.Button("Continue") {

            }
            .buttonStyle(FilledButtonStyle())
        })

        OnboardingStepView(title: {
            VStack(alignment: .leading) {
                Text("Pair your Device")
            }
        }, hero: {
            Image(systemSymbol: .link)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.accentColor)
                .shadow(color: .accentColor.opacity(0.8), radius: 12)
        }, content: {
            VStack {
                Text("Before you can start sideloading apps, there is some setup to do.")
                Text("The following setup will guide you through the steps one by one.")
            }
        }, action: {
            SwiftUI.Button("Continue") {

            }
            .buttonStyle(FilledButtonStyle())
        })

        OnboardingStepView(title: {
            VStack(alignment: .leading) {
                Text("Download WireGuard")
            }
        }, hero: {
            Image(systemSymbol: .icloudAndArrowDown)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.accentColor)
                .shadow(color: .accentColor.opacity(0.8), radius: 12)
        }, content: {
            VStack {
                Text("Before you can start sideloading apps, there is some setup to do.")
                Text("The following setup will guide you through the steps one by one.")
            }
        }, action: {
            SwiftUI.Button("Show in App Store") {

            }
            .buttonStyle(FilledButtonStyle())

            AppStoreView(isVisible: self.$isWireGuardAppStorePageVisible, itunesItemId: 1441195209)
                .frame(width: .zero, height: .zero)
        })

    }
}

