import FactoryKit
import SwiftUI

/// What happens when the last vial comes good: the tide goes out and the rack stands lit.
///
/// Full screen on the shore, never a half-height sheet with a seal on it. Choreographed over
/// about a second and a half — the number counts, the line draws, the rack rises and lights
/// one glass at a time, and how loud it gets depends on how it went.
struct LevelClearedView: View {
    let result: GameModel.FinishedLevel
    let board: Board
    let style: BoardStyle
    let streak: Int
    let onNext: () -> Void
    let onReplay: () -> Void

    @Environment(\.brand) private var brand

    @State private var verdict = ""
    @State private var burst = 0
    @State private var rackShown = Motion.isStill
    @State private var card: Image?

    private var tier: WinTier { WinTier(moves: result.moves, par: result.par) }

    /// The vials that ended up holding something — the rack as it stands at the end.
    private var rack: [[Int]] { board.tubes.filter { !$0.isEmpty } }

    var body: some View {
        ZStack {
            BrandBackground(drift: true)
            // Over par gets no confetti at all: a warm swell behind the rack instead, so that
            // a clean sweep is always the louder thing.
            if !tier.fires {
                Ellipse()
                    .fill(RadialGradient(colors: [brand.palette.highlight.opacity(0.26),
                                                  brand.palette.highlight.opacity(0)],
                                         center: .center, startRadius: 0, endRadius: 260))
                    .frame(height: 420)
                    .offset(y: 140)
                    .breathing(amount: 0.05, period: 4)
                    .allowsHitTesting(false)
            }
            ScrollView {
                VStack(spacing: 22) {
                    horizon
                    score
                    Text(verdict)
                        .brandFont(.title)
                        .foregroundStyle(brand.palette.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 8)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(brand.palette.inkSoft)
                        .multilineTextAlignment(.center)
                    rail
                    finishedRack
                    actions
                }
                .padding(.horizontal, FactoryTheme.padding)
                .padding(.bottom, 32)
                .frame(maxWidth: .infinity)
            }
        }
        .confetti(trigger: burst,
                  colors: rackColors,
                  from: UnitPoint(x: 0.5, y: 0.3),
                  power: tier.confettiPower,
                  onAppear: tier.fires)
        .task(id: result.id) { await arrive() }
    }

    // MARK: - Pieces

    /// The sun coming up over the flat, which is the one thing on this screen that is not
    /// about the score.
    private var horizon: some View {
        ZStack {
            Circle()
                .fill(RadialGradient(colors: [brand.palette.highlight,
                                              brand.palette.highlight.opacity(0.18)],
                                     center: .center, startRadius: 2, endRadius: 78))
                .frame(width: 92, height: 92)
                .breathing(amount: 0.05, period: 4.4)
            LinearGradient(colors: [brand.palette.highlight.opacity(0),
                                    brand.palette.highlight.opacity(0.55),
                                    brand.palette.highlight.opacity(0)],
                           startPoint: .leading, endPoint: .trailing)
                .frame(height: 1)
                .offset(y: 30)
        }
        .frame(height: 104)
        .padding(.top, 24)
        .accessibilityHidden(true)
    }

    /// The hero: the number of pours, counting up inside a thin lantern ring.
    private var score: some View {
        ZStack {
            Circle()
                .strokeBorder(brand.palette.highlight.opacity(0.45), lineWidth: 1)
                .frame(width: 210, height: 210)
            VStack(spacing: 2) {
                ChartMark(text: "Pours", color: brand.palette.highlight)
                CountUp(to: result.moves, duration: 0.7) { n in
                    Haptics.impact(0.3)
                    Tones.shared.play(.step(min(9, n)), volume: 0.35)
                }
                .brandDisplay(size: 96)
                .foregroundStyle(brand.palette.ink)
            }
        }
        .frame(height: 210)
        .dynamicTypeSize(...DynamicTypeSize.accessibility3)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(result.moves) pours. The charted line was \(result.par).")
    }

    private var subtitle: String {
        let where_ = result.levelID.isDaily ? "Today's pool" : "Level \(result.levelID.number ?? 0)"
        return "\(where_) · the charted line was \(result.par)"
    }

