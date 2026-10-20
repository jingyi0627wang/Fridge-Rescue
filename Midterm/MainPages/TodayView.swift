import SwiftUI

// MARK: - Today tab (Today + Impact in one place)
// Top: your progress (level, streak, money saved, CO₂, weekly goal).
//      Tap it for full stats, badges, charts and history (ImpactView).
// Then the food that needs attention:
//   • Use soon      – expires within 6 days (eat it → earn XP)
//   • Past its date – tossed it, or still good?
// A few recipes that use that food are suggested at the bottom.

struct TodayView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var router: AppRouter
    @EnvironmentObject var myRecipes: MyRecipeStore

    // Weekly goal (set on the full progress page).
    @AppStorage("goalType") private var goalTypeRaw = ""
    @AppStorage("goalTarget") private var goalTarget = 5

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
                    .font(.ui(15))
                    .foregroundStyle(Game.brownSoft)
                }
                .padding(.top, 12)

                progressCard
                    .padding(.top, 6)

                if !priority.isEmpty {
                    HStack(alignment: .firstTextBaseline) {
                        GameSectionHeader(title: "Use Soon")
                        Text("+\(availableXP(priority)) XP available")
                            .font(.ui(13, .medium))
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

    // MARK: - Progress (was the Impact tab)
    // Level + XP, then three equal tiles: streak, money saved, CO₂ saved,
    // and the weekly goal if one is set. Tap → full progress page.

    private var progressCard: some View {
        let info = foodStore.levelInfo
        let goal = GoalType(rawValue: goalTypeRaw)

        return NavigationLink {
            ImpactView()
        } label: {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    FreshlingMascot(size: 40)
                        .overlay(alignment: .bottomTrailing) {
                            Text("\(info.level)")
                                .font(.ui(12, .bold))
                                .foregroundStyle(.white)
                                .frame(width: 22, height: 22)
                                .background(Circle().fill(Game.orange))
                                .overlay(Circle().stroke(.white, lineWidth: 2))
                                .offset(x: 6, y: 4)
                        }

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Level \(info.level) · \(Text(LocalizedStringKey(info.title)))")
                            .font(.ui(16, .semibold))
                            .foregroundStyle(Game.brown)
                        GameProgressBar(progress: info.progress, height: 8)
                        Text("\(info.xpForLevel - info.xpIntoLevel) XP to level \(info.level + 1)")
                            .font(.ui(12))
                            .foregroundStyle(Game.brownSoft)
                    }

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Game.edgeDark)
                }

                HStack(spacing: 8) {
                    progressTile(value: "\(foodStore.rescueStreak)", label: "day streak") {
                        Image(systemName: "flame.fill")
                            .foregroundStyle(foodStore.rescueStreak > 0 ? Game.red : Game.gray)
                    }
                    progressTile(value: foodStore.moneySaved.formatted(.currency(code: "USD").precision(.fractionLength(0))),
                                 label: "money saved") {
                        Image("IconSavings").resizable().scaledToFit()
                    }
                    progressTile(value: String(format: "%.1f kg", foodStore.carbonSaved), label: "CO₂ saved") {
                        Image(systemName: "leaf.fill").foregroundStyle(Game.greenDark)
                    }
                }

                if let goal {
                    goalLine(goal)
                }
            }
            .gameCard(padding: 16)
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens your full progress")
    }

    /// One of three same-size tiles (fixed height so they always line up).
    private func progressTile<Icon: View>(value: String, label: LocalizedStringKey,
                                          @ViewBuilder icon: () -> Icon) -> some View {
        VStack(spacing: 3) {
            icon()
                .font(.system(size: 16))
                .frame(width: 20, height: 20)
            Text(value)
                .font(.ui(16, .bold))
                .foregroundStyle(Game.brown)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.ui(11))
                .foregroundStyle(Game.brownSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, minHeight: 72, maxHeight: 72)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Game.mint))
    }

    /// "Use 5 items this week   3/5"
    private func goalLine(_ goal: GoalType) -> some View {
        let current: Int
        let fraction: Double
        switch goal {
        case .useItems:
            current = foodStore.usedThisWeek
            fraction = Double(current) / Double(max(goalTarget, 1))
        case .wasteLess:
            current = foodStore.wastedThisWeek
            fraction = goalTarget == 0 ? (current == 0 ? 0 : 1) : Double(current) / Double(goalTarget)
        case .saveMoney:
            current = Int(foodStore.moneySavedThisMonth.rounded())
            fraction = Double(current) / Double(max(goalTarget, 1))
        }

        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(goal.headline(goalTarget))
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Game.brown)
                Spacer()
                Text(goal == .saveMoney ? "$\(current) / $\(goalTarget)" : "\(current) / \(goalTarget)")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Game.brownSoft)
                    .monospacedDigit()
            }
            GameProgressBar(progress: min(fraction, 1), color: goal == .wasteLess && current > goalTarget ? Game.red : Game.green, height: 6)
        }
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

                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.name)
                            .font(.ui(16, .semibold))
                            .foregroundStyle(Game.brown)
                            .lineLimit(1)
                        Group {
                            if item.quantity > 1 {
                                Text("\(item.daysLeftText), \(item.quantity) left")
                            } else {
                                Text(item.daysLeftText)
                            }
                        }
                        .font(.ui(13))
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
                    .font(.ui(16, .semibold))
                    .foregroundStyle(Game.brown)
                    .lineLimit(1)
                Text(item.daysLeftText)
                    .font(.ui(13))
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
