import FactoryKit
import SwiftUI

/// The first card: three small practice patterns the lacemaker pins before the book's first.
/// Each teaches one thing. A ghost hand shows the gesture and her line names the rule, and
/// both go the moment the teaching has worked. Nothing on it is kept in the sampler.
enum FirstCard {
    struct Note: Equatable, Hashable {
        var title: String
        var detail: String
    }

    /// What the ghost hand does: comes down on the first cell and leads the thread through
    /// the rest, or — backward — runs along the wound thread from its end to where it went
    /// wrong.
    struct Hand: Equatable {
        var cells: [Int]
        var backward = false
    }

    struct Card {
        let pricking: Pricking
        /// Thread already on the card when it is pinned: somebody else's wrong turn.
        let wound: [Int]
        let intro: Note
        let hand: Hand?
        /// Replaces the intro at the first pin taken, or at the first unpick on a card that
        /// arrives wound.
        let underway: Note?
        let done: Note
    }

    static let cards: [Card] = [
        // Three by three, walled into one lane: the gesture and the goal, nothing to decide.
        Card(pricking: pricking(side: 3, answer: [0, 1, 2, 5, 4, 3, 6, 7, 8],
                                walls: [(0, 3), (1, 4), (4, 7), (5, 8)], seed: 0x1E55_0001),
             wound: [],
             intro: Note(title: "Begin at the brass pin.",
                         detail: "Keep a finger down and lead the thread from pin to pin."),
             hand: Hand(cells: [0, 1, 2, 5]),
             underway: Note(title: "Every pin, once.",
                            detail: "The dark stitches are gimp; the thread goes round them. It ends on the ringed pin."),
             done: Note(title: "That is lace.",
                        detail: "One thread through every pin. The next card leaves more to you.")),
        // Four by four with five walls: the gimp leads, but the first pin already forks.
        Card(pricking: pricking(side: 4, answer: [0, 1, 2, 3, 7, 11, 15, 14, 13, 12, 8, 4, 5, 6, 10, 9],
                                walls: [(1, 5), (2, 6), (6, 7), (9, 13), (10, 14)], seed: 0x1E55_0002),
             wound: [],
             intro: Note(title: "Now there is a choice.",
                         detail: "Read the gimp before the thread goes in. Every pin, once, and home to the ring."),
             hand: nil,
             underway: nil,
             done: Note(title: "Round the gimp and home.",
                        detail: "One more. Somebody made a start on this one, and it went wrong.")),
        // Four by four, one wall, wound into the corner at the bottom left.
        Card(pricking: pricking(side: 4, answer: [0, 4, 8, 12, 13, 9, 5, 1, 2, 3, 7, 6, 10, 14, 15, 11],
                                walls: [(4, 5)], seed: 0x1E55_0003),
             wound: [0, 4, 8, 9, 13, 12],
             intro: Note(title: "Wound into a corner.",
                         detail: "Nowhere to go from the last pin. Take the thread back along itself to where it turned."),
             hand: Hand(cells: [12, 13, 9, 8], backward: true),
             underway: Note(title: "Picked out, and nothing lost.",
                            detail: "Corners first: the thread needs one way in and one way out."),
             done: Note(title: "That is the whole of it.",
                        detail: "Every pattern is one thread through every pin, and each has exactly one way through. The book's first is pinned.")),
    ]

    /// Said at a dead end on any practice card, while the ghost hand shows the way back.
    static let deadEnd = Note(title: "Nowhere to go from there.",
                              detail: "Take the thread back along itself, to the last pin that had a choice.")

    static let pickedOut = Note(title: "Picked out. The thread does not mind.",
                                detail: "Try the other way from there.")

    /// A practice pattern: every pin on the card, both ends pinned, the answer's ends as the
    /// brass pin and the ring.
    private static func pricking(side: Int, answer: [Int], walls: [(Int, Int)], seed: UInt64) -> Pricking {
        Pricking(side: side,
                 open: Array(repeating: true, count: side * side),
                 gimp: Set(walls.map { Edge($0.0, $0.1) }),
                 start: UInt8(answer[0]),
                 finish: UInt8(answer[answer.count - 1]),
                 ground: .tulle, shape: 1, rung: 0, seed: seed,
                 answer: answer.map(UInt8.init))
    }
}

/// A fingertip's ghost over the card. It comes down, leads through the hand's pins with a
/// faint thread behind it, lifts, rests and does it again. Backward, the stretch of thread it
/// passes is marked as the stretch that comes off. Still under `-stillFrames` and Reduce
/// Motion, part way along.
struct GhostHand: View {
    let points: [CGPoint]
    var backward = false
    let trail: Color
    let ink: Color
    let width: CGFloat
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private static let down = 0.45, per = 0.42, hold = 0.45, fade = 0.35, rest = 0.7

    var body: some View {
        let still = Motion.isStill || reduceMotion
        let steps = Double(max(points.count - 1, 1))
        let travel = Self.per * steps
        let period = Self.down + travel + Self.hold + Self.fade + Self.rest
        TimelineView(.animation(minimumInterval: 1.0 / 30, paused: still)) { ctx in
            let t = still ? Self.down + travel * 0.6
                          : ctx.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period)
            let p = min(max((t - Self.down) / travel, 0), 1)
            let u = steps * (p < 0.5 ? 2 * p * p : 1 - pow(-2 * p + 2, 2) / 2)
            let lifted = t - Self.down - travel - Self.hold
            let alpha = t < 0.2 ? t / 0.2 : (lifted > 0 ? max(0, 1 - lifted / Self.fade) : 1)
            let press = min(1, t / Self.down)
            ZStack {
                trailPath(to: u)
                    .stroke(trail.opacity(backward ? 0.55 : 0.3),
                            style: StrokeStyle(lineWidth: backward ? width + 3 : width, lineCap: .round))
                Circle()
                    .fill(ink.opacity(0.1))
                    .overlay(Circle().strokeBorder(ink.opacity(0.38), lineWidth: 1.5))
                    .frame(width: 38, height: 38)
                    .scaleEffect(1.3 - 0.3 * press)
                    .position(point(at: u))
            }
            .opacity(alpha)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func trailPath(to u: Double) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: first)
            let whole = min(Int(u), points.count - 1)
            if whole >= 1 { for i in 1...whole { path.addLine(to: points[i]) } }
            path.addLine(to: point(at: u))
        }
    }

    private func point(at u: Double) -> CGPoint {
        guard !points.isEmpty else { return .zero }
        let i = min(Int(u), points.count - 1)
        guard i < points.count - 1 else { return points[points.count - 1] }
        let f = CGFloat(u - Double(i))
        let a = points[i], b = points[i + 1]
        return CGPoint(x: a.x + (b.x - a.x) * f, y: a.y + (b.y - a.y) * f)
    }
}
