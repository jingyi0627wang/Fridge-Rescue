import SwiftUI
import UIKit

// MARK: - Food icons
// Picks one of the Freshlings food illustrations (Assets.xcassets/Food) for a food name.
// Rules are checked top to bottom, so put more specific words first
// (e.g. "eggplant" before "egg", "buttermilk" before "butter").
// If nothing matches, the category's default icon is used.

enum FoodIcon {

    /// `nil` asset = "known word, but no matching drawing" → use the category default.
    private static let rules: [(words: [String], asset: String?)] = [
        // Exceptions that would otherwise match a shorter word
        (["eggplant", "pineapple", "squash", "pumpkin", "butternut", "coconut", "dragon fruit"], nil),
        (["butter lettuce", "greens"], "FoodLeafy"),
        (["buttermilk"], "FoodMilk"),
        (["grapefruit"], "FoodOrange"),
        (["cherry tomato"], "FoodTomato"),

        // Meat & seafood
        (["bacon"], "FoodBacon"),
        (["shrimp", "prawn"], "FoodShrimp"),
        (["fish", "salmon", "tuna", "cod", "tilapia", "seafood"], "FoodFish"),
        (["chicken", "turkey", "drumstick", "wing"], "FoodChicken"),
        (["beef", "steak", "pork", "lamb", "ham", "sausage", "hot dog", "deli", "meat"], "FoodMeat"),

        // Dairy & eggs
        (["egg"], "FoodEgg"),
        (["cheese"], "FoodCheese"),
        (["yogurt", "sour cream"], "FoodYogurt"),
        (["butter"], "FoodButter"),
        (["milk", "cream", "half-and-half"], "FoodMilk"),

        // Pantry & other
        (["tofu"], "FoodTofu"),
        (["bread", "toast", "bagel", "bun", "tortilla"], "FoodBread"),
        (["juice", "smoothie"], "FoodJuice"),
        (["cereal", "oat", "granola", "rice", "nut"], "FoodCereal"),
        (["muffin", "cupcake", "pastry"], "FoodMuffin"),

        // Vegetables
        (["carrot", "parsnip"], "FoodCarrot"),
        (["broccoli", "cauliflower", "brussels"], "FoodBroccoli"),
        (["mushroom", "shiitake", "enoki"], "FoodMushroom"),
        (["tomato", "tomatillo"], "FoodTomato"),
        (["pepper"], "FoodPepper"),
        (["corn"], "FoodCorn"),
        (["cucumber", "zucchini", "okra", "green beans", "wax beans", "peas"], "FoodCucumber"),
        (["onion", "garlic", "shallot", "leek", "scallion"], "FoodOnion"),
        (["potato", "yam", "taro", "ginger", "jicama", "turnip", "rutabaga", "celeriac", "beet", "radish"], "FoodPotato"),
        (["spinach", "lettuce", "kale", "cabbage", "chard", "greens", "arugula", "bok choy",
          "cilantro", "watercress", "endive", "escarole", "radicchio", "celery", "romaine"], "FoodLeafy"),

        // Fruit
        (["avocado"], "FoodAvocado"),
        (["banana"], "FoodBanana"),
        (["strawberr", "berry", "berries"], "FoodStrawberry"),
        (["grape"], "FoodGrape"),
        (["lemon"], "FoodLemon"),
        (["lime", "kiwi"], "FoodLime"),
        (["orange", "mandarin", "tangerine", "clementine", "apricot", "peach", "nectarine", "mango", "papaya"], "FoodOrange"),
        (["pear"], "FoodPear"),
        (["watermelon", "melon", "cantaloupe", "honeydew"], "FoodWatermelon"),
        (["apple", "plum", "pomegranate", "fig", "cherr"], "FoodApple"),
    ]

    static func assetName(for name: String, category: FoodCategory) -> String {
        let text = name.lowercased()
        for rule in rules where rule.words.contains(where: { text.contains($0) }) {
            return rule.asset ?? defaultAsset(for: category)
        }
        return defaultAsset(for: category)
    }

    static func defaultAsset(for category: FoodCategory) -> String {
        switch category {
        case .vegetable: return "FoodLeafy"
        case .fruit: return "FoodApple"
        case .dairy: return "FoodMilk"
        case .meat: return "FoodMeat"
        case .other: return "FoodJar"
        }
    }
}

/// Freshlings food illustration, sized as a square.
struct FoodIconView: View {
    let name: String
    let category: FoodCategory
    var size: CGFloat

    init(name: String, category: FoodCategory, size: CGFloat) {
        self.name = name
        self.category = category
        self.size = size
    }

    init(item: FoodItem, size: CGFloat) {
        self.init(name: item.name, category: item.category, size: size)
    }

    var body: some View {
        Image(FoodIcon.assetName(for: name, category: category))
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

// MARK: - Category icons

extension FoodCategory {
    /// Icon for the category itself (chips, pickers).
    var iconAsset: String {
        switch self {
        case .vegetable: return "FoodBroccoli"
        case .fruit: return "FoodApple"
        case .dairy: return "FoodMilk"
        case .meat: return "FoodMeat"
        case .other: return "FoodJar"
        }
    }
}

extension FoodIcon {
    /// Small pre-sized copy for Menu / Picker rows.
    /// iOS menus draw images at their real size, so the big asset is shrunk first.
    static func menuImage(_ asset: String, size: CGFloat = 22) -> Image {
        guard let image = UIImage(named: asset) else { return Image(systemName: "circle") }
        let box = CGSize(width: size, height: size)
        let small = UIGraphicsImageRenderer(size: box).image { _ in
            image.draw(in: CGRect(origin: .zero, size: box))
        }
        return Image(uiImage: small.withRenderingMode(.alwaysOriginal))
    }
}

// MARK: - Recipe icons

/// Freshlings drawing for a recipe (used when there is no photo).
struct RecipeIconView: View {
    let recipe: Recipe
    var size: CGFloat

    var body: some View {
        Image(recipe.icon)
            .resizable()
            .interpolation(.high)
            .scaledToFit()
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
        ForEach(["Apple", "Eggs", "Whole Milk", "Bacon", "Cherry Tomato", "Eggplant",
                 "Chicken Breast", "Red Bell Pepper", "Butter", "Kale"], id: \.self) { name in
            VStack {
                FoodIconView(name: name, category: .other, size: 44)
                Text(name).font(.caption2)
            }
        }
    }
    .padding()
}
