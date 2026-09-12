import FactoryKit
import SwiftData
import SwiftUI

/// Screens 5 to 8, the Pro ones: the composing room. Set your own round of ten in any section
/// at any difficulty, and see which sections keep catching you. A round here prints a proof,
/// not an edition — same sheet, smaller type, no burst.
struct PracticeView: View {
    @Environment(\.brand) private var brand
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
    @State private var flags: [Bool] = []
    @State private var loading = false
    @State private var errorMessage: String?
    @State private var voice = RoundVoice()
    @State private var stampLine = ""

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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
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
        GeometryReader { geo in
        ScrollView {
            VStack(spacing: 18) {
                Spacer(minLength: 0)

                Image("TypeCase")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 290)
                    .popIn()
                    .accessibilityLabel("A composing stick and a type case")

                Text("The composing room")
                    .brandDisplay(size: 28, relativeTo: .title)
                    .foregroundStyle(brand.palette.ink)
                    .multilineTextAlignment(.center)
                    .popIn(delay: 0.05)

                Text("Where the paper is set before it goes to press.")
                    .brandFont(.body, weight: .regular)
                    .italic()
                    .foregroundStyle(brand.palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .popIn(delay: 0.1)

                VStack(spacing: 0) {
                    ForEach(Array(AppInfo.paywallBullets.enumerated()), id: \.offset) { offset, bullet in
                        HStack(alignment: .top, spacing: 10) {
                            Text("\u{261E}")
                                .brandFont(.callout)
                                .foregroundStyle(brand.palette.extras[offset % brand.palette.extras.count])
                            Text(bullet)
                                .scaledFont(size: 17, design: .serif, relativeTo: .body)
                                .foregroundStyle(brand.palette.ink)
                                .fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                        .padding(.vertical, 12)
                        if offset < AppInfo.paywallBullets.count - 1 {
                            InkRule(weight: 0.5, opacity: 0.22)
                        }
                    }
                }
                .popIn(delay: 0.15)

                Button {
                    Haptics.tap()
                    showPaywall = true
                } label: {
                    Text("See the composing room").frame(maxWidth: .infinity)
                }
                .brandProminent()
                .popIn(delay: 0.2)

                Spacer(minLength: 18)

                PrintersOrnament()
            }
            .padding(.horizontal, 30)
            .padding(.top, 20)
            .padding(.bottom, 46)
            .frame(minHeight: geo.size.height)
        }
        .paper()
        }
    }

    // MARK: - Setup

    private var setup: some View {
        ScrollView {
            VStack(spacing: 20) {
                Masthead(title: "The case", strapline: "Set a round of your own")

                VStack(alignment: .leading, spacing: 14) {
                    Text("Set a round").dateline(10, tracking: 2)

                    Picker("Section", selection: $categoryID) {
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
                        Haptics.tap()
                        Task { await load() }
                    } label: {
                        Group {
                            if loading {
                                ProgressView().tint(brand.palette.onAccent)
                            } else {
                                Text("Set a round of ten")
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .brandProminent()
                    .disabled(loading)

                    if errorMessage != nil {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("The wire is down")
                                .brandFont(.headline)
                                .foregroundStyle(brand.palette.ink)
                            Text("Nothing came through. Try again in a moment.")
                                .scaledFont(size: 15, design: .serif, relativeTo: .footnote)
                                .foregroundStyle(brand.palette.inkSoft)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .ruledBox(padding: 16)

                accuracyTable

                Text(OpenTDB.attribution)
                    .dateline(9, tracking: 1.4)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                PrintersOrnament()
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 18)
        }
        .paper()
        .onChange(of: categoryID) { _, _ in Tones.shared.play(.tap); Haptics.selection() }
        .onChange(of: difficultyRaw) { _, _ in Tones.shared.play(.tap); Haptics.selection() }
    }

    /// A printed league table, worst section first, because that is what she came to see.
    private var accuracyTable: some View {
        let ranked = stats.filter { $0.asked > 0 }.sorted { $0.accuracy < $1.accuracy }
        return VStack(alignment: .leading, spacing: 0) {
            Text("Where the copy stands").dateline(10, tracking: 2)
                .padding(.bottom, 10)

            if ranked.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("No copy on record")
                        .brandFont(.headline)
                        .foregroundStyle(brand.palette.ink)
                    Text("Answer a few and your sections show up here, worst first.")
                        .scaledFont(size: 15, design: .serif, relativeTo: .footnote)
                        .foregroundStyle(brand.palette.inkSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                ForEach(Array(ranked.enumerated()), id: \.element.id) { offset, stat in
                    HStack(spacing: 10) {
                        Rectangle()
                            .fill(AppBrand.ink(for: stat.category))
                            .frame(width: 3)
                        VStack(alignment: .leading, spacing: 6) {
                            Text(stat.category)
                                .scaledFont(size: 17, design: .serif, relativeTo: .body)
                                .foregroundStyle(brand.palette.ink)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .stroke(brand.palette.ink.opacity(0.35), lineWidth: 1)
                                    Rectangle()
                                        .fill(brand.palette.ink.opacity(0.85))
                                        .frame(width: max(1, geo.size.width * stat.accuracy))
                                }
                            }
                            .frame(height: 8)
                        }
                        Text("\(stat.correct)/\(stat.asked)")
                            .dateline(11, tracking: 1.2, color: brand.palette.ink)
                    }
                    .frame(height: 54)
                    .accessibilityElement(children: .combine)
                    if offset < ranked.count - 1 {
                        InkRule(weight: 0.5, opacity: 0.2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ruledBox(padding: 16)
    }

    // MARK: - Playing

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
                header: "Composing room · \(category.name) · \(difficulty.label)",
                onAnswer: { answer(item: item, choice: $0) },
                onReport: { report(item: item) },
                onNext: next
            )
        } else {
            proof
        }
    }

    /// A proof, not an edition: the same page at a smaller size, and no confetti.
    private var proof: some View {
        GeometryReader { geo in
        ScrollView {
            VStack(spacing: 16) {
                Masthead(title: "Proof", size: 26)
                Text("\(category.name) · \(difficulty.label)")
                    .dateline(10, tracking: 2)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(flags.filter { $0 }.count)")
                        .brandDisplay(size: 88)
                        .foregroundStyle(brand.palette.ink)
                    Text("/\(flags.count)")
                        .brandDisplay(size: 28, relativeTo: .title)
                        .foregroundStyle(brand.palette.inkSoft)
                }
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                Tally(flags: flags, total: max(flags.count, 10), height: 28)
                Button {
                    Haptics.tap()
                    Task { await load() }
                } label: {
                    Text("Another round").frame(maxWidth: .infinity)
                }
                .brandProminent()
                Button("Back to the case") { endRound() }
                    .brandFont(.subheadline)
                    .foregroundStyle(brand.palette.accent)

                Spacer(minLength: 24)

                PrintersOrnament()
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 24)
            .frame(minHeight: geo.size.height)
        }
        .paper()
        }
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
            flags = []
            voice = RoundVoice()
        } catch {
            items = []
            errorMessage = error.localizedDescription
        }
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
        index += 1
    }

    private func endRound() {
        items = []
        index = 0
        selected = nil
        flags = []
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
