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

    func addItem(_ item: FoodItem) {
        foodItems.append(item)
        // Remind the user 3 days before the item expires.
        Task {
            await ExpirationNotificationService.shared
                .requestAuthorizationAndSchedule(items: [item])
        }
    }

    func deleteItem(_ item: FoodItem) {
        foodItems.removeAll { $0.id == item.id }
        ExpirationNotificationService.shared.cancel(for: item)
    }

    func markAsUsed(_ item: FoodItem) {
        var completedItem = item
        completedItem.status = .used
        history.append(completedItem)
        deleteItem(item)
    }

    func markAsWasted(_ item: FoodItem) {
        var completedItem = item
        completedItem.status = .wasted
        history.append(completedItem)
        deleteItem(item)
    }

    func addDemoItems() {
        let calendar = Calendar.current
        let carrot = FoodItem(
            name: "Carrot",
            category: .vegetable,
            addedDate: Date(),
            expirationDate: calendar.date(byAdding: .day, value: 7, to: Date()) ?? Date(),
            quantity: 3,
            estimatedValue: 1.50,
            carbonFactor: 0.30
        )

        let milk = FoodItem(
            name: "Milk",
            category: .dairy,
            addedDate: calendar.date(byAdding: .day, value: -5, to: Date()) ?? Date(),
            expirationDate: calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
            quantity: 1,
            estimatedValue: 4.00,
            carbonFactor: 1.20
        )

        foodItems = [carrot, milk]
    }

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
