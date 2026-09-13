import FactoryKit
import SwiftUI

/// The spec's chart, in the bench's language: every day a gate cut into a brass-ruled scale,
/// its depth the day's count. Today's is in chalk blue and a day with a wax in it shows one.
/// Drawn in one `Canvas`; the days carry their own VoiceOver labels over the top, so the
/// chart reads properly instead of announcing "image".
struct StripView: View {
    let days: [Record.StripDay]
    let pigment: Color
    /// The brass scale, once the gauge has been earned: a day's depth is read off rather
    /// than compared.
    let ruled: Bool

    @Environment(\.brand) private var brand
    @Environment(\.colorScheme) private var scheme

    /// The ninetieth percentile, not the maximum. One outsized day against half a year of
    /// ordinary ones flattened every other cut to a stub; a scale a typical day fills is the
    /// one you can read a week off. The handful above it clip, which is what an outlier
    /// looks like on a ruled gauge.
    private var peak: Int {
        let counted = days.map(\.count).filter { $0 > 0 }.sorted()
        guard !counted.isEmpty else { return 4 }
        return max(4, counted[min(counted.count - 1, Int(Double(counted.count) * 0.9))])
    }

    var body: some View {
        ZStack(alignment: .top) {
            StaveBoard(pigment: nil) {
                Canvas { context, size in draw(&context, size: size) }
                    .frame(height: 72)
            }
            if ruled { brassScale }
        }
        .overlay { labels }
        .accessibilityElement(children: .contain)
    }

