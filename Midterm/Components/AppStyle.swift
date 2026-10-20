import SwiftUI
import UIKit
import CoreText

// MARK: - Freshlings style
// The whole app's look lives here:
//   • fresh sage-white background, deep green-black text
//   • the Freshlings light green as the accent; orange only for XP and coins
//   • Fredoka (rounded, like the wordmark) for titles and big numbers only;
//     everything else uses the iPhone's own font so it reads like a real app
//   • soft white surfaces with a gentle shadow, pill buttons, round food badges
// (The enum is still called `Game` and some names like `brown` are kept so
// every screen picks up the new look without renaming everything.)

// MARK: - Colors

enum Game {
    static let cream = hex(0xF5F7F0)         // app background (sage white)
    static let card = Color.white            // surfaces
    static let edge = hex(0xE6EBDD)          // hairlines
    static let edgeDark = hex(0xC3CABB)      // chevrons, placeholders
    static let track = hex(0xEEF1E8)         // empty bars, quiet buttons
    static let field = hex(0xE9ECE3)         // search field

    static let green = hex(0x8DE969)         // Freshling green (accent)
    static let greenDark = hex(0x5BBF3A)     // icons, toggles, selected tab
    static let greenInk = hex(0x1F4A10)      // text on green
    static let mint = hex(0xEAF8DF)          // light green tint

    static let brown = hex(0x1E2A1B)         // main text (deep green-black)
    static let brownSoft = hex(0x6A7464)     // secondary text

    static let orange = hex(0xFFAA01)        // XP and coins
    static let orangeDark = hex(0xC98300)
    static let orangeSoft = hex(0xFFF3D6)

    static let red = hex(0xF26B4F)
    static let redDark = hex(0xC2452C)
    static let redSoft = hex(0xFDE5DF)
    static let redEdge = hex(0xF6C9BD)

    static let yellow = hex(0xF5C451)
    static let blue = hex(0x7CC4FF)
    static let pink = hex(0xFF8FB8)
    static let gray = hex(0xB9C0B3)
    static let graySoft = hex(0xEFF1EA)

    static func hex(_ value: UInt32) -> Color {
        Color(
            red: Double((value >> 16) & 0xFF) / 255,
            green: Double((value >> 8) & 0xFF) / 255,
            blue: Double(value & 0xFF) / 255
        )
    }
}

extension Color {
    /// Accent for links, toggles and icons.
    static let brand = Game.greenDark
}

// MARK: - Font (Fredoka)

enum GameWeight {
    case medium, semibold, bold

    var fontName: String {
        switch self {
        case .medium: return "Fredoka-Medium"
        case .semibold: return "Fredoka-SemiBold"
        case .bold: return "Fredoka-Bold"
        }
    }

    var systemWeight: Font.Weight {
        switch self {
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        }
    }
}

