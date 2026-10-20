import SwiftUI

// MARK: - Recipe Details
// Photo, which Freshling this recipe rescues, ingredients (what's in your
// fridge and how many of each cooking uses up), steps, and "I Cooked This!".

struct RecipeDetailView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var myRecipes: MyRecipeStore
    @Environment(\.dismiss) private var dismiss
    @State private var confirmDelete = false

    /// Set when this is one of the user's own recipes.
    private var userRecipe: UserRecipe? {
        myRecipes.userRecipe(forRecipeID: recipe.id)
    }

    /// Plain-text version for the Share button.
    private var shareText: String {
        var lines = [recipe.name, ""]
        lines.append("Ingredients:")
        lines += recipe.items.map { "• \($0.amount) \($0.name)".replacingOccurrences(of: "•  ", with: "• ") }
        if !recipe.steps.isEmpty {
            lines.append("")
            lines.append("Steps:")
            lines += recipe.steps.enumerated().map { "\($0.offset + 1). \($0.element)" }
        }
        lines.append("")
        lines.append("Shared from Freshlings")
        return lines.joined(separator: "\n")
    }

    let recipe: Recipe
    var focusIngredient: FoodItem?

    /// Ingredients NOT in the fridge that the user ticked ("I have this").
    @State private var checked: Set<String> = []

    /// How many of each fridge item cooking will use (key = fridge item id).
    /// Starts from a guess based on the recipe amount; the user can change it.
    @State private var useCounts: [UUID: Int] = [:]

    /// Long recipes show the first few steps until "Show all" is tapped.
    @State private var showAllSteps = false
    private let collapsedSteps = 3

    // MARK: - Fridge matching

    /// Which fridge item each ingredient uses.
    private var matches: [(ingredient: RecipeIngredient, item: FoodItem)] {
        RecipeData.fridgeMatches(for: recipe, in: foodStore.foodItems)
    }

    private var rescueIngredient: FoodItem? {
        if let focusIngredient { return focusIngredient }
        return RecipeData.fridgeItems(for: recipe, in: foodStore.foodItems)
            .min { $0.hpPercentage < $1.hpPercentage }
    }

    private func useCount(for match: (ingredient: RecipeIngredient, item: FoodItem)) -> Int {
        let value = useCounts[match.item.id]
            ?? RecipeData.defaultUseCount(amount: match.ingredient.amount, for: match.item)
        return min(max(value, 0), match.item.quantity)
    }

    /// Fridge items that will actually be used (count > 0).
    private func plannedUses(_ matches: [(ingredient: RecipeIngredient, item: FoodItem)]) -> [(item: FoodItem, quantity: Int)] {
        matches
            .map { (item: $0.item, quantity: useCount(for: $0)) }
            .filter { $0.quantity > 0 }
    }

    // MARK: - Body

    var body: some View {
        // Computed once per render.
        let matches = self.matches
        let readyCount = recipe.items.filter { ingredient in
            matches.contains { $0.ingredient == ingredient } || checked.contains(ingredient.name)
        }.count
        let uses = plannedUses(matches)
        let shownSteps = showAllSteps ? recipe.steps : Array(recipe.steps.prefix(collapsedSteps))

        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                heroCard(inFridge: matches.count)

                HStack {
                    GameSectionHeader(title: "Ingredients")
                    Text("\(readyCount)/\(recipe.items.count) ready")
                        .font(.game(13, .bold))
                        .foregroundStyle(Game.greenInk)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Game.mint))
                        .padding(.top, 10)
                }

                VStack(spacing: 0) {
                    ForEach(Array(recipe.items.enumerated()), id: \.offset) { index, ingredient in
                        if index > 0 { DashedDivider() }
                        if let match = matches.first(where: { $0.ingredient == ingredient }) {
                            fridgeIngredientRow(match)
                        } else {
                            missingIngredientRow(ingredient)
                        }
                    }
                }
                .gameCard(padding: 0)

                if !recipe.steps.isEmpty {
                GameSectionHeader(title: "Steps", count: recipe.steps.count)
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(shownSteps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.game(15, .bold))
                                .foregroundStyle(Game.greenInk)
                                .frame(width: 30, height: 30)
                                .background(Circle().fill(Game.mint))
                            Text(step)
                                .font(.game(16, .medium))
                                .foregroundStyle(Game.brown)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 4)
                                .lineSpacing(2)
                        }
                    }

                    if recipe.steps.count > collapsedSteps {
                        Button {
                            withAnimation(.snappy) { showAllSteps.toggle() }
                        } label: {
                            if showAllSteps {
                                Text("Show Less")
                            } else {
                                Text("Show All \(recipe.steps.count) Steps")
                            }
                        }
                        .buttonStyle(.chunky(.white, small: true))
                    }
                }
                .gameCard(padding: 16)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .gameBackground()
        .navigationTitle(recipe.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .tint(Game.greenDark)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: shareText) {
                    Image(systemName: "square.and.arrow.up")
                }
                .accessibilityLabel("Share recipe")
            }
            if userRecipe != nil {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            if let userRecipe {
                                myRecipes.setShared(recipeID: recipe.id, !userRecipe.isShared)
                            }
                        } label: {
                            if userRecipe?.isShared == true {
                                Label("Remove from Community", systemImage: "person.2.slash")
                            } else {
                                Label("Share to Community", systemImage: "person.2.fill")
                            }
                        }
                        Button(role: .destructive) {
                            confirmDelete = true
                        } label: {
                            Label("Delete Recipe", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .confirmationDialog("Delete this recipe?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete Recipe", role: .destructive) {
                myRecipes.delete(recipeID: recipe.id)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
        .safeAreaInset(edge: .bottom) {
            cookedButton(uses: uses)
        }
    }

    // MARK: - Hero

    private func heroCard(inFridge: Int) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let url = recipe.imageURL {
                RecipePhoto(url: url) { Game.mint }
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .accessibilityHidden(true)
            } else {
                RecipeThumbnail(recipe: recipe, size: 72)
            }

            Text(recipe.name)
                .font(.game(26, .bold))
                .foregroundStyle(Game.brown)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                infoPill(icon: recipe.time > 0 ? "clock.fill" : "globe", text: recipe.timeText)
                infoPill(icon: "tag.fill", text: recipe.difficulty)
                infoPill(icon: "refrigerator.fill", text: "\(inFridge) in fridge")
            }

            if let rescueIngredient {
                Label(rescueDescription(for: rescueIngredient), systemImage: "heart.fill")
                    .font(.game(14, .semibold))
                    .foregroundStyle(rescueIngredient.freshnessLevel.tint)
                    .lineLimit(1)
            }

            if let source = recipe.sourceURL {
                Link(destination: source) {
                    Label("View on TheMealDB", systemImage: "arrow.up.right.square")
                        .font(.game(14, .semibold))
                        .foregroundStyle(Game.greenInk)
                }
            }
        }
        .gameCard(padding: 14)
    }

    private func infoPill(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(.game(12, .bold))
        .foregroundStyle(Game.greenInk)
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(Capsule().fill(Game.mint))
    }

    private func rescueDescription(for item: FoodItem) -> String {
        if item.daysUntilExpiration < 0 {
            return "Uses your \(item.name) (past its date)"
        }
        return "Rescues your \(item.name) · \(item.daysLeftText.lowercased())"
    }

    // MARK: - Ingredient rows

    /// In the fridge: link to the food + an inline "− 2/5 +" for how many cooking uses.
    private func fridgeIngredientRow(_ match: (ingredient: RecipeIngredient, item: FoodItem)) -> some View {
        let fridgeItem = match.item
        let count = useCount(for: match)
        let amount = match.ingredient.amount.isEmpty ? "" : match.ingredient.amount + " · "

        return HStack(spacing: 10) {
            NavigationLink {
                FoodDetailView(item: fridgeItem)
            } label: {
                HStack(spacing: 12) {
                    FreshlingAvatar(item: fridgeItem, size: 40)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(match.ingredient.name)
                            .font(.game(16, .semibold))
                            .foregroundStyle(Game.brown)
                            .lineLimit(1)
                        Text(verbatim: amount + fridgeItem.daysLeftText.lowercased())
                            .font(.game(12, .medium))
                            .foregroundStyle(fridgeItem.freshnessLevel.tint)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 4)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            roundButton("minus", enabled: count > 0) { useCounts[fridgeItem.id] = count - 1 }
            Text(verbatim: "\(count)/\(fridgeItem.quantity)")
                .font(.game(14, .bold))
                .foregroundStyle(count == 0 ? Game.brownSoft : Game.greenInk)
                .monospacedDigit()
                .frame(minWidth: 34)
                .accessibilityLabel("Uses \(count) of \(fridgeItem.quantity)")
            roundButton("plus", enabled: count < fridgeItem.quantity) { useCounts[fridgeItem.id] = count + 1 }
        }
        .padding(.horizontal, 14)
        .frame(minHeight: 64)
    }

    /// Not in the fridge: tap to tick it off.
    private func missingIngredientRow(_ ingredient: RecipeIngredient) -> some View {
        let isChecked = checked.contains(ingredient.name)

        return Button {
            if isChecked { checked.remove(ingredient.name) } else { checked.insert(ingredient.name) }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(isChecked ? Game.greenDark : Game.edgeDark)
                    .frame(width: 40, height: 40)
                ingredientText(ingredient,
                               detail: isChecked ? "Got it" : "Not in your fridge",
                               detailColor: Game.brownSoft)
            }
            .padding(.horizontal, 14)
            .frame(minHeight: 64)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isChecked)
    }

    private func ingredientText(_ ingredient: RecipeIngredient, detail: String, detailColor: Color) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ingredient.name)
                    .font(.game(16, .semibold))
                    .foregroundStyle(Game.brown)
                Text(detail)
                    .font(.game(12, .medium))
                    .foregroundStyle(detailColor)
                    .lineLimit(1)
            }
            Spacer(minLength: 6)
            if !ingredient.amount.isEmpty {
                Text(ingredient.amount)
                    .font(.game(14, .semibold))
                    .foregroundStyle(Game.brownSoft)
                    .multilineTextAlignment(.trailing)
            }
        }
    }

    private func roundButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(enabled ? Game.greenInk : Game.gray)
                .frame(width: 28, height: 28)
                .background(Circle().fill(enabled ? Game.mint : Game.graySoft))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - I Cooked This
    // Marks every fridge item this recipe uses as "used",
    // so it leaves the fridge and counts on the Impact page.

    private func cookedButton(uses: [(item: FoodItem, quantity: Int)]) -> some View {
        let parts: [String] = uses.map { "\($0.quantity) \($0.item.name)" }
        var xp = 0
        for use in uses { xp += FoodStore.questXP(for: use.item) * use.quantity }
        let summary: String = uses.isEmpty
            ? "No ingredients from your fridge"
            : "Uses " + parts.joined(separator: ", ")

        return VStack(spacing: 4) {
            Button {
                cook(uses)
            } label: {
                if uses.isEmpty {
                    Text("I Cooked This!")
                } else {
                    Text("I Cooked This! +\(xp) XP")
                }
            }
            .buttonStyle(.chunky(.green))
            .disabled(uses.isEmpty)

            Text(summary)
                .font(.game(12, .medium))
                .foregroundStyle(Game.brownSoft)
                .lineLimit(1)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 6)
        .background(Game.cream.opacity(0.97).ignoresSafeArea(edges: .bottom))
        .overlay(alignment: .top) {
            Rectangle().fill(Game.edge).frame(height: 2)
        }
    }

    /// No pop-ups: takes the chosen amounts out of the fridge, goes back,
    /// and the Undo bar at the bottom says what was used.
    private func cook(_ uses: [(item: FoodItem, quantity: Int)]) {
        guard !uses.isEmpty else { return }
        foodStore.cook(uses)
        FreshlingsHaptics.cookingComplete()
        dismiss()
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
        .environmentObject(MyRecipeStore())
    }
}
