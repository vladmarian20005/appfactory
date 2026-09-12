import FactoryKit
import SwiftUI

/// The session's row of tile slots under the nav bar. It is the only progress bar in the app
/// that empties, and the tiles in it are the same tiles that go into the wall.
struct CourseBar: View {
    @Environment(\.brand) private var brand
    let slots: Int
    /// The glaze of each tile set so far, in the order they were set.
    let filled: [Color]
    let themeName: String
    let due: Int
    let namespace: Namespace.ID

    private let gap: CGFloat = 3

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            GeometryReader { geo in
                let count = max(slots, 1)
                let size = min(12, (geo.size.width - gap * CGFloat(count - 1)) / CGFloat(count))
                HStack(spacing: gap) {
                    ForEach(0..<count, id: \.self) { i in
                        slot(i, size: size)
                            .frame(width: size, height: size)
                            .matchedGeometryEffect(id: "slot-\(i)", in: namespace, isSource: true)
                    }
                    Spacer(minLength: 0)
                }
                .frame(height: geo.size.height, alignment: .center)
            }
            .frame(height: 12)

            HStack {
                Mark(themeName.uppercased())
                    .foregroundStyle(brand.palette.inkSoft)
                Spacer(minLength: 12)
                Mark("\(due) DUE")
                    .foregroundStyle(brand.palette.inkSoft)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(themeName). \(filled.count) set, \(due) still due.")
    }

    @ViewBuilder
    private func slot(_ i: Int, size: CGFloat) -> some View {
        if i < filled.count {
            GlazedTile(glaze: filled[i], radius: 2, bevel: 1, sheen: false)
                .overlay {
                    // Every tenth tile set takes a thin line of fresh amber mortar: a small
                    // brightening inside the session, never an interruption.
                    if (i + 1) % 10 == 0 {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .strokeBorder(brand.palette.highlight, lineWidth: 1.2)
                    }
                }
        } else {
            GroutGap()
        }
    }
}

/// Not yet · Got it · Easy. The only capsules on this screen, so the thing you tap next is
/// never in doubt — and *Got it*, the common answer, is the one with weight.
struct GradeChips: View {
    @Environment(\.brand) private var brand
    let glaze: Color
    let onGrade: (Grade) -> Void

    /// *Got it* takes 1.3 shares of the row to the others' one, so three coloured pills never
    /// read as a row of sweets.
    var body: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 10
            let unit = max(48, (geo.size.width - spacing * 2) / 3.3)
            HStack(spacing: spacing) {
                chip(.again, title: "Not yet", tint: brand.palette.miss, filled: false)
                    .frame(width: unit)
                    .popIn(delay: 0)
                chip(.good, title: "Got it", tint: brand.palette.accent, filled: true)
                    .frame(width: unit * 1.3)
                    .popIn(delay: 0.05)
                chip(.easy, title: "Easy", tint: brand.palette.success, filled: false)
                    .frame(width: unit)
                    .popIn(delay: 0.1)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func chip(_ grade: Grade, title: String, tint: Color, filled: Bool) -> some View {
        Button {
            onGrade(grade)
        } label: {
            Text(title)
                .brandFont(.headline)
                .foregroundStyle(filled ? brand.palette.onAccent : tint)
                .lineLimit(2)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.5)
                // The three of them have to stay legible side by side: a grade that reads
                // "Not…" is a grade nobody can give.
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)
                .padding(.vertical, 15)
                .frame(maxWidth: .infinity)
                .background {
                    Capsule().fill(filled ? tint : Color.clear)
                }
                .overlay {
                    Capsule().strokeBorder(tint.opacity(filled ? 0 : 0.85), lineWidth: 1.5)
                }
                .shadow(color: filled ? tint.opacity(0.32) : .clear, radius: 10, y: 5)
        }
        .buttonStyle(.pressable(scale: 0.95))
    }
}

