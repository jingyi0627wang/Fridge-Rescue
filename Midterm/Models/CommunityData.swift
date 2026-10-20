import SwiftUI

// MARK: - Community (demo)
// The Community feed shows:
//   • recipes the user shared (from My Recipes, "Share to Community" on)
//   • SAMPLE posts below, clearly marked "Sample" in the app
// Sharing between phones would need an online server (e.g. Firebase);
// for this project everything stays on the phone.

struct CommunityPost: Identifiable {
    let id: String
    let author: String
    let authorColor: Color
    let recipe: Recipe
    let caption: String
    let baseLikes: Int
    let date: Date
    let isSample: Bool
}

struct WeeklyChallenge {
    let title: String
    let detail: String
    let emoji: String
    /// Food names that count for this challenge (matched like recipe ingredients).
    let foods: [String]
}

enum CommunityData {

    private static func ing(_ amount: String, _ name: String) -> RecipeIngredient {
        RecipeIngredient(name: name, amount: amount)
    }

    private static func daysAgo(_ days: Double) -> Date {
        Date().addingTimeInterval(-days * 24 * 60 * 60)
    }

    // MARK: Sample posts

    static let samplePosts: [CommunityPost] = [
        CommunityPost(
            id: "sample-banana-pancakes",
            author: "mei.cooks",
            authorColor: Game.pink,
            recipe: Recipe(
                id: "community-banana-pancakes",
                name: "Spotty Banana Oat Pancakes",
                emoji: "🥞",
                time: 15,
                difficulty: "Easy",
                items: [ing("2 ripe", "Banana"), ing("2", "Eggs"), ing("1 cup", "Rolled Oats"),
                        ing("1/4 cup", "Milk"), ing("1 tsp", "Cinnamon")],
                steps: [
                    "Mash the bananas in a bowl until smooth.",
                    "Whisk in the eggs and milk, then stir in the oats and cinnamon.",
                    "Cook small scoops in a buttered pan, 2 minutes per side."
                ]
            ),
            caption: "The browner the banana, the sweeter the pancake. No sugar needed!",
            baseLikes: 128,
            date: daysAgo(0.2),
            isSample: true
        ),
        CommunityPost(
            id: "sample-fried-rice",
            author: "dormchef",
            authorColor: Game.orange,
            recipe: Recipe(
                id: "community-fried-rice",
                name: "Fridge Clean-Out Fried Rice",
                emoji: "🍚",
                time: 20,
                difficulty: "Easy",
                items: [ing("2 cups", "Cooked Rice"), ing("2", "Eggs"), ing("1", "Carrot"),
                        ing("1 cup", "Green Peas"), ing("2", "Scallion"), ing("2 tbsp", "Soy Sauce")],
                steps: [
                    "Dice whatever veggies are hanging around your fridge.",
                    "Scramble the eggs in a hot pan, then set aside.",
                    "Fry the veggies, add cold rice and soy sauce, then fold the eggs back in."
                ]
            ),
            caption: "Day-old rice + random veggies = my favorite Sunday dinner.",
            baseLikes: 94,
            date: daysAgo(1),
            isSample: true
        ),
        CommunityPost(
            id: "sample-spinach-pesto",
            author: "zerowaste_sam",
            authorColor: Game.green,
            recipe: Recipe(
                id: "community-spinach-pesto",
                name: "Wilted Spinach Pesto Pasta",
                emoji: "🍝",
                time: 25,
                difficulty: "Easy",
                items: [ing("2 cups", "Spinach"), ing("1 clove", "Garlic"), ing("1/2 cup", "Parmesan Cheese"),
                        ing("1/4 cup", "Olive Oil"), ing("8 oz", "Pasta"), ing("1/2", "Lemon")],
                steps: [
                    "Cook the pasta and save a cup of the pasta water.",
                    "Blend spinach, garlic, parmesan, olive oil and lemon juice.",
                    "Toss with the pasta, adding pasta water until glossy."
                ]
            ),
            caption: "Sad, droopy spinach? Blend it. Nobody will ever know.",
            baseLikes: 76,
            date: daysAgo(2),
            isSample: true
        ),
        CommunityPost(
            id: "sample-french-toast",
            author: "leftoverlucas",
            authorColor: Game.blue,
            recipe: Recipe(
                id: "community-french-toast",
                name: "Stale Bread French Toast",
                emoji: "🍞",
                time: 15,
                difficulty: "Easy",
                items: [ing("4 slices", "Bread"), ing("2", "Eggs"), ing("1/2 cup", "Milk"),
                        ing("1 tbsp", "Butter"), ing("1 tsp", "Cinnamon")],
                steps: [
                    "Whisk the eggs, milk and cinnamon.",
                    "Soak each slice for 20 seconds per side. Stale bread soaks it up best.",
                    "Fry in butter until golden."
                ]
            ),
            caption: "Stale bread is actually BETTER for french toast. Fight me.",
            baseLikes: 61,
            date: daysAgo(3),
            isSample: true
        ),
        CommunityPost(
            id: "sample-veggie-broth",
            author: "ana.b",
            authorColor: Game.hex(0xFF8A6B),
            recipe: Recipe(
                id: "community-veggie-broth",
                name: "Veggie Scrap Broth",
                emoji: "🥣",
                time: 60,
                difficulty: "Easy",
                items: [ing("4 cups", "Vegetable Scraps"), ing("1", "Onion"), ing("2", "Celery"),
                        ing("1", "Carrot"), ing("8 cups", "Water")],
                steps: [
                    "Save onion ends, carrot peels and celery tops in a bag in the freezer.",
                    "Cover with water and simmer for 45–60 minutes.",
                    "Strain and keep in the fridge for up to 5 days."
                ]
            ),
            caption: "Keep a scrap bag in the freezer and you'll never buy broth again.",
            baseLikes: 49,
            date: daysAgo(5),
            isSample: true
        ),
        CommunityPost(
            id: "sample-smoothie",
            author: "ricebowl.rin",
            authorColor: Game.yellow,
            recipe: Recipe(
                id: "community-smoothie",
                name: "Last-Day Yogurt Smoothie",
                emoji: "🥤",
                time: 5,
                difficulty: "Easy",
                items: [ing("1 cup", "Yogurt"), ing("1", "Banana"), ing("1 cup", "Strawberry"),
                        ing("1/2 cup", "Milk"), ing("1 tsp", "Honey")],
                steps: [
                    "Throw everything in a blender.",
                    "Blend until smooth. Add ice if you like it cold."
                ]
            ),
            caption: "Yogurt expiring tomorrow → breakfast today.",
            baseLikes: 37,
            date: daysAgo(6),
            isSample: true
        )
    ]

