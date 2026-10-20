//
//  Foodstore+Impact.swift
//  Midterm
//
//  Created by Rumik He on 10/13/26.
//

import Foundation

struct CategoryStat: Identifiable {
    let category: FoodCategory
    let count: Int
    var id: String { category.rawValue }
}

extension FoodStore {


    var usedItems: [FoodItem] {
        history.filter { $0.status == .used }
    }

    var wastedItems: [FoodItem] {
        history.filter { $0.status == .wasted }
    }


    // Counts below add up QUANTITIES (units), not history records:
    // using 3 carrots one at a time = 3, the same as using all 3 at once.

    /// Adds up the quantity of every record (kept simple so the compiler stays fast).
    static func units(in records: [FoodItem]) -> Int {
        var total = 0
        for record in records { total += record.quantity }
        return total
    }

    /// Total units used (eaten / cooked).
    var usedCount: Int { FoodStore.units(in: usedItems) }

    /// Total units thrown away.
    var wastedCount: Int { FoodStore.units(in: wastedItems) }

    var moneySaved: Double {
        usedItems.reduce(0) { total, item in
            total + item.estimatedValue * Double(item.quantity)
        }
    }

    var carbonSaved: Double {
        usedItems.reduce(0) { total, item in
            total + item.carbonFactor * Double(item.quantity)
        }
    }

    var useRate: Double {
        let total = usedCount + wastedCount
        guard total > 0 else { return 0 }
        return Double(usedCount) / Double(total)
    }

    //charts

    var usedByCategory: [CategoryStat] {
        FoodCategory.allCases
            .map { category in
                CategoryStat(
                    category: category,
                    count: FoodStore.units(in: usedItems.filter { $0.category == category })
                )
            }
            .filter { $0.count > 0 }
    }
}


// MARK: - Progress over time

struct WeeklyStat: Identifiable {
    let weekStart: Date
    let status: String      // "Used" or "Wasted"
    let count: Int
    var id: String { "\(weekStart.timeIntervalSince1970)-\(status)" }
}

extension FoodStore {

    /// Used / wasted counts for each of the last `weeks` weeks (oldest first).
    func weeklyStats(weeks: Int = 6) -> [WeeklyStat] {
        let calendar = Calendar.current
        guard let thisWeek = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }

        return (0..<weeks).reversed().flatMap { offset -> [WeeklyStat] in
            guard let start = calendar.date(byAdding: .weekOfYear, value: -offset, to: thisWeek),
                  let end = calendar.date(byAdding: .weekOfYear, value: 1, to: start) else { return [] }

            let inWeek = history.filter { $0.finishedOn >= start && $0.finishedOn < end }
            return [
                WeeklyStat(weekStart: start, status: "Used",
                           count: FoodStore.units(in: inWeek.filter { $0.status == .used })),
                WeeklyStat(weekStart: start, status: "Wasted",
                           count: FoodStore.units(in: inWeek.filter { $0.status == .wasted }))
            ]
        }
    }

    /// Items used since the start of this week (for the weekly goal).
    var usedThisWeek: Int {
        guard let start = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start else { return 0 }
        return FoodStore.units(in: usedItems.filter { $0.finishedOn >= start })
    }

    /// Days in a row (up to today) where at least one item was used.
    /// The streak is still alive if the last rescue was yesterday.
    var rescueStreak: Int {
        let calendar = Calendar.current
        let usedDays = Set(usedItems.map { calendar.startOfDay(for: $0.finishedOn) })

        var day = calendar.startOfDay(for: Date())
        if !usedDays.contains(day) {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }

        var streak = 0
        while usedDays.contains(day) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }
}

// MARK: - Goal progress

extension FoodStore {

    private var startOfWeek: Date {
        Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
    }

    private var startOfMonth: Date {
        Calendar.current.dateInterval(of: .month, for: Date())?.start ?? Date()
    }

    var wastedThisWeek: Int {
        FoodStore.units(in: wastedItems.filter { $0.finishedOn >= startOfWeek })
    }

    var moneySavedThisMonth: Double {
        usedItems
            .filter { $0.finishedOn >= startOfMonth }
            .reduce(0) { $0 + $1.estimatedValue * Double($1.quantity) }
    }
}
