import SwiftUI

struct TodayView: View {

    @EnvironmentObject var foodStore: FoodStore

    // MARK: - Local Theme

    private let backgroundColor = Color(
        red: 0.965,
        green: 0.950,
        blue: 0.900
    )

    private let cardColor = Color(
        red: 0.995,
        green: 0.985,
        blue: 0.955
    )

    private let primaryText = Color(
        red: 0.16,
        green: 0.15,
        blue: 0.12
    )

    private let secondaryText = Color(
        red: 0.43,
        green: 0.42,
        blue: 0.36
    )

    private let green = Color(
        red: 0.38,
        green: 0.48,
        blue: 0.25
    )

    private let orange = Color(
        red: 0.76,
        green: 0.31,
        blue: 0.18
    )

    private let yellow = Color(
        red: 0.76,
        green: 0.58,
        blue: 0.18
    )

    private let red = Color(
        red: 0.72,
        green: 0.24,
        blue: 0.20
    )

    private let borderColor = Color.black.opacity(0.06)


    // MARK: - Data

    private var priorityItems: [FoodItem] {
        foodStore.foodItems
            .filter {
                $0.status == .active &&
                (
                    $0.freshnessLevel == .urgent ||
                    $0.freshnessLevel == .useSoon
                )
            }
            .sorted {
                $0.hpPercentage < $1.hpPercentage
            }
    }


    private var recommendedRecipes: [Recipe] {
        RecipeData.recommendations(
            for: priorityItems
        )
    }


    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                backgroundColor
                    .ignoresSafeArea()

