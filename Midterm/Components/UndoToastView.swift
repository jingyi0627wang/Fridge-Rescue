import SwiftUI

/// Small game-style bar shown at the bottom after an action, with an Undo button.
/// e.g. "Rescued Milk! +20 XP". Disappears by itself after 4 seconds.
/// Shown by MainTabView.
struct UndoToastView: View {
    @EnvironmentObject var foodStore: FoodStore
    let toast: FoodStore.UndoToast

    var body: some View {
        HStack(spacing: 10) {
            FreshlingMascot(size: 30)

            Text(toast.message)
                .font(.ui(15, .medium))
                .foregroundStyle(Game.brown)
                .lineLimit(2)

            Spacer(minLength: 8)

            Button("Undo") {
                withAnimation { foodStore.undo() }
            }
            .font(.ui(15, .semibold))
            .foregroundStyle(Game.greenInk)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Capsule().fill(Game.mint))
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
        )
        .shadow(color: Game.brown.opacity(0.12), radius: 12, y: 6)
        .padding(.horizontal, 16)
        .task(id: toast.id) {
            try? await Task.sleep(for: .seconds(4))
            withAnimation { foodStore.dismissToast(toast.id) }
        }
    }
}
