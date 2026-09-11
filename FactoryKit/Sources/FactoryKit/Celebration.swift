import SwiftUI

public extension View {
    /// Confetti over the view each time `trigger` changes — and once on appear with
    /// `onAppear: true`, for a screen that *is* the win.
    ///
    /// Drawn in one `Canvas`: no view per particle, no assets. Colors default to the brand's
    /// accent, highlight, success and extras. `power` scales the burst: 0.3 for a small
    /// flourish on one piece, 1 for a level, 1.4 for a perfect run. Stands down for Reduce
    /// Motion; under `-stillFrames` it freezes at its peak, so a capture of the win shows it.
    func confetti(trigger: Int,
                  colors: [Color]? = nil,
                  from origin: UnitPoint = UnitPoint(x: 0.5, y: 0.35),
                  rain: Bool = false,
                  count: Int = 90,
                  power: CGFloat = 1,
                  onAppear: Bool = false) -> some View {
        overlay {
            ConfettiView(trigger: trigger, colors: colors, origin: origin, rain: rain,
                         count: count, power: power, fireOnAppear: onAppear)
        }
    }
}

struct ConfettiView: View {
    let trigger: Int
    let colors: [Color]?
    let origin: UnitPoint
    let rain: Bool
    let count: Int
    let power: CGFloat
    let fireOnAppear: Bool

    @Environment(\.brand) private var brand
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var started: Date?
    @State private var seed: UInt64 = 1

    /// How long a burst lives.
    private static let life: Double = 2.8
    /// The frame a still capture shows: the burst open, nothing yet fallen away.
    private static let peak: Double = 0.5

    var body: some View {
        TimelineView(.animation(paused: started == nil || Motion.isStill)) { context in
            if let t = elapsed(at: context.date), t < Self.life {
                Canvas { gc, size in
                    draw(in: &gc, size: size, at: t)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { if fireOnAppear { fire() } }
        .onChange(of: trigger) { _, _ in fire() }
    }

    private func elapsed(at date: Date) -> Double? {
        guard let started else { return nil }
        return Motion.isStill ? Self.peak : date.timeIntervalSince(started)
    }

    private func fire() {
        guard !reduceMotion else { return }
        seed = UInt64(truncatingIfNeeded: trigger) &* 0x9E37_79B9_7F4A_7C15 &+ 1
        let now = Date()
        started = now
        guard !Motion.isStill else { return }
        // Stop the timeline once the burst is over, rather than redrawing nothing at 120 Hz.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(Self.life * 1_000_000_000))
            if started == now { started = nil }
        }
    }

    private var palette: [Color] {
        if let colors, !colors.isEmpty { return colors }
        return [brand.palette.accent, brand.palette.highlight, brand.palette.success] + brand.palette.extras
    }

    private func draw(in gc: inout GraphicsContext, size: CGSize, at t: Double) {
        var rng = SplitMix(seed: seed)
        let colors = palette
        // Linear drag with gravity, solved in closed form so any frame can be drawn directly —
        // which is what lets a still capture show the peak without simulating up to it.
        let drag = 2.1
        let gravity = 420.0
        let decay = (1 - exp(-drag * t)) / drag
        let fade = min(1, (Self.life - t) / 0.7)

        for _ in 0..<count {
            let angle: Double
            let speed: Double
            var x0 = origin.x * size.width
            var y0 = origin.y * size.height
            if rain {
                x0 = rng.unit() * size.width
                y0 = -20 - rng.unit() * size.height * 0.5
                angle = .pi / 2 + (rng.unit() - 0.5) * 0.6
                speed = 80 + rng.unit() * 120
            } else {
                // Mostly upward, fanned out, so the burst opens like a firework and falls.
                angle = -.pi / 2 + (rng.unit() - 0.5) * .pi * 1.3
                speed = (420 + rng.unit() * 720) * Double(power)
            }
            let vx = cos(angle) * speed
            let vy = sin(angle) * speed
            let x = x0 + vx * decay
            let y = y0 + (vy - gravity / drag) * decay + gravity / drag * t

            let spin = (rng.unit() - 0.5) * 14
            let flip = cos(rng.unit() * .pi * 2 + t * (4 + rng.unit() * 6))
            let w = 5 + rng.unit() * 6
            let h = w * (0.45 + rng.unit() * 0.9)
            let shape = Int(rng.unit() * 3)
            let color = colors[Int(rng.unit() * Double(colors.count)) % colors.count]

            var piece = gc
            piece.opacity = fade
            piece.translateBy(x: x, y: y)
            piece.rotate(by: .radians(spin * t))
            piece.scaleBy(x: max(0.15, abs(flip)), y: 1)
            let rect = CGRect(x: -w / 2, y: -h / 2, width: w, height: h)
            let path: Path
            switch shape {
            case 0: path = Path(ellipseIn: CGRect(x: -w / 2, y: -w / 2, width: w, height: w))
            case 1: path = Path(roundedRect: rect, cornerRadius: 1.5)
            default:
                var tri = Path()
                tri.move(to: CGPoint(x: 0, y: -h / 2))
                tri.addLine(to: CGPoint(x: w / 2, y: h / 2))
                tri.addLine(to: CGPoint(x: -w / 2, y: h / 2))
                tri.closeSubpath()
                path = tri
            }
            piece.fill(path, with: .color(color))
        }
    }
}

/// A small deterministic generator: the same trigger always draws the same burst, so a
/// capture is repeatable.
private struct SplitMix {
    var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
}
