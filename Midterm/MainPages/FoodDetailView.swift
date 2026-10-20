import SwiftUI

// MARK: - Food Details · Freshlings visual style
// This palette is local to this file so teammates' pages are unchanged.
private enum FreshlingsDetailStyle {
    static let background = Color(red: 0.985, green: 0.992, blue: 0.970)
    static let white = Color.white
    static let softGreen = Color(red: 0.931, green: 0.976, blue: 0.869)
    static let softYellow = Color(red: 1.000, green: 0.956, blue: 0.822)
    static let green = Color(red: 0.53, green: 0.89, blue: 0.36)
    static let darkGreen = Color(red: 0.22, green: 0.49, blue: 0.19)
    static let brown = Color(red: 0.34, green: 0.27, blue: 0.22)
    static let secondary = Color(red: 0.50, green: 0.48, blue: 0.41)
    static let orange = Color(red: 0.96, green: 0.56, blue: 0.29)
    static let gold = Color(red: 0.77, green: 0.54, blue: 0.09)
    static let red = Color(red: 0.86, green: 0.36, blue: 0.19)
    static let track = Color(red: 0.89, green: 0.92, blue: 0.85)
}

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

    private var statusColor: Color {
        switch item.freshnessLevel {
        case .fresh: return FreshlingsDetailStyle.darkGreen
        case .useSoon: return FreshlingsDetailStyle.gold
        case .urgent: return FreshlingsDetailStyle.red
        case .expired: return FreshlingsDetailStyle.secondary
        }
    }

    private var progress: CGFloat {
        CGFloat(max(0, min(item.hpPercentage / 100.0, 1)))
    }

    private var daysText: String {
        item.daysLeftText
    }

    var body: some View {
        ZStack {
            FreshlingsDetailStyle.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    heroSection
                    freshnessSection
                    if let storageTip {
                        tipSection(storageTip)
                    }
                    informationSection
                    recipeButton
                    finishButtons
                    deleteButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 36)
            }
        }
        // Keep the native navigation bar so iOS can handle edge-swipe Back.
        .navigationTitle("Food Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.visible, for: .navigationBar)
        .toolbarBackground(FreshlingsDetailStyle.background, for: .navigationBar)
        .tint(FreshlingsDetailStyle.darkGreen)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Food Details")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(FreshlingsDetailStyle.brown)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEdit = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(FreshlingsDetailStyle.darkGreen)
                }
                .accessibilityLabel("Edit")
            }
        }
        .sheet(isPresented: $showEdit) {
            EditFoodView(item: item)
                .environmentObject(foodStore)
        }
    }

    // MARK: - Storage tip

    private func tipSection(_ tip: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "lightbulb.fill")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(FreshlingsDetailStyle.gold)
                .frame(width: 40, height: 40)
                .background(FreshlingsDetailStyle.white, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Storage Tip")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(FreshlingsDetailStyle.brown)
                Text(tip)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(FreshlingsDetailStyle.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(FreshlingsDetailStyle.softYellow, in: RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Delete

    private var deleteButton: some View {
        Button(role: .destructive) {
            // No pop-up: deletes right away, with Undo at the bottom.
            foodStore.deleteItem(item)
            dismiss()
        } label: {
            Text("Delete Item")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(FreshlingsDetailStyle.secondary)
                .underline()
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    // MARK: - Used / Wasted
    // Moves the item into history so the Impact page can count it.

    /// actionCount, kept within 1…quantity (quantity can change after an action).
    private var count: Int { min(max(actionCount, 1), item.quantity) }

    private var finishButtons: some View {
        VStack(spacing: 12) {
            if item.quantity > 1 {
                countPicker
            }

            HStack(spacing: 12) {
                Button {
                    finish(.used)
                } label: {
                    Label(item.quantity > 1 ? "Used \(count)" : "I Used It",
                          systemImage: "checkmark.circle.fill")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(FreshlingsDetailStyle.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(FreshlingsDetailStyle.darkGreen, in: RoundedRectangle(cornerRadius: 20))
                }
                .buttonStyle(.plain)

                Button {
                    finish(.wasted)
                } label: {
                    Label(item.quantity > 1 ? "Threw Away \(count)" : "Threw Away",
                          systemImage: "trash")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(FreshlingsDetailStyle.red)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(FreshlingsDetailStyle.white, in: RoundedRectangle(cornerRadius: 20))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(FreshlingsDetailStyle.red.opacity(0.35), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    /// "How many?  −  1 of 3  +   All"
    private var countPicker: some View {
        HStack(spacing: 12) {
            Text("How many?")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(FreshlingsDetailStyle.brown)

            Spacer(minLength: 4)

            countButton("minus", enabled: count > 1) { actionCount = count - 1 }

            Text("\(count) of \(item.quantity)")
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundStyle(FreshlingsDetailStyle.darkGreen)
                .monospacedDigit()
                .frame(minWidth: 56)

            countButton("plus", enabled: count < item.quantity) { actionCount = count + 1 }

            Button("All") { actionCount = item.quantity }
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(count == item.quantity ? FreshlingsDetailStyle.white : FreshlingsDetailStyle.darkGreen)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(count == item.quantity ? FreshlingsDetailStyle.darkGreen : FreshlingsDetailStyle.softGreen,
                            in: Capsule())
                .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(FreshlingsDetailStyle.white, in: RoundedRectangle(cornerRadius: 20))
    }

    private func countButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(enabled ? FreshlingsDetailStyle.darkGreen : FreshlingsDetailStyle.secondary.opacity(0.4))
                .frame(width: 32, height: 32)
                .background(FreshlingsDetailStyle.softGreen, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    /// Takes `count` out of the fridge. Goes back only if none are left.
    private func finish(_ status: FoodStatus) {
        let usesAll = count >= item.quantity

            if status == .used {
                foodStore.markAsUsed(item, quantity: count)
                FreshlingsHaptics.success()
            } else {
                foodStore.markAsWasted(item, quantity: count)
                FreshlingsHaptics.light()
            }

            actionCount = 1

            if usesAll {
                dismiss()
            }
        }

    // MARK: - Food hero

    private var heroSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(FreshlingsDetailStyle.white.opacity(0.72))
                    .frame(width: 142, height: 142)

                Circle()
                    .stroke(FreshlingsDetailStyle.darkGreen.opacity(0.10), lineWidth: 2)
                    .frame(width: 142, height: 142)

                FoodIconView(item: item, size: 92)
            }

            Text(item.name)
                .font(.system(size: 32, weight: .heavy, design: .rounded))
                .foregroundStyle(FreshlingsDetailStyle.brown)
                .multilineTextAlignment(.center)

            Text(item.category.rawValue)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(FreshlingsDetailStyle.secondary)

            Text(item.freshnessLevel.title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(statusColor.opacity(0.12), in: Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(FreshlingsDetailStyle.softGreen, in: RoundedRectangle(cornerRadius: 28))
    }

    // MARK: - Freshness

    private var freshnessSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Label("Freshness HP", systemImage: "heart.fill")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundStyle(FreshlingsDetailStyle.brown)

                Spacer()

                Text("\(Int(item.hpPercentage))%")
                    .font(.system(size: 27, weight: .heavy, design: .rounded))
                    .foregroundStyle(statusColor)
                    .monospacedDigit()
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(FreshlingsDetailStyle.track)
                    Capsule()
                        .fill(statusColor)
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 11)
            .accessibilityLabel("Freshness")
            .accessibilityValue("\(Int(item.hpPercentage)) percent")

            HStack(spacing: 8) {
                Image(systemName: "clock.fill")
                    .foregroundStyle(statusColor)
                Text(daysText)
                    .foregroundStyle(FreshlingsDetailStyle.brown)
                Spacer(minLength: 0)
                Text("Use food while it's fresh")
                    .foregroundStyle(FreshlingsDetailStyle.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .font(.system(size: 12, weight: .medium, design: .rounded))
        }
        .padding(20)
        .background(FreshlingsDetailStyle.white, in: RoundedRectangle(cornerRadius: 24))
    }

    // MARK: - Food information

    private var informationSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Food Information")
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .foregroundStyle(FreshlingsDetailStyle.brown)
                .padding(.bottom, 10)

            informationRow("Quantity", "\(item.quantity)")
            Divider()
            informationRow("Added", formattedDate(item.addedDate))
            Divider()
            informationRow("Expiration", formattedDate(item.expirationDate))
            Divider()
            informationRow("Estimated Value", String(format: "$%.2f", item.estimatedValue))
            Divider()
            informationRow("Carbon Factor", String(format: "%.2f", item.carbonFactor))
        }
        .padding(20)
        .background(FreshlingsDetailStyle.white, in: RoundedRectangle(cornerRadius: 24))
    }

    private func informationRow(_ title: String, _ value: String) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .foregroundStyle(FreshlingsDetailStyle.secondary)
            Spacer(minLength: 8)
            Text(value)
                .fontWeight(.bold)
                .foregroundStyle(FreshlingsDetailStyle.brown)
                .multilineTextAlignment(.trailing)
        }
        .font(.system(size: 14, design: .rounded))
        .padding(.vertical, 11)
    }

    // MARK: - Recipes

    private var recipeButton: some View {
        Button {
            router.openRecipes(for: item)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "fork.knife")
                    .font(.system(size: 21, weight: .semibold))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Find Recipes")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Text("Cook with \(item.name) before it expires")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .lineLimit(2)
                }
                Spacer(minLength: 4)
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(FreshlingsDetailStyle.darkGreen)
            .padding(.horizontal, 20)
            .padding(.vertical, 17)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FreshlingsDetailStyle.green, in: RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        return formatter.string(from: date)
    }
}

#Preview {
    let store = FoodStore()
    store.addDemoItems()
    return NavigationStack {
        FoodDetailView(item: store.foodItems[0])
    }
    .environmentObject(store)
    .environmentObject(AppRouter())
}

