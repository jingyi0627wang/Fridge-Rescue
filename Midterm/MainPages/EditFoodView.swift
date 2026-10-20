// ------------------------------------------------------------
// Contributions by Gladys Yu: CO2 value updates when a food is renamed
// ------------------------------------------------------------

import SwiftUI

/// Edit a food item that is already in the fridge.
/// Opened from the pencil button on Food Details.
struct EditFoodView: View {
    @EnvironmentObject var foodStore: FoodStore
    @Environment(\.dismiss) private var dismiss

    private let original: FoodItem

    @State private var name: String
    @State private var category: FoodCategory
    @State private var quantity: Int
    @State private var priceText: String
    @State private var addedDate: Date
    @State private var expirationDate: Date

    init(item: FoodItem) {
        original = item
        _name = State(initialValue: item.name)
        _category = State(initialValue: item.category)
        _quantity = State(initialValue: item.quantity)
        _priceText = State(initialValue: String(format: "%.2f", item.estimatedValue))
        _addedDate = State(initialValue: item.addedDate)
        _expirationDate = State(initialValue: item.expirationDate)
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Food name", text: $name)
                        .textInputAutocapitalization(.words)

                    Picker("Category", selection: $category) {
                        ForEach(FoodCategory.allCases, id: \.self) { category in
                            Label(category.displayName, systemImage: category.symbolName).tag(category)
                        }
                    }
                }

                Section("Amount & Price") {
                    Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)

                    HStack {
                        Text("Price per unit")
                        Spacer()
                        Text(Locale.current.currencySymbol ?? "$").foregroundStyle(.secondary)
                        TextField("0.00", text: $priceText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(maxWidth: 100)
                    }
                }

                Section("Dates") {
                    DatePicker("Bought on", selection: $addedDate, in: ...Date(), displayedComponents: .date)
                    DatePicker("Expires on",
                               selection: $expirationDate,
                               in: Calendar.current.startOfDay(for: addedDate)...,
                               displayedComponents: .date)
                }
            }
            .font(.game(16, .medium))
            .foregroundStyle(Game.brown)
            .gameBackground()
            .tint(Game.greenDark)
            .navigationTitle("Edit Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private func save() {
        var updated = original
        updated.name = trimmedName
        updated.category = category
        updated.quantity = quantity
        updated.estimatedValue = Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? original.estimatedValue
        updated.addedDate = addedDate
        updated.expirationDate = Calendar.current.startOfDay(for: max(expirationDate, addedDate))

        // New name or category → look up the carbon value again
        // (e.g. "Other" renamed to "Chicken" should count as meat).
        if updated.name.lowercased() != original.name.lowercased() || updated.category != original.category {
            let presets = IngredientPresetService.shared.loadPresets()
            let preset = PresetMatcher.find(updated.name, in: presets)
            // Same rule as Add Food: known food → its own value, otherwise the category's.
            updated.carbonFactor = preset?.carbonFactor ?? updated.category.fallbackCarbonFactor
        }
        foodStore.updateItem(updated)
        dismiss()
    }
}

#Preview {
    let store = FoodStore()
    store.addDemoItems()
    return EditFoodView(item: store.foodItems[0])
        .environmentObject(store)
}
