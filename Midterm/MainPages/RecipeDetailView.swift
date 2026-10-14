import SwiftUI

// Freshlings recipe details. Keeps the existing Recipe, FoodItem,
// FoodStore and RecipeData interfaces unchanged.
struct RecipeDetailView: View {
    @EnvironmentObject var foodStore: FoodStore
    @Environment(\.dismiss) private var dismiss


    let recipe: Recipe
    var focusIngredient: FoodItem?

    /// Ingredients NOT in the fridge that the user ticked ("I have this").
    @State private var checked: Set<String> = []

    private enum Palette {
        static let background = Color(red: 0.985, green: 0.992, blue: 0.965)
        static let surface = Color.white
        static let green = Color(red: 0.53, green: 0.89, blue: 0.36)
        static let deepGreen = Color(red: 0.24, green: 0.48, blue: 0.22)
        static let paleGreen = Color(red: 0.92, green: 0.98, blue: 0.86)
        static let orange = Color(red: 0.96, green: 0.52, blue: 0.20)
        static let paleOrange = Color(red: 1.00, green: 0.95, blue: 0.86)
        static let brown = Color(red: 0.40, green: 0.29, blue: 0.24)
        static let secondary = Color(red: 0.49, green: 0.44, blue: 0.40)
        static let border = Color(red: 0.86, green: 0.91, blue: 0.82)
    }

    // MARK: - Original fridge matching behavior

    private func isInFridge(_ ingredient: String) -> Bool {
        FoodMatcher.fridgeItem(for: ingredient, in: foodStore.foodItems) != nil
    }

    private var ingredientsInFridgeCount: Int {
        recipe.ingredients.filter { isInFridge($0) }.count
    }

    /// In the fridge + ticked by hand.
    private var readyCount: Int {
        recipe.ingredients.filter { isInFridge($0) || checked.contains($0) }.count
    }

    private var rescueIngredient: FoodItem? {
        if let focusIngredient { return focusIngredient }

        return RecipeData.fridgeItems(for: recipe, in: foodStore.foodItems)
            .min { $0.hpPercentage < $1.hpPercentage }
    }

