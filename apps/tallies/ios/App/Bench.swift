import FactoryKit
import SwiftUI

// MARK: - The canvas

/// The limewashed workshop wall: 900 short brush strokes drawn once into a `Canvas`, seeded
/// from a fixed constant so every launch and every screenshot is the same wall. It never
/// animates — a moving texture is noise, and DESIGN.md says so.
struct Limewash: View {
    @Environment(\.brand) private var brand
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Canvas { context, size in
            var rng = Seeded(seed: 0x7A11_1E5B_E9C4_0D31)
            let ink = scheme == .dark ? Color.white.opacity(0.030) : brand.palette.ink.opacity(0.028)
            for _ in 0..<900 {
                let x = rng.unit() * size.width
                let y = rng.unit() * size.height
                let length = 8 + rng.unit() * 14
                let angle = (rng.unit() - 0.5) * 6 * .pi / 180
                var stroke = Path()
                stroke.move(to: CGPoint(x: x, y: y))
                stroke.addLine(to: CGPoint(x: x + cos(angle) * length, y: y + sin(angle) * length))
                context.stroke(stroke, with: .color(ink), lineWidth: 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// The brand's canvas with the limewash over it. Everything in the app sits on this.
struct BenchCanvas: View {
    var body: some View {
        BrandBackground()
            .overlay { Limewash() }
            .ignoresSafeArea()
    }
}

/// The app's horizon: which surface the work is lying on. In every screenshot.
struct BenchEdge: View {
    @Environment(\.brand) private var brand

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(brand.palette.highlight.opacity(0.25))
                .frame(height: 1)
            Rectangle()
                .fill(brand.palette.ink.opacity(0.10))
                .frame(height: 3)
        }
        .accessibilityHidden(true)
    }
}

extension View {
    /// The bench under the view, edge to edge, with the `List` and `Form` gray cleared.
    func benchBackground() -> some View {
        scrollContentBackground(.hidden).background { BenchCanvas() }
    }

    /// The marking on the wood: `STAVE 9`, `KEPT 61 DAYS`, `READING`. Never a sentence.
    func stencilCaps() -> some View {
        font(.system(.caption2, design: .monospaced))
            .textCase(.uppercase)
            .tracking(2.6)
    }
}

/// A deterministic generator, so the wall, the tilt of a stave and the grain of a board are
/// the same in every capture.
struct Seeded {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E37_79B9 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }
    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
}

extension String {
    /// A stable number from a string, for a stave's seeded tilt: never random per frame, or
    /// the pile would jitter on every redraw.
    var benchHash: UInt64 {
        var h: UInt64 = 0xCBF2_9CE4_8422_2325
        for byte in utf8 { h = (h ^ UInt64(byte)) &* 0x0000_0100_0000_01B3 }
        return h
    }
}

// MARK: - The shape language

/// The one distinctive shape: a V with two facets at different depths, so it reads as
/// something taken out of the wood rather than drawn on it. It repeats at every scale — the
/// cuts on a stave, the bullet before a paywall line, the mark in the pigment picker.
struct NotchShape: Shape {
    /// Which facet: the near one is in shadow, the far one catches the window.
    let near: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let mid = rect.midX
        if near {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: mid, y: rect.maxY))
            path.addLine(to: CGPoint(x: mid, y: rect.minY))
        } else {
            path.move(to: CGPoint(x: mid, y: rect.minY))
            path.addLine(to: CGPoint(x: mid, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        path.closeSubpath()
        return path
    }
}

/// One cut, drawn. `growth` is the notch opening: a spring past 1 is the 1 pt overshoot that
/// makes the wood give and then hold.
struct NotchMark: View {
    let mark: Mark
    let width: CGFloat
    let depth: CGFloat
    var growth: CGFloat = 1
    var lit: Bool = false

    @Environment(\.brand) private var brand

    var body: some View {
        ZStack {
            if mark == .wax {
                // A wax is a fill, not a cut: the number changed, the mark did not.
                NotchShape(near: true).fill(brand.palette.miss.opacity(0.50))
                NotchShape(near: false).fill(brand.palette.miss.opacity(0.34))
            } else {
                NotchShape(near: true).fill(lit ? brand.palette.highlight.opacity(0.85) : brand.palette.ink.opacity(0.55))
                NotchShape(near: false).fill(lit ? brand.palette.highlight.opacity(0.45) : brand.palette.ink.opacity(0.22))
            }
        }
        .frame(width: width * growth, height: depth)
        .accessibilityHidden(true)
    }
}

/// A bare stave with the first notch cut into it. The toolbar's add button: a chisel was
/// tried at 22 pt in mock 3 and reads as a blob, but this still resolves.
struct BareStaveGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = min(4, rect.height / 3)
        var path = Path(roundedRect: rect, cornerRadius: radius)
        let mid = rect.midX
        let w = rect.width * 0.18
        var notch = Path()
        notch.move(to: CGPoint(x: mid - w / 2, y: rect.minY - 1))
        notch.addLine(to: CGPoint(x: mid, y: rect.minY + rect.height * 0.62))
        notch.addLine(to: CGPoint(x: mid + w / 2, y: rect.minY - 1))
        notch.closeSubpath()
        path = path.subtracting(notch)
        return path
    }
}

