import SwiftUI

private struct FridgeArrivalModifier: ViewModifier {
    let itemID: UUID
    @EnvironmentObject private var foodStore: FoodStore
    @EnvironmentObject private var router: AppRouter
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var playCount = 0

    private struct PlaybackID: Hashable {
        let itemID: UUID
        let isFridgeVisible: Bool
    }

    func body(content: Content) -> some View {
        content
            .keyframeAnimator(initialValue: 0.0, trigger: playCount) { view, angle in
                view.rotationEffect(.degrees(angle))
            } keyframes: { _ in
                // Two complete left-right-center shakes, then stay at zero.
                CubicKeyframe(-4.0, duration: 0.08)
                CubicKeyframe(4.0, duration: 0.08)
                CubicKeyframe(0.0, duration: 0.08)
                CubicKeyframe(-4.0, duration: 0.08)
                CubicKeyframe(4.0, duration: 0.08)
                CubicKeyframe(0.0, duration: 0.08)
            }
            .task(id: PlaybackID(itemID: itemID, isFridgeVisible: router.selectedTab == .fridge)) {
                guard router.selectedTab == .fridge else { return }
                let firstAppearance = foodStore.consumeFridgeArrival(for: itemID)
                guard firstAppearance, !reduceMotion else { return }
                playCount += 1
            }
    }
}

extension View {
    func fridgeArrivalShake(itemID: UUID) -> some View {
        modifier(FridgeArrivalModifier(itemID: itemID))
    }
}
