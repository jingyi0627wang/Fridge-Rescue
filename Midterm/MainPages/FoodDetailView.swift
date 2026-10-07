import SwiftUI

struct FoodDetailView: View {

    let item: FoodItem

    // MARK: - Colors

    private let backgroundColor = Color(
        red: 0.97,
        green: 0.96,
        blue: 0.91
    )

    private let cardColor = Color(
        red: 0.995,
        green: 0.985,
        blue: 0.955
    )

    private let primaryText = Color(
        red: 0.12,
        green: 0.12,
        blue: 0.10
    )

    private let secondaryText = Color(
        red: 0.40,
        green: 0.40,
        blue: 0.35
    )

    private let green = Color(
        red: 0.34,
        green: 0.46,
        blue: 0.23
    )

    private let orange = Color(
        red: 0.76,
        green: 0.31,
        blue: 0.17
    )

    private let lightOrange = Color(
        red: 0.96,
        green: 0.88,
        blue: 0.82
    )

    // MARK: - Body

    var body: some View {

        ZStack {

            backgroundColor
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {

                VStack(spacing: 28) {

                    headerSection

                    foodHeroSection

                    freshnessSection

                    informationSection

                    recipeButton
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)
                .padding(.bottom, 50)
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .tabBar)
    }


    // MARK: - Header

    private var headerSection: some View {

        ZStack {

            HStack {

                Button {
                    dismiss()
                } label: {

                    Image(systemName: "chevron.left")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(primaryText)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.75))
                        )
                }

                Spacer()
            }

            Text("Food Details")
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(primaryText)
        }
    }


    // MARK: - Food Hero

    private var foodHeroSection: some View {

        VStack(spacing: 12) {

            ZStack {

                Circle()
                    .fill(iconBackground)
                    .frame(width: 82, height: 82)

                Text(foodEmoji)
                    .font(.system(size: 42))
            }

            Text(item.name)
                .font(.system(size: 34, weight: .bold))
                .foregroundStyle(primaryText)

            Text(item.category.rawValue)
                .font(.system(size: 17))
                .foregroundStyle(secondaryText)

            Text(item.freshnessLevel.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(statusColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.12))
                )
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
    }


    // MARK: - Freshness

    private var freshnessSection: some View {

        VStack(alignment: .leading, spacing: 22) {

            Text("Freshness")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(primaryText)

            HStack(alignment: .firstTextBaseline) {

                Text("\(Int(item.hpPercentage)) HP")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(statusColor)

                Spacer()

                Text(daysText)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(secondaryText)
            }

            GeometryReader { geometry in

                ZStack(alignment: .leading) {

                    Capsule()
                        .fill(Color.black.opacity(0.08))

                    Capsule()
                        .fill(statusColor)
                        .frame(
                            width:
                                geometry.size.width *
                                CGFloat(item.hpPercentage / 100)
                        )
                }
            }
            .frame(height: 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardColor)
        )
    }


    // MARK: - Food Information

    private var informationSection: some View {

        VStack(alignment: .leading, spacing: 0) {

            Text("Food Information")
                .font(.system(size: 21, weight: .bold))
                .foregroundStyle(primaryText)
                .padding(.bottom, 18)

            informationRow(
                title: "Quantity",
                value: "\(item.quantity)"
            )

            divider

            informationRow(
                title: "Added",
                value: formattedDate(item.addedDate)
            )

            divider

            informationRow(
                title: "Expiration",
                value: formattedDate(item.expirationDate)
            )

            divider

            informationRow(
                title: "Estimated Value",
                value: String(
                    format: "$%.2f",
                    item.estimatedValue
                )
            )

            divider

            informationRow(
                title: "Carbon Factor",
                value: String(
                    format: "%.2f",
                    item.carbonFactor
                )
            )
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(cardColor)
        )
    }


    // MARK: - Information Row

    private func informationRow(
        title: String,
        value: String
    ) -> some View {

        HStack {

            Text(title)
                .font(.system(size: 16))
                .foregroundStyle(secondaryText)

            Spacer()

            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(primaryText)
        }
        .padding(.vertical, 14)
    }


    private var divider: some View {

        Rectangle()
            .fill(Color.black.opacity(0.06))
            .frame(height: 1)
    }


    // MARK: - Find Recipes

    private var recipeButton: some View {

        NavigationLink {

            RecipeListView(
                focusIngredient: item
            )

        } label: {

            HStack(spacing: 14) {

                Image(systemName: "fork.knife")
                    .font(.system(size: 18, weight: .semibold))

                VStack(
                    alignment: .leading,
                    spacing: 3
                ) {

                    Text("Find Recipes with \(item.name)")
                        .font(
                            .system(
                                size: 17,
                                weight: .semibold
                            )
                        )

                    Text("Use it before it expires")
                        .font(.system(size: 13))
                        .opacity(0.75)
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 20)
            .frame(height: 72)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(green)
            )
        }
        .buttonStyle(.plain)
    }


    // MARK: - Status

    private var statusColor: Color {

        switch item.freshnessLevel {

        case .fresh:
            return green

        case .useSoon:
            return Color.orange

        case .urgent:
            return orange

        case .expired:
            return Color.gray
        }
    }


    // MARK: - Icon Background

    private var iconBackground: Color {

        switch item.freshnessLevel {

        case .fresh:
            return green.opacity(0.12)

        case .useSoon:
            return Color.orange.opacity(0.12)

        case .urgent:
            return lightOrange

        case .expired:
            return Color.gray.opacity(0.12)
        }
    }


    // MARK: - Food Emoji

    private var foodEmoji: String {

        switch item.category {

        case .vegetable:
            return "🥕"

        case .fruit:
            return "🍎"

        case .dairy:
            return "🥛"

        case .meat:
            return "🥩"

        case .other:
            return "🥣"
        }
    }


    // MARK: - Days Text

    private var daysText: String {

        if item.hpPercentage <= 0 {
            return "Expired"
        }

        if item.remainingDays == 0 {
            return "Expires today"
        }

        if item.remainingDays == 1 {
            return "1 day left"
        }

        return "\(item.remainingDays) days left"
    }


    // MARK: - Date

    private func formattedDate(
        _ date: Date
    ) -> String {

        let formatter = DateFormatter()

        formatter.dateFormat = "MMM d, yyyy"

        return formatter.string(from: date)
    }


    // MARK: - Dismiss

    @Environment(\.dismiss)
    private var dismiss
}
