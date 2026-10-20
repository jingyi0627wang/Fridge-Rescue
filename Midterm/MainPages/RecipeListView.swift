import SwiftUI

// MARK: - Recipes tab
// Search bar on top, then three pages:
//   • Discover   – recipes for your fridge (rescue first), plus online search
//   • My Recipes – recipes you wrote (+ button to add one)
//   • Community  – weekly challenge + shared recipes (yours + sample posts)
// Fridge, Today and Food Details jump here via AppRouter.openRecipes(for:)
// with an ingredient already selected.

struct RecipeListView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var myRecipes: MyRecipeStore

    enum Page: CaseIterable {
        case discover, mine, community

        var title: LocalizedStringKey {
            switch self {
            case .discover: return "Discover"
            case .mine: return "My Recipes"
            case .community: return "Community"
            }
        }
    }

    @State private var page: Page = .discover
    @State private var searchText = ""
    @State private var showAddRecipe = false

    // Online recipes from TheMealDB (loaded in .task below)
    @State private var onlineRecipes: [Recipe] = []
    @State private var onlineSearchResults: [Recipe] = []
    @State private var isLoadingOnline = false
    @State private var isOffline = false

    /// Sections start short; "Show all" expands one (key = section id).
    @State private var expandedSections: Set<String> = []
    private let collapsedCount = 4

    private var activeItems: [FoodItem] {
        foodStore.activeItemsByUrgency
    }

    private var query: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isSearching: Bool { !query.isEmpty }

    /// Ingredient chips: only food that expires soon (plus the selected one).
    private var chipItems: [FoodItem] {
        var items = activeItems.filter { RecipeData.needsAttention($0) }
        if let focusItem, !items.contains(where: { $0.id == focusItem.id }) {
            items.insert(focusItem, at: 0)
        }
        return items
    }

    /// Selected ingredient (nil = All).
    private var focusItem: FoodItem? {
        guard let id = router.recipeFocusID else { return nil }
        return activeItems.first { $0.id == id }
    }

    /// Items used to look up recipes.
    private var sourceItems: [FoodItem] {
        if let focusItem { return [focusItem] }
        return activeItems
    }

    /// Built-in + my recipes that use at least one fridge item.
    private var localRecommendations: [Recipe] {
        let mine = myRecipes.allRecipes.filter { RecipeData.matchCount($0, sourceItems) > 0 }
        return mine + RecipeData.recommendations(for: sourceItems)
    }

    private var recipes: [Recipe] {
        let all = RecipeData.merged(local: localRecommendations, online: onlineRecipes, items: foodStore.foodItems)
        guard let focusItem else { return all }
        // Only recipes that actually use the selected food.
        return all.filter { recipe in
            recipe.ingredients.contains { FoodMatcher.matches(ingredient: $0, foodName: focusItem.name) }
        }
    }

    /// Reload online recipes when the fridge or the selected ingredient changes.
    private var fridgeKey: String {
        sourceItems.map(\.name).sorted().joined(separator: "|")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                GameSearchField(text: $searchText, prompt: "Search recipes or ingredients")
                pagePicker

                switch page {
                case .discover:
                    if isSearching {
                        searchResults
                    } else {
                        discover
                    }
                case .mine:
                    mine
                case .community:
                    CommunityFeed(searchText: query)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.immediately)
        .gameBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showAddRecipe) {
            AddRecipeView()
        }
        .task(id: fridgeKey) {
            isLoadingOnline = true
            let result = await MealDBService.recommendations(for: sourceItems)
            onlineRecipes = result.recipes
            isOffline = result.isOffline
            isLoadingOnline = false
        }
        .task(id: query) {
            // Wait until the user stops typing, then search TheMealDB too.
            guard query.count >= 2 else {
                onlineSearchResults = []
                return
            }
            try? await Task.sleep(for: .milliseconds(450))
            guard !Task.isCancelled else { return }
            onlineSearchResults = await MealDBService.search(query)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("Recipes")
                .font(.game(32, .bold, relativeTo: .largeTitle))
                .foregroundStyle(Game.brown)
            Spacer(minLength: 8)
            Button {
                showAddRecipe = true
            } label: {
                Label("New", systemImage: "plus")
            }
            .buttonStyle(.chunky(.green, small: true, fullWidth: false))
            .accessibilityLabel("Add my recipe")
        }
        .padding(.top, 12)
    }

    // MARK: - Page picker (Discover / My Recipes / Community)

    private var pagePicker: some View {
        HStack(spacing: 4) {
            ForEach(Page.allCases, id: \.self) { item in
                let selected = page == item
                Button {
                    withAnimation(.snappy) { page = item }
                } label: {
                    Text(item.title)
                        .font(.ui(14, .semibold))
                        .foregroundStyle(selected ? Game.brown : Game.brownSoft)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 7)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: 9, style: .continuous).fill(.white)
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selected ? .isSelected : [])
            }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(Game.field))
        .sensoryFeedback(.selection, trigger: page)
    }

    // MARK: - Discover

    @ViewBuilder
    private var discover: some View {
        let sections = RecipeData.sections(for: recipes, items: foodStore.foodItems)
        let items = foodStore.foodItems

        if !chipItems.isEmpty {
            ingredientChips
        }

        if isLoadingOnline {
            HStack(spacing: 8) {
                ProgressView()
                Text("Finding more recipes online…")
            }
            .font(.game(13, .medium))
            .foregroundStyle(Game.brownSoft)
        } else if isOffline {
            Label("Offline: showing built-in recipes only", systemImage: "wifi.slash")
                .font(.game(13, .medium))
                .foregroundStyle(Game.brownSoft)
        }

        if sections.isEmpty && !isLoadingOnline {
            if activeItems.isEmpty {
                emptyCard(title: "No recipes yet!",
                          message: "Add food to your fridge to get recipe ideas, or search above.")
            } else {
                emptyCard(title: "No recipes yet!",
                          message: "No recipes found for this food. Try another ingredient or search above.")
            }
        } else {
            recipeSection(id: "rescue", title: "Rescue Recipes", recipes: sections.rescue, items: items)
            recipeSection(id: "most", title: "Uses Most of Your Fridge", recipes: sections.usesMost, items: items)
            recipeSection(id: "more", title: "More Ideas", recipes: sections.moreIdeas, items: items)

            if !onlineRecipes.isEmpty {
                Text("Recipes with photos are from TheMealDB.com")
                    .font(.game(12, .medium))
                    .foregroundStyle(Game.brownSoft)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 4)
            }
        }
    }

    private var ingredientChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                GameChip(title: "All", isSelected: focusItem == nil) {
                    router.recipeFocusID = nil
                }
                ForEach(chipItems) { item in
                    GameChip(title: LocalizedStringKey(item.name),
                             isSelected: focusItem?.id == item.id,
                             showsAlert: item.freshnessLevel == .urgent) {
                        router.recipeFocusID = (focusItem?.id == item.id) ? nil : item.id
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Search

    /// Every recipe the app knows (mine, built-in, community, online),
    /// filtered by name or ingredient.
    private var searchMatches: [Recipe] {
        let lowered = query.lowercased()
        let community: [Recipe] = CommunityData.samplePosts.map(\.recipe)
        let pool: [Recipe] = myRecipes.allRecipes + RecipeData.recipes + community
            + onlineRecipes + onlineSearchResults

        var seen = Set<String>()
        var results: [Recipe] = []
        for recipe in pool where seen.insert(recipe.name.lowercased()).inserted {
            let nameMatches = recipe.name.lowercased().contains(lowered)
            let ingredientMatches = recipe.ingredients.contains { $0.lowercased().contains(lowered) }
            if nameMatches || ingredientMatches {
                results.append(recipe)
            }
        }
        return results
    }

    @ViewBuilder
    private var searchResults: some View {
        let matches = searchMatches

        if matches.isEmpty {
            emptyCard(title: "No matches",
                      message: "Try another dish or ingredient, like \"pasta\" or \"banana\".")
        } else {
            GameSectionHeader(title: "Results", count: matches.count)
            recipeCards(matches, items: foodStore.foodItems)
        }
    }

    // MARK: - My Recipes

    private func myMatches(_ all: [Recipe]) -> [Recipe] {
        guard isSearching else { return all }
        let lowered = query.lowercased()
        return all.filter { recipe in
            recipe.name.lowercased().contains(lowered) ||
            recipe.ingredients.contains { $0.lowercased().contains(lowered) }
        }
    }

    @ViewBuilder
    private var mine: some View {
        let all = myRecipes.allRecipes
        let shown = myMatches(all)

        Button {
            showAddRecipe = true
        } label: {
            Label("Add My Recipe", systemImage: "square.and.pencil")
        }
        .buttonStyle(.chunky(.orange))

        if all.isEmpty {
            VStack(spacing: 10) {
                FreshlingMascot(size: 70, color: Game.orange)
                Text("Your recipe book is empty")
                    .font(.game(19, .bold))
                    .foregroundStyle(Game.brown)
                Text("Save your go-to dishes with a photo. Recipes that use your fridge food show up as rescue ideas.")
                    .font(.game(14, .medium))
                    .foregroundStyle(Game.brownSoft)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .gameCard(padding: 22)
        } else if shown.isEmpty {
            emptyCard(title: "No matches", message: "None of your recipes match that search.")
        } else {
            GameSectionHeader(title: "My Recipes", count: shown.count)
            recipeCards(shown, items: foodStore.foodItems)
        }
    }

    // MARK: - Shared pieces

    private func recipeCards(_ list: [Recipe], items: [FoodItem]) -> some View {
        LazyVStack(spacing: 10) {
            ForEach(list) { recipe in
                let rescue = RecipeData.rescueItem(for: recipe, in: items)
                NavigationLink {
                    RecipeDetailView(recipe: recipe, focusIngredient: rescue)
                } label: {
                    RecipeBookCard(
                        recipe: recipe,
                        fridgeCount: RecipeData.matchCount(recipe, items),
                        rescueFood: rescue,
                        uses: RecipeData.fridgeItems(for: recipe, in: items)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    @ViewBuilder
    private func recipeSection(id: String, title: LocalizedStringKey,
                               recipes: [Recipe], items: [FoodItem]) -> some View {
        if !recipes.isEmpty {
            let isExpanded = expandedSections.contains(id)
            let visible = isExpanded ? recipes : Array(recipes.prefix(collapsedCount))

            GameSectionHeader(title: title, count: recipes.count)
            recipeCards(visible, items: items)

            if recipes.count > collapsedCount {
                Button {
                    withAnimation(.snappy) {
                        if isExpanded { _ = expandedSections.remove(id) } else { _ = expandedSections.insert(id) }
                    }
                } label: {
                    if isExpanded {
                        Text("Show Less")
                    } else {
                        Text("Show All \(recipes.count)")
                    }
                }
                .buttonStyle(.chunky(.white, small: true))
            }
        }
    }

    private func emptyCard(title: LocalizedStringKey, message: LocalizedStringKey) -> some View {
        VStack(spacing: 8) {
            FreshlingMascot(size: 60, color: Game.gray)
            Text(title)
                .font(.game(18, .bold))
                .foregroundStyle(Game.brown)
            Text(message)
                .font(.game(14, .medium))
                .foregroundStyle(Game.brownSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .gameCard(padding: 22)
    }
}

#Preview {
    NavigationStack {
        RecipeListView()
    }
    .environmentObject(FoodStore())
    .environmentObject(AppRouter())
    .environmentObject(MyRecipeStore())
}
