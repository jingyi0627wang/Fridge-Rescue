import SwiftUI

// MARK: - Food Details
// One Freshling up close: its HP, a storage tip from the mascot, its info,
// and the actions: eat it (earn XP) / toss it (all or some), recipes, edit, delete.
// Eating or tossing always returns to the fridge.

struct FoodDetailView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var router: AppRouter
    @Environment(\.dismiss) private var dismiss
    @State private var showEdit = false
    /// How many to mark as used / thrown away (only shown when quantity > 1).
    @State private var actionCount = 1

    private let original: FoodItem

    init(item: FoodItem) {
        original = item
    }

    /// Always shows the latest version from the store (so edits appear right away).
    private var item: FoodItem {
        foodStore.foodItems.first { $0.id == original.id } ?? original
    }

    private var storageTip: String? {
        IngredientPresetService.shared.storageTip(for: item.name)
    }

    /// actionCount, kept within 1…quantity (quantity can change after an action).
    private var count: Int { min(max(actionCount, 1), item.quantity) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                heroCard

                if let storageTip {
                    MascotSays(verbatim: storageTip)
                        .padding(.vertical, 4)
                }

                actionsCard
                infoCard

                Button {
                    router.openRecipes(for: item)
                } label: {
                    Label("Find Recipes", systemImage: "fork.knife")
                }
                .buttonStyle(.chunky(.orange))

                Button("Delete Item", role: .destructive) {
                    // No pop-up: deletes right away, with Undo at the bottom.
                    foodStore.deleteItem(item)
                    dismiss()
                }
                .font(.game(15, .semibold))
                .foregroundStyle(Game.brownSoft)
                .padding(.top, 4)
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 30)
        }
        .gameBackground()
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showEdit = true }
            }
        }
        .tint(Game.greenDark)
        .sheet(isPresented: $showEdit) {
            EditFoodView(item: item)
                .environmentObject(foodStore)
        }
    }

    // MARK: - Hero

    private var heroCard: some View {
        VStack(spacing: 10) {
            FreshlingAvatar(item: item, size: 110)
                .padding(.top, 6)

            Text(item.name)
                .font(.game(28, .bold))
                .foregroundStyle(Game.brown)
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                Text(item.category.displayName)
                Text(verbatim: "·")
                Text("Qty \(item.quantity)")
            }
            .font(.game(15, .medium))
            .foregroundStyle(Game.brownSoft)

            VStack(spacing: 8) {
                HStack {
                    Text("HP \(item.hpPoints)/\(FoodItem.fullHPDays)")
                        .font(.game(15, .bold))
                        .foregroundStyle(Game.brown)
                    Spacer()
                    Text(item.freshnessLevel.displayName)
                        .font(.game(13, .bold))
                        .foregroundStyle(item.freshnessLevel == .fresh ? Game.greenInk : .white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(item.freshnessLevel.hpColor))
                }
                HPBar(item: item, segmentWidth: nil, height: 12, showsLabel: false)
                Text(item.daysLeftText)
                    .font(.game(14, .medium))
                    .foregroundStyle(item.freshnessLevel.tint)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .gameCard(padding: 18)
    }

    // MARK: - Eat it / toss it
    // Moves the item into history so the Impact page can count it.

    private var actionsCard: some View {
        VStack(spacing: 12) {
            if item.quantity > 1 {
                countPicker
            }

            Button {
                finish(.used)
            } label: {
                usedLabel
            }
            .buttonStyle(.chunky(.green))

            Button {
                finish(.wasted)
            } label: {
                wastedLabel
            }
            .buttonStyle(.chunky(.red, small: true))
        }
        .gameCard()
    }

    @ViewBuilder
    private var usedLabel: some View {
        let xp = FoodStore.questXP(for: item) * count
        if item.quantity > 1 {
            Text("Ate \(count) · +\(xp) XP")
        } else {
            Text("I ate it! +\(xp) XP")
        }
    }

    @ViewBuilder
    private var wastedLabel: some View {
        if item.quantity > 1 {
            Text("Tossed \(count)")
        } else {
            Text("Tossed it")
        }
    }

    /// "How many?   −  1 of 3  +   All"
    private var countPicker: some View {
        HStack(spacing: 10) {
            Text("How many?")
                .font(.game(15, .semibold))
                .foregroundStyle(Game.brown)

            Spacer(minLength: 4)

            roundButton("minus", enabled: count > 1) { actionCount = count - 1 }

            Text("\(count) of \(item.quantity)")
                .font(.game(16, .bold))
                .foregroundStyle(Game.greenInk)
                .monospacedDigit()
                .frame(minWidth: 54)

            roundButton("plus", enabled: count < item.quantity) { actionCount = count + 1 }

            Button("All") { actionCount = item.quantity }
                .font(.game(14, .bold))
                .foregroundStyle(count == item.quantity ? Game.greenInk : Game.brownSoft)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .background(Capsule().fill(count == item.quantity ? Game.green : Game.track))
                .buttonStyle(.plain)
        }
    }

    private func roundButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .heavy))
                .foregroundStyle(enabled ? Game.greenInk : Game.gray)
                .frame(width: 32, height: 32)
                .background(Circle().fill(enabled ? Game.mint : Game.graySoft))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    /// Takes `count` out of the fridge, then goes back to the fridge.
    private func finish(_ status: FoodStatus) {
        if status == .used {
            foodStore.markAsUsed(item, quantity: count)
            FreshlingsHaptics.success()
        } else {
            foodStore.markAsWasted(item, quantity: count)
            FreshlingsHaptics.light()
        }

        actionCount = 1
        dismiss()
    }

    // MARK: - Info

    private var infoCard: some View {
        VStack(spacing: 0) {
            infoRow("Expires", item.expirationDate.formatted(date: .abbreviated, time: .omitted))
            DashedDivider()
            infoRow("Bought", item.addedDate.formatted(date: .abbreviated, time: .omitted))
            DashedDivider()
            infoRow("Price per unit", item.estimatedValue.formatted(.currency(code: "USD")))
            DashedDivider()
            infoRow("CO₂e per unit", String(format: "%.2f kg", item.carbonFactor))
        }
        .gameCard(padding: 0)
    }

    private func infoRow(_ title: LocalizedStringKey, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Game.brownSoft)
            Spacer()
            Text(value)
                .foregroundStyle(Game.brown)
        }
        .font(.game(15, .semibold))
        .padding(.horizontal, 16)
        .padding(.vertical, 13)
    }
}

#Preview {
    let store = FoodStore()
    store.addDemoItems()
    return NavigationStack {
        FoodDetailView(item: store.foodItems[0])
    }
    .environmentObject(store)
    .environmentObject(MyRecipeStore())
    .environmentObject(AppRouter())
}
