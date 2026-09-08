import UIKit

public enum Haptics {
    public static func tap() { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
    public static func success() { UINotificationFeedbackGenerator().notificationOccurred(.success) }
    public static func warning() { UINotificationFeedbackGenerator().notificationOccurred(.warning) }
}
