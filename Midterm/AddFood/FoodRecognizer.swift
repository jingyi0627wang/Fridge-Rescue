import UIKit
import Vision

struct FoodSuggestion: Identifiable, Hashable {
    var id: String { name }
    let name: String
    let confidence: Float
    let category: FoodCategory
}

enum FoodRecognizer {

    private struct Label {
        let name: String
        let confidence: Float
    }

    private static let hintCategories: [String: FoodCategory] = [
        "fruit": .fruit, "citrus fruit": .fruit, "berry": .fruit,
        "vegetable": .vegetable, "produce": .vegetable, "leafy green": .vegetable,
        "dairy": .dairy,
        "meat": .meat, "seafood": .meat, "poultry": .meat
    ]

    private static let genericFood: Set<String> = [
        "food", "meal", "dish", "dessert", "baked goods", "beverage",
        "drink", "snack", "ingredient", "condiment"
    ]

    private static let ignored: Set<String> = [
        "container", "table", "kitchen", "refrigerator", "plate", "bowl", "jar",
        "bottle", "packaging", "people", "adult", "hand", "wood", "textile",
        "structure", "cutlery", "cookware", "tableware", "indoor", "plant",
        "paper", "cardboard", "plastic", "bag", "box", "counter"
    ]

    static func recognize(_ image: UIImage, presets: [IngredientPreset]) async -> [FoodSuggestion] {
        guard let cgImage = image.cgImage else { return [] }

        var found: [String: FoodSuggestion] = [:]
        func add(_ suggestion: FoodSuggestion) {
            if let existing = found[suggestion.name], existing.confidence >= suggestion.confidence { return }
            found[suggestion.name] = suggestion
        }

        for line in await readText(cgImage) {
            if let preset = presetMentioned(in: line, presets: presets) {
                add(FoodSuggestion(name: preset.name, confidence: 0.95, category: preset.category))
            }
        }

        var labels = await classify(cgImage)
        if let center = centerCrop(cgImage, fraction: 0.6) {
            labels += await classify(center)
        }

        let hintedCategory = labels
            .filter { hintCategories[$0.name] != nil && $0.confidence > 0.15 }
            .max { $0.confidence < $1.confidence }
            .flatMap { hintCategories[$0.name] } ?? .other

        let looksLikeFood = labels.contains {
            (genericFood.contains($0.name) || hintCategories[$0.name] != nil) && $0.confidence > 0.1
        }

        for label in labels {
            if genericFood.contains(label.name)
                || hintCategories[label.name] != nil
                || ignored.contains(label.name) { continue }

            if label.confidence >= 0.03, let preset = PresetMatcher.find(label.name, in: presets) {
                add(FoodSuggestion(name: preset.name,
                                   confidence: min(label.confidence + 0.3, 0.9),
                                   category: preset.category))
            } else if looksLikeFood && label.confidence >= 0.15 {
                add(FoodSuggestion(name: label.name.capitalized,
                                   confidence: label.confidence,
                                   category: hintedCategory))
            }
        }

        return Array(found.values.sorted { $0.confidence > $1.confidence }.prefix(6))
    }

    private static func classify(_ image: CGImage) async -> [Label] {
        do {
            let results = try await ClassifyImageRequest().perform(on: image)
            return results.map {
                Label(name: $0.identifier.replacingOccurrences(of: "_", with: " ").lowercased(),
                      confidence: $0.confidence)
            }
        } catch {
            print("Image classification failed: \(error)")
            return []
        }
    }

    private static func readText(_ image: CGImage) async -> [String] {
        do {
            let results = try await RecognizeTextRequest().perform(on: image)
            return results.compactMap { $0.topCandidates(1).first?.string }
        } catch {
            print("Text recognition failed: \(error)")
            return []
        }
    }

    private static func centerCrop(_ image: CGImage, fraction: CGFloat) -> CGImage? {
        let width = CGFloat(image.width)
        let height = CGFloat(image.height)
        let rect = CGRect(x: width * (1 - fraction) / 2,
                          y: height * (1 - fraction) / 2,
                          width: width * fraction,
                          height: height * fraction)
        return image.cropping(to: rect.integral)
    }

    private static func presetMentioned(in line: String, presets: [IngredientPreset]) -> IngredientPreset? {
        let words = line.lowercased()
            .components(separatedBy: CharacterSet.letters.inverted)
            .filter { !$0.isEmpty }
        guard !words.isEmpty else { return nil }
        let padded = " " + words.joined(separator: " ") + " "

        return presets
            .sorted { $0.name.count > $1.name.count }
            .first { preset in
                let key = preset.name.lowercased()
                let plural = key.hasSuffix("y") ? String(key.dropLast()) + "ies" : key + "s"
                return padded.contains(" \(key) ")
                    || padded.contains(" \(plural) ")
                    || padded.contains(" \(key)es ")
            }
    }
}
