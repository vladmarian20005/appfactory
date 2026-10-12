import SwiftUI

/// The four suit pips, the three court emblems and the seal — the same paths as
/// `design/cards.js`, read from the same SVG strings so a pip in the app is the pip in the mocks.
enum Pips {
    static let spade = "M50 5 C34 28 10 42 10 62 A19 19 0 0 0 45 72 C43 81 38 88 31 95 L69 95 C62 88 57 81 55 72 A19 19 0 0 0 90 62 C90 42 66 28 50 5 Z"
    static let heart = "M50 92 C24 68 6 52 6 31 A22 22 0 0 1 50 22 A22 22 0 0 1 94 31 C94 52 76 68 50 92 Z"
    static let club = "M50 8 A16 16 0 0 1 63 34 A17 17 0 1 1 57 60 C58 74 62 85 70 95 L30 95 C38 85 42 74 43 60 A17 17 0 1 1 37 34 A16 16 0 0 1 50 8 Z"
    static let diamond = "M50 4 Q70 30 92 50 Q70 70 50 96 Q30 70 8 50 Q30 30 50 4 Z"

    static let paths: [Suit: Path] = [
        .spade: SVGPath.parse(spade), .heart: SVGPath.parse(heart),
        .club: SVGPath.parse(club), .diamond: SVGPath.parse(diamond),
    ]
}

/// A suit pip in its 100 × 100 box, scaled to the frame.
struct PipShape: SwiftUI.Shape {
    let suit: Suit
    func path(in rect: CGRect) -> Path {
        let p = Pips.paths[suit] ?? Path()
        let s = min(rect.width, rect.height) / 100
        return p.applying(CGAffineTransform(translationX: rect.midX - 50 * s, y: rect.midY - 50 * s).scaledBy(x: s, y: s))
    }
}

/// The court emblems, in a 100 × 60 box: a crown of five points, a circlet with one gem, a plume.
struct EmblemShape: SwiftUI.Shape {
    let rank: Int
    func path(in rect: CGRect) -> Path {
        var p = Path()
        switch rank {
        case 13:
            p.move(to: CGPoint(x: 10, y: 52))
            for (x, y) in [(10, 18), (30, 34), (50, 6), (70, 34), (90, 18), (90, 52)] { p.addLine(to: CGPoint(x: x, y: y)) }
            p.closeSubpath()
            p.addRoundedRect(in: CGRect(x: 10, y: 52, width: 80, height: 8), cornerSize: CGSize(width: 2, height: 2))
        case 12:
            p.addEllipse(in: CGRect(x: 14, y: 16, width: 72, height: 36))
            p = p.strokedPath(StrokeStyle(lineWidth: 7))
            p.addEllipse(in: CGRect(x: 43, y: 9, width: 14, height: 14))
        default:
            p.move(to: CGPoint(x: 22, y: 58))
            p.addCurve(to: CGPoint(x: 78, y: 6), control1: CGPoint(x: 22, y: 20), control2: CGPoint(x: 46, y: 4))
            p.addCurve(to: CGPoint(x: 22, y: 58), control1: CGPoint(x: 70, y: 30), control2: CGPoint(x: 56, y: 50))
            p.closeSubpath()
        }
        let s = min(rect.width / 100, rect.height / 60)
        return p.applying(CGAffineTransform(translationX: rect.midX - 50 * s, y: rect.midY - 30 * s).scaledBy(x: s, y: s))
    }
}

/// Enough of SVG's path grammar for the pips: M L C Q A Z, absolute.
enum SVGPath {
    static func parse(_ d: String) -> Path {
        var tokens: [String] = []
        var cur = ""
        for ch in d {
            if ch.isLetter {
                if !cur.isEmpty { tokens.append(cur); cur = "" }
                tokens.append(String(ch))
            } else if ch == " " || ch == "," {
                if !cur.isEmpty { tokens.append(cur); cur = "" }
            } else {
                cur.append(ch)
            }
        }
        if !cur.isEmpty { tokens.append(cur) }

        var p = Path()
        var i = 0
        var cmd = "M"
        var pt = CGPoint.zero
        func num() -> CGFloat { defer { i += 1 }; return CGFloat(Double(tokens[i]) ?? 0) }
        while i < tokens.count {
            if let c = tokens[i].first, c.isLetter { cmd = tokens[i]; i += 1 }
            switch cmd {
            case "M":
                pt = CGPoint(x: num(), y: num()); p.move(to: pt); cmd = "L"
            case "L":
                pt = CGPoint(x: num(), y: num()); p.addLine(to: pt)
            case "C":
                let c1 = CGPoint(x: num(), y: num()), c2 = CGPoint(x: num(), y: num())
                pt = CGPoint(x: num(), y: num()); p.addCurve(to: pt, control1: c1, control2: c2)
            case "Q":
                let c1 = CGPoint(x: num(), y: num())
                pt = CGPoint(x: num(), y: num()); p.addQuadCurve(to: pt, control: c1)
            case "A":
                let r = num(); _ = num(); _ = num()
                let large = num() != 0, sweep = num() != 0
                let end = CGPoint(x: num(), y: num())
                arc(&p, from: pt, to: end, r: r, large: large, sweep: sweep)
                pt = end
            case "Z":
                p.closeSubpath()
            default:
                i += 1
            }
        }
        return p
    }

    /// A circular arc from SVG's endpoint form to a centre and two angles.
    private static func arc(_ p: inout Path, from a: CGPoint, to b: CGPoint, r rIn: CGFloat, large: Bool, sweep: Bool) {
        let x1 = (a.x - b.x) / 2, y1 = (a.y - b.y) / 2
        let d2 = x1 * x1 + y1 * y1
        let r = max(rIn, sqrt(d2))
        let sign: CGFloat = large == sweep ? -1 : 1
        let coef = sign * sqrt(max(0, (r * r - d2) / d2))
        let cx1 = coef * y1, cy1 = -coef * x1
        let center = CGPoint(x: cx1 + (a.x + b.x) / 2, y: cy1 + (a.y + b.y) / 2)
        let start = atan2((y1 - cy1) / r, (x1 - cx1) / r)
        let end = atan2((-y1 - cy1) / r, (-x1 - cx1) / r)
        // SVG's sweep 1 is increasing angle, which in SwiftUI's flipped space is not `clockwise`.
        p.addArc(center: center, radius: r, startAngle: .radians(Double(start)), endAngle: .radians(Double(end)), clockwise: !sweep)
    }
}
