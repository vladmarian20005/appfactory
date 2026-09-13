import FactoryKit
import SwiftData
import SwiftUI

/// Screen 2, the face: one stave, in your hand, and the cut.
///
/// The verb this screen exists for is the cut — the blade sinks into the shoulder, a V opens
/// and overshoots, seven pale slivers fly, the tone climbs through the gate and resets on the
/// fifth, and the blade walks on to the next position. Everything else on the screen is what
/// the record can be read back as.
struct CounterFaceView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dynamicTypeSize) private var typeSize
    @EnvironmentObject private var store: Store
    @Bindable var counter: Counter
    @Binding var showPaywall: Bool

    @Namespace private var staveSpace

    @State private var cuts = 0
    @State private var notchGrowth: CGFloat = 1
    @State private var strikeProgress: CGFloat = 1
    @State private var waxShake = 0
    @State private var win: WinState?
    @State private var reading: String?
    @State private var sittingCard: String?
    @State private var note: String?
    @State private var lastPraise: String?
    @State private var goalBurst = 0
    @State private var confirmingPlaneToday = false
    @State private var confirmingPlaneAll = false
    @State private var lastCutAt = Date.distantPast
    @State private var endWatch: Task<Void, Never>?

    /// The springs DESIGN.md names. The notch's is the one that matters: dampingFraction
    /// 0.74 carries it a point past its final width and settles back, which is the wood
    /// giving and then holding.
    private enum Cut {
        static let bite = Animation.spring(response: 0.11, dampingFraction: 0.92)
        static let open = Animation.spring(response: 0.16, dampingFraction: 0.74)
    }

    // MARK: Derived record

    private var record: Record { counter.record }
    private var marks: [Mark] { record.currentStave }
    private var daysKept: Int { record.daysKept }
    private var rung: Int { max(1, daysKept) }
    private var grain: Int { Bench.ladder["grain", at: rung] ?? 1 }
    private var span: Int {
        store.isProUnlocked ? (Bench.ladder["span", at: rung] ?? 14) : AppInfo.freeStripDays
    }
    private var hasRack: Bool { Bench.earned.isUnlocked("rack", at: record.stavesScored) }
    private var hasGauge: Bool { Bench.earned.isUnlocked("gauge", at: record.stavesScored) }
    private var isOiled: Bool { Bench.earned.isUnlocked("oil", at: record.stavesScored) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                BenchEdge()
                    .padding(.bottom, 4)
                if let win {
                    Text(win.headline)
                        .brandFont(.title)
                        .foregroundStyle(.brandHighlight)
                        .fixedSize(horizontal: false, vertical: true)
                        .transition(.opacity)
                }
                hero
                staveArea
                stripBlock
                panel
                foot
                if hasRack {
                    RackRail(dates: record.scoredStaveDates,
                             pigment: counter.pigment.color,
                             oiled: isOiled,
                             glowing: win?.lifted == true)
                        .padding(.top, 4)
                        .padding(.bottom, 26)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .benchBackground()
        .navigationTitle(counter.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .confirmationDialog("Plane today's \(counter.todayTotal) off \(counter.name)?",
                            isPresented: $confirmingPlaneToday, titleVisibility: .visible) {
            Button("Plane it off", role: .destructive, action: planeToday)
            Button("Leave it", role: .cancel) {}
        }
        .confirmationDialog("Plane every notch off \(counter.name)?",
                            isPresented: $confirmingPlaneAll, titleVisibility: .visible) {
            Button("Take it all off", role: .destructive, action: planeAll)
            Button("Leave it", role: .cancel) {}
        }
        .task { await open() }
    }

    // MARK: The hero

    private var hero: some View {
        // Side by side there is no room for a 116 pt numeral and a gauge at an accessibility
        // text size. The same instinct as the bench's row swap: stack rather than shrink,
        // because a wrapped number is a different number.
        Group {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 10) { total; dayLine }
            } else {
                HStack(alignment: .lastTextBaseline, spacing: 16) {
                    total
                    Spacer(minLength: 8)
                    dayLine.frame(maxWidth: 190)
                }
            }
        }
    }

    private var total: some View {
        ZStack(alignment: .leading) {
            if let win {
                // The ghost numeral the scored stave rises over, counting up as it goes.
                CountUp(to: win.total, from: max(0, win.total - 12), duration: 0.7) { n in
                    Haptics.impact(0.3 + 0.05 * CGFloat(n % 6))
                    Tones.shared.play(.step(n % 8), volume: 0.5)
                }
                .brandDisplay(size: 132)
                .foregroundStyle(.brandHighlight.opacity(0.22))
            } else {
                Text("\(record.total)")
                    .brandDisplay(size: 116)
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(.brandInk)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.4)
        .accessibilityLabel("\(record.total) on this stave's counter")
    }

    @ViewBuilder
    private var dayLine: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(counter.dailyGoal > 0
                 ? "\(record.today) today · goal \(counter.dailyGoal)"
                 : "\(record.today) today")
                .stencilCaps()
                .foregroundStyle(.brandInkSoft)
            if counter.dailyGoal > 0 {
                BrassGauge(today: record.today, goal: counter.dailyGoal)
                    .confetti(trigger: goalBurst, colors: [.brandSuccess, counter.pigment.color],
                              from: UnitPoint(x: 0.5, y: 0.5), count: 18, power: 0.4)
            }
        }
    }

    // MARK: The stave and the cut

    private var staveArea: some View {
        // The chisel's handle rises well above the shoulder, the way it does in mock 1. The
        // air above the stave is what keeps it from landing on the gauge.
        VStack(alignment: .leading, spacing: 12) {
            Button(action: cut) {
                staveBody.padding(.top, 22)
            }
            .buttonStyle(.pressable(scale: 0.98, haptic: false))
            .accessibilityLabel("Cut a notch")
            .accessibilityHint("Cuts a notch into \(counter.name)")

            HStack(alignment: .top, spacing: 14) {
                Button(action: wax) {
                    HStack(spacing: 7) {
                        WaxStickGlyph(height: 38)
                        Text("Wax")
                            .stencilCaps()
                            .foregroundStyle(.brandInkSoft)
                    }
                    .frame(height: 52)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.pressable)
                .disabled(record.total == 0 || win != nil)
                .accessibilityLabel("Fill the last notch with wax")
                .accessibilityHint("Takes one back off \(counter.name). The mark stays.")

                if let note {
                    Text(note)
                        .brandFont(.footnote, weight: .regular)
                        .foregroundStyle(.brandInkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 16)
                        .transition(.opacity)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private var staveBody: some View {
        ZStack(alignment: .topLeading) {
            if win?.lifted != true {
                stave
                    .matchedGeometryEffect(id: "stave", in: staveSpace)
            }
        }
        .frame(height: 128)
        // A cut taken back is forgiven with a gentle shake, never a buzzer.
        .shake(trigger: waxShake)
        .confetti(trigger: cuts,
                  colors: [Color(hex: 0xEDE1C6), Color(hex: 0xF6EFDC), Color(hex: 0x6A4A2A)],
                  from: UnitPoint(x: bladeFraction, y: 0.34),
                  count: 7, power: 0.22)
        .confetti(trigger: win?.burst ?? 0,
                  colors: [Color(hex: 0xEDE1C6), Color(hex: 0xF6EFDC), Color(hex: 0x6A4A2A), Color(hex: 0xA2361B)],
                  from: UnitPoint(x: 0.5, y: 0.46),
                  count: win?.tier == .best ? 110 : (win?.tier == .clean ? 72 : 40),
                  power: win?.tier == .best ? 1.4 : (win?.tier == .clean ? 1.0 : 0.6))
    }

    private var stave: some View {
        GeometryReader { geo in
            let width = geo.size.width
            StaveBoard(pigment: counter.pigment.color, oiled: isOiled) {
                ZStack(alignment: .topLeading) {
                    Color.clear.frame(height: 92)
                    StaveMarks(marks: marks,
                               openingGrowth: notchGrowth,
                               strikeProgress: strikeProgress,
                               gatesLit: win?.gatesLit ?? 0)
                        .padding(.leading, 22)
                        .padding(.trailing, 14)
                        .padding(.top, 9)
                    if marks.isEmpty && win == nil { ghostNotch }
                    Text(counter.name.uppercased())
                        .brandFont(.title3)
                        .foregroundStyle(.brandInk.opacity(0.42))
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .padding(.leading, 24)
                        .padding(.bottom, 12)
                        .frame(maxWidth: width * 0.7, maxHeight: .infinity, alignment: .bottomLeading)
                }
            }
            .overlay(alignment: .bottom) {
                if let win, win.scoreTrim > 0 { scoringStroke(width: width, trim: win.scoreTrim) }
            }
            .overlay(alignment: .topLeading) {
                blade(width: width)
            }
            .overlay(alignment: .trailing) {
                if let win, win.dated { endGrain }
            }
            .rotationEffect(.degrees(-2.5), anchor: .center)
        }
        .frame(height: 116)
    }

    /// Where the blade rests: over the *next* notch position, worked out the same way
    /// `StaveMarks` lays the marks out, so the edge sits on the spot the cut will land and
    /// not near it. The stave never moves; the blade walks, and that travel is the
    /// anticipation for the next cut.
    private func bladeX(width: CGFloat) -> CGFloat {
        let region = max(1, width - 36)
        let gateWidth = region / CGFloat(notchesPerStave / notchesPerGate)
        let span = gateWidth - 5
        let pitch = span / CGFloat(notchesPerGate - 1)
        let gate = min(notchesPerStave / notchesPerGate - 1, marks.count / notchesPerGate)
        let within = marks.count % notchesPerGate
        let inGate = within < 4 ? 2 + CGFloat(within) * pitch + 3.5 : span / 2
        return 22 + CGFloat(gate) * gateWidth + inGate
    }

    /// Where the swarf is thrown from, as a fraction of the stave.
    private var bladeFraction: CGFloat {
        let gate = CGFloat(min(9, marks.count / notchesPerGate))
        return min(0.97, 0.07 + gate / 10 * 0.88)
    }

    private func blade(width: CGFloat) -> some View {
        ChiselGlyph(height: 76)
            .offset(x: bladeX(width: width) - 13, y: win?.lifted == true ? -58 : -50)
            .opacity(win?.lifted == true ? 0 : 1)
            .modifier(BladeBreath(active: marks.isEmpty && win == nil))
            .animation(Motion.resolved(Motion.pop), value: marks.count)
            .accessibilityHidden(true)
    }

    /// On a bare stave the blade breathes and a ghost notch pulses where the first cut will
    /// land. Both stop at the first cut and never come back. There is no "tap to add" in this
    /// app — the affordance does the teaching.
    private var ghostNotch: some View {
        NotchMark(mark: .cut, width: 7, depth: 15)
            .opacity(0.10)
            .breathing(amount: 0.05, period: 2.6)
            .padding(.leading, 24)
            .padding(.top, 9)
            .accessibilityHidden(true)
    }

    private func scoringStroke(width: CGFloat, trim: CGFloat) -> some View {
        Path { path in
            path.move(to: CGPoint(x: 8, y: 86))
            path.addLine(to: CGPoint(x: width - 8, y: 10))
        }
        .trim(from: 0, to: trim)
        .stroke(.brandInk.opacity(0.78), style: StrokeStyle(lineWidth: 3.4, lineCap: .round))
        .frame(height: 96)
        .accessibilityHidden(true)
    }

    /// The date stamped into the stave's end, in the stencil caps. A finished stave says when.
    private var endGrain: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(Date.now.formatted(.dateTime.day().month(.abbreviated)))
                .stencilCaps()
                .foregroundStyle(.brandHighlight)
            Text("Stave \(record.stavesScored)")
                .stencilCaps()
                .foregroundStyle(.brandInkSoft)
        }
        .padding(8)
        .background(RoundedRectangle(cornerRadius: 3, style: .continuous)
            .fill(.brandSurface.mix(with: .brandInk, amount: 0.18)))
        .offset(x: 10)
        .transition(.scale(scale: 1.4).combined(with: .opacity))
    }

    // MARK: The strip

    private var stripBlock: some View {
        VStack(alignment: .leading, spacing: 7) {
            let days = record.strip(span: span, grain: grain)
            HStack {
                Text("Last \(span) days").stencilCaps()
                Spacer()
                if store.isProUnlocked {
                    Text("\(record.today) today").stencilCaps()
                } else {
                    Button("The whole record") { showPaywall = true }
                        .stencilCaps()
                }
            }
            .foregroundStyle(.brandInkSoft)

            StripView(days: days, pigment: counter.pigment.color, ruled: hasGauge)

            // Which stretch of the record this is, so the strip is a span and not a shape.
            HStack {
                Text(days.first?.day.formatted(.dateTime.day().month(.abbreviated)) ?? "")
                    .stencilCaps()
                Spacer()
                Text("Today").stencilCaps()
            }
            .foregroundStyle(.brandInkSoft.opacity(0.85))

            if grain >= 3 {
                HourBand(hours: record.hours(span: span), pigment: counter.pigment.color)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: The reading, and the sitting card

    private var panel: some View {
        StaveBoard(pigment: nil, oiled: isOiled) {
            VStack(alignment: .leading, spacing: 7) {
                Text(sittingCard == nil ? "Reading" : "This sitting")
                    .stencilCaps()
                    .foregroundStyle(.brandInkSoft)
                Text(sittingCard ?? reading ?? "The bench is ready. Nothing is cut yet.")
                    .brandFont(.callout, weight: .regular)
                    .foregroundStyle(.brandInk)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(14)
        }
        .animation(Motion.resolved(Motion.gentle), value: sittingCard)
    }

    private var foot: some View {
        Text("Kept \(daysKept) days · longest run \(record.longestRunOfDays)")
            .stencilCaps()
            .foregroundStyle(.brandInkSoft)
            .accessibilityLabel("Kept \(daysKept) days. Longest run \(record.longestRunOfDays) days.")
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if let image = shareCard {
                ShareLink(item: image,
                          preview: SharePreview(counter.name, image: image)) {
                    Label("Send the stave", systemImage: "square.and.arrow.up")
                }
            }
        }
        ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("Plane today off", role: .destructive) { confirmingPlaneToday = true }
                    .disabled(record.today == 0)
                Button("Plane the stave back", role: .destructive) { confirmingPlaneAll = true }
                    .disabled(counter.entries.isEmpty)
            } label: {
                Label("More", systemImage: "ellipsis")
            }
        }
    }

    @MainActor
    private var shareCard: Image? {
        ShareImage.render(size: CGSize(width: 360, height: 450)) {
            StaveShareCard(name: counter.name,
                           total: record.total,
                           marks: marks,
                           strip: record.strip(span: 14, grain: 1),
                           pigment: counter.pigment.color,
                           daysKept: daysKept,
                           clean: !record.staveHasWax)
                .brand(AppBrand.brand)
        }
    }

    // MARK: Acts

    private func cut() {
        guard win == nil else { return }
        // A second press inside 90 ms is the same press. A real cut takes as long as it takes.
        guard Date.now.timeIntervalSince(lastCutAt) > 0.09 else { return }
        lastCutAt = .now

        Haptics.rigid()
        let sitting = record.sitting
        Tones.shared.play(.step(sitting.chain % notchesPerGate))

        context.insert(Tap(delta: 1, counter: counter))
        try? context.save()

        notchGrowth = 0
        withMotion(Cut.open) { notchGrowth = 1 }
        cuts += 1
        withMotion(Motion.snappy) { note = nil }

        let now = record.cuts
        if now % notchesPerGate == 0 {
            strikeProgress = 0
            withAnimation(Motion.resolved(Motion.gentle)?.speed(3.9)) { strikeProgress = 1 }
            Haptics.soft()
            Tones.shared.play(.pop)
        }

        // The blade's lift: bite then release, two ticks 130 ms apart, which is what makes
        // the thumb believe it.
        if !Motion.isStill {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 130_000_000)
                Haptics.tap()
            }
        }

        if counter.dailyGoal > 0 && record.today == counter.dailyGoal {
            goalBurst += 1
            Haptics.success()
            Tones.shared.play(.success)
            withMotion(Motion.snappy) { note = AppInfo.line(from: AppInfo.goalReached, avoiding: note) }
        }

        if now % notchesPerStave == 0 { score() }
        armSittingEnd()
    }

    private func wax() {
        guard record.total > 0, win == nil else { return }
        Haptics.warning()
        Tones.shared.play(.miss)
        context.insert(Tap(delta: -1, counter: counter))
        try? context.save()
        waxShake += 1
        withMotion(Motion.snappy) {
            note = AppInfo.line(from: AppInfo.nearMiss, avoiding: note)
        }
        armSittingEnd()
    }

    /// The stave is scored: not a sheet with a checkmark — the stave is finished, dated and
    /// stood up in front of you, over about a second and a half.
    private func score() {
        let run = record.sitting
        let tier = run.tier(score: run.longestChain, beating: bestCleanRun)
        if run.longestChain > bestCleanRun { bestCleanRun = run.longestChain }

        var state = WinState(tier: tier,
                             headline: AppInfo.headline(for: tier),
                             total: record.total,
                             praise: AppInfo.line(from: AppInfo.praise, avoiding: lastPraise))
        lastPraise = state.praise
        note = state.praise

        guard !Motion.isStill else {
            // A still capture has to show the win, not the frame before it: everything lands
            // at once and the confetti freezes at its peak.
            state.gatesLit = notchesPerStave / notchesPerGate
            state.scoreTrim = 1
            state.lifted = true
            state.dated = true
            state.burst = 1
            win = state
            sittingCard = sittingLine(ending: true)
            return
        }

        win = state
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 90_000_000)
            // Everything holds, and the ten gates light one after another, left to right.
            for gate in 1...(notchesPerStave / notchesPerGate) {
                withAnimation(.linear(duration: 0.02)) { win?.gatesLit = gate }
                try? await Task.sleep(nanoseconds: 26_000_000)
            }
            withAnimation(.easeInOut(duration: 0.34)) { win?.scoreTrim = 1 }
            try? await Task.sleep(nanoseconds: 340_000_000)
            Haptics.thud()
            try? await Task.sleep(nanoseconds: 40_000_000)
            withMotion(Motion.bouncy) { win?.lifted = true }
            try? await Task.sleep(nanoseconds: 160_000_000)
            win?.burst += 1
            try? await Task.sleep(nanoseconds: 100_000_000)
            withMotion(Motion.bouncy) { win?.dated = true }
            Haptics.celebrate()
            Tones.shared.play(tier == .finished ? .success : .fanfare)
            if tier == .best {
                try? await Task.sleep(nanoseconds: 200_000_000)
                Haptics.celebrate()
                Tones.shared.play(.step(7))
            }
            try? await Task.sleep(nanoseconds: 280_000_000)
            withMotion(Motion.gentle) { sittingCard = sittingLine(ending: true) }
            try? await Task.sleep(nanoseconds: 400_000_000)
            withMotion(Motion.gentle) { win = nil }
        }
    }

    @AppStorage("tallies.bestCleanRun") private var bestCleanRun = 0

    /// The sitting card. Specific, earned, true, and no guilt in it — and it names what is
    /// waiting rather than asking for anything.
    private func sittingLine(ending: Bool) -> String {
        let run = record.sitting
        let cut = run.hits
        let waxed = run.misses
        let scored = record.stavesScored
        let notches = record.notchesIntoStave

        if scored == 0 && notches > 0 && cut == notches {
            let togo = notchesPerStave - notches
            return "\(Bench.capitalised(Bench.spelled(cut))) cut. \(Bench.capitalised(Bench.spelled(togo))) to go on this stave, and then it is scored and stood up."
        }

        let cutPart = "\(Bench.capitalised(Bench.spelled(cut))) cut, \(waxed == 0 ? "none waxed" : "\(Bench.spelled(waxed)) waxed")."
        let stavePart = ending && notches == 0
            ? "Fifty into this stave, and it is scored."
            : "\(Bench.capitalised(Bench.spelled(notches))) notches into this stave."
        return "\(cutPart) \(stavePart) \(Bench.horizon(stavesScored: scored, daysKept: daysKept, inRack: scored))"
    }

    /// A sitting runs from the first cut to two minutes after the last, and the card rises in
    /// place of the reading when it ends — not while it is still going, which would make the
    /// carver keep interrupting to say how it is going.
    private func armSittingEnd() {
        endWatch?.cancel()
        withMotion(Motion.gentle) { sittingCard = nil }
        guard !Motion.isStill else { return }
        endWatch = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(Record.sittingGap * 1_000_000_000))
            guard !Task.isCancelled else { return }
            withMotion(Motion.gentle) { sittingCard = sittingLine(ending: false) }
        }
    }

    private func planeToday() {
        let start = Calendar.current.startOfDay(for: .now)
        for entry in counter.entries where entry.at >= start { context.delete(entry) }
        try? context.save()
        Haptics.soft()
    }

    private func planeAll() {
        for entry in counter.entries { context.delete(entry) }
        try? context.save()
        Haptics.soft()
    }

    // MARK: Opening the screen

    private func open() async {
        // One reading, chosen by the rota at the start of the sitting and held for it.
        let state = Readings.load(for: counter)
        if let picked = Readings.next(for: counter, record: record, state: state) {
            reading = picked.line
            Readings.save(picked.state, for: counter)
        }
        // The last sitting is already over by the time the screen is opened again: the card
        // it ended on has had its moment, and the reading takes the panel back.
        switch LaunchOptions.demo {
        case "cut": await demoCut()
        case "score": await demoScore()
        default: break
        }
        if LaunchOptions.screen == "win" { score() }
    }

    /// Nothing on a runner can touch the screen, so the app plays its own signature
    /// interaction: five cuts, the fifth closing a gate.
    private func demoCut() async {
        try? await Task.sleep(nanoseconds: 700_000_000)
        for _ in 0..<5 {
            lastCutAt = .distantPast
            cut()
            try? await Task.sleep(nanoseconds: 330_000_000)
        }
    }

    /// The forty-eighth to the fiftieth, and the stave is scored.
    private func demoScore() async {
        try? await Task.sleep(nanoseconds: 700_000_000)
        for _ in 0..<3 {
            lastCutAt = .distantPast
            cut()
            try? await Task.sleep(nanoseconds: 400_000_000)
        }
    }
}

