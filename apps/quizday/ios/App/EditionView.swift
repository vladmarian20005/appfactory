import FactoryKit
import SwiftUI

/// Screen 3. Finishing the tenth question does not open a sheet with a checkmark — the screen
/// becomes the day's front page coming off the press, in the order a page prints: the rule
/// sweeps, the masthead sets, the dateline follows, the score counts up in ink, the tally
/// prints square by square, the tier headline stamps, the paper flies, and the run unrolls in
/// brass across the foot of the column.
struct EditionView: View {
    @Environment(\.brand) private var brand
    @EnvironmentObject private var desk: Desk

    let flags: [Bool]
    let editionNumber: Int
    let playedAt: Date
    let streak: Int
    let bestStreak: Int
    /// The longest chain she has managed in any edition before this one.
    var bestChain: Int = 0
    /// Editions filed, today's included. The rung the doors are read at.
    var filed: Int = 0

    @State private var pressRule: CGFloat = 0
    @State private var counting = false
    @State private var tallyPrinting = false
    @State private var headline = false
    @State private var personalBest = false
    @State private var ribbon: CGFloat = 0
    @State private var burst = 0
    @State private var shareImage: Image?

    private var score: Int { flags.filter { $0 }.count }
    private var total: Int { max(flags.count, 10) }
    private var run: Run { Run.replaying(flags) }
    private var tier: Tier { Tier.forEdition(run, total: total, beatingChain: bestChain) }
    /// A new longest run. The streak has its ribbon; this stamp is for the thing that was
    /// actually at risk inside the ten.
    private var isPersonalBest: Bool {
        run.longestChain > 1 && run.tier(score: run.longestChain, beating: bestChain) == .best
    }
    private var justOpened: [Earned.Milestone] {
        Desk.earned.justUnlocked(from: max(0, filed - 1), to: filed)
    }

    var body: some View {
        GeometryReader { geo in
            page(pageHeight: geo.size.height)
        }
    }

    private func page(pageHeight: CGFloat) -> some View {
        ScrollView {
            VStack(spacing: 0) {
                pressSweep

                Masthead(title: "Quizday", size: 34, doubleRule: tier.doubleImpression)
                    .popIn(delay: 0.18)
                    .padding(.top, 10)

                Text(dateline)
                    .dateline(11, tracking: 2)
                    .padding(.top, 10)
                    .popIn(delay: 0.26)

                scoreLine
                    .padding(.top, 14)

                if tallyPrinting || Motion.isStill {
                    Tally(flags: flags, total: total, height: 32, stagger: 0)
                        .padding(.top, 16)
                }

                headlineStamp
                    .padding(.top, 22)

                Text(tier.subline(score: score, total: total, chain: run.longestChain))
                    .brandFont(.title3, weight: .regular)
                    .italic()
                    .foregroundStyle(brand.palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 30)
                    .popIn(delay: 1.3)

                if streak > 0 {
                    HStack {
                        Spacer(minLength: 0)
                        StreakRibbon(days: streak)
                            .scaleEffect(x: Motion.isStill ? 1 : ribbon, anchor: .trailing)
                    }
                    .padding(.top, 26)
                    .accessibilityLabel(Voice.streak(streak, todayPlayed: true) ?? "")
                }

                // Below the fold, so the page and the plumbing never compete.
                InkRule(weight: 0.5, opacity: 0.3)
                    .padding(.top, 28)

                // What is waiting, named. The clock stays, under it and smaller: a countdown is
                // a fact about the paper, not a reason to come back.
                horizonLine
                    .padding(.top, 16)

                if lateEditionIsOpen {
                    lateEditionBox
                        .padding(.top, 14)
                }

                HStack(alignment: .top, spacing: 12) {
                    countdownBox
                    shareBox
                }
                .padding(.top, 14)

                Spacer(minLength: 24)

                // The page closes on a rule and the paper's own line, pinned to the foot of
                // the column.
                InkRule(weight: 0.5, opacity: 0.3)

                Text("Quizday · a new edition every morning")
                    .dateline(9, tracking: 2)
                    .padding(.top, 10)
            }
            .padding(.horizontal, 30)
            // The paper's own line is the last thing on the page, and the tab bar is glass
            // floating over the scroll: without this it printed underneath it.
            .padding(.bottom, 46)
            .frame(minHeight: pageHeight)
        }
        .paper(darken: 0.04)
        .confetti(trigger: burst,
                  colors: [Color(hex: 0xF5EFE2), Color(hex: 0xFBF7EC),
                           Color(hex: 0x1B2027), Color(hex: 0xC1362C)],
                  rain: tier.burst?.rain ?? false,
                  count: tier.burst?.count ?? 0,
                  power: tier.burst?.power ?? 0,
                  onAppear: Motion.isStill && tier.burst != nil)
        .task { await prepare() }
    }

