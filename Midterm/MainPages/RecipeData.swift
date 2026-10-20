import Foundation

struct Recipe: Identifiable {
    let id = UUID()

    let name: String
    let emoji: String
    let time: Int
    let difficulty: String
    let ingredients: [String]
    let steps: [String]
}

// MARK: - Matching fridge food to recipe ingredients
// "Milk" matches "Whole Milk", "Egg" matches "Eggs", "Onion" matches "Red Onion",
// but "Egg" does NOT match "Eggplant".

enum FoodMatcher {

    static func matches(ingredient: String, foodName: String) -> Bool {
        let ingredientWords = words(ingredient)
        let foodWords = Set(words(foodName))
        guard !ingredientWords.isEmpty else { return false }
        return ingredientWords.allSatisfy { foodWords.contains($0) }
    }

    /// The fridge item (lowest HP first) that can be used for this ingredient.
    static func fridgeItem(for ingredient: String, in items: [FoodItem]) -> FoodItem? {
        items
            .filter { $0.status == .active }
            .sorted { $0.hpPercentage < $1.hpPercentage }
            .first { matches(ingredient: ingredient, foodName: $0.name) }
    }

    private static func words(_ text: String) -> [String] {
        text.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
            .map(singular)
    }

    private static func singular(_ word: String) -> String {
        if word.hasSuffix("ies"), word.count > 4 { return String(word.dropLast(3)) + "y" }
        if word.hasSuffix("oes") { return String(word.dropLast(2)) }
        if word.hasSuffix("s"), !word.hasSuffix("ss"), word.count > 3 { return String(word.dropLast()) }
        return word
    }
}

enum RecipeData {