                ScrollView(
                    .vertical,
                    showsIndicators: false
                ) {

                    VStack(
                        alignment: .leading,
                        spacing: 30
                    ) {

                        headerSection

                        summarySection

                        if priorityItems.isEmpty {

                            allGoodSection

                        } else {

                            prioritySection

                            recipeSection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 22)

                    // Important:
                    // Keeps content above the bottom TabView.
                    .padding(.bottom, 150)
                }
            }
            .navigationBarHidden(true)
        }
    }


    // MARK: - Header

    private var headerSection: some View {

        VStack(
            alignment: .leading,
            spacing: 7
        ) {

            Text("TODAY")
                .font(
                    .system(
                        size: 11,
                        weight: .bold
                    )
                )
                .tracking(2.2)
                .foregroundStyle(green)

            Text("Use what matters first.")
                .font(
                    .system(
                        size: 31,
                        weight: .bold,
                        design: .serif
                    )
                )
                .foregroundStyle(primaryText)

            Text(
                "Start with the food that needs your attention most."
            )
            .font(
                .system(
                    size: 14,
                    weight: .regular
                )
            )
            .foregroundStyle(secondaryText)
        }
    }


    // MARK: - Summary

    private var summarySection: some View {

        HStack(
            spacing: 14
        ) {

            ZStack {

                Circle()
                    .fill(
                        summaryColor.opacity(0.12)
                    )
                    .frame(
                        width: 52,
                        height: 52
                    )

                Image(
                    systemName: summaryIcon
                )
                .font(
                    .system(
                        size: 19,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    summaryColor
                )
            }


            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                if priorityItems.isEmpty {

                    Text(
                        "You're all caught up"
                    )
                    .font(
                        .system(
                            size: 17,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        primaryText
                    )

                    Text(
                        "Nothing needs immediate attention."
                    )
                    .font(
                        .system(
                            size: 12
                        )
                    )
                    .foregroundStyle(
                        secondaryText
                    )

                } else {

                    Text(
                        "\(priorityItems.count) \(priorityItems.count == 1 ? "item" : "items") need attention"
                    )
                    .font(
                        .system(
                            size: 17,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        primaryText
                    )

                    Text(
                        "Use these first to reduce food waste."
                    )
                    .font(
                        .system(
                            size: 12
                        )
                    )
                    .foregroundStyle(
                        secondaryText
                    )
                }
            }

            Spacer()
        }
        .padding(18)
        .background(
            cardColor
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 22
            )
            .stroke(
                summaryColor.opacity(0.15),
                lineWidth: 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22
            )
        )
    }


    // MARK: - Priority Section

    private var prioritySection: some View {

        VStack(
            alignment: .leading,
            spacing: 15
        ) {

            sectionHeader(
                title: "Use These First",
                label: "LOWEST HP"
            )

            ForEach(
                priorityItems
            ) { item in

                NavigationLink {

                    FoodDetailView(
                        item: item
                    )

                } label: {

                    priorityCard(
                        item: item
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }


    // MARK: - Priority Card

    private func priorityCard(
        item: FoodItem
    ) -> some View {

        VStack(
            spacing: 15
        ) {

            HStack(
                spacing: 14
            ) {

                foodIcon(
                    item: item
                )

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text(
                        item.name
                    )
                    .font(
                        .system(
                            size: 17,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        primaryText
                    )

                    Text(
                        priorityMessage(
                            for: item
                        )
                    )
                    .font(
                        .system(
                            size: 12
                        )
                    )
                    .foregroundStyle(
                        secondaryText
                    )
                }

                Spacer()

                VStack(
                    alignment: .trailing,
                    spacing: 2
                ) {

                    Text(
                        "\(Int(item.hpPercentage))"
                    )
                    .font(
                        .system(
                            size: 25,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(
                        statusColor(
                            for: item
                        )
                    )

                    Text("HP")
                        .font(
                            .system(
                                size: 9,
                                weight: .bold
                            )
                        )
                        .tracking(1)
                        .foregroundStyle(
                            secondaryText
                        )
                }
            }


            GeometryReader { geometry in

                ZStack(
                    alignment: .leading
                ) {

                    Capsule()
                        .fill(
                            Color.black.opacity(
                                0.06
                            )
                        )

                    Capsule()
                        .fill(
                            statusColor(
                                for: item
                            )
                        )
                        .frame(
                            width:
                                geometry.size.width
                                * hpProgress(
                                    for: item
                                )
                        )
                }
            }
            .frame(
                height: 6
            )


            HStack {

                Text(
                    item.freshnessLevel.title
                )
                .font(
                    .system(
                        size: 11,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    statusColor(
                        for: item
                    )
                )

                Spacer()

                HStack(
                    spacing: 5
                ) {

                    Text(
                        item.remainingDays == 1
                        ? "1 day left"
                        : "\(item.remainingDays) days left"
                    )

                    Image(
                        systemName:
                            "chevron.right"
                    )
                }
                .font(
                    .system(
                        size: 11,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    secondaryText
                )
            }
        }
        .padding(18)
        .background(
            cardColor
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 22
            )
            .stroke(
                statusColor(
                    for: item
                )
                .opacity(0.12),
                lineWidth: 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22
            )
        )
    }


    // MARK: - Recipes

    private var recipeSection: some View {

        VStack(
            alignment: .leading,
            spacing: 15
        ) {

            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(
                    "Rescue Recipes"
                )
                .font(
                    .system(
                        size: 23,
                        weight: .bold,
                        design: .serif
                    )
                )
                .foregroundStyle(
                    primaryText
                )

                Text(
                    "Recipes that help use your priority ingredients."
                )
                .font(
                    .system(
                        size: 13
                    )
                )
                .foregroundStyle(
                    secondaryText
                )
            }


            if recommendedRecipes.isEmpty {

                noRecipeSection

            } else {

                ForEach(
                    Array(
                        recommendedRecipes.prefix(
                            3
                        )
                    )
                ) { recipe in

                    NavigationLink {

                        RecipeDetailView(
                            recipe: recipe,
                            focusIngredient:
                                matchingPriorityItem(
                                    for: recipe
                                )
                        )

                    } label: {

                        todayRecipeCard(
                            recipe: recipe
                        )
                    }
                    .buttonStyle(.plain)
                }


                NavigationLink {

                    RecipeListView()

                } label: {

                    HStack {

                        Text(
                            "View All Recipes"
                        )
                        .fontWeight(
                            .semibold
                        )

                        Spacer()

                        Image(
                            systemName:
                                "arrow.right"
                        )
                    }
                    .font(
                        .system(
                            size: 14
                        )
                    )
                    .foregroundStyle(
                        green
                    )
                    .padding(
                        .horizontal,
                        18
                    )
                    .frame(
                        height: 52
                    )
                    .background(
                        green.opacity(
                            0.09
                        )
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 16
                        )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }


    // MARK: - Recipe Card

    private func todayRecipeCard(
        recipe: Recipe
    ) -> some View {

        HStack(
            spacing: 15
        ) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 16
                )
                .fill(
                    green.opacity(
                        0.09
                    )
                )
                .frame(
                    width: 62,
                    height: 62
                )

                Text(
                    recipe.emoji
                )
                .font(
                    .system(
                        size: 29
                    )
                )
            }


            VStack(
                alignment: .leading,
                spacing: 5
            ) {

                Text(
                    recipe.name
                )
                .font(
                    .system(
                        size: 16,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    primaryText
                )
                .lineLimit(1)


                if let item =
                    matchingPriorityItem(
                        for: recipe
                    ) {

                    Text(
                        "Helps rescue \(item.name)"
                    )
                    .font(
                        .system(
                            size: 12,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        orange
                    )

                } else {

                    Text(
                        "Uses food from your fridge"
                    )
                    .font(
                        .system(
                            size: 12
                        )
                    )
                    .foregroundStyle(
                        secondaryText
                    )
                }


                HStack(
                    spacing: 6
                ) {

                    Image(
                        systemName:
                            "clock"
                    )

                    Text(
                        "\(recipe.time) min"
                    )

                    Text("•")

                    Text(
                        recipe.difficulty
                    )
                }
                .font(
                    .system(
                        size: 11
                    )
                )
                .foregroundStyle(
                    secondaryText
                )
            }

            Spacer()

            Image(
                systemName:
                    "chevron.right"
            )
            .font(
                .system(
                    size: 12,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                secondaryText
            )
        }
        .padding(16)
        .background(
            cardColor
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 20
            )
            .stroke(
                borderColor,
                lineWidth: 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 20
            )
        )
    }


    // MARK: - All Good

    private var allGoodSection: some View {

        VStack(
            spacing: 15
        ) {

            ZStack {

                Circle()
                    .fill(
                        green.opacity(
                            0.10
                        )
                    )
                    .frame(
                        width: 70,
                        height: 70
                    )

                Image(
                    systemName:
                        "checkmark.circle.fill"
                )
                .font(
                    .system(
                        size: 30
                    )
                )
                .foregroundStyle(
                    green
                )
            }


            Text(
                "Nothing urgent today"
            )
            .font(
                .system(
                    size: 19,
                    weight: .bold
                )
            )
            .foregroundStyle(
                primaryText
            )


            Text(
                "Your food is in good shape. Check back later for rescue suggestions."
            )
            .font(
                .system(
                    size: 13
                )
            )
            .foregroundStyle(
                secondaryText
            )
            .multilineTextAlignment(
                .center
            )
        }
        .frame(
            maxWidth: .infinity
        )
        .padding(
            .horizontal,
            25
        )
        .padding(
            .vertical,
            36
        )
        .background(
            cardColor
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 22
            )
            .stroke(
                borderColor,
                lineWidth: 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 22
            )
        )
    }


    // MARK: - No Recipe

    private var noRecipeSection: some View {

        VStack(
            alignment: .leading,
            spacing: 6
        ) {

            Text(
                "No matching recipes yet"
            )
            .font(
                .system(
                    size: 15,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                primaryText
            )

            Text(
                "Add more ingredients to unlock more rescue recipes."
            )
            .font(
                .system(
                    size: 12
                )
            )
            .foregroundStyle(
                secondaryText
            )
        }
        .frame(
            maxWidth: .infinity,
            alignment: .leading
        )
        .padding(18)
        .background(
            cardColor
        )
        .overlay {

            RoundedRectangle(
                cornerRadius: 18
            )
            .stroke(
                borderColor,
                lineWidth: 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }


    // MARK: - Section Header

    private func sectionHeader(
        title: String,
        label: String
    ) -> some View {

        HStack {

            Text(
                title
            )
            .font(
                .system(
                    size: 23,
                    weight: .bold,
                    design: .serif
                )
            )
            .foregroundStyle(
                primaryText
            )

            Spacer()

            Text(
                label
            )
            .font(
                .system(
                    size: 9,
                    weight: .bold
                )
            )
            .tracking(1.4)
            .foregroundStyle(
                orange
            )
        }
    }


    // MARK: - Food Icon

    private func foodIcon(
        item: FoodItem
    ) -> some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 14
            )
            .fill(
                statusColor(
                    for: item
                )
                .opacity(0.10)
            )
            .frame(
                width: 54,
                height: 54
            )

            Text(
                foodEmoji(
                    for: item
                )
            )
            .font(
                .system(
                    size: 25
                )
            )
        }
    }


    // MARK: - Recipe Matching

    private func matchingPriorityItem(
        for recipe: Recipe
    ) -> FoodItem? {

        priorityItems.first { item in

            recipe.ingredients.contains {
                ingredient in

                ingredient
                    .lowercased()
                    .contains(
                        item.name.lowercased()
                    )
                ||
                item.name
                    .lowercased()
                    .contains(
                        ingredient.lowercased()
                    )
            }
        }
    }


    // MARK: - Helpers

    private var summaryColor: Color {

        priorityItems.isEmpty
        ? green
        : orange
    }


    private var summaryIcon: String {

        priorityItems.isEmpty
        ? "checkmark.circle.fill"
        : "exclamationmark.circle.fill"
    }


    private func statusColor(
        for item: FoodItem
    ) -> Color {

        switch item.freshnessLevel {

        case .fresh:
            return green

        case .useSoon:
            return yellow

        case .urgent:
            return orange

        case .expired:
            return red
        }
    }


    private func hpProgress(
        for item: FoodItem
    ) -> Double {

        max(
            0,
            min(
                item.hpPercentage / 100.0,
                1
            )
        )
    }


    private func priorityMessage(
        for item: FoodItem
    ) -> String {

        if item.remainingDays == 0 {
            return "Expires today"
        }

        if item.remainingDays == 1 {
            return "Only 1 day left"
        }

        return "\(item.remainingDays) days left"
    }


    private func foodEmoji(
        for item: FoodItem
    ) -> String {

        switch item.category {

        case .vegetable:
            return "🥕"

        case .fruit:
            return "🍎"

        case .dairy:
            return "🥛"

        case .meat:
            return "🥩"

        case .other:
            return "🥣"
        }
    }
}


// MARK: - Preview

#Preview {

    TodayView()
        .environmentObject(
            FoodStore()
        )
}
