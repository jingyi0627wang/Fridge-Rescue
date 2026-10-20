
import SwiftUI
import Combine

// MARK: - App navigation
// Lets any page jump to another tab, e.g. "Find recipes for Milk"
// from Home, Today or Food Details opens the Recipes tab with Milk selected.

enum AppTab: Hashable {
    case fridge, today, add, recipes, impact
}

final class AppRouter: ObservableObject {
    @Published var selectedTab: AppTab = .fridge

    /// Fridge item selected in the Recipes tab's ingredient chips (nil = All).
    @Published var recipeFocusID: UUID?

    /// Changing this resets the Recipes tab back to its main list.
    @Published var recipesStackID = UUID()

    func openRecipes(for item: FoodItem? = nil) {
        recipeFocusID = item?.id
        recipesStackID = UUID()
        selectedTab = .recipes
    }
}

struct MainTabView: View {

    @EnvironmentObject var foodStore: FoodStore
    @StateObject private var router = AppRouter()

    // MARK: - Freshlings Colors
    private let freshGreen = Color(
        red: 0.53,
        green: 0.89,
        blue: 0.36
    )

    var body: some View {

        TabView(selection: $router.selectedTab) {

            // MARK: - My Fridge
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Image(systemName: "refrigerator")
                Text("Fridge")
            }
            .tag(AppTab.fridge)

            // MARK: - Today
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Image(systemName: "clock.fill")
                Text("Today")
            }
            .tag(AppTab.today)

            // MARK: - Add Food
            NavigationStack {
                AddFoodView(store: foodStore)
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("Add")
            }
            .tag(AppTab.add)

            // MARK: - Recipes
            NavigationStack {
                RecipeListView()
            }
            .id(router.recipesStackID)
            .tabItem {
                Image(systemName: "fork.knife")
                Text("Recipes")
            }
            .tag(AppTab.recipes)

            // MARK: - Impact
            NavigationStack {
                ImpactView()
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Impact")
            }
            .tag(AppTab.impact)
        }
        .environmentObject(router)
        .tint(freshGreen)
        // Undo bar for used / wasted / deleted / cooked actions.
        .overlay(alignment: .bottom) {
            if let toast = foodStore.toast {
                UndoToastView(toast: toast)
                    .padding(.bottom, 58)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: foodStore.toast?.id)
    }
}


// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(FoodStore())
}
