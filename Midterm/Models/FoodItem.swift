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
        case .urgent: return "Use Today"
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

    var totalShelfLifeDays: Int {
        max(Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: addedDate),
            to: Calendar.current.startOfDay(for: expirationDate)
        ).day ?? 1, 1)
    }

    var remainingDays: Int {
        max(Calendar.current.dateComponents(
            [.day],
            from: Calendar.current.startOfDay(for: Date()),
            to: Calendar.current.startOfDay(for: expirationDate)
        ).day ?? 0, 0)
    }

    var hpPercentage: Double {
        let value = Double(remainingDays) / Double(totalShelfLifeDays) * 100
        return min(max(value, 0), 100)
    }

    var freshnessLevel: FreshnessLevel {
        switch hpPercentage {
        case 61...100: return .fresh
        case 31..<61: return .useSoon
        case 1..<31: return .urgent
        default: return .expired
        }
    }
}