enum GameFont {
    /// Loads the bundled Fredoka files (no Info.plist entry needed).
    static func register() {
        for weight in [GameWeight.medium, .semibold, .bold] {
            if let url = Bundle.main.url(forResource: weight.fontName, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    /// True once the font is loaded. If it's ever missing, SF Rounded is used instead.
    /// (Registers the font on first use, so Xcode Previews show it too.)
    static let isAvailable: Bool = {
        if UIFont(name: GameWeight.bold.fontName, size: 12) == nil { register() }
        return UIFont(name: GameWeight.bold.fontName, size: 12) != nil
    }()

    static func uiFont(_ weight: GameWeight, _ size: CGFloat) -> UIFont {
        UIFont(name: weight.fontName, size: size)
            ?? .systemFont(ofSize: size, weight: weight == .medium ? .medium : .bold)
    }
}

extension Font {
    /// The app font.
    ///   • .bold at 17 pt or bigger → Fredoka SemiBold (titles, big numbers)
    ///   • everything else          → the iPhone's own font (SF Pro)
    static func game(_ size: CGFloat, _ weight: GameWeight = .semibold,
                     relativeTo style: Font.TextStyle = .body) -> Font {
        if weight == .bold && size >= 17 {
            if GameFont.isAvailable {
                return .custom(GameWeight.semibold.fontName, size: size, relativeTo: style)
            }
            return .system(size: size, weight: .bold, design: .rounded)
        }
        return .system(size: size, weight: weight.systemWeight)
    }
}

// MARK: - Navigation bar + tab bar look

enum GameAppearance {
    /// Call once at launch (MyApp.init).
    static func configure() {
        GameFont.register()

        let brown = UIColor(Game.brown)

        // Navigation bar: Fredoka titles. Backgrounds stay the iOS default, and the
        // tab bar isn't restyled at all, so both keep the native look.
        let buttons = UIBarButtonItemAppearance()

        let navStandard = UINavigationBarAppearance()
        navStandard.configureWithDefaultBackground()
        let navEdge = UINavigationBarAppearance()
        navEdge.configureWithTransparentBackground()

        for nav in [navStandard, navEdge] {
            nav.largeTitleTextAttributes = [.font: GameFont.uiFont(.semibold, 32), .foregroundColor: brown]
            nav.titleTextAttributes = [.font: GameFont.uiFont(.semibold, 18), .foregroundColor: brown]
            nav.buttonAppearance = buttons
            nav.doneButtonAppearance = buttons
            nav.backButtonAppearance = buttons
        }
        UINavigationBar.appearance().standardAppearance = navStandard
        UINavigationBar.appearance().compactAppearance = navStandard
        UINavigationBar.appearance().scrollEdgeAppearance = navEdge

        // Segmented pickers (History filter)
        UISegmentedControl.appearance().selectedSegmentTintColor = .white
        UISegmentedControl.appearance().setTitleTextAttributes(
            [.font: UIFont.systemFont(ofSize: 14, weight: .semibold), .foregroundColor: brown], for: .normal)
    }
}

// MARK: - Background

struct GameBackground: View {
    var body: some View {
        Game.cream
            .ignoresSafeArea()
            .accessibilityHidden(true)
    }
}

extension View {
    /// App background (also hides List/Form's gray background).
    func gameBackground() -> some View {
        self
            .scrollContentBackground(.hidden)
            .background(GameBackground())
    }

    /// Soft surface: white (or tinted) rounded rectangle with a gentle shadow.
    func gameCard(padding: CGFloat = 14, fill: Color = Game.card, radius: CGFloat = 22) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
                    .shadow(color: Game.brown.opacity(fill == Game.card ? 0.07 : 0), radius: 12, y: 5)
            )
    }
}

// MARK: - Buttons

enum ChunkyKind {
    case green, orange, red, white

    var fill: Color {
        switch self {
        case .green: return Game.green
        case .orange: return Game.orangeSoft
        case .red: return Game.redSoft
        case .white: return Game.track
        }
    }

    var text: Color {
        switch self {
        case .green: return Game.greenInk
        case .orange: return Game.orangeDark
        case .red: return Game.redDark
        case .white: return Game.brown
        }
    }
}

/// Pill button. Shrinks slightly when pressed.
/// (Name kept from the earlier "chunky" design so screens don't change.)
struct ChunkyButtonStyle: ButtonStyle {
    var kind: ChunkyKind = .green
    var small = false
    var fullWidth = true

    func makeBody(configuration: Configuration) -> some View {
        ChunkyButtonBody(configuration: configuration, kind: kind, small: small, fullWidth: fullWidth)
    }
}

private struct ChunkyButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let kind: ChunkyKind
    let small: Bool
    let fullWidth: Bool
    @Environment(\.isEnabled) private var isEnabled

    var body: some View {
        let pressed = configuration.isPressed && isEnabled

        configuration.label
            .font(.system(size: small ? 15 : 17, weight: .semibold))
            .foregroundStyle(isEnabled ? kind.text : Game.brownSoft)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.vertical, small ? 9 : 15)
            .padding(.horizontal, small ? 16 : 20)
            .frame(maxWidth: fullWidth ? .infinity : nil)
            .background(Capsule().fill(isEnabled ? kind.fill : Game.track))
            .scaleEffect(pressed ? 0.97 : 1)
            .opacity(pressed ? 0.85 : 1)
            .animation(.spring(duration: 0.2), value: pressed)
    }
}

extension ButtonStyle where Self == ChunkyButtonStyle {
    static func chunky(_ kind: ChunkyKind = .green, small: Bool = false,
                       fullWidth: Bool = true) -> ChunkyButtonStyle {
        ChunkyButtonStyle(kind: kind, small: small, fullWidth: fullWidth)
    }
}

// MARK: - Filter chips (category / ingredient)

struct GameChip: View {
    let title: LocalizedStringKey
    let isSelected: Bool
    var showsAlert = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                if showsAlert {
                    Circle().fill(Game.red).frame(width: 6, height: 6)
                }
                Text(title)
            }
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(isSelected ? Color.white : Game.brownSoft)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(isSelected ? Game.brown : Color.clear))
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

