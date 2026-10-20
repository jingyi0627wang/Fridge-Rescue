//
//  RootView.swift
//  Midterm
//
//  Created by Rumik He on 10/13/26.
//

import SwiftUI
import FirebaseAuth

/// 决定现在要显示哪一页：
/// Title（2 秒）→ 没登录：Login → 没看过引导：Onboarding → 主画面 Tab bar
struct RootView: View {

    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("hasSeenGuide") private var hasSeenGuide = false

    @State private var showTitle = true
    @State private var authReady = false
    @State private var authListener: AuthStateDidChangeListenerHandle?
    @AppStorage("username") private var username = ""

    var body: some View {
        ZStack {
            if showTitle || !authReady {
                TitleView()
                    .transition(.opacity)
            } else if !isLoggedIn {
                LoginView()
                    .transition(.opacity)
            } else if !hasSeenGuide {
                OnboardingView()
                    .transition(.opacity)
            } else {
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showTitle)
        .animation(.easeInOut(duration: 0.4), value: isLoggedIn)
        .animation(.easeInOut(duration: 0.4), value: hasSeenGuide)
        .onAppear {
            guard authListener == nil else { return }
            authListener = Auth.auth().addStateDidChangeListener { _, user in
                DispatchQueue.main.async {
                    isLoggedIn = user != nil
                    if let user {
                        username = user.displayName ?? user.email?.components(separatedBy: "@").first ?? username
                    }
                    authReady = true
                }
            }
        }
        .onDisappear {
            if let authListener {
                Auth.auth().removeStateDidChangeListener(authListener)
                self.authListener = nil
            }
        }
        .task {
            // 停留 2 秒后离开 Title
            try? await Task.sleep(for: .seconds(2))
            showTitle = false
        }
    }
}

#Preview {
    RootView()
        .environmentObject(FoodStore())
        .environmentObject(MyRecipeStore())
}
