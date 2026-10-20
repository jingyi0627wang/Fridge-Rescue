import SwiftUI
import PhotosUI
import UIKit

// MARK: - Add My Recipe
// Write your own recipe: photo (library or camera), name, time, difficulty,
// ingredients (type them or pick from your fridge), steps, and whether to
// share it to the Community tab. Saved on the phone (MyRecipeStore).

struct AddRecipeView: View {
    @EnvironmentObject var myRecipes: MyRecipeStore
    @EnvironmentObject var foodStore: FoodStore
    @Environment(\.dismiss) private var dismiss
    @AppStorage("username") private var username = ""

    private struct StepDraft: Identifiable {
        let id = UUID()
        var text: String
    }

    @State private var name = ""
    @State private var emoji = "🍲"
    @State private var minutes = 20
    @State private var difficulty = "Easy"
    @State private var ingredients: [UserRecipe.Ingredient] = [UserRecipe.Ingredient(name: "", amount: "")]
    @State private var steps: [StepDraft] = [StepDraft(text: "")]
    @State private var shareToCommunity = true

    @State private var photoItem: PhotosPickerItem?
    @State private var photoData: Data?
    /// Decoded once (not on every keystroke).
    @State private var previewImage: UIImage?
    @State private var showCamera = false

    private let difficulties = ["Easy", "Medium", "Hard"]
    private let emojiChoices = ["🍲", "🥗", "🍝", "🍜", "🍛", "🥘", "🍳", "🥞", "🍞", "🥪",
                                "🌮", "🍕", "🍚", "🥣", "🍰", "🍪", "🥤", "🍱"]

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !trimmedName.isEmpty &&
        ingredients.contains { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
    }

