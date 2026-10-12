import FactoryKit
import SwiftUI

/// The seven backs, each a `Canvas` inside a 3 pt inset border, as `design/cards.js` draws them.
struct CardBack: View {
    let kind: Back
    let width: CGFloat

    var body: some View {
        Canvas { gc, size in
            let w = size.width, h = size.height
            let inset = w * 0.06, r = w * 0.05
            let inner = CGRect(x: inset, y: inset, width: w - inset * 2, height: h - inset * 2)
            let frame = Path(roundedRect: inner, cornerRadius: r)
            let blue = AppBrand.lattice
            let brassDeep = AppBrand.CardBox.brassDeep
            let ink = AppBrand.CardBox.ink

            switch kind {
            case .lattice, .brassLattice:
                let c = kind == .lattice ? blue : brassDeep
                var g = gc
                g.clip(to: frame)
                let pitch = w * 0.15
                var lines = Path()
                var x = -h
                while x < w + h {
                    lines.move(to: CGPoint(x: x, y: 0)); lines.addLine(to: CGPoint(x: x + h, y: h))
                    lines.move(to: CGPoint(x: x, y: h)); lines.addLine(to: CGPoint(x: x + h, y: 0))
                    x += pitch * 1.414
                }
                g.stroke(lines, with: .color(c.opacity(0.9)), lineWidth: w * 0.022)
                gc.stroke(frame, with: .color(c), lineWidth: w * 0.03)
                var lozenge = Path()
                lozenge.move(to: CGPoint(x: w / 2, y: h / 2 - w * 0.12))
                lozenge.addLine(to: CGPoint(x: w / 2 + w * 0.09, y: h / 2))
                lozenge.addLine(to: CGPoint(x: w / 2, y: h / 2 + w * 0.12))
                lozenge.addLine(to: CGPoint(x: w / 2 - w * 0.09, y: h / 2))
                lozenge.closeSubpath()
                gc.fill(lozenge, with: .color(AppBrand.CardBox.stock))
                gc.stroke(lozenge, with: .color(c), lineWidth: w * 0.025)

            case .chevron:
                var g = gc
                g.clip(to: frame)
                let p = w * 0.22
                var path = Path()
                var y: CGFloat = inset
                while y < h {
                    var x: CGFloat = 0
                    path.move(to: CGPoint(x: x, y: y + p * 0.5))
                    while x < w {
                        path.addLine(to: CGPoint(x: x + p / 2, y: y))
                        path.addLine(to: CGPoint(x: x + p, y: y + p * 0.5))
                        x += p
                    }
                    y += p * 0.5
                }
                g.stroke(path, with: .color(blue), lineWidth: w * 0.03)
                gc.stroke(frame, with: .color(blue), lineWidth: w * 0.03)

            case .houndstooth:
                var g = gc
                g.clip(to: frame)
                let p = w * 0.2
                var path = Path()
                var y: CGFloat = 0
                while y < h {
                    var x: CGFloat = 0
                    while x < w {
                        path.addRect(CGRect(x: x, y: y, width: p / 2, height: p / 2))
                        path.addRect(CGRect(x: x + p / 2, y: y + p / 2, width: p / 2, height: p / 2))
                        path.move(to: CGPoint(x: x + p / 2, y: y)); path.addLine(to: CGPoint(x: x + p, y: y + p / 2)); path.addLine(to: CGPoint(x: x + p, y: y)); path.closeSubpath()
                        path.move(to: CGPoint(x: x, y: y + p / 2)); path.addLine(to: CGPoint(x: x + p / 2, y: y + p)); path.addLine(to: CGPoint(x: x, y: y + p)); path.closeSubpath()
                        x += p
                    }
                    y += p
                }
                g.fill(path, with: .color(ink.opacity(0.7)))
                gc.stroke(frame, with: .color(ink.opacity(0.7)), lineWidth: w * 0.03)

            case .stars:
                gc.fill(frame, with: .color(blue))
                var g = gc
                g.clip(to: frame)
                let p = w * 0.2, s = w * 0.05
                var y = p / 2
                while y < h {
                    var x = p / 2
                    while x < w {
                        var star = Path()
                        star.move(to: CGPoint(x: x, y: y - s))
                        star.addQuadCurve(to: CGPoint(x: x + s, y: y), control: CGPoint(x: x, y: y))
                        star.addQuadCurve(to: CGPoint(x: x, y: y + s), control: CGPoint(x: x, y: y))
                        star.addQuadCurve(to: CGPoint(x: x - s, y: y), control: CGPoint(x: x, y: y))
                        star.addQuadCurve(to: CGPoint(x: x, y: y - s), control: CGPoint(x: x, y: y))
                        g.fill(star, with: .color(AppBrand.brand.palette.accent))
                        x += p
                    }
                    y += p
                }

            case .leaf:
                let green = AppBrand.CardBox.green
                gc.stroke(frame, with: .color(green), lineWidth: w * 0.025)
                var leaf = Path()
                leaf.move(to: CGPoint(x: w / 2, y: h * 0.28))
                leaf.addCurve(to: CGPoint(x: w / 2, y: h * 0.74), control1: CGPoint(x: w * 0.82, y: h * 0.4), control2: CGPoint(x: w * 0.8, y: h * 0.66))
                leaf.addCurve(to: CGPoint(x: w / 2, y: h * 0.28), control1: CGPoint(x: w * 0.2, y: h * 0.66), control2: CGPoint(x: w * 0.18, y: h * 0.4))
                leaf.move(to: CGPoint(x: w / 2, y: h * 0.3))
                leaf.addLine(to: CGPoint(x: w / 2, y: h * 0.72))
                gc.stroke(leaf, with: .color(green), style: StrokeStyle(lineWidth: w * 0.03, lineJoin: .round))

            case .seal:
                gc.stroke(frame, with: .color(brassDeep), lineWidth: w * 0.025)
                let R = w * 0.3
                gc.stroke(Path(ellipseIn: CGRect(x: w / 2 - R, y: h / 2 - R, width: R * 2, height: R * 2)),
                          with: .color(brassDeep), lineWidth: w * 0.03)
                for (i, suit) in Suit.allCases.enumerated() {
                    let a = -Double.pi / 2 + Double(i) * .pi / 2
                    let sz = w * 0.16
                    let rect = CGRect(x: w / 2 + cos(a) * R * 0.62 - sz / 2, y: h / 2 + sin(a) * R * 0.62 - sz / 2, width: sz, height: sz)
                    gc.fill(PipShape(suit: suit).path(in: rect), with: .color(brassDeep))
                }
            }
        }
        .frame(width: width, height: width * 1.4)
        .accessibilityHidden(true)
    }
}
