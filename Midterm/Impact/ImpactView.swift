//
//  ImpactView.swift
//  Midterm
//
//  Created by Rumik He on 10/13/26.
//

import SwiftUI
import Charts

// Same Freshlings palette as HomeView / FoodDetailView.
private enum ImpactStyle {
    static let background = Color(red: 0.985, green: 0.992, blue: 0.970)
    static let surface = Color.white
    static let olive = Color(red: 0.22, green: 0.49, blue: 0.19)        // dark green accent
    static let primaryText = Color(red: 0.34, green: 0.27, blue: 0.22)  // brown
    static let secondaryText = Color(red: 0.50, green: 0.48, blue: 0.41)
    static let border = Color(red: 0.82, green: 0.90, blue: 0.77).opacity(0.55)
    static let softGreen = Color(red: 0.931, green: 0.976, blue: 0.869)
    static let wasted = Color(red: 0.96, green: 0.56, blue: 0.29)       // orange
}

struct ImpactView: View {

    @EnvironmentObject var foodStore: FoodStore

    // Goal settings (see GoalSettingView). Empty type = no goal yet.
    @AppStorage("goalType") private var goalTypeRaw = ""
    @AppStorage("goalTarget") private var goalTarget = 5

    @State private var showGoalSheet = false
    @State private var showInfo = false

    private var goalType: GoalType? { GoalType(rawValue: goalTypeRaw) }

