import SwiftUI

@main
struct MyApp: App {

    @StateObject private var foodStore = FoodStore()

    var body: some Scene {
        WindowGroup {
            // Title → Login → Onboarding → MainTabView
            RootView()
                .environmentObject(foodStore)
                .task {
                    await ExpirationNotificationService.shared
                        .requestAuthorizationAndSchedule(items: foodStore.foodItems)
                }
        }
    }
}
