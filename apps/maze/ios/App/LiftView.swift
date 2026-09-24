import FactoryKit
import SwiftUI

/// The reward. The last pin goes in and the pins come out, and the lace lifts off the pillow
/// while he watches — drawn from `lift.phase`, so a still capture of the final phase is the
/// whole composition and the filmstrip of `-demo lift` is the motion.
struct LiftView: View {
    let lift: Bench.Lift
    @EnvironmentObject private var bench: Bench
    @Environment(\.brand) private var brand
    @State private var wave: CGFloat = Motion.isStill ? 1 : 0

    private var piece: Piece { lift.piece }
    private var tier: Run.Tier { lift.tier }

    /// How far the lace rises: 28 for a best, 14 for a clean, 10 otherwise.
    private var rise: CGFloat {
        switch tier {
        case .best: 28
        case .clean: 14
        default: 10
        }
    }

    private var snips: (count: Int, power: CGFloat)? {
        switch tier {
        case .best: (70, 1.2)
        case .clean: (52, 0.8)
        case .good: (34, 0.5)
        case .finished: piece.restarted ? nil : (26, 0.4)
        }
    }

    var body: some View {
        GeometryReader { geo in
            let cardSize = max(200, min(geo.size.width - 48, geo.size.height * 0.4))
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text("\(Words.size(piece.side)) · \(piece.ground.name) ground").caps()
                        Spacer()
                        Text(piece.isToday ? Date.now.formatted(.dateTime.day().month(.wide)) : piece.mark).caps()
                    }
                    PillowBolster(dim: lift.phase >= 3 ? 0.08 : 0) {
                        card(size: cardSize)
                    }
                    .confetti(trigger: lift.phase >= 5 ? piece.id : 0,
                              colors: [AppBrand.Workbox.steel, piece.thread.color, AppBrand.Workbox.brass],
                              from: UnitPoint(x: 0.5, y: 0.45),
                              count: snips?.count ?? 0,
                              power: snips?.power ?? 0,
                              onAppear: Motion.isStill && snips != nil)
                    words
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .onChange(of: lift.phase) { _, phase in
            if phase == 1 {
                withAnimation(Motion.resolved(.linear(duration: 0.6))) { wave = 1 }
            }
        }
        .onAppear { if lift.phase >= 1 { wave = 1 } }
    }

    // MARK: - The card, the pins coming out, the lace lifting

    private func card(size: CGFloat) -> some View {
        let layout = CardLayout(side: piece.side, size: size)
        let path = piece.path.map(Int.init)
        let lifted = lift.phase >= 3
        let pinsOut = lift.phase >= 2
        return PrickingCard(size: size) {
            ZStack {
                // The pricks, the gimp, and the windows stay on the card.
                Canvas { gc, _ in
                    let pr = lift.pricking
                    for c in 0..<(pr.side * pr.side) {
                        let p = layout.centre(c)
                        if !pr.open[c] {
                            let h = layout.pitch / 2 + 0.5
                            gc.fill(Path(CGRect(x: p.x - h, y: p.y - h, width: 2 * h, height: 2 * h)),
                                    with: .color(AppBrand.Pillow.cloth))
                        } else {
                            gc.drawPrick(at: p, size: 1.8, ink: brand.palette.ink)
                        }
                    }
                    gc.drawGimp(pr.gimp, layout: layout, color: AppBrand.Pillow.gimp.opacity(0.7))
                }
                // The ghost numeral: pins taken, a watermark in the parchment under the lace.
                if lift.phase >= 4 {
                    CountUp(to: piece.pins, duration: 0.6) { n in
                        Haptics.impact(0.25 + 0.03 * CGFloat(n % 20))
                    }
                    .brandDisplay(size: 112)
                    .foregroundStyle(brand.palette.accent.opacity(0.14))
                    .transition(.opacity)
                    .accessibilityHidden(true)
                }
                // The pins, rising out of the pillow and gone.
                Canvas { gc, _ in
                    for c in path {
                        gc.drawPin(at: layout.centre(c), head: 5, color: AppBrand.Workbox.steel, sunk: true)
                    }
                }
                .scaleEffect(pinsOut ? 1.3 : 1)
                .opacity(pinsOut ? 0 : 1)
                .animation(Motion.resolved(.easeOut(duration: 0.6)), value: pinsOut)
                // The lace.
                lace(layout: layout, path: path)
                    .scaleEffect(lifted ? 1.06 : 1)
                    .offset(y: lifted ? -rise : 0)
                    .shadow(color: .black.opacity(lifted ? 0.22 : 0), radius: lifted ? 18 : 0, x: 0, y: lifted ? rise * 0.6 : 0)
                    .animation(Motion.resolved(Motion.bouncy), value: lifted)
            }
            .frame(width: size, height: size)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The finished piece: \(Words.size(piece.side)), the \(piece.ground.name) ground, \(piece.pins) pins in one thread.")
    }

    private func lace(layout: CardLayout, path: [Int]) -> some View {
        let picot = (tier == .best || piece.picot) && lift.phase >= 4
        return ZStack {
            Canvas { gc, _ in
                gc.drawThread(path, plaits: piece.plaits, layout: layout,
                              style: ThreadStyle(color: piece.thread.color, twist: piece.thread.twist,
                                                 twistAll: lift.phase >= 1))
                if picot {
                    gc.drawPicot(layout: layout, color: AppBrand.Workbox.gold)
                }
            }
            // The thread tightens: a wave runs from the start pin to the last, a shade brighter
            // and 0.4 pt heavier.
            Path { p in
                guard let first = path.first else { return }
                p.move(to: layout.centre(first))
                for c in path.dropFirst() { p.addLine(to: layout.centre(c)) }
            }
            .trim(from: max(0, wave - 0.12), to: wave)
            .stroke(piece.thread.color.opacity(wave >= 1 ? 0 : 1),
                    style: StrokeStyle(lineWidth: layout.threadWidth + 0.4, lineCap: .round, lineJoin: .round))
            .brightness(0.06)
        }
    }

    // MARK: - The words

    private var words: some View {
        VStack(alignment: .leading, spacing: 14) {
            if lift.phase >= 6 {
                VStack(alignment: .leading, spacing: 8) {
                    Text(lift.headline)
                        .brandDisplay(size: 30, relativeTo: .title)
                        .foregroundStyle(brand.palette.highlight)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(lift.praise)
                        .font(.body.italic())
                        .foregroundStyle(brand.palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .transition(.opacity.combined(with: .offset(y: 8)))
            }
            if lift.phase >= 7 {
                marginCard
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .padding(.top, rise * 0.4)
        .animation(Motion.resolved(Motion.gentle), value: lift.phase)
    }

    /// The margin card: what was done, what is waiting, and the two ways on.
    private var marginCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(lift.ending.0)
                .font(.body)
                .foregroundStyle(brand.palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(lift.ending.1)
                .font(.body)
                .foregroundStyle(brand.palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { nextButton; SwatchShareLink(piece: piece, record: bench.record) }
                VStack(spacing: 10) { nextButton; SwatchShareLink(piece: piece, record: bench.record) }
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .brandSurface(padding: 18)
    }

    private var nextButton: some View {
        Button {
            Haptics.tap()
            bench.pinNext()
        } label: {
            Text(bench.bookOpen ? "Pin the next pattern" : "See the whole book")
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)
        }
        .brandProminent()
    }
}
