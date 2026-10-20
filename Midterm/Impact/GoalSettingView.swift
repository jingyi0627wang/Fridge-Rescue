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

    private enum Style {
        static let background = Color(red: 0.985, green: 0.992, blue: 0.970)
        static let green = Color(red: 0.53, green: 0.89, blue: 0.36)
        static let softGreen = Color(red: 0.931, green: 0.976, blue: 0.869)
        static let darkGreen = Color(red: 0.22, green: 0.49, blue: 0.19)
        static let brown = Color(red: 0.34, green: 0.27, blue: 0.22)
        static let secondary = Color(red: 0.50, green: 0.48, blue: 0.41)
    }

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
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {

                    Text("1. Pick a goal")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(Style.brown)

                    ForEach(GoalType.allCases) { type in
                        typeCard(type)
                    }

                    Text("2. Choose your target")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundStyle(Style.brown)
                        .padding(.top, 6)

                    targetPicker

                    // Live preview of the goal sentence
                    HStack(spacing: 10) {
                        Image(systemName: "flag.checkered")
                        Text(selected.headline(target))
                    }
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Style.darkGreen)
                    .frame(maxWidth: .infinity)
                    .padding(16)
                    .background(Style.softGreen, in: RoundedRectangle(cornerRadius: 18))

                    if hasGoal {
                        Button("Remove goal", role: .destructive) {
                            goalTypeRaw = ""
                            dismiss()
                        }
                        .frame(maxWidth: .infinity)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                }
                .padding(20)
            }
            .background(Style.background.ignoresSafeArea())
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
                    .fontWeight(.bold)
                }
            }
        }
    }

    private func typeCard(_ type: GoalType) -> some View {
        let isSelected = type == selected

        return Button {
            if selected != type {
                selected = type
                target = type.defaultTarget
            }
        } label: {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: type.icon)
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Style.darkGreen : Style.secondary)
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text(type.title)
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundStyle(Style.brown)
                    Text(type.explanation)
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Style.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 0)

                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isSelected ? Style.darkGreen : Style.secondary.opacity(0.5))
            }
            .padding(16)
            .background(isSelected ? Style.softGreen : .white, in: RoundedRectangle(cornerRadius: 18))
            .overlay(
                RoundedRectangle(cornerRadius: 18)
                    .stroke(isSelected ? Style.green : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var targetPicker: some View {
        HStack(spacing: 18) {
            stepButton("minus", enabled: target > selected.range.lowerBound) {
                target = max(target - selected.step, selected.range.lowerBound)
            }

            VStack(spacing: 2) {
                Text(selected == .saveMoney ? "$\(target)" : "\(target)")
                    .font(.system(size: 44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Style.brown)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                Text(selected.targetLabel(target))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Style.secondary)
            }
            .frame(maxWidth: .infinity)

            stepButton("plus", enabled: target < selected.range.upperBound) {
                target = min(target + selected.step, selected.range.upperBound)
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 18))
        .animation(.snappy, value: target)
    }

    private func stepButton(_ icon: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(enabled ? Style.darkGreen : Style.secondary.opacity(0.4))
                .frame(width: 48, height: 48)
                .background(Style.softGreen, in: Circle())
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
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
