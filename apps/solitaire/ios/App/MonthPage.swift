import FactoryKit
import SwiftUI

/// One month on card stock: the running head, a slot per day carrying the card that day's deal
/// had to dig for, today ringed in brass, the week's shape, and the hem. Reused at a fixed size
/// by the share card.
struct MonthPage: View {
    let month: Date            // any day in the month
    let record: Record
    let today: Int
    var compact = false
    var selected: Int? = nil
    var onSelect: ((Int) -> Void)? = nil

    @Environment(\.brand) private var brand
    private let ink = AppBrand.CardBox.ink

    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.firstWeekday = 2
        return c
    }

    /// Day numbers (Play.dayNumber) of every day of the month, with leading blanks for Monday-first.
    private var grid: [Int?] {
        let first = cal.date(from: cal.dateComponents([.year, .month], from: month))!
        let count = cal.range(of: .day, in: .month, for: first)!.count
        let lead = (cal.component(.weekday, from: first) + 5) % 7
        let start = Play.dayNumber(first)
        return Array(repeating: nil, count: lead) + (0..<count).map { start + $0 }
    }

    var body: some View {
        let pad: CGFloat = compact ? 14 : 20
        VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            HStack(alignment: .lastTextBaseline) {
                Text(monthName)
                    .brandDisplay(size: compact ? 26 : 40)
                    .foregroundStyle(ink)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer()
                Text(year)
                    .font(.caption2.weight(.medium)).textCase(.uppercase).tracking(2)
                    .foregroundStyle(ink.opacity(0.6))
            }
            Rectangle().fill(ink.opacity(0.18)).frame(height: 1)
            GeometryReader { geo in
                let w = (geo.size.width - 6 * 6) / 7
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        ForEach(Array(["M", "T", "W", "T", "F", "S", "S"].enumerated()), id: \.offset) { _, d in
                            Text(d).font(.caption2.weight(.medium)).foregroundStyle(ink.opacity(0.55))
                                .frame(width: w)
                        }
                    }
                    let cells = grid
                    ForEach(0..<((cells.count + 6) / 7), id: \.self) { row in
                        HStack(spacing: 6) {
                            ForEach(0..<7, id: \.self) { col in
                                let i = row * 7 + col
                                if i < cells.count, let day = cells[i] {
                                    slot(day: day, width: w)
                                } else {
                                    Color.clear.frame(width: w, height: w * 1.4)
                                }
                            }
                        }
                    }
                }
            }
            .frame(height: gridHeight)
            weekShape
            Rectangle().fill(ink.opacity(0.18)).frame(height: 1)
            HStack {
                Text(hem)
                    .font(.caption2.weight(.medium)).textCase(.uppercase).tracking(compact ? 1 : 2)
                    .foregroundStyle(ink.opacity(0.65))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                if record.sealed { SealMark(size: compact ? 16 : 22) }
            }
        }
        .padding(pad)
        .background(AppBrand.CardBox.stock, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(record.gilt ? brand.palette.accent : ink.opacity(0.12), lineWidth: record.gilt ? 1.2 : 0.5)
        }
        .environment(\.dynamicTypeSize, .large)
    }

    /// The grid's height for the page's width, so a page can sit in a pager.
    private var gridHeight: CGFloat {
        let rows = CGFloat((grid.count + 6) / 7)
        return 20 + rows * (slotWidth * 1.4 + 6)
    }
    var pageWidth: CGFloat = 0
    private var slotWidth: CGFloat {
        let inner = (pageWidth > 0 ? pageWidth : (compact ? 324 : 361)) - (compact ? 28 : 40)
        return (inner - 36) / 7
    }

    @ViewBuilder
    private func slot(day: Int, width w: CGFloat) -> some View {
        let e = record.entry(forDay: day)
        let isToday = day == today
        let shape = RoundedRectangle(cornerRadius: w * 0.08, style: .continuous)
        Button {
            onSelect?(day)
        } label: {
            ZStack(alignment: .topLeading) {
                if let e {
                    CardFace(card: e.buried, width: w)
                        .shadow(color: ink.opacity(0.18), radius: 1.5, y: 1)
                        .overlay(alignment: .topTrailing) {
                            if e.isClean {
                                Circle().fill(AppBrand.CardBox.green).frame(width: 6, height: 6).offset(x: -3, y: 3)
                            }
                        }
                } else {
                    shape.strokeBorder(ink.opacity(0.12), lineWidth: 1).frame(width: w, height: w * 1.4)
                    Text(dayOfMonth(day))
                        .font(.caption2.weight(.medium))
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(ink.opacity(0.45))
                        .padding(.leading, 4).padding(.top, 3)
                }
            }
            .frame(width: w, height: w * 1.4)
            .overlay {
                if isToday || selected == day {
                    shape.inset(by: -2.5).strokeBorder(selected == day && !isToday ? ink.opacity(0.4) : brand.palette.accent, lineWidth: 1.5)
                }
            }
            .overlay(alignment: .bottom) {
                if e?.underMark == true {
                    Capsule().fill(AppBrand.CardBox.brassDeep).frame(width: w * 0.8, height: 2).offset(y: 6)
                }
            }
        }
        .buttonStyle(.pressable(scale: 0.94))
        .disabled(onSelect == nil)
        .accessibilityLabel(slotLabel(day: day, entry: e))
    }

    private func slotLabel(day: Int, entry e: Entry?) -> String {
        let date = Voice.shortDate(Play.date(ofDay: day))
        guard let e else { return date }
        let how = e.isClean ? "came out clean" : "came out"
        return "\(date), \(how) in \(e.moves) moves, \(e.buried.name)"
    }

    private var weekShape: some View {
        let grades = Play.dailyWeek.map { Play.dials(at: $0).grade }
        let names = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        return VStack(spacing: 4) {
            Text(zip(names, grades).map { "\($0) \($1)" }.joined(separator: " · "))
            Text("Draw one to Wednesday · draw three from Thursday")
        }
        .font(.caption2.weight(.medium)).textCase(.uppercase).tracking(compact ? 0.8 : 1.6)
        .foregroundStyle(ink.opacity(0.6))
        .lineLimit(1)
        .minimumScaleFactor(0.6)
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("The week: Monday grade one, rising to Sunday grade nine. Draw one to Wednesday, draw three from Thursday.")
    }

    private var hem: String {
        "\(record.entries.count) entries · \(record.daysRunning(today: today)) days running · \(record.clean) clean"
    }

    private var monthName: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_GB"); f.dateFormat = "MMMM"
        return f.string(from: month)
    }

    private var year: String {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_GB"); f.dateFormat = "yyyy"
        return f.string(from: month)
    }

    private func dayOfMonth(_ day: Int) -> String {
        String(cal.component(.day, from: Play.date(ofDay: day)))
    }
}
