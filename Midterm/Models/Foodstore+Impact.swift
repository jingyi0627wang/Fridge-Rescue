//
//  Foodstore+Impact.swift
//  Midterm
//
//  Created by Rumik He on 10/13/26.
//

import Foundation

struct CategoryStat: Identifiable {
    let category: FoodCategory
    let count: Int
    var id: String { category.rawValue }
}

extension FoodStore {


    var usedItems: [FoodItem] {
        history.filter { $0.status == .used }
    }

    var wastedItems: [FoodItem] {
        history.filter { $0.status == .wasted }
    }


    var moneySaved: Double {
        usedItems.reduce(0) { total, item in
            total + item.estimatedValue * Double(item.quantity)
        }
    }

    var carbonSaved: Double {
        usedItems.reduce(0) { total, item in
            total + item.carbonFactor * Double(item.quantity)
        }
    }

    var useRate: Double {
        let total = usedItems.count + wastedItems.count
        guard total > 0 else { return 0 }
        return Double(usedItems.count) / Double(total)
    }

    //charts

    var usedByCategory: [CategoryStat] {
        FoodCategory.allCases
            .map { category in
                CategoryStat(
                    category: category,
                    count: usedItems.filter { $0.category == category }.count
                )
            }
            .filter { $0.count > 0 }
    }
}

