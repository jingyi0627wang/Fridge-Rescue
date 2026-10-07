import SwiftUI

@main
struct MyApp: App {

    @StateObject private var foodStore = FoodStore()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(foodStore)
        }
    }
}
