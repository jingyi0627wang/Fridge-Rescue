import Foundation
import SwiftUI

enum FoodStatus: String, Codable {
    case active
    case used
    case wasted
}

enum FoodCategory: String, Codable, CaseIterable {
    case vegetable = "Vegetable"
    case fruit = "Fruit"
    case dairy = "Dairy"
    case meat = "Meat"
    case other = "Other"
}

enum FreshnessLevel {
    case fresh
    case useSoon
    case urgent
    case expired

    var title: String {
        switch self {
        case .fresh: return "Fresh"
        case .useSoon: return "Use Soon"
        case .urgent: return "Urgent"
        case .expired: return "Expired"
        }
    }

    var color: Color {
        switch self {
        case .fresh: return .green
        case .useSoon: return .yellow
        case .urgent: return .red
        case .expired: return .gray
        }
    }
}

struct FoodItem: Identifiable, Codable {
    var id = UUID()
    var name: String
    var category: FoodCategory
    var addedDate: Date
    var expirationDate: Date
    var quantity: Int
    var status: FoodStatus = .active
    var estimatedValue: Double
    var carbonFactor: Double
    /// When the item was marked as used or wasted (nil while still in the fridge).
    /// Optional so food saved by older versions of the app still loads.
    var finishedDate: Date? = nil
    /// History records only: id of the fridge item this came from
    /// (so "Back to Fridge" can add the quantity back to it).
    var originalID: UUID? = nil
    /// Optional photo taken by the user (file name in FoodPhotoStore).
    /// Shown instead of the drawing. Optional so older saved food still loads.
    var photoFile: String? = nil

    /// Date used for history and charts.
    var finishedOn: Date { finishedDate ?? addedDate }

    var totalShelfLifeDays: Int {
        max(Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: addedDate),
            to: Calendar.current.startOfDay(for: expirationDate)
        ).day ?? 1, 1)
    }

    /// Days until expiration. 0 = expires today, negative = already expired.
    var daysUntilExpiration: Int {
        Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: expirationDate)
        ).day ?? 0
    }

    /// Same as daysUntilExpiration but never below 0 (for "X days left" text).
    var remainingDays: Int {
        max(daysUntilExpiration, 0)
    }

    /// "Expired 2 days ago" / "Expires today" / "1 day left" / "5 days left"
    var daysLeftText: String {
        let days = daysUntilExpiration
        if days < -1 { return "Expired \(-days) days ago" }
        if days == -1 { return "Expired yesterday" }
        if days == 0 { return "Expires today" }
        if days == 1 { return "1 day left" }
        return "\(days) days left"
    }

    // MARK: - HP
    // HP depends ONLY on how many days are left, not on when the food was bought.
    // 7 or more days left = 100% HP. Each day less takes away 1/7 of the bar.
    static let fullHPDays = 7

    var hpPercentage: Double {
        guard daysUntilExpiration >= 0 else { return 0 }
        // Expiring today still shows a sliver of HP so it isn't confused with expired.
        let days = max(Double(daysUntilExpiration), 0.3)
        return min(days / Double(Self.fullHPDays), 1) * 100
    }

    var freshnessLevel: FreshnessLevel {
        switch daysUntilExpiration {
        case Self.fullHPDays...: return .fresh      // 7+ days
        case 3..<Self.fullHPDays: return .useSoon   // 3–6 days
        case 0..<3: return .urgent                  // today – 2 days
        default: return .expired                    // past the date
        }
    }
}
