import FactoryKit
import SwiftData
import SwiftUI

/// Screen 1. The day's ten questions, the same ten for everyone, then the edition it prints.
struct TodayView: View {
    @Environment(\.brand) private var brand
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var desk: Desk
    @Query private var results: [DayResult]
    @Query private var reports: [QuestionReport]

    @State private var phase: Phase = .intro
    @State private var index = 0
    @State private var selected: Int?
    @State private var flags: [Bool] = []
    @State private var items: [QuizItem] = []
    @State private var voice = RoundVoice()
    @State private var stampLine = ""
    /// What is standing. A miss costs the chain and the clean sheet, and takes nothing else.
    @State private var run = Run()
    @State private var brokenChain = 0
    /// The ten the desk has set for today, held so the section line describes the real edition.
    @State private var setForToday: [QuizItem] = []

    private enum Phase { case intro, playing, done }

    private var today: Date { .now }
    private var todayKey: String { DayKey.key(for: today) }
    private var todayResult: DayResult? { results.first { $0.dayKey == todayKey } }
    private var streak: Int { Streaks.current(from: results) }
    private var editionNumber: Int { DailyPack.editionNumber(for: today) }
    /// Editions filed before today's: the rung the ladder is read at.
    private var filed: Int { results.filter { $0.dayKey != todayKey }.count }