    private var hasNoHistory: Bool {
        foodStore.usedItems.isEmpty && foodStore.wastedItems.isEmpty
    }

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        ZStack {
            ImpactStyle.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    streakCard
                    goalCard

                    if hasNoHistory {
                        emptyState
                    } else {
                        statGrid
                        useRateCard
                        weeklyChartCard
                        categoryChartCard
                        historyLink
                    }
                }
                .padding(20)
            }
        }
        .navigationTitle("Impact")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("How we calculate")
            }
        }
        .sheet(isPresented: $showGoalSheet) {
            GoalSettingView(goalTypeRaw: $goalTypeRaw, goalTarget: $goalTarget)
        }
        .sheet(isPresented: $showInfo) {
            ImpactInfoView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "leaf")
                .font(.system(size: 34))
                .foregroundStyle(ImpactStyle.olive)
            Text("No impact yet")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(ImpactStyle.primaryText)
            Text("Use your first item to see money and carbon saved.")
                .font(.system(size: 13, design: .rounded))
                .foregroundStyle(ImpactStyle.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(ImpactStyle.surface, in: RoundedRectangle(cornerRadius: 18))
    }

    private var statGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            statCard(
                title: "Money saved",
                value: foodStore.moneySaved.formatted(.currency(code: "USD")),
                icon: "dollarsign.circle"
            )
            statCard(
                title: "CO₂e saved",
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
                .foregroundStyle(ImpactStyle.olive)

            Text(value)
                .font(.system(size: 24, weight: .heavy, design: .rounded))
                .foregroundStyle(ImpactStyle.primaryText)

            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(ImpactStyle.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(ImpactStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ImpactStyle.border, lineWidth: 1)
        )
    }



    private var useRateCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Use rate")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ImpactStyle.primaryText)
                Spacer()
                Text("\(Int(foodStore.useRate * 100))%")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ImpactStyle.olive)
            }

            ProgressView(value: foodStore.useRate)
                .tint(ImpactStyle.olive)

            Text("Share of finished items you used instead of throwing away.")
                .font(.system(size: 12))
                .foregroundStyle(ImpactStyle.secondaryText)
        }
        .padding(16)
        .background(ImpactStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ImpactStyle.border, lineWidth: 1)
        )
    }



    // MARK: - Streak

    private var streakCard: some View {
        HStack(spacing: 14) {
            Text(foodStore.rescueStreak > 0 ? "🔥" : "🌱")
                .font(.system(size: 30))
                .frame(width: 54, height: 54)
                .background(ImpactStyle.surface, in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 3) {
                Text(foodStore.rescueStreak == 1 ? "1-day streak" : "\(foodStore.rescueStreak)-day streak")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundStyle(ImpactStyle.primaryText)
                Text(foodStore.rescueStreak > 0
                     ? "Days in a row you used food. Keep it going!"
                     : "Use one item today to start a streak.")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(ImpactStyle.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(ImpactStyle.softGreen, in: RoundedRectangle(cornerRadius: 18))
    }

    // MARK: - Goal

    @ViewBuilder
    private var goalCard: some View {
        if let goalType {
            activeGoalCard(goalType)
        } else {
            Button {
                showGoalSheet = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: "flag.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(ImpactStyle.olive)
                        .frame(width: 44, height: 44)
                        .background(ImpactStyle.softGreen, in: Circle())
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Set your first goal")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundStyle(ImpactStyle.primaryText)
                        Text("Use more, waste less, or save money.")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundStyle(ImpactStyle.secondaryText)
                    }
                    Spacer()
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(ImpactStyle.olive)
                }
                .padding(16)
                .background(ImpactStyle.surface, in: RoundedRectangle(cornerRadius: 18))
                .overlay(RoundedRectangle(cornerRadius: 18).stroke(ImpactStyle.border, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    private func activeGoalCard(_ type: GoalType) -> some View {
        let progress = goalProgress(type)

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Label(type.title.uppercased(), systemImage: type.icon)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(ImpactStyle.olive)
                    Text(type.headline(goalTarget))
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(ImpactStyle.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Button("Edit") { showGoalSheet = true }
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(ImpactStyle.olive)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(ImpactStyle.softGreen, in: Capsule())
            }

            ProgressView(value: progress.fraction)
                .tint(progress.isBad ? ImpactStyle.wasted : ImpactStyle.olive)

            HStack {
                Text(progress.current)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(ImpactStyle.primaryText)
                Spacer()
                Text(progress.status)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundStyle(progress.isBad ? ImpactStyle.wasted : ImpactStyle.olive)
            }
        }
        .padding(16)
        .background(ImpactStyle.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(ImpactStyle.border, lineWidth: 1))
    }

    private struct GoalProgress {
        let fraction: Double
        let current: String
        let status: String
        let isBad: Bool
    }

    private func goalProgress(_ type: GoalType) -> GoalProgress {
        let target = goalTarget
        switch type {
        case .useItems:
            let used = foodStore.usedThisWeek
            return GoalProgress(
                fraction: min(Double(used) / Double(max(target, 1)), 1),
                current: "\(used) of \(target) used",
                status: used >= target ? "Goal reached! 🎉" : "\(target - used) more to go",
                isBad: false
            )
        case .wasteLess:
            let wasted = foodStore.wastedThisWeek
            let over = wasted > target
            return GoalProgress(
                fraction: target == 0 ? (wasted == 0 ? 0 : 1) : min(Double(wasted) / Double(target), 1),
                current: "\(wasted) wasted so far",
                status: over ? "Over by \(wasted - target)" : (wasted == target && target > 0 ? "At your limit" : "On track ✓"),
                isBad: over
            )
        case .saveMoney:
            let saved = foodStore.moneySavedThisMonth
            let goal = Double(target)
            return GoalProgress(
                fraction: min(saved / max(goal, 1), 1),
                current: "\(saved.formatted(.currency(code: "USD"))) of $\(target)",
                status: saved >= goal ? "Goal reached! 🎉" : "\((goal - saved).formatted(.currency(code: "USD"))) to go",
                isBad: false
            )
        }
    }

    // MARK: - Progress over time

    private var weeklyChartCard: some View {
        let stats = foodStore.weeklyStats()

        return VStack(alignment: .leading, spacing: 12) {
            Text("Last 6 weeks")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ImpactStyle.primaryText)

            Chart(stats) { stat in
                BarMark(
                    x: .value("Week", stat.weekStart, unit: .weekOfYear),
                    y: .value("Items", stat.count)
                )
                .foregroundStyle(by: .value("Status", stat.status))
                .cornerRadius(4)
            }
            .chartForegroundStyleScale([
                "Used": ImpactStyle.olive,
                "Wasted": ImpactStyle.wasted
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartLegend(position: .top, alignment: .leading)
            .frame(height: 200)

            Text("Items used vs. wasted each week.")
                .font(.system(size: 12))
                .foregroundStyle(ImpactStyle.secondaryText)
        }
        .padding(16)
        .background(ImpactStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ImpactStyle.border, lineWidth: 1)
        )
    }

    // MARK: - History

    private var historyLink: some View {
        NavigationLink {
            HistoryView()
        } label: {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                Text("View Food History")
                Spacer()
                Text("\(foodStore.history.count)")
                    .foregroundStyle(ImpactStyle.secondaryText)
                Image(systemName: "chevron.right")
            }
            .font(.system(size: 15, weight: .bold, design: .rounded))
            .foregroundStyle(ImpactStyle.olive)
            .padding(17)
            .background(ImpactStyle.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(ImpactStyle.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var categoryChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Used by category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ImpactStyle.primaryText)

            if foodStore.usedByCategory.isEmpty {
                Text("Nothing used yet.")
                    .font(.system(size: 13))
                    .foregroundStyle(ImpactStyle.secondaryText)
            } else {
                Chart(foodStore.usedByCategory) { stat in
                    BarMark(
                        x: .value("Category", stat.category.rawValue),
                        y: .value("Items used", stat.count)
                    )
                    .foregroundStyle(ImpactStyle.olive)
                    .cornerRadius(6)
                }
                .frame(height: 180)
            }
        }
        .padding(16)
        .background(ImpactStyle.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18))
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(ImpactStyle.border, lineWidth: 1)
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
