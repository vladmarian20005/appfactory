import FactoryKit
import SwiftData
import SwiftUI

/// Screen 1. The day's ten questions, the same ten for everyone, then the edition it prints.
struct TodayView: View {
    @Environment(\.brand) private var brand
    @Environment(\.modelContext) private var context
    @Query private var results: [DayResult]
    @Query private var reports: [QuestionReport]

    @State private var phase: Phase = .intro
    @State private var index = 0
    @State private var selected: Int?
    @State private var flags: [Bool] = []
    @State private var items: [QuizItem] = []
    @State private var voice = RoundVoice()
    @State private var stampLine = ""

    private enum Phase { case intro, playing, done }

    private var today: Date { .now }
    private var todayKey: String { DayKey.key(for: today) }
    private var todayResult: DayResult? { results.first { $0.dayKey == todayKey } }
    private var streak: Int { Streaks.current(from: results) }
    private var roundNumber: Int { DailyPack.roundNumber(for: today) }

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

                    HandPress(width: 250)
                        .padding(.vertical, 2)
                        .popIn(delay: 0.1)
                        .accessibilityLabel("A hand press, turning")

                    Text("Ten questions, set this morning.")
                        .brandFont(.title3, weight: .regular)
                        .italic()
                        .foregroundStyle(brand.palette.ink)
                        .popIn(delay: 0.15)

                    SectionLine(categories: DailyPack.categories(for: today))
                        .popIn(delay: 0.2)

                    if let line = Voice.streak(streak, todayPlayed: false) {
                        HStack {
                            Spacer(minLength: 0)
                            StreakRibbon(days: streak, numberSize: 34)
                                .frame(maxWidth: 220)
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

                    Spacer(minLength: 24)

                    PrintersOrnament()
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 18)
                .frame(minHeight: geo.size.height)
            }
            .paper()
        }
        .onAppear { Tones.shared.warmUp() }
    }

    private var dateline: String {
        let day = today.formatted(.dateTime.weekday(.wide).day().month(.wide))
        return "\(day) · Round \(roundNumber)"
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
                           roundNumber: result?.roundNumber ?? roundNumber,
                           playedAt: result?.playedAt ?? .now,
                           streak: streak,
                           bestStreak: Streaks.best(from: results))
            // Asked here, once the page has settled, never mid-question.
            .factoryReviewPrompt(afterSessions: 3)
    }

    // MARK: - Flow

    private func syncPhase() {
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
    private func playDemoAnswer() {
        start()
        for _ in 0..<3 {
            guard index < items.count else { break }
            answer(item: items[index], choice: items[index].correct)
            next()
        }
        guard index < items.count else { return }
        let right = items[index]
        at(1.8) { answer(item: right, choice: right.correct) }
        at(3.4) { next() }
        at(4.2) {
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
        at(2.0) { answer(item: last, choice: last.correct) }
        // A long beat before the page goes to press: a screenshot of a screen that is
        // animating hard takes the best part of two seconds on a runner, so the film needs
        // the sheet, the press and the printing spread out or it catches only the ends.
        at(3.6) { next() }
    }

    private func at(_ seconds: Double, _ work: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func start() {
        items = DailyPack.items(for: today)
        guard !items.isEmpty else { return }
        index = 0
        selected = nil
        flags = []
        voice = RoundVoice()
        phase = .playing
    }

    private func answer(item: QuizItem, choice: Int) {
        guard selected == nil else { return }
        selected = choice
        let correct = choice == item.correct
        stampLine = voice.line(correct: correct)
        flags.append(correct)
        record(category: item.category, correct: correct)
    }

    private func next() {
        selected = nil
        if index + 1 < items.count {
            index += 1
        } else {
            save(flags: flags)
            phase = .done
        }
    }

    private func save(flags: [Bool]) {
        guard results.first(where: { $0.dayKey == todayKey }) == nil else { return }
        context.insert(DayResult(dayKey: todayKey, roundNumber: roundNumber, flags: flags))
        try? context.save()
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
