import SwiftUI

struct RecipeListView: View {

    @EnvironmentObject var foodStore: FoodStore
    var focusIngredient: FoodItem?

    // MARK: - Colors

    private let titleColor = Color(
        red: 0.12,
        green: 0.12,
        blue: 0.10
    )

    private let bodyColor = Color(
        red: 0.35,
        green: 0.35,
        blue: 0.31
    )

    private let mutedColor = Color(
        red: 0.46,
        green: 0.45,
        blue: 0.40
    )

    // MARK: - Recommended Recipes

    private var recipes: [Recipe] {
        if let focusIngredient {
            return RecipeData.recommendations(for: [focusIngredient])
        } else {
            return RecipeData.recommendations(for: foodStore.foodItems)
        }
    }

    // Find which fridge ingredient this recipe helps rescue
    private func rescueIngredient(for recipe: Recipe) -> FoodItem? {

        let activeFoods = foodStore.foodItems
            .filter { $0.status == .active }
            .sorted { $0.hpPercentage < $1.hpPercentage }

        return activeFoods.first { food in
            recipe.ingredients.contains {
                $0.lowercased() == food.name.lowercased()
            }
        }
    }

    // MARK: - Body

    var body: some View {

        ZStack {

            PremiumTheme.background
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {

                VStack(alignment: .leading, spacing: 30) {

                    headerSection

                    recipeSection

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 22)
                .padding(.top, 28)
                .padding(.bottom, 110)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Header

    private var headerSection: some View {

        VStack(alignment: .leading, spacing: 10) {

            Text("RECIPES")
                .font(.system(size: 13, weight: .bold))
                .tracking(3)
                .foregroundStyle(PremiumTheme.olive)

            Text(
                focusIngredient == nil
                ? "Cook with what\nyou have."
                : "Cook with\n\(focusIngredient!.name)."
            )
            .font(.system(size: 38, weight: .bold))
            .foregroundStyle(titleColor)
            .fixedSize(horizontal: false, vertical: true)

            Text(
                focusIngredient == nil
                ? "Recipes based on ingredients already in your fridge."
                : "Recipes that help you use \(focusIngredient!.name) before it expires."
            )
            .font(.system(size: 16, weight: .regular))
            .foregroundStyle(bodyColor)
            .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Recipe Section

    private var recipeSection: some View {

        VStack(alignment: .leading, spacing: 18) {

            HStack {

                Text("Recommended")
                    .font(.system(size: 27, weight: .bold))
                    .foregroundStyle(titleColor)

                Spacer()

                Text("\(recipes.count) RECIPES")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(2)
                    .foregroundStyle(mutedColor)
            }

            if recipes.isEmpty {

                emptyState

            } else {

                ForEach(recipes) { recipe in

                    let rescueFood = rescueIngredient(for: recipe)

                    NavigationLink {

                        RecipeDetailView(
                            recipe: recipe,
                            focusIngredient: rescueFood
                        )
                        .environmentObject(foodStore)

                    } label: {

                        RecipeListCard(
                            recipe: recipe,
                            rescueFood: rescueFood
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {

        VStack(spacing: 14) {

            ZStack {

                Circle()
                    .fill(PremiumTheme.olive.opacity(0.10))
                    .frame(width: 60, height: 60)

                Image(systemName: "fork.knife")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(PremiumTheme.olive)
            }

            Text("No recipes yet")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(titleColor)

            Text(
                "Add more ingredients to your fridge to discover recipe ideas."
            )
            .font(.system(size: 14))
            .foregroundStyle(bodyColor)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 34)
        .padding(.horizontal, 20)
        .background(Color.white.opacity(0.82))
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
    }
}


// MARK: - Recipe Card

private struct RecipeListCard: View {

    let recipe: Recipe
    let rescueFood: FoodItem?

    // Strong contrast colors specifically for recipe cards
    private let titleColor = Color(
        red: 0.13,
        green: 0.13,
        blue: 0.11
    )

    private let bodyColor = Color(
        red: 0.36,
        green: 0.36,
        blue: 0.32
    )

    private let mutedColor = Color(
        red: 0.46,
        green: 0.45,
        blue: 0.40
    )

    private let rescueColor = Color(
        red: 0.78,
        green: 0.32,
        blue: 0.20
    )

    var body: some View {

        HStack(spacing: 18) {

            // MARK: Recipe Icon

            ZStack {

                RoundedRectangle(
                    cornerRadius: 20,
                    style: .continuous
                )
                .fill(
                    PremiumTheme.olive.opacity(0.08)
                )

                Text(recipe.emoji)
                    .font(.system(size: 38))
            }
            .frame(width: 92, height: 92)

            // MARK: Recipe Information

            VStack(alignment: .leading, spacing: 7) {

                Text(recipe.name)
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(titleColor)
                    .lineLimit(2)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )

                Text(
                    recipe.ingredients
                        .prefix(2)
                        .joined(separator: " • ")
                )
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(bodyColor)
                .lineLimit(1)

                // Rescue information
                if let rescueFood {

                    HStack(spacing: 6) {

                        Image(systemName: "leaf.fill")
                            .font(.system(size: 11))

                        Text("Helps rescue \(rescueFood.name)")
                            .font(
                                .system(
                                    size: 13,
                                    weight: .semibold
                                )
                            )
                    }
                    .foregroundStyle(rescueColor)
                }

                // Time + difficulty
                HStack(spacing: 7) {

                    Image(systemName: "clock")
                        .font(.system(size: 12))

                    Text("\(recipe.time) min")

                    Text("•")

                    Text(recipe.difficulty)
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(mutedColor)
            }

            Spacer(minLength: 4)

            // MARK: Arrow

            Image(systemName: "chevron.right")
                .font(
                    .system(
                        size: 14,
                        weight: .bold
                    )
                )
                .foregroundStyle(bodyColor)
        }
        .padding(18)
        .background(
            Color.white.opacity(0.88)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 24,
                style: .continuous
            )
            .stroke(
                Color.black.opacity(0.07),
                lineWidth: 1
            )
        }
    }
}


// MARK: - Preview

#Preview {

    NavigationStack {

        RecipeListView()
            .environmentObject(FoodStore())
    }
}
