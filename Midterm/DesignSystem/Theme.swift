import SwiftUI
import CoreText

// MARK: - Freshlings design system
// One source for colors and fonts, matching the "Freshlings" design system
// (tokens.json). Page palettes (FreshlingsHomeStyle, RecipeFreshlingsStyle, …)
// point here, so changing a value in this file changes the whole app.

enum FL {

    // MARK: Brand palette (Figma)
    static let leaf = hex(0x7BA531)          // brand green: bars, icons, active
    static let sprout = hex(0xB2E680)        // icon fills, soft highlights
    static let citrus = hex(0xF3AE3D)        // accent: badges, money, Use Soon bars
    static let lime = hex(0xC0FA63)          // secondary buttons, selected chips
    static let mint = hex(0xE1F2BB)          // soft panels, HP bar track
    static let bark = hex(0x735543)          // titles and body text
    static let tomato = hex(0xE46B54)        // alerts, Urgent bars

    // MARK: Surfaces
    static let surface = Color.white         // Impact screen, outlined cards
    static let canvas = hex(0xFBFDF7)        // screens made of white cards
    static let cardTint = hex(0xF0F9DF)      // filled cards
    static let cardOutline = hex(0xE8F6CB)   // 1px border of outlined cards
    static let rateTint = hex(0xE2FDB4)      // progress panels, tab bar
    static let highlight = hex(0xF8D848)     // ONE most-important card per screen
    static let ink = hex(0x0E100B)           // tab bar icons and labels

    // MARK: Recommended (readable text and buttons)
    static let leafDeep = hex(0x467017)      // primary button (white text 5.9:1), green text
    static let barkSoft = hex(0x7D6656)      // secondary text
    static let citrusInk = hex(0x94590A)     // Use Soon text
    static let tomatoInk = hex(0xA83A27)     // Urgent / error text

    // MARK: Freshness states
    static func status(_ level: FreshnessLevel) -> Color {
        switch level {
        case .fresh: return leafDeep
        case .useSoon: return citrusInk
        case .urgent: return tomatoInk
        case .expired: return barkSoft
        }
    }

    // MARK: Type
    // Bagel Fat One = page titles only. Anek Latin = everything else.
    enum Face {
        static let display = "BagelFatOne-Regular"
        static func body(_ weight: Font.Weight) -> String {
            switch weight {
            case .medium: return "AnekLatin-Medium"
            case .semibold: return "AnekLatin-SemiBold"
            case .bold, .heavy, .black: return "AnekLatin-Bold"
            default: return "AnekLatin-Regular"
            }
        }
    }

    static func title(_ size: CGFloat = 48) -> Font { .custom(Face.display, size: size) }      // Title 48
    static func title2(_ size: CGFloat = 48) -> Font { .custom(Face.body(.bold), size: size) } // Title 2 48 Bold
    static let title3 = Font.custom(Face.body(.bold), size: 24)                                 // Title 3 24 Bold
    static let largeButton = Font.custom(Face.body(.semibold), size: 24)                        // Large Button 24 SemiBold
    static let bodyText = Font.custom(Face.body(.regular), size: 14)                            // Body Text 14
    static let button = Font.custom(Face.body(.medium), size: 12)                               // Button 12

    /// Drop-in for `.system(size:weight:design: .rounded)` used across the pages:
    /// big heavy text becomes the Bagel Fat One title, everything else Anek Latin.
    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        if size >= 28 && (weight == .heavy || weight == .black) {
            return .custom(Face.display, size: size)
        }
        return .custom(Face.body(weight), size: size)
    }

    // MARK: Font registration
    // Registers the .ttf files in Fonts/ at launch (no Info.plist entry needed).
    static func registerFonts() {
        let names = ["BagelFatOne-Regular", "AnekLatin-Regular", "AnekLatin-Medium",
                     "AnekLatin-SemiBold", "AnekLatin-Bold"]
        for name in names {
            guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
                print("Font file missing: \(name).ttf")
                continue
            }
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }

    private static func hex(_ value: UInt32) -> Color {
        Color(red: Double((value >> 16) & 0xFF) / 255,
              green: Double((value >> 8) & 0xFF) / 255,
              blue: Double(value & 0xFF) / 255)
    }
}
