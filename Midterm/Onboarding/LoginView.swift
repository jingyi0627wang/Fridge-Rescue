//
//  LoginView.swift
//  Midterm
//
//  Created by Rumik He on 10/13/26.
//

//
//  LoginView.swift
//  Midterm
//
//  Created by Rumik He on 10/13/26.
//

//
//  LoginView.swift
//  Midterm
//
//  Created by Rumik He on 10/13/26.
//

//
//  LoginView.swift
//  Midterm
//
//  Created by Rumik He on 10/13/26.
//

import SwiftUI

struct LoginView: View {


    @AppStorage("username") private var savedUsername = ""
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("hasSeenGuide") private var hasSeenGuide = false


    @State private var isSignUp = false
    @State private var usernameInput = ""
    @State private var passwordInput = ""
    @State private var errorMessage: String?
    @State private var showForgotAlert = false
    @State private var showComingSoon = false
    @FocusState private var typing: Bool


    private var hasAccount: Bool {
        !savedUsername.isEmpty && KeychainHelper.readPassword() != nil
    }


    private enum Layout {
        static let characterWidth: CGFloat = 118
        static let wordmarkWidth: CGFloat = 210
        static let logoGap: CGFloat = 22
        static let cardMargin: CGFloat = 21
        static let cardRadius: CGFloat = 44
        static let cardInset: CGFloat = 30      // card edge → fields / button
        static let rowHeight: CGFloat = 68      // fields and main button
        static let fieldRadius: CGFloat = 26
        static let socialSize: CGFloat = 54
    }

    var body: some View {

        GeometryReader { geo in
            let small = geo.size.height < 760          // SE / mini
            VStack(spacing: 0) {
                logo(scale: small ? 0.72 : 1)
                    .padding(.top, small ? 0 : 4)
                    .padding(.bottom, small ? 14 : 28)

                card(bottomInset: geo.safeAreaInsets.bottom, small: small)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            // Keyboard: slide the whole page up instead of squashing it.
            .offset(y: typing ? -(small ? 150 : 175) : 0)
            .animation(.easeOut(duration: 0.25), value: typing)
        }
        .ignoresSafeArea(.container, edges: .bottom)
        .ignoresSafeArea(.keyboard)
        .background { PatternBackground() }
        .contentShape(Rectangle())
        .onTapGesture { typing = false }               // tap outside → hide keyboard
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

    private func logo(scale: CGFloat) -> some View {
        VStack(spacing: Layout.logoGap * scale) {
            Image("FreshlingsCharacter")
                .resizable()
                .scaledToFit()
                .frame(width: Layout.characterWidth * scale)
            Image("FreshlingsWordmark")
                .resizable()
                .scaledToFit()
                .frame(width: Layout.wordmarkWidth * scale)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Freshlings")
    }

    // MARK: - 绿色卡片（一直延伸到屏幕底部）

    private func card(bottomInset: CGFloat, small: Bool) -> some View {
        VStack(spacing: 0) {

            Text(isSignUp ? "Sign up" : "Log in")
                .font(FreshlingsTheme.display(small ? 38 : 44))
                .foregroundStyle(.white)

            Spacer(minLength: 12).frame(maxHeight: 26)

            // 用户名
            inputField(icon: "person") {
                TextField("", text: $usernameInput,
                          prompt: placeholder("Enter Name"))
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textContentType(.username)
                    .focused($typing)
            }

            // 密码
            inputField(icon: "lock") {
                SecureField("", text: $passwordInput,
                            prompt: placeholder(isSignUp ? "Password (4+ characters)" : "Password"))
                    .textContentType(isSignUp ? .newPassword : .password)
                    .submitLabel(.go)
                    .onSubmit(submit)
                    .focused($typing)
            }
            .padding(.top, 15)

            // 错误提示 + Forgot Password（右对齐，在输入框下方）
            HStack(alignment: .top) {
                if let errorMessage {
                    Text(errorMessage)
                        .font(FreshlingsTheme.body(13, weight: .semibold))
                        .foregroundStyle(FreshlingsTheme.errorRed)
                }
                Spacer(minLength: 8)
                if !isSignUp {
                    Button("Forgot Password?") { showForgotAlert = true }
                        .font(FreshlingsTheme.body(12, weight: .medium))
                        .underline()
                        .foregroundStyle(FreshlingsTheme.linkGreen)
                }
            }
            .frame(minHeight: 18)
            .padding(.top, 12)
            .padding(.trailing, -3)

            Spacer(minLength: 12).frame(maxHeight: 30)

            // 主按钮
            Button(action: submit) {
                Text("Rescue the Freshlings!")
                    .font(FreshlingsTheme.body(21, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: Layout.rowHeight)
                    .background(FreshlingsTheme.deepGreen, in: Capsule())
            }

            // 切换 Log in / Sign up
            Button(isSignUp ? "Already have an account? Log in" : "Sign up", action: toggleMode)
                .font(FreshlingsTheme.body(15, weight: .medium))
                .underline()
                .foregroundStyle(FreshlingsTheme.linkGreen)
                .frame(minHeight: 44)
                .padding(.top, small ? 6 : 12)

            Spacer(minLength: 8).frame(maxHeight: 44)

            // 社交登录（目前只是外观）
            HStack(spacing: 14) {
                socialButton(Image.asset("IconGoogle", fallbackSystemName: "g.circle.fill"), name: "Google")
                socialButton(Image(systemName: "apple.logo"), name: "Apple")
                socialButton(Image.asset("IconFacebook", fallbackSystemName: "f.circle.fill"), name: "Facebook")
                socialButton(Image.asset("IconDiscord", fallbackSystemName: "gamecontroller.fill"), name: "Discord")
            }

            Spacer(minLength: 16)
        }
        .padding(.horizontal, Layout.cardInset)
        .padding(.top, small ? 26 : 40)
        .padding(.bottom, max(bottomInset, 16))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background {
            // The pattern is an overlay, so its big scaled-to-fill size can't
            // make the card grow past its frame (that was covering the logo).
            FreshlingsTheme.green
                .overlay {
                    Image("TitlePattern")
                        .resizable()
                        .scaledToFill()
                        .blendMode(.multiply)   // white parts vanish, lines stay
                        .opacity(0.5)
                }
                .clipShape(UnevenRoundedRectangle(topLeadingRadius: Layout.cardRadius,
                                              topTrailingRadius: Layout.cardRadius,
                                              style: .continuous))
        }
        .padding(.horizontal, Layout.cardMargin)
    }

    private func placeholder(_ text: String) -> Text {
        Text(text).foregroundStyle(FreshlingsTheme.placeholder)
    }

    private func inputField<Field: View>(icon: String,
                                         @ViewBuilder field: () -> Field) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundStyle(FreshlingsTheme.placeholder)
                .frame(width: 24)
            field()
                .font(FreshlingsTheme.body(16, weight: .medium))
                .foregroundStyle(FreshlingsTheme.linkGreen)
        }
        .padding(.horizontal, 26)
        .frame(height: Layout.rowHeight)
        .background(FreshlingsTheme.field,
                    in: RoundedRectangle(cornerRadius: Layout.fieldRadius, style: .continuous))
    }

    private func socialButton(_ image: Image, name: String) -> some View {
        Button { showComingSoon = true } label: {
            image
                .renderingMode(.template)
                .resizable()
                .scaledToFit()
                .frame(width: 26, height: 26)
                .foregroundStyle(FreshlingsTheme.deepGreen)
                .frame(width: Layout.socialSize, height: Layout.socialSize)
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
