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

    func loadPresets() -> [IngredientPreset] {
        guard let url = Bundle.main.url(forResource: "ingredients_preset", withExtension: "json") else {
            print("Cannot find ingredients_preset.json")
            return []
        }

        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode([IngredientPreset].self, from: data)
        } catch {
            print("Failed to load presets: \(error)")
            return []
        }
    }

    func findIngredient(named name: String) -> IngredientPreset? {
        loadPresets().first { $0.name.lowercased() == name.lowercased() }
    }
}
