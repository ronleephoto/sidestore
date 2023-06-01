//
//  DevModeView.swift
//  SideStore
//
//  Created by naturecodevoid on 2/16/23.
//  Copyright © 2023 SideStore. All rights reserved.
//

import SwiftUI
import LocalConsole
import minimuxer

// Yes, we know the password is right here. It's not supposed to be a secret, just something to hopefully prevent people breaking SideStore with dev mode and then complaining to us.
let DEV_MODE_PASSWORD = "devmode"

struct DevModePrompt: View {
    @Binding var isShowingDevModePrompt: Bool
    @Binding var isShowingDevModeMenu: Bool
    
    @State var countdown = 0
    @State var isShowingPasswordAlert = false
    @State var isShowingIncorrectPasswordAlert = false
    @State var password = ""
    
    var button: some View {
        SwiftUI.Button(action: {
            if #available(iOS 16.0, *) {
                isShowingPasswordAlert = true
            } else {
                // iOS 14 doesn't support .alert, so just go straight to dev mode without asking for a password
                // iOS 15 also doesn't seem to support TextField in an alert (the text field was nonexistent)
                enableDevMode()
            }
        }) {
            Text(countdown <= 0 ? L10n.Action.enable + " " + L10n.DevModeView.title : L10n.DevModeView.read + " (\(countdown))")
                .foregroundColor(.red)
        }
        .buttonStyle(FilledButtonStyle(tintColor: Color.gray.opacity(0.5)))
        .disabled(countdown > 0)
    }
    
    @ViewBuilder
    var text: some View {
        if #available(iOS 15.0, *),
           let string = try? AttributedString(markdown: L10n.DevModeView.prompt, options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
            Text(string)
        } else {
            Text(L10n.DevModeView.prompt)
        }
    }
    
    var view: some View {
        ScrollView {
            VStack {
                text
                    .foregroundColor(.primary)
                    .padding(.bottom)
                
                button
            }
            .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .navigationTitle(L10n.DevModeView.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                SwiftUI.Button(action: { isShowingDevModePrompt = false }) {
                    Text(L10n.Action.close)
                }
            }
        }
        .onAppear {
            countdown = 20
            tickCountdown()
        }
    }
    
    var body: some View {
        NavigationView {
            if #available(iOS 15.0, *) {
                view
                    .alert(L10n.DevModeView.password, isPresented: $isShowingPasswordAlert) {
                        TextField(L10n.DevModeView.password, text: $password)
                            .autocapitalization(.none)
                            .autocorrectionDisabled(true)
                        SwiftUI.Button(L10n.Action.submit, action: {
                            if password == DEV_MODE_PASSWORD {
                                enableDevMode()
                            } else {
                                isShowingIncorrectPasswordAlert = true
                            }
                        })
                    }
                    .alert(L10n.DevModeView.incorrectPassword, isPresented: $isShowingIncorrectPasswordAlert) {
                        SwiftUI.Button(L10n.Action.tryAgain, action: {
                            isShowingIncorrectPasswordAlert = false
                            isShowingPasswordAlert = true
                        })
                        SwiftUI.Button(L10n.Action.cancel, action: {
                            isShowingIncorrectPasswordAlert = false
                            isShowingDevModePrompt = false
                        })
                    }
            } else {
                view
            }
        }
    }
    
    func enableDevMode() {
        UserDefaults.standard.isDevModeEnabled = true
        isShowingDevModePrompt = false
        isShowingDevModeMenu = true
    }
    
    func tickCountdown() {
        if countdown <= 0 { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            countdown -= 1
            tickCountdown()
        }
    }
}

struct DevModeMenu: View {
    @ObservedObject private var iO = Inject.observer
    
    @AppStorage("isConsoleEnabled")
    var isConsoleEnabled: Bool = false
    
    @AppStorage("isDevModeEnabled")
    var isDevModeEnabled: Bool = false
    
    #if !UNSTABLE
    @State var isUnstableAlertShowing = false
    #endif
    
    var body: some View {
        List {
            Section {
                Toggle(L10n.DevModeView.General.console, isOn: self.$isConsoleEnabled)
                    .onChange(of: self.isConsoleEnabled) { value in
                        LCManager.shared.isVisible = value
                    }
                
                NavigationLink(L10n.UnstableFeaturesView.title) {
                    #if UNSTABLE
                    UnstableFeaturesView(inDevMode: true)
                    #endif
                }
                #if !UNSTABLE
                .disabled(true)
                .alert(isPresented: $isUnstableAlertShowing) {
                    Alert(title: Text(L10n.DevModeView.General.unstableFeaturesNightlyOnly))
                }
                .onTapGesture { isUnstableAlertShowing = true }
                #endif
                
                SwiftUI.Button(action: {
                    isDevModeEnabled = false
                }, label: { Text(L10n.DevModeView.General.disableDevMode) }).foregroundColor(.red)
            } header: {
                Text(L10n.DevModeView.General.header)
            }
            
            Section {
                NavigationLink(L10n.DevModeView.Files.dataExplorer) {
                    FileExplorer.normal(url: FileManager.default.altstoreSharedDirectory)
                        .navigationTitle(L10n.DevModeView.Files.dataExplorer)
                }.foregroundColor(.red)
                
                NavigationLink(L10n.DevModeView.Files.tmpExplorer) {
                    FileExplorer.normal(url: FileManager.default.temporaryDirectory)
                        .navigationTitle(L10n.DevModeView.Files.tmpExplorer)
                }.foregroundColor(.red)
            } header: {
                Text(L10n.DevModeView.Files.header)
            }
            
            Section {
                AsyncFallibleButton(action: {
                    let dir = try dump_profiles(FileManager.default.documentsDirectory.absoluteString)
                    DispatchQueue.main.async {
                        UIApplication.shared.open(URL(string: "shareddocuments://" + dir.toString())!, options: [:], completionHandler: nil)
                    }
                }) { execute in
                    Text(L10n.DevModeView.Minimuxer.dumpProfiles)
                }
                
                NavigationLink(L10n.DevModeView.Minimuxer.afcExplorer) {
                    FileExplorer.afc()
                        .navigationTitle(L10n.DevModeView.Minimuxer.afcExplorer)
                }.foregroundColor(.red)
            } header: {
                Text(L10n.DevModeView.Minimuxer.header)
            } footer: {
                Text(L10n.DevModeView.Minimuxer.footer)
            }
            
            Section {
                Toggle(L10n.DevModeView.Signing.skipResign, isOn: ResignAppOperation.skipResignBinding)
                    .foregroundColor(.red)
            } header: {
                Text(L10n.DevModeView.Signing.header)
            } footer: {
                Text(L10n.DevModeView.Signing.footer)
            }
        }
        .navigationTitle(L10n.DevModeView.title)
        .enableInjection()
    }
}

struct DevModeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            List {
                NavigationLink("DevModeMenu") {
                    DevModeMenu()
                }
            }
        }
    }
}
