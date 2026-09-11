import FactoryKit
import SwiftData
import SwiftUI

/// The rack on the flat. Pick a vial up, tip it into another.
struct PlayView: View {
    @EnvironmentObject private var model: GameModel
    @EnvironmentObject private var store: Store
    @Environment(\.modelContext) private var context
    @Environment(\.brand) private var brand

    @Binding var showPaywall: Bool

    @AppStorage("tidepour.calmMode") private var calmMode = false
    @AppStorage("tidepour.accessiblePalette") private var accessiblePalette = false
    @AppStorage("tidepour.shapeMarkers") private var shapeMarkers = false
    @AppStorage("tidepour.currentLevel") private var currentLevel = 1
    @AppStorage("tidepour.highestCleared") private var highestCleared = 0

    private var style: BoardStyle {
        BoardStyle(accessiblePalette: accessiblePalette && store.isUnlocked,
                   calm: calmMode && store.isUnlocked,
                   markers: shapeMarkers && store.isUnlocked)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if model.isDealing {
                dealing
            } else {
                BoardView(board: model.board,
                          style: style,
                          selection: model.selection,
                          hint: model.hint,
                          flight: model.flight,
                          stream: model.stream,
                          rise: model.rise,
                          teaching: model.teaching,
                          completions: model.completions,
                          completedTube: model.completedTube,
                          refusedTube: model.refusedTube,
                          refusals: model.refusals) { model.tap($0) }
                    .padding(.horizontal, FactoryTheme.padding)
                    .padding(.top, 24)
                    .padding(.bottom, 10)
                    .frame(minHeight: 240)
                    .layoutPriority(1)
            }
            controls
        }
        .brandBackground(drift: true)
        .navigationTitle(model.title)
        .navigationBarTitleDisplayMode(.inline)
        // Deep water in both appearances, so the bar carries light content in both. Left to
        // itself the title draws near-black over the pool.
        .toolbarColorScheme(.dark, for: .navigationBar)
        .fullScreenCover(item: Binding(get: { model.pendingResult },
                                       set: { model.pendingResult = $0 })) { result in
            LevelClearedView(result: result,
                             board: model.board,
                             style: style,
                             streak: streak,
                             onNext: { advance(from: result) },
                             onReplay: {
                                 model.pendingResult = nil
                                 model.open(result.levelID, force: true)
                             })
                .brand(AppBrand.brand)
                .onAppear { record(result) }
        }
        .onAppear(perform: start)
        .onChange(of: style) { _, new in model.timing = new }
    }

    // MARK: - The chart marks at the top

    /// The count poured, the line to beat, and the badge that says this board was walked
    /// before it was handed over. Side by side while they fit, stacked when the text size
    /// says they do not.
    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 12) {
                    counter
                    Spacer(minLength: 8)
                    verifiedBadge
                }
                VStack(alignment: .leading, spacing: 6) {
                    counter
                    verifiedBadge
                }
            }
            if !style.calm {
                PourRail(moves: model.moves, par: model.par)
                    .frame(height: 3)
                HStack {
                    charted
                    Spacer(minLength: 8)
                    ChartMark(text: "The line · \(model.par)", color: brand.palette.highlight)
                }
            }
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, FactoryTheme.padding)
        .padding(.top, 2)
    }

    @ViewBuilder
    private var counter: some View {
        if style.calm {
            Label("Calm", systemImage: "leaf.fill")
                .brandFont(.title2)
                .foregroundStyle(brand.palette.success)
        } else {
            Text("\(model.moves)")
                .brandDisplay(size: 64, relativeTo: .largeTitle)
                .monospacedDigit()
                .foregroundStyle(brand.palette.ink)
                .lineLimit(1)
                .contentTransition(.numericText(value: Double(model.moves)))
                .accessibilityLabel("\(model.moves) poured, the line is \(model.par)")
        }
    }

    private var verifiedBadge: some View {
        Label("Charted", systemImage: "checkmark.seal.fill")
            .font(.caption)
            .foregroundStyle(brand.palette.accent)
            .lineLimit(1)
            .accessibilityLabel("This level was solved before it was handed to you.")
    }

    /// The left-hand chart mark under the rail. It becomes the charted line while the hint is
    /// armed — no sentence anywhere: the arrows on the vials say which way it pours.
    @ViewBuilder
    private var charted: some View {
        if model.hint != nil {
            HStack(spacing: 5) {
                Image(systemName: "point.topleft.down.to.point.bottomright.curvepath")
                    .font(.caption2)
                Text("the charted line")
                    .brandFont(.caption, weight: .semibold)
                    .italic()
            }
            .foregroundStyle(brand.palette.accent)
            .lineLimit(1)
            .transition(.opacity)
        } else {
            ChartMark(text: "Poured")
        }
    }

    /// Deliberately quiet: dealing takes a moment on the widest racks, because the board is
    /// solved before it is served.
    private var dealing: some View {
        VStack(spacing: 14) {
            Image("LowTide")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 210)
                .opacity(0.9)
            Text(Voice.line(from: Voice.waiting, key: "waiting"))
                .brandFont(.title3)
                .foregroundStyle(brand.palette.inkSoft)
                .multilineTextAlignment(.center)
        }
        .padding(FactoryTheme.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel("Setting the rack.")
    }

    private var controls: some View {
        HStack(spacing: 12) {
            ControlButton(title: "Back", symbol: "arrow.uturn.backward", action: model.undo)
                .disabled(!model.canUndo)
            ControlButton(title: model.isThinking ? "Solving" : "Show me",
                          symbol: "lightbulb.fill",
                          action: model.requestHint)
                .disabled(model.isSolved || model.isDealing)
            ControlButton(title: "Refill", symbol: "arrow.counterclockwise", action: model.restart)
                .disabled(model.moves == 0)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .tint(brand.palette.accent)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .padding(FactoryTheme.padding)
    }

    // MARK: - Flow

    private var streak: Int {
        let played = Set((try? context.fetch(FetchDescriptor<LevelResult>()))?.map(\.dayKey) ?? [])
        return Streaks.current(days: played)
    }

    private func start() {
        model.timing = style
        Tones.shared.warmUp()
        openInitialLevel()
    }

    private func openInitialLevel() {
        if let target = initialLevelID {
            model.open(target)
        }
        if let moment = LaunchOptions.demo {
            model.playDemo(moment)
            return
        }
        if LaunchOptions.won {
            // Straight to the finished rack. Under -stillFrames the whole solution resolves
            // in one frame, so the capture is the win rather than the road to it.
            Task {
                await model.waitForBoard()
                model.autoPlay(model.solutionLength, gap: 0.02)
            }
            return
        }
        if let count = LaunchOptions.autoMoves {
            // The board may still be dealing; play once it is there.
            Task {
                await model.waitForBoard()
                model.autoPlay(count)
                if LaunchOptions.hint { model.requestHint() }
            }
        } else if LaunchOptions.hint {
            Task {
                await model.waitForBoard()
                model.requestHint()
            }
        }
    }

    private var initialLevelID: LevelID? {
        if LaunchOptions.daily { return .daily(DayKey.key()) }
        if let n = LaunchOptions.level { return .numbered(n) }
        if model.levelID != nil { return nil }
        return .numbered(max(1, currentLevel))
    }

    private func record(_ result: GameModel.FinishedLevel) {
        let key = LevelResult.key(for: result.levelID)
        let existing = try? context.fetch(
            FetchDescriptor<LevelResult>(predicate: #Predicate { $0.key == key })
        )
        if let previous = existing?.first {
            if result.moves < previous.moves { previous.moves = result.moves }
            previous.clearedAt = .now
        } else {
            context.insert(LevelResult(key: key,
                                       number: result.levelID.number,
                                       dayKey: result.dayKey,
                                       moves: result.moves,
                                       par: result.par))
        }
        if let n = result.levelID.number {
            highestCleared = max(highestCleared, n)
            currentLevel = max(currentLevel, n)
        }
        try? context.save()
    }

    private func advance(from result: GameModel.FinishedLevel) {
        model.pendingResult = nil
        guard let n = result.levelID.number else {
            model.open(.numbered(max(1, currentLevel)))
            return
        }
        let next = n + 1
        if next > AppInfo.freeLevelCount && !store.isUnlocked {
            showPaywall = true
            return
        }
        currentLevel = next
        model.open(.numbered(next))
    }
}

/// Start to the line: how far along the charted line this board is, and how far past it.
struct PourRail: View {
    let moves: Int
    let par: Int

    @Environment(\.brand) private var brand

    private var progress: Double {
        guard par > 0 else { return 0 }
        return min(1.2, Double(moves) / Double(par))
    }

    var body: some View {
        GeometryReader { geo in
            let full = geo.size.width
            let line = full * 0.86
            ZStack(alignment: .leading) {
                Capsule().fill(brand.palette.ink.opacity(0.14))
                Capsule()
                    .fill(moves > par ? brand.palette.miss : brand.palette.accent)
                    .frame(width: min(full, line * progress))
                // The line itself: a lantern tick at par, which is where the charted route ends.
                Capsule()
                    .fill(brand.palette.highlight)
                    .frame(width: 2, height: 9)
                    .offset(x: line - 1, y: -3)
                Circle()
                    .fill(moves > par ? brand.palette.miss : brand.palette.accent)
                    .frame(width: 9, height: 9)
                    .shadow(color: brand.palette.accent.opacity(0.7), radius: 6)
                    .offset(x: min(full - 9, max(0, line * progress - 4.5)), y: -3)
            }
        }
        .animation(Motion.resolved(Motion.bouncy), value: moves)
        .accessibilityHidden(true)
    }
}

/// Back, Show me and Refill. Three words do not fit across a phone at an accessibility text
/// size, so past that size the button keeps the symbol and hands the word to VoiceOver.
struct ControlButton: View {
    let title: String
    let symbol: String
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Button(action: action) {
            Group {
                if typeSize.isAccessibilitySize {
                    Image(systemName: symbol)
                } else {
                    Label(title, systemImage: symbol)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .accessibilityLabel(title)
    }
}