    static let recipes: [Recipe] = [

        Recipe(
            name: "Creamy Carrot Soup",
            emoji: "🥕",
            time: 20,
            difficulty: "Easy",
            ingredients: ["Carrot", "Milk", "Onion", "Salt"],
            steps: [
                "Cut the carrots and onion into small pieces.",
                "Cook the vegetables until they become soft.",
                "Add milk and simmer for a few minutes.",
                "Blend until smooth.",
                "Season with salt and serve warm."
            ]
        ),

        Recipe(
            name: "Milk Pancakes",
            emoji: "🥞",
            time: 15,
            difficulty: "Easy",
            ingredients: ["Milk", "Egg", "Flour", "Sugar"],
            steps: [
                "Combine flour and sugar in a bowl.",
                "Add milk and egg.",
                "Mix until the batter is smooth.",
                "Cook both sides in a heated pan.",
                "Serve while warm."
            ]
        ),

        Recipe(
            name: "Roasted Carrots",
            emoji: "🥕",
            time: 25,
            difficulty: "Easy",
            ingredients: ["Carrot", "Olive Oil", "Salt"],
            steps: [
                "Cut the carrots into even pieces.",
                "Coat them lightly with olive oil.",
                "Season with salt.",
                "Roast until tender and lightly browned."
            ]
        ),

        Recipe(
            name: "Tomato & Egg Stir-Fry",
            emoji: "🍳",
            time: 10,
            difficulty: "Easy",
            ingredients: ["Tomato", "Egg", "Scallion", "Sugar", "Salt"],
            steps: [
                "Beat the eggs with a pinch of salt.",
                "Scramble the eggs in a hot pan until just set, then set aside.",
                "Cook the tomato wedges until they turn soft and juicy.",
                "Add a little sugar and salt, then return the eggs.",
                "Top with chopped scallion and serve with rice."
            ]
        ),

        Recipe(
            name: "Veggie Omelette",
            emoji: "🥚",
            time: 12,
            difficulty: "Easy",
            ingredients: ["Egg", "Spinach", "Bell Pepper", "Cheese"],
            steps: [
                "Chop the spinach and bell pepper.",
                "Cook the vegetables in a pan for 2 minutes.",
                "Pour in the beaten eggs and let them set.",
                "Add cheese, fold the omelette, and serve."
            ]
        ),

        Recipe(
            name: "Chicken & Broccoli Stir-Fry",
            emoji: "🥦",
            time: 20,
            difficulty: "Medium",
            ingredients: ["Chicken", "Broccoli", "Bell Pepper", "Garlic", "Soy Sauce"],
            steps: [
                "Slice the chicken and cut the broccoli into small florets.",
                "Cook the chicken in a hot pan until golden.",
                "Add garlic, broccoli, and bell pepper.",
                "Stir in soy sauce and cook until the broccoli is tender."
            ]
        ),

        Recipe(
            name: "Crispy Potato Hash",
            emoji: "🥔",
            time: 25,
            difficulty: "Easy",
            ingredients: ["Potato", "Onion", "Bacon", "Egg"],
            steps: [
                "Dice the potatoes and onion.",
                "Cook the bacon, then fry the potatoes in the fat until crispy.",
                "Add the onion and cook until soft.",
                "Top with a fried egg."
            ]
        ),

        Recipe(
            name: "Banana Smoothie",
            emoji: "🍌",
            time: 5,
            difficulty: "Easy",
            ingredients: ["Banana", "Milk", "Yogurt", "Strawberry"],
            steps: [
                "Peel the banana and wash the strawberries.",
                "Add everything to a blender.",
                "Blend until smooth and drink right away."
            ]
        ),

        Recipe(
            name: "Fresh Fruit Salad",
            emoji: "🍎",
            time: 10,
            difficulty: "Easy",
            ingredients: ["Apple", "Banana", "Orange", "Grape", "Yogurt"],
            steps: [
                "Cut all the fruit into bite-sized pieces.",
                "Mix in a large bowl.",
                "Serve with a spoon of yogurt on top."
            ]
        ),

        Recipe(
            name: "Garlic Spinach Pasta",
            emoji: "🍝",
            time: 20,
            difficulty: "Easy",
            ingredients: ["Spinach", "Garlic", "Parmesan Cheese", "Pasta", "Olive Oil"],
            steps: [
                "Boil the pasta until al dente.",
                "Cook sliced garlic in olive oil.",
                "Add spinach and cook until wilted.",
                "Toss with the pasta and parmesan."
            ]
        ),

        Recipe(
            name: "Beef Tacos",
            emoji: "🌮",
            time: 20,
            difficulty: "Easy",
            ingredients: ["Ground Beef", "Tomato", "Lettuce", "Cheese", "Tortilla"],
            steps: [
                "Brown the ground beef and season it.",
                "Chop the tomato and lettuce.",
                "Warm the tortillas.",
                "Fill with beef, vegetables, and cheese."
            ]
        ),

        Recipe(
            name: "Zucchini Fritters",
            emoji: "🥒",
            time: 25,
            difficulty: "Medium",
            ingredients: ["Zucchini", "Egg", "Flour", "Parmesan Cheese"],
            steps: [
                "Grate the zucchini and squeeze out the water.",
                "Mix with egg, flour, and parmesan.",
                "Fry spoonfuls of the batter until golden on both sides."
            ]
        ),

        Recipe(
            name: "Guacamole",
            emoji: "🥑",
            time: 10,
            difficulty: "Easy",
            ingredients: ["Avocado", "Lime", "Tomato", "Onion", "Cilantro"],
            steps: [
                "Mash the avocado in a bowl.",
                "Add diced tomato, onion, and chopped cilantro.",
                "Squeeze in lime juice and add salt to taste."
            ]
        ),

        Recipe(
            name: "Yogurt Berry Parfait",
            emoji: "🫐",
            time: 5,
            difficulty: "Easy",
            ingredients: ["Yogurt", "Blueberry", "Strawberry", "Granola"],
            steps: [
                "Spoon yogurt into a glass.",
                "Add a layer of berries.",
                "Repeat and finish with granola on top."
            ]
        ),

        Recipe(
            name: "Cabbage Fried Rice",
            emoji: "🍚",
            time: 15,
            difficulty: "Easy",
            ingredients: ["Cabbage", "Egg", "Carrot", "Scallion", "Rice"],
            steps: [
                "Scramble the eggs and set aside.",
                "Stir-fry shredded cabbage and diced carrot.",
                "Add cooked rice and the eggs.",
                "Season with soy sauce and top with scallion."
            ]
        )
    ]

    /// Recipes that use at least one active fridge item.
    /// Recipes using MORE fridge items come first.
    static func recommendations(
        for items: [FoodItem]
    ) -> [Recipe] {

        let activeItems = items.filter { $0.status == .active }

        return recipes
            .map { recipe in (recipe, matchCount(recipe, activeItems)) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
            .map { $0.0 }
    }

    /// How many of this recipe's ingredients are in the fridge.
    static func matchCount(
        _ recipe: Recipe,
        _ items: [FoodItem]
    ) -> Int {
        recipe.ingredients.filter { ingredient in
            items.contains {
                $0.status == .active &&
                FoodMatcher.matches(ingredient: ingredient, foodName: $0.name)
            }
        }.count
    }

    /// The fridge items a recipe would use up (one per ingredient).
    static func fridgeItems(for recipe: Recipe, in items: [FoodItem]) -> [FoodItem] {
        var used: [FoodItem] = []
        for ingredient in recipe.ingredients {
            let remaining = items.filter { item in !used.contains { $0.id == item.id } }
            if let match = FoodMatcher.fridgeItem(for: ingredient, in: remaining) {
                used.append(match)
            }
        }
        return used
    }
}
