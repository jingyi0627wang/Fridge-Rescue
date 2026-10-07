import SwiftUI

struct MainTabView: View {

    @EnvironmentObject var foodStore: FoodStore

    var body: some View {

        TabView {

            // MARK: - My Fridge
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Image(systemName: "refrigerator")
                Text("Fridge")
            }

            // MARK: - Today
            NavigationStack {
                TodayView()
            }
            .tabItem {
                Image(systemName: "clock.fill")
                Text("Today")
            }

            // MARK: - Add Food
            NavigationStack {
                AddFoodPlaceholderView()
            }
            .tabItem {
                Image(systemName: "plus.circle.fill")
                Text("Add")
            }

            // MARK: - Recipes
            NavigationStack {
                RecipeListView()
            }
            .tabItem {
                Image(systemName: "fork.knife")
                Text("Recipes")
            }

            // MARK: - Impact
            NavigationStack {
                ImpactPlaceholderView()
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Impact")
            }
        }
        .tint(
            Color(
                red: 0.34,
                green: 0.46,
                blue: 0.23
            )
        )
    }
}


// MARK: - Temporary Add Food Page
// Member 2 can replace this later.

struct AddFoodPlaceholderView: View {

    var body: some View {

        ZStack {

            Color(
                red: 0.969,
                green: 0.965,
                blue: 0.945
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(
                        Color(
                            red: 0.34,
                            green: 0.46,
                            blue: 0.23
                        )
                    )

                Text("Add Food")
                    .font(.system(size: 30, weight: .bold))

                Text("Manual entry and AI food recognition will appear here.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}


// MARK: - Temporary Impact Page
// Member 4 can replace this later.

struct ImpactPlaceholderView: View {

    var body: some View {

        ZStack {

            Color(
                red: 0.969,
                green: 0.965,
                blue: 0.945
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(
                        Color(
                            red: 0.34,
                            green: 0.46,
                            blue: 0.23
                        )
                    )

                Text("Impact")
                    .font(.system(size: 30, weight: .bold))

                Text("Your food rescue statistics will appear here.")
                    .foregroundStyle(.secondary)
            }
        }
    }
}


// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(FoodStore())
}
