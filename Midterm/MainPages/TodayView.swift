import SwiftUI

// Freshlings Today screen.
// Visual styling is local to this file so other teammates' screens are unchanged.
struct TodayView: View {
    @EnvironmentObject var foodStore: FoodStore

    // MARK: - Freshlings palette
    private let background = Color(red: 0.985, green: 0.990, blue: 0.962)
    private let cardWhite = Color.white
    private let grass = Color(red: 0.52, green: 0.87, blue: 0.34)
    private let deepGreen = Color(red: 0.19, green: 0.44, blue: 0.17)
    private let mint = Color(red: 0.91, green: 0.97, blue: 0.85)
    private let paleYellow = Color(red: 1.00, green: 0.96, blue: 0.80)
    private let orange = Color(red: 0.91, green: 0.45, blue: 0.22)
    private let textBrown = Color(red: 0.29, green: 0.25, blue: 0.19)
    private let secondaryBrown = Color(red: 0.48, green: 0.44, blue: 0.37)

    // MARK: - Existing data rules (unchanged)
    private var priorityItems: [FoodItem] {
        foodStore.foodItems
            .filter {
                $0.status == .active &&
                ($0.freshnessLevel == .urgent || $0.freshnessLevel == .useSoon)
            }
            .sorted { $0.hpPercentage < $1.hpPercentage }
    }

    @State private var onlineRecipes: [Recipe] = []

    private var recommendedRecipes: [Recipe] {
        RecipeData.merged(
            local: RecipeData.recommendations(for: priorityItems),
            online: onlineRecipes,
            items: foodStore.foodItems
        )
    }

    private var priorityKey: String {
        priorityItems.map(\.name).joined(separator: "|")
    }

