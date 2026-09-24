import FactoryKit
import SwiftUI

/// Screen 1 · Today. The pattern, the thread, and the winding.
struct PillowView: View {
    @EnvironmentObject private var bench: Bench
    @EnvironmentObject private var store: Store
    @Environment(\.brand) private var brand
    @State private var confirmPull = false

    var body: some View {
        NavigationStack {
            Group {
                if let lift = bench.lift {
                    LiftView(lift: lift)
                } else if bench.todayDone {
                    doneForToday
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
        if let lift = bench.lift { return lift.pricking.ground.title }
        if bench.todayDone { return "The pillow" }
        return bench.current?.pricking.ground.title ?? "The pillow"
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Text(title).brandFont(.title3).foregroundStyle(brand.palette.ink)
                .accessibilityAddTraits(.isHeader)
        }
        ToolbarItem(placement: .topBarTrailing) {
            if let lift = bench.lift {
                SwatchShareLink(piece: lift.piece, record: bench.record, compact: true)
            } else {
                Menu {
                    if bench.current?.isEmpty == false {
                        Button("Pull the pins", role: .destructive) { confirmPull = true }
                    }
                    if bench.record.hasEarned("silk") {
                        Picker("Thread", selection: Binding(get: { bench.record.thread }, set: bench.setThread)) {
                            ForEach(availableThreads, id: \.self) { t in Text(t.name).tag(t) }
                        }
                    }
                    if bench.which != .today {
                        Button("Back to today's pattern") { bench.backToToday() }
                    } else if bench.bookOpen {
                        Button("Pin the next pattern") { bench.pinNext() }
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
            let cardSize = max(200, min(geo.size.width - 48, geo.size.height - 230))
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
                margin
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }

    /// Two columns so nothing wraps: the shape and the count at the left, the day at the right.
    private var head: some View {
        let p = bench.current
        let pr = p?.pricking
        return HStack(alignment: .lastTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                if let pr {
                    Text("\(Words.size(pr.side)) · \(pr.ground.name) ground").caps()
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
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                switch p?.kind {
                case .book(let rung)?:
                    Text("Pattern \(rung)").caps()
                    Text("The book").caps()
                case .loose(let n)?:
                    Text("Loose work").caps()
                    Text("Piece \(n)").caps()
                default:
                    Text("Today's pattern").caps()
                    Text(Date.now.formatted(.dateTime.day().month(.wide))).caps()
                }
            }
            .multilineTextAlignment(.trailing)
            .accessibilityElement(children: .combine)
        }
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
                    .contentTransition(.numericText())
            }
            lineView
                .frame(minHeight: 26, alignment: .topLeading)
            RunMarks(path: path, plaits: plaits, color: bench.record.threadInHand.color)
        }
        .padding(.horizontal, 6)
    }

    @ViewBuilder
    private var lineView: some View {
        if let line = bench.line {
            let parts = split(line.text)
            (Text(parts.0)
                .foregroundStyle(line.kind == .plait ? brand.palette.success : brand.palette.miss)
             + Text(parts.1).italic().foregroundStyle(brand.palette.inkSoft))
                .font(.body)
                .id(line.id)
                .transition(.opacity.combined(with: .offset(y: 4)))
        }
    }

    /// The word before the first full stop is set upright in its colour; the rest in italic.
    private func split(_ s: String) -> (String, String) {
        guard let dot = s.firstIndex(of: "."), s.distance(from: s.startIndex, to: dot) < 24 else { return ("", s) }
        let head = String(s[...dot])
        return (head, String(s[s.index(after: dot)...]))
    }

    // MARK: - Today's is in the sampler

    private var doneForToday: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image("Bobbins")
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280)
                    .ambientFloat(distance: 4, period: 4.4)
                    .accessibilityHidden(true)
                    .padding(.top, 24)
                Text("Today's is in the sampler")
                    .brandFont(.largeTitle)
                    .foregroundStyle(brand.palette.ink)
                    .multilineTextAlignment(.center)
                Text(bench.bookOpen ? "The next pattern in the book is pinned and waiting."
                                    : "The book goes on past the sixtieth, and today's is kept.")
                    .font(.title3)
                    .foregroundStyle(brand.palette.inkSoft)
                    .multilineTextAlignment(.center)
                if let piece = bench.todayPiece {
                    Text("Today · \(Words.size(piece.side)) · \(piece.ground.name) ground · \(piece.isClean ? "worked clean" : "picked out \(Words.times(piece.unpicks))")")
                        .caps()
                        .multilineTextAlignment(.center)
                }
                Button {
                    Haptics.tap()
                    bench.pinNext()
                } label: {
                    Text("Pin the next pattern").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
                }
                .brandProminent()
                .padding(.top, 8)
            }
            .padding(24)
        }
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
