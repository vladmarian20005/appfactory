import FactoryKit
import SwiftData
import SwiftUI

/// The board. Tap a tube, tap where it should go.
struct PlayView: View {
    @EnvironmentObject private var model: GameModel
    @EnvironmentObject private var store: Store
    @Environment(\.modelContext) private var context

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
            instruction
            if model.isDealing {
                dealing
            } else {
                BoardView(board: model.board,
                          style: style,
                          selection: model.selection,
                          hint: model.hint) { model.tap($0) }
                    .padding(.horizontal, FactoryTheme.padding)
                    .padding(.vertical, 8)
            }
            controls
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(model.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(get: { model.pendingResult }, set: { model.pendingResult = $0 })) { result in
            LevelClearedView(result: result,
                             onNext: { advance(from: result) },
                             onReplay: {
                                 model.pendingResult = nil
                                 model.open(result.levelID, force: true)
                             })
                .presentationDetents([.medium])
                .onAppear { record(result) }
        }
        .onAppear(perform: openInitialLevel)
    }

    // MARK: - Pieces

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            if style.calm {
                Label("Calm mode", systemImage: "leaf.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Text("\(model.moves) moves")
                    .font(.headline)
                    .monospacedDigit()
                Text("par \(model.par)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            Spacer()
            Label("Solution verified", systemImage: "checkmark.seal.fill")
                .font(.caption)
                .foregroundStyle(Color.accentColor)
                .accessibilityLabel("This level was solved before it was handed to you.")
        }
        .padding(.horizontal, FactoryTheme.padding)
        .padding(.top, 4)
    }

    /// One line under the header, only until the first pour.
    @ViewBuilder
    private var instruction: some View {
        if let hint = model.hint {
            Label("Pour the \(hintColorName(hint)) out of the tube marked up, into the one marked down — the next move of the solution Tidepour already checked.",
                  systemImage: "lightbulb.fill")
                .font(.footnote)
                .foregroundStyle(Color.accentColor)
                .padding(.horizontal, FactoryTheme.padding)
                .padding(.top, 2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else if model.moves == 0 && !model.isDealing {
            Text("Tap a tube, then tap the one to pour it into.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, FactoryTheme.padding)
                .padding(.top, 2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    /// Deliberately still: dealing takes a moment on the widest boards, and a spinner that
    /// never settles is what the capture tooling photographs.
    private var dealing: some View {
        VStack(spacing: 10) {
            Image(systemName: "drop.fill")
                .foregroundStyle(Color.accentColor)
                .scaledFont(size: 40, relativeTo: .title)
            Text("Dealing a board")
                .font(.headline)
            Text("Tidepour is solving this one before it hands it to you.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(FactoryTheme.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func hintColorName(_ hint: Move) -> String {
        guard hint.from < model.board.tubes.count,
              let color = model.board.tubes[hint.from].last else { return "liquid" }
        return style.name(color)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button {
                model.undo()
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .frame(maxWidth: .infinity)
            }
            .disabled(!model.canUndo)

            Button {
                model.requestHint()
            } label: {
                Label(model.isThinking ? "Solving" : "Hint", systemImage: "lightbulb.fill")
                    .frame(maxWidth: .infinity)
            }
            .disabled(model.isSolved || model.isDealing)

            Button {
                model.restart()
            } label: {
                Label("Restart", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .disabled(model.moves == 0)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .labelStyle(.titleAndIcon)
        .padding(FactoryTheme.padding)
    }

    // MARK: - Flow

    private func openInitialLevel() {
        if let target = initialLevelID {
            model.open(target)
        }
        if let count = LaunchOptions.autoMoves {
            // The board may still be dealing; play once it is there.
            Task {
                for _ in 0..<40 where model.isDealing {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                model.autoPlay(count)
                if LaunchOptions.hint { model.requestHint() }
            }
        } else if LaunchOptions.hint {
            Task {
                for _ in 0..<40 where model.isDealing {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
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

/// What comes up when the last tube separates: the score against par, and the way on.
struct LevelClearedView: View {
    let result: GameModel.FinishedLevel
    let onNext: () -> Void
    let onReplay: () -> Void

    private var verdict: String {
        if result.moves < result.par { return "Under par. That is the shortest route beaten." }
        if result.moves == result.par { return "Exactly par — the shortest solution there is." }
        return "Par is \(result.par). Every level has one, and it is always reachable."
    }

    var body: some View {
        VStack(spacing: 18) {
            Image(systemName: "checkmark.seal.fill")
                .foregroundStyle(Color.accentColor)
                .scaledFont(size: 48, relativeTo: .largeTitle)
            VStack(spacing: 6) {
                Text(result.levelID.isDaily ? "Daily puzzle cleared" : "Level cleared")
                    .font(.title2.bold())
                Text("\(result.moves) moves")
                    .font(.title3)
                    .monospacedDigit()
                Text(verdict)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            VStack(spacing: 10) {
                Button(result.levelID.isDaily ? "Back to the ladder" : "Next level", action: onNext)
                    .buttonStyle(.factoryPrimary)
                Button("Play it again", action: onReplay)
                    .font(.subheadline)
            }
        }
        .padding(FactoryTheme.padding)
        .frame(maxWidth: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}
