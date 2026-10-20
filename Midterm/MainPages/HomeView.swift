import SwiftUI

// MARK: - Fridge tab ("My Freshlings")
// Every food is a Freshling. Its HP bar goes down as it gets closer to expiring.
// Top: level and money saved. Search, then filter by category.
// Tap a Freshling for details; press and hold for quick actions.

struct HomeView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var router: AppRouter

    @State private var showSettings = false
    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory? = nil   // nil = All

    private var activeItems: [FoodItem] {
        foodStore.activeItemsByUrgency
    }

    /// Food list after search + category filter.
    private var filteredItems: [FoodItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return activeItems.filter { item in
            (selectedCategory == nil || item.category == selectedCategory) &&
            (query.isEmpty || item.name.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        let items = filteredItems
        let needRescue = activeItems.filter { RecipeData.needsAttention($0) }.count

        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .center) {
                        Text("Fridge")
                            .font(.game(32, .bold, relativeTo: .largeTitle))
                            .foregroundStyle(Game.brown)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        Spacer()
                        hud
                    }
                    subtitle(total: activeItems.count, needRescue: needRescue)
                        .font(.ui(15))
                        .foregroundStyle(Game.brownSoft)
                }
                .padding(.top, 12)

                if activeItems.isEmpty {
                    emptyState
                } else {
                    GameSearchField(text: $searchText)
                        .padding(.top, 4)
                    categoryChips

                    if items.isEmpty {
                        noMatchState
                    }

                    if !items.isEmpty {
                        fridge(items)
                            .padding(.top, 6)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .gameBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) {
            NavigationStack {
                SettingsView(foodStore: foodStore)
            }
        }
    }

    @ViewBuilder
    private func subtitle(total: Int, needRescue: Int) -> some View {
        if total == 0 {
            Text("Nothing in here yet")
        } else if needRescue == 0 {
            Text("\(total) items, all fresh")
        } else {
            Text("\(total) items, \(needRescue) to use soon")
        }
    }

    // MARK: - HUD (level, money saved, settings)

    private var hud: some View {
        let info = foodStore.levelInfo

        return HStack(spacing: 6) {
            Button {
                router.selectedTab = .today
            } label: {
                HStack(spacing: 5) {
                    ZStack {
                        Circle().stroke(Game.track, lineWidth: 3)
                        Circle()
                            .trim(from: 0, to: info.progress)
                            .stroke(Game.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 16, height: 16)
                    Text("Lv \(info.level)")
                        .font(.ui(13, .semibold))
                        .foregroundStyle(Game.brown)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 6)
                .background(Capsule().fill(.white).shadow(color: Game.brown.opacity(0.07), radius: 2, y: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Level \(info.level)")

            // Money saved (price of food eaten instead of thrown away)
            HStack(spacing: 4) {
                Image("IconSavings")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                Text("\(foodStore.moneySaved.formatted(.currency(code: "USD").precision(.fractionLength(0)))) saved")
                    .font(.ui(13, .semibold))
                    .foregroundStyle(Game.brown)
                    .monospacedDigit()
            }
            .padding(.leading, 5)
            .padding(.trailing, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(.white).shadow(color: Game.brown.opacity(0.07), radius: 2, y: 1))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Money saved")
            .accessibilityValue(foodStore.moneySaved.formatted(.currency(code: "USD")))

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(Game.brownSoft)
                    .frame(width: 32, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    // MARK: - Category chips

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                GameChip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(FoodCategory.allCases, id: \.self) { category in
                    GameChip(title: category.displayName, isSelected: selectedCategory == category) {
                        selectedCategory = (selectedCategory == category) ? nil : category
                    }
                }
            }
            .padding(.vertical, 2)
        }
    }

    // MARK: - Groups

    private enum FreshnessGroup: CaseIterable {
        case urgent, expired, useSoon, fresh

        func contains(_ item: FoodItem) -> Bool {
            switch self {
            case .urgent: return item.freshnessLevel == .urgent
            case .expired: return item.freshnessLevel == .expired
            case .useSoon: return item.freshnessLevel == .useSoon
            case .fresh: return item.freshnessLevel == .fresh
            }
        }

        var title: LocalizedStringKey {
            switch self {
            case .urgent: return "Use first"
            case .expired: return "Past their date"
            case .useSoon: return "This week"
            case .fresh: return "Fresh"
            }
        }

        var color: Color {
            switch self {
            case .urgent: return Game.red
            case .expired: return Game.gray
            case .useSoon: return Game.yellow
            case .fresh: return Game.green
            }
        }
    }

    // MARK: - The fridge
    // One shelf per freshness group (most urgent at the top), 4 Freshlings per row.

    private let shelfColumns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 4)

    private func fridge(_ items: [FoodItem]) -> some View {
        FridgeBody {
            ForEach(FreshnessGroup.allCases, id: \.self) { group in
                let groupItems = items.filter { group.contains($0) }
                if !groupItems.isEmpty {
                    ShelfTag(title: group.title, color: group.color, count: groupItems.count)

                    LazyVGrid(columns: shelfColumns, spacing: 12) {
                        ForEach(groupItems) { item in
                            NavigationLink {
                                FoodDetailView(item: item)
                            } label: {
                                FridgeTile(item: item)
                            }
                            .buttonStyle(.plain)
                            .foodQuickActions(item, store: foodStore)
                        }
                    }
                    .padding(.top, 10)

                    GlassShelf()
                        .padding(.bottom, 2)
                }
            }
        }
    }

    // MARK: - Empty states

    private var noMatchState: some View {
        VStack(spacing: 6) {
            FreshlingMascot(size: 56, color: Game.gray)
            Text("Nothing matches")
                .font(.game(17, .semibold))
                .foregroundStyle(Game.brown)
            Text("Try another name or category.")
                .font(.game(14, .medium))
                .foregroundStyle(Game.brownSoft)
        }
        .frame(maxWidth: .infinity)
        .gameCard(padding: 22)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            FreshlingMascot(size: 110)
                .padding(.top, 6)

            Text("Your fridge is empty")
                .font(.game(22, .bold))
                .foregroundStyle(Game.brown)

            Text("Add what you bought and Freshlings will tell you what to eat first.")
                .font(.game(15, .medium))
                .foregroundStyle(Game.brownSoft)
                .multilineTextAlignment(.center)

            Button("Add Food") {
                router.selectedTab = .add
            }
            .buttonStyle(.chunky(.green))
            .padding(.top, 6)

            // For demos / testing: fills the fridge with sample food.
            Button("Load Demo Food") {
                foodStore.addDemoItems()
            }
            .buttonStyle(.chunky(.white, small: true))
        }
        .frame(maxWidth: .infinity)
        .gameCard(padding: 20)
        .padding(.top, 8)
    }
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(FoodStore())
    .environmentObject(MyRecipeStore())
    .environmentObject(AppRouter())
}