// MARK: - Small status pills (level, coins)

struct HUDPill: View {
    let icon: String
    let iconColor: Color
    let text: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .heavy))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Circle().fill(iconColor))
            Text(text)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Game.brown)
                .monospacedDigit()
        }
        .padding(.leading, 5)
        .padding(.trailing, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(.white)
                .shadow(color: Game.brown.opacity(0.07), radius: 2, y: 1)
        )
    }
}

/// "+20 XP"
struct XPTag: View {
    let xp: Int

    var body: some View {
        Text("+\(xp) XP")
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(Game.orangeDark)
    }
}

// MARK: - Section header

struct GameSectionHeader: View {
    let title: LocalizedStringKey
    var count: Int? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.game(20, .bold))
                .foregroundStyle(Game.brown)
            Spacer()
            if let count {
                Text("\(count)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Game.brownSoft)
            }
        }
        .padding(.horizontal, 2)
        .padding(.top, 14)
    }
}

// MARK: - Freshlings (food characters)

extension FoodCategory {
    /// Freshling body color for this kind of food.
    var freshlingColor: Color {
        switch self {
        case .vegetable: return Game.green
        case .fruit: return Game.pink
        case .dairy: return Game.blue
        case .meat: return Game.hex(0xFF8A6B)
        case .other: return Game.hex(0xFFB938)
        }
    }

    var freshlingBackground: Color {
        switch self {
        case .vegetable: return Game.mint
        case .fruit: return Game.hex(0xFFE8F1)
        case .dairy: return Game.hex(0xE5F3FF)
        case .meat: return Game.hex(0xFFE9E2)
        case .other: return Game.orangeSoft
        }
    }

    /// Small SF Symbol for menus and pickers.
    var symbolName: String {
        switch self {
        case .vegetable: return "carrot.fill"
        case .fruit: return "leaf.fill"
        case .dairy: return "drop.fill"
        case .meat: return "fork.knife"
        case .other: return "bag.fill"
        }
    }

    var iconColor: Color { freshlingColor }

    /// Localized name for Text views ("Vegetable" → "蔬菜").
    var displayName: LocalizedStringKey { LocalizedStringKey(rawValue) }
}

/// The Freshlings character in any color.
struct FreshlingMascot: View {
    var size: CGFloat = 64
    var color: Color = Game.green

    var body: some View {
        Image("FreshlingsCharacter")
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .foregroundStyle(color)
            .frame(width: size, height: size * 1.125)
            .accessibilityHidden(true)
    }
}

/// A food's picture: our drawing of it (or its emoji if we didn't draw it) on a tile
/// colored by category, with a red "!" when it's low on HP and gray + sleeping
/// when it's past its date. Without a name it shows the Freshling character.
struct FreshlingAvatar: View {
    let category: FoodCategory
    var name: String? = nil
    var level: FreshnessLevel = .fresh
    var size: CGFloat = 56
    var showsStatus = true

    /// Shortcut for a fridge item.
    init(item: FoodItem, size: CGFloat = 56, showsStatus: Bool = true) {
        self.category = item.category
        self.name = item.name
        self.level = item.freshnessLevel
        self.size = size
        self.showsStatus = showsStatus
    }

    init(category: FoodCategory, name: String? = nil, level: FreshnessLevel = .fresh,
         size: CGFloat = 56, showsStatus: Bool = true) {
        self.category = category
        self.name = name
        self.level = level
        self.size = size
        self.showsStatus = showsStatus
    }

    var body: some View {
        let expired = level == .expired

        Circle()
            .fill(expired ? Game.graySoft : category.freshlingBackground)
            .frame(width: size, height: size)
            .overlay {
                if let name {
                    FreshSymbol(symbol: FoodIcon.symbol(for: name, category: category), size: size * 0.64)
                        .grayscale(expired ? 1 : 0)
                        .opacity(expired ? 0.55 : 1)
                } else {
                    FreshlingMascot(size: size * 0.62, color: expired ? Game.gray : category.freshlingColor)
                }
            }
            .overlay(alignment: .topTrailing) {
                // Small red dot = almost out of HP
                if showsStatus && level == .urgent {
                    Circle()
                        .fill(Game.red)
                        .frame(width: max(size * 0.2, 9), height: max(size * 0.2, 9))
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .offset(x: -size * 0.02, y: size * 0.02)
                }
            }
            .accessibilityHidden(true)
    }
}

/// Kept for screens that ask for a small category picture.
struct CategoryIcon: View {
    let category: FoodCategory
    var size: CGFloat = 32

