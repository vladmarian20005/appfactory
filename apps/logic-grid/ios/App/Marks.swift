import SwiftUI

/// The almond a burin actually cuts: points at either end, slightly convex sides. It is the
/// fixed-pairing mark on the plate, the bullet on the paywall, the peg on the drying line and
/// the selection mark everywhere. There is no checkmark anywhere in this app.
struct Lozenge: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let midY = rect.midY
        path.move(to: CGPoint(x: rect.minX, y: midY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: midY),
                          control: CGPoint(x: rect.midX, y: rect.minY - rect.height * 0.18))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: midY),
                          control: CGPoint(x: rect.midX, y: rect.maxY + rect.height * 0.18))
        path.closeSubpath()
        return path
    }
}

/// A rule of three lozenges, the section divider.
struct LozengeRule: View {
    var count: Int = 3
    var color: Color
    var width: CGFloat = 13

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { _ in
                Lozenge().fill(color).frame(width: width, height: width * 0.6)
            }
        }
        .accessibilityHidden(true)
    }
}

/// The thirty-two engraved figures a member of a category is labelled with — a bell, a ferry,
/// a lamp, a key, a fish — drawn as one stroke weight in a 64-unit box. They are what kills
/// the category's rotated eight-point column heading, and they are reused across every theme,
/// so the cast costs the same whether the app ships four subjects or forty.
enum Glyph: String, Codable, CaseIterable {
    case steamer, sloop, dinghy, wave, basket, coil, lamp, apple, bell, key
    case fish, moon, chest, barrel, rope, spoon, hand, gate, anchor, candle
    case jar, feather, leaf, hook, bridge, kiln, cask, scale
    case hourOne, hourTwo, hourThree, hourFour, hourFive, hourSix

    /// The clock faces are one drawing with the hand in six places, which is exactly how a
    /// shop would punch them.
    var clockHour: Int? {
        switch self {
        case .hourOne: return 0
        case .hourTwo: return 1
        case .hourThree: return 2
        case .hourFour: return 3
        case .hourFive: return 4
        case .hourSix: return 5
        default: return nil
        }
    }
}

/// One cast mark, cut into the copper. A `Shape`, so it strokes at whatever weight the plate
/// is drawn at and scales to any cell.
struct CastMark: Shape {
    let glyph: Glyph

    func path(in rect: CGRect) -> Path {
        let scale = min(rect.width, rect.height) / 64
        let dx = rect.minX + (rect.width - 64 * scale) / 2
        let dy = rect.minY + (rect.height - 64 * scale) / 2
        let path = unitPath()
        return path.applying(CGAffineTransform(scaleX: scale, y: scale)
            .concatenating(CGAffineTransform(translationX: dx, y: dy)))
    }

