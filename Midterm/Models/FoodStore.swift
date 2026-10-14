import Foundation
import SwiftUI
import Combine

final class FoodStore: ObservableObject {
    @Published var foodItems: [FoodItem] = [] {
        didSet {
            saveItems()
            sortedCache = nil
        }
    }

    /// Active food, most urgent (fewest days left) first.
    /// Sorted once and reused until the food list or the date changes.
    var activeItemsByUrgency: [FoodItem] {
        let today = Calendar.current.startOfDay(for: Date())
        if let cache = sortedCache, cache.day == today { return cache.items }
        // Split into small steps with explicit types (keeps the compiler fast).
        let active: [FoodItem] = foodItems.filter { $0.status == .active }
        let keyed: [(item: FoodItem, days: Int)] = active.map { (item: $0, days: $0.daysUntilExpiration) }
        let ordered = keyed.sorted { a, b in
            if a.days != b.days { return a.days < b.days }
            return a.item.name < b.item.name
        }
        let sorted: [FoodItem] = ordered.map { $0.item }
        sortedCache = (today, sorted)
        return sorted
    }

    private var sortedCache: (day: Date, items: [FoodItem])?

    @Published var history: [FoodItem] = [] {
        didSet { saveHistory() }
    }

    private let foodItemsKey = "savedFoodItems"
    private let historyKey = "savedFoodHistory"

    init() {
        loadData()
    }

    // MARK: - Fridge

    func addItem(_ item: FoodItem) {
        foodItems.append(item)
        // Remind the user 3 days before the item expires.
        Task {
            await ExpirationNotificationService.shared
                .requestAuthorizationAndSchedule(items: [item])
        }
    }

    /// Saves changes made on the Edit screen and re-schedules the reminder.
    func updateItem(_ item: FoodItem) {
        guard let index = foodItems.firstIndex(where: { $0.id == item.id }) else { return }
        foodItems[index] = item
        ExpirationNotificationService.shared.cancel(for: item)
        Task {
            await ExpirationNotificationService.shared
                .requestAuthorizationAndSchedule(items: [item])
        }
    }

    func deleteItem(_ item: FoodItem) {
        undoable("Deleted \(item.name)") {
            removeFromFridge(item)
        }
    }

    private func removeFromFridge(_ item: FoodItem) {
        foodItems.removeAll { $0.id == item.id }
        ExpirationNotificationService.shared.cancel(for: item)
    }

    // MARK: - Used / Wasted
    // `quantity` = how many to take out (nil = all of them).
    // Using 1 of 3 carrots leaves 2 in the fridge and adds a history
    // record for 1 carrot (so money and carbon are counted correctly).

    func markAsUsed(_ item: FoodItem, quantity: Int? = nil) {
        let count = clampedCount(item, quantity)
        undoable(message(item, count, verb: "Used", allText: "marked as used")) {
            take(item, count, as: .used)
        }
    }

    func markAsWasted(_ item: FoodItem, quantity: Int? = nil) {
        let count = clampedCount(item, quantity)
        undoable(message(item, count, verb: "Threw away", allText: "counted as wasted")) {
            take(item, count, as: .wasted)
        }
    }

    /// "I Cooked This": how many of each fridge item the recipe used.
    func cook(_ uses: [(item: FoodItem, quantity: Int)]) {
        let used = uses.filter { $0.quantity > 0 }
        guard !used.isEmpty else { return }
        let names = used.map { $0.quantity > 1 ? "\($0.quantity) \($0.item.name)" : $0.item.name }
        undoable("Cooked! Used \(names.joined(separator: ", "))") {
            used.forEach { take($0.item, $0.quantity, as: .used) }
        }
    }

    private func clampedCount(_ item: FoodItem, _ quantity: Int?) -> Int {
        let current = foodItems.first { $0.id == item.id }?.quantity ?? item.quantity
        return min(max(quantity ?? current, 1), current)
    }

    private func message(_ item: FoodItem, _ count: Int, verb: String, allText: String) -> String {
        let current = foodItems.first { $0.id == item.id }?.quantity ?? item.quantity
        if count >= current { return "\(item.name) \(allText)" }
        return "\(verb) \(count) \(item.name) · \(current - count) left"
    }

    private func take(_ item: FoodItem, _ count: Int, as status: FoodStatus) {
        // Always work on the latest version in the fridge.
        guard let index = foodItems.firstIndex(where: { $0.id == item.id }) else { return }
        let current = foodItems[index]
        let count = min(max(count, 1), current.quantity)

        var record = current
        record.id = UUID()
        record.originalID = current.id
        record.quantity = count
        record.status = status
        record.finishedDate = Date()
        history.append(record)

        if count >= current.quantity {
            removeFromFridge(current)
        } else {
            foodItems[index].quantity -= count
        }
    }