    var body: some View {
        FreshlingAvatar(category: category, size: size, showsStatus: false)
    }
}

// MARK: - HP (freshness)

extension FreshnessLevel {
    /// HP bar color.
    var hpColor: Color {
        switch self {
        case .fresh: return Game.green
        case .useSoon: return Game.yellow
        case .urgent: return Game.red
        case .expired: return Game.gray
        }
    }

    /// Color for "3 days left" text.
    var tint: Color {
        switch self {
        case .fresh: return Game.brownSoft
        case .useSoon: return Game.orangeDark
        case .urgent: return Game.redDark
        case .expired: return Game.brownSoft
        }
    }

    /// Localized title for Text views ("Fresh", "Use Soon", …).
    var displayName: LocalizedStringKey { LocalizedStringKey(title) }
}

extension FoodItem {
    /// HP points out of 7: one per day left (expiring today still shows 1).
    var hpPoints: Int {
        let days = daysUntilExpiration
        if days < 0 { return 0 }
        return max(1, min(days, FoodItem.fullHPDays))
    }
}

/// Game health bar: 7 segments, one per day left.
struct HPBar: View {
    let item: FoodItem
    var segmentWidth: CGFloat? = 12
    var height: CGFloat = 5
    var showsLabel = true

    var body: some View {
        let filled = item.hpPoints
        let color = item.freshnessLevel.hpColor

        HStack(spacing: 6) {
            if showsLabel {
                Text("HP")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Game.brownSoft)
            }
            HStack(spacing: 3) {
                ForEach(0..<FoodItem.fullHPDays, id: \.self) { index in
                    segment(filled: index < filled, color: color)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("HP")
        .accessibilityValue("\(filled) of \(FoodItem.fullHPDays)")
    }

    @ViewBuilder
    private func segment(filled: Bool, color: Color) -> some View {
        let shape = RoundedRectangle(cornerRadius: height * 0.4, style: .continuous)
            .fill(filled ? color : Game.track)
        if let segmentWidth {
            shape.frame(width: segmentWidth, height: height)
        } else {
            shape.frame(maxWidth: .infinity).frame(height: height)
        }
    }
}

/// Kept for older screens: same as HPBar without the label.
struct FreshnessBar: View {
    let item: FoodItem

    var body: some View {
        HPBar(item: item, segmentWidth: nil, showsLabel: false)
    }
}

/// Rounded progress bar (XP, goals, use rate).
struct GameProgressBar: View {
    let progress: Double
    var color: Color = Game.green
    var height: CGFloat = 14

    var body: some View {
        let clamped = CGFloat(min(max(progress, 0), 1))
        let minimum: CGFloat = progress > 0 ? height : 0

        return GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Game.track)
                Capsule()
                    .fill(color)
                    .overlay(alignment: .bottom) {
                        Capsule()
                            .fill(.black.opacity(0.10))
                            .frame(height: height * 0.3)
                    }
                    .clipShape(Capsule())
                    .frame(width: max(geometry.size.width * clamped, minimum))
            }
        }
        .frame(height: height)
        .accessibilityElement()
        .accessibilityValue("\(Int(min(max(progress, 0), 1) * 100)) percent")
    }
}

// MARK: - Mascot message

/// The Freshling mascot with a short message on a light green card.
struct MascotSays: View {
    private let text: Text
    private let mascotColor: Color

    /// Translated message (use for fixed text).
    init(_ key: LocalizedStringKey, mascotColor: Color = Game.green) {
        text = Text(key)
        self.mascotColor = mascotColor
    }

    /// Ready-made Text (e.g. a message picked by the screen).
    init(text: Text, mascotColor: Color = Game.green) {
        self.text = text
        self.mascotColor = mascotColor
    }

    /// Message shown as-is (e.g. a storage tip from the ingredient list).
    init(verbatim string: String, mascotColor: Color = Game.green) {
        text = Text(verbatim: string)
        self.mascotColor = mascotColor
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            FreshlingMascot(size: 44, color: mascotColor)

            text
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Game.brown)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Game.mint))
    }
}

// MARK: - Divider between rows

/// Thin line between rows in a list surface. (Name kept from earlier design.)
struct DashedDivider: View {
    var body: some View {
        Rectangle()
            .fill(Game.edge)
            .frame(height: 1)
            .padding(.horizontal, 14)
    }
}

// MARK: - Search field

