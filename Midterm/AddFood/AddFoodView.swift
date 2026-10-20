// ------------------------------------------------------------
// Add Food page: first version by Gladys Yu (manual entry, autofill, scanner)
// Later team edits included
// ------------------------------------------------------------

import SwiftUI

// MARK: - Add Food tab
// A normal tab page (like Fridge and Today), not a pop-up.
// Scan, pick from Quick Add or the ingredient list, or type it in.
// "Next" goes to the expiration date; after "Add to Fridge" the page resets
// for the next item and the bottom bar confirms (with Undo).

struct AddFoodView: View {
    @ObservedObject var store: FoodStore

    @State private var presets: [IngredientPreset] = []
    @State private var lastAutoFilledName = ""

    @State private var name = ""
    @State private var category: FoodCategory = .other
    @State private var quantity = 1
    @State private var priceText = ""
    @State private var addedDate = Date()
    @FocusState private var keyboardFocused: Bool

    @State private var showScanner = false
    @State private var isLookingUp = false
    @State private var scanned: ScannedFood?
    @State private var scanMessage: String?

    @State private var showConfirm = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        Form {
            scanSection
            quickAddSection
            detailsSection
            amountSection
        }
        .font(.game(16, .medium))
        .foregroundStyle(Game.brown)
        .gameBackground()
        .tint(Game.greenDark)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle("Add a Freshling")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !trimmedName.isEmpty {
                    Button("Clear", action: resetForm)
                }
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    keyboardFocused = false
                }
                .fontWeight(.semibold)
            }
        }
        .safeAreaInset(edge: .bottom) { nextButton }
        .navigationDestination(isPresented: $showConfirm) {
            ExpirationConfirmView(draft: makeDraft(), store: store) {
                // Saved: go back to a fresh, empty Add page.
                showConfirm = false
                resetForm()
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

    // MARK: - Next (button at the bottom)

    private var nextButton: some View {
        Button {
            keyboardFocused = false
            showConfirm = true
        } label: {
            Text(trimmedName.isEmpty ? "Enter a Food to Continue" : "Next: Expiration Date")
        }
        .buttonStyle(.chunky(.green))
        .disabled(trimmedName.isEmpty)
        .padding(.horizontal, 18)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(Game.cream.opacity(0.97).ignoresSafeArea(edges: .bottom))
    }

    private func resetForm() {
        keyboardFocused = false
        name = ""
        category = .other
        quantity = 1
        priceText = ""
        addedDate = Date()
        scanned = nil
        scanMessage = nil
        lastAutoFilledName = ""
    }

    // MARK: - Scan

    private var scanSection: some View {
        Section {
            Button {
                scanMessage = nil
                showScanner = true
            } label: {
                Label("Scan Barcode or Sticker", systemImage: "barcode.viewfinder")
            }
            .buttonStyle(.chunky(.orange))
            .disabled(!BarcodeScannerView.isSupported || isLookingUp)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0))

            if isLookingUp {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Looking up product…").foregroundStyle(.secondary)
                }
            } else if let scanned {
                VStack(alignment: .leading, spacing: 2) {
                    Label(scanned.name, systemImage: "checkmark.circle.fill")
                        .foregroundStyle(Color.brand)
                    if !scanned.detail.isEmpty {
                        Text(scanned.detail)
                            .font(.game(14, .medium))
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
                    suggestionRow("Usually", items: usual, showsCount: true)
                }
                suggestionRow("Recent", items: recent, showsCount: false)
            } header: {
                Text("Quick Add")
            } footer: {
                Text("Fills in the name, amount and the price you paid last time. You can still change them.")
            }
        }
    }

    private func suggestionRow(_ title: LocalizedStringKey,
                               items: [QuickAddSuggestion], showsCount: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.game(13, .medium))
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

        return HStack(spacing: 8) {
            FreshlingAvatar(category: suggestion.category, name: suggestion.name, size: 30, showsStatus: false)
            VStack(alignment: .leading, spacing: 1) {
                Text(suggestion.name)
                    .font(.game(14, .semibold))
                    .lineLimit(1)
                Text(detail)
                    .font(.game(11, .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(isSelected ? Game.mint : Game.cream,
                    in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isSelected ? Game.greenDark : Game.edge, lineWidth: 2)
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

    // MARK: - Details

    private var detailsSection: some View {
        Section("Details") {
            HStack {
                TextField("Food name (e.g. Carrot)", text: $name)
                    .textInputAutocapitalization(.words)
                    .focused($keyboardFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        keyboardFocused = false
                    }

                // Common ingredients list
                if !presets.isEmpty {
                    Menu {
                        ForEach(presets) { preset in
                            Button {
                                name = preset.name
                            } label: {
                                Label(preset.name, systemImage: preset.category.symbolName)
                            }
                        }
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                    .accessibilityLabel("Common ingredients")
                }
            }

            Picker("Category", selection: $category) {
                ForEach(FoodCategory.allCases, id: \.self) { category in
                    Label(category.displayName, systemImage: category.symbolName)
                        .tag(category)
                }
            }

            DatePicker("Bought on", selection: $addedDate, in: ...Date(), displayedComponents: .date)
        }
    }

    // MARK: - Amount & price

    private var amountSection: some View {
        Section {
            Stepper("Quantity: \(quantity)\(unitSuffix)", value: $quantity, in: 1...99)

            HStack {
                Text("Price per unit")
                Spacer()
                Text(Locale.current.currencySymbol ?? "$").foregroundStyle(.secondary)
                TextField("0.00", text: $priceText)
                    .keyboardType(.decimalPad)
                    .focused($keyboardFocused)
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

    // MARK: - Scanning

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
                FreshlingsHaptics.success()
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
    NavigationStack {
        AddFoodView(store: FoodStore())
    }
}
