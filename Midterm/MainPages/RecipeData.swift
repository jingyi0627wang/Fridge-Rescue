import Foundation

struct RecipeIngredient: Hashable {
    let name: String      // used to match fridge food, e.g. "Carrot"
    let amount: String    // shown to the user, e.g. "3 medium"
}

struct Recipe: Identifiable {
    let id: String

    let name: String
    let emoji: String
    let time: Int              // minutes (0 = unknown, e.g. online recipes)
    let difficulty: String     // local: "Easy"/"Medium"; online: category like "Chicken"
    let items: [RecipeIngredient]
    let steps: [String]

    // Online recipes (TheMealDB) only
    var imageURL: URL? = nil
    var area: String? = nil    // cuisine, e.g. "Italian"
    var sourceURL: URL? = nil

    init(id: String = UUID().uuidString,
         name: String, emoji: String, time: Int, difficulty: String,
         items: [RecipeIngredient], steps: [String],
         imageURL: URL? = nil, area: String? = nil, sourceURL: URL? = nil) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.time = time
        self.difficulty = difficulty
        self.items = items
        self.steps = steps
        self.imageURL = imageURL
        self.area = area
        self.sourceURL = sourceURL
    }

    /// Ingredient names only (used for matching).
    var ingredients: [String] { items.map(\.name) }

    var isOnline: Bool { sourceURL != nil }

    /// "20 min", or the cuisine for online recipes that have no time.
    var timeText: String {
        time > 0 ? "\(time) min" : (area ?? "Online")
    }
}

