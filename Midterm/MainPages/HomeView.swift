import SwiftUI

struct HomeView: View {

    @EnvironmentObject var foodStore: FoodStore

    // MARK: - Data

    private var activeItems: [FoodItem] {
        foodStore.foodItems
            .filter { $0.status == .active }
            .sorted { $0.hpPercentage < $1.hpPercentage }
    }

    private var attentionItems: [FoodItem] {
        activeItems.filter {
            $0.freshnessLevel == .urgent ||
            $0.freshnessLevel == .useSoon
        }
    }

    private var rescueItem: FoodItem? {
        attentionItems.first
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumTheme.background
                    .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 30) {

                        headerSection

                        overviewSection

                        if let rescueItem {
                            rescueSection(rescueItem)
                        }

                        foodSection
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 18)

                    // Extra space so content is not hidden by TabView
                    .padding(.bottom, 110)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {

            VStack(alignment: .leading, spacing: 7) {

                Text("MY FRIDGE")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(2.2)
                    .foregroundStyle(PremiumTheme.olive)

                Text("Keep what matters.")
                    .font(
                        .system(
                            size: 32,
                            weight: .medium,
                            design: .serif
                        )
                    )
                    .foregroundStyle(PremiumTheme.primaryText)

                Text("Use ingredients while they're at their best.")
                    .font(.system(size: 14))
                    .foregroundStyle(PremiumTheme.secondaryText)
            }

            Spacer()

            ZStack {
                Circle()
                    .fill(PremiumTheme.surface)

                Image(systemName: "leaf.fill")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(PremiumTheme.olive)
            }
            .frame(width: 46, height: 46)
            .overlay {
                Circle()
                    .stroke(PremiumTheme.border, lineWidth: 1)
            }
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        HStack(spacing: 12) {

            overviewCard(
                number: activeItems.count,
                label: "IN FRIDGE",
                accent: PremiumTheme.olive
            )

            overviewCard(
                number: attentionItems.count,
                label: "USE SOON",
                accent: PremiumTheme.warmAccent
            )
        }
    }

