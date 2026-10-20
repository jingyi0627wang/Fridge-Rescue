import SwiftUI
import PhotosUI
import UIKit

// MARK: - Add Food tab
// Clear order, top to bottom:
//   1. The food: picture (drawing or your own photo) + name
//   2. Shortcuts: Scan, the ingredient list, and Recent foods
//   3. Details: category, amount, price, bought date
// "Next" goes to the expiration date; after "Add to Fridge" the page resets.

struct AddFoodView: View {
    @ObservedObject var store: FoodStore

    @State private var presets: [IngredientPreset] = []
    @State private var lastAutoFilledName = ""

    @State private var name = ""
    @State private var category: FoodCategory = .other
    @State private var quantity = 1
    @State private var priceText = ""
    @State private var addedDate = Date()
    @FocusState private var nameFocused: Bool
    @FocusState private var priceFocused: Bool

    // Optional photo (shown instead of the drawing)
    @State private var photoData: Data?
    @State private var photoItem: PhotosPickerItem?
    @State private var showPhotoOptions = false
    @State private var showLibrary = false
    @State private var showCamera = false

    @State private var showScanner = false
    @State private var isLookingUp = false
    @State private var scanned: ScannedFood?
    @State private var scanMessage: String?

    @State private var showConfirm = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    /// True when we have no drawing for this name (shows the mystery icon).
    private var isUnknownFood: Bool {
        !trimmedName.isEmpty && FoodIconNames.assetName(for: trimmedName) == nil
    }

