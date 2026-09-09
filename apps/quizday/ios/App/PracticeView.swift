import FactoryKit
import SwiftData
import SwiftUI

/// Screen 3, the Pro one. Unlimited rounds in whatever category and difficulty the player
/// picks, plus the accuracy table that shows where the weak spots are.
struct PracticeView: View {
    @EnvironmentObject private var store: Store
    @Environment(\.modelContext) private var context
    @Query private var stats: [CategoryStat]
    @Query private var reports: [QuestionReport]
    @Binding var showPaywall: Bool

    @AppStorage("quizday.practiceCategory") private var categoryID = 9
    @AppStorage("quizday.practiceDifficulty") private var difficultyRaw = OpenTDB.Difficulty.medium.rawValue

    @State private var items: [QuizItem] = []
    @State private var index = 0
    @State private var selected: Int?
    @State private var correctCount = 0
    @State private var loading = false
    @State private var errorMessage: String?

    private var isPro: Bool { store.isPro || LaunchOptions.forcePro }
    private var category: OpenTDB.Category {
        OpenTDB.categories.first { $0.id == categoryID } ?? OpenTDB.categories[0]
    }
    private var difficulty: OpenTDB.Difficulty {
        OpenTDB.Difficulty(rawValue: difficultyRaw) ?? .medium
    }

    var body: some View {
        Group {
            if !isPro {
                locked
            } else if !items.isEmpty {
                playing
            } else {
                setup
            }
        }
        .navigationTitle("Practice")
        .navigationBarTitleDisplayMode(items.isEmpty ? .large : .inline)
        .task {
            if LaunchOptions.practiceStart, isPro, items.isEmpty, !loading { await load() }
        }
        .toolbar {
            if !items.isEmpty {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { endRound() }
                }
            }
        }
    }

    // MARK: - Locked

    private var locked: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "infinity")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundStyle(Color.accentColor)
                    Text("Practice is part of Pro")
                        .font(.title2.bold())
                    Text("Play as many rounds as you like in any category, at the difficulty you choose, and see your accuracy build up category by category.")
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(AppInfo.paywallBullets, id: \.self) { bullet in
                        Label(bullet, systemImage: "checkmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .factoryCard()

                Button("See Pro") {
                    Haptics.tap()
                    showPaywall = true
                }
                .buttonStyle(.factoryPrimary)

                Label(AppInfo.paywallPromise, systemImage: "hand.raised.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(FactoryTheme.padding)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Setup

    private var setup: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("New round")
                        .font(.headline)

                    Picker("Category", selection: $categoryID) {
                        ForEach(OpenTDB.categories) { category in
                            Text(category.name).tag(category.id)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Difficulty", selection: $difficultyRaw) {
                        ForEach(OpenTDB.Difficulty.allCases) { level in
                            Text(level.label).tag(level.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)

                    Button {
                        Task { await load() }
                    } label: {
                        if loading {
                            ProgressView().tint(.white)
                        } else {
                            Text("Start ten questions")
                        }
                    }
                    .buttonStyle(.factoryPrimary)
                    .disabled(loading)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .factoryCard()

                accuracyCard

                Text(OpenTDB.attribution)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(FactoryTheme.padding)
        }
        .background(Color(.systemGroupedBackground))
    }

    private var accuracyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your accuracy")
                .font(.headline)
            let ranked = stats.filter { $0.asked > 0 }.sorted { $0.accuracy < $1.accuracy }
            if ranked.isEmpty {
                Text("Play a daily round or a practice round and your accuracy per category shows up here.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                ForEach(ranked) { stat in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(stat.category).font(.subheadline)
                            Spacer()
                            Text("\(stat.correct)/\(stat.asked)")
                                .font(.subheadline.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(.secondary)
                        }
                        ProgressView(value: stat.accuracy)
                            .tint(Color.accentColor)
                    }
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .factoryCard()
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
            summary
        }
    }

    private var summary: some View {
        VStack(spacing: 16) {
            Text("\(correctCount) out of \(items.count)")
                .font(.system(size: 40, weight: .bold, design: .rounded))
            Text("\(category.name) · \(difficulty.label)")
                .foregroundStyle(.secondary)
            Button("Another round") {
                Task { await load() }
            }
            .buttonStyle(.factoryPrimary)
            Button("Back to practice") { endRound() }
                .font(.subheadline)
        }
        .padding(FactoryTheme.padding)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Flow

    private func load() async {
        loading = true
        errorMessage = nil
        defer { loading = false }
        do {
            let fetched = try await OpenTDB.fetch(category: category, difficulty: difficulty)
            items = fetched
            index = 0
            selected = nil
            correctCount = 0
        } catch {
            items = []
            errorMessage = error.localizedDescription
        }
    }

    private func answer(item: QuizItem, choice: Int) {
        guard selected == nil else { return }
        selected = choice
        let correct = choice == item.correct
        if correct {
            correctCount += 1
            Haptics.success()
        } else {
            Haptics.warning()
        }
        record(category: item.category, correct: correct)
    }

    private func next() {
        selected = nil
        index += 1
    }

    private func endRound() {
        items = []
        index = 0
        selected = nil
        correctCount = 0
    }

    private func record(category: String, correct: Bool) {
        let all = (try? context.fetch(FetchDescriptor<CategoryStat>())) ?? []
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
