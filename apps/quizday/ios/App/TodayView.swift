import FactoryKit
import SwiftData
import SwiftUI

/// Screen 1. The day's ten questions, the same ten for everyone, then the result.
struct TodayView: View {
    @Environment(\.modelContext) private var context
    @Query private var results: [DayResult]
    @Query private var reports: [QuestionReport]

    @State private var phase: Phase = .intro
    @State private var index = 0
    @State private var selected: Int?
    @State private var flags: [Bool] = []
    @State private var items: [QuizItem] = []

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
        .navigationTitle("Today")
        .navigationBarTitleDisplayMode(phase == .playing ? .inline : .large)
        .onAppear(perform: syncPhase)
    }

    // MARK: - Intro

    private var intro: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(today, format: .dateTime.weekday(.wide).day().month(.wide))
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    Text("Round \(roundNumber)")
                        .font(.largeTitle.bold())
                    Text("Ten questions. The same ten everyone gets today. No timer, no ads, nothing to run out of.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if streak > 0 {
                    Label("\(streak) day streak. Play today to keep it.", systemImage: "flame.fill")
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Today's categories")
                        .font(.headline)
                    FlowRow(spacing: 8) {
                        ForEach(DailyPack.categories(for: today), id: \.self) { category in
                            Text(category)
                                .font(.footnote)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color(.tertiarySystemFill), in: Capsule())
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .factoryCard()

                Button("Start today's ten") {
                    Haptics.tap()
                    start()
                }
                .buttonStyle(.factoryPrimary)
            }
            .padding(FactoryTheme.padding)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Playing

    @ViewBuilder
    private var playing: some View {
        if index < items.count {
            let item = items[index]
            QuestionCard(
                item: item,
                position: index + 1,
                total: items.count,
                selected: selected,
                reported: reports.contains { $0.questionID == item.id },
                onAnswer: { answer(item: item, choice: $0) },
                onReport: { report(item: item) },
                onNext: next
            )
        } else {
            ProgressView()
        }
    }

    // MARK: - Done

    private var done: some View {
        let result = todayResult
        let shownFlags = result?.flags ?? flags
        let score = shownFlags.filter { $0 }.count
        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Round \(result?.roundNumber ?? roundNumber) done")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.accentColor)
                    Text("\(score) out of \(shownFlags.count)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text(verdict(score: score, total: shownFlags.count))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                SquareRow(flags: shownFlags)

                if streak > 0 {
                    Label(streak == 1 ? "Streak started" : "\(streak) day streak",
                          systemImage: "flame.fill")
                        .font(.headline)
                        .foregroundStyle(.orange)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .factoryCard()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Next ten", systemImage: "clock")
                        .font(.headline)
                    Text(timerInterval: Date.now...nextMidnight, countsDown: true)
                        .font(.system(.title2, design: .rounded).weight(.semibold))
                        .monospacedDigit()
                    Text("A new round every day. Nothing to buy in between.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .factoryCard()

                ShareLink(item: ShareCard.text(roundNumber: result?.roundNumber ?? roundNumber,
                                               flags: shownFlags,
                                               streak: streak)) {
                    Label("Share your squares", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color(.secondarySystemGroupedBackground),
                                    in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            .padding(FactoryTheme.padding)
        }
        .background(Color(.systemGroupedBackground))
        // Asked here, not on the root: a rating request in the middle of a question is the
        // kind of interruption this app exists to avoid.
        .factoryReviewPrompt(afterSessions: 3)
    }

    private var nextMidnight: Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date.now) ?? Date.now
        return calendar.startOfDay(for: tomorrow)
    }

    private func verdict(score: Int, total: Int) -> String {
        switch score {
        case total: return "A clean sweep. Come back tomorrow for ten more."
        case 0: return "A hard round. Every answer came with the reason, so tomorrow starts better."
        case ..<(total / 2): return "Some tricky ones today. The explanations are the point as much as the score."
        default: return "A solid round. Come back tomorrow for ten more."
        }
    }

    // MARK: - Flow

    private func syncPhase() {
        if let answered = LaunchOptions.answered, todayResult == nil {
            let sample = (0..<10).map { $0 < answered }
            save(flags: sample.shuffled())
        }
        if LaunchOptions.autoPlay, todayResult == nil {
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

    private func start() {
        items = DailyPack.items(for: today)
        guard !items.isEmpty else { return }
        index = 0
        selected = nil
        flags = []
        phase = .playing
    }

    private func answer(item: QuizItem, choice: Int) {
        guard selected == nil else { return }
        selected = choice
        let correct = choice == item.correct
        flags.append(correct)
        record(category: item.category, correct: correct)
        if correct { Haptics.success() } else { Haptics.warning() }
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

/// The ten squares, shown on the result and in the share text.
struct SquareRow: View {
    let flags: [Bool]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(flags.enumerated()), id: \.offset) { _, hit in
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(hit ? Color.accentColor : Color(.tertiarySystemFill))
                    .frame(height: 26)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(flags.filter { $0 }.count) of \(flags.count) correct")
    }
}

/// Wrapping row of chips. Categories vary in length, so a fixed grid would leave holes.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