// MARK: - The stave

/// A stave of pale ash: the surface everything in this app is written on. Corner radius 5,
/// a darker edge along the bottom and a highlight along the top, so it has thickness rather
/// than a shadow. Nothing in this app is a 22 pt white card.
struct StaveBoard<Content: View>: View {
    var pigment: Color?
    var scored: Bool = false
    var oiled: Bool = false
    @ViewBuilder var content: () -> Content

    @Environment(\.brand) private var brand

    var body: some View {
        content()
            .background {
                ZStack {
                    RoundedRectangle(cornerRadius: brand.corner, style: .continuous)
                        // The oil is earned at twenty staves and has to be visible when it
                        // arrives, or the reward is a line of copy about a colour nobody
                        // can see.
                        .fill(oiled ? brand.palette.surface.mix(with: .cutShadow, amount: 0.28)
                                    : brand.palette.surface)
                    grain
                    if let pigment {
                        HStack(spacing: 0) {
                            UnevenRoundedRectangle(topLeadingRadius: brand.corner,
                                                   bottomLeadingRadius: brand.corner,
                                                   bottomTrailingRadius: 0,
                                                   topTrailingRadius: 0,
                                                   style: .continuous)
                                .fill(pigment)
                                .frame(width: 13)
                            Spacer(minLength: 0)
                        }
                    }
                    RoundedRectangle(cornerRadius: brand.corner, style: .continuous)
                        .strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.45), brand.palette.ink.opacity(0.20)],
                                           startPoint: .top, endPoint: .bottom),
                            lineWidth: 1.2)
                }
            }
            .overlay(alignment: .bottom) {
                if scored { scoringStroke }
            }
    }

    /// Four hairlines with the grain, so the board is wood rather than paper.
    private var grain: some View {
        GeometryReader { geo in
            Canvas { context, size in
                var rng = Seeded(seed: 0x51A5_E6_1234)
                for _ in 0..<7 {
                    let y = rng.unit() * size.height
                    let x0 = rng.unit() * size.width * 0.5
                    let x1 = min(size.width - 2, x0 + size.width * (0.25 + rng.unit() * 0.6))
                    var line = Path()
                    line.move(to: CGPoint(x: x0, y: y))
                    line.addCurve(to: CGPoint(x: x1, y: y + (rng.unit() - 0.5) * 3),
                                  control1: CGPoint(x: x0 + (x1 - x0) * 0.33, y: y + (rng.unit() - 0.5) * 5),
                                  control2: CGPoint(x: x0 + (x1 - x0) * 0.66, y: y - (rng.unit() - 0.5) * 5))
                    context.stroke(line, with: .color(brand.palette.ink.opacity(0.038)), lineWidth: 0.8)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .clipShape(RoundedRectangle(cornerRadius: brand.corner, style: .continuous))
    }

    private var scoringStroke: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 6, y: geo.size.height - 6))
                path.addLine(to: CGPoint(x: geo.size.width - 6, y: 6))
            }
            .stroke(brand.palette.ink.opacity(0.7), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
        .accessibilityHidden(true)
    }
}

extension Color {
    /// The dark at the bottom of a cut, and what the oil takes the ash towards.
    ///
    /// Not `ink`: that flips with the appearance — by night it is the lamplight — so mixing
    /// towards it made every cut on the dark bench *lighter* than the wood it was cut into,
    /// and the strip came out in salmon. Wood in shadow is dark in both appearances.
    static let cutShadow = Color(light: 0x221A0F, dark: 0x0D0A05)

    /// Mixing two brand colours so the oiled bench can darken without a second palette.
    /// `Color.mix(with:by:)` is iOS 18; this works on 17 and gives the same answer.
    func mix(with other: Color, amount: Double) -> Color {
        let a = UIColor(self), b = UIColor(other)
        var ar: CGFloat = 0, ag: CGFloat = 0, ab: CGFloat = 0, aa: CGFloat = 0
        var br: CGFloat = 0, bg: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        a.getRed(&ar, green: &ag, blue: &ab, alpha: &aa)
        b.getRed(&br, green: &bg, blue: &bb, alpha: &ba)
        let t = CGFloat(max(0, min(1, amount)))
        return Color(.sRGB,
                     red: Double(ar + (br - ar) * t),
                     green: Double(ag + (bg - ag) * t),
                     blue: Double(ab + (bb - ab) * t),
                     opacity: Double(aa + (ba - aa) * t))
    }
}

