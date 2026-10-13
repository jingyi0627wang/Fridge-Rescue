//
//  LoginView.swift
//  Midterm
//
//  Created by Rumik He on 10/13/26.
//

import SwiftUI

struct LoginView: View {

    // 存在手机里的值
    @AppStorage("username") private var savedUsername = ""
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("hasSeenGuide") private var hasSeenGuide = false

    // 只在这一页用的暂时状态
    @State private var isSignUp = false
    @State private var usernameInput = ""
    @State private var passwordInput = ""
    @State private var errorMessage: String?
    @State private var showForgotAlert = false
    @State private var showComingSoon = false

    /// 手机里有没有已经建好的账号
    private var hasAccount: Bool {
        !savedUsername.isEmpty && KeychainHelper.readPassword() != nil
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 0) {
                    logo
                        .padding(.top, 24)
                        .padding(.bottom, 32)

                    card
                        .frame(maxHeight: .infinity, alignment: .top)
                }
                .frame(minHeight: geo.size.height)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollBounceBehavior(.basedOnSize)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .background { PatternBackground() }
        .onAppear { isSignUp = !hasAccount }
        .onChange(of: usernameInput) { errorMessage = nil }
        .onChange(of: passwordInput) { errorMessage = nil }
        .alert("Forgot your password?", isPresented: $showForgotAlert) {
            Button("Reset account", role: .destructive, action: resetAccount)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Your password is saved only on this phone, so it can't be recovered. You can reset the account and create a new one. Your fridge won't be affected.")
        }
        .alert("Coming soon", isPresented: $showComingSoon) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Social sign-in isn't available yet. Please use a username and password for now.")
        }
    }

    // MARK: - Logo（角色 + 字）

    private var logo: some View {
        VStack(spacing: 18) {
            Image("FreshlingsCharacter")
                .resizable()
                .scaledToFit()
                .frame(width: 130)
            Image("FreshlingsWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: 210)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Freshlings")
    }

    // MARK: - 绿色卡片

    private var card: some View {
        VStack(spacing: 16) {

            Text(isSignUp ? "Sign up" : "Log in")
                .font(FreshlingsTheme.display(44))
                .foregroundStyle(.white)
                .padding(.bottom, 12)

            // 用户名
            inputField(icon: "person") {
                TextField("", text: $usernameInput,
                          prompt: placeholder("Enter Name"))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
            }

            // 密码
            inputField(icon: "lock") {
                SecureField("", text: $passwordInput,
                            prompt: placeholder(isSignUp ? "Password (4+ characters)" : "Password"))
                    .textContentType(isSignUp ? .newPassword : .password)
                    .submitLabel(.go)
                    .onSubmit(submit)
            }

            // 错误提示 + Forgot Password
            HStack(alignment: .top) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(FreshlingsTheme.body(14, weight: .semibold))
                        .foregroundStyle(FreshlingsTheme.errorRed)
                }
                Spacer()
                if !isSignUp {
                    Button("Forgot Password?") { showForgotAlert = true }
                        .font(FreshlingsTheme.body(14, weight: .medium))
                        .underline()
                        .foregroundStyle(FreshlingsTheme.linkGreen)
                }
            }
            .frame(minHeight: 20)

            // 主按钮
            Button(action: submit) {
                Text("Rescue the Freshlings!")
                    .font(FreshlingsTheme.body(22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(FreshlingsTheme.deepGreen, in: Capsule())
            }
            .padding(.top, 12)

            // 切换 Log in / Sign up
            Button(isSignUp ? "Already have an account? Log in" : "Sign up", action: toggleMode)
                .font(FreshlingsTheme.body(17, weight: .medium))
                .underline()
                .foregroundStyle(FreshlingsTheme.linkGreen)
                .padding(.top, 4)

            // 社交登录（目前只是外观）
            HStack(spacing: 14) {
                socialButton(Image("IconGoogle"), name: "Google")
                socialButton(Image(systemName: "apple.logo"), name: "Apple")
                socialButton(Image("IconFacebook"), name: "Facebook")
                socialButton(Image("IconDiscord"), name: "Discord")
            }
            .padding(.top, 28)
        }
        .padding(.horizontal, 28)
        .padding(.top, 40)
        .padding(.bottom, 56)
        .background {
            ZStack {
                FreshlingsTheme.green
                Image("TitlePattern")
                    .resizable()
                    .scaledToFill()
                    .opacity(0.35)
            }
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 48, topTrailingRadius: 48))
        }
        .padding(.horizontal, 20)
    }

 

    private func placeholder(_ text: String) -> Text {
        Text(text).foregroundStyle(FreshlingsTheme.placeholder)
    }

    private func inputField<Field: View>(icon: String,
                                         @ViewBuilder field: () -> Field) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(FreshlingsTheme.placeholder)
                .frame(width: 24)
            field()
                .font(FreshlingsTheme.body(18, weight: .medium))
                .foregroundStyle(FreshlingsTheme.linkGreen)
        }
        .padding(.horizontal, 22)
        .frame(height: 64)
        .background(FreshlingsTheme.field, in: RoundedRectangle(cornerRadius: 28))
    }

    private func socialButton(_ image: Image, name: String) -> some View {
        Button { showComingSoon = true } label: {
            image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .foregroundStyle(FreshlingsTheme.deepGreen)
                .frame(width: 58, height: 58)
                .background(FreshlingsTheme.field, in: Circle())
        }
        .accessibilityLabel("Continue with \(name)")
    }



    private func submit() {
        let name = usernameInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else {
            errorMessage = "Enter a username."
            return
        }
        guard !passwordInput.isEmpty else {
            errorMessage = "Enter a password."
            return
        }

        if isSignUp {
            guard passwordInput.count >= 4 else {
                errorMessage = "Password must be at least 4 characters."
                return
            }
            savedUsername = name
            KeychainHelper.savePassword(passwordInput)
            hasSeenGuide = false          // 新账号要看一次引导
        } else {
            guard hasAccount else {
                errorMessage = "No account yet. Tap Sign up to create one."
                return
            }
            guard name == savedUsername,
                  passwordInput == KeychainHelper.readPassword() else {
                errorMessage = "Username or password is incorrect."
                return
            }
        }

        passwordInput = ""
        isLoggedIn = true
    }

    private func toggleMode() {
        isSignUp.toggle()
        passwordInput = ""
        errorMessage = nil
    }

    private func resetAccount() {
        KeychainHelper.deletePassword()
        savedUsername = ""
        usernameInput = ""
        passwordInput = ""
        errorMessage = nil
        isSignUp = true
    }
}

#Preview {
    LoginView()
}
