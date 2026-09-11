import FactoryKit
import SwiftData
import SwiftUI

/// The three densities the month is printed in, and the legend that reads them. One
/// definition, so a change to either stays honest about the other.
enum ScoreShade: String, CaseIterable, Identifiable {
    case high, mid, low

    var id: String { rawValue }

    /// Ink, not a tint of the accent: the month should read as a printed pattern.
    var opacity: Double {
        switch self {
        case .high: return 0.92
        // DESIGN.md's middle density was 0.62, which puts the knocked-out score at 4.04:1 —
        // large text only. 0.70 takes it to AA and the three-step ramp still reads as three.
        case .mid: return 0.70
        case .low: return 0.34
        }
    }

    var label: String {
        switch self {
        case .high: return "8+"
        case .mid: return "5–7"
        case .low: return "under 5"
        }
    }

    static func forScore(_ score: Int) -> ScoreShade {
        switch score {
        case 8...: return .high
        case 5...7: return .mid
        default: return .low
        }
    }
}

/// Screen 4. The run, and the back issues. Hero: the streak at 96 pt — one number, not three
/// tiles, and a single ledger line under it for everything else.
struct ScorecardView: View {
    @Environment(\.brand) private var brand
    @Query private var results: [DayResult]

    @AppStorage("quizday.reminderOn") private var reminderOn = false
    @AppStorage("quizday.reminderHour") private var reminderHour = 20
    @AppStorage("quizday.reminderMinute") private var reminderMinute = 0

    @State private var month: Date = Calendar.current.startOfDay(for: .now)
    @State private var permissionDenied = false

