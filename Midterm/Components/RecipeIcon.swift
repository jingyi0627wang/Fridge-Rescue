import Foundation

/// Recipe illustrations are separate from raw ingredient illustrations.
/// The stored `emoji` field is kept for compatibility but now stores an asset ID.
enum RecipeIcon {
    struct Choice: Identifiable {
        let id: String
        let title: String
    }

    static let defaultSymbol = "recipe-soup"
    static let choices: [Choice] = [
        Choice(id: "recipe-soup", title: "Soup"),
        Choice(id: "recipe-salad", title: "Salad"),
        Choice(id: "recipe-pasta", title: "Pasta"),
        Choice(id: "recipe-noodles", title: "Noodles"),
        Choice(id: "recipe-curry", title: "Curry Rice"),
        Choice(id: "recipe-skillet", title: "Skillet"),
        Choice(id: "recipe-fried-egg", title: "Fried Egg"),
        Choice(id: "recipe-pancakes", title: "Pancakes"),
        Choice(id: "recipe-toast", title: "Toast"),
        Choice(id: "recipe-sandwich", title: "Sandwich"),
        Choice(id: "recipe-taco", title: "Taco"),
        Choice(id: "recipe-pizza", title: "Pizza"),
        Choice(id: "recipe-rice", title: "Rice"),
        Choice(id: "recipe-porridge", title: "Porridge"),
        Choice(id: "recipe-cake", title: "Cake"),
        Choice(id: "recipe-cookie", title: "Cookie"),
        Choice(id: "recipe-smoothie", title: "Smoothie"),
        Choice(id: "recipe-bento", title: "Bento Box"),
    ]

    private static let legacy: [String: String] = [
        "🍲": "recipe-soup",
        "🥗": "recipe-salad",
        "🍝": "recipe-pasta",
        "🍜": "recipe-noodles",
        "🍛": "recipe-curry",
        "🥘": "recipe-skillet",
        "🍳": "recipe-fried-egg",
        "🥞": "recipe-pancakes",
        "🍞": "recipe-toast",
        "🥪": "recipe-sandwich",
        "🌮": "recipe-taco",
        "🍕": "recipe-pizza",
        "🍚": "recipe-rice",
        "🥣": "recipe-porridge",
        "🍰": "recipe-cake",
        "🍪": "recipe-cookie",
        "🥤": "recipe-smoothie",
        "🍱": "recipe-bento",
        "FoodCarrot": "food-carrot",
        "FoodTomato": "food-tomato",
        "FoodBroccoli": "food-broccoli",
        "FoodLeafy": "food-green-leaf-lettuce",
        "FoodPotato": "food-potato",
        "FoodMushroom": "food-mushroom",
        "FoodChicken": "food-chicken",
        "FoodFish": "food-fish",
        "FoodShrimp": "food-shrimp",
        "FoodAvocado": "food-avocado",
        "FoodBanana": "food-banana",
        "FoodStrawberry": "food-strawberry",
    ]

    static func symbol(for storedValue: String) -> String {
        if choices.contains(where: { $0.id == storedValue }) { return storedValue }
        if let migrated = legacy[storedValue] { return migrated }
        if FoodIconNames.byName.values.contains(storedValue) { return storedValue }
        return defaultSymbol
    }

    static func title(for storedValue: String) -> String {
        let resolved = symbol(for: storedValue)
        if let choice = choices.first(where: { $0.id == resolved }) { return choice.title }
        return "Ingredient illustration"
    }
}
