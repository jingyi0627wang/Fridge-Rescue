import Foundation

struct IngredientPreset: Codable, Identifiable {
    var id: String { name }
    let name: String
    let category: FoodCategory
    let shelfLifeDays: Int
    let estimatedValue: Double
    let carbonFactor: Double
    let storageTip: String
}

final class IngredientPresetService {
    static let shared = IngredientPresetService()
    private init() {}

    /// The JSON is read once and then kept in memory.
    private var cache: [IngredientPreset]?

    func loadPresets() -> [IngredientPreset] {
        if let cache { return cache }

        guard let url = Bundle.main.url(forResource: "ingredients_preset", withExtension: "json") else {
            print("Cannot find ingredients_preset.json")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            let presets = try JSONDecoder().decode([IngredientPreset].self, from: data)
            cache = presets
            return presets
        } catch {
            print("Failed to load presets: \(error)")
            return []
        }
    }

    func findIngredient(named name: String) -> IngredientPreset? {
        loadPresets().first { $0.name.lowercased() == name.lowercased() }
    }

    /// Storage tip for a food in the fridge ("Whole Milk" → Milk's tip).
    func storageTip(for foodName: String) -> String? {
        guard let tip = PresetMatcher.find(foodName, in: loadPresets())?.storageTip,
              !tip.isEmpty else { return nil }
        return tip
    }
}
