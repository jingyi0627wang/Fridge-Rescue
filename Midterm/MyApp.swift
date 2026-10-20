
import SwiftUI

@main
struct MyApp: App {

    @StateObject private var foodStore = FoodStore()
    @StateObject private var myRecipes = MyRecipeStore()

    @AppStorage("appLanguage")
    private var appLanguage = "en"

    init() {
        // Fredoka font + game-style title bar and tab bar.
        GameAppearance.configure()
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

