//
//  ImpactView.swift
//  Midterm
//
//  Created by Rumik He on 10/13/26.
//

import SwiftUI
import Charts

struct ImpactView: View {

    @EnvironmentObject var foodStore: FoodStore


    private var hasNoHistory: Bool {
        foodStore.usedItems.isEmpty && foodStore.wastedItems.isEmpty
    }


    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            PremiumTheme.background
                .ignoresSafeArea()

            if hasNoHistory {
                emptyState
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        statGrid
                        useRateCard
                        categoryChartCard
                    }
                    .padding(20)
                }
            }
        }
        .navigationTitle("Impact")
    }



    private var emptyState: some View {
        ContentUnavailableView(
            "No impact yet",
            systemImage: "leaf",
            description: Text("Use your first item to see your impact.")
        )
    }



    private var statGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            statCard(
                title: "Money saved",
                value: foodStore.moneySaved.formatted(.currency(code: "USD")),
                icon: "dollarsign.circle"
            )
            statCard(
                title: "Carbon saved",
                value: String(format: "%.1f kg", foodStore.carbonSaved),
                icon: "leaf"
            )
            statCard(
                title: "Items used",
                value: "\(foodStore.usedItems.count)",
                icon: "checkmark.circle"
            )
            statCard(
                title: "Items wasted",
                value: "\(foodStore.wastedItems.count)",
                icon: "trash"
            )
        }
    }

    private func statCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(PremiumTheme.olive)

            Text(value)
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(PremiumTheme.primaryText)

            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(PremiumTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(PremiumTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(PremiumTheme.border, lineWidth: 1)
        )
    }



    private var useRateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Use rate")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(PremiumTheme.primaryText)
                Spacer()
                Text("\(Int(foodStore.useRate * 100))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(PremiumTheme.olive)
            }

            ProgressView(value: foodStore.useRate)
                .tint(PremiumTheme.olive)

            Text("Share of finished items you used instead of throwing away.")
                .font(.system(size: 12))
                .foregroundStyle(PremiumTheme.secondaryText)
        }
        .padding(16)
        .background(PremiumTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(PremiumTheme.border, lineWidth: 1)
        )
    }



    private var categoryChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Used by category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(PremiumTheme.primaryText)

            if foodStore.usedByCategory.isEmpty {
                Text("Nothing used yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(PremiumTheme.secondaryText)
            } else {
                Chart(foodStore.usedByCategory) { stat in
                    BarMark(
                        x: .value("Category", stat.category.rawValue),
                        y: .value("Items used", stat.count)
                    )
                    .foregroundStyle(PremiumTheme.olive)
                    .cornerRadius(6)
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(PremiumTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(PremiumTheme.border, lineWidth: 1)
        )
    }
}



#Preview("With data") {
    let store = FoodStore()
    store.history = []
    store.addDemoItems()

    let carrot = store.foodItems[0]
    let milk = store.foodItems[1]
    store.markAsUsed(carrot)
    store.markAsWasted(milk)

    return NavigationStack {
        ImpactView()
    }
    .environmentObject(store)
}

#Preview("Empty") {
    let store = FoodStore()
    store.history = []

    return NavigationStack {
        ImpactView()
    }
    .environmentObject(store)
}
