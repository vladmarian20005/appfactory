import FactoryKit
import SwiftUI

/// Past days: every day's lace since No. 1, the same ones everybody had. A day worked shows its
/// piece; a day not worked shows its number, and opens it over Today — with the unlock.
struct ArchiveView: View {
    @EnvironmentObject private var bench: Bench
    @Environment(\.brand) private var brand

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(bench.archiveOpen
                     ? "Every day's lace since No. 1. Work the ones you missed; days running only count on the day."
                     : "Every day's lace since No. 1. The past ones open with the whole book; today's is always free.")
                    .font(.subheadline)
                    .foregroundStyle(brand.palette.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
                ForEach(months, id: \.first) { days in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(Play.date(ofDay: days[0]).formatted(.dateTime.month(.wide).year()))
                            .brandFont(.title3)
                            .foregroundStyle(brand.palette.ink)
                        PastDaysGrid(days: days)
                    }
                }
            }
            .padding(16)
        }
        .linen(ticking: bench.record.ticking)
        .navigationTitle("Past days")
        .navigationBarTitleDisplayMode(.inline)
    }

    /// Past days, newest first, in runs of one calendar month.
    private var months: [[Int]] {
        var out: [[Int]] = []
        let cal = Calendar.current
        for d in Play.pastDays() {
            let m = cal.component(.month, from: Play.date(ofDay: d))
            if let last = out.last?.first, cal.component(.month, from: Play.date(ofDay: last)) == m {
                out[out.count - 1].append(d)
            } else {
                out.append([d])
            }
        }
        return out
    }
}

/// Past days as small cards, five to a row.
struct PastDaysGrid: View {
    let days: [Int]
    @EnvironmentObject private var bench: Bench

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 12) {
            ForEach(days, id: \.self) { d in
                if let piece = bench.record.piece(forLace: d) {
                    NavigationLink(value: piece) { PastDayCell(day: d, piece: piece) }
                        .buttonStyle(.pressable)
                        .accessibilityLabel("Lace number \(Play.dailyNumber(day: d)), worked")
                } else {
                    Button {
                        Haptics.tap()
                        bench.show(.past(d))
                    } label: {
                        PastDayCell(day: d, piece: nil)
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel("Lace number \(Play.dailyNumber(day: d)), \(Play.date(ofDay: d).formatted(.dateTime.weekday(.wide).day().month(.wide))), not worked")
                    .accessibilityHint(bench.archiveOpen ? "Opens it on the pillow" : "Opens with the whole book")
                }
            }
        }
    }
}

/// One past day: its piece if worked, else its number on bare parchment.
struct PastDayCell: View {
    let day: Int
    let piece: Piece?
    @EnvironmentObject private var bench: Bench
    @Environment(\.brand) private var brand

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(brand.palette.surface)
                    .shadow(color: .black.opacity(0.08), radius: 3, x: 1, y: 2)
                if let piece {
                    SmallLace(piece: piece, size: 44)
                } else {
                    VStack(spacing: 1) {
                        Text("\(Play.dailyNumber(day: day))")
                            .brandFont(.headline)
                            .foregroundStyle(brand.palette.ink.opacity(bench.archiveOpen ? 0.85 : 0.45))
                        let side = Play.dials(at: Play.dailyRung(day: day)).side
                        Text("\(side)×\(side)")
                            .font(.caption2)
                            .foregroundStyle(brand.palette.inkSoft.opacity(0.7))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                }
            }
            .frame(height: 54)
            Text(Play.date(ofDay: day).formatted(.dateTime.day().month(.abbreviated)))
                .caps(.caption2, tracking: 1)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
    }
}
