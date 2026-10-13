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
            Stepper("Quantity: \(quantity)", value: $quantity, in: 1...99)

            HStack {
                Text("Price")
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
            Text("Price is used to calculate money saved on the Impact page.")
        }
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
