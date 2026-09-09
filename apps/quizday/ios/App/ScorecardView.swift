import FactoryKit
import SwiftData
import SwiftUI

/// The three shades the calendar uses, and the legend that explains them. One definition,
/// so a change to either stays honest about the other.
enum ScoreShade: String, CaseIterable, Identifiable {
    case high, mid, low

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .high: return Color.accentColor.opacity(0.85)
        case .mid: return Color.accentColor.opacity(0.45)
        case .low: return Color.accentColor.opacity(0.2)
        }
    }

    var label: String {
        switch self {
        case .high: return "8 or more"
        case .mid: return "5 to 7"
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

/// Screen 2. What today came to, how the streak stands, and the month at a glance.
struct ScorecardView: View {
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
            VStack(alignment: .leading, spacing: 20) {
                todayCard
                statsRow
                calendarCard
                reminderCard
            }
            .padding(FactoryTheme.padding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Scorecard")
    }

    // MARK: - Today

    private var todayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today")
                .font(.headline)
            if let result = todayResult {
                Text("\(result.score) out of \(result.total)")
                    .scaledFont(size: 36, weight: .bold, design: .rounded)
                SquareRow(flags: result.flags)
                ShareLink(item: ShareCard.text(roundNumber: result.roundNumber,
                                               flags: result.flags,
                                               streak: streak)) {
                    Label("Share", systemImage: "square.and.arrow.up").font(.subheadline)
                }
            } else {
                Text("Not played yet")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text("Today's ten are waiting on the Today tab.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .factoryCard()
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            stat(value: "\(streak)", label: "day streak", symbol: "flame.fill", tint: .orange)
            stat(value: "\(best)", label: "best streak", symbol: "trophy.fill", tint: Color.accentColor)
            stat(value: "\(results.count)", label: results.count == 1 ? "day played" : "days played", symbol: "calendar", tint: .secondary)
        }
    }

    private func stat(value: String, label: String, symbol: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Image(systemName: symbol).foregroundStyle(tint)
            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: FactoryTheme.cornerRadius, style: .continuous))
    }

    // MARK: - Calendar

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(month, format: .dateTime.month(.wide).year())
                    .font(.headline)
                Spacer()
                Button { step(-1) } label: { Image(systemName: "chevron.left") }
                    .accessibilityLabel("Previous month")
                Button { step(1) } label: { Image(systemName: "chevron.right") }
                    .accessibilityLabel("Next month")
                    .disabled(isCurrentMonth)
            }

            HStack(spacing: 4) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            let cells = monthCells
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(cells) { cell in
                    dayCell(cell)
                }
            }

            HStack(spacing: 12) {
                ForEach(ScoreShade.allCases) { shade in
                    legend(color: shade.color, text: shade.label)
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .factoryCard()
    }

    private func legend(color: Color, text: String) -> some View {
        HStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 3, style: .continuous).fill(color).frame(width: 10, height: 10)
            Text(text)
        }
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
            let day = calendar.component(.day, from: date)
            VStack(spacing: 2) {
                Text("\(day)")
                    .font(.caption2)
                    .foregroundStyle(cell.result == nil ? .secondary : .primary)
                Text(cell.result.map { "\($0.score)" } ?? " ")
                    .font(.caption.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(cell.result == nil ? Color.clear : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(fill(for: cell.result), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(isToday ? Color.accentColor : .clear, lineWidth: 1.5)
            )
            .accessibilityElement()
            .accessibilityLabel(accessibilityLabel(date: date, result: cell.result))
        } else {
            Color.clear.frame(height: 1)
        }
    }

    private func accessibilityLabel(date: Date, result: DayResult?) -> String {
        let day = date.formatted(.dateTime.day().month(.wide))
        guard let result else { return "\(day), not played" }
        return "\(day), scored \(result.score) out of \(result.total)"
    }

    private func fill(for result: DayResult?) -> Color {
        guard let result else { return Color(.tertiarySystemFill).opacity(0.5) }
        return ScoreShade.forScore(result.score).color
    }

    private func step(_ months: Int) {
        guard let next = Calendar.current.date(byAdding: .month, value: months, to: month) else { return }
        if months > 0, next > Date.now { return }
        withAnimation(.easeOut(duration: 0.15)) { month = next }
    }

    // MARK: - Reminder

    private var reminderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: reminderBinding) {
                Label("Daily reminder", systemImage: "bell")
                    .font(.headline)
            }
            if reminderOn {
                DatePicker("Remind me at",
                           selection: reminderTimeBinding,
                           displayedComponents: .hourAndMinute)
                    .font(.subheadline)
            }
            if permissionDenied {
                Text("Notifications are turned off for Quizday. Turn them on in the Settings app to use the reminder.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("One notification a day, at a time you choose. That is the only one Quizday sends.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .factoryCard()
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