    // MARK: - History

    /// Puts a history record back in the fridge. If the original item is still
    /// there (e.g. 2 carrots left), the quantity is added back to it.
    func restoreFromHistory(_ record: FoodItem) {
        undoable("\(record.name) moved back to the fridge") {
            history.removeAll { $0.id == record.id }

            if let originalID = record.originalID,
               let index = foodItems.firstIndex(where: { $0.id == originalID }) {
                foodItems[index].quantity += record.quantity
            } else {
                var restored = record
                restored.id = record.originalID ?? record.id
                restored.originalID = nil
                restored.status = .active
                restored.finishedDate = nil
                addItem(restored)
            }
        }
    }

    func removeFromHistory(_ item: FoodItem) {
        undoable("Removed \(item.name) from history") {
            history.removeAll { $0.id == item.id }
        }
    }

    // MARK: - Undo
    // Instead of "Are you sure?" pop-ups, actions happen right away and a small
    // bar at the bottom offers "Undo" for a few seconds (see UndoToastView).

    struct UndoToast: Identifiable {
        let id = UUID()
        let message: String
        fileprivate let previousItems: [FoodItem]
        fileprivate let previousHistory: [FoodItem]
    }

    @Published var toast: UndoToast?

    func undoable(_ message: String, _ change: () -> Void) {
        let items = foodItems
        let past = history
        change()
        toast = UndoToast(message: message, previousItems: items, previousHistory: past)
    }

    func undo() {
        guard let toast else { return }
        let removedFromFridge = foodItems.filter { item in
            !toast.previousItems.contains { $0.id == item.id }
        }
        removedFromFridge.forEach { ExpirationNotificationService.shared.cancel(for: $0) }

        foodItems = toast.previousItems
        history = toast.previousHistory
        self.toast = nil

        Task {
            await ExpirationNotificationService.shared
                .requestAuthorizationAndSchedule(items: foodItems)
        }
    }

    func dismissToast(_ id: UUID) {
        if toast?.id == id { toast = nil }
    }

    // MARK: - Demo

    func addDemoItems() {
        let calendar = Calendar.current
        let presets = IngredientPresetService.shared.loadPresets()

        // Uses the preset's category, price and carbon data when available.
        func demo(_ name: String, _ category: FoodCategory, qty: Int,
                  boughtDaysAgo: Int, expiresIn: Int, price: Double) -> FoodItem {
            let preset = PresetMatcher.find(name, in: presets)
            return FoodItem(
                name: name,
                category: preset?.category ?? category,
                addedDate: calendar.date(byAdding: .day, value: -boughtDaysAgo, to: Date()) ?? Date(),
                expirationDate: calendar.date(byAdding: .day, value: expiresIn, to: Date()) ?? Date(),
                quantity: qty,
                estimatedValue: price,
                carbonFactor: preset?.carbonFactor ?? category.fallbackCarbonFactor
            )
        }

        foodItems = [
            demo("Carrot", .vegetable, qty: 3, boughtDaysAgo: 0, expiresIn: 10, price: 0.40),
            demo("Milk", .dairy, qty: 1, boughtDaysAgo: 5, expiresIn: 1, price: 4.00),
            demo("Eggs", .dairy, qty: 1, boughtDaysAgo: 10, expiresIn: 5, price: 5.00),
            demo("Tomato", .vegetable, qty: 2, boughtDaysAgo: 4, expiresIn: 2, price: 0.80),
            demo("Chicken Breast", .meat, qty: 1, boughtDaysAgo: 1, expiresIn: 0, price: 7.00),
            demo("Banana", .fruit, qty: 4, boughtDaysAgo: 3, expiresIn: 3, price: 0.30)
        ]
    }

    // MARK: - Saving

    private func saveItems() {
        guard let data = try? JSONEncoder().encode(foodItems) else { return }
        UserDefaults.standard.set(data, forKey: foodItemsKey)
    }

    private func saveHistory() {
        guard let data = try? JSONEncoder().encode(history) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    private func loadData() {
        if let data = UserDefaults.standard.data(forKey: foodItemsKey),
           let savedItems = try? JSONDecoder().decode([FoodItem].self, from: data) {
            foodItems = savedItems
        }

        if let data = UserDefaults.standard.data(forKey: historyKey),
           let savedHistory = try? JSONDecoder().decode([FoodItem].self, from: data) {
            history = savedHistory
        }
    }
}