    private var brassScale: some View {
        Rectangle()
            .fill(LinearGradient(colors: [Color(hex: 0xE7C069), Color(hex: 0xA9822C)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(height: 2.5)
            .accessibilityHidden(true)
    }

    private func draw(_ context: inout GraphicsContext, size: CGSize) {
        guard !days.isEmpty else { return }
        let slot = size.width / CGFloat(days.count)
        let top: CGFloat = 3
        let usable = size.height - top - 6
        let today = Calendar.current.startOfDay(for: .now)

        for (index, day) in days.enumerated() {
            let x0 = CGFloat(index) * slot
            let isToday = day.day == today
            // Each day is cut at whatever grain the ladder has opened: one gate, or two, or
            // four, or twenty-four — until the cells are too fine to see, when the day goes
            // back to one. An hour cut into a week is noise; into half a year it is a person.
            let cells = day.cells.count
            let cellWidth = slot / CGFloat(cells)
            let showCells = cells > 1 && cellWidth >= 1.4
            // A cut is wood taken out, so the pigment is carried down into the walnut of the
            // trough rather than painted on the wall. Painted at full strength the strip read
            // as a bar chart in the counter's colour, which is the thing this app is not.
            let colour = isToday ? brand.palette.accent
                                 : (day.waxed ? brand.palette.miss : pigment.mix(with: brand.palette.ink, amount: 0.42))

            if showCells {
                for (c, count) in day.cells.enumerated() where count > 0 {
                    let depth = usable * min(1, CGFloat(count) / CGFloat(peak))
                    let rect = CGRect(x: x0 + CGFloat(c) * cellWidth + 0.2, y: top,
                                      width: max(0.8, cellWidth - 0.4), height: max(2, depth))
                    context.fill(Path(rect), with: .color(colour.opacity(0.85)))
                }
            } else if day.count > 0 {
                let depth = usable * min(1, CGFloat(day.count) / CGFloat(peak))
                let width = max(1.6, min(9, slot - 1.6))
                let rect = CGRect(x: x0 + (slot - width) / 2, y: top, width: width, height: max(3, depth))
                // A cut, not a bar: the near facet is in shadow and the far one catches the
                // window, which is what makes the strip read as notched rather than plotted.
                context.fill(Path(rect), with: .color(colour.opacity(0.88)))
                let lip = CGRect(x: rect.maxX - width * 0.34, y: top, width: width * 0.34, height: rect.height)
                context.fill(Path(lip), with: .color(.white.opacity(scheme == .dark ? 0.10 : 0.22)))
            } else {
                // A gap in the strip is a gap, and that is the truth. It is not an accusation.
                let dot = CGRect(x: x0 + slot / 2 - 0.75, y: top, width: 1.5, height: 1.5)
                context.fill(Path(dot), with: .color(brand.palette.ink.opacity(0.16)))
            }
        }
    }

    /// One element per day, so VoiceOver reads "Tuesday the 4th, nine" instead of skipping
    /// the chart entirely.
    private var labels: some View {
        HStack(spacing: 0) {
            ForEach(days) { day in
                Color.clear
                    .accessibilityElement()
                    .accessibilityLabel("\(day.day.formatted(.dateTime.weekday(.wide).day(.ordinalOfDayInMonth))), \(Bench.spelled(day.count))")
            }
        }
    }
}

/// The hour band: when in a day the cuts land, across everything the strip reaches back over.
/// It arrives with the ladder's `grain`, and it is the thing that cannot be faked early.
struct HourBand: View {
    let hours: [Int]
    let pigment: Color

    @Environment(\.brand) private var brand

    var body: some View {
        let peak = max(1, hours.max() ?? 1)
        HStack(alignment: .bottom, spacing: 1.5) {
            ForEach(hours.indices, id: \.self) { hour in
                Rectangle()
                    .fill(pigment.opacity(hours[hour] == 0 ? 0.12 : 0.30 + 0.55 * Double(hours[hour]) / Double(peak)))
                    .frame(height: max(2, 26 * CGFloat(hours[hour]) / CGFloat(peak)))
            }
        }
        .frame(height: 26)
        .accessibilityElement()
        .accessibilityLabel("Cuts by hour of the day")
    }
}

/// The spec's goal ring, rebuilt as the thing a bench would actually have: a ruled brass
/// scale with a chalk line at the goal, filling as the day's cuts land.
struct BrassGauge: View {
    let today: Int
    let goal: Int

    @Environment(\.brand) private var brand

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            // Room past the line, so reaching it is a place on the scale and not the end of it.
            let scale = CGFloat(max(goal, today)) * 1.15
            let fill = width * min(1, CGFloat(today) / max(1, scale))
            let line = width * min(1, CGFloat(goal) / max(1, scale))
            ZStack(alignment: .leading) {
                Rectangle().fill(brand.palette.ink.opacity(0.14))
                Rectangle()
                    .fill(today >= goal ? brand.palette.success : brand.palette.success.opacity(0.75))
                    .frame(width: fill)
                ticks(width: width, scale: scale)
                Rectangle()
                    .fill(brand.palette.accent)
                    .frame(width: 2)
                    .offset(x: line - 1)
                Rectangle()
                    .fill(LinearGradient(colors: [Color(hex: 0xE7C069), Color(hex: 0xA9822C)],
                                         startPoint: .leading, endPoint: .trailing))
                    .frame(height: 1.5)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
        }
        .frame(height: 13)
        .accessibilityElement()
        .accessibilityLabel("\(today) of \(goal) today")
    }

    private func ticks(width: CGFloat, scale: CGFloat) -> some View {
        Canvas { context, size in
            let step = max(1, Int((Double(scale) / 10).rounded()))
            var value = step
            while CGFloat(value) < scale {
                let x = width * CGFloat(value) / scale
                context.fill(Path(CGRect(x: x, y: size.height * 0.45, width: 1, height: size.height * 0.55)),
                             with: .color(brand.palette.ink.opacity(0.22)))
                value += step
            }
        }
        .accessibilityHidden(true)
    }
}

/// The rack behind the bench: every scored stave standing on its rail, oldest at the back,
/// each with its pigment band and the date it was closed on. It arrives at one stave scored
/// and it is not for sale.
struct RackRail: View {
    let dates: [Date]
    let pigment: Color
    let oiled: Bool
    /// The stave that has just arrived glows for a moment.
    var glowing: Bool = false

    @Environment(\.brand) private var brand

    private var shown: [Date] { Array(dates.suffix(14)) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(shown.enumerated()), id: \.offset) { index, date in
                    staveInRack(index: index, date: date, last: index == shown.count - 1)
                }
                Spacer(minLength: 0)
            }
            Rectangle()
                .fill(LinearGradient(colors: [Color(hex: 0xE7C069), Color(hex: 0xA9822C)],
                                     startPoint: .leading, endPoint: .trailing))
                .frame(height: 3)
        }
        .accessibilityElement()
        .accessibilityLabel("\(dates.count) scored \(dates.count == 1 ? "stave" : "staves") in the rack")
    }

    private func staveInRack(index: Int, date: Date, last: Bool) -> some View {
        // A seeded height, so the rack reads as a row of real boards rather than a bar chart.
        var rng = Seeded(seed: UInt64(index) &+ 0x5A1E)
        let height = 58 + CGFloat(rng.unit()) * 16
        let board = oiled ? brand.palette.surface.mix(with: brand.palette.ink, amount: 0.22)
                          : brand.palette.surface
        return VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(pigment)
                .frame(height: 6)
            ZStack {
                Rectangle().fill(board)
                // Fifty notches seen end on: ten gates of tight marks with the scoring stroke
                // cut across the lot. A scored stave has to look scored, or the rack is a row
                // of blank tiles.
                Canvas { context, size in
                    for gate in 0..<10 {
                        let y = 5 + CGFloat(gate) * (size.height - 10) / 10
                        for mark in 0..<4 {
                            let x = 3 + CGFloat(mark) * (size.width - 7) / 4
                            context.fill(Path(CGRect(x: x, y: y, width: 1, height: 3.4)),
                                         with: .color(brand.palette.ink.opacity(0.20)))
                        }
                    }
                    var score = Path()
                    score.move(to: CGPoint(x: 2, y: size.height - 6))
                    score.addLine(to: CGPoint(x: size.width - 2, y: 6))
                    context.stroke(score, with: .color(brand.palette.ink.opacity(0.55)), lineWidth: 1.4)
                }
                // The date the stave was closed on, read down the board the way a marking on
                // wood is read.
                Text(date.formatted(.dateTime.day().month(.abbreviated)))
                    .stencilCaps()
                    .foregroundStyle(brand.palette.inkSoft)
                    .lineLimit(1)
                    .fixedSize()
                    .rotationEffect(.degrees(-90))
                    .frame(width: 18, height: height)
            }
            .frame(height: height)
            .clipped()
        }
        .frame(width: 18)
        .shadow(color: glowing && last ? brand.palette.highlight.opacity(0.8) : .clear, radius: 9)
    }
}
