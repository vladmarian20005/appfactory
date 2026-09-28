import FactoryKit
import SwiftUI

/// Screen 1 · Today — today's lace and nothing else, the one everybody has. The same view,
/// `over` the Today tab, works the book or loose work, and closes back to it.
struct PillowView: View {
    @Binding var tab: RootView.Tab
    var over = false
    @EnvironmentObject private var bench: Bench
    @EnvironmentObject private var store: Store
    @Environment(\.brand) private var brand
    @State private var confirmPull = false
    @ScaledMetric(relativeTo: .body) private var reserve: CGFloat = 250

    var body: some View {
        NavigationStack {
            Group {
                if !over && bench.awayFromToday {
                    // Under the cover: nothing here while another pattern is on the pillow.
                    Color.clear
                } else if let lift = bench.lift {
                    LiftView(lift: lift)
                } else if !over && bench.todayDone {
                    DoneToday(tab: $tab)
                } else {
                    winding
                }
            }
            .linen(ticking: bench.record.ticking)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .alert("Pull the pins?", isPresented: $confirmPull) {
                Button("Pull them", role: .destructive) { bench.pullPins() }
                Button("Leave them", role: .cancel) {}
            } message: {
                Text("The thread comes off every pin and the pattern starts over.")
            }
        }
    }

