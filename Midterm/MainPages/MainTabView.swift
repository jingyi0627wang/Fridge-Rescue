
import SwiftUI

struct MainTabView: View {

    @EnvironmentObject var foodStore: FoodStore

    // MARK: - Freshlings Colors
    private let freshGreen = Color(
        red: 0.53,
        green: 0.89,
        blue: 0.36
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
            AddFoodTabView()
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
                ImpactView()
            }
            .tabItem {
                Image(systemName: "chart.bar.fill")
                Text("Impact")
            }
        }
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


// MARK: - Add Food Tab
// AddFoodView (Member 2) has its own NavigationStack + Cancel button,
// so it is shown as a sheet instead of being pushed inside the tab.

struct AddFoodTabView: View {

    @EnvironmentObject var foodStore: FoodStore
    @State private var showAddFood = false

    private let freshGreen = Color(red: 0.53, green: 0.89, blue: 0.36)
    private let darkGreen = Color(red: 0.22, green: 0.49, blue: 0.19)
    private let brown = Color(red: 0.34, green: 0.27, blue: 0.22)
    private let secondary = Color(red: 0.50, green: 0.48, blue: 0.41)
    private let creamBackground = Color(red: 0.985, green: 0.992, blue: 0.970)

    var body: some View {

        ZStack {

            creamBackground
                .ignoresSafeArea()

            VStack(spacing: 18) {

                Image("FreshlingsCharacter")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120)
                    .accessibilityHidden(true)

                Text("Add a Freshling")
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(brown)

                Text("Scan a barcode or type the food name. We'll suggest an expiration date for you.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                Button {
                    showAddFood = true
                } label: {
                    Label("Add Food", systemImage: "plus")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(darkGreen)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(freshGreen, in: Capsule())
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
        }
        .sheet(isPresented: $showAddFood) {
            AddFoodView(store: foodStore)
        }
    }
}


// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(FoodStore())
}