    private var dateline: String {
        "Round \(editionNumber) · \(Masthead.dateline(for: playedAt))"
    }

    // MARK: - The page, part by part

    /// The press rule crossing the page: the sheet has been through the machine.
    private var pressSweep: some View {
        InkRule(weight: 3, color: brand.palette.accent)
            .scaleEffect(x: Motion.isStill ? 1 : pressRule, anchor: .leading)
            .accessibilityHidden(true)
    }

    private var scoreLine: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            if counting || Motion.isStill {
                CountUp(to: score, duration: 0.7) { tick in
                    Haptics.impact(0.4 + 0.05 * CGFloat(tick))
                    Tones.shared.play(.step(tick))
                }
                .brandDisplay(size: 112)
                .foregroundStyle(brand.palette.ink)
            } else {
                Text(" ").brandDisplay(size: 112)
            }
            Text("/\(total)")
                .brandDisplay(size: 34, relativeTo: .title)
                .foregroundStyle(brand.palette.inkSoft)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .accessibilityElement()
        .accessibilityLabel("\(score) out of \(total)")
    }

    private var headlineStamp: some View {
        ZStack {
            // A clean sweep stamps twice: a fainter second impression behind the first.
            if tier.doubleImpression, headline || Motion.isStill {
                Stamp(text: tier.headline, size: 24, stretch: 296)
                    .rotationEffect(.degrees(-7))
                    .opacity(0.35)
            }
            if headline || Motion.isStill {
                Stamp(text: tier.headline, size: 24, empty: tier == .blank, stretch: 296)
                    .rotationEffect(.degrees(tier.stamps ? -3 : 0))
                    .transition(tier.stamps
                                ? .scale(scale: 1.5).combined(with: .opacity)
                                : .opacity)
            }
        }
        // The brass stamp is laid outside the headline's ZStack: once the tier stamp was cut to
        // three quarters of the page it had nowhere inside it to land, and it came down across
        // the subline.
        .overlay(alignment: .bottomTrailing) {
            if isPersonalBest, personalBest || Motion.isStill {
                Stamp(text: "Longest run yet", color: brand.palette.highlight, size: 12)
                    .fixedSize()
                    .rotationEffect(.degrees(5))
                    .offset(x: 18, y: 30)
                    .transition(.scale(scale: 1.4).combined(with: .opacity))
            }
        }
    }

    /// The editor's last word, and the only part of the foot of the page that is about her.
    /// A door that opened tonight is named as opened; otherwise the next one is named as waiting.
    private var horizonLine: some View {
        let opened = justOpened.last
        let line = opened.map { "\(Voice.opened($0)) \($0.blurb)" }
            ?? Voice.horizon(filed: filed,
                             weakest: desk.weakestSections(limit: 1).first,
                             misses: desk.weakestSections(limit: 1).first.map(desk.misses(in:)) ?? 0)
        return HStack(alignment: .top, spacing: 10) {
            Rectangle()
                .fill(opened == nil ? brand.palette.inkSoft.opacity(0.5) : brand.palette.highlight)
                .frame(width: 3)
                .frame(maxHeight: .infinity)
            Text(line)
                .scaledFont(size: 16, design: .serif, relativeTo: .callout)
                .italic()
                .foregroundStyle(brand.palette.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .fixedSize(horizontal: false, vertical: true)
        .popIn(delay: 1.42)
        .accessibilityElement(children: .combine)
    }

    private var lateEditionIsOpen: Bool {
        Desk.earned.isUnlocked("late", at: filed)
    }

    /// The one door in this app that money cannot open. Practice stays behind the paywall; this
    /// arrives because she filed seven editions, and it is set from what got past her.
    private var lateEditionBox: some View {
        NavigationLink {
            LateEditionView(filed: filed)
        } label: {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("The late edition").dateline(10, tracking: 2, color: brand.palette.highlight)
                    Text("\(Spelled.leading(Desk.lateEditionCount(filed: filed))) more, set from what got past you.")
                        .scaledFont(size: 16, design: .serif, relativeTo: .callout)
                        .foregroundStyle(brand.palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .brandFont(.footnote)
                    .foregroundStyle(brand.palette.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .ruledBox(padding: 14, ruleColor: brand.palette.highlight)
        }
        .buttonStyle(.plain)
        .popIn(delay: 1.46)
    }

    private var countdownBox: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tomorrow's edition goes to press in")
                .dateline(10, tracking: 1.6)
                .fixedSize(horizontal: false, vertical: true)
            Text(timerInterval: Date.now...nextMidnight, countsDown: true)
                .scaledFont(size: 20, weight: .medium, design: .monospaced, relativeTo: .subheadline)
                .foregroundStyle(brand.palette.inkSoft)
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ruledBox(padding: 14)
        .popIn(delay: 1.5)
    }

    /// A ruled box with the share glyph in accent above the label, not a filled tile. The
    /// front page travels as a picture; the line of text is only the fallback.
    @ViewBuilder
    private var shareBox: some View {
        Group {
            if let shareImage {
                ShareLink(item: shareImage,
                          preview: SharePreview("Quizday · Round \(editionNumber)", image: shareImage)) {
                    shareLabel
                }
            } else {
                ShareLink(item: ShareEdition.line(roundNumber: editionNumber, flags: flags, streak: streak)) {
                    shareLabel
                }
            }
        }
        .buttonStyle(.plain)
        .popIn(delay: 1.5)
    }

    private var shareLabel: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.and.arrow.up")
                .brandFont(.title3)
                .foregroundStyle(brand.palette.accent)
            Text("Share the edition")
                .brandFont(.subheadline)
                .foregroundStyle(brand.palette.ink)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
        .ruledBox(padding: 14)
    }

    private var nextMidnight: Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date.now) ?? Date.now
        return calendar.startOfDay(for: tomorrow)
    }

    // MARK: - The choreography

    /// The front page renders once, not on every count-up tick.
    @MainActor
    private func prepare() async {
        shareImage = ShareEdition.card(score: score, total: total, flags: flags,
                                       roundNumber: editionNumber, playedAt: playedAt,
                                       streak: streak, tier: tier)
        await printEdition()
    }

    /// About a second and a half, in the order a page prints. Under `-stillFrames` every beat
    /// is already landed, so the capture shows the edition rather than a blank sheet.
    @MainActor
    private func printEdition() async {
        guard !Motion.isStill else { return }
        withAnimation(Motion.resolved(.easeOut(duration: 0.30))) { pressRule = 1 }
        await pause(0.34)
        counting = true
        await pause(0.70)
        withMotion(Motion.snappy) { tallyPrinting = true }
        await pause(0.14)
        Haptics.celebrate()
        if tier.fanfare { Tones.shared.play(.fanfare) }
        if !tier.stamps { Tones.shared.play(.pop) }
        withMotion(tier.stamps ? Motion.bouncy : Motion.gentle) { headline = true }
        await pause(0.06)
        if tier.burst != nil { burst += 1 }
        if isPersonalBest {
            await pause(0.16)
            Haptics.thud()
            Tones.shared.play(.step(7))
            withMotion(Motion.bouncy) { personalBest = true }
        }
        await pause(0.16)
        withMotion(Motion.bouncy) { ribbon = 1 }
    }

    private func pause(_ seconds: Double) async {
        try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
    }
}
