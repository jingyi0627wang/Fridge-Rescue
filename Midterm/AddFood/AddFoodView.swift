import SwiftUI



// Add Food is a normal tab page (like Fridge and Today), not a pop-up.

// MainTabView puts it in its own NavigationStack. After "Add to Fridge"

// the page resets for the next item and the bottom bar confirms (with Undo).

struct AddFoodView: View {

    @ObservedObject var store: FoodStore



    // Freshlings page style (same palette as Home / Today)

    private enum Style {

        static let background = Color(red: 0.985, green: 0.992, blue: 0.970)

        static let green = Color(red: 0.53, green: 0.89, blue: 0.36)

        static let darkGreen = Color(red: 0.22, green: 0.49, blue: 0.19)

        static let brown = Color(red: 0.34, green: 0.27, blue: 0.22)

        static let secondary = Color(red: 0.40, green: 0.37, blue: 0.32)

        static let softGreen = Color(red: 0.931, green: 0.976, blue: 0.869)

    }



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

            headerSection

            scanSection

            quickAddSection

            detailsSection

            amountSection

        }

        .scrollContentBackground(.hidden)

        .background(Style.background.ignoresSafeArea())

        .tint(Style.darkGreen)

        .scrollDismissesKeyboard(.immediately)

        .toolbar {

            ToolbarItemGroup(placement: .keyboard) {

                Spacer()



                Button("Done") {

                    keyboardFocused = false

                }

                .fontWeight(.semibold)

            }

        }

        // Same as the other tabs: custom header instead of a navigation bar.

        .toolbar(.hidden, for: .navigationBar)

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



    // MARK: - Header (matches Home / Today)



    private var headerSection: some View {

        Section {

            HStack(alignment: .center, spacing: 12) {

                VStack(alignment: .leading, spacing: 6) {

                    Text("ADD FOOD")

                        .font(.system(size: 12, weight: .bold, design: .rounded))

                        .tracking(1.5)

                        .foregroundStyle(Style.darkGreen)

                    Text("Add a Freshling")

                        .font(.system(size: 32, weight: .heavy, design: .rounded))

                        .foregroundStyle(Style.brown)

                    Text("Scan it, pick a favorite, or type it in.")

                        .font(.system(size: 14, weight: .medium, design: .rounded))

                        .foregroundStyle(Style.secondary)

                }

                Spacer(minLength: 4)

                if !trimmedName.isEmpty {

                    Button("Clear", action: resetForm)

                        .font(.system(size: 13, weight: .bold, design: .rounded))

                        .foregroundStyle(Style.darkGreen)

                        .padding(.horizontal, 12)

                        .padding(.vertical, 7)

                        .background(Style.softGreen, in: Capsule())

                        .buttonStyle(.plain)

                }

            }

            .listRowBackground(Color.clear)

            .listRowInsets(EdgeInsets(top: 8, leading: 4, bottom: 4, trailing: 4))

        }

    }



    // MARK: - Next (big button at the bottom)



    private var nextButton: some View {

        Button {

            keyboardFocused = false
            showConfirm = true

        } label: {

            HStack {

                Text(trimmedName.isEmpty ? "Enter a food to continue" : "Next: Expiration Date")

                if !trimmedName.isEmpty { Image(systemName: "arrow.right") }

            }

            .font(.system(size: 17, weight: .bold, design: .rounded))

            .foregroundStyle(trimmedName.isEmpty ? Style.secondary : Style.darkGreen)

            .frame(maxWidth: .infinity)

            .padding(.vertical, 16)

            .background(trimmedName.isEmpty ? Style.softGreen : Style.green, in: Capsule())

        }

        .buttonStyle(.plain)

        .disabled(trimmedName.isEmpty)

        .padding(.horizontal, 20)

        .padding(.vertical, 10)

        .background(Style.background.opacity(0.95))

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



    private var scanSection: some View {

        Section {

            Button {

                scanMessage = nil

                showScanner = true

            } label: {

                Label {
                    Text("Scan Barcode or Produce Sticker")
                } icon: {
                    Image("IconScan")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 26)
                }

                    .frame(maxWidth: .infinity)

            }

            .buttonStyle(.borderedProminent)

            .disabled(!BarcodeScannerView.isSupported || isLookingUp)

            .listRowBackground(Color.clear)

            .listRowInsets(EdgeInsets())



            if isLookingUp {

                HStack(spacing: 10) {

                    ProgressView()

                    Text("Looking up product…").foregroundStyle(Style.secondary)

                }

            } else if let scanned {

                VStack(alignment: .leading, spacing: 2) {

                    Label(scanned.name, systemImage: "checkmark.circle.fill")

                        .font(.headline)

                        .foregroundStyle(.green)

                    if !scanned.detail.isEmpty {

                        Text(scanned.detail)

                            .font(.subheadline)

                            .foregroundStyle(Style.secondary)

                    }

                }

            } else if let scanMessage {

                Text(scanMessage).foregroundStyle(Style.secondary)

            }

        } footer: {

            if BarcodeScannerView.isSupported {

                Text("Packaged food: scan the barcode. Fruit & vegetables: scan the 4-digit number on the sticker.")
                    .foregroundStyle(Style.secondary)

            } else {

                Text("Scanning needs a real iPhone. Type the food below instead.")
                    .foregroundStyle(Style.secondary)

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
                    .foregroundStyle(Style.brown)
                    .fontWeight(.semibold)

            } footer: {

                Text("Fills in the name, amount and the price you paid last time. You can still change them.")
                    .foregroundStyle(Style.secondary)

            }

        }

    }



    private func suggestionRow(_ title: String, icon: String,

                               items: [QuickAddSuggestion], showsCount: Bool) -> some View {

        VStack(alignment: .leading, spacing: 8) {

            Label(title, systemImage: icon)

                .font(.caption.weight(.semibold))

                .foregroundStyle(Style.secondary)



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

            HStack(spacing: 5) {
                FoodIconView(name: suggestion.name, category: suggestion.category, size: 20)
                Text(suggestion.name)
                    .lineLimit(1)
            }
                .font(.subheadline.weight(.semibold))

            Text(detail)

                .font(.caption2)

                .foregroundStyle(Style.secondary)

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

        Section {

            HStack {

                TextField("", text: $name, prompt: Text("Food name (e.g. Carrot)").foregroundColor(Style.secondary))
                    .foregroundStyle(Style.brown)

                    .textInputAutocapitalization(.words)

                    .focused($keyboardFocused)

                    .submitLabel(.done)

                    .onSubmit {

                        keyboardFocused = false

                    }



                if !presets.isEmpty {

                    Menu {

                        ForEach(presets) { preset in

                            Button {
                                name = preset.name
                            } label: {
                                Label {
                                    Text(preset.name)
                                } icon: {
                                    FoodIcon.menuImage(FoodIcon.assetName(for: preset.name, category: preset.category))
                                }
                            }

                        }

                    } label: {

                        Image(systemName: "list.bullet.circle")

                            .font(.title3)

                    }

                }

            }


                Picker("Category", selection: $category) {
                    ForEach(
                        Array(FoodCategory.allCases.enumerated()),
                        id: \.offset
                    ) { _, category in
                        Label {
                            Text(category.rawValue)
                        } icon: {
                            FoodIcon.menuImage(category.iconAsset)
                        }
                            .tag(category)
                    }
                }


            DatePicker("Bought on", selection: $addedDate, in: ...Date(), displayedComponents: .date)
                .foregroundStyle(Style.brown)

        } header: {
            Text("Details")
                .foregroundStyle(Style.brown)
                .fontWeight(.semibold)
        }

    }



    private var amountSection: some View {

        Section {

            Stepper("Quantity: \(quantity)\(unitSuffix)", value: $quantity, in: 1...99)
                .foregroundStyle(Style.brown)



            HStack {

                Text("Price per unit")
                    .foregroundStyle(Style.brown)

                Spacer()

                Text(Locale.current.currencySymbol ?? "$").foregroundStyle(Style.secondary)

                TextField("", text: $priceText, prompt: Text("0.00").foregroundColor(Style.secondary))
                    .foregroundStyle(Style.brown)

                    .keyboardType(.decimalPad)

                    .focused($keyboardFocused)

                    .multilineTextAlignment(.trailing)

                    .frame(maxWidth: 100)

            }

        } header: {

            Text("Amount & Price")
                .foregroundStyle(Style.brown)
                .fontWeight(.semibold)

        } footer: {

            Text("Enter the price of ONE \(currentPreset?.unit ?? "unit"). Money saved = price × quantity.")
                .foregroundStyle(Style.secondary)

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