    private func overviewCard(
        number: Int,
        label: String,
        accent: Color
    ) -> some View {

        VStack(alignment: .leading, spacing: 17) {

            Text(String(format: "%02d", number))
                .font(
                    .system(
                        size: 30,
                        weight: .medium,
                        design: .serif
                    )
                )
                .foregroundStyle(PremiumTheme.primaryText)

            HStack {

                Text(label)
                    .font(.system(size: 10, weight: .semibold))
                    .tracking(1.5)
                    .foregroundStyle(PremiumTheme.secondaryText)

                Spacer()

                Circle()
                    .fill(accent)
                    .frame(width: 7, height: 7)
            }
        }
        .padding(19)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PremiumTheme.surface)
        .overlay {
            RoundedRectangle(cornerRadius: 14)
                .stroke(PremiumTheme.border, lineWidth: 1)
        }
        .clipShape(
            RoundedRectangle(cornerRadius: 14)
        )
    }

    // MARK: - Priority

    private func rescueSection(
        _ item: FoodItem
    ) -> some View {

        VStack(alignment: .leading, spacing: 16) {

            sectionHeader(
                title: "Priority",
                detail: "USE FIRST"
            )

            VStack(alignment: .leading, spacing: 20) {

                HStack(alignment: .top, spacing: 16) {

                    foodSymbol(
                        for: item,
                        size: 54
                    )

                    VStack(alignment: .leading, spacing: 6) {

                        Text(item.name)
                            .font(
                                .system(
                                    size: 23,
                                    weight: .medium,
                                    design: .serif
                                )
                            )
                            .foregroundStyle(
                                PremiumTheme.primaryText
                            )

                        Text(priorityMessage(for: item))
                            .font(.system(size: 13))
                            .foregroundStyle(
                                PremiumTheme.secondaryText
                            )
                            .fixedSize(
                                horizontal: false,
                                vertical: true
                            )
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {

                        Text("\(Int(item.hpPercentage))")
                            .font(
                                .system(
                                    size: 28,
                                    weight: .medium,
                                    design: .serif
                                )
                            )
                            .foregroundStyle(
                                statusColor(for: item)
                            )

                        Text("FRESHNESS")
                            .font(
                                .system(
                                    size: 8,
                                    weight: .semibold
                                )
                            )
                            .tracking(1.2)
                            .foregroundStyle(
                                PremiumTheme.mutedText
                            )
                    }
                }

                freshnessLine(item)

                NavigationLink {
                    RecipeListView(
                        focusIngredient: item
                    )
                    .environmentObject(foodStore)

                } label: {

                    HStack {

                        Image(
                            systemName:
                                "fork.knife"
                        )

                        Text("Explore recipes")
                            .font(
                                .system(
                                    size: 14,
                                    weight: .semibold
                                )
                            )

                        Spacer()

                        Image(
                            systemName:
                                "arrow.up.right"
                        )
                        .font(
                            .system(
                                size: 12,
                                weight: .semibold
                            )
                        )
                    }
                    .foregroundStyle(
                        PremiumTheme.buttonText
                    )
                    .padding(.horizontal, 17)
                    .frame(height: 52)
                    .background(
                        PremiumTheme.cream
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius: 12
                        )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
            .background(
                PremiumTheme.surface
            )
            .overlay {
                RoundedRectangle(
                    cornerRadius: 18
                )
                .stroke(
                    PremiumTheme.border,
                    lineWidth: 1
                )
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 18
                )
            )
        }
    }

    // MARK: - Food List

    private var foodSection: some View {

        VStack(alignment: .leading, spacing: 16) {

            sectionHeader(
                title: "Inventory",
                detail: "LOWEST FIRST"
            )

            if activeItems.isEmpty {

                emptyState

            } else {

                VStack(spacing: 12) {

                    ForEach(activeItems) { item in

                        NavigationLink {

                            FoodDetailView(
                                item: item
                            )
                            .environmentObject(
                                foodStore
                            )

                        } label: {

                            foodRow(item)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func foodRow(
        _ item: FoodItem
    ) -> some View {

        VStack(spacing: 17) {

            HStack(spacing: 15) {

                foodSymbol(
                    for: item,
                    size: 48
                )

                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {

                    Text(item.name)
                        .font(
                            .system(
                                size: 17,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            PremiumTheme.primaryText
                        )

                    Text(
                        "\(item.category.rawValue.uppercased())  ·  QTY \(item.quantity)"
                    )
                    .font(
                        .system(
                            size: 9,
                            weight: .medium
                        )
                    )
                    .tracking(1)
                    .foregroundStyle(
                        PremiumTheme.mutedText
                    )
                }

                Spacer()

                VStack(
                    alignment: .trailing,
                    spacing: 5
                ) {

                    Text(
                        "\(Int(item.hpPercentage))%"
                    )
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(
                        statusColor(for: item)
                    )

                    Text(
                        item
                            .freshnessLevel
                            .title
                            .uppercased()
                    )
                    .font(
                        .system(
                            size: 8,
                            weight: .semibold
                        )
                    )
                    .tracking(1)
                    .foregroundStyle(
                        PremiumTheme.mutedText
                    )
                }

                Image(
                    systemName:
                        "chevron.right"
                )
                .font(.system(size: 11))
                .foregroundStyle(
                    PremiumTheme.mutedText
                )
            }

            freshnessLine(item)

            HStack {

                Image(
                    systemName:
                        "clock"
                )
                .font(.system(size: 10))

                Text(
                    daysText(for: item)
                )
                .font(.system(size: 11))

                Spacer()

                Text(
                    expirationText(
                        for: item
                    )
                )
                .font(.system(size: 10))
            }
            .foregroundStyle(
                PremiumTheme.secondaryText
            )
        }
        .padding(18)
        .background(
            PremiumTheme.surface
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 18
            )
            .stroke(
                PremiumTheme.border,
                lineWidth: 1
            )
        }
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    // MARK: - Section Header

    private func sectionHeader(
        title: String,
        detail: String
    ) -> some View {

        HStack(
            alignment:
                .lastTextBaseline
        ) {

            Text(title)
                .font(
                    .system(
                        size: 23,
                        weight: .medium,
                        design: .serif
                    )
                )
                .foregroundStyle(
                    PremiumTheme.primaryText
                )

            Spacer()

            Text(detail)
                .font(
                    .system(
                        size: 9,
                        weight: .semibold
                    )
                )
                .tracking(1.4)
                .foregroundStyle(
                    PremiumTheme.mutedText
                )
        }
    }

    // MARK: - Food Symbol

    private func foodSymbol(
        for item: FoodItem,
        size: CGFloat
    ) -> some View {

        ZStack {

            RoundedRectangle(
                cornerRadius: 12
            )
            .fill(
                PremiumTheme
                    .elevatedSurface
            )

            Text(
                foodEmoji(for: item)
            )
            .font(
                .system(
                    size: size * 0.43
                )
            )
        }
        .frame(
            width: size,
            height: size
        )
        .overlay {
            RoundedRectangle(
                cornerRadius: 12
            )
            .stroke(
                PremiumTheme.border,
                lineWidth: 1
            )
        }
    }

    // MARK: - Freshness Line

    private func freshnessLine(
        _ item: FoodItem
    ) -> some View {

        GeometryReader { geometry in

            ZStack(
                alignment: .leading
            ) {

                Capsule()
                    .fill(
                        PremiumTheme
                            .progressTrack
                    )
                    .frame(height: 4)

                Capsule()
                    .fill(
                        statusColor(
                            for: item
                        )
                    )
                    .frame(
                        width:
                            geometry.size.width *
                            CGFloat(
                                item.hpPercentage /
                                100
                            ),
                        height: 4
                    )
            }
        }
        .frame(height: 4)
    }

    // MARK: - Empty State

    private var emptyState: some View {

        VStack(spacing: 10) {

            Image(
                systemName:
                    "refrigerator"
            )
            .font(.system(size: 26))
            .foregroundStyle(
                PremiumTheme.olive
            )

            Text(
                "Your fridge is empty."
            )
            .font(
                .system(
                    size: 20,
                    weight: .medium,
                    design: .serif
                )
            )
            .foregroundStyle(
                PremiumTheme.primaryText
            )

            Text(
                "Add food to begin tracking freshness."
            )
            .font(.system(size: 13))
            .foregroundStyle(
                PremiumTheme.secondaryText
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
        .background(
            PremiumTheme.surface
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 18
            )
        )
    }

    // MARK: - Helpers

    private func priorityMessage(
        for item: FoodItem
    ) -> String {

        if item.remainingDays == 0 {
            return "Best used today."
        }

        if item.remainingDays == 1 {
            return "Only 1 day left before expiration."
        }

        return "\(item.remainingDays) days remaining."
    }

    private func daysText(
        for item: FoodItem
    ) -> String {

        if item.remainingDays == 0 {
            return "Expires today"
        }

        if item.remainingDays == 1 {
            return "1 day left"
        }

        return "\(item.remainingDays) days left"
    }

    private func expirationText(
        for item: FoodItem
    ) -> String {

        let formatter =
            DateFormatter()

        formatter.dateFormat =
            "MMM d"

        return
            "EXP. \(formatter.string(from: item.expirationDate).uppercased())"
    }

    private func statusColor(
        for item: FoodItem
    ) -> Color {

        switch item.freshnessLevel {

        case .fresh:
            return PremiumTheme.olive

        case .useSoon:
            return PremiumTheme.gold

        case .urgent:
            return PremiumTheme.warmAccent

        case .expired:
            return PremiumTheme.mutedText
        }
    }

    private func foodEmoji(
        for item: FoodItem
    ) -> String {

        switch item.category {

        case .vegetable:

            if item.name
                .lowercased()
                .contains("carrot") {
                return "🥕"
            }

            return "🥬"

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


// MARK: - Premium Warm Theme

enum PremiumTheme {

    // Warm ivory background
    static let background =
        Color(
            red: 0.965,
            green: 0.949,
            blue: 0.910
        )

    // Main white / ivory cards
    static let surface =
        Color(
            red: 0.995,
            green: 0.985,
            blue: 0.955
        )

    // Raised icon areas
    static let elevatedSurface =
        Color(
            red: 0.925,
            green: 0.918,
            blue: 0.870
        )

    // Main cream button
    static let cream =
        Color(
            red: 0.84,
            green: 0.80,
            blue: 0.67
        )

    // Muted olive green
    static let olive =
        Color(
            red: 0.35,
            green: 0.43,
            blue: 0.26
        )

    // Use Soon
    static let gold =
        Color(
            red: 0.68,
            green: 0.53,
            blue: 0.26
        )

    // Urgent / expiration
    static let warmAccent =
        Color(
            red: 0.72,
            green: 0.34,
            blue: 0.21
        )

    // Main text
    static let primaryText =
        Color(
            red: 0.13,
            green: 0.14,
            blue: 0.11
        )

    // Button text
    static let buttonText =
        Color(
            red: 0.12,
            green: 0.13,
            blue: 0.10
        )

    // Secondary text
    static let secondaryText =
        Color(
            red: 0.39,
            green: 0.39,
            blue: 0.33
        )

    // Small metadata
    static let mutedText =
        Color(
            red: 0.52,
            green: 0.50,
            blue: 0.43
        )

    // Card border
    static let border =
        Color(
            red: 0.80,
            green: 0.77,
            blue: 0.68
        )
        .opacity(0.48)

    // HP track
    static let progressTrack =
        Color(
            red: 0.82,
            green: 0.80,
            blue: 0.73
        )
        .opacity(0.62)
}


// MARK: - Preview

#Preview {
    HomeView()
        .environmentObject(
            FoodStore()
        )
}
