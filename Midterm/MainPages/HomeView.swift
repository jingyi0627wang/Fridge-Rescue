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

    private var activeItems: [FoodItem] {
        foodStore.foodItems
            .filter { $0.status == .active }
            .sorted { $0.hpPercentage < $1.hpPercentage }
    }

    private var attentionItems: [FoodItem] {
        activeItems.filter {
            $0.freshnessLevel == .urgent || $0.freshnessLevel == .useSoon
        }
    }

    private var rescueItem: FoodItem? { attentionItems.first }

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

            ZStack {
                Circle()
                    .fill(FreshlingsHomeStyle.softGreen)
                    .frame(width: 62, height: 62)

                Text("🌱")
                    .font(.system(size: 34))
            }
            .accessibilityHidden(true)
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

            HStack(spacing: 12) {
                summaryCard(
                    number: activeItems.count,
                    title: "In Fridge",
                    symbol: "refrigerator.fill",
                    background: FreshlingsHomeStyle.white,
                    accent: FreshlingsHomeStyle.darkGreen
                )

                summaryCard(
                    number: attentionItems.count,
                    title: "Use Soon",
                    symbol: "clock.fill",
                    background: FreshlingsHomeStyle.softYellow,
                    accent: FreshlingsHomeStyle.orange
                )
            }
        }
    }

    private func summaryCard(
        number: Int,
        title: String,
        symbol: String,
        background: Color,
        accent: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: symbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(accent)

            Text("\(number)")
                .font(.system(size: 29, weight: .heavy, design: .rounded))
                .foregroundStyle(FreshlingsHomeStyle.brown)

            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(FreshlingsHomeStyle.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 21))
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

                NavigationLink {
                    RecipeListView(focusIngredient: item)
                        .environmentObject(foodStore)
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
            sectionTitle("My Food", subtitle: "Lowest freshness first")

            if activeItems.isEmpty {
                emptyState
            } else {
                VStack(spacing: 11) {
                    ForEach(activeItems) { item in
                        NavigationLink {
                            FoodDetailView(item: item)
                                .environmentObject(foodStore)
                        } label: {
                            foodRow(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func foodRow(_ item: FoodItem) -> some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 12) {
                foodSymbol(for: item, size: 53)

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(FreshlingsHomeStyle.brown)
                        .lineLimit(1)

                    Text("\(item.category.rawValue.capitalized) · Qty \(item.quantity)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(FreshlingsHomeStyle.secondary)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(item.hpPercentage))%")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(statusColor(for: item))

                    Text(item.freshnessLevel.title)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(FreshlingsHomeStyle.secondary)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(FreshlingsHomeStyle.secondary)
            }

            freshnessLine(item)

            HStack(spacing: 5) {
                Image(systemName: "clock")
                Text(daysText(for: item))
                Spacer()
                Text(expirationText(for: item))
            }
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(FreshlingsHomeStyle.secondary)
        }
        .padding(15)
        .background(FreshlingsHomeStyle.white)
        .clipShape(RoundedRectangle(cornerRadius: 21))
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
        if item.remainingDays <= 0 { return "Best used today!" }
        if item.remainingDays == 1 { return "Only 1 day left. Use me soon!" }
        return "\(item.remainingDays) days left. Let's save it!"
    }

    private func daysText(for item: FoodItem) -> String {
        if item.remainingDays <= 0 { return "Expires today" }
        if item.remainingDays == 1 { return "1 day left" }
        return "\(item.remainingDays) days left"
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
}

