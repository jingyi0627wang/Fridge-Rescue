import SwiftUI
import UIKit

// MARK: - Freshlings food icons
// A "symbol" is either the name of one of our drawings in Assets.xcassets/Food
// (e.g. "FoodCarrot") or an emoji (e.g. "🍆").
//
// Rule: show our drawing whenever we drew that food; only foods we did NOT draw
// keep their emoji. FoodEmoji.swift still decides which food a name is
// ("Chicken Breast" → 🍗); this file swaps that emoji for our drawing of it.

enum FoodIcon {

    /// Emoji → our drawing of the same food. Emoji not listed here have no drawing.
    private static let drawings: [String: String] = [
        "🍎": "FoodApple", "🥑": "FoodAvocado", "🍌": "FoodBanana", "🍞": "FoodBread",
        "🥦": "FoodBroccoli", "🥕": "FoodCarrot", "🧀": "FoodCheese", "🍗": "FoodChicken",
        "🥚": "FoodEgg", "🍳": "FoodEgg", "🐟": "FoodFish", "🥛": "FoodMilk",
        "🍄": "FoodMushroom", "🍓": "FoodStrawberry", "🍅": "FoodTomato", "🍤": "FoodShrimp",
        "🥬": "FoodLeafy", "🧊": "FoodTofu", "🥓": "FoodBacon", "🥩": "FoodMeat",
        "🫑": "FoodPepper", "🧈": "FoodButter", "🥣": "FoodCereal", "🌽": "FoodCorn",
        "🥒": "FoodCucumber", "🍇": "FoodGrape", "🧃": "FoodJuice", "🥤": "FoodJuice",
        "🍋": "FoodLemon", "🧅": "FoodOnion", "🍊": "FoodOrange", "🍐": "FoodPear",
        "🥔": "FoodPotato", "🍉": "FoodWatermelon",
    ]

    /// Names we drew that FoodEmoji can't tell apart (e.g. lemon and lime are both 🍋).
    /// Checked before FoodEmoji, first match wins.
    private static let nameDrawings: [(keywords: [String], drawing: String)] = [
        (["lime"], "FoodLime"),
        (["yogurt", "yoghurt", "sour cream", "kefir"], "FoodYogurt"),
        (["cereal", "oat", "granola", "muesli"], "FoodCereal"),
        (["muffin", "cupcake"], "FoodMuffin"),
        (["jam", "jelly", "preserve"], "FoodJar"),
    ]

    /// Our drawing for a food, or its emoji if we didn't draw it.
    static func symbol(for name: String, category: FoodCategory) -> String {
        let key = name.lowercased()
        if let match = nameDrawings.first(where: { rule in rule.keywords.contains { startsWord(key, $0) } }) {
            return match.drawing
        }
        return symbol(forEmoji: FoodEmoji.emoji(for: name, category: category))
    }

    /// Our drawing for an emoji (recipes, challenges), or the emoji itself.
    /// A value that is already a drawing name is returned as is.
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

    /// "pear" matches "Pear" and "Asian Pear" but not "spears".
    private static func startsWord(_ text: String, _ keyword: String) -> Bool {
        var range = text.startIndex..<text.endIndex
        while let found = text.range(of: keyword, range: range) {
            if found.lowerBound == text.startIndex || !text[text.index(before: found.lowerBound)].isLetter {
                return true
            }
            range = found.upperBound..<text.endIndex
        }
        return false
    }
}

// MARK: - Category icons

extension FoodCategory {
    /// Our drawing for the category, or nil for "Other" (keeps its SF Symbol).
    var drawingName: String? {
        switch self {
        case .vegetable: return "FoodCarrot"
        case .fruit: return "FoodApple"
        case .dairy: return "FoodMilk"
        case .meat: return "FoodMeat"
        case .other: return nil
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
                 "Chicken Breast", "Lime", "Mango", "Greek Yogurt"], id: \.self) { name in
            VStack {
                FoodIconView(name: name, size: 44)
                Text(name).font(.caption2)
            }
        }
    }
    .padding()
}
