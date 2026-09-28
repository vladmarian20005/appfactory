import FactoryKit
import SwiftUI

/// Today's lace, once it is in the sampler. What the day was for is done, and the screen says
/// so first: the piece, how it went, the days running and when the next one is pricked. Only
/// under that, for anyone who wants more today, the book.
struct DoneToday: View {
    @Binding var tab: RootView.Tab
    @EnvironmentObject private var bench: Bench
    @Environment(\.brand) private var brand

    private var record: Record { bench.record }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .lastTextBaseline) {
                    Text("Today's lace · No. \(bench.todayNumber)").caps()
                    Spacer(minLength: 8)
                    Text(Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))).caps()
                }
                if let piece = bench.todayPiece {
                    PillowBolster {
                        PieceCard(piece: piece, size: 200)
                            .padding(.vertical, 8)
                    }
                    VStack(alignment: .leading, spacing: 6) {
                        Text(Voice.headline(piece.runTier, unpicks: piece.unpicks))
                            .brandDisplay(size: 28, relativeTo: .title)
                            .foregroundStyle(brand.palette.highlight)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Done for today. Everybody who opens Lacework today works this same lace.")
                            .font(.body.italic())
                            .foregroundStyle(brand.palette.inkSoft)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    days
                    SwatchShareLink(piece: piece, record: record, wide: true)
                }
                PinRule()
                more
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 32)
        }
    }

    // MARK: - The days

    /// Days running at the left; at the right, how long until the next lace is pricked.
    private var days: some View {
        let running = record.daysRunning()
        let tomorrow = Play.dials(at: Play.dailyRung(day: Play.dayNumber() + 1)).side
        return VStack(alignment: .leading, spacing: 12) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top) {
                    daysRunning(running)
                    Spacer(minLength: 12)
                    NextLace(alignment: .trailing)
                }
                VStack(alignment: .leading, spacing: 14) {
                    daysRunning(running)
                    NextLace(alignment: .leading)
                }
            }
            Text("Tomorrow's is \(Words.size(tomorrow)).")
                .font(.subheadline)
                .foregroundStyle(brand.palette.inkSoft)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .brandSurface(padding: 18)
    }

    private func daysRunning(_ n: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("\(n)")
                .brandDisplay(size: 44)
                .foregroundStyle(brand.palette.ink)
                .monospacedDigit()
            Text(n == 1 ? "Day running" : "Days running").caps()
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(n) \(n == 1 ? "day" : "days") running")
    }

    // MARK: - More, for anyone who wants it

    private var more: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Want more?").brandFont(.title2).foregroundStyle(brand.palette.ink)
            MoreRow(title: "The pattern book",
                    detail: bookDetail,
                    mark: bench.bookOpen ? nil : "Unlock") {
                bench.pinNext()
            }
        }
    }

    private var bookDetail: String {
        let d = Play.dials(at: record.rung)
        if !bench.bookOpen { return "Your three free patterns are worked. One payment opens the rest of the book." }
        if bench.hasBook { return "Pattern \(record.rung) is next: \(Words.size(d.side))." }
        return "Pattern \(record.rung) is next: \(Words.size(d.side)). \(Words.capitalised(bench.freeLeft)) of three free."
    }
}

/// A row to more lace: a title, a line, and a mark for what needs the unlock.
struct MoreRow: View {
    let title: String
    let detail: String
    var mark: String?
    let action: () -> Void
    @Environment(\.brand) private var brand

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title).font(.headline).foregroundStyle(brand.palette.ink)
                        if let mark {
                            Text(mark).caps(.caption2, tracking: 1.5)
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .overlay(Capsule().strokeBorder(brand.palette.ink.opacity(0.3), lineWidth: 0.75))
                        }
                    }
                    Text(detail)
                        .font(.subheadline)
                        .foregroundStyle(brand.palette.inkSoft)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(brand.palette.inkSoft)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(brand.palette.surface.opacity(0.8), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.pressable(scale: 0.98))
    }
}

/// "Next lace in 7 h 12 min", to the minute. It changes once a minute, so a capture still
/// settles.
struct NextLace: View {
    var alignment: HorizontalAlignment = .trailing
    @Environment(\.brand) private var brand

    var body: some View {
        TimelineView(.periodic(from: .now, by: 60)) { ctx in
            let next = Calendar.current.date(byAdding: .day, value: 1,
                                             to: Calendar.current.startOfDay(for: ctx.date)) ?? ctx.date
            let minutes = max(0, Int(next.timeIntervalSince(ctx.date) / 60))
            VStack(alignment: alignment, spacing: 2) {
                Text(minutes >= 60 ? "\(minutes / 60) h \(minutes % 60) min" : "\(minutes) min")
                    .brandFont(.title2)
                    .foregroundStyle(brand.palette.ink)
                    .monospacedDigit()
                Text("Until the next lace").caps()
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("The next lace is pricked in \(minutes / 60) hours and \(minutes % 60) minutes")
        }
    }
}
