
import SwiftUI

@main
struct MyApp: App {

    @StateObject private var foodStore = FoodStore()

    @AppStorage("appLanguage")
    private var appLanguage = "en"

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(foodStore)
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

