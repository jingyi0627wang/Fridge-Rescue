import SwiftUI

struct RecipeDetailView: View {

    @EnvironmentObject var foodStore: FoodStore

    let recipe: Recipe
    var focusIngredient: FoodItem?

    // MARK: - Colors

    private let pageBackground = Color(
        red: 0.969,
        green: 0.965,
        blue: 0.945
    )

    private let cardBackground = Color.white.opacity(0.82)

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
        red: 0.47,
        green: 0.46,
        blue: 0.41
    )

    private let greenColor = Color(
        red: 0.34,
        green: 0.46,
        blue: 0.23
    )

    private let orangeColor = Color(
        red: 0.76,
        green: 0.31,
        blue: 0.18
    )

    // MARK: - Fridge Matching

    private func isInFridge(_ ingredient: String) -> Bool {

        foodStore.foodItems.contains { food in

            food.status == .active &&
            food.name.lowercased() == ingredient.lowercased()
        }
    }

    private var ingredientsInFridgeCount: Int {

        recipe.ingredients.filter {
            isInFridge($0)
        }.count
    }

    // MARK: - Rescue Ingredient

    private var rescueIngredient: FoodItem? {

        if let focusIngredient {
            return focusIngredient
        }

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

            pageBackground
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {

                VStack(
                    alignment: .leading,
                    spacing: 30
                ) {

                    heroSection

                    quickInfoSection

                    if let rescueIngredient {
                        recommendationSection(
                            item: rescueIngredient
                        )
                    }

                    ingredientsSection

                    cookingStepsSection

                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 140)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(
            pageBackground,
            for: .navigationBar
        )
    }

    // MARK: - Hero

    private var heroSection: some View {

        VStack(spacing: 20) {

            ZStack {

                RoundedRectangle(
                    cornerRadius: 30,
                    style: .continuous
                )
                .fill(
                    greenColor.opacity(0.08)
                )

                VStack(spacing: 18) {

                    Text(recipe.emoji)
                        .font(.system(size: 64))

                    Text(recipe.name)
                        .font(
                            .system(
                                size: 30,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(titleColor)
                        .multilineTextAlignment(.center)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }
                .padding(.horizontal, 20)
            }
            .frame(height: 260)
        }
    }

    // MARK: - Quick Information

    private var quickInfoSection: some View {

        HStack(spacing: 12) {

            infoPill(
                icon: "clock",
                text: "\(recipe.time) min"
            )

            infoPill(
                icon: "chart.bar.fill",
                text: recipe.difficulty
            )

            infoPill(
                icon: "refrigerator",
                text: "\(ingredientsInFridgeCount) in fridge"
            )

            Spacer(minLength: 0)
        }
    }

    private func infoPill(
        icon: String,
        text: String
    ) -> some View {

        HStack(spacing: 6) {

            Image(systemName: icon)
                .font(.system(size: 12))

            Text(text)
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )
        }
        .foregroundStyle(bodyColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            Color.black.opacity(0.04)
        )
        .clipShape(Capsule())
    }

    // MARK: - Recommendation

    private func recommendationSection(
        item: FoodItem
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            HStack(spacing: 9) {

                Image(systemName: "sparkles")
                    .font(
                        .system(
                            size: 18,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(orangeColor)

                Text("Why this recipe?")
                    .font(
                        .system(
                            size: 25,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(titleColor)
            }

            HStack(
                alignment: .top,
                spacing: 16
            ) {

                ZStack {

                    Circle()
                        .fill(
                            orangeColor.opacity(0.11)
                        )
                        .frame(
                            width: 52,
                            height: 52
                        )

                    Image(
                        systemName: "exclamationmark"
                    )
                    .font(
                        .system(
                            size: 17,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(orangeColor)
                }

                VStack(
                    alignment: .leading,
                    spacing: 6
                ) {

                    Text("Rescue \(item.name)")
                        .font(
                            .system(
                                size: 17,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(titleColor)

                    Text(rescueDescription(for: item))
                        .font(
                            .system(
                                size: 15,
                                weight: .regular
                            )
                        )
                        .foregroundStyle(bodyColor)
                        .fixedSize(
                            horizontal: false,
                            vertical: true
                        )
                }

                Spacer()
            }
            .padding(20)
            .background(
                orangeColor.opacity(0.045)
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
                    orangeColor.opacity(0.14),
                    lineWidth: 1
                )
            }
        }
    }

    private func rescueDescription(
        for item: FoodItem
    ) -> String {

        if item.hpPercentage <= 0 {
            return "\(item.name) has expired."
        }

        if item.remainingDays == 0 {
            return "\(item.name) expires today. This recipe helps you use it before it goes to waste."
        }

        if item.remainingDays == 1 {
            return "\(item.name) has only 1 day left. This recipe helps rescue it while it's still fresh."
        }

        return "\(item.name) has \(item.remainingDays) days left. This recipe helps you use it while it's still fresh."
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            HStack {

                Text("Ingredients")
                    .font(
                        .system(
                            size: 25,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(titleColor)

                Spacer()

                Text(
                    "\(ingredientsInFridgeCount)/\(recipe.ingredients.count) READY"
                )
                .font(
                    .system(
                        size: 11,
                        weight: .bold
                    )
                )
                .tracking(1.5)
                .foregroundStyle(greenColor)
            }

            VStack(spacing: 0) {

                ForEach(
                    Array(
                        recipe.ingredients.enumerated()
                    ),
                    id: \.offset
                ) { index, ingredient in

                    ingredientRow(
                        ingredient: ingredient
                    )

                    if index <
                        recipe.ingredients.count - 1 {

                        Divider()
                            .overlay(
                                Color.black.opacity(0.07)
                            )
                            .padding(.leading, 62)
                    }
                }
            }
            .background(cardBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 26,
                    style: .continuous
                )
            )
            .overlay {

                RoundedRectangle(
                    cornerRadius: 26,
                    style: .continuous
                )
                .stroke(
                    Color.black.opacity(0.05),
                    lineWidth: 1
                )
            }
        }
    }

    private func ingredientRow(
        ingredient: String
    ) -> some View {

        let available = isInFridge(ingredient)

        return HStack(spacing: 14) {

            ZStack {

                Circle()
                    .fill(
                        available
                        ? greenColor.opacity(0.11)
                        : Color.black.opacity(0.045)
                    )
                    .frame(
                        width: 44,
                        height: 44
                    )

                Image(
                    systemName:
                        available
                        ? "checkmark"
                        : "plus"
                )
                .font(
                    .system(
                        size: 15,
                        weight: .bold
                    )
                )
                .foregroundStyle(
                    available
                    ? greenColor
                    : bodyColor
                )
            }

            Text(ingredient)
                .font(
                    .system(
                        size: 16,
                        weight: .medium
                    )
                )
                .foregroundStyle(titleColor)

            Spacer()

            Text(
                available
                ? "In your fridge"
                : "Need to buy"
            )
            .font(
                .system(
                    size: 13,
                    weight: .semibold
                )
            )
            .foregroundStyle(
                available
                ? greenColor
                : mutedColor
            )
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    // MARK: - Cooking Steps

    private var cookingStepsSection: some View {

        VStack(
            alignment: .leading,
            spacing: 16
        ) {

            Text("Cooking Steps")
                .font(
                    .system(
                        size: 25,
                        weight: .bold
                    )
                )
                .foregroundStyle(titleColor)

            VStack(spacing: 0) {

                ForEach(
                    Array(recipe.steps.enumerated()),
                    id: \.offset
                ) { index, step in

                    cookingStepRow(
                        number: index + 1,
                        text: step
                    )

                    if index <
                        recipe.steps.count - 1 {

                        Divider()
                            .overlay(
                                Color.black.opacity(0.07)
                            )
                            .padding(.leading, 68)
                    }
                }
            }
            .background(cardBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 26,
                    style: .continuous
                )
            )
            .overlay {

                RoundedRectangle(
                    cornerRadius: 26,
                    style: .continuous
                )
                .stroke(
                    Color.black.opacity(0.05),
                    lineWidth: 1
                )
            }
        }
    }

    private func cookingStepRow(
        number: Int,
        text: String
    ) -> some View {

        HStack(
            alignment: .top,
            spacing: 16
        ) {

            ZStack {

                Circle()
                    .fill(
                        greenColor.opacity(0.12)
                    )
                    .frame(
                        width: 42,
                        height: 42
                    )

                Text("\(number)")
                    .font(
                        .system(
                            size: 14,
                            weight: .bold
                        )
                    )
                    .foregroundStyle(greenColor)
            }

            Text(text)
                .font(
                    .system(
                        size: 15,
                        weight: .regular
                    )
                )
                .foregroundStyle(bodyColor)
                .fixedSize(
                    horizontal: false,
                    vertical: true
                )

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 17)
    }
}


// MARK: - Preview

#Preview {

    NavigationStack {

        RecipeDetailView(
            recipe: RecipeData.recipes[0],
            focusIngredient: nil
        )
        .environmentObject(FoodStore())
    }
}
