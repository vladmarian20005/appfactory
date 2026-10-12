import FactoryKit
import SwiftUI

/// How every card on this phone is drawn: the back, gilt edges once earned, four colours and
/// large pips when asked for. Set once at the root from the record.
struct CardStyle: Equatable {
    var back: Back = .lattice
    var gilt = false
    var fourColour = false
    var largePips = false
}

private struct CardStyleKey: EnvironmentKey { static let defaultValue = CardStyle() }

extension EnvironmentValues {
    var cardStyle: CardStyle {
        get { self[CardStyleKey.self] }
        set { self[CardStyleKey.self] = newValue }
    }
}

/// One card, at any size, drawn the way `design/cards.js` draws it: cream stock, 5 : 7, a
/// corner of 8 % of the width, the index in New York top-left and upside down bottom-right,
/// one centre pip, and a brass emblem over a court's letter.
struct CardFace: View {
    let card: Card
    var faceUp = true
    let width: CGFloat
    /// The brass hairline a card shows for a moment as it lands on a foundation.
    var flash = false

    @Environment(\.cardStyle) private var style

    private var h: CGFloat { width * 1.4 }
    private var corner: CGFloat { width * 0.08 }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        ZStack {
            shape.fill(AppBrand.CardBox.stock)
            if faceUp { face } else { CardBack(kind: style.back, width: width) }
            shape.strokeBorder(style.gilt || flash ? AppBrand.brand.palette.accent : AppBrand.CardBox.ink.opacity(0.12),
                               lineWidth: style.gilt || flash ? max(1, width * 0.022) : 0.5)
        }
        .frame(width: width, height: h)
        .compositingGroup()
        // A card is a drawing sized to the table; its index is sized to the card, so it is
        // read at the card's own scale. Large pips are the legibility setting.
        .environment(\.dynamicTypeSize, .large)
    }

    private var ink: Color {
        if style.fourColour {
            switch card.suit {
            case .spade: return AppBrand.CardBox.ink
            case .heart: return AppBrand.CardBox.red
            case .club: return AppBrand.CardBox.green
            case .diamond: return AppBrand.CardBox.blue
            }
        }
        return card.isRed ? AppBrand.CardBox.red : AppBrand.CardBox.ink
    }

    @ViewBuilder
    private var face: some View {
        let fs = width * 0.26
        ZStack {
            index(fs)
                .position(x: width * 0.1 + fs * 0.42, y: width * 0.11 + fs * 0.62)
            index(fs)
                .rotationEffect(.degrees(180))
                .position(x: width - (width * 0.1 + fs * 0.42), y: h - (width * 0.11 + fs * 0.62))
            centre
        }
        .frame(width: width, height: h)
    }

    private func index(_ fs: CGFloat) -> some View {
        VStack(spacing: fs * 0.04) {
            Text(card.index)
                .scaledFont(size: fs, weight: .semibold, design: .serif)
                .tracking(card.rank == 10 ? -fs * 0.08 : 0)
                .foregroundStyle(ink)
                .fixedSize()
            PipShape(suit: card.suit).fill(ink).frame(width: fs * 0.6, height: fs * 0.6)
        }
        .frame(width: fs * 1.1)
    }

    @ViewBuilder
    private var centre: some View {
        switch card.rank {
        case 1:
            PipShape(suit: card.suit).fill(ink).frame(width: width * 0.62, height: width * 0.62)
        case 11...13:
            let ls = width * 0.48
            VStack(spacing: 0) {
                EmblemShape(rank: card.rank)
                    .fill(AppBrand.CardBox.brassDeep)
                    .frame(width: width * 0.26, height: width * 0.156)
                Text(card.index)
                    .scaledFont(size: ls, weight: .semibold, design: .serif)
                    .foregroundStyle(ink)
                    .fixedSize()
                    .frame(height: ls * 0.92)
                PipShape(suit: card.suit).fill(ink).frame(width: width * 0.16, height: width * 0.16)
            }
        default:
            let s = width * (style.largePips ? 0.7 : 0.55)
            PipShape(suit: card.suit).fill(ink).frame(width: s, height: s)
        }
    }
}

/// A card turning: the back, swap at 90°, the face. Animate `faceUp` and it turns.
struct TurningCard: View, Animatable {
    let card: Card
    var angle: Double            // 0 face up, 180 face down
    let width: CGFloat
    var flash = false

    init(card: Card, faceUp: Bool, width: CGFloat, flash: Bool = false) {
        self.card = card
        self.angle = faceUp ? 0 : 180
        self.width = width
        self.flash = flash
    }

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    var body: some View {
        CardFace(card: card, faceUp: angle < 90, width: width, flash: flash)
            .rotation3DEffect(.degrees(angle < 90 ? angle : angle - 180), axis: (0, 1, 0), perspective: 0.4)
    }
}

/// An empty place on the cloth: a card-shaped outline, and on a foundation its suit ghosted.
struct CardSlot: View {
    var suit: Suit?
    let width: CGFloat
    var body: some View {
        let shape = RoundedRectangle(cornerRadius: width * 0.08, style: .continuous)
        ZStack {
            shape.fill(AppBrand.CardBox.stock.opacity(0.06))
            shape.strokeBorder(AppBrand.CardBox.stock.opacity(0.14), lineWidth: 1)
            if let suit {
                PipShape(suit: suit).fill(AppBrand.CardBox.stock.opacity(0.18))
                    .frame(width: width * 0.36, height: width * 0.36)
            }
        }
        .frame(width: width, height: width * 1.4)
    }
}
