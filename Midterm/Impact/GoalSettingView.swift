import SwiftUI

// MARK: - Goal types

enum GoalType: String, CaseIterable, Identifiable {
    case useItems
    case wasteLess
    case saveMoney

    var id: String { rawValue }

    var title: String {
        switch self {
        case .useItems: return "Use more food"
        case .wasteLess: return "Waste less"
        case .saveMoney: return "Save money"
        }
    }

    var icon: String {
        switch self {
        case .useItems: return "checkmark.circle.fill"
        case .wasteLess: return "trash.slash.fill"
        case .saveMoney: return "dollarsign.circle.fill"
        }
    }

    var explanation: String {
        switch self {
        case .useItems:
            return "Count every item you mark as \"I Used It\" or cook in a recipe. Resets every Monday."
        case .wasteLess:
            return "Set the most items you're OK throwing away. Stay under it to keep the goal. Resets every Monday."
        case .saveMoney:
            return "Adds up the price of everything you used instead of throwing away. Resets on the 1st of each month."
        }
    }

    var range: ClosedRange<Int> {
        switch self {
        case .useItems: return 1...50
        case .wasteLess: return 0...20
        case .saveMoney: return 5...500
        }
    }

    var step: Int { self == .saveMoney ? 5 : 1 }

    var defaultTarget: Int {
        switch self {
        case .useItems: return 5
        case .wasteLess: return 2
        case .saveMoney: return 30
        }
    }

    /// The sentence shown on the Impact card, e.g. "Use 5 items this week".
    func headline(_ target: Int) -> String {
        switch self {
        case .useItems:
            return "Use \(target) \(target == 1 ? "item" : "items") this week"
        case .wasteLess:
            return target == 0
                ? "Waste nothing this week"
                : "Waste no more than \(target) \(target == 1 ? "item" : "items") this week"
        case .saveMoney:
            return "Save $\(target) this month"
        }
    }

    func targetLabel(_ target: Int) -> String {
        switch self {
        case .useItems: return "\(target) \(target == 1 ? "item" : "items") / week"
        case .wasteLess: return "max \(target) / week"
        case .saveMoney: return "$\(target) / month"
        }
    }
}

// MARK: - Set Goal sheet

struct GoalSettingView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var goalTypeRaw: String
    @Binding var goalTarget: Int

    @State private var selected: GoalType
    @State private var target: Int

    init(goalTypeRaw: Binding<String>, goalTarget: Binding<Int>) {
        _goalTypeRaw = goalTypeRaw
        _goalTarget = goalTarget
        let current = GoalType(rawValue: goalTypeRaw.wrappedValue)
        _selected = State(initialValue: current ?? .useItems)
        _target = State(initialValue: current == nil ? GoalType.useItems.defaultTarget : goalTarget.wrappedValue)
    }

    private var hasGoal: Bool { GoalType(rawValue: goalTypeRaw) != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    ForEach(GoalType.allCases) { type in
                        typeRow(type)
                    }
                }

                Section {
                    Stepper(value: $target, in: selected.range, step: selected.step) {
                        Text(selected.targetLabel(target))
                            .monospacedDigit()
                    }
                } header: {
                    Text("Target")
                } footer: {
                    Text(selected.headline(target))
                }

                if hasGoal {
                    Section {
                        Button("Remove Goal", role: .destructive) {
                            goalTypeRaw = ""
                            dismiss()
                        }
                    }
                }
            }
            .font(.game(16, .medium))
            .foregroundStyle(Game.brown)
            .gameBackground()
            .tint(Game.greenDark)
            .navigationTitle(hasGoal ? "Change Goal" : "Set a Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        goalTypeRaw = selected.rawValue
                        goalTarget = target
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func typeRow(_ type: GoalType) -> some View {
        Button {
            if selected != type {
                selected = type
                target = type.defaultTarget
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: type.icon)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(Color.brand)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 3) {
                    Text(type.title)
                        .foregroundStyle(.primary)
                    Text(type.explanation)
                        .font(.game(13, .medium))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                if type == selected {
                    Image(systemName: "checkmark")
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.brand)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - "How is this calculated?" sheet

struct ImpactInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Money saved") {
                    Text("Price per unit × quantity, for every item you used instead of throwing away.")
                }

                Section {
                    Text("For each item you used:")
                    Text("CO₂e per kg × weight of one unit × quantity")
                        .font(.system(.body, design: .monospaced))
                    Text("Example: 1 lb pack of chicken breast = 9.87 kg CO₂e/kg × 0.45 kg ≈ 4.4 kg CO₂e")
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Carbon saved")
                } footer: {
                    Text("When food is thrown away, all the emissions from growing, processing and transporting it are wasted. Using it means those emissions weren't for nothing.")
                }

                Section("Where the numbers come from") {
                    Text("Emissions per kg: Poore, J. & Nemecek, T. (2018). Reducing food's environmental impacts through producers and consumers. Science, 360(6392), 987–992.")
                    Link("View the data on Our World in Data",
                         destination: URL(string: "https://ourworldindata.org/grapher/ghg-per-kg-poore")!)
                    Text("Unit weights (e.g. one carrot ≈ 60 g, a half gallon of milk ≈ 1.9 kg) are typical US grocery sizes. Foods not in our list use an average for their category.")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.game(16, .medium))
            .foregroundStyle(Game.brown)
            .gameBackground()
            .tint(Game.greenDark)
            .navigationTitle("How We Calculate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview("Set Goal") {
    GoalSettingView(goalTypeRaw: .constant(""), goalTarget: .constant(5))
}

#Preview("Info") {
    ImpactInfoView()
}
