import SwiftUI

// MARK: - Today tab ("Daily Quests")
// The mascot sums up the day, and each food that needs attention is a quest:
//   • Rescue quests – food that expires within 6 days (eat it → earn XP)
//   • Check quests  – food past its date (tossed it, or still good?)
// A few rescue recipes are suggested at the bottom.

struct TodayView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var myRecipes: MyRecipeStore

    @State private var onlineRecipes: [Recipe] = []
    @State private var showAllQuests = false
    private let collapsedCount = 5

    /// Opens Food Details from the "Still good" button.
    @State private var detailID: UUID?

    // MARK: - Data

    private var expiredItems: [FoodItem] {
        foodStore.activeItemsByUrgency.filter { $0.freshnessLevel == .expired }
    }

    /// Expires in 0–6 days, most urgent first.
    private var priorityItems: [FoodItem] {
        foodStore.activeItemsByUrgency.filter { RecipeData.needsAttention($0) }
    }

    private var recommendedRecipes: [Recipe] {
        let mine = myRecipes.allRecipes.filter { RecipeData.matchCount($0, priorityItems) > 0 }
        return RecipeData.merged(
            local: mine + RecipeData.recommendations(for: priorityItems),
            online: onlineRecipes,
            items: foodStore.foodItems
        )
    }

    /// Reload online recipes only when the urgent food changes.
    private var priorityKey: String {
        priorityItems.map(\.name).joined(separator: "|")
    }

    // MARK: - Body

    var body: some View {
        // Computed once per render.
        let expired = expiredItems
        let priority = priorityItems
        let visible = showAllQuests ? priority : Array(priority.prefix(collapsedCount))
        let recipes = priority.isEmpty ? [] : Array(recommendedRecipes.prefix(3))
        let allItems = foodStore.foodItems
        let questsLeft = expired.count + priority.count

        return ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Today")
                        .font(.game(32, .bold, relativeTo: .largeTitle))
                        .foregroundStyle(Game.brown)
                    Group {
                        if questsLeft == 0 {
                            Text("\(Date.now.formatted(.dateTime.weekday(.wide))), all caught up")
                        } else if questsLeft == 1 {
                            Text("\(Date.now.formatted(.dateTime.weekday(.wide))), 1 thing to use up")
                        } else {
                            Text("\(Date.now.formatted(.dateTime.weekday(.wide))), \(questsLeft) things to use up")
                        }
                    }
                    .font(.system(size: 15))
                    .foregroundStyle(Game.brownSoft)
                }
                .padding(.top, 12)

                MascotSays(text: mascotText(priority: priority, expired: expired))
                    .padding(.top, 6)

                if !priority.isEmpty {
                    HStack(alignment: .firstTextBaseline) {
                        GameSectionHeader(title: "Use Soon")
                        Text("+\(availableXP(priority)) XP available")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Game.brownSoft)
                            .fixedSize()
                    }

                    VStack(spacing: 0) {
                        ForEach(Array(visible.enumerated()), id: \.element.id) { index, item in
                            if index > 0 { DashedDivider() }
                            useSoonRow(item)
                        }
                    }
                    .gameCard(padding: 0)

                    if priority.count > collapsedCount {
                        Button {
                            withAnimation(.snappy) { showAllQuests.toggle() }
                        } label: {
                            if showAllQuests {
                                Text("Show Less")
                            } else {
                                Text("Show \(priority.count - collapsedCount) More")
                            }
                        }
                        .buttonStyle(.chunky(.white, small: true))
                    }
                }

                if !expired.isEmpty {
                    GameSectionHeader(title: "Past Its Date", count: expired.count)
                    VStack(spacing: 0) {
                        ForEach(Array(expired.enumerated()), id: \.element.id) { index, item in
                            if index > 0 { DashedDivider() }
                            expiredRow(item)
                        }
                    }
                    .gameCard(padding: 0)
                }

                if questsLeft == 0 {
                    Button("Add Food") {
                        router.selectedTab = .add
                    }
                    .buttonStyle(.chunky(.green))
                    .padding(.top, 4)
                }

                if !recipes.isEmpty {
                    GameSectionHeader(title: "Cook Something")
                    VStack(spacing: 10) {
                        ForEach(recipes) { recipe in
                            let rescue = RecipeData.rescueItem(for: recipe, in: allItems)
                            NavigationLink {
                                RecipeDetailView(recipe: recipe, focusIngredient: rescue)
                            } label: {
                                RecipeBookCard(
                                    recipe: recipe,
                                    fridgeCount: RecipeData.matchCount(recipe, allItems),
                                    rescueFood: rescue,
                                    uses: RecipeData.fridgeItems(for: recipe, in: allItems)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button("See All Recipes") {
                        router.openRecipes()
                    }
                    .buttonStyle(.chunky(.white, small: true))
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .gameBackground()
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(item: $detailID) { id in
            if let item = foodStore.foodItems.first(where: { $0.id == id }) {
                FoodDetailView(item: item)
            }
        }
        .task(id: priorityKey) {
            onlineRecipes = await MealDBService.recommendations(for: priorityItems).recipes
        }
    }

    // MARK: - Mascot

    private func mascotText(priority: [FoodItem], expired: [FoodItem]) -> Text {
        let urgent = priority.filter { $0.freshnessLevel == .urgent }
        let rescued = foodStore.rescuedToday

        if foodStore.activeItemsByUrgency.isEmpty {
            return Text("Your fridge is empty. Add some food and I'll keep an eye on it!")
        } else if urgent.count >= 2 {
            return Text("\(urgent[0].name) and \(urgent[1].name) are almost out of HP. Can you save them today?")
        } else if let first = urgent.first {
            return Text("\(first.name) is almost out of HP. Can you save it today?")
        } else if let first = priority.first {
            return Text("\(first.name) should be eaten this week. Want a recipe idea?")
        } else if !expired.isEmpty {
            return Text("Some Freshlings are past their date. Are they still good?")
        } else if rescued > 0 {
            return Text("Nice! You rescued \(rescued) today. Every Freshling is happy.")
        }
        return Text("All quests done! Every Freshling is happy and fresh.")
    }

    // MARK: - Rows

    private func availableXP(_ items: [FoodItem]) -> Int {
        var total = 0
        for item in items { total += FoodStore.questXP(for: item) }
        return total
    }

    /// Food that expires soon: tap for details, "Ate it" to rescue one (earns XP).
    private func useSoonRow(_ item: FoodItem) -> some View {
        HStack(spacing: 12) {
            NavigationLink {
                FoodDetailView(item: item)
            } label: {
                HStack(spacing: 12) {
                    FreshlingAvatar(item: item, size: 46)
                        .wiggle(item.freshnessLevel == .urgent)

                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Game.brown)
                            .lineLimit(1)
                        Group {
                            if item.quantity > 1 {
                                Text("\(item.daysLeftText), \(item.quantity) left")
                            } else {
                                Text(item.daysLeftText)
                            }
                        }
                        .font(.system(size: 13))
                        .foregroundStyle(item.freshnessLevel == .urgent ? Game.redDark : Game.brownSoft)
                        XPTag(xp: FoodStore.questXP(for: item))
                            .padding(.top, 1)
                    }

                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                foodStore.markAsUsed(item, quantity: 1)
                FreshlingsHaptics.success()
            } label: {
                if item.quantity > 1 {
                    Text("Ate 1")
                } else {
                    Text("Ate it")
                }
            }
            .buttonStyle(.chunky(.green, small: true, fullWidth: false))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .contextMenu {
            Button {
                router.openRecipes(for: item)
            } label: {
                Label("Find Recipes", systemImage: "fork.knife")
            }
        }
    }

    /// Food past its date: "Tossed" counts it as wasted; "Still good"
    /// opens Food Details (mark it used there, or change the date).
    private func expiredRow(_ item: FoodItem) -> some View {
        HStack(spacing: 10) {
            FreshlingAvatar(item: item, size: 46)

            VStack(alignment: .leading, spacing: 1) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Game.brown)
                    .lineLimit(1)
                Text(item.daysLeftText)
                    .font(.system(size: 13))
                    .foregroundStyle(Game.brownSoft)
                    .lineLimit(2)
            }

            Spacer(minLength: 4)

            // Stacked so the food name keeps room on small phones.
            VStack(spacing: 6) {
                Button("Still good") {
                    detailID = item.id
                }
                .buttonStyle(.chunky(.white, small: true))

                Button("Tossed") {
                    foodStore.markAsWasted(item)
                    FreshlingsHaptics.light()
                }
                .buttonStyle(.chunky(.red, small: true))
            }
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}

#Preview {
    NavigationStack {
        TodayView()
    }
    .environmentObject(FoodStore())
    .environmentObject(AppRouter())
    .environmentObject(MyRecipeStore())
}