    var body: some View {
        NavigationStack {
            Form {
                photoSection

                Section("Recipe") {
                    TextField("Recipe name", text: $name)
                        .textInputAutocapitalization(.words)

                    Picker("Icon", selection: $emoji) {
                        ForEach(emojiChoices, id: \.self) { choice in
                            Text(choice).tag(choice)
                        }
                    }

                    Stepper("Time: \(minutes) min", value: $minutes, in: 5...240, step: 5)

                    Picker("Difficulty", selection: $difficulty) {
                        ForEach(difficulties, id: \.self) { level in
                            Text(LocalizedStringKey(level)).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                ingredientsSection
                stepsSection

                Section {
                    Toggle("Share to Community", isOn: $shareToCommunity)
                } footer: {
                    Text("Shared recipes appear in the Community tab with your name.")
                }
            }
            .font(.game(16, .medium))
            .foregroundStyle(Game.brown)
            .gameBackground()
            .tint(Game.greenDark)
            .navigationTitle("New Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .fontWeight(.semibold)
                        .disabled(!canSave)
                }
            }
            .onChange(of: photoItem) {
                guard let item = photoItem else { return }
                Task {
                    let data = try? await item.loadTransferable(type: Data.self)
                    // Ignore it if another photo was picked in the meantime.
                    if photoItem == item, let data {
                        photoData = data
                    }
                }
            }
            .onChange(of: photoData) {
                previewImage = photoData.flatMap { UIImage(data: $0) }
            }
            .fullScreenCover(isPresented: $showCamera, onDismiss: { photoItem = nil }) {
                CameraPicker(imageData: $photoData)
                    .ignoresSafeArea()
            }
        }
    }

    // MARK: - Photo

    private var photoSection: some View {
        Section {
            Group {
                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        Game.mint
                        VStack(spacing: 6) {
                            Text(emoji).font(.system(size: 54))
                            Text("Add a photo of your dish")
                                .font(.game(14, .medium))
                                .foregroundStyle(Game.brownSoft)
                        }
                    }
                }
            }
            .frame(height: 190)
            .frame(maxWidth: .infinity)
            .clipped()
            .listRowInsets(EdgeInsets())

            HStack(spacing: 10) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Library", systemImage: "photo.on.rectangle")
                }
                .buttonStyle(.chunky(.white, small: true))

                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("Camera", systemImage: "camera.fill")
                    }
                    .buttonStyle(.chunky(.white, small: true))
                }

                if photoData != nil {
                    Button {
                        photoData = nil
                        photoItem = nil
                    } label: {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.chunky(.red, small: true, fullWidth: false))
                    .accessibilityLabel("Remove photo")
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 0, trailing: 0))
        }
    }

    // MARK: - Ingredients

    private var ingredientsSection: some View {
        Section {
            ForEach($ingredients) { $ingredient in
                HStack(spacing: 10) {
                    Text(FoodEmoji.emoji(for: ingredient.name, category: .other))
                        .font(.system(size: 20))
                        .opacity(ingredient.name.isEmpty ? 0.35 : 1)
                    TextField("Ingredient", text: $ingredient.name)
                        .textInputAutocapitalization(.words)
                    TextField("Amount", text: $ingredient.amount)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: 100)
                        .foregroundStyle(Game.brownSoft)
                }
            }
            .onDelete { ingredients.remove(atOffsets: $0) }

            Button {
                ingredients.append(UserRecipe.Ingredient(name: "", amount: ""))
            } label: {
                Label("Add Ingredient", systemImage: "plus.circle.fill")
            }

            if !foodStore.activeItemsByUrgency.isEmpty {
                Menu {
                    ForEach(foodStore.activeItemsByUrgency) { item in
                        Button {
                            addFromFridge(item)
                        } label: {
                            Text(verbatim: "\(FoodEmoji.emoji(for: item.name, category: item.category)) \(item.name)")
                        }
                    }
                } label: {
                    Label("Add from My Fridge", systemImage: "refrigerator.fill")
                }
            }
        } header: {
            Text("Ingredients")
        } footer: {
            Text("Ingredients that match your fridge food help this recipe show up as a rescue idea.")
        }
    }

    private func addFromFridge(_ item: FoodItem) {
        // Fill the first empty row, otherwise add a new one.
        if let index = ingredients.firstIndex(where: { $0.name.trimmingCharacters(in: .whitespaces).isEmpty }) {
            ingredients[index].name = item.name
        } else {
            ingredients.append(UserRecipe.Ingredient(name: item.name, amount: ""))
        }
    }

    // MARK: - Steps

    private var stepsSection: some View {
        Section("Steps") {
            ForEach($steps) { $step in
                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("\(stepNumber(step)).")
                        .font(.game(15, .bold))
                        .foregroundStyle(Game.greenInk)
                    TextField("Describe this step", text: $step.text, axis: .vertical)
                        .lineLimit(1...5)
                }
            }
            .onDelete { steps.remove(atOffsets: $0) }

            Button {
                steps.append(StepDraft(text: ""))
            } label: {
                Label("Add Step", systemImage: "plus.circle.fill")
            }
        }
    }

    private func stepNumber(_ step: StepDraft) -> Int {
        (steps.firstIndex { $0.id == step.id } ?? 0) + 1
    }

    // MARK: - Save

    private func save() {
        let photoFile = photoData.flatMap { myRecipes.savePhoto($0) }
        let recipe = UserRecipe(
            name: trimmedName,
            emoji: emoji,
            minutes: minutes,
            difficulty: difficulty,
            ingredients: ingredients.filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty },
            steps: steps.map(\.text).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
            photoFile: photoFile,
            isShared: shareToCommunity,
            createdAt: Date(),
            author: username.isEmpty ? "You" : username
        )
        myRecipes.add(recipe)
        FreshlingsHaptics.success()
        dismiss()
    }
}

// MARK: - Camera

/// Takes one photo with the camera and returns it as JPEG data.
struct CameraPicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ picker: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker

        init(_ parent: CameraPicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController,
                                   didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.imageData = image.jpegData(compressionQuality: 0.85)
            }
            parent.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    AddRecipeView()
        .environmentObject(MyRecipeStore())
        .environmentObject(FoodStore())
}
