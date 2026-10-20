import Foundation

// MARK: - TheMealDB (free online recipes)
// https://www.themealdb.com/api.php
//
// The test key "1" is free for development and educational use.
// (Publishing on the App Store requires a supporter key: swap `apiKey` below.)
//
// How it works:
// 1. For the most urgent fridge items, ask "which meals use <ingredient>?"
//      GET /filter.php?i=chicken_breast   → [{ idMeal, strMeal, strMealThumb }]
// 2. Meals that use MORE of your fridge items rank higher.
// 3. For the top meals, download the full recipe (ingredients + steps):
//      GET /lookup.php?i=52772
// Results are cached in memory, so switching tabs doesn't re-download.
// If there is no internet, the app just shows the built-in recipes.

enum MealDBService {

    private static let apiKey = "1"
    private static var baseURL: String { "https://www.themealdb.com/api/json/v1/\(apiKey)/" }

    struct OnlineResult {
        let recipes: [Recipe]
        let isOffline: Bool
    }

    private struct MealSummary: Decodable {
        let idMeal: String
        let strMeal: String
    }

    private struct FilterResponse: Decodable {
        let meals: [MealSummary]?
    }

    private enum FetchError: Error { case offline }

    // Caches (live while the app is open)
    private static var mealsByIngredient: [String: [MealSummary]] = [:]
    private static var recipesByID: [String: Recipe] = [:]

    // MARK: Public

    /// Online recipes for these fridge items, best matches first.
    static func recommendations(for items: [FoodItem], maxRecipes: Int = 8) async -> OnlineResult {
        // Only look up the most urgent items to keep it fast.
        let active: [FoodItem] = items.filter { $0.status == .active }
        let keyed: [(item: FoodItem, days: Int)] = active.map { (item: $0, days: $0.daysUntilExpiration) }
        let byUrgency = keyed.sorted { a, b in a.days < b.days }
        let targets: [FoodItem] = byUrgency.prefix(4).map { $0.item }

        guard !targets.isEmpty else { return OnlineResult(recipes: [], isOffline: false) }

        var scores: [String: Int] = [:]
        var order: [String] = []

        do {
            for item in targets {
                for meal in try await meals(using: item.name) {
                    if scores[meal.idMeal] == nil { order.append(meal.idMeal) }
                    scores[meal.idMeal, default: 0] += 1
                }
            }
        } catch {
            return OnlineResult(recipes: [], isOffline: true)
        }

        // Meals that use more of your fridge items first.
        let topIDs = order
            .enumerated()
            .sorted { lhs, rhs in
                let l = scores[lhs.element] ?? 0, r = scores[rhs.element] ?? 0
                return l != r ? l > r : lhs.offset < rhs.offset
            }
            .prefix(maxRecipes)
            .map(\.element)

        var recipes: [Recipe] = []
        for id in topIDs {
            if let recipe = try? await recipe(id: id) {
                recipes.append(recipe)
            }
        }

        let counted: [(recipe: Recipe, count: Int)] = recipes.map { (recipe: $0, count: RecipeData.matchCount($0, items)) }
        let byMatches = counted.sorted { a, b in a.count > b.count }
        let sorted: [Recipe] = byMatches.map { $0.recipe }
        return OnlineResult(recipes: sorted, isOffline: false)
    }

    // MARK: Step 1 — meals that use an ingredient

    private static func meals(using foodName: String) async throws -> [MealSummary] {
        let key = foodName.lowercased()
        if let cached = mealsByIngredient[key] { return cached }

        // TheMealDB names are like "Chicken Breast", "Carrots", "Eggs", and
        // spelling matters ("carrot" → 1 meal, "carrots" → 79). Try the full name
        // in a few spellings and keep the one with the most meals; if nothing,
        // try the last word ("Whole Milk" → "Milk").
        for group in searchNames(for: foodName) {
            var best: [MealSummary] = []
            for candidate in group {
                let query = candidate.replacingOccurrences(of: " ", with: "_")
                guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
                      let url = URL(string: baseURL + "filter.php?i=" + encoded) else { continue }

                let data = try await download(url)
                let meals = (try? JSONDecoder().decode(FilterResponse.self, from: data))?.meals ?? []
                if meals.count > best.count { best = meals }
            }
            if !best.isEmpty {
                mealsByIngredient[key] = best
                return best
            }
        }

        mealsByIngredient[key] = []
        return []
    }

    /// "Whole Milk" → [["Whole Milk", "Whole Milks"], ["Milk", "Milks"]]
    private static func searchNames(for name: String) -> [[String]] {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let lastWord = trimmed.split(separator: " ").last.map(String.init) ?? trimmed
        let bases = trimmed == lastWord ? [trimmed] : [trimmed, lastWord]
        return bases.map { base in
            var names: [String] = []
            for variant in [base, plural(base), singular(base)] where !names.contains(variant) {
                names.append(variant)
            }
            return names
        }
    }

