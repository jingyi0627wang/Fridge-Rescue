import SwiftUI
import UIKit

// MARK: - Kitchen game pieces
// Built on the colors and font in AppStyle.swift:
//   • Fridge pieces   – fridge body, shelf tags, glass shelves, food tiles
//   • RecipeBookCard  – recipe card with the fridge food it uses
//   • Wiggle / bob    – small idle animations
//   • LevelUpView     – "Level up" celebration with confetti

extension Game {
    // Fridge colors
    static let fridgeTop = Color.white
    static let fridgeBottom = hex(0xF6FAFB)
    static let ice = hex(0xE3EEF2)
    static let iceLight = hex(0xEEF5F8)
}

// MARK: - Idle animations

private enum WigglePhase: CaseIterable {
    case rest, left, right, left2, right2

    var angle: Double {
        switch self {
        case .rest: return 0
        case .left: return -4
        case .right: return 4
        case .left2: return -2
        case .right2: return 2
        }
    }
}

/// Urgent food shakes a little every couple of seconds ("rescue me!").
private struct WiggleModifier: ViewModifier {
    let isOn: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func body(content: Content) -> some View {
        if isOn && !reduceMotion {
            content.phaseAnimator(WigglePhase.allCases) { view, phase in
                view.rotationEffect(.degrees(phase.angle))
            } animation: { phase in
                phase == .rest ? .easeInOut(duration: 2.4) : .easeInOut(duration: 0.1)
            }
        } else {
            content
        }
    }
}

/// The mascot gently bobs up and down.
private struct BobModifier: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content.phaseAnimator([false, true]) { view, up in
                view.offset(y: up ? -4 : 0)
            } animation: { _ in
                .easeInOut(duration: 0.9)
            }
        }
    }
}

extension View {
    func wiggle(_ isOn: Bool) -> some View {
        modifier(WiggleModifier(isOn: isOn))
    }

    func bob() -> some View {
        modifier(BobModifier())
    }
}

// MARK: - Fridge
// The fridge is the one playful element: a soft white fridge interior with
// frosted shelves. Everything else in the app stays calm.

struct FridgeBody<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(.horizontal, 14)
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(LinearGradient(colors: [Game.fridgeTop, Game.fridgeBottom],
                                     startPoint: .top, endPoint: .bottom))
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: Game.brown.opacity(0.07), radius: 14, y: 6)
        .padding(.bottom, 6)
    }
}

/// Shelf name with a colored dot: "Use first", "This week"…
struct ShelfTag: View {
    let title: LocalizedStringKey
    let color: Color
    let count: Int

    var body: some View {
        HStack(spacing: 7) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(title)
            Spacer()
            Text("\(count)")
                .foregroundStyle(Game.edgeDark)
        }
        .font(.system(size: 13, weight: .semibold))
        .foregroundStyle(Game.brownSoft)
        .padding(.top, 12)
    }
}

/// Frosted glass shelf under each row of food.
struct GlassShelf: View {
    var body: some View {
        Rectangle()
            .fill(LinearGradient(colors: [Game.iceLight, Game.ice], startPoint: .top, endPoint: .bottom))
            .frame(height: 6)
            .overlay(alignment: .top) { Rectangle().fill(.white).frame(height: 1) }
            .padding(.horizontal, -14)
            .padding(.top, 12)
            .accessibilityHidden(true)
    }
}

/// One food on a shelf: picture, quantity, name, tiny HP bar.
struct FridgeTile: View {
    let item: FoodItem

