
import UIKit

enum FreshlingsHaptics {

    // Food added or saved successfully
    static func success() {
        UINotificationFeedbackGenerator()
            .notificationOccurred(.success)
    }

    // Stronger feedback for I Cooked This
    static func cookingComplete() {
        UIImpactFeedbackGenerator(style: .heavy)
            .impactOccurred()
    }

    // Food marked as thrown away
    static func light() {
        UIImpactFeedbackGenerator(style: .light)
            .impactOccurred()
    }

    // A confirmed operation failed
    static func error() {
        UINotificationFeedbackGenerator()
            .notificationOccurred(.error)
    }

    // Changing quantity or selecting an option
    static func selection() {
        UISelectionFeedbackGenerator()
            .selectionChanged()
    }
}

