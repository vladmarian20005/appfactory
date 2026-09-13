import FactoryKit
import SwiftData
import SwiftUI

/// Screen 1, the bench: every stave you keep, laid across the screen like work, and a cut
/// without leaving the screen. Not a list of cards — a pile of boards.
struct BenchView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: Store
    @Binding var showPaywall: Bool

    @Query(sort: \Counter.createdAt, order: .forward) private var counters: [Counter]
    @State private var path: [Counter] = []
    @State private var showLay = false

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if counters.isEmpty {
                    bareBench
                } else {
                    bench
                }
            }
            .benchBackground()
            .navigationTitle("Tallies")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { layTapped() } label: {
                        BareStaveGlyph()
                            .frame(width: 26, height: 15)
                    }
                    .accessibilityLabel("Lay a new stave")
                }
            }
            .navigationDestination(for: Counter.self) {
                CounterFaceView(counter: $0, showPaywall: $showPaywall)
            }
            .sheet(isPresented: $showLay) {
                LayStaveView { name, colorID, goal in
                    context.insert(Counter(name: name, colorID: colorID, dailyGoal: goal))
                    try? context.save()
                }
            }
            .onAppear(perform: applyLaunchOptions)
        }
    }

    /// Mock 3: the drawn bench, not a `ContentUnavailableView` with a bullet-list symbol.
    private var bareBench: some View {
        VStack(spacing: 0) {
            BenchEdge()
            ScrollView {
                VStack(spacing: 18) {
                    Image("Bench")
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                        .ambientFloat(distance: 3, period: 4.4)
                        .accessibilityLabel("A bench with cut ash, a chisel on the rail and a curl of shavings")
                    Text("A bare bench")
                        .brandFont(.largeTitle)
                        .foregroundStyle(.brandInk)
                    Text("There is ash cut to length and a chisel on the rail. Say what the first stave is for.")
                        .brandFont(.body, weight: .regular)
                        .foregroundStyle(.brandInkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Button("Lay a stave on the bench") { showLay = true }
                        .brandProminent()
                        .padding(.top, 6)
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 24)
            }
        }
    }

    private var bench: some View {
        VStack(spacing: 0) {
            BenchEdge()
            List {
                ForEach(Array(counters.enumerated()), id: \.element.id) { index, counter in
                    StaveRow(counter: counter, index: index, onCut: { cut(counter) })
                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: -8, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .popIn(delay: Double(index) * 0.05)
                }
                .onDelete(perform: plane)

                if !store.isProUnlocked && counters.count >= AppInfo.freeStaveLimit {
                    blank
                        .listRowInsets(EdgeInsets(top: 10, leading: 20, bottom: 14, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .benchBackground()

            rack
        }
    }

    /// The rack behind the bench: every stave anybody has scored, whatever it was for, oldest
    /// at the back. It arrives at one stave and cannot be bought, so on a first bench there is
    /// nothing here and the boards have the screen to themselves.
    @ViewBuilder
    private var rack: some View {
        let scored = counters.flatMap { counter in
            Record.scoredDates(for: counter).map {
                RackRail.Scored(date: $0, pigment: counter.pigment.color)
            }
        }.sorted { $0.date < $1.date }

        if !scored.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text("Kept \(daysKept) days · \(scored.count) in the rack")
                    .stencilCaps()
                    .foregroundStyle(.brandInkSoft)
                RackRail(staves: scored,
                         oiled: Bench.earned.isUnlocked("oil", at: scored.count))
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    /// Distinct days with a cut on any stave — the rung the whole ladder is keyed on.
    private var daysKept: Int {
        let calendar = Calendar.current
        let days = counters.flatMap { $0.entries }.filter { $0.delta > 0 }
            .map { calendar.startOfDay(for: $0.at) }
        return Set(days).count
    }

    /// Not a lock row: the fourth position on the bench is an uncut, unpainted blank.
    private var blank: some View {
        Button { showPaywall = true } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .strokeBorder(.brandInk.opacity(0.22), style: StrokeStyle(lineWidth: 1.2, dash: [5, 4]))
                Text("Three staves on the bench — the rack holds more")
                    .stencilCaps()
                    .foregroundStyle(.brandInkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .frame(height: 62)
            .rotationEffect(.degrees(1.1))
        }
        .buttonStyle(.pressable(scale: 0.98))
    }

    private func layTapped() {
        if store.isProUnlocked || counters.count < AppInfo.freeStaveLimit {
            showLay = true
        } else {
            showPaywall = true
        }
    }

    private func cut(_ counter: Counter) {
        Haptics.rigid()
        let before = counter.entries.reduce(0) { $0 + max(0, $1.delta) }
        Tones.shared.play(.step(before % notchesPerGate))
        context.insert(Tap(delta: 1, counter: counter))
        try? context.save()
        // The gate closes on the fifth: a small reward inside the loop, so a sitting has a
        // shape you can hear before you see it.
        if (before + 1) % notchesPerGate == 0 {
            Haptics.soft()
            Tones.shared.play(.pop)
        }
    }

    private func plane(_ offsets: IndexSet) {
        for index in offsets { context.delete(counters[index]) }
        try? context.save()
    }

    private func applyLaunchOptions() {
        // The demo flags come first: a `-demo` launch carries no `-screen`, and guarding on
        // one meant the app played its signature interaction on a screen it never opened.
        if LaunchOptions.demo != nil || LaunchOptions.screen == "face" || LaunchOptions.screen == "win" {
            if let first = counters.first, path.isEmpty { path = [first] }
            return
        }
        if LaunchOptions.screen == "lay" { showLay = true }
    }
}

/// One stave on the bench: the pigment band, the name burned in, the running total, the last
/// two gates cut live along the shoulder, and the chisel at the right end.
///
/// The link and the chisel are siblings, not one nested in the other. A `Button` inside a
/// `NavigationLink` label is ambiguous about which one a tap belongs to, and the whole point
/// of this screen is that cutting does not navigate anywhere.
struct StaveRow: View {
    let counter: Counter
    let index: Int
    let onCut: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var cuts = 0
    @State private var growth: CGFloat = 1
    @State private var box = RecordBox()

    /// Hashed from the counter's name, never random per frame, or the pile would jitter on
    /// every redraw.
    private var tilt: Double {
        var rng = Seeded(seed: counter.name.benchHash)
        return -1.4 + rng.unit() * 3.0
    }

    private var record: Record { box.record(for: counter) }

    /// The last two gates, taken from a gate boundary so the fives still read as fives.
    private var window: [Mark] {
        let full = record.currentStave
        guard !full.isEmpty else { return [] }
        let start = max(0, ((full.count - 1) / notchesPerGate) * notchesPerGate - notchesPerGate)
        return Array(full[start...])
    }

    var body: some View {
        StaveBoard(pigment: counter.pigment.color,
                   oiled: Bench.earned.isUnlocked("oil", at: record.stavesScored)) {
            Group {
                if typeSize.isAccessibilitySize { stacked } else { sideBySide }
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .leading)
        }
        .rotationEffect(.degrees(tilt))
        // Overlapping, so they read as a pile of work on a bench rather than as rows.
        .padding(.vertical, 1)
        .confetti(trigger: cuts,
                  colors: [Color(hex: 0xEDE1C6), Color(hex: 0xF6EFDC), Color(hex: 0x6A4A2A)],
                  from: UnitPoint(x: 0.86, y: 0.3), count: 7, power: 0.22)
    }

    private var sideBySide: some View {
        ZStack(alignment: .topLeading) {
            StaveMarks(marks: window, capacity: notchesPerGate * 2, notchDepth: 14,
                       openingGrowth: growth, gateWidth: 36)
                .padding(.leading, 24)
                .padding(.trailing, 78)
                .padding(.top, 8)

            HStack(alignment: .bottom, spacing: 10) {
                NavigationLink(value: counter) {
                    HStack(alignment: .bottom, spacing: 10) {
                        Text(counter.name.uppercased())
                            .brandFont(.title3)
                            .foregroundStyle(.brandInk.opacity(0.55))
                            .lineLimit(2)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 6)
                        total
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityHint("Opens the stave")

                chisel
            }
            .padding(.leading, 24)
            .padding(.trailing, 12)
            .padding(.bottom, 10)
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    private var stacked: some View {
        VStack(alignment: .leading, spacing: 12) {
            NavigationLink(value: counter) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(counter.name.uppercased())
                        .brandFont(.title3)
                        .foregroundStyle(.brandInk.opacity(0.6))
                        .fixedSize(horizontal: false, vertical: true)
                    total
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityHint("Opens the stave")

            chisel
                .frame(maxWidth: .infinity, minHeight: 56)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
    }

    private var total: some View {
        Text("\(record.total)")
            .brandDisplay(size: 44, relativeTo: .title)
            .monospacedDigit()
            .contentTransition(.numericText())
            .foregroundStyle(.brandInk)
            // A wrapped number is a different number. Shrink it rather than break it.
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .accessibilityLabel("\(record.total)")
    }

    private var chisel: some View {
        Button {
            onCut()
            growth = 0
            withMotion(.spring(response: 0.16, dampingFraction: 0.74)) { growth = 1 }
            cuts += 1
        } label: {
            ChiselGlyph(height: 66)
                .frame(width: 46, height: 66)
                .contentShape(Rectangle())
        }
        .buttonStyle(.pressable(scale: 0.98, haptic: false))
        .accessibilityLabel("Cut a notch")
        .accessibilityHint("Cuts a notch into \(counter.name)")
    }
}
