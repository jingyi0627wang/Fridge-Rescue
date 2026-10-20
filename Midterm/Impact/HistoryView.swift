import SwiftUI

/// Past food: everything marked as used or wasted, newest first.
/// Swipe left to remove a record, swipe right to put it back in the fridge.
struct HistoryView: View {
    @EnvironmentObject var foodStore: FoodStore

    private enum Filter: String, CaseIterable {
        case all = "All", used = "Used", wasted = "Wasted"
    }

    @State private var filter: Filter = .all


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
                ContentUnavailableView(
                    "Nothing Here Yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Food you mark as used or thrown away shows up here.")
                )
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
                                .tint(.brand)
                            }
                    }
                } footer: {
                    Text("Swipe right to move an item back to the fridge.")
                }
            }
        }
        .listStyle(.insetGrouped)
        .font(.game(16, .medium))
        .foregroundStyle(Game.brown)
        .gameBackground()
        .tint(Game.greenDark)
        .navigationTitle("Food History")
        .toolbar(.hidden, for: .tabBar)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ item: FoodItem) -> some View {
        let used = item.status == .used

        return HStack(spacing: 12) {
            FreshlingAvatar(category: item.category, name: item.name, size: 40, showsStatus: false)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                Text("Qty \(item.quantity) · \(item.finishedOn.formatted(date: .abbreviated, time: .omitted))")
                    .font(.game(14, .medium))
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            VStack(alignment: .trailing, spacing: 2) {
                if used {
                    Text("Rescued")
                        .font(.game(14, .semibold))
                        .foregroundStyle(Color.brand)
                } else {
                    Text("Lost")
                        .font(.game(14, .semibold))
                        .foregroundStyle(Game.redDark)
                }
                Text((item.estimatedValue * Double(item.quantity)).formatted(.currency(code: "USD")))
                    .font(.game(13, .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 2)
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
