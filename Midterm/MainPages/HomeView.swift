import SwiftUI

// MARK: - Home-only Freshlings styling
// Kept local to avoid changing styles used by teammates' views.
private enum FreshlingsHomeStyle {
    static let background = Color(red: 0.985, green: 0.992, blue: 0.970)
    static let white = Color.white
    static let softGreen = Color(red: 0.931, green: 0.976, blue: 0.869)
    static let softYellow = Color(red: 1.000, green: 0.956, blue: 0.822)
    static let green = Color(red: 0.53, green: 0.89, blue: 0.36)
    static let darkGreen = Color(red: 0.22, green: 0.49, blue: 0.19)
    static let brown = Color(red: 0.34, green: 0.27, blue: 0.22)
    static let secondary = Color(red: 0.50, green: 0.48, blue: 0.41)
    static let orange = Color(red: 0.96, green: 0.56, blue: 0.29)
    static let gold = Color(red: 0.91, green: 0.70, blue: 0.25)
    static let track = Color(red: 0.89, green: 0.92, blue: 0.85)
}

struct HomeView: View {
    @EnvironmentObject var foodStore: FoodStore
    @EnvironmentObject var router: AppRouter

    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory? = nil   // nil = All

    /// Collapsed / expanded state per freshness group (title → expanded).
    /// With lots of food, "Fresh" starts collapsed so urgent food is near the top.
    @State private var groupExpanded: [String: Bool] = [:]

    private var activeItems: [FoodItem] {
        foodStore.activeItemsByUrgency
    }

    private var attentionItems: [FoodItem] {
        activeItems.filter {
            $0.freshnessLevel == .urgent || $0.freshnessLevel == .useSoon
        }
    }

    private var rescueItem: FoodItem? { attentionItems.first }

