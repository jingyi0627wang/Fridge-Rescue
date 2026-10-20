import Foundation

// MARK: - Add history ("Recent" and "Usually" on the Add Food page)

/// One time the user added a food to the fridge.
struct AddRecord: Codable, Identifiable {
    var id = UUID()
    let name: String
    let category: FoodCategory
    let quantity: Int
    let price: Double
    let date: Date

    init(item: FoodItem) {
        name = item.name
        category = item.category
        quantity = item.quantity
        price = item.estimatedValue
        date = item.addedDate
    }
}

/// A food suggestion shown as a chip on Add Food.
struct QuickAddSuggestion: Identifiable {
    var id: String { name.lowercased() }
    let name: String
    let category: FoodCategory
    let quantity: Int        // last time (Recent) or most common amount (Usually)
    let price: Double        // price paid last time
    let timesAdded: Int
    let lastAdded: Date
}

extension FoodStore {

    private static let maxLogSize = 300

    func logAdd(_ item: FoodItem) {
        // Date = now, so food bought a few days ago still counts as just added.
        addLog.append(AddRecord(name: item.name, category: item.category,
                                quantity: item.quantity, price: item.estimatedValue, date: Date()))
        if addLog.count > Self.maxLogSize {
            addLog.removeFirst(addLog.count - Self.maxLogSize)
        }
    }

    /// One suggestion per food name, built from every time it was added.
    private var suggestionsByName: [QuickAddSuggestion] {
        let groups = Dictionary(grouping: addLog) { $0.name.lowercased() }
        var result: [QuickAddSuggestion] = []
        for (_, records) in groups {
            let ordered = records.sorted { $0.date < $1.date }
            guard let last = ordered.last else { continue }
            // Most common quantity (ties → the most recent one).
            var counts: [Int: Int] = [:]
            var usualQuantity = last.quantity
            var bestCount = 0
            for record in ordered {
                let count = (counts[record.quantity] ?? 0) + 1
                counts[record.quantity] = count
                if count >= bestCount {
                    bestCount = count
                    usualQuantity = record.quantity
                }
            }

            result.append(QuickAddSuggestion(
                name: last.name,
                category: last.category,
                quantity: usualQuantity,
                price: last.price,
                timesAdded: ordered.count,
                lastAdded: last.date
            ))
        }
        return result
    }

    /// Most recently added foods, newest first.
    func recentAdds(limit: Int = 8) -> [QuickAddSuggestion] {
        let sorted = suggestionsByName.sorted { $0.lastAdded > $1.lastAdded }
        return Array(sorted.prefix(limit))
    }

    /// Foods added 2+ times, most often first.
    func usualAdds(limit: Int = 8) -> [QuickAddSuggestion] {
        let repeated = suggestionsByName.filter { $0.timesAdded >= 2 }
        let sorted = repeated.sorted { a, b in
            if a.timesAdded != b.timesAdded { return a.timesAdded > b.timesAdded }
            return a.lastAdded > b.lastAdded
        }
        return Array(sorted.prefix(limit))
    }
}

extension AddRecord {
    init(name: String, category: FoodCategory, quantity: Int, price: Double, date: Date) {
        self.name = name
        self.category = category
        self.quantity = quantity
        self.price = price
        self.date = date
    }
}