    private var todayKey: String { DayKey.key(for: .now) }
    private var todayResult: DayResult? { results.first { $0.dayKey == todayKey } }
    private var streak: Int { Streaks.current(from: results) }
    private var best: Int { Streaks.best(from: results) }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                Masthead(title: "The file", strapline: "Every edition you have filed")
                if results.isEmpty {
                    emptyFile
                } else {
                    runBlock
                    calendarBlock
                    todaysEdition
                }
                morningEdition
                PrintersOrnament()
            }
            .padding(.horizontal, 30)
            .padding(.vertical, 18)
        }
        .paper()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Nothing filed

    private var emptyFile: some View {
        VStack(spacing: 14) {
            Image("Spike")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
                .accessibilityLabel("A spindle spike through a stack of back issues")
            Text("The file is empty")
                .brandDisplay(size: 26, relativeTo: .title2)
                .foregroundStyle(brand.palette.ink)
            Text("Play an edition and it gets spiked here, dated.")
                .scaledFont(size: 16, design: .serif, relativeTo: .body)
                .foregroundStyle(brand.palette.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .popIn()
    }

    // MARK: - The run

    private var runBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text("\(streak)")
                    .brandDisplay(size: 96)
                    .foregroundStyle(brand.palette.ink)
                Text(streak == 1 ? "day\nrunning" : "days\nrunning")
                    .dateline(12, tracking: 1.8, color: brand.palette.onAccent)
                    .fixedSize()
                    .padding(.leading, 22)
                    .padding(.trailing, 14)
                    .padding(.vertical, 8)
                    .background(RibbonShape(notch: 14).fill(brand.palette.highlight))
                    .offset(y: -10)
                Spacer(minLength: 0)
            }
            Text(ledger)
                .dateline(10, tracking: 1.4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(streak) days running. \(ledger)")
    }

    private var ledger: String {
        let asked = results.reduce(0) { $0 + $1.total }
        let correct = results.reduce(0) { $0 + $1.score }
        let filed = results.count == 1 ? "1 edition filed" : "\(results.count) editions filed"
        return "Best \(best) · \(filed) · \(correct) of \(asked) answered"
    }

    // MARK: - The month

    private var calendarBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(month, format: .dateTime.month(.wide).year())
                    .dateline(11, tracking: 2, color: brand.palette.ink)
                Spacer()
                Button { step(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Previous month")
                Button { step(1) } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel("Next month")
                    .disabled(isCurrentMonth)
            }

            InkRule(weight: 0.5, opacity: 0.25)

            HStack(spacing: 0) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { offset, symbol in
                    Text(symbol)
                        .dateline(9, tracking: 2)
                        .frame(maxWidth: .infinity)
                        .overlay(alignment: .trailing) {
                            if offset < 6 { columnRule }
                        }
                }
            }

            let cells = monthCells
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 3) {
                ForEach(Array(cells.enumerated()), id: \.element.id) { offset, cell in
                    dayCell(cell)
                        .overlay(alignment: .trailing) {
                            if offset % 7 < 6 { columnRule }
                        }
                }
            }

            InkRule(weight: 0.5, opacity: 0.25)

            Text(legendLine)
                .dateline(9, tracking: 1.4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ruledBox(padding: 14)
    }

    private var columnRule: some View {
        Rectangle()
            .fill(brand.palette.ink.opacity(0.12))
            .frame(width: 0.5)
    }

    private var legendLine: String {
        "Solid \(ScoreShade.high.label) · \(ScoreShade.mid.label) · \(ScoreShade.low.label) · ruled, unplayed"
    }

    private struct DayCell: Identifiable {
        let id: Int
        let date: Date?
        let result: DayResult?
    }

    private var weekdaySymbols: [String] {
        let calendar = Calendar.current
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private var isCurrentMonth: Bool {
        Calendar.current.isDate(month, equalTo: .now, toGranularity: .month)
    }

    private var monthCells: [DayCell] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: month),
              let range = calendar.range(of: .day, in: .month, for: month)
        else { return [] }
        let firstWeekday = calendar.component(.weekday, from: interval.start)
        let leading = (firstWeekday - calendar.firstWeekday + 7) % 7
        var cells: [DayCell] = (0..<leading).map { DayCell(id: -($0 + 1), date: nil, result: nil) }
        for day in range {
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: interval.start) else { continue }
            let key = DayKey.key(for: date)
            cells.append(DayCell(id: day, date: date, result: results.first { $0.dayKey == key }))
        }
        return cells
    }

    @ViewBuilder
    private func dayCell(_ cell: DayCell) -> some View {
        if let date = cell.date {
            let calendar = Calendar.current
            let isToday = calendar.isDateInToday(date)
            let future = date > Date.now && !isToday
            let day = calendar.component(.day, from: date)
            ZStack {
                if let result = cell.result {
                    let shade = ScoreShade.forScore(result.score)
                    Rectangle()
                        .fill(brand.palette.ink.opacity(shade.opacity))
                    // Knocked out in paper on a dark square, printed in ink on a pale one:
                    // paper on the lightest density comes out at under 2:1 and the month has
                    // to be readable at arm's length, not only look like a printed pattern.
                    Text("\(result.score)")
                        .dateline(11, tracking: 0,
                                  color: shade == .low ? brand.palette.ink : brand.palette.canvas)
                } else if !future {
                    Rectangle()
                        .stroke(brand.palette.ink.opacity(0.3), lineWidth: 1)
                        .overlay(alignment: .topLeading) {
                            Text("\(day)")
                                .dateline(8, tracking: 0)
                                .padding(2)
                        }
                }
            }
            .frame(height: 34)
            .padding(.horizontal, 3)
            .overlay {
                if isToday {
                    PencilEllipse()
                        .stroke(brand.palette.accent, style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
                        .padding(-1)
                }
            }
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel(date: date, result: cell.result))
        } else {
            Color.clear.frame(height: 34)
        }
    }

    private func accessibilityLabel(date: Date, result: DayResult?) -> String {
        let day = date.formatted(.dateTime.day().month(.wide))
        guard let result else { return "\(day), not played" }
        return "\(day), scored \(result.score) out of \(result.total)"
    }

    private func step(_ months: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: months, to: month) else { return }
        if months > 0, next > Date.now { return }
        Haptics.selection()
        withMotion(Motion.snappy) { month = next }
    }

    // MARK: - Today's edition

    @ViewBuilder
    private var todaysEdition: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's edition").dateline(10, tracking: 2)
            if let result = todayResult {
                Tally(flags: result.flags, total: result.total, height: 26)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(result.score)")
                        .brandDisplay(size: 34, relativeTo: .title)
                        .foregroundStyle(brand.palette.ink)
                    Text("/\(result.total)")
                        .dateline(12, tracking: 1.2)
                    Spacer(minLength: 8)
                    ShareLink(item: ShareEdition.line(roundNumber: result.roundNumber,
                                                      flags: result.flags,
                                                      streak: streak)) {
                        Text("Share the edition")
                            .dateline(10, tracking: 1.6, color: brand.palette.accent)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                Text("Today is still blank.")
                    .scaledFont(size: 17, design: .serif, relativeTo: .body)
                    .italic()
                    .foregroundStyle(brand.palette.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ruledBox(padding: 16)
    }

    // MARK: - The morning edition

    private var morningEdition: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: reminderBinding) {
                Text("The morning edition")
                    .brandFont(.headline)
                    .foregroundStyle(brand.palette.ink)
            }
            if reminderOn {
                DatePicker("Ready by",
                           selection: reminderTimeBinding,
                           displayedComponents: .hourAndMinute)
                    .brandFont(.subheadline, weight: .regular)
            }
            Text(permissionDenied
                 ? "Notifications are off for Quizday. Turn them on in the Settings app and the edition arrives again."
                 : "One knock at the door, at the hour you choose.")
                .scaledFont(size: 14, design: .serif, relativeTo: .footnote)
                .foregroundStyle(brand.palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .ruledBox(padding: 16)
    }

    private var reminderBinding: Binding<Bool> {
        Binding(get: { reminderOn }, set: { newValue in
            if newValue {
                Task {
                    let granted = await Reminders.requestAuthorization()
                    await MainActor.run {
                        permissionDenied = !granted
                        reminderOn = granted
                    }
                    if granted { await Reminders.schedule(hour: reminderHour, minute: reminderMinute) }
                }
            } else {
                reminderOn = false
                permissionDenied = false
                Reminders.cancel()
            }
        })
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                var components = DateComponents()
                components.hour = reminderHour
                components.minute = reminderMinute
                return Calendar.current.date(from: components) ?? Date.now
            },
            set: { newValue in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: newValue)
                reminderHour = parts.hour ?? 20
                reminderMinute = parts.minute ?? 0
                Task { await Reminders.schedule(hour: reminderHour, minute: reminderMinute) }
            }
        )
    }
}
