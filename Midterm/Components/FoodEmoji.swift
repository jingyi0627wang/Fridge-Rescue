import Foundation

// MARK: - Food pictures
// Picks a food emoji for a food name, e.g. "Chicken Breast" → 🍗, "2% Milk" → 🥛.
// Rules are checked top to bottom and the FIRST match wins, so specific names
// come before general ones ("Eggplant" before "egg", "Pineapple" before "apple",
// "Butter Lettuce" before "butter"). Unknown food gets its category's emoji.
// Only emoji available on iOS 17 are used.

enum FoodEmoji {

    private static let rules: [(keywords: [String], emoji: String)] = [
        // Tricky names first
        (["butter lettuce", "beet greens", "turnip greens", "collard greens",
          "mustard greens"], "🥬"),
        (["pearl onion"], "🧅"),
        (["cherry tomato"], "🍅"),
        (["bell pepper"], "🫑"),
        (["eggplant"], "🍆"),
        (["pineapple"], "🍍"),
        (["grapefruit"], "🍊"),
        (["watermelon"], "🍉"),
        (["peanut"], "🥜"),
        (["ice cream"], "🍦"),
        (["butternut", "acorn squash", "kabocha", "delicata",
          "spaghetti squash", "pumpkin"], "🎃"),
        (["sweet potato", "yam", "beet"], "🍠"),
        (["buttermilk", "milk", "half-and-half", "heavy cream", "whipping cream"], "🥛"),
        (["cream cheese", "cheese", "mozzarella", "parmesan", "cheddar", "ricotta",
          "feta", "brie"], "🧀"),
        (["sour cream", "yogurt", "yoghurt", "kefir"], "🥣"),
        (["butter", "margarine", "ghee"], "🧈"),
        (["egg"], "🥚"),
        (["chickpea", "lentil", "black bean", "kidney bean", "pinto"], "🫘"),
        (["bean sprout", "sprouts", "microgreen"], "🌱"),

        // Meat & fish
        (["bacon"], "🥓"),
        (["hot dog", "sausage", "bratwurst", "chorizo", "pepperoni"], "🌭"),
        (["turkey"], "🦃"),
        (["chicken", "wing", "drumstick", "poultry"], "🍗"),
        (["ham", "lamb roast", "ribs", "rib"], "🍖"),
        (["deli", "salami", "prosciutto"], "🥪"),
        (["shrimp", "prawn"], "🍤"),
        (["salmon", "tuna", "fish", "cod", "tilapia", "trout"], "🐟"),
        (["crab", "lobster"], "🦀"),
        (["beef", "steak", "pork", "lamb", "veal", "ground", "meat", "roast"], "🥩"),

        // Fruit
        (["granny smith", "green apple"], "🍏"),
        (["apple"], "🍎"),
        (["pear"], "🍐"),
        (["banana", "plantain"], "🍌"),
        (["strawberr"], "🍓"),
        (["blueberr", "blackberr", "raspberr", "berry", "berries"], "🫐"),
        (["cherr"], "🍒"),
        (["grape", "raisin"], "🍇"),
        (["lemon", "lime"], "🍋"),
        (["orange", "mandarin", "clementine", "tangerine"], "🍊"),
        (["peach", "nectarine", "apricot", "plum"], "🍑"),
        (["mango", "papaya"], "🥭"),
        (["melon", "cantaloupe", "honeydew"], "🍈"),
        (["coconut"], "🥥"),
        (["kiwi"], "🥝"),
        (["avocado"], "🥑"),
        (["pomegranate", "dragon fruit", "fig"], "🍇"),

        // Vegetables
        (["tomato", "tomatillo"], "🍅"),
        (["carrot", "parsnip"], "🥕"),
        (["broccoli", "cauliflower"], "🥦"),
        (["corn"], "🌽"),
        (["cucumber", "zucchini", "yellow squash", "chayote", "okra", "pickle"], "🥒"),
        (["chili", "jalapeño", "jalapeno", "hot pepper"], "🌶️"),
        (["bell pepper", "pepper"], "🫑"),
        (["mushroom"], "🍄"),
        (["garlic"], "🧄"),
        (["ginger"], "🫚"),
        (["scallion", "green onion", "leek", "chive"], "🌿"),
        (["onion", "shallot"], "🧅"),
        (["peas", "pea pod", "green bean", "wax bean", "edamame"], "🫛"),
        (["potato", "radish", "turnip", "rutabaga", "kohlrabi", "celeriac",
          "jicama", "taro", "lotus"], "🥔"),
        (["cilantro", "parsley", "basil", "mint", "dill", "herb", "fennel",
          "asparagus", "artichoke", "celery"], "🌿"),
        (["lettuce", "spinach", "kale", "chard", "cabbage", "bok choy", "greens",
          "arugula", "endive", "escarole", "radicchio", "watercress", "collard",
          "brussels", "salad"], "🥬"),
        (["bamboo"], "🎍"),

        // Pantry & other
        (["bread", "bagel", "toast", "bun"], "🍞"),
        (["croissant"], "🥐"),
        (["tortilla", "pita", "naan"], "🫓"),
        (["rice"], "🍚"),
        (["pasta", "spaghetti", "noodle", "ramen"], "🍝"),
        (["dumpling"], "🥟"),
        (["juice"], "🧃"),
        (["soda", "cola"], "🥤"),
        (["coffee"], "☕️"),
        (["chocolate"], "🍫"),
        (["cookie"], "🍪"),
        (["cake"], "🍰"),
        (["honey"], "🍯"),
        (["soup", "can "], "🥫"),
        (["pizza"], "🍕"),
        (["nut", "almond", "walnut", "cashew"], "🥜"),
        (["tofu"], "🧊")
    ]

    /// True if `keyword` appears in `text` at the start of a word, so
    /// "spears" doesn't match "pear" and "graham" doesn't match "ham".
    private static func startsWord(_ text: String, _ keyword: String) -> Bool {
        var searchRange = text.startIndex..<text.endIndex
        while let found = text.range(of: keyword, range: searchRange) {
            if found.lowerBound == text.startIndex
                || !text[text.index(before: found.lowerBound)].isLetter {
                return true
            }
            searchRange = found.upperBound..<text.endIndex
        }
        return false
    }

    /// Picture for when no rule matches.
    static func fallback(for category: FoodCategory) -> String {
        switch category {
        case .vegetable: return "🥬"
        case .fruit: return "🍎"
        case .dairy: return "🥛"
        case .meat: return "🥩"
        case .other: return "🥫"
        }
    }

    /// Results are remembered, since lists ask for the same names many times.
    private static var cache: [String: String] = [:]

    static func emoji(for name: String, category: FoodCategory) -> String {
        let key = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if let cached = cache[key] { return cached }

        var result: String?
        for rule in rules where rule.keywords.contains(where: { startsWord(key, $0) }) {
            result = rule.emoji
            break
        }
        // Only remember real matches; the fallback depends on the category.
        if let result {
            cache[key] = result
            return result
        }
        return fallback(for: category)
    }
}
