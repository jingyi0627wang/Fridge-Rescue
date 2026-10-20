import SwiftUI
import FirebaseCore //

@main
struct MyApp: App {

    @StateObject private var foodStore = FoodStore()
    @StateObject private var myRecipes = MyRecipeStore()

    @AppStorage("appLanguage")
    private var appLanguage = "en"

    /// Testing: every launch starts at Title → Login → Onboarding.
    /// The account and the fridge are kept; only "logged in" and "seen the guide" reset.
    /// Set to false before the final demo / release.
    static let showLoginEveryLaunch = true

    init() {
        // 
        FirebaseApp.configure()

        // Design-system fonts (Bagel Fat One + Anek Latin) + title bar look.
        GameAppearance.configure()

        if Self.showLoginEveryLaunch {
            UserDefaults.standard.set(false, forKey: "isLoggedIn")
            UserDefaults.standard.set(false, forKey: "hasSeenGuide")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(foodStore)
                .environmentObject(myRecipes)
                .environment(
                    \.locale,
                    Locale(identifier: appLanguage)
                )
                .preferredColorScheme(.light)
                .task {
                    await ExpirationNotificationService.shared
                        .requestAuthorizationAndSchedule(
                            items: foodStore.foodItems
                        )
                }
        }
    }
}
