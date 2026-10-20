import SwiftUI

// MARK: - Freshlings Recipe List
// This file preserves the existing RecipeData recommendation and navigation logic.

struct RecipeListView: View {
    @EnvironmentObject var foodStore: FoodStore
    var focusIngredient: FoodItem?

    private var recipes: [Recipe] {
        if let focusIngredient {
            return RecipeData.recommendations(for: [focusIngredient])
        }
        return RecipeData.recommendations(for: foodStore.foodItems)
    }

    private func rescueIngredient(for recipe: Recipe) -> FoodItem? {
        // Lowest-HP fridge item this recipe uses.
        RecipeData.fridgeItems(for: recipe, in: foodStore.foodItems)
            .min { $0.hpPercentage < $1.hpPercentage }
    }

    var body: some View {
        ZStack {
            RecipeFreshlingsStyle.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                    headerSection
                    recipeSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 110)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 7) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("FRESHLINGS KITCHEN")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.4)
            }
            .foregroundStyle(RecipeFreshlingsStyle.leafGreen)

            Text(focusIngredient == nil ? "Let's cook!" : "Let's use \(focusIngredient!.name)!")
                .font(.system(size: 33, weight: .heavy, design: .rounded))
                .foregroundStyle(RecipeFreshlingsStyle.brown)
                .fixedSize(horizontal: false, vertical: true)

            Text(focusIngredient == nil
                 ? "Tasty ideas for the food already in your fridge."
                 : "Fun ways to rescue \(focusIngredient!.name) before it expires.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(RecipeFreshlingsStyle.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(RecipeFreshlingsStyle.green)
                        .frame(width: 70, height: 70)
                    Text("🥕")
                        .font(.system(size: 35))
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Save food, make something yummy!")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(RecipeFreshlingsStyle.brown)
                    Text("Every rescued ingredient counts.")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(RecipeFreshlingsStyle.secondary)
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RecipeFreshlingsStyle.lightGreen)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        }
    }

    // MARK: Recommendations
    private var recipeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("Recommended")
                    .font(.system(size: 23, weight: .heavy, design: .rounded))
                    .foregroundStyle(RecipeFreshlingsStyle.brown)

                Spacer(minLength: 4)

                Text("\(recipes.count) RECIPES")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .tracking(0.7)
                    .foregroundStyle(RecipeFreshlingsStyle.leafGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(RecipeFreshlingsStyle.lightGreen)
                    .clipShape(Capsule())
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
                        FreshlingsRecipeCard(
                            recipe: recipe,
                            rescueFood: rescueFood
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("🍅")
                .font(.system(size: 52))
                .frame(width: 90, height: 90)
                .background(RecipeFreshlingsStyle.lightGreen)
                .clipShape(Circle())

            Text("No recipes yet!")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(RecipeFreshlingsStyle.brown)

            Text("Add more ingredients to your fridge to discover delicious rescue ideas.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(RecipeFreshlingsStyle.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 22)
        .padding(.vertical, 32)
        .background(RecipeFreshlingsStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

// MARK: - Recipe Card
private struct FreshlingsRecipeCard: View {
    let recipe: Recipe
    let rescueFood: FoodItem?

    var body: some View {
        HStack(spacing: 14) {
            Text(recipe.emoji)
                .font(.system(size: 35))
                .frame(width: 76, height: 85)
                .background(RecipeFreshlingsStyle.lightGreen)
                .clipShape(RoundedRectangle(cornerRadius: 19, style: .continuous))

            VStack(alignment: .leading, spacing: 7) {
                Text(recipe.name)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(RecipeFreshlingsStyle.brown)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(recipe.ingredients.prefix(2).joined(separator: " • "))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(RecipeFreshlingsStyle.secondary)
                    .lineLimit(1)

                if let rescueFood {
                    Label("Rescue \(rescueFood.name)", systemImage: "leaf.fill")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(RecipeFreshlingsStyle.orange)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                    Text("\(recipe.time) min")
                    Text("•")
                    Text(recipe.difficulty)
                }
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(RecipeFreshlingsStyle.secondary)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(RecipeFreshlingsStyle.leafGreen)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RecipeFreshlingsStyle.card)
        .clipShape(RoundedRectangle(cornerRadius: 23, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 23, style: .continuous)
                .stroke(RecipeFreshlingsStyle.outline, lineWidth: 1)
        }
    }
}

// MARK: - Local Palette (no shared theme overrides)
private enum RecipeFreshlingsStyle {
    static let background = Color(red: 0.985, green: 0.989, blue: 0.967)
    static let card = Color.white
    static let lightGreen = Color(red: 0.923, green: 0.975, blue: 0.865)
    static let green = Color(red: 0.53, green: 0.89, blue: 0.36)
    static let leafGreen = Color(red: 0.28, green: 0.58, blue: 0.23)
    static let brown = Color(red: 0.43, green: 0.29, blue: 0.22)
    static let secondary = Color(red: 0.46, green: 0.43, blue: 0.39)
    static let orange = Color(red: 0.91, green: 0.45, blue: 0.17)
    static let outline = Color(red: 0.82, green: 0.90, blue: 0.77).opacity(0.55)
}

#Preview {
    NavigationStack {
        RecipeListView()
            .environmentObject(FoodStore())
    }
}