    private var rail: some View {
        VStack(spacing: 6) {
            PourRail(moves: result.moves, par: result.par)
                .frame(height: 3)
            HStack {
                ChartMark(text: "Start")
                Spacer()
                ChartMark(text: "The line", color: brand.palette.highlight)
            }
        }
        .padding(.horizontal, 6)
    }

    /// Every vial standing full and lit, one at a time.
    private var finishedRack: some View {
        HStack(alignment: .bottom, spacing: 10) {
            ForEach(Array(rack.enumerated()), id: \.offset) { index, contents in
                TubeView(contents: contents,
                         style: style,
                         width: 42,
                         unitHeight: 21,
                         isComplete: true)
                    .popIn(delay: 0.4 + Double(index) * 0.06)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
        .padding(.bottom, 18)
        .opacity(rackShown ? 1 : 0)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("The rack, \(rack.count) vials, every one a single colour.")
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button(result.levelID.isDaily ? "Back to the shore" : "Take the next one", action: onNext)
                .brandProminent()
            HStack(spacing: 12) {
                Button("Pour it again", action: onReplay)
                    .buttonStyle(.bordered)
                if let card {
                    ShareLink(item: card,
                              preview: SharePreview(shareTitle, image: card)) {
                        Label("Share the rack", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.bordered)
                }
            }
            .controlSize(.large)
            .tint(brand.palette.accent)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    private var shareTitle: String {
        "\(subtitle.components(separatedBy: " · ").first ?? "Tidepour") · \(result.moves) pours"
    }

    private var rackColors: [Color] {
        let colors = rack.compactMap { $0.first }.map { style.liquid($0).color }
        return colors.isEmpty ? [brand.palette.accent, brand.palette.highlight] : colors
    }

    // MARK: - The choreography

    private func arrive() async {
        verdict = Voice.verdict(moves: result.moves, par: result.par)
        card = rackCardImage(result: result, board: board, style: style, streak: streak)

        guard !Motion.isStill else {
            rackShown = true
            return
        }
        try? await Task.sleep(nanoseconds: 380_000_000)
        withMotion(Motion.gentle) { rackShown = true }
        try? await Task.sleep(nanoseconds: 120_000_000)
        switch tier {
        case .underPar, .atPar:
            burst += 1
            Haptics.celebrate()
            Tones.shared.play(.fanfare)
        case .overPar:
            Haptics.success()
            Tones.shared.play(.success)
        }
    }
}

/// What travels: the rack, the day, the pours against the line, the streak — as a picture,
/// because a line of text is not something anyone puts in a group chat.
struct RackCard: View {
    let result: GameModel.FinishedLevel
    let board: Board
    let style: BoardStyle
    let streak: Int

    @Environment(\.brand) private var brand

    private var rack: [[Int]] { board.tubes.filter { !$0.isEmpty } }

    var body: some View {
        ZStack {
            BrandBackground()
            VStack(spacing: 14) {
                Text("Tidepour")
                    .brandFont(.title3)
                    .foregroundStyle(brand.palette.accent)
                Text("\(result.moves)")
                    .brandDisplay(size: 84)
                    .foregroundStyle(brand.palette.ink)
                ChartMark(text: "Pours · the line was \(result.par)",
                          color: brand.palette.highlight)
                HStack(alignment: .bottom, spacing: 7) {
                    ForEach(Array(rack.prefix(7).enumerated()), id: \.offset) { _, contents in
                        TubeView(contents: contents, style: style,
                                 width: 30, unitHeight: 16, isComplete: true)
                    }
                }
                .padding(.top, 6)
                .padding(.bottom, 14)
                ChartMark(text: streak > 0 ? "\(result.dayKey) · \(streak)-day streak"
                                           : result.dayKey)
            }
            .padding(24)
        }
    }
}

/// Rendered outside the app's hierarchy, so it inherits nothing: the brand goes on here.
@MainActor
func rackCardImage(result: GameModel.FinishedLevel,
                   board: Board,
                   style: BoardStyle,
                   streak: Int) -> Image? {
    ShareImage.render {
        RackCard(result: result, board: board, style: style, streak: streak)
            .brand(AppBrand.brand)
    }
}
