import SwiftUI
import UIKit

// Food names are resolved before any emoji fallback. Only unnamed recipe symbols
// use the deliberately limited emoji-to-drawing bridge below.
enum FoodIcon {
    private static let drawings: [String: String] = [
        "🫐": "food-blueberry", "🍍": "food-pineapple", "🥥": "food-coconut",
        "🍒": "food-cherry", "🍑": "food-peach", "🥝": "food-kiwi",
        "🥭": "food-mango", "🍈": "food-honeydew-melon", "🌶": "food-thai-chili",
        "🫛": "food-green-peas", "🦃": "food-turkey", "🍖": "food-ham",
        "🌭": "food-hot-dogs", "🍠": "food-sweet-potato",
        "🍎": "food-apple", "🍏": "food-apple", "🥑": "food-avocado",
        "🍌": "food-banana", "🍞": "food-bread", "🥦": "food-broccoli",
        "🥕": "food-carrot", "🧀": "food-cheese", "🍗": "food-chicken",
        "🥚": "food-egg", "🍳": "food-egg", "🐟": "food-fish",
        "🥛": "food-milk", "🍄": "food-mushroom", "🍓": "food-strawberry",
        "🍅": "food-tomato", "🍤": "food-shrimp", "🥬": "food-green-leaf-lettuce",
        "🧊": "food-tofu", "🥓": "food-bacon", "🥩": "food-beef",
        "🫑": "food-bell-pepper", "🧈": "food-butter", "🥣": "food-cereal",
        "🌽": "food-corn", "🥒": "food-cucumber", "🍇": "food-grapes",
        "🧃": "food-juice", "🍋": "food-lemon", "🧅": "food-onion",
        "🍊": "food-orange", "🍐": "food-pear", "🥔": "food-potato",
        "🍉": "food-watermelon", "🍚": "food-rice", "🍝": "food-pasta",
        "🍆": "food-eggplant", "🧄": "food-garlic", "🫚": "food-ginger"
    ]

    /// Every covered food resolves to its own named asset (including every leafy variety).
    /// Do not round-trip through FoodEmoji: different foods share the same emoji.
    static func symbol(for name: String, category: FoodCategory) -> String {
        if let drawing = FoodIconNames.assetName(for: name) { return drawing }
        return FoodEmoji.emoji(for: name, category: category)
    }

    /// Compatibility bridge for existing recipe emoji pickers and stored recipes.
    static func symbol(forEmoji emoji: String) -> String {
        let plain = emoji.replacingOccurrences(of: "\u{FE0F}", with: "")
        return drawings[plain] ?? drawings[emoji] ?? emoji
    }

    /// True if `symbol` is one of our drawings (not an emoji).
    static func isDrawing(_ symbol: String) -> Bool {
        UIImage(named: symbol) != nil
    }

    /// Small pre-sized copy of a drawing for Menu / Picker rows
    /// (iOS menus draw images at their real size, so the big asset is shrunk first).
    static func menuImage(_ symbol: String, size: CGFloat = 22) -> Image? {
        guard let image = UIImage(named: symbol) else { return nil }
        let box = CGSize(width: size, height: size)
        let small = UIGraphicsImageRenderer(size: box).image { _ in
            image.draw(in: CGRect(origin: .zero, size: box))
        }
        return Image(uiImage: small.withRenderingMode(.alwaysOriginal))
    }

}

// MARK: - Category icons

extension FoodCategory {
    /// Every category has a drawing; Other uses a gray mystery vegetable.
    var drawingName: String? {
        switch self {
        case .vegetable: return "food-carrot"
        case .fruit: return "food-apple"
        case .dairy: return "food-milk"
        case .meat: return "food-beef"
        case .other: return "food-mystery-vegetable"
        }
    }
}

// MARK: - Views

/// Shows one of our drawings, or the emoji when there is no drawing.
struct FreshSymbol: View {
    let symbol: String
    var size: CGFloat

    var body: some View {
        if FoodIcon.isDrawing(symbol) {
            Image(symbol)
                .resizable()
                .interpolation(.high)
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        } else {
            Text(verbatim: symbol)
                .font(.system(size: size * 0.8))
                .frame(width: size, height: size)
                .accessibilityHidden(true)
        }
    }
}

/// Icon for a food name (drawing when we have one, emoji otherwise).
struct FoodIconView: View {
    let name: String
    var category: FoodCategory = .other
    var size: CGFloat

    var body: some View {
        FreshSymbol(symbol: FoodIcon.symbol(for: name, category: category), size: size)
    }
}

/// Menu / Picker row: small drawing + title, or "emoji title" when there is no drawing.
struct FreshMenuLabel: View {
    let title: String
    let symbol: String

    var body: some View {
        if let image = FoodIcon.menuImage(symbol) {
            Label { Text(verbatim: title) } icon: { image }
        } else {
            Text(verbatim: "\(symbol) \(title)")
        }
    }
}

/// Category row for pickers: our drawing, or the SF Symbol for "Other".
struct CategoryLabel: View {
    let category: FoodCategory

    var body: some View {
        if let drawing = category.drawingName, let image = FoodIcon.menuImage(drawing) {
            Label { Text(category.displayName) } icon: { image }
        } else {
            Label(category.displayName, systemImage: category.symbolName)
        }
    }
}

#Preview {
    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
        ForEach(["Apple", "Eggs", "Whole Milk", "Bacon", "Cherry Tomato", "Eggplant",
                 "Chicken Breast", "Lime", "Mango", "Greek Yogurt", "Red Leaf Lettuce", "Ground Turkey"], id: \.self) { name in
            VStack {
                FoodIconView(name: name, size: 44)
                Text(name).font(.caption2)
            }
        }
    }
    .padding()
}