    // swiftlint:disable:next cyclomatic_complexity
    private func unitPath() -> Path {
        var p = Path()
        if let hour = glyph.clockHour {
            p.addEllipse(in: CGRect(x: 8, y: 8, width: 48, height: 48))
            let angle = Double(hour) / 6 * 2 * .pi - .pi / 2
            p.move(to: CGPoint(x: 32, y: 32))
            p.addLine(to: CGPoint(x: 32 + cos(angle) * 17, y: 32 + sin(angle) * 17))
            return p
        }
        switch glyph {
        case .steamer:
            p.move(to: CGPoint(x: 6, y: 40)); p.addLine(to: CGPoint(x: 58, y: 40))
            p.addLine(to: CGPoint(x: 50, y: 52)); p.addLine(to: CGPoint(x: 14, y: 52))
            p.closeSubpath()
            p.addRect(CGRect(x: 26, y: 20, width: 12, height: 20))
            p.move(to: CGPoint(x: 18, y: 14)); p.addLine(to: CGPoint(x: 46, y: 14))
        case .sloop:
            p.move(to: CGPoint(x: 8, y: 44)); p.addLine(to: CGPoint(x: 56, y: 44))
            p.addLine(to: CGPoint(x: 46, y: 56)); p.addLine(to: CGPoint(x: 16, y: 56))
            p.closeSubpath()
            p.move(to: CGPoint(x: 32, y: 6)); p.addLine(to: CGPoint(x: 32, y: 44))
            p.move(to: CGPoint(x: 32, y: 10)); p.addLine(to: CGPoint(x: 52, y: 40))
            p.addLine(to: CGPoint(x: 32, y: 40))
        case .dinghy:
            p.move(to: CGPoint(x: 8, y: 42)); p.addLine(to: CGPoint(x: 50, y: 42))
            p.addLine(to: CGPoint(x: 40, y: 56)); p.addLine(to: CGPoint(x: 18, y: 56))
            p.closeSubpath()
            p.move(to: CGPoint(x: 44, y: 8)); p.addLine(to: CGPoint(x: 18, y: 42))
        case .wave:
            p.move(to: CGPoint(x: 6, y: 26))
            p.addLine(to: CGPoint(x: 32, y: 42)); p.addLine(to: CGPoint(x: 58, y: 26))
            p.move(to: CGPoint(x: 6, y: 38))
            p.addLine(to: CGPoint(x: 32, y: 54)); p.addLine(to: CGPoint(x: 58, y: 38))
        case .basket:
            p.move(to: CGPoint(x: 12, y: 26)); p.addLine(to: CGPoint(x: 52, y: 26))
            p.addLine(to: CGPoint(x: 46, y: 56)); p.addLine(to: CGPoint(x: 18, y: 56))
            p.closeSubpath()
            p.move(to: CGPoint(x: 22, y: 26))
            p.addQuadCurve(to: CGPoint(x: 42, y: 26), control: CGPoint(x: 32, y: 6))
        case .coil:
            p.addEllipse(in: CGRect(x: 10, y: 10, width: 44, height: 44))
            p.addEllipse(in: CGRect(x: 22, y: 22, width: 20, height: 20))
            p.addEllipse(in: CGRect(x: 29, y: 29, width: 6, height: 6))
        case .lamp:
            p.move(to: CGPoint(x: 32, y: 10)); p.addLine(to: CGPoint(x: 52, y: 46))
            p.addLine(to: CGPoint(x: 12, y: 46)); p.closeSubpath()
            p.move(to: CGPoint(x: 18, y: 54)); p.addLine(to: CGPoint(x: 46, y: 54))
        case .apple:
            p.addEllipse(in: CGRect(x: 14, y: 20, width: 36, height: 38))
            p.move(to: CGPoint(x: 32, y: 20)); p.addLine(to: CGPoint(x: 32, y: 8))
            p.move(to: CGPoint(x: 32, y: 12))
            p.addQuadCurve(to: CGPoint(x: 48, y: 8), control: CGPoint(x: 42, y: 16))
        case .bell:
            p.move(to: CGPoint(x: 14, y: 48))
            p.addCurve(to: CGPoint(x: 50, y: 48),
                       control1: CGPoint(x: 18, y: 14), control2: CGPoint(x: 46, y: 14))
            p.closeSubpath()
            p.move(to: CGPoint(x: 32, y: 10)); p.addLine(to: CGPoint(x: 32, y: 16))
            p.addEllipse(in: CGRect(x: 28, y: 50, width: 8, height: 8))
        case .key:
            p.addEllipse(in: CGRect(x: 8, y: 12, width: 22, height: 22))
            p.move(to: CGPoint(x: 28, y: 30)); p.addLine(to: CGPoint(x: 56, y: 54))
            p.move(to: CGPoint(x: 44, y: 34)); p.addLine(to: CGPoint(x: 36, y: 44))
            p.move(to: CGPoint(x: 52, y: 40)); p.addLine(to: CGPoint(x: 44, y: 50))
        case .fish:
            p.move(to: CGPoint(x: 8, y: 32))
            p.addQuadCurve(to: CGPoint(x: 46, y: 32), control: CGPoint(x: 27, y: 10))
            p.addQuadCurve(to: CGPoint(x: 8, y: 32), control: CGPoint(x: 27, y: 54))
            p.move(to: CGPoint(x: 46, y: 32)); p.addLine(to: CGPoint(x: 58, y: 18))
            p.addLine(to: CGPoint(x: 58, y: 46)); p.closeSubpath()
        case .moon:
            p.move(to: CGPoint(x: 42, y: 8))
            p.addCurve(to: CGPoint(x: 42, y: 56),
                       control1: CGPoint(x: 12, y: 16), control2: CGPoint(x: 12, y: 48))
            p.addCurve(to: CGPoint(x: 42, y: 8),
                       control1: CGPoint(x: 26, y: 46), control2: CGPoint(x: 26, y: 18))
        case .chest:
            p.addRect(CGRect(x: 10, y: 26, width: 44, height: 28))
            p.move(to: CGPoint(x: 24, y: 26))
            p.addQuadCurve(to: CGPoint(x: 40, y: 26), control: CGPoint(x: 32, y: 10))
        case .barrel:
            p.move(to: CGPoint(x: 18, y: 10))
            p.addQuadCurve(to: CGPoint(x: 18, y: 54), control: CGPoint(x: 8, y: 32))
            p.addLine(to: CGPoint(x: 46, y: 54))
            p.addQuadCurve(to: CGPoint(x: 46, y: 10), control: CGPoint(x: 56, y: 32))
            p.closeSubpath()
            p.move(to: CGPoint(x: 11, y: 24)); p.addLine(to: CGPoint(x: 53, y: 24))
            p.move(to: CGPoint(x: 11, y: 40)); p.addLine(to: CGPoint(x: 53, y: 40))
        case .rope:
            p.move(to: CGPoint(x: 8, y: 22))
            p.addCurve(to: CGPoint(x: 56, y: 22),
                       control1: CGPoint(x: 24, y: 2), control2: CGPoint(x: 40, y: 42))
            p.move(to: CGPoint(x: 8, y: 42))
            p.addCurve(to: CGPoint(x: 56, y: 42),
                       control1: CGPoint(x: 24, y: 22), control2: CGPoint(x: 40, y: 62))
        case .spoon:
            p.addEllipse(in: CGRect(x: 20, y: 6, width: 24, height: 30))
            p.move(to: CGPoint(x: 32, y: 36)); p.addLine(to: CGPoint(x: 32, y: 58))
        case .hand:
            p.move(to: CGPoint(x: 18, y: 56)); p.addLine(to: CGPoint(x: 18, y: 28))
            p.addQuadCurve(to: CGPoint(x: 28, y: 20), control: CGPoint(x: 22, y: 18))
            p.addLine(to: CGPoint(x: 28, y: 34))
            p.move(to: CGPoint(x: 28, y: 26)); p.addLine(to: CGPoint(x: 38, y: 24))
            p.move(to: CGPoint(x: 28, y: 32)); p.addLine(to: CGPoint(x: 44, y: 30))
            p.move(to: CGPoint(x: 18, y: 56)); p.addLine(to: CGPoint(x: 46, y: 56))
            p.addLine(to: CGPoint(x: 46, y: 30))
        case .gate:
            p.addRect(CGRect(x: 10, y: 14, width: 44, height: 38))
            p.move(to: CGPoint(x: 10, y: 14)); p.addLine(to: CGPoint(x: 54, y: 52))
            p.move(to: CGPoint(x: 54, y: 14)); p.addLine(to: CGPoint(x: 10, y: 52))
        case .anchor:
            p.move(to: CGPoint(x: 32, y: 16)); p.addLine(to: CGPoint(x: 32, y: 56))
            p.move(to: CGPoint(x: 18, y: 26)); p.addLine(to: CGPoint(x: 46, y: 26))
            p.addEllipse(in: CGRect(x: 26, y: 6, width: 12, height: 12))
            p.move(to: CGPoint(x: 12, y: 40))
            p.addQuadCurve(to: CGPoint(x: 52, y: 40), control: CGPoint(x: 32, y: 62))
        case .candle:
            p.addRect(CGRect(x: 24, y: 24, width: 16, height: 32))
            p.move(to: CGPoint(x: 32, y: 24))
            p.addQuadCurve(to: CGPoint(x: 32, y: 8), control: CGPoint(x: 42, y: 16))
            p.addQuadCurve(to: CGPoint(x: 32, y: 24), control: CGPoint(x: 22, y: 16))
        case .jar:
            p.addRect(CGRect(x: 16, y: 22, width: 32, height: 34))
            p.move(to: CGPoint(x: 22, y: 22)); p.addLine(to: CGPoint(x: 22, y: 12))
            p.addLine(to: CGPoint(x: 42, y: 12)); p.addLine(to: CGPoint(x: 42, y: 22))
        case .feather:
            p.move(to: CGPoint(x: 14, y: 56))
            p.addCurve(to: CGPoint(x: 52, y: 10),
                       control1: CGPoint(x: 20, y: 34), control2: CGPoint(x: 34, y: 14))
            p.move(to: CGPoint(x: 24, y: 42)); p.addLine(to: CGPoint(x: 42, y: 32))
            p.move(to: CGPoint(x: 30, y: 32)); p.addLine(to: CGPoint(x: 46, y: 22))
        case .leaf:
            p.move(to: CGPoint(x: 12, y: 52))
            p.addQuadCurve(to: CGPoint(x: 52, y: 12), control: CGPoint(x: 16, y: 16))
            p.addQuadCurve(to: CGPoint(x: 12, y: 52), control: CGPoint(x: 48, y: 48))
            p.move(to: CGPoint(x: 12, y: 52)); p.addLine(to: CGPoint(x: 44, y: 20))
        case .hook:
            p.move(to: CGPoint(x: 32, y: 8)); p.addLine(to: CGPoint(x: 32, y: 34))
            p.addCurve(to: CGPoint(x: 20, y: 44),
                       control1: CGPoint(x: 32, y: 44), control2: CGPoint(x: 26, y: 48))
            p.addCurve(to: CGPoint(x: 44, y: 44),
                       control1: CGPoint(x: 12, y: 38), control2: CGPoint(x: 44, y: 28))
        case .bridge:
            p.move(to: CGPoint(x: 6, y: 46))
            p.addQuadCurve(to: CGPoint(x: 58, y: 46), control: CGPoint(x: 32, y: 10))
            p.move(to: CGPoint(x: 6, y: 56)); p.addLine(to: CGPoint(x: 58, y: 56))
            p.move(to: CGPoint(x: 20, y: 40)); p.addLine(to: CGPoint(x: 20, y: 56))
            p.move(to: CGPoint(x: 44, y: 40)); p.addLine(to: CGPoint(x: 44, y: 56))
        case .kiln:
            p.move(to: CGPoint(x: 12, y: 56)); p.addLine(to: CGPoint(x: 12, y: 30))
            p.addQuadCurve(to: CGPoint(x: 52, y: 30), control: CGPoint(x: 32, y: 6))
            p.addLine(to: CGPoint(x: 52, y: 56)); p.closeSubpath()
            p.addRect(CGRect(x: 26, y: 40, width: 12, height: 16))
        case .cask:
            p.addEllipse(in: CGRect(x: 14, y: 14, width: 36, height: 36))
            p.move(to: CGPoint(x: 32, y: 14)); p.addLine(to: CGPoint(x: 32, y: 50))
            p.move(to: CGPoint(x: 14, y: 32)); p.addLine(to: CGPoint(x: 50, y: 32))
        case .scale:
            p.move(to: CGPoint(x: 32, y: 8)); p.addLine(to: CGPoint(x: 32, y: 52))
            p.move(to: CGPoint(x: 10, y: 20)); p.addLine(to: CGPoint(x: 54, y: 20))
            p.move(to: CGPoint(x: 10, y: 20)); p.addLine(to: CGPoint(x: 18, y: 34))
            p.addLine(to: CGPoint(x: 2, y: 34)); p.closeSubpath()
            p.move(to: CGPoint(x: 54, y: 20)); p.addLine(to: CGPoint(x: 62, y: 34))
            p.addLine(to: CGPoint(x: 46, y: 34)); p.closeSubpath()
            p.move(to: CGPoint(x: 18, y: 56)); p.addLine(to: CGPoint(x: 46, y: 56))
        default:
            p.addEllipse(in: CGRect(x: 14, y: 14, width: 36, height: 36))
        }
        return p
    }
}

/// A cast mark as it appears cut into copper: the trough with the light catching its upper lip.
struct EngravedMark: View {
    let glyph: Glyph
    var size: CGFloat = 22
    var color: Color
    var lip: Color?
    var weight: CGFloat = 2.2

    var body: some View {
        ZStack {
            if let lip {
                CastMark(glyph: glyph)
                    .stroke(lip, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))
                    .offset(x: -0.6, y: -0.7)
            }
            CastMark(glyph: glyph)
                .stroke(color, style: StrokeStyle(lineWidth: weight, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
