import Foundation

struct IngredientPreset: Codable, Identifiable {
    var id: String { name }
    let name: String
    let category: FoodCategory
    let shelfLifeDays: Int
    let estimatedValue: Double
    /// kg CO2e for ONE unit (= carbonPerKg × unitWeightKg).
    let carbonFactor: Double
    let storageTip: String

    // Carbon data — Poore & Nemecek (2018), via Our World in Data.
    // Optional so older JSON files still load.
    let unit: String?            // what "1" means, e.g. "each", "bunch", "1 lb pack"
    let unitWeightKg: Double?    // typical weight of one unit
    let carbonPerKg: Double?     // kg CO2e per kg of this food
    let carbonSource: String?    // food group used from the dataset
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
        let key = foodName.lowercased()
        if let cached = tipCache[key] { return cached }
        let tip = PresetMatcher.find(foodName, in: loadPresets())?.storageTip
        let result = (tip?.isEmpty ?? true) ? nil : tip
        tipCache[key] = .some(result)
        return result
    }

    private var tipCache: [String: String?] = [:]
}
