import Foundation
import SwiftUI
import Combine

final class FoodStore: ObservableObject {
    @Published var foodItems: [FoodItem] = [] {
        didSet { saveItems() }
    }

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
        foodItems.removeAll { $0.id == item.id }
        ExpirationNotificationService.shared.cancel(for: item)
    }

    // MARK: - Used / Wasted

    func markAsUsed(_ item: FoodItem) {
        finish(item, as: .used)
    }

    func markAsWasted(_ item: FoodItem) {
        finish(item, as: .wasted)
    }

    /// Used by "I Cooked This" on a recipe.
    func markAsUsed(_ items: [FoodItem]) {
        items.forEach { finish($0, as: .used) }
    }

    private func finish(_ item: FoodItem, as status: FoodStatus) {
        var completedItem = item
        completedItem.status = status
        completedItem.finishedDate = Date()
        history.append(completedItem)
        deleteItem(item)
    }

    // MARK: - History

    /// Puts an item back in the fridge (undo a mistake).
    func restoreFromHistory(_ item: FoodItem) {
        history.removeAll { $0.id == item.id }
        var restored = item
        restored.status = .active
        restored.finishedDate = nil
        addItem(restored)
    }

    func removeFromHistory(_ item: FoodItem) {
        history.removeAll { $0.id == item.id }
    }

    // MARK: - Demo

    func addDemoItems() {
        let calendar = Calendar.current
        func daysFromNow(_ days: Int) -> Date {
            calendar.date(byAdding: .day, value: days, to: Date()) ?? Date()
        }

        foodItems = [
            FoodItem(name: "Carrot", category: .vegetable,
                     addedDate: Date(), expirationDate: daysFromNow(7),
                     quantity: 3, estimatedValue: 1.50, carbonFactor: 0.30),
            FoodItem(name: "Milk", category: .dairy,
                     addedDate: daysFromNow(-5), expirationDate: daysFromNow(1),
                     quantity: 1, estimatedValue: 4.00, carbonFactor: 1.20),
            FoodItem(name: "Eggs", category: .dairy,
                     addedDate: daysFromNow(-10), expirationDate: daysFromNow(4),
                     quantity: 6, estimatedValue: 0.50, carbonFactor: 0.40),
            FoodItem(name: "Tomato", category: .vegetable,
                     addedDate: daysFromNow(-4), expirationDate: daysFromNow(2),
                     quantity: 2, estimatedValue: 0.80, carbonFactor: 0.30),
            FoodItem(name: "Chicken Breast", category: .meat,
                     addedDate: daysFromNow(-1), expirationDate: daysFromNow(2),
                     quantity: 1, estimatedValue: 7.00, carbonFactor: 6.00),
            FoodItem(name: "Banana", category: .fruit,
                     addedDate: daysFromNow(-3), expirationDate: daysFromNow(3),
                     quantity: 4, estimatedValue: 0.30, carbonFactor: 0.20)
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
