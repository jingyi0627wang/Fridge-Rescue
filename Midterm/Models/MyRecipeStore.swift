import SwiftUI
import Combine
import UIKit

// MARK: - My Recipes
// Recipes the user writes (with an optional photo), plus which community
// posts they liked. Everything is saved on the phone:
//   • recipe text → UserDefaults (JSON)
//   • photos      → Documents/RecipePhotos/<id>.jpg

struct UserRecipe: Codable, Identifiable {
    struct Ingredient: Codable, Identifiable, Hashable {
        var id = UUID()
        var name: String
        var amount: String
    }

    var id = UUID()
    var name: String
    var emoji: String
    var minutes: Int
    var difficulty: String
    var ingredients: [Ingredient]
    var steps: [String]
    var photoFile: String?
    var isShared: Bool
    var createdAt: Date
    var author: String

    /// The id used for this recipe in the rest of the app.
    var recipeID: String { "mine-\(id.uuidString)" }

    /// As a Recipe, so it works everywhere recipes are shown
    /// (lists, search, details, "I Cooked This").
    var asRecipe: Recipe {
        Recipe(
            id: recipeID,
            name: name,
            emoji: emoji,
            time: minutes,
            difficulty: difficulty,
            items: ingredients
                .filter { !$0.name.trimmingCharacters(in: .whitespaces).isEmpty }
                .map { RecipeIngredient(name: $0.name, amount: $0.amount) },
            steps: steps.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty },
            imageURL: photoFile.map { MyRecipeStore.photoURL(for: $0) }
        )
    }
}

final class MyRecipeStore: ObservableObject {
    @Published private(set) var recipes: [UserRecipe] = [] {
        didSet { save() }
    }

    /// Community posts the user liked (post ids).
    @Published private(set) var likedPostIDs: Set<String> = [] {
        didSet { save() }
    }

    private let recipesKey = "savedUserRecipes"
    private let likesKey = "likedCommunityPosts"

    init() {
        load()
    }

    // MARK: Recipes

    /// Newest first.
    var allRecipes: [Recipe] {
        recipes.sorted { $0.createdAt > $1.createdAt }.map(\.asRecipe)
    }

    var sharedRecipes: [UserRecipe] {
        recipes.filter(\.isShared).sorted { $0.createdAt > $1.createdAt }
    }

    func add(_ recipe: UserRecipe) {
        recipes.append(recipe)
    }

    func userRecipe(forRecipeID id: String) -> UserRecipe? {
        recipes.first { $0.recipeID == id }
    }

    func delete(recipeID: String) {
        guard let recipe = userRecipe(forRecipeID: recipeID) else { return }
        if let file = recipe.photoFile {
            try? FileManager.default.removeItem(at: MyRecipeStore.photoURL(for: file))
        }
        recipes.removeAll { $0.id == recipe.id }
    }

    func setShared(recipeID: String, _ shared: Bool) {
        guard let index = recipes.firstIndex(where: { $0.recipeID == recipeID }) else { return }
        recipes[index].isShared = shared
    }

    /// True if a recipe with this name is already in My Recipes.
    func hasRecipe(named name: String) -> Bool {
        recipes.contains { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// "Save" on a community post: copies the recipe into My Recipes.
    func saveCopy(of recipe: Recipe, author: String) {
        guard !hasRecipe(named: recipe.name) else { return }
        add(UserRecipe(
            name: recipe.name,
            emoji: recipe.emoji,
            minutes: recipe.time,
            difficulty: recipe.difficulty,
            ingredients: recipe.items.map { UserRecipe.Ingredient(name: $0.name, amount: $0.amount) },
            steps: recipe.steps,
            photoFile: nil,
            isShared: false,
            createdAt: Date(),
            author: author
        ))
    }

    // MARK: Likes

    func isLiked(_ postID: String) -> Bool {
        likedPostIDs.contains(postID)
    }

    func toggleLike(_ postID: String) {
        if likedPostIDs.contains(postID) {
            likedPostIDs.remove(postID)
        } else {
            likedPostIDs.insert(postID)
        }
    }

    // MARK: Photos

    /// Documents/RecipePhotos (created once).
    private static let photoFolder: URL = {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let folder = documents.appendingPathComponent("RecipePhotos", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }()

    static func photoURL(for fileName: String) -> URL {
        photoFolder.appendingPathComponent(fileName)
    }

    /// Shrinks the photo (max 1200 px) and saves it as JPEG. Returns the file name.
    func savePhoto(_ data: Data) -> String? {
        guard let image = UIImage(data: data) else { return nil }
        let longest = max(image.size.width, image.size.height)
        let scale = min(1, 1200 / max(longest, 1))
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        // Scale 1 = real pixels (otherwise the phone's 3x screen scale is used).
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let jpeg = resized.jpegData(compressionQuality: 0.75) else { return nil }
        let name = "\(UUID().uuidString).jpg"
        do {
            try jpeg.write(to: MyRecipeStore.photoURL(for: name))
            return name
        } catch {
            return nil
        }
    }

    // MARK: Saving

    private func save() {
        if let data = try? JSONEncoder().encode(recipes) {
            UserDefaults.standard.set(data, forKey: recipesKey)
        }
        UserDefaults.standard.set(Array(likedPostIDs), forKey: likesKey)
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: recipesKey),
           let saved = try? JSONDecoder().decode([UserRecipe].self, from: data) {
            recipes = saved
        }
        if let liked = UserDefaults.standard.stringArray(forKey: likesKey) {
            likedPostIDs = Set(liked)
        }
    }
}
