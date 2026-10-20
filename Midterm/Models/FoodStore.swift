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
        undoable("Deleted \(item.name)") {
            removeFromFridge(item)
        }
    }

    private func removeFromFridge(_ item: FoodItem) {
        foodItems.removeAll { $0.id == item.id }
        ExpirationNotificationService.shared.cancel(for: item)
    }

    // MARK: - Used / Wasted

    func markAsUsed(_ item: FoodItem) {
        undoable("\(item.name) marked as used") {
            finish(item, as: .used)
        }
    }

    func markAsWasted(_ item: FoodItem) {
        undoable("\(item.name) counted as wasted") {
            finish(item, as: .wasted)
        }
    }

    /// Used by "I Cooked This" on a recipe.
    func markAsUsed(_ items: [FoodItem]) {
        guard !items.isEmpty else { return }
        undoable("Cooked! Used \(items.map(\.name).joined(separator: ", "))") {
            items.forEach { finish($0, as: .used) }
        }
    }

    private func finish(_ item: FoodItem, as status: FoodStatus) {
        var completedItem = item
        completedItem.status = status
        completedItem.finishedDate = Date()
        history.append(completedItem)
        removeFromFridge(item)
    }

    // MARK: - History

    /// Puts an item back in the fridge.
    func restoreFromHistory(_ item: FoodItem) {
        undoable("\(item.name) moved back to the fridge") {
            history.removeAll { $0.id == item.id }
            var restored = item
            restored.status = .active
            restored.finishedDate = nil
            addItem(restored)
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

    private func undoable(_ message: String, _ change: () -> Void) {
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
