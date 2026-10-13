import SwiftUI

/// 一页引导的内容
struct OnboardingPage {
    let image: String       // Assets 里的插画名称
    let title: String       // 大标题，用 \n 换行
    let textOnTop: Bool     // true：字在上、图在下；false：图在上、字在下
}

/// 登录后看到的 4 页引导。左右滑动换页，最后一页按按钮进入 App。
struct OnboardingView: View {

    @AppStorage("hasSeenGuide") private var hasSeenGuide = false
    @State private var page = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(image: "Onboarding1", title: "Track\nwhat’s in\nyour fridge", textOnTop: false),
        OnboardingPage(image: "Onboarding2", title: "HP shows\nshelf life left", textOnTop: true),
        OnboardingPage(image: "Onboarding3", title: "Use\nwhat’s\nexpiring first", textOnTop: false),
        OnboardingPage(image: "Onboarding4", title: "See\nyour impact", textOnTop: true)
    ]

    private var isLastPage: Bool { page == pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {

            // 顶部的小角色
            Image("FreshlingsCharacter")
                .resizable()
                .scaledToFit()
                .frame(height: 52)
                .padding(.top, 12)
                .accessibilityHidden(true)

            progressBars
                .padding(.top, 28)
                .padding(.horizontal, 48)

            // 可以左右滑动的 4 页
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageContent(pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // 底部：前 3 页是 Skip，最后一页是按钮
            bottomArea
                .frame(height: 96)
                .padding(.horizontal, 48)
                .padding(.bottom, 16)
        }
        .background(Color.white.ignoresSafeArea())
        .animation(.easeInOut(duration: 0.25), value: page)
    }

    // MARK: - 进度条

    private var progressBars: some View {
        HStack(spacing: 10) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == page ? FreshlingsTheme.deepGreen : FreshlingsTheme.barIdle)
                    .frame(height: 7)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Page \(page + 1) of \(pages.count)")
    }

    // MARK: - 每一页

    @ViewBuilder
    private func pageContent(_ item: OnboardingPage) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if item.textOnTop {
                title(item.title)
                    .padding(.top, 56)
                Spacer(minLength: 24)
                illustration(item.image)
                Spacer(minLength: 16)
            } else {
                Spacer(minLength: 16)
                illustration(item.image)
                Spacer(minLength: 24)
                title(item.title)
                    .padding(.bottom, 24)
            }
        }
        .padding(.horizontal, 40)
    }

    private func title(_ text: String) -> some View {
        Text(text)
            .font(FreshlingsTheme.heading(46))
            .foregroundStyle(FreshlingsTheme.brown)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func illustration(_ name: String) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(maxWidth: .infinity, maxHeight: 340)
            .accessibilityHidden(true)
    }

    // MARK: - 底部

    @ViewBuilder
    private var bottomArea: some View {
        if isLastPage {
            Button(action: finish) {
                Label("Add your first freshling", systemImage: "sparkle")
                    .font(FreshlingsTheme.body(22, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(FreshlingsTheme.ctaGreen, in: Capsule())
            }
        } else {
            Button("Skip", action: finish)
                .font(FreshlingsTheme.body(18, weight: .bold))
                .foregroundStyle(FreshlingsTheme.skipGray)
                .frame(minWidth: 88, minHeight: 44)
        }
    }

    private func finish() {
        hasSeenGuide = true   // RootView 看到后会自动切到 Tab bar
    }
}

#Preview {
    OnboardingView()
}
