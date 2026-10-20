
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
    private let freshGreen = FL.leafDeep   // selected tab (design: leaf-deep)

    var body: some View {

        TabView(selection: $router.selectedTab) {

            // MARK: - My Fridge
            NavigationStack {
                HomeView()
            }
            .tabItem {
                tabIcon("TabFridge", for: .fridge)
                Text("Fridge")
            }
            .tag(AppTab.fridge)

            // MARK: - Today
            NavigationStack {
                TodayView()
            }
            .tabItem {
                tabIcon("TabToday", for: .today)
                Text("Today")
            }
            .tag(AppTab.today)

            // MARK: - Add Food
            NavigationStack {
                AddFoodView(store: foodStore)
            }
            .tabItem {
                tabIcon("TabAdd", for: .add)
                Text("Add")
            }
            .tag(AppTab.add)

            // MARK: - Recipes
            NavigationStack {
                RecipeListView()
            }
            .id(router.recipesStackID)
            .tabItem {
                tabIcon("TabRecipes", for: .recipes)
                Text("Recipes")
            }
            .tag(AppTab.recipes)

            // MARK: - Impact
            NavigationStack {
                ImpactView()
            }
            .tabItem {
                tabIcon("TabImpact", for: .impact)
                Text("Impact")
            }
            .tag(AppTab.impact)
        }
        .environmentObject(router)
        .tint(freshGreen)
        .sensoryFeedback(
                   .selection,
                   trigger: router.selectedTab
               )
        // Undo bar for used / wasted / deleted / cooked actions.
        .overlay(alignment: .bottom) {
            if let toast = foodStore.toast {
                UndoToastView(toast: toast)
                    .padding(.bottom, 58)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(duration: 0.35), value: foodStore.toast?.id)
        // "Level up" celebration
        .overlay {
            if let level = foodStore.levelUp {
                LevelUpView(level: level) {
                    withAnimation { foodStore.levelUp = nil }
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: foodStore.levelUp)
    }

    // MARK: - Tab icons
    // Freshlings drawings from Assets.xcassets/Tabs (28pt, 1x/2x/3x).
    // Selected tab = full color, other tabs = the gray "Inactive" version.
    private func tabIcon(_ name: String, for tab: AppTab) -> Image {
        let asset = router.selectedTab == tab ? name : name + "Inactive"
        return Image(asset).renderingMode(.original)
    }
}


// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(FoodStore())
        .environmentObject(MyRecipeStore())
}
