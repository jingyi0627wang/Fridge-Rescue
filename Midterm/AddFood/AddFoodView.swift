import SwiftUI
import PhotosUI
import UIKit

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

    @State private var photo: UIImage?
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false

    @State private var suggestions: [FoodSuggestion] = []
    @State private var isRecognizing = false
    @State private var recognitionNote: String?

    @State private var showConfirm = false

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                photoSection
                if photo != nil { aiSection }
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
                    resetForm()
                    dismiss()
                }
            }
            .onAppear {
                if presets.isEmpty { presets = IngredientPresetService.shared.loadPresets() }
            }
            .onChange(of: pickerItem) { loadPickedPhoto() }
            .onChange(of: name) { autoFillFromPreset() }
            .fullScreenCover(isPresented: $showCamera) {
                CameraPicker { image in setPhoto(image) }
                    .ignoresSafeArea()
            }
        }
    }

    private var photoSection: some View {
        Section {
            if let photo {
                Color.clear
                    .frame(height: 220)
                    .overlay {
                        Image(uiImage: photo)
                            .resizable()
                            .scaledToFill()
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(alignment: .topTrailing) {
                        Button(action: removePhoto) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(.white, .black.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                        .padding(8)
                    }
                    .listRowInsets(EdgeInsets())
            }

            HStack {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Label(photo == nil ? "Choose Photo" : "Change Photo",
                          systemImage: "photo.on.rectangle")
                }
                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Spacer()
                    Button { showCamera = true } label: {
                        Label("Take Photo", systemImage: "camera")
                    }
                }
            }
            .buttonStyle(.borderless)
        } header: {
            Text("Photo")
        } footer: {
            Text("Add a photo and we'll try to recognize the food for you.")
        }
    }

    private var aiSection: some View {
        Section("AI Suggestions") {
            if isRecognizing {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Looking at your photo…").foregroundStyle(.secondary)
                }
            } else if suggestions.isEmpty {
                Text(recognitionNote ?? "No suggestions.")
                    .foregroundStyle(.secondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(suggestions) { suggestion in
                            Button { apply(suggestion) } label: {
                                Text("\(suggestion.category.addFoodIcon) \(suggestion.name)")
                            }
                            .buttonStyle(.bordered)
                            .tint(suggestion.name == trimmedName ? .green : .gray)
                        }
                    }
                }
                Text("Tap a suggestion to use it. You can still edit the name below.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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

    private func autoFillFromPreset() {
        guard let preset = PresetMatcher.find(name, in: presets),
              preset.name != lastAutoFilledName else { return }
        lastAutoFilledName = preset.name
        category = preset.category
        priceText = String(format: "%.2f", preset.estimatedValue)
    }

    private func loadPickedPhoto() {
        guard let pickerItem else { return }
        Task {
            if let data = try? await pickerItem.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                setPhoto(image)
            }
        }
    }

    private func setPhoto(_ image: UIImage) {
        let small = image.resized(maxDimension: 1024)
        photo = small
        Task { await recognize(small) }
    }

    private func recognize(_ image: UIImage) async {
        isRecognizing = true
        recognitionNote = nil
        suggestions = []

        let results = await FoodRecognizer.recognize(image, presets: presets)

        guard photo === image else { return }

        suggestions = results
        isRecognizing = false

        if let top = results.first {
            if trimmedName.isEmpty { apply(top) }
        } else {
            recognitionNote = "Couldn't recognize this food. Type the name below."
        }
    }

    private func apply(_ suggestion: FoodSuggestion) {
        name = suggestion.name
        if suggestion.category != .other { category = suggestion.category }
    }

    private func removePhoto() {
        photo = nil
        pickerItem = nil
        suggestions = []
        recognitionNote = nil
        isRecognizing = false
    }

    private func makeDraft() -> FoodDraft {
        FoodDraft(
            name: trimmedName,
            category: category,
            quantity: quantity,
            addedDate: addedDate,
            estimatedValue: Double(priceText.replacingOccurrences(of: ",", with: ".")) ?? 0,
            preset: PresetMatcher.find(trimmedName, in: presets),
            photo: photo,
            recognizedFromPhoto: suggestions.contains {
                $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame
            }
        )
    }

    private func resetForm() {
        showConfirm = false
        name = ""
        lastAutoFilledName = ""
        category = .other
        quantity = 1
        priceText = ""
        addedDate = Date()
        removePhoto()
    }
}

#Preview {
    AddFoodView(store: FoodStore())
}
