import FactoryKit
import SwiftUI

/// The cloth's nap: a seeded field of 1 pt flecks, about one per 9 pt², from a fixed constant
/// so every launch and every screenshot are identical. It never moves.
struct Nap: View {
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        Canvas(rendersAsynchronously: true) { gc, size in
            var s: UInt32 = 0xBA12E
            func rnd() -> CGFloat {
                s = s &* 1_664_525 &+ 1_013_904_223
                return CGFloat(s) / 4_294_967_296
            }
            var flecks = Path()
            let step: CGFloat = 3
            var y: CGFloat = 0
            while y < size.height {
                var x: CGFloat = 0
                while x < size.width {
                    if rnd() < 0.42 {
                        flecks.addRect(CGRect(x: x + rnd() * step, y: y + rnd() * step, width: 1, height: 1))
                    }
                    x += step
                }
                y += step
            }
            gc.fill(flecks, with: .color(.white.opacity(scheme == .dark ? 0.025 : 0.03)))
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension View {
    /// The baize: the brand's canvas, the lamp's glow, breathing, and the nap over it.
    func baize(swell: Bool = false) -> some View {
        background {
            ZStack {
                BrandBackground()
                    .scaleEffect(swell ? 1.12 : 1, anchor: UnitPoint(x: 0.12, y: 0.02))
                    .breathing(amount: 0.03, period: 5)
                Nap()
            }
            .ignoresSafeArea()
        }
        .scrollContentBackground(.hidden)
    }
}

/// The wood of the desk showing round the inset cloth: a 6 pt band of walnut with a highlight
/// on its inner edge.
struct DeskEdge: View {
    var top = true
    @Environment(\.brand) private var brand

    var body: some View {
        brand.palette.surface
            .frame(height: 6)
            .overlay(alignment: top ? .bottom : .top) {
                Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
            }
            .accessibilityHidden(true)
    }
}

/// A brass corner: an L of 14 × 14 pt in brass deep with a lamp highlight.
struct BrassCorner: View {
    var flipped = false

    var body: some View {
        Canvas { gc, size in
            var l = Path()
            l.move(to: CGPoint(x: 0, y: 14))
            l.addLine(to: CGPoint(x: 0, y: 0))
            l.addLine(to: CGPoint(x: 14, y: 0))
            l.addLine(to: CGPoint(x: 14, y: 4))
            l.addLine(to: CGPoint(x: 4, y: 4))
            l.addLine(to: CGPoint(x: 4, y: 14))
            l.closeSubpath()
            gc.fill(l, with: .color(AppBrand.CardBox.brassDeep))
            var hi = Path()
            hi.move(to: CGPoint(x: 0.5, y: 14)); hi.addLine(to: CGPoint(x: 0.5, y: 0.5)); hi.addLine(to: CGPoint(x: 14, y: 0.5))
            gc.stroke(hi, with: .color(AppBrand.CardBox.lamp), lineWidth: 1.2)
        }
        .frame(width: 14, height: 14)
        .rotationEffect(.degrees(flipped ? 180 : 0))
        .accessibilityHidden(true)
    }
}

/// The caps: `.caption2`, uppercase, tracked, in inkSoft — the desk diary's running head.
struct Caps: View {
    let text: String
    var color: Color?
    var style: Font.TextStyle = .caption2
    @Environment(\.brand) private var brand

    init(_ text: String, color: Color? = nil, style: Font.TextStyle = .caption2) {
        self.text = text
        self.color = color
        self.style = style
    }

    var body: some View {
        Text(text)
            .font(.system(style, weight: .medium))
            .textCase(.uppercase)
            .tracking(2)
            .foregroundStyle(color ?? brand.palette.inkSoft)
    }
}

/// `No. 52`, the `No.` at 60 % of the numeral.
struct LedgerNumber: View {
    let number: Int
    let size: CGFloat
    var color: Color?
    @Environment(\.brand) private var brand

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: size * 0.08) {
            Text("No.").brandDisplay(size: size * 0.6)
            Text("\(number)").brandDisplay(size: size)
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .foregroundStyle(color ?? brand.palette.ink)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Number \(number)")
    }
}
