// ------------------------------------------------------------
// Written by Gladys Yu
// Food draft, ingredient-name matching, fallback shelf life and CO2
// ------------------------------------------------------------

import Foundation

struct FoodDraft {
    var name: String
    var category: FoodCategory
    var quantity: Int
    var addedDate: Date
    var estimatedValue: Double
    var preset: IngredientPreset?
    var fromScan: Bool

    var shelfLifeDays: Int {
        preset?.shelfLifeDays ?? category.fallbackShelfLifeDays
    }

    var carbonFactor: Double {
        preset?.carbonFactor ?? category.fallbackCarbonFactor
    }
}

enum PresetMatcher {
    static func find(_ name: String, in presets: [IngredientPreset]) -> IngredientPreset? {
        let text = name.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        if let exact = presets.first(where: { $0.name.lowercased() == text }) {
            return exact
        }

        return presets
            .sorted { $0.name.count > $1.name.count }
            .first { preset in
                let key = preset.name.lowercased()
                if text.contains(key) { return true }
                if key.hasSuffix("y") && text.contains(key.dropLast() + "ies") { return true }
                return false
            }
    }
}

extension FoodCategory {
    var addFoodIcon: String {
        switch self {
        case .vegetable: return "🥦"
        case .fruit: return "🍎"
        case .dairy: return "🥛"
        case .meat: return "🥩"
        default: return "🛒"
        }
    }

    var fallbackShelfLifeDays: Int {
        switch self {
        case .meat: return 3
        default: return 7
        }
    }

    /// Used when the food isn't in ingredients_preset.json.
    /// kg CO2e per unit = Poore & Nemecek (2018) kg CO2e/kg × an assumed unit weight.
    var fallbackCarbonFactor: Double {
        switch self {
        case .vegetable: return 0.53 * 0.2   // "Other Vegetables", ~200 g
        case .fruit: return 1.05 * 0.2       // "Other Fruit", ~200 g
        case .dairy: return 3.15 * 0.5       // "Milk", ~500 g
        case .meat: return 9.87 * 0.45       // "Poultry Meat", 1 lb pack
        default: return 1.57 * 0.5           // "Wheat & Rye" (pantry staples), ~500 g
        }
    }
}
