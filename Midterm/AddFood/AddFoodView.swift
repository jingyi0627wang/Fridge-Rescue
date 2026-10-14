import SwiftUI

struct AddFoodView: View {
    @ObservedObject var store: FoodStore
    @Environment(\.dismiss) private var dismiss

    @State private var presets: [IngredientPreset] = []
    @State private var lastAutoFilledName = ""

    @State private var name = ""
    @State private var category: FoodCategory = .other
    @State private var quantity = 1
    @State private var priceText = ""
    @State private var addedDate = Date()

    @State private var showScanner = false
    @State private var isLookingUp = false
    @State private var scanned: ScannedFood?
    @State private var scanMessage: String?

    @State private var showConfirm = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                scanSection
                quickAddSection
                detailsSection
                amountSection
            }
            .navigationTitle("Add Food")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") { showConfirm = true }
                        .disabled(trimmedName.isEmpty)
                }
            }
            .navigationDestination(isPresented: $showConfirm) {
                ExpirationConfirmView(draft: makeDraft(), store: store) {
                    dismiss()
                }
            }
            .onAppear {
                if presets.isEmpty { presets = IngredientPresetService.shared.loadPresets() }
            }
            .onChange(of: name) { autoFillFromPreset() }
            .fullScreenCover(isPresented: $showScanner) {
                ScannerScreen { result in handle(result) }
            }
        }
    }

    private var scanSection: some View {
        Section {
            Button {
                scanMessage = nil
                showScanner = true
            } label: {
                Label("Scan Barcode or Produce Sticker", systemImage: "barcode.viewfinder")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!BarcodeScannerView.isSupported || isLookingUp)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())

            if isLookingUp {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Looking up product…").foregroundStyle(.secondary)
                }
            } else if let scanned {
                VStack(alignment: .leading, spacing: 2) {
                    Label(scanned.name, systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.green)
                    if !scanned.detail.isEmpty {
                        Text(scanned.detail)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let scanMessage {
                Text(scanMessage).foregroundStyle(.secondary)
            }
        } footer: {
            if BarcodeScannerView.isSupported {
                Text("Packaged food: scan the barcode. Fruit & vegetables: scan the 4-digit number on the sticker.")
            } else {
                Text("Scanning needs a real iPhone. Type the food below instead.")
            }
        }
    }

    // MARK: - Quick Add (Recent / Usually)
    // Tap a food you've added before to fill in its name, category,
    // usual amount and the price you paid last time.

    @ViewBuilder
    private var quickAddSection: some View {
        let recent = store.recentAdds()
        let usual = store.usualAdds()

        if !recent.isEmpty {
            Section {
                if !usual.isEmpty {
                    suggestionRow("Usually", icon: "repeat", items: usual, showsCount: true)
                }
                suggestionRow("Recent", icon: "clock.arrow.circlepath", items: recent, showsCount: false)
            } header: {
                Text("Quick Add")
            } footer: {
                Text("Fills in the name, amount and the price you paid last time. You can still change them.")
            }
        }
    }

    private func suggestionRow(_ title: String, icon: String,
                               items: [QuickAddSuggestion], showsCount: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items) { suggestion in
                        Button {
                            apply(suggestion)
                        } label: {
                            suggestionChip(suggestion, showsCount: showsCount)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.trailing, 16)
            }
        }
        .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 0))
    }

    private func suggestionChip(_ suggestion: QuickAddSuggestion, showsCount: Bool) -> some View {
        let isSelected = trimmedName.lowercased() == suggestion.name.lowercased()
        let price = suggestion.price > 0 ? " · " + suggestion.price.formatted(.currency(code: "USD")) : ""
        let detail = showsCount
            ? "×\(suggestion.quantity) · \(suggestion.timesAdded) times"
            : "×\(suggestion.quantity)\(price) · \(suggestion.lastAdded.formatted(.relative(presentation: .named)))"

        return VStack(alignment: .leading, spacing: 2) {
            Text("\(suggestion.category.addFoodIcon) \(suggestion.name)")
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
            Text(detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(isSelected ? Color.green.opacity(0.18) : Color(.secondarySystemBackground),
                    in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.green : .clear, lineWidth: 1.5)
        )
    }

    private func apply(_ suggestion: QuickAddSuggestion) {
        // Keep the price from last time instead of the preset's default price.
        lastAutoFilledName = PresetMatcher.find(suggestion.name, in: presets)?.name ?? ""
        name = suggestion.name
        category = suggestion.category
        quantity = suggestion.quantity
        priceText = suggestion.price > 0 ? String(format: "%.2f", suggestion.price) : ""
        scanned = nil
        scanMessage = nil
    }

    private var detailsSection: some View {
        Section("Details") {
            HStack {
                TextField("Food name (e.g. Carrot)", text: $name)
                    .textInputAutocapitalization(.words)

                if !presets.isEmpty {
                    Menu {
                        ForEach(presets) { preset in
                            Button("\(preset.category.addFoodIcon) \(preset.name)") {
                                name = preset.name
                            }
                        }
                    } label: {
                        Image(systemName: "list.bullet.circle")
                            .font(.title3)
                    }
                }
            }

            Picker("Category", selection: $category) {
                ForEach(FoodCategory.allCases, id: \.self) { category in
                    Text("\(category.addFoodIcon) \(category.rawValue)").tag(category)
                }
            }

            DatePicker("Bought on", selection: $addedDate, in: ...Date(), displayedComponents: .date)
        }
    }

    private var amountSection: some View {
        Section {
            Stepper("Quantity: \(quantity)\(unitSuffix)", value: $quantity, in: 1...99)

            HStack {
                Text("Price per unit")
                Spacer()
                Text(Locale.current.currencySymbol ?? "$").foregroundStyle(.secondary)
                TextField("0.00", text: $priceText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: 100)
            }
        } header: {
            Text("Amount & Price")
        } footer: {
            Text("Enter the price of ONE \(currentPreset?.unit ?? "unit"). Money saved = price × quantity.")
        }
    }

    private var currentPreset: IngredientPreset? {
        PresetMatcher.find(trimmedName, in: presets)
    }

    /// e.g. " × bunch" so users know what 1 means.
    private var unitSuffix: String {
        guard let unit = currentPreset?.unit, unit != "each" else { return "" }
        return " × \(unit)"
    }

    private func handle(_ result: ScanResult) {
        scanned = nil
        isLookingUp = true
        Task {
            let food: ScannedFood?
            let code: String
            switch result {
            case .barcode(let value):
                code = value
                food = await ProductLookup.lookup(barcode: value)
            case .plu(let value):
                code = value
                food = ProductLookup.lookup(plu: value)
            }
            isLookingUp = false

            if let food {
                scanned = food
                name = food.name
                if food.category != .other { category = food.category }
            } else {
                scanMessage = "Couldn't find code \(code). Type the name below."
            }
        }
    }

    private func autoFillFromPreset() {
        guard let preset = PresetMatcher.find(name, in: presets),
              preset.name != lastAutoFilledName else { return }
        lastAutoFilledName = preset.name
        category = preset.category
        priceText = String(format: "%.2f", preset.estimatedValue)
    }

    private func makeDraft() -> FoodDraft {
        FoodDraft(
            name: trimmedName,
            category: category,
            quantity: quantity,
            addedDate: addedDate,
            estimatedValue: Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0,
            preset: PresetMatcher.find(trimmedName, in: presets),
            fromScan: scanned?.name == trimmedName
        )
    }
}

#Preview {
    AddFoodView(store: FoodStore())
}
