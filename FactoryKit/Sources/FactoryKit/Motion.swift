import SwiftUI
import UIKit

/// One set of springs for every app, and the switch that lets the capture tooling photograph
/// an app that moves.
///
/// The simulator capture waits for the screen to stop changing, and the first apps answered
/// that by never moving at all — "a lift rather than a bounce: the capture tooling waits for
/// the screen to stop moving". A still app is the wrong fix. The right one is here: looping
/// motion goes through these helpers, which stand still when the app is launched with
/// `-stillFrames` (as `verify-app.sh` launches every capture), and one-shot effects such as
/// confetti render their peak frame instead of nothing.
public enum Motion {
    /// The capture tooling launched the app. Looping motion pauses; celebrations freeze at
    /// their peak; sounds stay quiet.
    public static let isStill = ProcessInfo.processInfo.arguments.contains("-stillFrames")

    /// Quick and settled: selection, toggles, small moves.
    public static let snappy = Animation.spring(response: 0.3, dampingFraction: 0.8)
    /// A visible overshoot: things arriving, pieces landing.
    public static let bouncy = Animation.spring(response: 0.45, dampingFraction: 0.62)
    /// Slow and soft: large layout changes, calm apps.
    public static let gentle = Animation.spring(response: 0.7, dampingFraction: 0.9)
    /// A pop: badges, counters, confirmations.
    public static let pop = Animation.spring(response: 0.26, dampingFraction: 0.55)

    /// What `animation` becomes for a capture (none) or for someone with Reduce Motion on (a
    /// short cross-fade, so state still changes visibly without anything travelling).
    public static func resolved(_ animation: Animation) -> Animation? {
        if isStill { return nil }
        if UIAccessibility.isReduceMotionEnabled { return .easeInOut(duration: 0.2) }
        return animation
    }
}

/// `withAnimation`, standing down for the capture tooling and for Reduce Motion.
@discardableResult
public func withMotion<Result>(_ animation: Animation = Motion.snappy, _ body: () throws -> Result) rethrows -> Result {
    try withAnimation(Motion.resolved(animation), body)
}

// MARK: - Pressable content

/// For content the app draws and the user taps — tiles, cards, game pieces — as opposed to a
/// system control. Squashes on press with a spring and answers with a soft haptic, so every
/// touch gets a response inside a frame.
public struct PressableButtonStyle: ButtonStyle {
    let scale: CGFloat
    let haptic: Bool

    public init(scale: CGFloat = 0.95, haptic: Bool = true) {
        self.scale = scale
        self.haptic = haptic
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .brightness(configuration.isPressed ? -0.03 : 0)
            .animation(Motion.isStill ? nil : Motion.pop, value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed && haptic { Haptics.soft() }
            }
    }
}

public extension ButtonStyle where Self == PressableButtonStyle {
    static var pressable: PressableButtonStyle { PressableButtonStyle() }
    static func pressable(scale: CGFloat = 0.95, haptic: Bool = true) -> PressableButtonStyle {
        PressableButtonStyle(scale: scale, haptic: haptic)
    }
}

// MARK: - Entrances, ambience, feedback

public extension View {
    /// Arrives with a spring from slightly small and transparent. Stagger siblings with
    /// `delay` (0.04–0.08 s apart) so a screen assembles rather than appears.
    func popIn(delay: Double = 0) -> some View {
        modifier(PopIn(delay: delay))
    }

    /// A slow bob, for art that should feel alive: a mascot, a hero object, a floating badge.
    func ambientFloat(amplitude: CGFloat = 6, period: Double = 3.6) -> some View {
        modifier(AmbientFloat(amplitude: amplitude, period: period))
    }

    /// A slow swell in scale, for glows and things that should feel lit from inside.
    func breathing(amount: CGFloat = 0.04, period: Double = 3.2) -> some View {
        modifier(Breathing(amount: amount, period: period))
    }

    /// A short, forgiving shake each time `trigger` changes: a wrong answer, an illegal move.
    func shake<T: Equatable>(trigger: T) -> some View {
        modifier(Shake(trigger: trigger))
    }
}

private struct PopIn: ViewModifier {
    let delay: Double
    @State private var shown = Motion.isStill
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(shown || reduceMotion ? 1 : 0.82)
            .opacity(shown ? 1 : 0)
            .onAppear {
                guard !shown else { return }
                let animation = reduceMotion ? Animation.easeOut(duration: 0.2) : Motion.bouncy
                withAnimation(animation.delay(delay)) { shown = true }
            }
    }
}

private struct AmbientFloat: ViewModifier {
    let amplitude: CGFloat
    let period: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let still = Motion.isStill || reduceMotion
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: still)) { context in
            let t = still ? 0 : context.date.timeIntervalSinceReferenceDate
            content.offset(y: CGFloat(sin(t * 2 * .pi / period)) * amplitude)
        }
    }
}

private struct Breathing: ViewModifier {
    let amount: CGFloat
    let period: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        let still = Motion.isStill || reduceMotion
        TimelineView(.animation(minimumInterval: 1.0 / 60, paused: still)) { context in
            let t = still ? 0 : context.date.timeIntervalSinceReferenceDate
            content.scaleEffect(1 + amount * CGFloat(0.5 + 0.5 * sin(t * 2 * .pi / period)))
        }
    }
}

private struct Shake<T: Equatable>: ViewModifier {
    let trigger: T
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        if reduceMotion || Motion.isStill {
            content
        } else {
            content.keyframeAnimator(initialValue: CGFloat.zero, trigger: trigger) { view, x in
                view.offset(x: x)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(-11, duration: 0.07)
                    CubicKeyframe(9, duration: 0.08)
                    CubicKeyframe(-5, duration: 0.08)
                    CubicKeyframe(2, duration: 0.07)
                    SpringKeyframe(0, duration: 0.2)
                }
            }
        }
    }
}

// MARK: - Counting

/// A number that counts to its value — a score, a streak, a total — instead of appearing.
/// Style it like text: `CountUp(to: 8).brandDisplay(size: 96)`.
///
/// `onTick` fires on every step, for a haptic or a rising tone. Under `-stillFrames` the final
/// value shows at once.
public struct CountUp: View {
    private let value: Int
    private let duration: Double
    private let onTick: ((Int) -> Void)?
    @State private var shown: Int

    public init(to value: Int, from start: Int = 0, duration: Double = 0.8, onTick: ((Int) -> Void)? = nil) {
        self.value = value
        self.duration = duration
        self.onTick = onTick
        _shown = State(initialValue: Motion.isStill ? value : start)
    }

    public var body: some View {
        Text("\(shown)")
            .monospacedDigit()
            .contentTransition(.numericText(value: Double(shown)))
            .accessibilityLabel("\(value)")
            .task(id: value) { await count() }
    }

    private func count() async {
        guard !Motion.isStill, !UIAccessibility.isReduceMotionEnabled else {
            shown = value
            return
        }
        let distance = value - shown
        guard distance != 0 else { return }
        // At most ~24 steps however large the number, so a big total still lands on time.
        let steps = min(abs(distance), 24)
        let pause = UInt64(duration / Double(steps) * 1_000_000_000)
        for step in 1...steps {
            try? await Task.sleep(nanoseconds: pause)
            if Task.isCancelled { return }
            let next = shown + (value - shown) / (steps - step + 1)
            withAnimation(Motion.snappy) { shown = next }
            onTick?(next)
        }
        shown = value
    }
}
