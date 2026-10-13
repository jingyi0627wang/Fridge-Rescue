
import SwiftUI

struct MainTabView: View {

    @EnvironmentObject var foodStore: FoodStore

    // MARK: - Freshlings Colors
    private let freshGreen = Color(
        red: 0.53,
        green: 0.89,
        blue: 0.36
    )

    private let creamBackground = Color(
        red: 0.98,
        green: 0.99,
        blue: 0.96
    )

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
        .tint(freshGreen)
    }
}


// MARK: - Temporary Add Food Page
// Member 2 can replace this later.

struct AddFoodPlaceholderView: View {

    private let freshGreen = Color(
        red: 0.53,
        green: 0.89,
        blue: 0.36
    )

    private let creamBackground = Color(
        red: 0.98,
        green: 0.99,
        blue: 0.96
    )

    var body: some View {

        ZStack {

            creamBackground
                .ignoresSafeArea()

            VStack(spacing: 18) {

                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(freshGreen)

                Text("Add Food")
                    .font(.system(size: 30, weight: .bold))

                Text(
                    "Manual entry and AI food recognition will appear here."
                )
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

    private let freshGreen = Color(
        red: 0.53,
        green: 0.89,
        blue: 0.36
    )

    private let creamBackground = Color(
        red: 0.98,
        green: 0.99,
        blue: 0.96
    )

    var body: some View {

        ZStack {

            creamBackground
                .ignoresSafeArea()

            VStack(spacing: 18) {

                Image(systemName: "chart.bar.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(freshGreen)

                Text("Impact")
                    .font(.system(size: 30, weight: .bold))

                Text(
                    "Your food rescue statistics will appear here."
                )
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