struct GameSearchField: View {
    @Binding var text: String
    var prompt: LocalizedStringKey = "Search your fridge"

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Game.brownSoft)
            TextField(prompt, text: $text)
                .font(.system(size: 16))
                .foregroundStyle(Game.brown)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Game.edgeDark)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear search")
            }
        }
        .padding(.horizontal, 12)
        .frame(height: 40)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Game.field))
    }
}

// MARK: - Food row (Fridge, Quests)

struct FoodRow: View {
    let item: FoodItem

    var body: some View {
        HStack(spacing: 12) {
            FreshlingAvatar(item: item, size: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.game(17, .semibold))
                    .foregroundStyle(Game.brown)
                    .lineLimit(1)
                Text("Qty \(item.quantity) · \(item.daysLeftText)")
                    .font(.game(13, .medium))
                    .foregroundStyle(item.freshnessLevel.tint)
                    .lineLimit(1)
                HPBar(item: item)
                    .padding(.top, 3)
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Game.edgeDark)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}

// MARK: - Long-press menu for a fridge item

struct FoodQuickActions: ViewModifier {
    let item: FoodItem
    let store: FoodStore

    func body(content: Content) -> some View {
        content
            .contextMenu {
                if item.quantity > 1 {
                    Button {
                        store.markAsUsed(item, quantity: 1)
                    } label: {
                        Label("Used 1 (of \(item.quantity))", systemImage: "checkmark.circle")
                    }
                    Button {
                        store.markAsUsed(item)
                    } label: {
                        Label("Used All \(item.quantity)", systemImage: "checkmark.circle.fill")
                    }
                    Button {
                        store.markAsWasted(item, quantity: 1)
                    } label: {
                        Label("Threw Away 1", systemImage: "xmark.bin")
                    }
                } else {
                    Button {
                        store.markAsUsed(item)
                    } label: {
                        Label("I Used It", systemImage: "checkmark.circle")
                    }
                    Button {
                        store.markAsWasted(item)
                    } label: {
                        Label("Threw Away", systemImage: "xmark.bin")
                    }
                }
                Button(role: .destructive) {
                    store.deleteItem(item)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
    }
}

extension View {
    func foodQuickActions(_ item: FoodItem, store: FoodStore) -> some View {
        modifier(FoodQuickActions(item: item, store: store))
    }
}

// MARK: - Recipes

struct RecipeThumbnail: View {
    let recipe: Recipe
    var size: CGFloat = 64

    var body: some View {
        Group {
            if let url = recipe.imageURL {
                RecipePhoto(url: url) { placeholder }
            } else {
                placeholder
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.28, style: .continuous))
        .accessibilityHidden(true)
    }

    private var placeholder: some View {
        ZStack {
            Game.mint
            if recipe.emoji.isEmpty {
                Image(systemName: "fork.knife")
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(Game.greenDark)
            } else {
                FreshSymbol(symbol: FoodIcon.symbol(forEmoji: recipe.emoji), size: size * 0.62)
            }
        }
    }
}

/// A recipe photo: from the phone (My Recipes) or downloaded (TheMealDB).
struct RecipePhoto<Placeholder: View>: View {
    let url: URL
    @ViewBuilder let placeholder: () -> Placeholder

    var body: some View {
        if url.isFileURL {
            if let image = UIImage(contentsOfFile: url.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholder()
            }
        } else {
            AsyncImage(url: url) { image in
                image.resizable().scaledToFill()
            } placeholder: {
                placeholder()
            }
        }
    }
}

struct RecipeRow: View {
    let recipe: Recipe
    let fridgeCount: Int
    /// The food that expires soonest that this recipe uses (if any).
    let rescueFood: FoodItem?

    var body: some View {
        HStack(spacing: 12) {
            RecipeThumbnail(recipe: recipe)

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.game(16, .semibold))
                    .foregroundStyle(Game.brown)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let rescueFood {
                    Text("Rescues \(rescueFood.name) · \(rescueFood.daysLeftText.lowercased())")
                        .font(.game(13, .medium))
                        .foregroundStyle(rescueFood.freshnessLevel.tint)
                        .lineLimit(1)
                }

                HStack(spacing: 6) {
                    Label("\(fridgeCount)/\(recipe.items.count)", systemImage: "refrigerator.fill")
                        .font(.game(12, .bold))
                        .foregroundStyle(Game.greenInk)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Game.mint))
                    Text(recipe.timeText)
                        .font(.game(12, .medium))
                        .foregroundStyle(Game.brownSoft)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Game.edgeDark)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .contentShape(Rectangle())
    }
}