/// The marks along a stave's shoulder: ten gates of five, the fifth cut struck across the
/// four before it. `openingGrowth` opens the newest notch; `strikeProgress` draws the
/// diagonal of the gate that just closed.
struct StaveMarks: View {
    let marks: [Mark]
    var capacity: Int = notchesPerStave
    var notchDepth: CGFloat = 15
    var openingGrowth: CGFloat = 1
    var strikeProgress: CGFloat = 1
    /// How many gates are lit, left to right, during the win's hold.
    var gatesLit: Int = 0
    /// A fixed width per gate, for a window onto a stave — the bench shows the last two gates
    /// and they have to be cut at the same pitch as the fifty on the face, not stretched to
    /// fill the row.
    var gateWidth: CGFloat?

    @Environment(\.brand) private var brand

    private var gateCount: Int { capacity / notchesPerGate }

    var body: some View {
        GeometryReader { geo in
            let gateWidth = gateWidth ?? geo.size.width / CGFloat(gateCount)
            ZStack(alignment: .topLeading) {
                ForEach(0..<gateCount, id: \.self) { gate in
                    gateView(gate, width: gateWidth, height: geo.size.height)
                        .offset(x: CGFloat(gate) * gateWidth)
                }
            }
        }
        .frame(height: notchDepth)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func gateView(_ gate: Int, width: CGFloat, height: CGFloat) -> some View {
        let base = gate * notchesPerGate
        let span = width - 5
        let pitch = span / CGFloat(notchesPerGate - 1)
        let struck = marks.count > base + 4
        let strikingNow = marks.count == base + 5
        ZStack(alignment: .topLeading) {
            ForEach(0..<4, id: \.self) { i in
                if marks.indices.contains(base + i) {
                    let isNewest = base + i == marks.count - 1
                    NotchMark(mark: marks[base + i],
                              width: min(7, pitch * 0.7),
                              depth: notchDepth,
                              growth: isNewest ? openingGrowth : 1,
                              lit: gate < gatesLit)
                        .offset(x: 2 + CGFloat(i) * pitch)
                }
            }
            if struck {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: notchDepth))
                    path.addLine(to: CGPoint(x: span, y: -1))
                }
                .trim(from: 0, to: strikingNow ? strikeProgress : 1)
                .stroke(gate < gatesLit ? brand.palette.highlight.opacity(0.9)
                                        : brand.palette.ink.opacity(marks[base + 4] == .wax ? 0.26 : 0.62),
                        style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                .frame(width: span, height: notchDepth)
            }
        }
        .frame(width: width, height: height, alignment: .topLeading)
    }
}

// MARK: - The tools

/// The chisel: a broad blade with a brass ferrule and an ash handle. It rests on the
/// shoulder at the next notch position and walks along it as the stave fills.
struct ChiselGlyph: View {
    var height: CGFloat = 96

    var body: some View {
        let w = height * 0.30
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: w * 0.45, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xE8CFA0), Color(hex: 0xC49A5C)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: w * 0.78, height: height * 0.44)
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(LinearGradient(colors: [Color(hex: 0xE7B64A), Color(hex: 0xA87A22)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: w * 0.92, height: height * 0.10)
            BladeShape()
                .fill(LinearGradient(colors: [Color(hex: 0xF2F4F6), Color(hex: 0x9AA3AC)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(width: w, height: height * 0.46)
        }
        .rotationEffect(.degrees(18))
        .accessibilityHidden(true)
    }

    private struct BladeShape: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX - rect.width * 0.16, y: rect.maxY - rect.height * 0.22))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.minX + rect.width * 0.16, y: rect.maxY - rect.height * 0.22))
            path.closeSubpath()
            return path
        }
    }
}

/// The wax stick: a dull block of filling wax. Smaller and quieter than the chisel, because
/// taking a cut back is the rarer act — and it is not an alarm.
struct WaxStickGlyph: View {
    var height: CGFloat = 60
    @Environment(\.brand) private var brand

    var body: some View {
        RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(LinearGradient(colors: [brand.palette.miss.opacity(0.95), brand.palette.miss.opacity(0.62)],
                                 startPoint: .topLeading, endPoint: .bottomTrailing))
            .frame(width: height * 0.30, height: height)
            .overlay(alignment: .bottom) {
                Triangle()
                    .fill(brand.palette.miss.opacity(0.45))
                    .frame(width: height * 0.30, height: height * 0.18)
            }
            .rotationEffect(.degrees(-14))
            .accessibilityHidden(true)
    }

    private struct Triangle: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
            path.closeSubpath()
            return path
        }
    }
}