/// Where the win is in its second and a half.
struct WinState: Equatable {
    let tier: Run.Tier
    let headline: String
    let total: Int
    let praise: String
    var gatesLit = 0
    var scoreTrim: CGFloat = 0
    var lifted = false
    var dated = false
    var burst = 0
}

/// The blade floats over a bare stave and stops at the first cut. Through FactoryKit, so it
/// stands still under `-stillFrames` and for Reduce Motion.
private struct BladeBreath: ViewModifier {
    let active: Bool

    func body(content: Content) -> some View {
        if active {
            content.ambientFloat(distance: 3, period: 2.6)
        } else {
            content
        }
    }
}

/// The brand's colours as shape styles, so a view can say `.brandInk` the way it says
/// `.primary`. Reading them from the environment at every use site made the face a wall of
/// `brand.palette.` and nothing else.
extension ShapeStyle where Self == Color {
    static var brandInk: Color { AppBrand.brand.palette.ink }
    static var brandInkSoft: Color { AppBrand.brand.palette.inkSoft }
    static var brandSurface: Color { AppBrand.brand.palette.surface }
    static var brandAccent: Color { AppBrand.brand.palette.accent }
    static var brandHighlight: Color { AppBrand.brand.palette.highlight }
    static var brandSuccess: Color { AppBrand.brand.palette.success }
    static var brandMiss: Color { AppBrand.brand.palette.miss }
}
