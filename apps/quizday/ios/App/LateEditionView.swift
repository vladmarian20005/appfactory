import FactoryKit
import SwiftData
import SwiftUI

/// The late edition: the one door in this app that money does not open.
///
/// It arrives at seven editions filed, runs to eight at twenty-five, and at sixty she picks the
/// section it is set from. Every question in it is one that got past her — this is the round the
/// misses have been accumulating for, and until now they accumulated where nothing read them.
///
/// It is not a second daily: nothing about it expires, nothing runs out, and skipping it costs
/// her nothing. It is simply there, every evening she has filed, set from her own corrections.
struct LateEditionView: View {
    @Environment(\.brand) private var brand
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var desk: Desk
    @Query private var results: [DayResult]
    @Query private var reports: [QuestionReport]

    /// Passed in where the caller already knows it; otherwise counted from the file.
    var filed: Int?

    @State private var items: [QuizItem] = []
    @State private var index = 0
    @State private var selected: Int?
    @State private var flags: [Bool] = []
    @State private var voice = RoundVoice()
    @State private var stampLine = ""
    @State private var section: String?

    private var editions: Int { filed ?? results.count }
    private var count: Int { Desk.lateEditionCount(filed: editions) }
    private var picksSection: Bool { Desk.earned.isUnlocked("ownSection", at: editions) }

    var body: some View {
        Group {
            if items.isEmpty {
                setup
            } else if index < items.count {
                sheet
            } else {
                proof
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if LaunchOptions.lateStart, items.isEmpty { deal() }
        }
    }

    // MARK: - The spike

    private var setup: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 18) {
                    Masthead(title: "Late edition", strapline: "Set from your own corrections")

                    Text(Masthead.dateline(for: .now))
                        .dateline(11, tracking: 2)

                    Spacer(minLength: 0)

                    Image("Spike")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 250)
                        .padding(.vertical, 4)
                        .accessibilityLabel("A spindle spike through a stack of back issues")

                    Text("\(Spelled.leading(count)) that got past you, pulled back off the spike.")
                        .brandFont(.title3, weight: .regular)
                        .italic()
                        .foregroundStyle(brand.palette.ink)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    if picksSection, !sections.isEmpty {
                        sectionPicker
                    } else if !sections.isEmpty {
                        SectionLine(categories: Array(sections.prefix(4)))
                    }

                    Button {
                        Haptics.tap()
                        Tones.shared.play(.tap)
                        deal()
                    } label: {
                        Text("Pull the corrections").frame(maxWidth: .infinity)
                    }
                    .brandProminent()

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
    }

    /// The sections that keep catching her, which is the only list this picker could honestly
    /// offer: there is no late edition for a section that has never caught her out.
    private var sections: [String] { desk.weakestSections(limit: 6) }

    private var sectionPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Set from").dateline(10, tracking: 2)
            Picker("Set from", selection: $section) {
                Text("Everything that caught you").tag(String?.none)
                ForEach(sections, id: \.self) { name in
                    Text(name).tag(String?.some(name))
                }
            }
            .pickerStyle(.menu)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ruledBox(padding: 14)
        .onChange(of: section) { _, _ in Haptics.selection(); Tones.shared.play(.tap) }
    }

    // MARK: - The round

    @ViewBuilder
    private var sheet: some View {
        let item = items[index]
        QuestionSheet(
            item: item,
            position: index + 1,
            total: items.count,
            flags: flags,
            selected: selected,
            stampLine: stampLine,
            reported: reports.contains { $0.questionID == item.id },
            header: "Late edition · \(section ?? item.category)",
            onAnswer: { answer(item: item, choice: $0) },
            onReport: { report(item: item) },
            onNext: next
        )
    }

    /// A late edition files as a correction, not as an edition: a smaller print, and the squares
    /// that came back right are the ones that are no longer on the spike.
    private var proof: some View {
        let held = flags.filter { $0 }.count
        return GeometryReader { geo in
            ScrollView {
                VStack(spacing: 16) {
                    Masthead(title: "Corrected", size: 26)
                    Text("Late edition · \(Masthead.shortDateline(for: .now))")
                        .dateline(10, tracking: 2)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(held)")
                            .brandDisplay(size: 88)
                            .foregroundStyle(brand.palette.ink)
                        Text("/\(flags.count)")
                            .brandDisplay(size: 28, relativeTo: .title)
                            .foregroundStyle(brand.palette.inkSoft)
                    }
                    .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                    .accessibilityElement()
                    .accessibilityLabel("\(held) of \(flags.count) put right")

                    Tally(flags: flags, total: flags.count, height: 28)

                    Text(closingLine(held: held))
                        .scaledFont(size: 16, design: .serif, relativeTo: .callout)
                        .italic()
                        .foregroundStyle(brand.palette.inkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Button {
                        Haptics.tap()
                        deal()
                    } label: {
                        Text("Pull another").frame(maxWidth: .infinity)
                    }
                    .brandProminent()

                    Button("Back to the page") { dismiss() }
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

    private func closingLine(held: Int) -> String {
        switch held {
        case flags.count where held > 0: return "All of them put right. Off the spike for good."
        case 0: return "None of them yet. They keep."
        default: return "\(Spelled.leading(held)) off the spike. The rest keep."
        }
    }

    // MARK: - Flow

    private func deal() {
        items = desk.lateEdition(for: .now, filed: editions, section: section)
        index = 0
        selected = nil
        flags = []
        voice = RoundVoice()
    }

    private func answer(item: QuizItem, choice: Int) {
        guard selected == nil else { return }
        selected = choice
        let correct = choice == item.correct
        stampLine = voice.line(correct: correct)
        flags.append(correct)
        desk.record(item.id, correct: correct)
        let all = (try? context.fetch(FetchDescriptor<CategoryStat>())) ?? []
        if let stat = all.first(where: { $0.category == item.category }) {
            stat.asked += 1
            if correct { stat.correct += 1 }
        } else {
            context.insert(CategoryStat(category: item.category, asked: 1, correct: correct ? 1 : 0))
        }
        try? context.save()
    }

    private func next() {
        selected = nil
        index += 1
    }

    private func report(item: QuizItem) {
        guard !reports.contains(where: { $0.questionID == item.id }) else { return }
        context.insert(QuestionReport(questionID: item.id, questionText: item.question))
        try? context.save()
    }
}