    private var photo: UIImage? { photoData.flatMap { UIImage(data: $0) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header
                foodCard
                shortcutButtons
                scanStatus
                recentRow
                GameSectionHeader(title: "Details")
                detailsCard
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 24)
        }
        .gameBackground()
        .tint(Game.greenDark)
        .scrollDismissesKeyboard(.immediately)
        .toolbar(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    nameFocused = false
                    priceFocused = false
                }
                .fontWeight(.semibold)
            }
        }
        .safeAreaInset(edge: .bottom) { nextButton }
        .navigationDestination(isPresented: $showConfirm) {
            ExpirationConfirmView(draft: makeDraft(), store: store) {
                showConfirm = false
                resetForm()
            }
        }
        .onAppear {
            if presets.isEmpty { presets = IngredientPresetService.shared.loadPresets() }
        }
        .onChange(of: name) { autoFillFromPreset() }
        .onChange(of: photoItem) {
            guard let photoItem else { return }
            Task {
                if let data = try? await photoItem.loadTransferable(type: Data.self) {
                    photoData = data
                }
                self.photoItem = nil
            }
        }
        .confirmationDialog("Food Photo", isPresented: $showPhotoOptions, titleVisibility: .hidden) {
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                Button("Take Photo") { showCamera = true }
            }
            Button("Choose from Library") { showLibrary = true }
            if photoData != nil {
                Button("Remove Photo", role: .destructive) { photoData = nil }
            }
        }
        .photosPicker(isPresented: $showLibrary, selection: $photoItem, matching: .images)
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker(imageData: $photoData).ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showScanner) {
            ScannerScreen { result in handle(result) }
        }
    }

    // MARK: - Header (same style as Fridge, Today and Recipes)

    private var header: some View {
        HStack(alignment: .center) {
            Text("Add Food")
                .font(.game(32, .bold, relativeTo: .largeTitle))
                .foregroundStyle(Game.brown)
            Spacer(minLength: 8)
            if !trimmedName.isEmpty || photoData != nil {
                Button("Clear", action: resetForm)
                    .buttonStyle(.chunky(.white, small: true, fullWidth: false))
            }
        }
        .frame(height: 44)
        .padding(.top, 12)
    }

    // MARK: - 1. The food (picture + name)

    private var foodCard: some View {
        HStack(spacing: 14) {
            Button {
                nameFocused = false
                showPhotoOptions = true
            } label: {
                ZStack(alignment: .bottomTrailing) {
                    FreshlingAvatar(category: category,
                                    name: trimmedName.isEmpty ? nil : trimmedName,
                                    size: 76, showsStatus: false, photo: photo)
                    Image(systemName: "camera.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 26, height: 26)
                        .background(Game.greenDark, in: Circle())
                        .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(photoData == nil ? "Add photo" : "Change photo")

            VStack(alignment: .leading, spacing: 6) {
                TextField("Food name", text: $name)
                    .font(.game(22, .bold))
                    .foregroundStyle(Game.brown)
                    .textInputAutocapitalization(.words)
                    .focused($nameFocused)
                    .submitLabel(.done)
                    .onSubmit { nameFocused = false }

                Rectangle()
                    .fill(nameFocused ? Game.greenDark : Game.edge)
                    .frame(height: 2)

                Group {
                    if isUnknownFood && photoData == nil {
                        Button {
                            showPhotoOptions = true
                        } label: {
                            Label("Add a photo", systemImage: "camera")
                        }
                        .foregroundStyle(Game.greenDark)
                    } else if trimmedName.isEmpty {
                        Text("e.g. Carrot, Milk, Leftover pasta")
                            .foregroundStyle(Game.brownSoft)
                    } else {
                        CategoryLabel(category: category)
                            .foregroundStyle(Game.brownSoft)
                    }
                }
                .font(.game(13, .medium))
                .frame(height: 18, alignment: .leading)
            }
        }
        .gameCard()
    }

    // MARK: - 2. Shortcuts

    private var shortcutButtons: some View {
        HStack(spacing: 10) {
            Button {
                scanMessage = nil
                showScanner = true
            } label: {
                Label {
                    Text("Scan")
                } icon: {
                    Image("IconScan").resizable().scaledToFit().frame(width: 20, height: 20)
                }
            }
            .buttonStyle(.chunky(.white, small: true))
            .disabled(!BarcodeScannerView.isSupported || isLookingUp)

            Menu {
                ForEach(presets) { preset in
                    Button {
                        name = preset.name
                    } label: {
                        FreshMenuLabel(title: preset.name,
                                       symbol: FoodIcon.symbol(for: preset.name, category: preset.category))
                    }
                }
            } label: {
                Label("Food List", systemImage: "list.bullet")
                    .frame(maxWidth: .infinity)
            }
            .menuStyle(.button)
            .buttonStyle(.chunky(.white, small: true))
            .disabled(presets.isEmpty)
        }
    }

    @ViewBuilder
    private var scanStatus: some View {
        if isLookingUp {
            HStack(spacing: 8) {
                ProgressView()
                Text("Looking up product…")
            }
            .font(.game(14, .medium))
            .foregroundStyle(Game.brownSoft)
        } else if let scanned {
            Label(scanned.detail.isEmpty ? scanned.name : "\(scanned.name) · \(scanned.detail)",
                  systemImage: "checkmark.circle.fill")
                .font(.game(14, .medium))
                .foregroundStyle(Game.greenDark)
                .lineLimit(1)
        } else if let scanMessage {
            Text(scanMessage)
                .font(.game(14, .medium))
                .foregroundStyle(Game.brownSoft)
        }
    }

    // MARK: Recent (one row)

    @ViewBuilder
    private var recentRow: some View {
        let recent = store.recentAdds()
        if !recent.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                GameSectionHeader(title: "Recent")
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(recent) { suggestion in
                            Button {
                                apply(suggestion)
                            } label: {
                                suggestionChip(suggestion)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
                .scrollClipDisabled()
            }
        }
    }

    private func suggestionChip(_ suggestion: QuickAddSuggestion) -> some View {
        let isSelected = trimmedName.lowercased() == suggestion.name.lowercased()
        return HStack(spacing: 6) {
            FreshlingAvatar(category: suggestion.category, name: suggestion.name, size: 28, showsStatus: false)
            Text(suggestion.name)
                .font(.game(14, .semibold))
                .foregroundStyle(Game.brown)
                .lineLimit(1)
        }
        .padding(.leading, 6)
        .padding(.trailing, 12)
        .frame(height: 40)
        .background(isSelected ? Game.mint : Game.card, in: Capsule())
        .overlay(Capsule().strokeBorder(isSelected ? Game.greenDark : Game.edge, lineWidth: 2))
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
        FreshlingsHaptics.light()
    }

    // MARK: - 3. Details (one compact card, equal-height rows)

    private var detailsCard: some View {
        VStack(spacing: 0) {
            detailRow("Category") {
                Picker("Category", selection: $category) {
                    ForEach(FoodCategory.allCases, id: \.self) { category in
                        CategoryLabel(category: category).tag(category)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
            }
            DashedDivider()
            detailRow(unitLabel) {
                HStack(spacing: 12) {
                    roundButton("minus", disabled: quantity <= 1) { quantity -= 1 }
                    Text("\(quantity)")
                        .font(.game(18, .bold))
                        .monospacedDigit()
                        .frame(minWidth: 24)
                    roundButton("plus", disabled: quantity >= 99) { quantity += 1 }
                }
            }
            DashedDivider()
            detailRow("Price each") {
                HStack(spacing: 2) {
                    Text(Locale.current.currencySymbol ?? "$")
                        .foregroundStyle(Game.brownSoft)
                    TextField("0.00", text: $priceText)
                        .keyboardType(.decimalPad)
                        .focused($priceFocused)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 70)
                }
            }
            DashedDivider()
            detailRow("Bought") {
                DatePicker("Bought", selection: $addedDate, in: ...Date(), displayedComponents: .date)
                    .labelsHidden()
            }
        }
        .font(.game(16, .medium))
        .foregroundStyle(Game.brown)
        .gameCard(padding: 0)
    }

    private func detailRow<Trailing: View>(_ title: LocalizedStringKey,
                                           @ViewBuilder trailing: () -> Trailing) -> some View {
        HStack {
            Text(title)
            Spacer(minLength: 8)
            trailing()
        }
        .padding(.horizontal, 14)
        .frame(height: 54)
    }

    private func roundButton(_ symbol: String, disabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 13, weight: .bold))
                .frame(width: 30, height: 30)
                .background(Game.mint, in: Circle())
                .foregroundStyle(Game.greenDark)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.4 : 1)
    }

    private var currentPreset: IngredientPreset? {
        PresetMatcher.find(trimmedName, in: presets)
    }

    /// "Amount" or e.g. "Bunches" so users know what 1 means.
    private var unitLabel: LocalizedStringKey {
        guard let unit = currentPreset?.unit, unit != "each" else { return "Amount" }
        return "Amount (\(unit))"
    }

    // MARK: - Next (button at the bottom)

    private var nextButton: some View {
        Button {
            nameFocused = false
            priceFocused = false
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
        nameFocused = false
        priceFocused = false
        name = ""
        category = .other
        quantity = 1
        priceText = ""
        addedDate = Date()
        photoData = nil
        scanned = nil
        scanMessage = nil
        lastAutoFilledName = ""
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
                scanMessage = "Couldn't find code \(code). Type the name instead."
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
        var draft = FoodDraft(
            name: trimmedName,
            category: category,
            quantity: quantity,
            addedDate: addedDate,
            estimatedValue: Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0,
            preset: PresetMatcher.find(trimmedName, in: presets),
            fromScan: scanned?.name == trimmedName
        )
        draft.photoData = photoData
        return draft
    }
}

#Preview {
    NavigationStack {
        AddFoodView(store: FoodStore())
    }
}
