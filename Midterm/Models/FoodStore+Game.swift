import SwiftUI

// MARK: - Game: XP, levels, badges
// Everything here is worked out from the food history the app already saves,
// so nothing new needs to be stored and old data counts too.
//
// XP rules
//   • Every unit of food you use ("rescue") = 10 XP
//   • Rescued with 2 days or less left (or already past its date) = 20 XP
//   • Throwing food away = 0 XP

struct LevelInfo {
    let level: Int
    let xpIntoLevel: Int     // XP earned since this level started
    let xpForLevel: Int      // XP needed to reach the next level
    let totalXP: Int

    var progress: Double {
        xpForLevel == 0 ? 0 : min(Double(xpIntoLevel) / Double(xpForLevel), 1)
    }

    /// Rank name shown under the player's name.
    var title: String { LevelInfo.title(for: level) }

    static func title(for level: Int) -> String {
        switch level {
        case 1: return "Sprout"
        case 2: return "Seedling"
        case 3: return "Leaf Helper"
        case 4: return "Fridge Rescuer"
        case 5: return "Waste Warrior"
        case 6: return "Freshness Hero"
        default: return "Freshling Legend"
        }
    }
}

struct GameBadge: Identifiable {
    let id: String
    let title: String
    let detail: String
    let icon: String       // SF Symbol
    let color: Color
    let unlocked: Bool
}

extension FoodStore {

    // MARK: XP

    /// XP for one unit, based on days left when it was used.
    static func xpPerUnit(daysLeft: Int) -> Int {
        daysLeft <= 2 ? 20 : 10
    }

    /// XP a history record earned (0 for wasted food).
    static func xp(for record: FoodItem) -> Int {
        guard record.status == .used else { return 0 }
        let calendar = Calendar.current
        let daysLeft = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: record.finishedOn),
            to: calendar.startOfDay(for: record.expirationDate)
        ).day ?? 0
        return xpPerUnit(daysLeft: daysLeft) * record.quantity
    }

    /// XP you'd get for rescuing ONE of this fridge item today.
    static func questXP(for item: FoodItem) -> Int {
        xpPerUnit(daysLeft: item.daysUntilExpiration)
    }

    var totalXP: Int {
        var total = 0
        for record in history { total += FoodStore.xp(for: record) }
        return total
    }

    /// Level L starts at 50 × L × (L − 1) XP: 0, 100, 300, 600, 1000, …
    /// (each level needs 100 more XP than the one before).
    static func xpToReach(level: Int) -> Int {
        50 * level * (level - 1)
    }

    var levelInfo: LevelInfo {
        let xp = totalXP
        var level = 1
        while xp >= FoodStore.xpToReach(level: level + 1) {
            level += 1
        }
        let start = FoodStore.xpToReach(level: level)
        let next = FoodStore.xpToReach(level: level + 1)
        return LevelInfo(level: level, xpIntoLevel: xp - start, xpForLevel: next - start, totalXP: xp)
    }

    // MARK: Today

    /// Units rescued (used) today, for the Daily Quests header.
    var rescuedToday: Int {
        let today = Calendar.current.startOfDay(for: Date())
        return FoodStore.units(in: usedItems.filter { $0.finishedOn >= today })
    }

    // MARK: Streaks

    /// Longest run of days in a row with at least one item used.
    var longestStreak: Int {
        let calendar = Calendar.current
        let days = Set(usedItems.map { calendar.startOfDay(for: $0.finishedOn) }).sorted()
        var best = 0
        var current = 0
        var previous: Date?
        for day in days {
            if let previous,
               let next = calendar.date(byAdding: .day, value: 1, to: previous),
               calendar.isDate(next, inSameDayAs: day) {
                current += 1
            } else {
                current = 1
            }
            best = max(best, current)
            previous = day
        }
        return best
    }

    // MARK: Badges

    var badges: [GameBadge] {
        let used = usedCount
        let money = moneySaved
        let streak = longestStreak

        // Units rescued with 1 day or less left.
        var lastMinute = 0
        let calendar = Calendar.current
        for record in usedItems {
            let daysLeft = calendar.dateComponents(
                [.day],
                from: calendar.startOfDay(for: record.finishedOn),
                to: calendar.startOfDay(for: record.expirationDate)
            ).day ?? 0
            if daysLeft <= 1 { lastMinute += record.quantity }
        }

        let usedCategories = Set(usedItems.map(\.category))

        return [
            GameBadge(id: "first", title: "First Rescue", detail: "Use your first food",
                      icon: "leaf.fill", color: Game.green, unlocked: used >= 1),
            GameBadge(id: "ten", title: "10 Rescued", detail: "Use 10 foods",
                      icon: "star.fill", color: Game.yellow, unlocked: used >= 10),
            GameBadge(id: "fifty", title: "50 Rescued", detail: "Use 50 foods",
                      icon: "crown.fill", color: Game.orange, unlocked: used >= 50),
            GameBadge(id: "streak3", title: "3-Day Streak", detail: "Use food 3 days in a row",
                      icon: "flame.fill", color: Game.red, unlocked: streak >= 3),
            GameBadge(id: "streak7", title: "7-Day Streak", detail: "Use food 7 days in a row",
                      icon: "flame.circle.fill", color: Game.red, unlocked: streak >= 7),
            GameBadge(id: "save25", title: "Saved $25", detail: "Save $25 of food",
                      icon: "dollarsign", color: Game.orange, unlocked: money >= 25),
            GameBadge(id: "save100", title: "Saved $100", detail: "Save $100 of food",
                      icon: "banknote.fill", color: Game.green, unlocked: money >= 100),
            GameBadge(id: "hero", title: "Last-Minute Hero", detail: "Rescue 5 foods with 1 day left",
                      icon: "bolt.fill", color: Game.yellow, unlocked: lastMinute >= 5),
            GameBadge(id: "rainbow", title: "Rainbow Eater", detail: "Use food from every category",
                      icon: "sparkles", color: Game.pink,
                      unlocked: usedCategories.count >= FoodCategory.allCases.count),
            GameBadge(id: "planet", title: "Planet Pal", detail: "Save 10 kg of CO₂",
                      icon: "globe.americas.fill", color: Game.blue, unlocked: carbonSaved >= 10)
        ]
    }

    var unlockedBadgeCount: Int {
        badges.filter(\.unlocked).count
    }
}
