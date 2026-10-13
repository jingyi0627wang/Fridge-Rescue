import SwiftUI

struct HPBarView: View {
    let item: FoodItem

    // MARK: - Freshlings Palette
    private let cardBackground = Color(red: 1.00, green: 0.995, blue: 0.970)
    private let mainText = Color(red: 0.23, green: 0.30, blue: 0.20)
    private let secondaryText = Color(red: 0.44, green: 0.48, blue: 0.39)
    private let trackColor = Color(red: 0.88, green: 0.93, blue: 0.82)

    private var statusColor: Color {
        switch item.freshnessLevel {
        case .fresh: return Color(red: 0.29, green: 0.65, blue: 0.25)
        case .useSoon: return Color(red: 0.77, green: 0.54, blue: 0.09)
        case .urgent: return Color(red: 0.86, green: 0.36, blue: 0.19)
        case .expired: return Color(red: 0.52, green: 0.54, blue: 0.51)
        }
    }

    private var statusBackground: Color {
        statusColor.opacity(0.11)
    }

    private var foodEmoji: String {
        switch item.category {
        case .vegetable:
            return item.name.localizedCaseInsensitiveContains("carrot") ? "🥕" : "🥬"
        case .fruit: return "🍎"
        case .dairy: return "🥛"
        case .meat: return "🥩"
        case .other: return "🥣"
        }
    }

    private var hpProgress: Double {
        max(0, min(item.hpPercentage / 100.0, 1.0))
    }

    private var daysText: String {
        if item.freshnessLevel == .expired { return "Expired" }
        if item.remainingDays == 0 { return "Expires today" }
        if item.remainingDays == 1 { return "1 day left" }
        return "\(item.remainingDays) days left"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 13) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(statusBackground)
                    Text(foodEmoji)
                        .font(.system(size: 29))
                }
                .frame(width: 58, height: 58)
                .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 5) {
                    Text(item.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(mainText)
                        .lineLimit(1)

                    Text("\(item.category.rawValue)  ·  ×\(item.quantity)")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundStyle(secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 4)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(Int(item.hpPercentage))%")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundStyle(statusColor)
                        .monospacedDigit()
                    Text("FRESHNESS")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundStyle(secondaryText)
                }

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(secondaryText)
                    .accessibilityHidden(true)
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(trackColor)
                    Capsule()
                        .fill(statusColor)
                        .frame(width: geometry.size.width * hpProgress)
                }
            }
            .frame(height: 9)
            .accessibilityLabel("Freshness")
            .accessibilityValue("\(Int(item.hpPercentage)) percent")

            HStack(spacing: 8) {
                Label(daysText, systemImage: "clock")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(secondaryText)

                Spacer(minLength: 8)

                Text(item.freshnessLevel.title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(statusColor)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(statusBackground, in: Capsule())
            }
        }
        .padding(16)
        .background(cardBackground, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color(red: 0.81, green: 0.88, blue: 0.75).opacity(0.65), lineWidth: 1)
        }
    }
}

// MARK: - Shared App Colors
// Keep these properties for compatibility with other existing views.
extension Color {
    static let fridgeBackground = Color(red: 0.98, green: 0.99, blue: 0.96)
    static let fridgeGreen = Color(red: 0.29, green: 0.65, blue: 0.25)
    static let fridgeOrange = Color(red: 0.86, green: 0.36, blue: 0.19)
    static let fridgeRed = Color(red: 0.82, green: 0.27, blue: 0.27)
}

// MARK: - Legacy Theme Support
// Keep the same names so older views do not need to change.
enum FridgeTheme {
    static let background = PremiumTheme.background
    static let card = PremiumTheme.surface
    static let green = PremiumTheme.olive
    static let yellow = PremiumTheme.gold
    static let orange = PremiumTheme.warmAccent
    static let red = Color(red: 0.65, green: 0.30, blue: 0.27)
    static let primaryText = PremiumTheme.primaryText
    static let secondaryText = PremiumTheme.secondaryText
    static let border = PremiumTheme.border
}