/// Short way to write an ingredient in the recipe list below.
private func ing(_ amount: String, _ name: String) -> RecipeIngredient {
    RecipeIngredient(name: name, amount: amount)
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
            .map { singular($0) }
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
            name: "Creamy Carrot Soup", emoji: "🥕", time: 30, difficulty: "Easy",
            items: [ing("4 medium", "Carrot"), ing("1/2 cup", "Milk"), ing("1 small", "Onion"),
                    ing("1 tbsp", "Butter"), ing("2 cups", "Water"), ing("to taste", "Salt")],
            steps: [
                "Peel the carrots and slice them into rounds about 1 cm thick. Dice the onion.",
                "Melt the butter in a pot over medium heat. Add the onion and cook for 3–4 minutes until soft and see-through, not brown.",
                "Add the carrots and 2 cups of water. Bring to a boil, then turn down to low, cover, and simmer for 15 minutes, until a fork slides easily into the carrots.",
                "Turn off the heat and let it cool for 5 minutes. Blend until completely smooth (in a blender, or with a hand blender in the pot).",
                "Pour back into the pot, stir in the milk, and warm over low heat for 2 minutes. Don't let it boil or the milk can split.",
                "Taste, add salt a pinch at a time, and serve warm."
            ]
        ),

        Recipe(
            name: "Milk Pancakes", emoji: "🥞", time: 20, difficulty: "Easy",
            items: [ing("1 cup", "Milk"), ing("1", "Egg"), ing("1 cup", "Flour"),
                    ing("2 tbsp", "Sugar"), ing("2 tsp", "Baking Powder"), ing("1 tbsp", "Butter")],
            steps: [
                "In a large bowl, whisk the flour, sugar, and baking powder together.",
                "In another bowl, whisk the milk and egg. Pour into the dry ingredients and stir just until no dry flour is left. A few lumps are fine; over-mixing makes them tough.",
                "Let the batter rest for 5 minutes while you heat a non-stick pan over medium-low heat. Add a little butter.",
                "Pour about 1/4 cup of batter per pancake. Cook for 2–3 minutes until bubbles appear on top and the edges look dry.",
                "Flip and cook for 1–2 minutes more, until golden underneath.",
                "Keep finished pancakes on a warm plate and serve with fruit or syrup."
            ]
        ),

        Recipe(
            name: "Roasted Carrots", emoji: "🥕", time: 35, difficulty: "Easy",
            items: [ing("6 medium", "Carrot"), ing("1 tbsp", "Olive Oil"),
                    ing("1/2 tsp", "Salt"), ing("1 tsp", "Honey")],
            steps: [
                "Heat the oven to 425°F (220°C) and line a baking tray with parchment paper.",
                "Peel the carrots and cut them into sticks about the size of your finger, so they cook evenly.",
                "Toss with olive oil and salt on the tray. Spread them out in one layer; crowded carrots steam instead of roasting.",
                "Roast for 15 minutes, flip them, and roast 10–15 minutes more, until the edges are browned and they are tender.",
                "Drizzle with honey while hot and toss before serving."
            ]
        ),

        Recipe(
            name: "Tomato & Egg Stir-Fry", emoji: "🍳", time: 15, difficulty: "Easy",
            items: [ing("2 medium", "Tomato"), ing("3", "Egg"), ing("1 stalk", "Scallion"),
                    ing("1 tsp", "Sugar"), ing("1/2 tsp", "Salt"), ing("2 tbsp", "Cooking Oil")],
            steps: [
                "Cut the tomatoes into wedges. Slice the scallion, keeping the white and green parts separate.",
                "Beat the eggs with a pinch of salt until no streaks of white remain.",
                "Heat 1 tbsp oil in a pan over medium-high heat until it shimmers. Pour in the eggs, wait 5 seconds, then gently push them around. Take them out when they are just set but still soft (about 1 minute).",
                "Add the remaining oil and the scallion whites. Stir for 10 seconds, then add the tomatoes.",
                "Cook for 3–4 minutes, pressing the tomatoes lightly, until they soften and release juice. Add the sugar and salt.",
                "Return the eggs, stir for 30 seconds to coat them in the sauce, top with scallion greens, and serve over rice."
            ]
        ),

        Recipe(
            name: "Veggie Omelette", emoji: "🥚", time: 15, difficulty: "Easy",
            items: [ing("3", "Egg"), ing("1 handful", "Spinach"), ing("1/2", "Bell Pepper"),
                    ing("1/4 cup grated", "Cheese"), ing("1 tsp", "Butter")],
            steps: [
                "Dice the bell pepper into small pieces and roughly chop the spinach.",
                "Beat the eggs with a pinch of salt and pepper.",
                "Melt the butter in a non-stick pan over medium heat. Cook the pepper for 2 minutes, then add the spinach and stir until it wilts (about 30 seconds).",
                "Spread the vegetables evenly and pour in the eggs. Let them set for 1 minute without stirring.",
                "Lift the edges with a spatula and tilt the pan so raw egg runs underneath. Cook until the top is almost set, 1–2 minutes.",
                "Sprinkle cheese over one half, fold the omelette in half, and slide it onto a plate."
            ]
        ),

        Recipe(
            name: "Chicken & Broccoli Stir-Fry", emoji: "🥦", time: 25, difficulty: "Medium",
            items: [ing("1 lb", "Chicken"), ing("1 head", "Broccoli"), ing("1", "Bell Pepper"),
                    ing("3 cloves", "Garlic"), ing("3 tbsp", "Soy Sauce"), ing("1 tsp", "Cornstarch")],
            steps: [
                "Cut the chicken into thin, bite-sized slices. Toss with 1 tbsp soy sauce and the cornstarch; let it sit for 10 minutes.",
                "Cut the broccoli into small florets and slice the bell pepper. Mince the garlic.",
                "Heat 1 tbsp oil in a large pan over high heat. Add the chicken in a single layer and leave it for 1 minute to brown, then stir-fry for 3–4 minutes until no pink remains. Remove to a plate.",
                "Add a little more oil, then the broccoli and 2 tbsp of water. Cover and cook for 2 minutes so the broccoli steams.",
                "Uncover, add the bell pepper and garlic, and stir-fry for 1 minute until fragrant.",
                "Return the chicken, add the remaining 2 tbsp soy sauce, and toss for 1 minute until everything is glossy. Serve with rice."
            ]
        ),

        Recipe(
            name: "Crispy Potato Hash", emoji: "🥔", time: 30, difficulty: "Easy",
            items: [ing("3 medium", "Potato"), ing("1", "Onion"), ing("4 slices", "Bacon"),
                    ing("2", "Egg"), ing("to taste", "Salt")],
            steps: [
                "Dice the potatoes into 1 cm cubes (no need to peel) and the onion into small pieces. Cut the bacon into strips.",
                "Cook the bacon in a large pan over medium heat for 5–6 minutes until crispy. Take it out and leave the fat in the pan.",
                "Add the potatoes in one layer. Cook for 5 minutes without stirring so a golden crust forms, then flip and cook 8–10 minutes more, stirring now and then.",
                "Add the onion and cook for 3–4 minutes until soft. Season with salt and stir the bacon back in.",
                "Make two small wells, crack an egg into each, cover the pan, and cook for 3–4 minutes until the whites are set."
            ]
        ),

        Recipe(
            name: "Banana Smoothie", emoji: "🍌", time: 5, difficulty: "Easy",
            items: [ing("2 ripe", "Banana"), ing("1 cup", "Milk"), ing("1/2 cup", "Yogurt"),
                    ing("4–5", "Strawberry"), ing("1 tsp", "Honey")],
            steps: [
                "Peel the bananas and break them into chunks. Rinse the strawberries and remove the green tops.",
                "Put the milk and yogurt in the blender first (liquid at the bottom helps it blend), then add the fruit and honey.",
                "Blend on high for 30–45 seconds until completely smooth.",
                "Taste. Add more milk if it's too thick, or a few ice cubes if you want it colder. Drink right away."
            ]
        ),

        Recipe(
            name: "Fresh Fruit Salad", emoji: "🍎", time: 10, difficulty: "Easy",
            items: [ing("1", "Apple"), ing("1", "Banana"), ing("1", "Orange"),
                    ing("1 cup", "Grape"), ing("1/2 cup", "Yogurt"), ing("1/2", "Lemon")],
            steps: [
                "Wash all the fruit. Core and dice the apple; peel and slice the banana; peel the orange and separate it into segments; halve the grapes.",
                "Put everything in a bowl and squeeze the lemon over it. The lemon juice stops the apple and banana from turning brown.",
                "Toss gently and chill for 10 minutes if you have time.",
                "Serve with a spoonful of yogurt on top."
            ]
        ),

        Recipe(
            name: "Garlic Spinach Pasta", emoji: "🍝", time: 20, difficulty: "Easy",
            items: [ing("200 g", "Pasta"), ing("4 big handfuls", "Spinach"), ing("4 cloves", "Garlic"),
                    ing("1/3 cup grated", "Parmesan Cheese"), ing("3 tbsp", "Olive Oil")],
            steps: [
                "Bring a large pot of salted water to a boil and cook the pasta 1 minute less than the package says. Save 1/2 cup of the pasta water before draining.",
                "While it cooks, thinly slice the garlic.",
                "Warm the olive oil in a large pan over medium-low heat. Add the garlic and cook for 1–2 minutes until lightly golden. Watch it closely; burnt garlic is bitter.",
                "Add the spinach a handful at a time, stirring until each batch wilts.",
                "Add the drained pasta and a splash of pasta water. Toss for 1 minute so the sauce coats the pasta.",
                "Turn off the heat, stir in the parmesan, and season with salt and pepper."
            ]
        ),

        Recipe(
            name: "Beef Tacos", emoji: "🌮", time: 20, difficulty: "Easy",
            items: [ing("1 lb", "Ground Beef"), ing("2", "Tomato"), ing("2 cups shredded", "Lettuce"),
                    ing("1 cup shredded", "Cheese"), ing("8 small", "Tortilla"), ing("2 tsp", "Chili Powder")],
            steps: [
                "Dice the tomatoes and shred the lettuce. Put them in small bowls with the cheese.",
                "Brown the ground beef in a pan over medium-high heat for 6–8 minutes, breaking it into small pieces, until no pink is left. Pour off extra fat.",
                "Stir in the chili powder, a pinch of salt, and 2 tbsp water. Cook for 1 minute.",
                "Warm the tortillas in a dry pan for 20–30 seconds per side.",
                "Fill each tortilla with beef, then top with tomato, lettuce, and cheese."
            ]
        ),

        Recipe(
            name: "Zucchini Fritters", emoji: "🥒", time: 30, difficulty: "Medium",
            items: [ing("2 medium", "Zucchini"), ing("1", "Egg"), ing("1/3 cup", "Flour"),
                    ing("1/4 cup grated", "Parmesan Cheese"), ing("1/2 tsp", "Salt")],
            steps: [
                "Grate the zucchini, sprinkle with the salt, and let it sit in a strainer for 10 minutes.",
                "Wrap the zucchini in a clean towel and squeeze out as much water as you can. This is the key step: wet zucchini makes soggy fritters.",
                "Mix the zucchini with the egg, flour, and parmesan until it forms a thick batter.",
                "Heat a thin layer of oil in a pan over medium heat. Drop in spoonfuls of batter and flatten them to about 1 cm thick.",
                "Fry for 3 minutes per side until deep golden. Drain on a paper towel and serve warm."
            ]
        ),

        Recipe(
            name: "Guacamole", emoji: "🥑", time: 10, difficulty: "Easy",
            items: [ing("2 ripe", "Avocado"), ing("1", "Lime"), ing("1 small", "Tomato"),
                    ing("1/4", "Onion"), ing("2 tbsp chopped", "Cilantro"), ing("1/2 tsp", "Salt")],
            steps: [
                "Cut the avocados in half, remove the pits, and scoop the flesh into a bowl.",
                "Mash with a fork, leaving some small chunks for texture.",
                "Finely dice the tomato and onion, and chop the cilantro. Add them to the bowl.",
                "Squeeze in the lime juice, add the salt, and stir. Taste and add more lime or salt if needed.",
                "Serve right away, or press plastic wrap directly onto the surface to keep it green."
            ]
        ),

        Recipe(
            name: "Yogurt Berry Parfait", emoji: "🫐", time: 5, difficulty: "Easy",
            items: [ing("1 cup", "Yogurt"), ing("1/2 cup", "Blueberry"), ing("1/2 cup sliced", "Strawberry"),
                    ing("1/3 cup", "Granola"), ing("1 tsp", "Honey")],
            steps: [
                "Rinse the berries and pat them dry. Slice the strawberries.",
                "Spoon a third of the yogurt into a glass, then add a layer of berries.",
                "Repeat the layers twice more.",
                "Add the granola right before eating so it stays crunchy, and drizzle with honey."
            ]
        ),

        Recipe(
            name: "Cabbage Fried Rice", emoji: "🍚", time: 20, difficulty: "Easy",
            items: [ing("2 cups shredded", "Cabbage"), ing("2", "Egg"), ing("1", "Carrot"),
                    ing("2 stalks", "Scallion"), ing("2 cups cooked (day-old)", "Rice"), ing("2 tbsp", "Soy Sauce")],
            steps: [
                "Use cold, day-old rice if you can; fresh rice turns mushy. Break up any clumps with your hands.",
                "Shred the cabbage, dice the carrot small, and slice the scallions.",
                "Scramble the eggs in a hot oiled pan until just set, then move them to a plate.",
                "Add a little more oil and stir-fry the carrot for 2 minutes, then the cabbage for 2–3 minutes until it softens.",
                "Add the rice and press it against the pan. Stir-fry for 3–4 minutes until it is hot and slightly crispy.",
                "Add the soy sauce and eggs, toss for 1 minute, and finish with scallions."
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

    /// Which fridge item each recipe ingredient uses (one item per ingredient).
    static func fridgeMatches(for recipe: Recipe, in items: [FoodItem]) -> [(ingredient: RecipeIngredient, item: FoodItem)] {
        var matches: [(ingredient: RecipeIngredient, item: FoodItem)] = []
        for ingredient in recipe.items {
            let remaining = items.filter { item in !matches.contains { $0.item.id == item.id } }
            if let match = FoodMatcher.fridgeItem(for: ingredient.name, in: remaining) {
                matches.append((ingredient, match))
            }
        }
        return matches
    }

    /// The fridge items a recipe would use up (one per ingredient).
    static func fridgeItems(for recipe: Recipe, in items: [FoodItem]) -> [FoodItem] {
        fridgeMatches(for: recipe, in: items).map(\.item)
    }

    /// How many of a fridge item cooking this recipe uses up, guessed from the amount:
    /// "3" or "2 medium" → 2–3 (if the food is counted one by one), anything else
    /// ("1/2 cup", "200 g", "2 tbsp") → 1. The user can change it on the recipe page.
    static func defaultUseCount(amount: String, for item: FoodItem) -> Int {
        let words = amount.lowercased().split(separator: " ").map(String.init)
        let sizeWords: Set<String> = ["small", "medium", "large", "ripe", "big", "whole"]
        let unit = IngredientPresetService.shared.loadPresets()
            .first { $0.name.lowercased() == item.name.lowercased() }?.unit ?? "each"

        guard unit == "each",
              let first = words.first, let number = Int(first), number > 0,
              words.dropFirst().allSatisfy({ sizeWords.contains($0) }) else {
            return min(1, item.quantity)
        }
        return min(number, item.quantity)
    }
}

// MARK: - Recipe categories (Recipes tab)

struct RecipeSections {
    /// Uses food that expires soon, most urgent first.
    let rescue: [Recipe]
    /// Uses 2+ things from your fridge.
    let usesMost: [Recipe]
    /// Everything else (often online recipes using 1 item).
    let moreIdeas: [Recipe]

    var isEmpty: Bool { rescue.isEmpty && usesMost.isEmpty && moreIdeas.isEmpty }
}

extension RecipeData {

    /// Food that "needs attention" (expires within 6 days).
    static func needsAttention(_ item: FoodItem) -> Bool {
        item.status == .active && (item.freshnessLevel == .urgent || item.freshnessLevel == .useSoon)
    }

    /// The most urgent fridge item this recipe would rescue (nil if none are urgent).
    static func rescueItem(for recipe: Recipe, in items: [FoodItem]) -> FoodItem? {
        fridgeItems(for: recipe, in: items)
            .filter { needsAttention($0) }
            .min { $0.daysUntilExpiration < $1.daysUntilExpiration }
    }

    /// Splits recipes into the three Recipes-tab sections. Each recipe appears once.
    static func sections(for recipes: [Recipe], items: [FoodItem]) -> RecipeSections {
        var rescue: [(Recipe, Int, Int)] = []   // recipe, days left of rescued item, match count
        var usesMost: [(Recipe, Int)] = []
        var more: [Recipe] = []

        for recipe in recipes {
            let count = matchCount(recipe, items)
            if let item = rescueItem(for: recipe, in: items) {
                rescue.append((recipe, item.daysUntilExpiration, count))
            } else if count >= 2 {
                usesMost.append((recipe, count))
            } else {
                more.append(recipe)
            }
        }

        return RecipeSections(
            rescue: rescue
                .sorted { $0.1 != $1.1 ? $0.1 < $1.1 : $0.2 > $1.2 }
                .map(\.0),
            usesMost: usesMost
                .sorted { $0.1 > $1.1 }
                .map(\.0),
            moreIdeas: more
        )
    }
}
