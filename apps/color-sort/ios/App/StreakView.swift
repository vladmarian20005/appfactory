import FactoryKit
import SwiftData
import SwiftUI

/// The chart: today's pool, the run of evenings it feeds, and the month behind it.
struct StreakView: View {
    @Query private var results: [LevelResult]
    let onPlayDaily: () -> Void

    @Environment(\.brand) private var brand

    private var todayKey: String { DayKey.key() }
    private var playedDays: Set<String> { Set(results.map(\.dayKey)) }
    private var today: LevelResult? {
        results.first { $0.isDaily && $0.dayKey == todayKey }
    }
    private var levelsCleared: Int { results.filter { !$0.isDaily }.count }
    private var streak: Int { Streaks.current(days: playedDays) }
    private var longest: Int { Streaks.longest(days: playedDays) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                hero
                todaysPool
                CalendarMonthView(playedDays: playedDays)
                share
            }
            .padding(.horizontal, FactoryTheme.padding)
            .padding(.top, 8)
            // Clear of the tab bar: the last row was sitting half under it.
            .padding(.bottom, 96)
        }
        .brandBackground(drift: true)
        .navigationTitle("Chart")
        // Inline, because a large title is drawn in the content area where the toolbar's
        // colour scheme does not reach it — and a near-black "Chart" over the pool is worse
        // than no heading at all. The streak is the heading here anyway.
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - The one number on this screen

    /// The streak, standing in the pool. One hero, not three identical tiles.
    private var hero: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text("\(streak)")
                    .brandDisplay(size: 110)
                    .foregroundStyle(brand.palette.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                VStack(alignment: .leading, spacing: 2) {
                    ChartMark(text: streak == 1 ? "Evening" : "Evenings", color: brand.palette.highlight)
                    ChartMark(text: "in a row")
                }
                .padding(.bottom, 14)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(alignment: .bottomLeading) {
                // The light it stands in.
                Ellipse()
                    .fill(RadialGradient(colors: [brand.palette.accent.opacity(0.22),
                                                  brand.palette.accent.opacity(0)],
                                         center: .center, startRadius: 0, endRadius: 110))
                    .frame(width: 230, height: 96)
                    .offset(x: -30, y: 28)
                    .breathing(amount: 0.05, period: 5)
                    .allowsHitTesting(false)
            }
            Text("Longest run \(longest) · \(playedDays.count) evenings on the shore")
                .font(.subheadline)
                .foregroundStyle(brand.palette.inkSoft)
            Text("\(levelsCleared) racks and \(results.filter(\.isDaily).count) pools cleared")
                .font(.subheadline)
                .foregroundStyle(brand.palette.inkSoft)
        }
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(streak) evenings in a row. Longest run \(longest). \(playedDays.count) evenings played. \(levelsCleared) racks and \(results.filter(\.isDaily).count) pools cleared.")
    }

    private var todaysPool: some View {
        VStack(alignment: .leading, spacing: 12) {
            ChartMark(text: "Today's pool", color: brand.palette.accent)
            Text("The same rack fills for everyone who walks down today — seeded from the date, walked before it is served.")
                .font(.footnote)
                .foregroundStyle(brand.palette.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
            if let today {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundStyle(brand.palette.success)
                    Text("\(today.moves) pours, the line was \(today.par)")
                        .brandFont(.headline)
                        .foregroundStyle(brand.palette.ink)
                }
                Button("Pour it again", action: onPlayDaily)
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .tint(brand.palette.accent)
            } else {
                Button("Pour today's", action: onPlayDaily)
                    .brandProminent()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .brandSurface()
    }

    @ViewBuilder
    private var share: some View {
        if let image = card {
            ShareLink(item: image, preview: SharePreview("Tidepour · \(todayKey)", image: image)) {
                Label("Share the rack", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .tint(brand.palette.accent)
        }
    }

    /// The day's result as a picture, not a line of text nobody taps.
    @MainActor
    private var card: Image? {
        guard let today else { return nil }
        let result = GameModel.FinishedLevel(levelID: .daily(today.dayKey),
                                             moves: today.moves,
                                             par: today.par,
                                             dayKey: today.dayKey)
        return rackCardImage(result: result,
                             board: .cleared(colors: 6),
                             style: BoardStyle(),
                             streak: streak)
    }
}

/// The month so far, one pool per day, lit on the evenings a rack was cleared.
struct CalendarMonthView: View {
    let playedDays: Set<String>
    var reference: Date = .now

    @Environment(\.brand) private var brand

    /// Grows with the text size, so the day numbers still fit their pools — and capped below,
    /// because seven columns of a month cannot grow without bound on a phone.
    @ScaledMetric(relativeTo: .caption) private var cellHeight: CGFloat = 32

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
        VStack(alignment: .leading, spacing: 12) {
            ChartMark(text: monthLabel, color: brand.palette.highlight)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7), spacing: 8) {
                ForEach(Array(weekdaySymbols.enumerated()), id: \.offset) { _, symbol in
                    Text(symbol)
                        .font(.caption2)
                        .foregroundStyle(brand.palette.inkSoft.opacity(0.7))
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
        .accessibilityLabel("\(monthLabel). \(playedDaysThisMonth) evenings played this month.")
    }

    private var playedDaysThisMonth: Int {
        cells.compactMap { $0 }.filter { playedDays.contains(DayKey.key(for: $0)) }.count
    }

    /// A pool, not a rounded square: filled and lit on an evening that was played, a dark
    /// ring of wet sand on one that was not.
    private func day(_ date: Date) -> some View {
        let played = playedDays.contains(DayKey.key(for: date))
        let isToday = calendar.isDateInToday(date)
        return Text("\(calendar.component(.day, from: date))")
            .font(.caption)
            .monospacedDigit()
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .foregroundStyle(played ? brand.palette.onAccent : brand.palette.inkSoft)
            .frame(maxWidth: .infinity)
            .frame(height: cellHeight)
            .background {
                Circle()
                    .fill(played
                          ? AnyShapeStyle(RadialGradient(colors: [brand.palette.accent,
                                                                  brand.palette.accent.opacity(0.72)],
                                                         center: UnitPoint(x: 0.4, y: 0.32),
                                                         startRadius: 1, endRadius: cellHeight))
                          : AnyShapeStyle(brand.palette.ink.opacity(0.07)))
                    .shadow(color: played ? brand.palette.accent.opacity(0.5) : .clear, radius: 6)
            }
            .overlay {
                if isToday {
                    Circle().strokeBorder(brand.palette.highlight, lineWidth: 2)
                }
            }
    }
}
