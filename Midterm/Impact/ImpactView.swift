//
//  ImpactView.swift
//  Freshlings
//

import SwiftUI
import Charts

// MARK: - Impact tab (player profile)
// Your level and XP, money ("coins") and CO₂ saved, streak, weekly goal,
// badges, charts over time, and the food history.

struct ImpactView: View {
    @EnvironmentObject var foodStore: FoodStore

    @AppStorage("username") private var username = ""

    // Goal settings (see GoalSettingView). Empty type = no goal yet.
    @AppStorage("goalType") private var goalTypeRaw = ""
    @AppStorage("goalTarget") private var goalTarget = 5

    @State private var showGoalSheet = false
    @State private var showInfo = false
    @State private var selectedBadge: GameBadge?

    private var goalType: GoalType? { GoalType(rawValue: goalTypeRaw) }

    private var hasNoHistory: Bool {
        foodStore.usedItems.isEmpty && foodStore.wastedItems.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                header
                profileCard
                statGrid
                streakCard

                GameSectionHeader(title: "Weekly Goal")
                goalCard

                GameSectionHeader(title: "Badges", count: foodStore.unlockedBadgeCount)
                badgeGrid

                if !hasNoHistory {
                    GameSectionHeader(title: "Last 6 Weeks")
                    weeklyChart
                    GameSectionHeader(title: "Rescued by Category")
                    categoryChart
                }

                NavigationLink {
                    HistoryView()
                } label: {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                        Text("Food History")
                        Spacer()
                        Text("\(foodStore.history.count)")
                            .foregroundStyle(Game.brownSoft)
                        Image(systemName: "chevron.right")
                            .foregroundStyle(Game.edgeDark)
                    }
                    .font(.game(17, .semibold))
                    .foregroundStyle(Game.brown)
                    .gameCard(padding: 16)
                }
                .buttonStyle(.plain)
                .padding(.top, 8)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .gameBackground()
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showGoalSheet) {
            GoalSettingView(goalTypeRaw: $goalTypeRaw, goalTarget: $goalTarget)
        }
        .sheet(isPresented: $showInfo) {
            ImpactInfoView()
        }
        .alert(item: $selectedBadge) { badge in
            Alert(
                title: Text(badge.title),
                message: Text(badgeMessage(badge)),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private func badgeMessage(_ badge: GameBadge) -> LocalizedStringKey {
        if badge.unlocked { return "Unlocked! \(badge.detail)." }
        return "Locked: \(badge.detail) to unlock it."
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("My Impact")
                .font(.game(32, .bold, relativeTo: .largeTitle))
                .foregroundStyle(Game.brown)
            Spacer()
            Button {
                showInfo = true
            } label: {
                Image(systemName: "info")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(Game.brownSoft)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(.white))
                    .overlay(Circle().strokeBorder(Game.edge, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("How we calculate")
        }
        .padding(.top, 10)
    }

    // MARK: - Profile (level + XP)

    private var profileCard: some View {
        let info = foodStore.levelInfo

        return VStack(spacing: 8) {
            FreshlingMascot(size: 72)
                .overlay(alignment: .bottomTrailing) {
                    Text("\(info.level)")
                        .font(.game(15, .bold))
                        .foregroundStyle(.white)
                        .frame(width: 30, height: 30)
                        .background(Circle().fill(Game.orange))
                        .overlay(Circle().stroke(.white, lineWidth: 3))
                        .offset(x: 8, y: 4)
                }

            Text(username.isEmpty ? "Freshling Keeper" : username)
                .font(.game(24, .bold))
                .foregroundStyle(Game.brown)

            Text("Level \(info.level) · \(Text(LocalizedStringKey(info.title)))")
                .font(.game(15, .medium))
                .foregroundStyle(Game.brownSoft)

            VStack(spacing: 6) {
                HStack {
                    Text("XP")
                        .font(.game(13, .bold))
                        .foregroundStyle(Game.brown)
                    Spacer()
                    Text("\(info.xpIntoLevel) / \(info.xpForLevel)")
                        .font(.game(13, .semibold))
                        .foregroundStyle(Game.brownSoft)
                        .monospacedDigit()
                }
                GameProgressBar(progress: info.progress)
                Text("Rescue food to earn XP. Food with 2 days or less left is worth double!")
                    .font(.game(12, .medium))
                    .foregroundStyle(Game.brownSoft)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.top, 6)
        }
        .frame(maxWidth: .infinity)
        .gameCard(padding: 16)
    }

    // MARK: - Totals

    private var statGrid: some View {
        Grid(horizontalSpacing: 10, verticalSpacing: 10) {
            GridRow {
                statCard(icon: "dollarsign", color: Game.orange,
                         value: foodStore.moneySaved.formatted(.currency(code: "USD")),
                         label: "Coins saved")
                statCard(icon: "leaf.fill", color: Game.greenDark,
                         value: String(format: "%.1f kg", foodStore.carbonSaved),
                         label: "CO₂ saved")
            }
            GridRow {
                statCard(icon: "heart.fill", color: Game.red,
                         value: "\(foodStore.usedCount)",
                         label: "Freshlings rescued")
                statCard(icon: "xmark", color: Game.gray,
                         value: "\(foodStore.wastedCount)",
                         label: "Lost")
            }
        }
    }

    private func statCard(icon: String, color: Color, value: String, label: LocalizedStringKey) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 24, height: 24)
                .background(Circle().fill(color))
            Text(value)
                .font(.game(22, .bold))
                .foregroundStyle(Game.brown)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.game(13, .medium))
                .foregroundStyle(Game.brownSoft)
                .lineLimit(1)
        }
        .gameCard(padding: 14)
    }

    // MARK: - Streak + use rate

    private var streakCard: some View {
        let streak = foodStore.rescueStreak

        return HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(streak > 0 ? Game.red : Game.gray)
                .frame(width: 48, height: 48)
                .background(Circle().fill(streak > 0 ? Game.redSoft : Game.graySoft))

            VStack(alignment: .leading, spacing: 2) {
                if streak == 1 {
                    Text("1-day streak")
                } else {
                    Text("\(streak)-day streak")
                }
                Text(streak > 0
                     ? "Rescue something today to keep it going!"
                     : "Rescue one food today to start a streak.")
                    .font(.game(13, .medium))
                    .foregroundStyle(Game.brownSoft)
            }
            .font(.game(18, .bold))
            .foregroundStyle(Game.brown)

            Spacer(minLength: 0)

            if !hasNoHistory {
                VStack(spacing: 0) {
                    Text(foodStore.useRate, format: .percent.precision(.fractionLength(0)))
                        .font(.game(18, .bold))
                        .foregroundStyle(Game.greenInk)
                    Text("use rate")
                        .font(.game(11, .semibold))
                        .foregroundStyle(Game.brownSoft)
                }
            }
        }
        .gameCard()
    }

    // MARK: - Goal

    @ViewBuilder
    private var goalCard: some View {
        if let goalType {
            let progress = goalProgress(goalType)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    Text(goalType.headline(goalTarget))
                        .font(.game(17, .semibold))
                        .foregroundStyle(Game.brown)
                    Spacer()
                    Button("Edit") { showGoalSheet = true }
                        .font(.game(14, .bold))
                        .foregroundStyle(Game.greenInk)
                }

                GameProgressBar(progress: progress.fraction,
                                color: progress.isBad ? Game.red : Game.green)

                HStack {
                    Text(progress.current)
                        .foregroundStyle(Game.brown)
                    Spacer()
                    Text(progress.status)
                        .foregroundStyle(progress.isBad ? Game.redDark : Game.greenInk)
                }
                .font(.game(14, .semibold))
            }
            .gameCard()
        } else {
            VStack(spacing: 10) {
                Text("Pick a goal: rescue more, waste less, or save money.")
                    .font(.game(15, .medium))
                    .foregroundStyle(Game.brownSoft)
                    .multilineTextAlignment(.center)
                Button("Set a Goal") { showGoalSheet = true }
                    .buttonStyle(.chunky(.green, small: true))
            }
            .frame(maxWidth: .infinity)
            .gameCard()
        }
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
                current: "\(used) / \(target) rescued",
                status: used >= target ? "Goal reached!" : "\(target - used) to go",
                isBad: false
            )
        case .wasteLess:
            let wasted = foodStore.wastedThisWeek
            let over = wasted > target
            return GoalProgress(
                fraction: target == 0 ? (wasted == 0 ? 0 : 1) : min(Double(wasted) / Double(target), 1),
                current: "\(wasted) lost so far",
                status: over ? "Over by \(wasted - target)" : (wasted == target && target > 0 ? "At your limit" : "On track!"),
                isBad: over
            )
        case .saveMoney:
            let saved = foodStore.moneySavedThisMonth
            let goal = Double(target)
            return GoalProgress(
                fraction: min(saved / max(goal, 1), 1),
                current: "\(saved.formatted(.currency(code: "USD"))) of $\(target)",
                status: saved >= goal ? "Goal reached!" : "\((goal - saved).formatted(.currency(code: "USD"))) to go",
                isBad: false
            )
        }
    }

    // MARK: - Badges

    private var badgeGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 14) {
            ForEach(foodStore.badges) { badge in
                Button {
                    selectedBadge = badge
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: badge.unlocked ? badge.icon : "lock.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 56, height: 56)
                            .background(Circle().fill(badge.unlocked ? badge.color : Game.gray))
                            .overlay(Circle().stroke(.white, lineWidth: 3))
                            .background(Circle().fill(Game.edge).offset(y: 4))
                        Text(LocalizedStringKey(badge.title))
                            .font(.game(11, .semibold))
                            .foregroundStyle(badge.unlocked ? Game.brown : Game.brownSoft)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .opacity(badge.unlocked ? 1 : 0.6)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(badge.unlocked ? "\(badge.title), unlocked" : "\(badge.title), locked")
            }
        }
        .gameCard(padding: 14)
    }

    // MARK: - Charts

    private var weeklyChart: some View {
        let stats = foodStore.weeklyStats()

        return VStack(alignment: .leading, spacing: 8) {
            Chart(stats) { stat in
                BarMark(
                    x: .value("Week", stat.weekStart, unit: .weekOfYear),
                    y: .value("Items", stat.count)
                )
                .foregroundStyle(by: .value("Status", stat.status))
                .cornerRadius(5)
            }
            .chartForegroundStyleScale([
                "Used": Game.green,
                "Wasted": Game.red
            ])
            .chartXAxis {
                AxisMarks(values: .stride(by: .weekOfYear)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                }
            }
            .chartLegend(position: .top, alignment: .leading)
            .frame(height: 190)

            Text("Food rescued vs. lost each week.")
                .font(.game(12, .medium))
                .foregroundStyle(Game.brownSoft)
        }
        .gameCard()
    }

    @ViewBuilder
    private var categoryChart: some View {
        if foodStore.usedByCategory.isEmpty {
            Text("Nothing rescued yet.")
                .font(.game(15, .medium))
                .foregroundStyle(Game.brownSoft)
                .gameCard()
        } else {
            Chart(foodStore.usedByCategory) { stat in
                BarMark(
                    x: .value("Category", stat.category.rawValue),
                    y: .value("Items used", stat.count)
                )
                .foregroundStyle(stat.category.freshlingColor)
                .cornerRadius(5)
            }
            .frame(height: 170)
            .gameCard()
        }
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
    .environmentObject(MyRecipeStore())
}

#Preview("Empty") {
    let store = FoodStore()
    store.history = []

    return NavigationStack {
        ImpactView()
    }
    .environmentObject(store)
    .environmentObject(MyRecipeStore())
}
