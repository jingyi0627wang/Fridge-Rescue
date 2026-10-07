import Foundation

struct Recipe: Identifiable {
    let id = UUID()

    let name: String
    let emoji: String
    let time: Int
    let difficulty: String
    let ingredients: [String]
    let steps: [String]
}

enum RecipeData {

    static let recipes: [Recipe] = [

        Recipe(
            name: "Creamy Carrot Soup",
            emoji: "🥕",
            time: 20,
            difficulty: "Easy",
            ingredients: [
                "Carrot",
                "Milk",
                "Onion",
                "Salt"
            ],
            steps: [
                "Cut the carrots and onion into small pieces.",
                "Cook the vegetables until they become soft.",
                "Add milk and simmer for a few minutes.",
                "Blend until smooth.",
                "Season with salt and serve warm."
            ]
        ),

        Recipe(
            name: "Milk Pancakes",
            emoji: "🥞",
            time: 15,
            difficulty: "Easy",
            ingredients: [
                "Milk",
                "Egg",
                "Flour",
                "Sugar"
            ],
            steps: [
                "Combine flour and sugar in a bowl.",
                "Add milk and egg.",
                "Mix until the batter is smooth.",
                "Cook both sides in a heated pan.",
                "Serve while warm."
            ]
        ),

        Recipe(
            name: "Roasted Carrots",
            emoji: "🥕",
            time: 25,
            difficulty: "Easy",
            ingredients: [
                "Carrot",
                "Olive Oil",
                "Salt"
            ],
            steps: [
                "Cut the carrots into even pieces.",
                "Coat them lightly with olive oil.",
                "Season with salt.",
                "Roast until tender and lightly browned."
            ]
        )
    ]

    static func recommendations(
        for items: [FoodItem]
    ) -> [Recipe] {

        let fridgeNames = Set(
            items.map { $0.name.lowercased() }
        )

        return recipes
            .filter { recipe in
                recipe.ingredients.contains {
                    fridgeNames.contains($0.lowercased())
                }
            }
            .sorted { first, second in
                matchCount(first, fridgeNames) >
                matchCount(second, fridgeNames)
            }
    }

    private static func matchCount(
        _ recipe: Recipe,
        _ fridgeNames: Set<String>
    ) -> Int {

        recipe.ingredients.filter {
            fridgeNames.contains($0.lowercased())
        }.count
    }
}