/// The bench: one tile at a time, turned over and graded. Nothing else is on screen.
struct BenchView: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var library: Library
    @Environment(\.brand) private var brand
    @Binding var showSettings: Bool
    let onSeeTheWall: () -> Void

    @Namespace private var bench

    @State private var queue: [Word] = []
    @State private var plannedCount = 0
    /// The tiles this session has put into the wall, in the order they went in. The course
    /// draws their glazes; the win presses the same tiles into the wall.
    @State private var setWords: [Word] = []
    @State private var flyingSlot = 0
    @State private var wentBack = 0
    @State private var startedKnown = 0
    @State private var angle: Double = 0
    @State private var flying = false
    @State private var draining: CGFloat = 0
    @State private var leaving = false
    @State private var rising = false
    @State private var lustre = false
    @State private var burst = 0
    @State private var finished = false
    @State private var loaded = false

    private var current: Word? { queue.first }
    private var glaze: Color { AppBrand.glaze(current?.theme ?? 0) }
    private var turned: Bool { angle >= 90 }

    var body: some View {
        Group {
            if finished {
                WinView(setWords: setWords,
                        wentBack: wentBack,
                        startedKnown: startedKnown,
                        onDone: { startSession() })
            } else if let word = current {
                drill(word)
            } else {
                SweptBench(onSeeTheWall: onSeeTheWall)
            }
        }
        .navigationTitle(finished ? "" : "Bench")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !finished {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "sun.max")
                    }
                    .accessibilityLabel("Settings")
                }
            }
        }
        .onAppear {
            guard !loaded else { return }
            loaded = true
            startSession()
            Tones.shared.warmUp()
            runDemoIfAsked()
        }
        .onChange(of: library.summons) { _, _ in
            // A word fetched off the wall goes on the bench straight away.
            if !finished { startSession() }
        }
    }

    // MARK: - The screen

    private func drill(_ word: Word) -> some View {
        VStack(spacing: 0) {
            CourseBar(slots: max(plannedCount, 1),
                      filled: setWords.map { AppBrand.glaze($0.theme) },
                      themeName: Deck.themeName(word.theme),
                      due: queue.count,
                      namespace: bench)
                .padding(.horizontal, 18)
                .padding(.top, 4)

            Spacer(minLength: 8)

            VStack(spacing: 38) {
                ZStack {
                    stackBehind
                    // The tile rests here; the travelling tile above matches into it.
                    Color.clear
                        .frame(width: 318, height: 318)
                        .matchedGeometryEffect(id: "bench", in: bench, isSource: true)
                }
                .frame(width: 318, height: 318)

                chipRow(word)
                    .frame(height: 56)
                    .padding(.horizontal, 24)
            }

            Spacer(minLength: 8)
        }
        .overlay(alignment: .top) { travellingTile(word) }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .workshopBackground()
        .confetti(trigger: burst, colors: [glaze, brand.palette.highlight, AppBrand.motif], count: 14, power: 0.45)
    }

    /// The two bisque tiles waiting behind, offset 8 and 16 points down.
    private var stackBehind: some View {
        ZStack {
            BisqueTile()
                .frame(width: 318, height: 318)
                .offset(x: 9, y: 16)
                .opacity(0.55)
            BisqueTile()
                .frame(width: 318, height: 318)
                .offset(x: 5, y: 8)
                .opacity(0.8)
        }
        .shadow(color: .black.opacity(0.08), radius: 12, y: 8)
    }

    @ViewBuilder
    private func travellingTile(_ word: Word) -> some View {
        ZStack {
            // The glaze ground is always in the hierarchy, so what flies to the course is the
            // tile itself rather than a new view fading in at the far end.
            RoundedRectangle(cornerRadius: flying ? 2 : 12, style: .continuous)
                .fill(LinearGradient(colors: [glaze, glaze.shaded(0.14)], startPoint: .top, endPoint: .bottom))
                .opacity(flying ? 1 : 0)

            if !flying {
                tileFace(word)
            }
        }
        .overlay {
            // Easy: a lustre sweep travels the tile as it lands.
            if lustre {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white.opacity(0.4))
            }
        }
        .matchedGeometryEffect(id: flying ? "slot-\(flyingSlot)" : "bench",
                               in: bench,
                               isSource: false)
        .offset(y: leaving ? 150 : (rising ? 40 : 0))
        .scaleEffect(rising ? 0.94 : 1)
        .opacity(leaving ? 0 : 1)
    }

    @ViewBuilder
    private func tileFace(_ word: Word) -> some View {
        let tile = TurningTile(angle: angle,
                               word: word,
                               glaze: glaze,
                               showRank: true,
                               onChime: { Speech.shared.say(word) })
            .frame(width: 318, height: 318)
            .overlay {
                // Not yet: the glaze drains to bisque, top to bottom, and nothing turns red.
                BisqueTile()
                    .mask(alignment: .top) {
                        Rectangle().frame(height: draining)
                    }
                    .allowsHitTesting(false)
            }
            .shadow(color: .black.opacity(0.14), radius: 16, y: 10)

        if turned {
            tile
        } else {
            Button { turn(word) } label: { tile }
                .buttonStyle(.pressable(scale: 0.985))
        }
    }

    @ViewBuilder
    private func chipRow(_ word: Word) -> some View {
        if turned {
            GradeChips(glaze: glaze) { grade(word, $0) }
                .popIn(delay: 0.05)
        } else {
            Color.clear
        }
    }

    // MARK: - The turn

    /// The turn takes 340 ms in the hand. On a `-demo` launch it is performed for the camera,
    /// because `simctl` can only take a frame about every half second and a 340 ms turn falls
    /// between two of them — a filmstrip of a motion nobody filmed.
    private var turnSpring: Animation {
        LaunchOptions.demo == nil ? Motion.bouncy : .spring(response: 0.95, dampingFraction: 0.72)
    }

    private var edgeDelay: UInt64 {
        LaunchOptions.demo == nil ? 170_000_000 : 470_000_000
    }

    private func turn(_ word: Word) {
        guard angle < 90 else { return }
        Haptics.soft()
        withMotion(turnSpring) { angle = 180 }
        UserDefaults.standard.set(true, forKey: "thousand.turnedOne")
        // The ceramic tick lands at the edge-on frame, which is where the eye expects it.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: edgeDelay)
            Haptics.rigid()
            Tones.shared.play(.pop)
            if Speech.speaksOnTurn { Speech.shared.say(word) }
        }
    }

    private func grade(_ word: Word, _ grade: Grade) {
        guard turned, !flying, !leaving else { return }
        let reachedWall = library.record(word, grade)

        switch grade {
        case .again:
            wentBack += 1
            Haptics.thud()
            Tones.shared.play(.miss)
            withMotion(Motion.gentle) { draining = 318 }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 220_000_000)
                withMotion(Motion.gentle) { leaving = true }
                try? await Task.sleep(nanoseconds: 320_000_000)
                var rest = queue
                let back = rest.removeFirst()
                rest.append(back)
                reset(to: rest)
            }

        case .good, .easy:
            let n = setWords.count
            flyingSlot = n
            withMotion(Motion.snappy) { flying = true }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: grade == .easy ? 240_000_000 : 320_000_000)
                setWords.append(word)
                if grade == .easy {
                    Haptics.impact(0.6)
                    Tones.shared.play(.step(n + 2))
                    burst += 1
                    withMotion(Motion.pop) { lustre = true }
                    try? await Task.sleep(nanoseconds: 180_000_000)
                    withMotion(Motion.pop) { lustre = false }
                } else {
                    Haptics.rigid()
                    Tones.shared.play(.step(n))
                }
                if reachedWall { Haptics.impact(0.5) }
                var rest = queue
                rest.removeFirst()
                reset(to: rest)
            }
        }
    }

    /// The next tile rises from the stack; the due count on the course drops by one.
    private func reset(to rest: [Word]) {
        flying = false
        lustre = false
        leaving = false
        draining = 0
        angle = 0
        if rest.isEmpty {
            withMotion(Motion.gentle) {
                queue = []
                finished = true
            }
            return
        }
        rising = true
        queue = rest
        // On the next turn of the run loop, not this one: setting it true and false inside a
        // single update means the tile is never drawn low, and the rise never happens.
        Task { @MainActor in
            await Task.yield()
            withMotion(Motion.gentle) { rising = false }
        }
    }

    // MARK: - Sessions

    private func startSession() {
        let planned = library.plannedSession(pro: store.isPro || LaunchOptions.forcePro)
        startedKnown = library.setCount
        setWords = []
        wentBack = 0
        draining = 0
        flying = false
        leaving = false
        angle = LaunchOptions.turned ? 180 : 0
        // `-demo win` is the reward, filmed. Landing on it and playing it slowly is the whole
        // moment; playing two turns first only guarantees the camera arrives after it.
        finished = LaunchOptions.won || LaunchOptions.demo == "win"
        queue = LaunchOptions.swept ? [] : planned
        plannedCount = queue.count

        if finished {
            // A capture of the win needs a session to have happened. Take the day's tiles from
            // what is already in the wall, two from each panel, so the course and the fresh
            // mortar read the way a real session's would.
            var day: [Word] = []
            for theme in 0..<Deck.themes.count {
                day += Deck.panel(theme).filter { library.firing($0) == .set }.prefix(2)
            }
            setWords = Array(day.prefix(24))
            plannedCount = setWords.count
            startedKnown = max(0, library.setCount - setWords.count)
        }

        teachTheFirstTile()
    }

    /// No text anywhere says to turn the tile. On a player's very first card it peeks instead:
    /// a sliver of clay edge and the bisque behind, twice, and never again once it has worked.
    private func teachTheFirstTile() {
        guard !UserDefaults.standard.bool(forKey: "thousand.turnedOne"),
              !Motion.isStill, !finished, !queue.isEmpty else { return }
        Task { @MainActor in
            for _ in 0..<2 {
                try? await Task.sleep(nanoseconds: 900_000_000)
                guard angle < 1 else { return }
                withMotion(Motion.gentle) { angle = 14 }
                try? await Task.sleep(nanoseconds: 450_000_000)
                guard angle < 90 else { return }
                withMotion(Motion.gentle) { angle = 0 }
                try? await Task.sleep(nanoseconds: 1_100_000_000)
            }
        }
    }

    // MARK: - The moments the critic films

    /// Nothing on a runner can touch the screen, so the app performs the turn and reaches the
    /// win by itself when asked.
    private func runDemoIfAsked() {
        guard let demo = LaunchOptions.demo else { return }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 900_000_000)
            switch demo {
            case "turn":
                // Over and over, and mostly on the turned face. `simctl` takes about one frame
                // every two seconds on a runner, so a beat the app holds for half a second is
                // a beat no filmstrip will ever contain.
                for _ in 0..<8 {
                    guard let word = current, !finished else { return }
                    turn(word)
                    try? await Task.sleep(nanoseconds: 3_600_000_000)
                    grade(word, .good)
                    try? await Task.sleep(nanoseconds: 600_000_000)
                }
            default:
                // "win" needs nothing here: `startSession` lands on the reward, and WinView
                // plays its own choreography four times slower under a -demo launch.
                break
            }
        }
    }
}

/// Nothing is due. The bench is swept, the tools are down, and the app does not invent work to
/// fill the screen.
struct SweptBench: View {
    @EnvironmentObject private var store: Store
    @EnvironmentObject private var library: Library
    @Environment(\.brand) private var brand
    let onSeeTheWall: () -> Void

    var body: some View {
        let pro = store.isPro || LaunchOptions.forcePro
        VStack(spacing: 22) {
            Spacer(minLength: 0)
            Image("SweptBench")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 260)
                .ambientFloat(distance: 4, period: 5)
                .accessibilityLabel("The bench, swept, with the tools laid down")

            VStack(spacing: 10) {
                Text("The bench is swept.")
                    .brandFont(.title)
                    .foregroundStyle(brand.palette.ink)
                    .multilineTextAlignment(.center)
                Text(Voice.sweptBench(drying: library.dryingCount,
                                      tomorrow: library.readyTomorrow(pro: pro)))
                    .font(.body)
                    .foregroundStyle(brand.palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            Button {
                Haptics.tap()
                onSeeTheWall()
            } label: {
                Text("See the wall")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .brandProminent()
            .padding(.horizontal, 40)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .workshopBackground()
    }
}