    var body: some View {
        Group {
            switch phase {
            case .intro: intro
            case .playing: playing
            case .done: done
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: syncPhase)
    }

    // MARK: - The paper on the step

    private var intro: some View {
        // The page fills the screen so the ornament closes the column at its foot, the way a
        // short page of type does, instead of floating half way up.
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 18) {
                    Masthead(title: "Quizday", strapline: "A new edition every morning")
                        .popIn()

                    Text(dateline)
                        .dateline(11, tracking: 2)
                        .popIn(delay: 0.05)

                    Spacer(minLength: 0)

                    // The mock fills the sheet with the press; the build drew it at 250 and
                    // left a band of empty paper above the masthead rule and another under the
                    // subtitle. It is the hero of the first screen, so it takes the room.
                    HandPress(width: 310)
                        .padding(.vertical, 2)
                        .popIn(delay: 0.1)
                        .accessibilityLabel("A hand press, turning")

                    Text("Ten questions, set this morning.")
                        .brandFont(.title3, weight: .regular)
                        .italic()
                        .foregroundStyle(brand.palette.ink)
                        .popIn(delay: 0.15)

                    SectionLine(categories: DailyPack.categories(in: setForToday), shape: shapeLine)
                        .popIn(delay: 0.2)

                    if let line = Voice.streak(streak, todayPlayed: false) {
                        HStack {
                            Spacer(minLength: 0)
                            StreakRibbon(days: streak, numberSize: 34)
                        }
                        .popIn(delay: 0.25)
                        .accessibilityLabel(line)
                    }

                    Button {
                        Haptics.tap()
                        Tones.shared.play(.tap)
                        start()
                    } label: {
                        Text("Open today's edition").frame(maxWidth: .infinity)
                    }
                    .brandProminent()
                    .padding(.top, 2)
                    .popIn(delay: 0.3)

                    Spacer(minLength: 18)

                    PrintersOrnament()
                }
                .padding(.horizontal, 32)
                .padding(.top, 18)
                .padding(.bottom, 46)
                .frame(minHeight: geo.size.height)
            }
            .paper()
        }
        .onAppear { Tones.shared.warmUp() }
    }

    private var dateline: String {
        "\(Masthead.dateline(for: today)) · Round \(editionNumber)"
    }

    /// What this morning's paper is made of, from the ladder at the rung she has reached.
    private var shapeLine: String {
        Desk.difficulties(at: filed + 1, count: setForToday.isEmpty ? 10 : setForToday.count)
            .map { "\($0.1) \($0.0)" }
            .joined(separator: " · ")
    }

    // MARK: - The sheet

    @ViewBuilder
    private var playing: some View {
        if index < items.count {
            let item = items[index]
            QuestionSheet(
                item: item,
                position: index + 1,
                total: items.count,
                flags: flags,
                selected: selected,
                stampLine: stampLine,
                reported: reports.contains { $0.questionID == item.id },
                run: run,
                brokenChain: brokenChain,
                teaching: results.isEmpty && index == 0,
                onAnswer: { answer(item: item, choice: $0) },
                onReport: { report(item: item) },
                onNext: next
            )
        } else {
            ProgressView().paper()
        }
    }

    // MARK: - The edition

    private var done: some View {
        let result = todayResult
        let shownFlags = result?.flags ?? flags
        return EditionView(flags: shownFlags,
                           editionNumber: result?.roundNumber ?? editionNumber,
                           playedAt: result?.playedAt ?? .now,
                           streak: streak,
                           bestStreak: Streaks.best(from: results),
                           bestChain: Streaks.bestChain(from: results, excluding: todayKey),
                           filed: results.count)
            // Asked here, once the page has settled, never mid-question.
            .factoryReviewPrompt(afterSessions: 3)
    }

    // MARK: - Flow

    private func syncPhase() {
        // Set the day's ten before anything reads them: the section line on the unplayed sheet
        // is the edition's own sections, not a fixed round's.
        if setForToday.isEmpty { setForToday = desk.edition(for: today, filed: filed) }
        if let answered = LaunchOptions.answered, todayResult == nil {
            var sample = (0..<10).map { $0 < answered }
            SeededShuffle.apply(&sample, seed: UInt64(answered) &+ 3)
            save(flags: sample)
        }
        if LaunchOptions.autoPlay || LaunchOptions.demo == "answer" {
            if todayResult == nil {
                start()
                if let step = LaunchOptions.playStep {
                    for _ in 0..<max(0, step) {
                        guard index < items.count else { break }
                        answer(item: items[index], choice: items[index].correct)
                        next()
                    }
                }
                if LaunchOptions.reveal, index < items.count {
                    let item = items[index]
                    answer(item: item, choice: (item.correct + 1) % item.answers.count)
                }
                if LaunchOptions.demo == "answer" { playDemoAnswer() }
                return
            }
        }
        if LaunchOptions.demo == "win", todayResult == nil {
            playDemoWin()
            return
        }
        if todayResult != nil {
            phase = .done
        } else if phase == .playing, !items.isEmpty {
            // keep playing
        } else {
            phase = .intro
        }
    }

    /// `-demo answer`: nothing on a runner can touch the screen, so the app presses the ink
    /// itself. Two presses, spaced so a filmstrip catches them: question four answered right,
    /// the page turning, then question five answered wrong — the sweep, the stamp, the tally,
    /// and the pencil correction, in that order.
    ///
    /// The waits are long because `simctl io screenshot` costs about a third of a second, so a
    /// beat that is over in 0.55 s has to be given room either side of it to be filmed at all.
    /// The presses land at 6, 9 and 11.5 s against qa.json's `delay: 4.0`, so the 0–220 ms ink
    /// sweep falls in the middle of a frame rather than between two — before this the strip
    /// opened on flat white and then cut straight to a settled sheet.
    private func playDemoAnswer() {
        start()
        for _ in 0..<3 {
            guard index < items.count else { break }
            answer(item: items[index], choice: items[index].correct)
            next()
        }
        guard index < items.count else { return }
        let right = items[index]
        at(6.0) { answer(item: right, choice: right.correct) }
        at(9.0) { next() }
        at(11.5) {
            guard index < items.count else { return }
            let item = items[index]
            answer(item: item, choice: (item.correct + 1) % item.answers.count)
        }
    }

    /// `-demo win`: nine questions in, then the tenth pressed and the edition sent to press,
    /// so the film shows the round ending and the front page printing itself.
    private func playDemoWin() {
        start()
        guard !items.isEmpty else { return }
        // Eight right and one away with the tenth still to press: the tier, the tally and the
        // ribbon all have work to do when it lands.
        for position in 0..<(items.count - 1) {
            guard index < items.count else { break }
            let item = items[index]
            answer(item: item, choice: position == 3 ? (item.correct + 1) % item.answers.count : item.correct)
            next()
        }
        guard index < items.count else { return }
        let last = items[index]
        at(8.0) { answer(item: last, choice: last.correct) }
        // A long beat before the page goes to press: a screenshot of a screen that is
        // animating hard takes the best part of two seconds on a runner, so the film needs
        // the sheet, the press and the printing spread out or it catches only the ends. The
        // page prints at 12 s against `delay: 4.0`, which puts the burst at about 13.2 s —
        // inside the strip rather than after it.
        at(12.0) { next() }
    }

    private func at(_ seconds: Double, _ work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func start() {
        items = setForToday.isEmpty ? desk.edition(for: today, filed: filed) : setForToday
        guard !items.isEmpty else { return }
        setForToday = items
        index = 0
        selected = nil
        flags = []
        run = Run()
        brokenChain = 0
        voice = RoundVoice()
        phase = .playing
    }

    private func answer(item: QuizItem, choice: Int) {
        guard selected == nil else { return }
        selected = choice
        let correct = choice == item.correct
        stampLine = voice.line(correct: correct)
        flags.append(correct)
        // The chain is what she can lose. Hold what it was so the sheet can strike it out
        // rather than have it disappear between two frames.
        brokenChain = correct ? 0 : run.chain
        if correct { run.hit() } else { run.miss() }
        record(item: item, correct: correct)
    }

    private func next() {
        selected = nil
        brokenChain = 0
        if index + 1 < items.count {
            index += 1
        } else {
            desk.served(items)
            save(flags: flags)
            phase = .done
        }
    }

    private func save(flags: [Bool]) {
        guard results.first(where: { $0.dayKey == todayKey }) == nil else { return }
        context.insert(DayResult(dayKey: todayKey, roundNumber: editionNumber, flags: flags))
        try? context.save()
    }

    private func record(item: QuizItem, correct: Bool) {
        // The desk is the only thing that decides what she gets next, so every answer goes
        // through it. `CategoryStat` still accumulates for the league table next door.
        desk.record(item.id, correct: correct)
        record(category: item.category, correct: correct)
    }

    private func record(category: String, correct: Bool) {
        let descriptor = FetchDescriptor<CategoryStat>()
        let all = (try? context.fetch(descriptor)) ?? []
        if let stat = all.first(where: { $0.category == category }) {
            stat.asked += 1
            if correct { stat.correct += 1 }
        } else {
            context.insert(CategoryStat(category: category, asked: 1, correct: correct ? 1 : 0))
        }
        try? context.save()
    }

    private func report(item: QuizItem) {
        guard !reports.contains(where: { $0.questionID == item.id }) else { return }
        context.insert(QuestionReport(questionID: item.id, questionText: item.question))
        try? context.save()
    }
}

// MARK: - The press

/// The iron hand-press, with its flywheel turning on its own hub once every twenty seconds.
/// Still for the capture tooling and for Reduce Motion.
struct HandPress: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var width: CGFloat = 250

    /// press-body.svg is a 400 × 320 box and the axle the wheel turns on is at (330, 176).
    private var scale: CGFloat { width / 400 }

    var body: some View {
        let still = Motion.isStill || reduceMotion
        ZStack {
            Image("PressBody")
                .resizable()
                .scaledToFit()
                .frame(width: width)
            TimelineView(.animation(minimumInterval: 1.0 / 30, paused: still)) { context in
                let turns = still ? 0 : context.date.timeIntervalSinceReferenceDate / 20
                Image("PressWheel")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120 * scale)
                    .rotationEffect(.degrees(turns * 360))
                    .offset(x: (330 - 200) * scale, y: (176 - 160) * scale)
            }
        }
        .frame(width: width, height: 320 * scale)
        .accessibilityElement()
    }
}