    var body: some View {
        ZStack {
            Palette.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 25) {
                    heroSection
                    quickInfoSection

                    if let rescueIngredient {
                        recommendationSection(item: rescueIngredient)
                    }

                    ingredientsSection
                    cookingStepsSection
                    cookedButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 110)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Palette.background, for: .navigationBar)
        .tint(Palette.deepGreen)
    }

    // MARK: - I Cooked This
    // Marks every fridge item this recipe uses as "used",
    // so it leaves the fridge and counts on the Impact page.

    private var itemsToUse: [FoodItem] {
        RecipeData.fridgeItems(for: recipe, in: foodStore.foodItems)
    }

    private var cookedButton: some View {
        Button {
            cook()
        } label: {
            VStack(spacing: 4) {
                Label("I Cooked This", systemImage: "frying.pan.fill")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                Text(itemsToUse.isEmpty
                     ? "No ingredients from your fridge"
                     : "Marks \(itemsToUse.count) fridge \(itemsToUse.count == 1 ? "item" : "items") as eaten")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundStyle(itemsToUse.isEmpty ? Palette.secondary : Palette.deepGreen)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(itemsToUse.isEmpty ? Palette.border : Palette.green,
                        in: RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .disabled(itemsToUse.isEmpty)
    }

    /// No pop-ups: marks the items right away, goes back,
    /// and the Undo bar at the bottom says what was used.
    private func cook() {
        foodStore.markAsUsed(itemsToUse)
        dismiss()
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 14) {
            HStack {
                Label("FRESHLINGS KITCHEN", systemImage: "leaf.fill")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .tracking(1.2)
                    .foregroundStyle(Palette.deepGreen)
                Spacer()
                Image(systemName: "sparkles")
                    .foregroundStyle(Palette.orange)
            }

            if let url = recipe.imageURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Text(recipe.emoji).font(.system(size: 76))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: 22))
                .accessibilityHidden(true)
            } else {
                Text(recipe.emoji)
                    .font(.system(size: 76))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .accessibilityHidden(true)
            }

            Text(recipe.name)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.brown)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let source = recipe.sourceURL {
                Link(destination: source) {
                    Label("Recipe from TheMealDB", systemImage: "arrow.up.right.square")
                }
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(Palette.deepGreen)
            } else {
                Text("A little recipe to save something fresh!")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Palette.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(Palette.paleGreen, in: RoundedRectangle(cornerRadius: 30))
    }

    // MARK: - Recipe information

    private var quickInfoSection: some View {
        HStack(spacing: 8) {
            infoPill(icon: recipe.time > 0 ? "clock" : "globe", text: recipe.timeText)
            infoPill(icon: recipe.isOnline ? "tag.fill" : "chart.bar.fill", text: recipe.difficulty)
            infoPill(icon: "refrigerator", text: "\(ingredientsInFridgeCount) in fridge")
        }
    }

    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text).lineLimit(1).minimumScaleFactor(0.75)
        }
        .font(.system(size: 11, weight: .bold, design: .rounded))
        .foregroundStyle(Palette.deepGreen)
        .padding(.horizontal, 8)
        .padding(.vertical, 11)
        .frame(maxWidth: .infinity)
        .background(Palette.surface, in: Capsule())
        .overlay(Capsule().stroke(Palette.border, lineWidth: 1))
    }

    // MARK: - Rescue recommendation

    private func recommendationSection(item: FoodItem) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionTitle("Why this recipe?", icon: "sparkles")

            HStack(alignment: .top, spacing: 14) {
                Image(systemName: "leaf.fill")
                    .font(.system(size: 27, weight: .semibold))
                    .foregroundStyle(Palette.deepGreen)
                    .frame(width: 53, height: 53)
                    .background(.white.opacity(0.85), in: RoundedRectangle(cornerRadius: 17))

                VStack(alignment: .leading, spacing: 6) {
                    Text("Help rescue \(item.name)!")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.brown)

                    Text(rescueDescription(for: item))
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(Palette.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
            .padding(18)
            .background(Palette.paleOrange, in: RoundedRectangle(cornerRadius: 24))
        }
    }

    private func rescueDescription(for item: FoodItem) -> String {
        if item.daysUntilExpiration < 0 {
            return "\(item.name) has expired. Check whether it is safe to use before cooking."
        }
        if item.remainingDays == 0 {
            return "\(item.name) expires today. This recipe helps you use it while it's still fresh."
        }
        if item.remainingDays == 1 {
            return "\(item.name) has only 1 day left. Use it while it's still fresh."
        }
        return "\(item.name) has \(item.remainingDays) days left. This recipe can help you use it in time."
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                sectionTitle("Ingredients", icon: "basket.fill")
                Spacer(minLength: 8)
                Text("\(readyCount)/\(recipe.items.count) READY")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.deepGreen)
            }

            Text("Tap a fridge item to see it. Tick the others once you have them.")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Palette.secondary)

            VStack(spacing: 0) {
                ForEach(Array(recipe.items.enumerated()), id: \.offset) { index, ingredient in
                    ingredientRow(ingredient)
                    if index < recipe.items.count - 1 {
                        Divider().overlay(Palette.border).padding(.leading, 54)
                    }
                }
            }
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Palette.border, lineWidth: 1))
        }
    }

    @ViewBuilder
    private func ingredientRow(_ ingredient: RecipeIngredient) -> some View {
        if let fridgeItem = FoodMatcher.fridgeItem(for: ingredient.name, in: foodStore.foodItems) {
            // In the fridge → open that food's details
            NavigationLink {
                FoodDetailView(item: fridgeItem)
            } label: {
                ingredientRowContent(
                    ingredient,
                    icon: "checkmark.circle.fill",
                    iconColor: Palette.deepGreen,
                    detail: "Your \(fridgeItem.name) · \(fridgeItem.daysLeftText)",
                    detailColor: fridgeItem.freshnessLevel == .fresh ? Palette.deepGreen : Palette.orange,
                    showsChevron: true
                )
            }
            .buttonStyle(.plain)
        } else {
            // Not in the fridge → tap to tick it off
            let isChecked = checked.contains(ingredient.name)
            Button {
                if isChecked { checked.remove(ingredient.name) } else { checked.insert(ingredient.name) }
            } label: {
                ingredientRowContent(
                    ingredient,
                    icon: isChecked ? "checkmark.square.fill" : "square",
                    iconColor: isChecked ? Palette.deepGreen : Palette.secondary.opacity(0.6),
                    detail: isChecked ? "Got it" : "Not in fridge",
                    detailColor: Palette.secondary,
                    showsChevron: false
                )
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.selection, trigger: isChecked)
        }
    }

    private func ingredientRowContent(
        _ ingredient: RecipeIngredient,
        icon: String,
        iconColor: Color,
        detail: String,
        detailColor: Color,
        showsChevron: Bool
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(iconColor)
                .frame(width: 26)

            VStack(alignment: .leading, spacing: 3) {
                Text(ingredient.name)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(Palette.brown)
                Text(detail)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(detailColor)
                    .lineLimit(1)
            }

            Spacer(minLength: 5)

            if !ingredient.amount.isEmpty {
                Text(ingredient.amount)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Palette.deepGreen)
                    .multilineTextAlignment(.trailing)
            }

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Palette.secondary)
            }
        }
        .padding(.horizontal, 17)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Cooking steps

    private var cookingStepsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle("Cooking Steps", icon: "fork.knife")

            VStack(spacing: 0) {
                ForEach(Array(recipe.steps.enumerated()), id: \.offset) { index, step in
                    HStack(alignment: .top, spacing: 14) {
                        Text("\(index + 1)")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundStyle(Palette.deepGreen)
                            .frame(width: 37, height: 37)
                            .background(Palette.paleGreen, in: Circle())

                        Text(step)
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Palette.brown)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 8)

                        Spacer(minLength: 0)
                    }
                    .padding(16)

                    if index < recipe.steps.count - 1 {
                        Divider().overlay(Palette.border).padding(.leading, 64)
                    }
                }
            }
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 24))
            .overlay(RoundedRectangle(cornerRadius: 24).stroke(Palette.border, lineWidth: 1))
        }
    }

    private func sectionTitle(_ title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(Palette.deepGreen)
            Text(title)
                .font(.system(size: 23, weight: .heavy, design: .rounded))
                .foregroundStyle(Palette.brown)
        }
    }
}

#Preview {
    NavigationStack {
        RecipeDetailView(
            recipe: RecipeData.recipes[0],
            focusIngredient: nil
        )
        .environmentObject(FoodStore())
        .environmentObject(AppRouter())
    }
}

