import SwiftUI

// MARK: - Freshlings Recipe List (Recipes tab)
// The ONE place to browse recipes. Home, Today and Food Details jump here
// via AppRouter.openRecipes(for:) with an ingredient chip already selected.
//
// Sections:
//   1. Rescue First           – uses food that expires soon (most urgent first)
//   2. Uses Most of Your Fridge – uses 2+ fridge items
//   3. More Ideas             – everything else (incl. online recipes)

struct RecipeListView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var router: AppRouter

    // Online recipes from TheMealDB (loaded in .task below)
    @State private var onlineRecipes: [Recipe] = []
    @State private var isLoadingOnline = false
    @State private var isOffline = false

    private var activeItems: [FoodItem] {
        foodStore.foodItems
            .filter { $0.status == .active }
            .sorted { $0.hpPercentage < $1.hpPercentage }
    }

    /// Selected ingredient chip (nil = All).
    private var focusItem: FoodItem? {
        guard let id = router.recipeFocusID else { return nil }
        return activeItems.first { $0.id == id }
    }

    /// Items used to look up recipes.
    private var sourceItems: [FoodItem] {
        if let focusItem { return [focusItem] }
        return activeItems
    }

    private var recipes: [Recipe] {
        let all = RecipeData.merged(
            local: RecipeData.recommendations(for: sourceItems),
            online: onlineRecipes,
            items: foodStore.foodItems
        )
        guard let focusItem else { return all }
        // Only recipes that actually use the selected food.
        return all.filter { recipe in
            recipe.ingredients.contains { FoodMatcher.matches(ingredient: $0, foodName: focusItem.name) }
        }
    }

    private var sections: RecipeSections {
        RecipeData.sections(for: recipes, items: foodStore.foodItems)
    }

    /// Reload online recipes when the fridge or the selected chip changes.
    private var fridgeKey: String {
        sourceItems.map(\.name).sorted().joined(separator: "|")
    }

    var body: some View {
        ZStack {
            RecipeFreshlingsStyle.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    headerSection

                    if !activeItems.isEmpty {
                        ingredientChips
                    }

                    onlineStatus

                    if sections.isEmpty && !isLoadingOnline {
                        emptyState
                    } else {
                        recipeSection(
                            "Rescue First",
                            subtitle: "Uses food that expires soon",
                            icon: "exclamationmark.circle.fill",
                            tint: RecipeFreshlingsStyle.orange,
                            recipes: sections.rescue
                        )
                        recipeSection(
                            "Uses Most of Your Fridge",
                            subtitle: "Less to buy",
                            icon: "refrigerator.fill",
                            tint: RecipeFreshlingsStyle.leafGreen,
                            recipes: sections.usesMost
                        )
                        recipeSection(
                            "More Ideas",
                            subtitle: "Uses 1 fridge item",
                            icon: "sparkles",
                            tint: RecipeFreshlingsStyle.secondary,
                            recipes: sections.moreIdeas
                        )

                        if !onlineRecipes.isEmpty {
                            Text("Recipes with photos are from TheMealDB.com")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(RecipeFreshlingsStyle.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 110)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .task(id: fridgeKey) {
            isLoadingOnline = true
            let result = await MealDBService.recommendations(for: sourceItems)
            onlineRecipes = result.recipes
            isOffline = result.isOffline
            isLoadingOnline = false
        }
    }

    // MARK: Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("FRESHLINGS KITCHEN")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.4)
            }
            .foregroundStyle(RecipeFreshlingsStyle.leafGreen)

            Text(focusItem.map { "Let's use \($0.name)!" } ?? "Let's cook!")
                .font(.system(size: 33, weight: .heavy, design: .rounded))
                .foregroundStyle(RecipeFreshlingsStyle.brown)
                .fixedSize(horizontal: false, vertical: true)

            Text(focusItem.map { "\($0.name): \($0.daysLeftText.lowercased())." }
                 ?? "Recipes for the food already in your fridge.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(RecipeFreshlingsStyle.secondary)
        }
    }

    // MARK: Ingredient chips

    private var ingredientChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip("All", isSelected: focusItem == nil, isUrgent: false) {
                    router.recipeFocusID = nil
                }
                ForEach(activeItems) { item in
                    chip(item.name,
                         isSelected: focusItem?.id == item.id,
                         isUrgent: RecipeData.needsAttention(item)) {
                        router.recipeFocusID = (focusItem?.id == item.id) ? nil : item.id
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    private func chip(_ title: String, isSelected: Bool, isUrgent: Bool,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if isUrgent {
                    Circle()
                        .fill(RecipeFreshlingsStyle.orange)
                        .frame(width: 7, height: 7)
                }
                Text(title)
            }
            .font(.system(size: 13, weight: .bold, design: .rounded))
            .foregroundStyle(isSelected ? RecipeFreshlingsStyle.leafGreen : RecipeFreshlingsStyle.secondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(isSelected ? RecipeFreshlingsStyle.green : RecipeFreshlingsStyle.card, in: Capsule())
            .overlay(Capsule().stroke(RecipeFreshlingsStyle.outline, lineWidth: isSelected ? 0 : 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isUrgent ? "\(title), expires soon" : title)
    }

    // MARK: Online status

    @ViewBuilder
    private var onlineStatus: some View {
        if isLoadingOnline {
            HStack(spacing: 8) {
                ProgressView()
                Text("Finding more recipes online…")
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
            .foregroundStyle(RecipeFreshlingsStyle.secondary)
        } else if isOffline {
            Label("Offline: showing built-in recipes only", systemImage: "wifi.slash")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(RecipeFreshlingsStyle.secondary)
        }
    }

    // MARK: Sections

    @ViewBuilder
    private func recipeSection(_ title: String, subtitle: String, icon: String,
                               tint: Color, recipes: [Recipe]) -> some View {
        if !recipes.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(tint)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.system(size: 21, weight: .heavy, design: .rounded))
                            .foregroundStyle(RecipeFreshlingsStyle.brown)
                        Text(subtitle)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(RecipeFreshlingsStyle.secondary)
                    }
                    Spacer(minLength: 4)
                    Text("\(recipes.count)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(tint)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(RecipeFreshlingsStyle.lightGreen, in: Capsule())
                }

                ForEach(recipes) { recipe in
                    NavigationLink {
                        RecipeDetailView(
                            recipe: recipe,
                            focusIngredient: RecipeData.rescueItem(for: recipe, in: foodStore.foodItems)
                        )
                    } label: {
                        FreshlingsRecipeCard(
                            recipe: recipe,
                            rescueFood: RecipeData.rescueItem(for: recipe, in: foodStore.foodItems),
                            fridgeCount: RecipeData.matchCount(recipe, foodStore.foodItems)
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

            Text(activeItems.isEmpty
                 ? "Add food to your fridge to get recipe ideas."
                 : "No recipes found for this food. Try another ingredient or All.")
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
    let fridgeCount: Int

    var body: some View {
        HStack(spacing: 14) {
            thumbnail
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
                    Label("Rescue \(rescueFood.name) · \(rescueFood.daysLeftText.lowercased())",
                          systemImage: "leaf.fill")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(RecipeFreshlingsStyle.orange)
                        .lineLimit(1)
                }

                Label("\(fridgeCount)/\(recipe.items.count) in your fridge", systemImage: "refrigerator")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(RecipeFreshlingsStyle.leafGreen)

                HStack(spacing: 6) {
                    Image(systemName: "clock")
                    Text(recipe.timeText)
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

    /// Photo for online recipes, emoji for built-in ones.
    @ViewBuilder
    private var thumbnail: some View {
        if let url = recipe.imageURL {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                Text(recipe.emoji).font(.system(size: 35))
            }
        } else {
            Text(recipe.emoji).font(.system(size: 35))
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
    }
    .environmentObject(FoodStore())
    .environmentObject(AppRouter())
}