    var body: some View {
        ZStack {
            background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    summaryCard

                    if priorityItems.isEmpty {
                        allGoodCard
                    } else {
                        prioritySection
                        recipeSection
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 36)
            }
        }
        // MainTabView already wraps TodayView in NavigationStack.
        .toolbar(.hidden, for: .navigationBar)
        .task(id: priorityKey) {
            onlineRecipes = await MealDBService.recommendations(for: priorityItems).recipes
        }
    }

    // MARK: - Header
    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 7) {
                Text("TODAY'S FRESHLINGS")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.4)
                    .foregroundStyle(deepGreen)

                Text("Let's save some food!")
                    .font(.system(size: 29, weight: .heavy, design: .rounded))
                    .foregroundStyle(textBrown)
                    .fixedSize(horizontal: false, vertical: true)

                Text("A little care keeps your food happy.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(secondaryBrown)
            }

            Spacer(minLength: 0)

            Image(systemName: "leaf.fill")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(deepGreen)
                .frame(width: 54, height: 54)
                .background(mint, in: Circle())
        }
    }

    // MARK: - Dynamic summary
    private var summaryCard: some View {
        HStack(spacing: 14) {
            Text(priorityItems.isEmpty ? "🌱" : "🥕")
                .font(.system(size: 38))
                .frame(width: 65, height: 65)
                .background(.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 22))

            VStack(alignment: .leading, spacing: 5) {
                Text(priorityItems.isEmpty ? "All fresh and happy!" : "\(priorityItems.count) need some love!")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(textBrown)

                Text(priorityItems.isEmpty
                     ? "Nothing needs your attention right now."
                     : "Use these ingredients first to reduce waste.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(secondaryBrown)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(priorityItems.isEmpty ? mint : paleYellow,
                    in: RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Priority food
    private var prioritySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Use These First", label: "LOWEST HP")

            ForEach(priorityItems) { item in
                NavigationLink {
                    FoodDetailView(item: item)
                } label: {
                    priorityCard(item)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func priorityCard(_ item: FoodItem) -> some View {
        VStack(spacing: 14) {
            HStack(spacing: 12) {
                Text(foodEmoji(for: item))
                    .font(.system(size: 29))
                    .frame(width: 59, height: 59)
                    .background(mint, in: RoundedRectangle(cornerRadius: 19))

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(textBrown)

                    Text(priorityMessage(for: item))
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(secondaryBrown)
                }

                Spacer(minLength: 6)

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(Int(item.hpPercentage))%")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(statusColor(for: item))
                    Text("HP")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(secondaryBrown)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(mint)
                    Capsule()
                        .fill(statusColor(for: item))
                        .frame(width: geometry.size.width * hpProgress(for: item))
                }
            }
            .frame(height: 9)

            HStack {
                Text(item.freshnessLevel.title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor(for: item))

                Spacer()

                Text(daysText(for: item))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryBrown)
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(secondaryBrown)
            }
        }
        .padding(18)
        .background(cardWhite, in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(statusColor(for: item).opacity(0.14), lineWidth: 1)
        }
    }

    // MARK: - Recipe recommendations
    private var recipeSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionTitle("Rescue Recipes", label: "COOK & SAVE")

            Text("Tasty ideas to use your priority ingredients.")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(secondaryBrown)

            if recommendedRecipes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("No matching recipes yet")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(textBrown)
                    Text("Add more ingredients to discover rescue recipes.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(secondaryBrown)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(18)
                .background(.white, in: RoundedRectangle(cornerRadius: 22))
            } else {
                ForEach(Array(recommendedRecipes.prefix(3))) { recipe in
                    NavigationLink {
                        RecipeDetailView(
                            recipe: recipe,
                            focusIngredient: matchingPriorityItem(for: recipe)
                        )
                    } label: {
                        recipeCard(recipe)
                    }
                    .buttonStyle(.plain)
                }

                NavigationLink {
                    RecipeListView()
                } label: {
                    HStack {
                        Text("View All Recipes")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(deepGreen)
                    .padding(17)
                    .background(mint, in: RoundedRectangle(cornerRadius: 18))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func recipeCard(_ recipe: Recipe) -> some View {
        HStack(spacing: 13) {
            Group {
                if let url = recipe.imageURL {
                    AsyncImage(url: url) { image in
                        image.resizable().scaledToFill()
                    } placeholder: {
                        Text(recipe.emoji).font(.system(size: 30))
                    }
                } else {
                    Text(recipe.emoji).font(.system(size: 30))
                }
            }
            .frame(width: 62, height: 62)
            .background(paleYellow)
            .clipShape(RoundedRectangle(cornerRadius: 19))

            VStack(alignment: .leading, spacing: 5) {
                Text(recipe.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(textBrown)
                    .lineLimit(2)

                if let item = matchingPriorityItem(for: recipe) {
                    Text("Helps rescue \(item.name)")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundStyle(orange)
                } else {
                    Text("Uses food from your fridge")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(secondaryBrown)
                }

                Text("\(recipe.timeText)  •  \(recipe.difficulty)")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(secondaryBrown)
            }

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(secondaryBrown)
        }
        .padding(14)
        .background(.white, in: RoundedRectangle(cornerRadius: 22))
    }

    // MARK: - Empty state
    private var allGoodCard: some View {
        VStack(spacing: 12) {
            Text("🌼")
                .font(.system(size: 43))
            Text("Nothing urgent today!")
                .font(.system(size: 21, weight: .heavy, design: .rounded))
                .foregroundStyle(textBrown)
            Text("Your food is in good shape. Check back later for more rescue ideas.")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(secondaryBrown)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 35)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Shared local helpers
    private func sectionTitle(_ title: String, label: String) -> some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 23, weight: .heavy, design: .rounded))
                .foregroundStyle(textBrown)
            Spacer()
            Text(label)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundStyle(deepGreen)
        }
    }

    private func matchingPriorityItem(for recipe: Recipe) -> FoodItem? {
        priorityItems.first { item in
            recipe.ingredients.contains { ingredient in
                FoodMatcher.matches(ingredient: ingredient, foodName: item.name)
            }
        }
    }

    private func hpProgress(for item: FoodItem) -> CGFloat {
        CGFloat(max(0, min(item.hpPercentage / 100.0, 1)))
    }

    private func statusColor(for item: FoodItem) -> Color {
        switch item.freshnessLevel {
        case .fresh: return deepGreen
        case .useSoon: return Color(red: 0.75, green: 0.56, blue: 0.10)
        case .urgent: return orange
        case .expired: return Color(red: 0.72, green: 0.25, blue: 0.23)
        }
    }

    private func priorityMessage(for item: FoodItem) -> String {
        if item.daysUntilExpiration == 1 { return "Only 1 day left" }
        return item.daysLeftText
    }

    private func daysText(for item: FoodItem) -> String {
        item.daysLeftText
    }

    private func foodEmoji(for item: FoodItem) -> String {
        switch item.category {
        case .vegetable: return "🥕"
        case .fruit: return "🍎"
        case .dairy: return "🥛"
        case .meat: return "🥩"
        case .other: return "🥣"
        }
    }
}

#Preview {
    NavigationStack {
        TodayView()
    }
    .environmentObject(FoodStore())
}

