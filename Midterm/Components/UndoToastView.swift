import SwiftUI

/// Small bar shown at the bottom after an action, with an Undo button.
/// Disappears by itself after 4 seconds. Shown by MainTabView.
struct UndoToastView: View {
    @EnvironmentObject var foodStore: FoodStore
    let toast: FoodStore.UndoToast

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color(red: 0.53, green: 0.89, blue: 0.36))

            Text(toast.message)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .lineLimit(2)

            Spacer(minLength: 8)

            Button("Undo") {
                withAnimation { foodStore.undo() }
            }
            .font(.system(size: 14, weight: .heavy, design: .rounded))
            .foregroundStyle(Color(red: 0.53, green: 0.89, blue: 0.36))
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(Color(red: 0.20, green: 0.24, blue: 0.18), in: Capsule())
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
        .padding(.horizontal, 16)
        .task(id: toast.id) {
            try? await Task.sleep(for: .seconds(4))
            withAnimation { foodStore.dismissToast(toast.id) }
        }
    }
}
