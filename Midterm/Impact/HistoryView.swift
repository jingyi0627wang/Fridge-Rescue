import SwiftUI

/// Past food: everything marked as used or wasted, newest first.
/// Swipe left to remove a record, swipe right to put it back in the fridge.
struct HistoryView: View {
    @EnvironmentObject var foodStore: FoodStore

    private enum Filter: String, CaseIterable {
        case all = "All", used = "Used", wasted = "Wasted"
    }

    @State private var filter: Filter = .all

    private enum Style {
        static let background = Color(red: 0.985, green: 0.992, blue: 0.970)
        static let darkGreen = Color(red: 0.22, green: 0.49, blue: 0.19)
        static let softGreen = Color(red: 0.931, green: 0.976, blue: 0.869)
        static let brown = Color(red: 0.34, green: 0.27, blue: 0.22)
        static let secondary = Color(red: 0.50, green: 0.48, blue: 0.41)
        static let orange = Color(red: 0.86, green: 0.36, blue: 0.19)
    }

    private var records: [FoodItem] {
        foodStore.history
            .filter { item in
                switch filter {
                case .all: return true
                case .used: return item.status == .used
                case .wasted: return item.status == .wasted
                }
            }
            .sorted { $0.finishedOn > $1.finishedOn }
    }

    var body: some View {
        List {
            Section {
                Picker("Show", selection: $filter) {
                    ForEach(Filter.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            if records.isEmpty {
                Text("Nothing here yet.")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Style.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(records) { item in
                        row(item)
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    foodStore.removeFromHistory(item)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                            .swipeActions(edge: .leading) {
                                Button {
                                    foodStore.restoreFromHistory(item)
                                } label: {
                                    Label("Back to Fridge", systemImage: "arrow.uturn.backward")
                                }
                                .tint(Style.darkGreen)
                            }
                    }
                } footer: {
                    Text("Swipe right to move an item back to the fridge.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Style.background.ignoresSafeArea())
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ item: FoodItem) -> some View {
        let used = item.status == .used

        return HStack(spacing: 12) {
            FoodIconView(item: item, size: 30)
                .frame(width: 44, height: 44)
                .background(Style.softGreen, in: RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Style.brown)
                Text("Qty \(item.quantity) · \(item.finishedOn.formatted(date: .abbreviated, time: .omitted))")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Style.secondary)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 3) {
                Text(used ? "Used" : "Wasted")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(used ? Style.darkGreen : Style.orange)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background((used ? Style.darkGreen : Style.orange).opacity(0.12), in: Capsule())
                Text((item.estimatedValue * Double(item.quantity)).formatted(.currency(code: "USD")))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Style.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let store = FoodStore()
    store.history = []
    store.addDemoItems()
    store.markAsUsed(store.foodItems[0])
    store.markAsWasted(store.foodItems[0])

    return NavigationStack {
        HistoryView()
    }
    .environmentObject(store)
}
