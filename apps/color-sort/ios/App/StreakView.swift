import FactoryKit
import SwiftData
import SwiftUI

/// Progress: today's shared puzzle, the streak it feeds, and the month behind it.
struct StreakView: View {
    @Query private var results: [LevelResult]
    let onPlayDaily: () -> Void

    private var todayKey: String { DayKey.key() }
    private var playedDays: Set<String> { Set(results.map(\.dayKey)) }
    private var today: LevelResult? {
        results.first { $0.isDaily && $0.dayKey == todayKey }
    }
    private var levelsCleared: Int { results.filter { !$0.isDaily }.count }
    private var streak: Int { Streaks.current(days: playedDays) }
    private var longest: Int { Streaks.longest(days: playedDays) }

    private var shareLine: String {
        let today = today.map { "cleared in \($0.moves) moves, par \($0.par)" } ?? "not played yet"
        return "Tidepour daily · \(todayKey) · \(today) · \(streak)-day streak. "
             + "Same puzzle for everyone, every day. No ads, no coins, nothing runs out."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                dailyCard
                streakCard
                CalendarMonthView(playedDays: playedDays)
                    .factoryCard()
                totals
                ShareLink(item: shareLine) {
                    Label("Share today's result", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(FactoryTheme.padding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Progress")
    }

    private var dailyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Daily puzzle", systemImage: "calendar.badge.clock")
                .font(.headline)
            Text("Everyone who opens Tidepour today gets this exact board — seeded from the date, solved before it is served.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            if let today {
                Label("Cleared in \(today.moves) moves, par \(today.par)", systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(Color.accentColor)
                Button("Play it again", action: onPlayDaily)
                    .buttonStyle(.bordered)
            } else {
                Button("Play today's puzzle", action: onPlayDaily)
                    .buttonStyle(.factoryPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .factoryCard()
    }

    private var streakCard: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(streak)", caption: "day streak")
            StatTile(value: "\(longest)", caption: "longest run")
            StatTile(value: "\(playedDays.count)", caption: "days played")
        }
    }

    private var totals: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent("Levels cleared", value: "\(levelsCleared)")
            LabeledContent("Daily puzzles cleared", value: "\(results.filter(\.isDaily).count)")
            Text("No timer, no lives, no coins. Nothing here expires and nothing here runs out.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .factoryCard()
    }
}

struct StatTile: View {
    let value: String
    let caption: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .scaledFont(size: 30, weight: .bold, design: .rounded, relativeTo: .title)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: FactoryTheme.cornerRadius, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// The month so far, one square per day, filled on the days a puzzle was cleared.
struct CalendarMonthView: View {
    let playedDays: Set<String>
    var reference: Date = .now

    /// Grows with the text size, so the day numbers still fit their squares — and capped
    /// below, because seven columns of a month cannot grow without bound on a phone.
    @ScaledMetric(relativeTo: .caption) private var cellHeight: CGFloat = 30

    private var calendar: Calendar { .current }

    private var monthLabel: String {
        reference.formatted(.dateTime.month(.wide).year())
    }

    /// Leading blanks so the first of the month lands under the right weekday, then the days.
    private var cells: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: reference) else { return [] }
        let first = interval.start
        let weekdayOfFirst = calendar.component(.weekday, from: first)
        let leading = (weekdayOfFirst - calendar.firstWeekday + 7) % 7
        let days = calendar.range(of: .day, in: .month, for: reference)?.count ?? 30
        var out: [Date?] = Array(repeating: nil, count: leading)
        for offset in 0..<days {
            out.append(calendar.date(byAdding: .day, value: offset, to: first))
        }
        return out
    }

    private var weekdaySymbols: [String] {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return Array(symbols[start...] + symbols[..<start])
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(monthLabel)
                .font(.headline)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 6) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                ForEach(Array(cells.enumerated()), id: \.offset) { _, date in
                    if let date {
                        day(date)
                    } else {
                        Color.clear.frame(height: cellHeight)
                    }
                }
            }
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(monthLabel). \(playedDaysThisMonth) days played this month.")
    }

    private var playedDaysThisMonth: Int {
        cells.compactMap { $0 }.filter { playedDays.contains(DayKey.key(for: $0)) }.count
    }

    private func day(_ date: Date) -> some View {
        let played = playedDays.contains(DayKey.key(for: date))
        let isToday = calendar.isDateInToday(date)
        return Text("\(calendar.component(.day, from: date))")
            .font(.caption)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(played ? Color.white : Color.primary)
            .frame(maxWidth: .infinity)
            .frame(height: cellHeight)
            .background(played ? Color.accentColor : Color(.tertiarySystemGroupedBackground),
                        in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.accentColor, lineWidth: 2)
                }
            }
    }
}