    // MARK: Weekly challenge (changes every week)

    static let challenges: [WeeklyChallenge] = [
        WeeklyChallenge(title: "Banana Rescue", detail: "Use up a banana before it goes brown.",
                        emoji: "🍌", foods: ["Banana"]),
        WeeklyChallenge(title: "Leafy Greens Week", detail: "Eat your spinach, lettuce or kale in time.",
                        emoji: "🥬", foods: ["Spinach", "Lettuce", "Kale", "Arugula"]),
        WeeklyChallenge(title: "Milk Mission", detail: "Finish a carton of milk before it expires.",
                        emoji: "🥛", foods: ["Milk"]),
        WeeklyChallenge(title: "Tomato Time", detail: "Rescue a tomato before it gets soft.",
                        emoji: "🍅", foods: ["Tomato"]),
        WeeklyChallenge(title: "Egg-cellent Week", detail: "Use up your eggs.",
                        emoji: "🥚", foods: ["Egg"])
    ]

    static var currentChallenge: WeeklyChallenge {
        let week = Calendar.current.component(.weekOfYear, from: Date())
        return challenges[week % challenges.count]
    }
}

extension FoodStore {
    /// Units of the challenge food rescued this week.
    func challengeProgress(_ challenge: WeeklyChallenge) -> Int {
        guard let start = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        let matching = usedItems.filter { record in
            record.finishedOn >= start &&
            challenge.foods.contains { FoodMatcher.matches(ingredient: $0, foodName: record.name) }
        }
        return FoodStore.units(in: matching)
    }
}