    private var title: String {
        if bench.lesson != nil { return "Learn to wind" }
        switch bench.current?.kind ?? bench.lift?.piece.kind {
        case .book(let rung)?: return "Pattern \(rung)"
        case .loose?: return "Loose work"
        default: return "Today"
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(title).brandFont(.title3).foregroundStyle(brand.palette.ink)
                .accessibilityAddTraits(.isHeader)
        }
        if over {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    Haptics.tap()
                    bench.backToToday()
                } label: {
                    Image(systemName: "xmark")
                }
                .accessibilityLabel("Back to today's lace")
            }
        } else if bench.lesson != nil {
            ToolbarItem(placement: .topBarLeading) {
                Button("Skip") { bench.endLesson() }
                    .accessibilityLabel("Skip the practice")
            }
        }
        ToolbarItem(placement: .topBarTrailing) {
            if let lift = bench.lift {
                SwatchShareLink(piece: lift.piece, record: bench.record, compact: true)
            } else if bench.lesson != nil || bench.current != nil {
                Menu {
                    if bench.current?.isEmpty == false {
                        Button("Pull the pins", role: .destructive) { confirmPull = true }
                    }
                    if bench.record.hasEarned("silk") {
                        Picker("Thread", selection: Binding(get: { bench.record.thread }, set: bench.setThread)) {
                            ForEach(availableThreads, id: \.self) { t in Text(t.name).tag(t) }
                        }
                    }
                    if bench.lesson != nil {
                        Button("Skip the practice") { bench.endLesson() }
                    } else if !over {
                        Button("How to play") { bench.beginLesson() }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
                .accessibilityLabel("The pillow's menu")
            }
        }
    }

    private var availableThreads: [ThreadColour] {
        ThreadColour.allCases.filter { t in
            switch t {
            case .indigo: true
            case .rose: bench.record.hasEarned("silk")
            case .gold: bench.record.hasEarned("gold")
            }
        }
    }

    // MARK: - Winding

    private var winding: some View {
        GeometryReader { geo in
            // The room the head and the margin need grows with the text; the card gives way.
            let cardSize = max(200, min(geo.size.width - 48, geo.size.height - min(reserve, geo.size.height * 0.6)))
            VStack(alignment: .leading, spacing: 14) {
                head
                PillowBolster {
                    if let p = bench.current {
                        CardView(pillow: p, size: cardSize)
                            .id(p.pricking.seed)
                    } else {
                        PrickingCard(size: cardSize) { Color.clear }
                            .accessibilityLabel("The card is being pricked")
                    }
                }
                // A handful of snips as each practice card comes clear.
                .confetti(trigger: bench.lessonCheers,
                          colors: [AppBrand.Workbox.steel, bench.record.threadInHand.color, AppBrand.Workbox.brass],
                          from: UnitPoint(x: 0.5, y: 0.45),
                          count: 26, power: 0.5)
                if let lesson = bench.lesson {
                    lessonMargin(lesson)
                } else {
                    margin
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    /// Two columns so nothing wraps: the pins at the left, whose lace it is at the right. Under
    /// them, before the first pin, one line on what this pattern is.
    private var head: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .lastTextBaseline) {
                    count
                    Spacer(minLength: 8)
                    day.multilineTextAlignment(.trailing)
                }
                // Large text: the day goes under the count rather than crowding it.
                VStack(alignment: .leading, spacing: 6) {
                    count
                    day
                }
            }
            if bench.lesson == nil, let p = bench.current, p.isEmpty {
                Text(goal(for: p))
                    .font(.subheadline.italic())
                    .foregroundStyle(brand.palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                    .transition(.opacity)
            }
        }
        .animation(Motion.resolved(Motion.gentle), value: bench.current?.isEmpty)
    }

    /// What this pattern is, said once, before the first pin.
    private func goal(for p: SavedPillow) -> String {
        let start = p.pricking.start == nil ? "Start at any pin" : "Start at the gold pin"
        switch p.kind {
        case .today: return "Today's lace, the same one for everybody. \(start), and every pin, once."
        case .book: return "From the pattern book. \(start), and every pin, once."
        case .loose: return "Loose work, never the same twice. \(start), and every pin, once."
        }
    }

    private var count: some View {
        let p = bench.current
        let pr = p?.pricking
        return VStack(alignment: .leading, spacing: 4) {
                if let pr {
                    Text(Words.size(pr.side))
                        .caps()
                        .fixedSize(horizontal: false, vertical: true)
                }
                HStack(alignment: .lastTextBaseline, spacing: 8) {
                    Text("\(p?.path.count ?? 0)")
                        .brandDisplay(size: 34)
                        .monospacedDigit()
                        .foregroundStyle(brand.palette.ink)
                        .contentTransition(.numericText(value: Double(p?.path.count ?? 0)))
                        .animation(Motion.resolved(Motion.snappy), value: p?.path.count)
                    Text("of \(pr?.pins ?? 0) pins").caps()
                }
            }
            .accessibilityElement(children: .combine)
    }

    private var day: some View {
        VStack(alignment: .trailing, spacing: 4) {
                switch (bench.lesson?.step, bench.current?.kind) {
                case (let step?, _):
                    Text("Practice").caps()
                    Text("\(Words.capitalised(step + 1)) of \(Words.number(FirstCard.cards.count))").caps()
                case (nil, .book(let rung)?):
                    Text("Pattern \(rung)").brandFont(.title3).foregroundStyle(brand.palette.ink)
                    Text(bench.hasBook || bench.freeLeft == 0 ? "The book"
                         : "The book · \(Words.number(bench.freeLeft)) free").caps()
                case (nil, .loose(let n)?):
                    Text("Loose work").brandFont(.title3).foregroundStyle(brand.palette.ink)
                    Text("Piece \(n)").caps()
                default:
                    Text("No. \(bench.todayNumber)").brandFont(.title3).foregroundStyle(brand.palette.ink)
                    Text(Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))).caps()
                }
            }
            .accessibilityElement(children: .combine)
    }

    /// Under the pillow: the thread's caps, the lacemaker's latest line, and the run marks.
    private var margin: some View {
        let p = bench.current
        let path = p?.path.map(Int.init) ?? []
        let plaits = p?.plaits ?? []
        return VStack(alignment: .leading, spacing: 10) {
            if let p, !p.isEmpty {
                Text(Voice.marginCaps(chain: p.run.chain, unpicks: p.run.misses, plaits: plaits.count))
                    .caps()
                    .fixedSize(horizontal: false, vertical: true)
                    .contentTransition(.numericText())
            }
            lineView
                .frame(minHeight: 26, alignment: .topLeading)
            RunMarks(path: path, plaits: plaits, color: bench.record.threadInHand.color)
        }
        .padding(.horizontal, 6)
    }

    /// On a practice card the margin is the lacemaker's note: the rule upright in New York,
    /// the rest in italic under it. The last card's note ends on the way into the book.
    private func lessonMargin(_ lesson: Bench.Lesson) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(lesson.note.title)
                .brandFont(.title3)
                .foregroundStyle(lesson.cleared ? brand.palette.success : brand.palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(lesson.note.detail)
                .font(.body.italic())
                .foregroundStyle(brand.palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            if lesson.cleared && lesson.isLast {
                Button {
                    Haptics.tap()
                    bench.endLesson()
                } label: {
                    Text("Start today's lace · No. \(bench.todayNumber)").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .brandProminent()
                .padding(.top, 10)
                .transition(.opacity.combined(with: .offset(y: 6)))
            }
        }
        .id(lesson.note)
        .transition(.opacity.combined(with: .offset(y: 4)))
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var lineView: some View {
        if let line = bench.line {
            let parts = split(line.text, head: line.kind == .hint ? 48 : 24)
            (Text(parts.0)
                .foregroundStyle(line.kind == .plait ? brand.palette.success
                                 : line.kind == .hint ? brand.palette.ink : brand.palette.miss)
             + Text(parts.1).italic().foregroundStyle(brand.palette.inkSoft))
                .font(.body)
                .id(line.id)
                .transition(.opacity.combined(with: .offset(y: 4)))
        }
    }

    /// The word before the first full stop is set upright in its colour; the rest in italic.
    private func split(_ s: String, head limit: Int = 24) -> (String, String) {
        guard let dot = s.firstIndex(of: "."), s.distance(from: s.startIndex, to: dot) < limit else { return ("", s) }
        let head = String(s[...dot])
        return (head, String(s[s.index(after: dot)...]))
    }
}

/// One short bar of thread per straight run wound so far: solid where the run plaited, faint
/// where it did not — the shape of the solve, legible at a glance.
struct RunMarks: View {
    let path: [Int]
    let plaits: [Range<Int>]
    let color: Color

    var body: some View {
        let runs = ThreadGeometry.runs(in: path)
        let plaited = Set(plaits.map(\.lowerBound))
        // Wraps rather than running off the edge on a long thread.
        FlowRow(spacing: 8) {
            ForEach(Array(runs.enumerated()), id: \.offset) { _, run in
                Capsule()
                    .fill(color.opacity(plaited.contains(run.lowerBound) ? 1 : 0.3))
                    .frame(width: 18, height: 3.4)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(Motion.resolved(Motion.snappy), value: runs.count)
        .accessibilityElement()
        .accessibilityLabel("\(runs.count) runs wound, \(plaits.count) plaited")
    }
}

/// A simple wrapping row.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 320
        var x: CGFloat = 0, y: CGFloat = 0, line: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > width, x > 0 { x = 0; y += line + spacing; line = 0 }
            x += sz.width + spacing
            line = max(line, sz.height)
        }
        return CGSize(width: width, height: y + line)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, line: CGFloat = 0
        for s in subviews {
            let sz = s.sizeThatFits(.unspecified)
            if x + sz.width > bounds.maxX, x > bounds.minX { x = bounds.minX; y += line + spacing; line = 0 }
            s.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(sz))
            x += sz.width + spacing
            line = max(line, sz.height)
        }
    }
}