    var body: some View {
        VStack(spacing: 4) {
            FreshlingAvatar(item: item, size: 60)
                .overlay(alignment: .bottomTrailing) {
                    if item.quantity > 1 {
                        Text("\(item.quantity)")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(Game.brown)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(
                                Capsule().fill(.white)
                                    .shadow(color: .black.opacity(0.1), radius: 2, y: 1)
                            )
                            .offset(x: 4, y: 2)
                    }
                }
                .wiggle(item.freshnessLevel == .urgent)

            Text(item.name)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(Game.brown)
                .lineLimit(1)

            HPBar(item: item, segmentWidth: 6, height: 3, showsLabel: false)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(item.name), \(item.daysLeftText)")
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Recipe card

struct RecipeBookCard: View {
    let recipe: Recipe
    let fridgeCount: Int
    /// The food that expires soonest that this recipe uses (if any).
    let rescueFood: FoodItem?
    /// Fridge food this recipe uses (shown as little pictures).
    let uses: [FoodItem]

    var body: some View {
        HStack(spacing: 12) {
            RecipeThumbnail(recipe: recipe, size: 62)

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Game.brown)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if let rescueFood {
                    Text("Rescues \(rescueFood.name) · \(rescueFood.daysLeftText.lowercased())")
                        .font(.game(13, .medium))
                        .foregroundStyle(rescueFood.freshnessLevel.tint)
                        .lineLimit(1)
                } else {
                    Text("\(fridgeCount) of \(recipe.items.count) in your fridge")
                        .font(.game(13, .medium))
                        .foregroundStyle(Game.brownSoft)
                        .lineLimit(1)
                }

                HStack(spacing: 4) {
                    if !uses.isEmpty {
                        Text("Uses")
                            .font(.game(12, .semibold))
                            .foregroundStyle(Game.brownSoft)
                    }
                    ForEach(Array(uses.prefix(5))) { item in
                        FoodIconView(name: item.name, category: item.category, size: 19)
                            .padding(3)
                            .background(Circle().fill(Game.mint))
                    }
                    Text(verbatim: uses.isEmpty ? recipe.timeText : "· \(recipe.timeText)")
                        .font(.game(12, .medium))
                        .foregroundStyle(Game.brownSoft)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Game.edgeDark)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.white)
                .shadow(color: Game.brown.opacity(0.07), radius: 12, y: 5)
        )
        .contentShape(Rectangle())
    }
}

// MARK: - Level up!

private struct ConfettiPiece: Identifiable {
    let id: Int
    let x: CGFloat          // 0…1 across the screen
    let color: Color
    let spin: Double
    let duration: Double
    let delay: Double
}

/// Confetti falling once from the top of the screen.
struct ConfettiView: View {
    @State private var falling = false
    /// Made once, so the confetti doesn't jump if the screen redraws.
    @State private var pieces: [ConfettiPiece] = ConfettiView.makePieces()

    private static func makePieces() -> [ConfettiPiece] {
        (0..<36).map { index in
        ConfettiPiece(
            id: index,
            x: CGFloat.random(in: 0...1),
            color: [Game.red, Game.orange, Game.green, Game.blue, Game.pink, Game.yellow].randomElement() ?? Game.green,
            spin: Double.random(in: 180...720),
            duration: Double.random(in: 1.8...3.2),
            delay: Double.random(in: 0...0.6)
        )
        }
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(pieces) { piece in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(piece.color)
                        .frame(width: 8, height: 13)
                        .rotationEffect(.degrees(falling ? piece.spin : 0))
                        .position(x: piece.x * geometry.size.width,
                                  y: falling ? geometry.size.height + 40 : -40)
                        .animation(.easeIn(duration: piece.duration).delay(piece.delay), value: falling)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .onAppear { falling = true }
        .accessibilityHidden(true)
    }
}

/// Full-screen celebration shown by MainTabView when FoodStore.levelUp is set.
struct LevelUpView: View {
    let level: Int
    let onDone: () -> Void

    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Game.brown.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture(perform: onDone)

            if !reduceMotion {
                ConfettiView()
            }

            VStack(spacing: 6) {
                Text("Level up!")
                    .font(.game(34, .bold))
                    .foregroundStyle(Game.orange)

                FreshlingMascot(size: 100)
                    .bob()
                    .padding(.vertical, 6)

                Text("Level \(level)")
                    .font(.game(24, .bold))
                    .foregroundStyle(Game.brown)

                Text("You're now a")
                    .font(.game(16, .medium))
                    .foregroundStyle(Game.brownSoft)
                Text(LocalizedStringKey(LevelInfo.title(for: level)))
                    .font(.game(20, .bold))
                    .foregroundStyle(Game.orangeDark)

                Button("Awesome!", action: onDone)
                    .buttonStyle(.chunky(.green))
                    .padding(.top, 12)
            }
            .frame(maxWidth: 320)
            .gameCard(padding: 22, radius: 30)
            .padding(.horizontal, 30)
            .scaleEffect(appeared ? 1 : 0.6)
            .opacity(appeared ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.5, bounce: 0.45)) { appeared = true }
            FreshlingsHaptics.success()
        }
    }
}