    /// Food list after search + category filter.
    private var filteredItems: [FoodItem] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return activeItems.filter { item in
            (selectedCategory == nil || item.category == selectedCategory) &&
            (query.isEmpty || item.name.localizedCaseInsensitiveContains(query))
        }
    }

    var body: some View {
        ZStack {
            FreshlingsHomeStyle.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    overviewSection

                    if let rescueItem {
                        rescueSection(rescueItem)
                    }

                    foodSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        // MainTabView already embeds HomeView in a NavigationStack.
        .toolbar(.hidden, for: .navigationBar)
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("MY FRESHLINGS")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(FreshlingsHomeStyle.darkGreen)

                Text("My Fridge")
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(FreshlingsHomeStyle.brown)

                Text("Keep your food fresh and happy!")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(FreshlingsHomeStyle.secondary)
            }

            Spacer(minLength: 4)

            // Test data menu (for demos and testing with lots of food).
            Menu {
                Button {
                    foodStore.addDemoItems()
                } label: {
                    Label("Load Demo Food (6)", systemImage: "carrot")
                }
                Button {
                    foodStore.loadStressTestData()
                } label: {
                    Label("Load Lots of Food (60)", systemImage: "square.stack.3d.up.fill")
                }
                Divider()
                Button(role: .destructive) {
                    foodStore.clearAllData()
                } label: {
                    Label("Clear Fridge & History", systemImage: "trash")
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(FreshlingsHomeStyle.softGreen)
                        .frame(width: 62, height: 62)

                    Text("🌱")
                        .font(.system(size: 34))
                }
            }
            .accessibilityLabel("Test data")
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Freshness Garden")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(FreshlingsHomeStyle.brown)

                    Text("\(activeItems.count) Freshlings")
                        .font(.system(size: 30, weight: .heavy, design: .rounded))
                        .foregroundStyle(FreshlingsHomeStyle.darkGreen)

                    Text(attentionItems.isEmpty
                         ? "Everything is looking fresh!"
                         : "\(attentionItems.count) \(attentionItems.count == 1 ? "food needs" : "foods need") attention")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundStyle(FreshlingsHomeStyle.secondary)
                }

                Spacer(minLength: 4)

                Text("🥦")
                    .font(.system(size: 63))
                    .accessibilityHidden(true)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FreshlingsHomeStyle.softGreen)
            .clipShape(RoundedRectangle(cornerRadius: 25))
        }
    }

    // MARK: - Priority item

    private func rescueSection(_ item: FoodItem) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionTitle("Use First", subtitle: "Needs your attention")

            VStack(alignment: .leading, spacing: 15) {
                HStack(alignment: .center, spacing: 13) {
                    foodSymbol(for: item, size: 64)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.name)
                            .font(.system(size: 21, weight: .bold, design: .rounded))
                            .foregroundStyle(FreshlingsHomeStyle.brown)

                        Text(priorityMessage(for: item))
                            .font(.system(size: 13, design: .rounded))
                            .foregroundStyle(FreshlingsHomeStyle.secondary)
                    }

                    Spacer(minLength: 0)

                    Text("\(Int(item.hpPercentage))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(statusColor(for: item))
                }

                freshnessLine(item)

                // Opens the Recipes tab with this food selected.
                Button {
                    router.openRecipes(for: item)
                } label: {
                    HStack {
                        Image(systemName: "fork.knife")
                        Text("Explore recipes")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                    }
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(FreshlingsHomeStyle.darkGreen)
                    .padding(.horizontal, 17)
                    .frame(height: 48)
                    .background(FreshlingsHomeStyle.green)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(17)
            .background(FreshlingsHomeStyle.softYellow)
            .clipShape(RoundedRectangle(cornerRadius: 23))
        }
    }

    // MARK: - Food list

    private var foodSection: some View {
        VStack(alignment: .leading, spacing: 13) {
            sectionTitle("My Food", subtitle: "Tap a group to fold it")

            if activeItems.isEmpty {
                emptyState
            } else {
                searchBar
                categoryChips

                if filteredItems.isEmpty {
                    noMatchState
                } else {
                    // Computed once, then split into freshness groups.
                    let items = filteredItems
                    let isSearching = !searchText.trimmingCharacters(in: .whitespaces).isEmpty
                    ForEach(FreshnessGroup.allCases, id: \.self) { group in
                        let groupItems = items.filter { group.contains($0) }
                        if !groupItems.isEmpty {
                            foodGroup(group, items: groupItems,
                                      totalCount: items.count, isSearching: isSearching)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Freshness groups

    private enum FreshnessGroup: String, CaseIterable {
        case expired = "Expired"
        case urgent = "Urgent"
        case useSoon = "Use Soon"
        case fresh = "Fresh"

        func contains(_ item: FoodItem) -> Bool {
            switch self {
            case .expired: return item.freshnessLevel == .expired
            case .urgent: return item.freshnessLevel == .urgent
            case .useSoon: return item.freshnessLevel == .useSoon
            case .fresh: return item.freshnessLevel == .fresh
            }
        }

        var hint: String {
            switch self {
            case .expired: return "Check before using"
            case .urgent: return "0–2 days left"
            case .useSoon: return "3–6 days left"
            case .fresh: return "7+ days left"
            }
        }
    }

    private func isExpanded(_ group: FreshnessGroup, totalCount: Int, isSearching: Bool) -> Bool {
        if isSearching { return true }
        if let saved = groupExpanded[group.rawValue] { return saved }
        // Default: collapse Fresh when the fridge is big.
        return !(group == .fresh && totalCount > 12)
    }

    private func foodGroup(_ group: FreshnessGroup, items: [FoodItem],
                           totalCount: Int, isSearching: Bool) -> some View {
        let expanded = isExpanded(group, totalCount: totalCount, isSearching: isSearching)

        return VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.snappy) { groupExpanded[group.rawValue] = !expanded }
            } label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(groupColor(group))
                        .frame(width: 9, height: 9)
                    Text(group.rawValue)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundStyle(FreshlingsHomeStyle.brown)
                    Text("\(items.count)")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundStyle(groupColor(group))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(groupColor(group).opacity(0.13), in: Capsule())
                    Text(group.hint)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundStyle(FreshlingsHomeStyle.secondary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(FreshlingsHomeStyle.secondary)
                        .rotationEffect(.degrees(expanded ? 0 : -90))
                }
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                LazyVStack(spacing: 8) {
                    ForEach(items) { item in
                        NavigationLink {
                            FoodDetailView(item: item)
                        } label: {
                            foodRow(item)
                        }
                        .buttonStyle(.plain)
                        .contextMenu { quickActions(item) }
                    }
                }
            }
        }
    }

    private func groupColor(_ group: FreshnessGroup) -> Color {
        switch group {
        case .expired: return FreshlingsHomeStyle.secondary
        case .urgent: return FreshlingsHomeStyle.orange
        case .useSoon: return FreshlingsHomeStyle.gold
        case .fresh: return FreshlingsHomeStyle.darkGreen
        }
    }

    /// Long-press menu. With more than 1, quick actions take ONE out;
    /// exact counts are on Food Details.
    @ViewBuilder
    private func quickActions(_ item: FoodItem) -> some View {
        if item.quantity > 1 {
            Button {
                foodStore.markAsUsed(item, quantity: 1)
            } label: {
                Label("Used 1 (of \(item.quantity))", systemImage: "checkmark.circle")
            }
            Button {
                foodStore.markAsUsed(item)
            } label: {
                Label("Used All \(item.quantity)", systemImage: "checkmark.circle.fill")
            }
            Button {
                foodStore.markAsWasted(item, quantity: 1)
            } label: {
                Label("Threw Away 1", systemImage: "trash")
            }
        } else {
            Button {
                foodStore.markAsUsed(item)
            } label: {
                Label("I Used It", systemImage: "checkmark.circle")
            }
            Button {
                foodStore.markAsWasted(item)
            } label: {
                Label("Threw Away", systemImage: "trash")
            }
        }
        Button(role: .destructive) {
            foodStore.deleteItem(item)
        } label: {
            Label("Delete", systemImage: "xmark.bin")
        }
    }

    // MARK: - Search & filter

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(FreshlingsHomeStyle.secondary)
            TextField("Search your fridge", text: $searchText)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundStyle(FreshlingsHomeStyle.brown)
                .autocorrectionDisabled()
            if !searchText.isEmpty {
                Button { searchText = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(FreshlingsHomeStyle.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 46)
        .background(FreshlingsHomeStyle.white, in: Capsule())
    }

    private var categoryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(title: "All", isSelected: selectedCategory == nil) {
                    selectedCategory = nil
                }
                ForEach(FoodCategory.allCases, id: \.self) { category in
                    chip(title: "\(category.addFoodIcon) \(category.rawValue)",
                         isSelected: selectedCategory == category) {
                        selectedCategory = (selectedCategory == category) ? nil : category
                    }
                }
            }
        }
    }

    private func chip(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? FreshlingsHomeStyle.darkGreen : FreshlingsHomeStyle.secondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isSelected ? FreshlingsHomeStyle.green : FreshlingsHomeStyle.white,
                            in: Capsule())
        }
        .buttonStyle(.plain)
    }

    private var noMatchState: some View {
        VStack(spacing: 6) {
            Text("🔍").font(.system(size: 34))
            Text("No matching food")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(FreshlingsHomeStyle.brown)
            Text("Try another name or category.")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(FreshlingsHomeStyle.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .background(FreshlingsHomeStyle.white, in: RoundedRectangle(cornerRadius: 21))
    }

    /// Compact row (~64 pt tall) so long lists don't need endless scrolling.
    private func foodRow(_ item: FoodItem) -> some View {
        HStack(spacing: 12) {
            foodSymbol(for: item, size: 44)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(FreshlingsHomeStyle.brown)
                    .lineLimit(1)
                    .truncationMode(.tail)

                Text("Qty \(item.quantity) · \(item.daysLeftText)")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(FreshlingsHomeStyle.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 6)

            VStack(alignment: .trailing, spacing: 5) {
                Text("\(Int(item.hpPercentage))%")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(statusColor(for: item))
                    .monospacedDigit()
                freshnessLine(item)
                    .frame(width: 56)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(FreshlingsHomeStyle.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(FreshlingsHomeStyle.white)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .contentShape(Rectangle())
    }

    // MARK: - Shared UI

    private func sectionTitle(_ title: String, subtitle: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(FreshlingsHomeStyle.brown)

            Spacer(minLength: 6)

            Text(subtitle)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(FreshlingsHomeStyle.secondary)
        }
    }

    private func foodSymbol(for item: FoodItem, size: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 17)
                .fill(FreshlingsHomeStyle.softGreen)

            Text(foodEmoji(for: item))
                .font(.system(size: size * 0.52))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func freshnessLine(_ item: FoodItem) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(FreshlingsHomeStyle.track)

                Capsule()
                    .fill(statusColor(for: item))
                    .frame(width: geometry.size.width * CGFloat(
                        min(max(item.hpPercentage, 0), 100) / 100
                    ))
            }
        }
        .frame(height: 7)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Text("🥬")
                .font(.system(size: 48))

            Text("Your fridge is waiting!")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(FreshlingsHomeStyle.brown)

            Text("Add food to start growing your Freshlings garden.")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(FreshlingsHomeStyle.secondary)
                .multilineTextAlignment(.center)

            // Goes to the Add tab.
            Button {
                router.selectedTab = .add
            } label: {
                Label("Add Food", systemImage: "plus")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(FreshlingsHomeStyle.white)
                    .padding(.horizontal, 22)
                    .padding(.vertical, 12)
                    .background(FreshlingsHomeStyle.darkGreen, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)

            // For demos / testing: fills the fridge with sample food.
            Button {
                foodStore.addDemoItems()
            } label: {
                Text("Try with demo food")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(FreshlingsHomeStyle.darkGreen)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(FreshlingsHomeStyle.green, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 20)
        .background(FreshlingsHomeStyle.softGreen)
        .clipShape(RoundedRectangle(cornerRadius: 23))
    }

    // MARK: - Text and color helpers

    private func priorityMessage(for item: FoodItem) -> String {
        if item.daysUntilExpiration < 0 { return "Past its date. Check before using." }
        if item.daysUntilExpiration == 0 { return "Best used today!" }
        if item.remainingDays == 1 { return "Only 1 day left. Use me soon!" }
        return "\(item.remainingDays) days left. Let's save it!"
    }

    private func daysText(for item: FoodItem) -> String {
        item.daysLeftText
    }

    private func expirationText(for item: FoodItem) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return "Exp. \(formatter.string(from: item.expirationDate))"
    }

    private func statusColor(for item: FoodItem) -> Color {
        switch item.freshnessLevel {
        case .fresh:
            return FreshlingsHomeStyle.darkGreen
        case .useSoon:
            return FreshlingsHomeStyle.gold
        case .urgent:
            return FreshlingsHomeStyle.orange
        case .expired:
            return FreshlingsHomeStyle.secondary
        }
    }

    private func foodEmoji(for item: FoodItem) -> String {
        switch item.category {
        case .vegetable:
            return item.name.lowercased().contains("carrot") ? "🥕" : "🥬"
        case .fruit:
            return "🍐"
        case .dairy:
            return "🥛"
        case .meat:
            return "🥩"
        case .other:
            return "🍽️"
        }
    }
}

// MARK: - Existing shared theme (preserved for other pages)
// Keep this declaration if PremiumTheme was originally defined in HomeView.swift.
enum PremiumTheme {
    static let background = Color(red: 0.965, green: 0.949, blue: 0.910)
    static let surface = Color(red: 0.995, green: 0.985, blue: 0.955)
    static let elevatedSurface = Color(red: 0.925, green: 0.918, blue: 0.870)
    static let cream = Color(red: 0.84, green: 0.80, blue: 0.67)
    static let olive = Color(red: 0.35, green: 0.43, blue: 0.26)
    static let gold = Color(red: 0.68, green: 0.53, blue: 0.26)
    static let warmAccent = Color(red: 0.72, green: 0.34, blue: 0.21)
    static let primaryText = Color(red: 0.13, green: 0.14, blue: 0.11)
    static let buttonText = Color(red: 0.12, green: 0.13, blue: 0.10)
    static let secondaryText = Color(red: 0.39, green: 0.39, blue: 0.33)
    static let mutedText = Color(red: 0.52, green: 0.50, blue: 0.43)
    static let border = Color(red: 0.80, green: 0.77, blue: 0.68).opacity(0.48)
    static let progressTrack = Color(red: 0.82, green: 0.80, blue: 0.73).opacity(0.62)
}

#Preview {
    NavigationStack {
        HomeView()
    }
    .environmentObject(FoodStore())
    .environmentObject(AppRouter())
}

