import UIKit

/// The phone answering back. Every touch that changes something deserves one; pick by weight.
public enum Haptics {
    /// A light tap: buttons, small confirmations.
    public static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    /// A detent: picking between options, scrubbing, a piece snapping to a slot.
    public static func selection() { UISelectionFeedbackGenerator().selectionChanged() }
    /// Cushioned: pressing into content, a drop landing in liquid.
    public static func soft() { UIImpactFeedbackGenerator(style: .soft).impactOccurred() }
    /// Crisp: a card flipping, a lock clicking, a tile landing on a hard surface.
    public static func rigid() { UIImpactFeedbackGenerator(style: .rigid).impactOccurred() }
    /// Weighty: something big arriving, a level's last piece.
    public static func thud() { UIImpactFeedbackGenerator(style: .heavy).impactOccurred() }
    /// An impact scaled 0…1, for things that grow: combos, streak days, a count-up's ticks.
    public static func impact(_ intensity: CGFloat) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: max(0, min(1, intensity)))
    }
    public static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    public static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
    public static func error() { UINotificationFeedbackGenerator().notificationOccurred(.error) }
    /// Finishing the loop: a firm beat, then the success pattern on top of it.
    public static func celebrate() {
        thud()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { success() }
    }
}