    private static func plural(_ word: String) -> String {
        let lower = word.lowercased()
        if lower.hasSuffix("s") { return word }
        if lower.hasSuffix("y"), !lower.hasSuffix("ey") { return String(word.dropLast()) + "ies" }
        if lower.hasSuffix("o") { return word + "es" }
        return word + "s"
    }

    private static func singular(_ word: String) -> String {
        let lower = word.lowercased()
        if lower.hasSuffix("ies") { return String(word.dropLast(3)) + "y" }
        if lower.hasSuffix("oes") { return String(word.dropLast(2)) }
        if lower.hasSuffix("s"), !lower.hasSuffix("ss") { return String(word.dropLast()) }
        return word
    }

    // MARK: Step 2 — full recipe

    private static func recipe(id: String) async throws -> Recipe? {
        if let cached = recipesByID[id] { return cached }
        guard let url = URL(string: baseURL + "lookup.php?i=" + id) else { return nil }

        let data = try await download(url)
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let meal = (json["meals"] as? [[String: Any]])?.first,
              let recipe = makeRecipe(from: meal) else { return nil }

        recipesByID[id] = recipe
        return recipe
    }

    private static func makeRecipe(from meal: [String: Any]) -> Recipe? {
        func text(_ key: String) -> String {
            ((meal[key] as? String) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let id = text("idMeal")
        let name = text("strMeal")
        guard !id.isEmpty, !name.isEmpty else { return nil }

        // strIngredient1…20 + strMeasure1…20
        var items: [RecipeIngredient] = []
        for i in 1...20 {
            let ingredient = text("strIngredient\(i)")
            guard !ingredient.isEmpty else { continue }
            items.append(RecipeIngredient(name: ingredient.capitalized, amount: text("strMeasure\(i)")))
        }

        let category = text("strCategory")
        let area = text("strArea")

        return Recipe(
            id: "mealdb-\(id)",
            name: name,
            emoji: emoji(for: category),
            time: 0,
            difficulty: category.isEmpty ? "Recipe" : category,
            items: items,
            steps: steps(from: text("strInstructions")),
            imageURL: URL(string: text("strMealThumb")),
            area: area.isEmpty ? nil : area,
            sourceURL: URL(string: "https://www.themealdb.com/meal/\(id)")
        )
    }

    /// Splits the instructions into steps and removes "STEP 1"-style labels.
    private static func steps(from instructions: String) -> [String] {
        var lines = instructions
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { line in
                guard !line.isEmpty else { return false }
                let lower = line.lowercased()
                let isLabel = lower.hasPrefix("step") && lower.count <= 8
                let isNumber = Int(line.trimmingCharacters(in: CharacterSet(charactersIn: ".)"))) != nil
                return !isLabel && !isNumber
            }

        // Some recipes are one long paragraph: split into sentences.
        if lines.count == 1, let paragraph = lines.first {
            lines = paragraph
                .components(separatedBy: ". ")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .map { $0.hasSuffix(".") ? $0 : $0 + "." }
        }
        return lines
    }

    private static func emoji(for category: String) -> String {
        switch category.lowercased() {
        case "chicken": return "🍗"
        case "beef": return "🥩"
        case "pork": return "🥓"
        case "lamb", "goat": return "🍖"
        case "seafood": return "🐟"
        case "pasta": return "🍝"
        case "vegetarian", "vegan": return "🥗"
        case "breakfast": return "🍳"
        case "dessert": return "🍰"
        case "side": return "🥔"
        case "starter": return "🥟"
        default: return "🍽️"
        }
    }

    // MARK: Networking

    private static func download(_ url: URL) async throws -> Data {
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                throw FetchError.offline
            }
            return data
        } catch {
            throw FetchError.offline
        }
    }
}

extension RecipeData {
    /// Built-in + online recipes in one list (no duplicate names),
    /// recipes using more fridge items first.
    static func merged(local: [Recipe], online: [Recipe], items: [FoodItem]) -> [Recipe] {
        var seen = Set(local.map { $0.name.lowercased() })
        let extra = online.filter { seen.insert($0.name.lowercased()).inserted }
        // Count once per recipe (not inside the sort comparator).
        let all: [Recipe] = local + extra
        var counted: [(recipe: Recipe, order: Int, count: Int)] = []
        for (index, recipe) in all.enumerated() {
            counted.append((recipe: recipe, order: index, count: matchCount(recipe, items)))
        }
        let ordered = counted.sorted { a, b in
            if a.count != b.count { return a.count > b.count }
            return a.order < b.order
        }
        return ordered.map { $0.recipe }
    }
}
