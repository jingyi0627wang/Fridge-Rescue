import SwiftUI

struct HPBarView: View {
    let item: FoodItem

    private var statusColor: Color {
        switch item.freshnessLevel {
        case .fresh:
            return .fridgeGreen
        case .useSoon:
            return .fridgeOrange
        case .urgent:
            return .fridgeRed
        case .expired:
            return .gray
        }
    }

    private var foodIcon: String {
        switch item.category {
        case .vegetable:
            return "carrot.fill"
        case .fruit:
            return "apple.logo"
        case .dairy:
            return "waterbottle.fill"
        case .meat:
            return "fork.knife"
        case .other:
            return "takeoutbag.and.cup.and.straw.fill"
        }
    }

    private var hpProgress: Double {
        max(0, min(item.hpPercentage / 100.0, 1.0))
    }

    private var daysText: String {
        if item.freshnessLevel == .expired {
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

    var body: some View {
        VStack(spacing: 12) {

            HStack(spacing: 13) {

                Image(systemName: foodIcon)
                    .font(.system(size: 20))
                    .foregroundStyle(statusColor)
                    .frame(width: 48, height: 48)
                    .background(statusColor.opacity(0.10))
                    .clipShape(
                        RoundedRectangle(cornerRadius: 14)
                    )

                VStack(alignment: .leading, spacing: 4) {

                    Text(item.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.primary)

                    Text("\(item.category.rawValue) · ×\(item.quantity)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 7) {

                    Text("\(Int(item.hpPercentage)) HP")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(statusColor)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.secondary)
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {

                    Capsule()
                        .fill(Color.gray.opacity(0.12))

                    Capsule()
                        .fill(statusColor)
                        .frame(
                            width: geometry.size.width * hpProgress
                        )
                }
            }
            .frame(height: 6)

            HStack {

                Label(
                    daysText,
                    systemImage: "clock"
                )
                .font(.system(size: 12))
                .foregroundStyle(.secondary)

                Spacer()

                Text(item.freshnessLevel.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(statusColor)
            }
        }
        .padding(15)
        .background(Color.white)
        .clipShape(
            RoundedRectangle(cornerRadius: 20)
        )
        .shadow(
            color: Color.black.opacity(0.025),
            radius: 8,
            x: 0,
            y: 4
        )
    }
}


// MARK: - Shared App Colors

extension Color {

    static let fridgeBackground = Color(
        red: 0.98,
        green: 0.97,
        blue: 0.95
    )

    static let fridgeGreen = Color(
        red: 0.29,
        green: 0.59,
        blue: 0.38
    )

    static let fridgeOrange = Color(
        red: 0.94,
        green: 0.48,
        blue: 0.24
    )

    static let fridgeRed = Color(
        red: 0.92,
        green: 0.36,
        blue: 0.33
    )
}
// MARK: - Legacy Theme Support

enum FridgeTheme {

    static let background = PremiumTheme.background

    static let card = PremiumTheme.surface

    static let green = PremiumTheme.olive

    static let yellow = PremiumTheme.gold

    static let orange = PremiumTheme.warmAccent

    static let red = Color(
        red: 0.65,
        green: 0.30,
        blue: 0.27
    )

    static let primaryText = PremiumTheme.primaryText

    static let secondaryText = PremiumTheme.secondaryText

    static let border = PremiumTheme.border
}
