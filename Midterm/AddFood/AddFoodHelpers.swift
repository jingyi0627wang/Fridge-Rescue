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

    var fallbackCarbonFactor: Double {
        switch self {
        case .vegetable: return 0.3
        case .fruit: return 0.4
        case .dairy: return 1.2
        case .meat: return 5.0
        default: return 0.5
        }
    }
}
