import FactoryKit
import SwiftUI

/// Screen 2 · Progress. The pieces, and the days.
struct SamplerView: View {
    @Binding var tab: RootView.Tab
    @EnvironmentObject private var bench: Bench
    @Environment(\.brand) private var brand
    @State private var reminderOn = false
    @State private var hour = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: .now) ?? .now

    private var record: Record { bench.record }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if record.hasEarned("year") { yearCloth }
                    if record.pieces.isEmpty {
                        bare
                    } else {
                        hero
                        cloth
                    }
                    MonthCard(record: record)
                    reminder
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .linen(ticking: record.ticking)
            .navigationTitle("The sampler")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let last = record.pieces.last {
                    ToolbarItem(placement: .topBarTrailing) {
                        SwatchShareLink(piece: last, record: record, compact: true)
                    }
                }
            }
            .navigationDestination(for: Piece.self) { PieceView(piece: $0) }
            .onAppear { reminderOn = record.reminderHour != nil }
        }
    }

    // MARK: - The hero

    /// Pieces worked at 112, with today's piece beside it.
    private var hero: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: 12) {
                count
                Spacer(minLength: 0)
                today
            }
            VStack(alignment: .leading, spacing: 12) {
                count
                today
            }
        }
    }

    private var count: some View {
        VStack(alignment: .leading, spacing: 0) {
            CountUp(to: record.pieces.count, duration: 0.7)
                .brandDisplay(size: 112)
                .foregroundStyle(brand.palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(record.pieces.count == 1 ? "Piece" : "Pieces").caps(.caption, tracking: 3)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(record.pieces.count) pieces in the sampler")
    }

    @ViewBuilder
    private var today: some View {
        if let piece = bench.todayPiece {
            NavigationLink(value: piece) {
                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .trailing, spacing: 6) {
                        Text("Today · \(Words.size(piece.side)) · \(piece.ground.name) ground")
                            .caps()
                            .multilineTextAlignment(.trailing)
                        Text(Voice.headline(piece.runTier, unpicks: piece.unpicks))
                            .brandFont(.title3)
                            .foregroundStyle(brand.palette.highlight)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(3)
                    }
                    .frame(maxWidth: 170, alignment: .trailing)
                    PieceCard(piece: piece, size: 104)
                }
            }
            .buttonStyle(.pressable)
            .accessibilityLabel("Today's piece, \(Words.size(piece.side)), the \(piece.ground.name) ground")
        } else {
            VStack(alignment: .trailing, spacing: 10) {
                Text("Today's pattern").caps()
                Button {
                    Haptics.tap()
                    bench.backToToday()
                    tab = .pillow
                } label: {
                    Text(record.todayPillow?.isEmpty == false ? "Back to the pillow" : "Pick up the bobbin")
                        .font(.headline)
                }
                .brandProminent()
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, 24)
        }
    }

    // MARK: - The cloth

    /// Every piece he has worked as a small lace, in rows of five, newest first, on a hemmed
    /// sheet of parchment. At five hundred pieces it is a long scroll of small laces.
    private var cloth: some View {
        let pieces = Array(record.pieces.reversed())
        return VStack(spacing: 16) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 5), spacing: 14) {
                ForEach(pieces) { piece in
                    NavigationLink(value: piece) {
                        VStack(spacing: 6) {
                            SmallLace(piece: piece, size: 52)
                            Text(piece.mark).caps(.caption2, tracking: 1.2).lineLimit(1).minimumScaleFactor(0.7)
                        }
                    }
                    .buttonStyle(.pressable)
                    .accessibilityLabel(pieceLabel(piece))
                }
            }
            Text(hem).caps(.caption2, tracking: 2).multilineTextAlignment(.center)
        }
        .padding(18)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(brand.palette.surface)
                .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 5)
        }
        .overlay {
            // The hem: a hairline eight points in, all round.
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(brand.palette.ink.opacity(0.2), lineWidth: 1)
                .padding(8)
                .allowsHitTesting(false)
        }
    }

    /// What remembers you, instead of a streak.
    private var hem: String {
        var parts = ["\(record.pieces.count) \(record.pieces.count == 1 ? "piece" : "pieces")"]
        let days = record.daysRunning()
        if days > 0 { parts.append("\(days) \(days == 1 ? "day" : "days") running") }
        if record.largestSide > 0 { parts.append("Largest \(record.largestSide) × \(record.largestSide)") }
        return parts.joined(separator: " · ")
    }

    private func pieceLabel(_ p: Piece) -> String {
        "Piece \(p.id), \(Words.size(p.side)), the \(p.ground.name) ground, \(p.isClean ? "worked clean" : "picked out \(Words.times(p.unpicks))")"
    }

    private var yearCloth: some View {
        VStack(spacing: 6) {
            Image("Lace")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 150)
                .accessibilityHidden(true)
            Text("The first cloth · hemmed and hung").caps()
        }
        .frame(maxWidth: .infinity)
    }

    private var bare: some View {
        VStack(spacing: 14) {
            Image("Pillow")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 280)
                .ambientFloat(distance: 4, period: 4.4)
                .accessibilityHidden(true)
            Text("The sampler is bare")
                .brandFont(.largeTitle)
                .foregroundStyle(brand.palette.ink)
            Text("Today's pattern is pricked and pinned on the pillow. The first piece goes here.")
                .font(.title3)
                .foregroundStyle(brand.palette.inkSoft)
                .multilineTextAlignment(.center)
            Button {
                Haptics.tap()
                bench.backToToday()
                tab = .pillow
            } label: {
                Text("To the pillow").font(.headline).frame(maxWidth: .infinity).padding(.vertical, 4)
            }
            .brandProminent()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - The reminder

    private var reminder: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Pin a reminder", isOn: $reminderOn)
                .foregroundStyle(brand.palette.ink)
                .onChange(of: reminderOn) { _, on in setReminder(on) }
            if reminderOn {
                DatePicker("At", selection: $hour, displayedComponents: .hourAndMinute)
                    .foregroundStyle(brand.palette.inkSoft)
                    .onChange(of: hour) { _, _ in setReminder(true) }
            }
        }
        .padding(16)
        .background(brand.palette.surface.opacity(0.7), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func setReminder(_ on: Bool) {
        if on {
            let h = Calendar.current.component(.hour, from: hour)
            Task {
                let ok = await Reminder.pin(hour: h)
                bench.setReminder(ok ? h : nil)
                if !ok { reminderOn = false }
            }
        } else {
            Reminder.cancel()
            bench.setReminder(nil)
        }
    }
}

/// A piece on its own square of parchment.
struct PieceCard: View {
    let piece: Piece
    var size: CGFloat
    @Environment(\.brand) private var brand

    var body: some View {
        SmallLace(piece: piece, size: size * 0.86)
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(brand.palette.surface)
                    .shadow(color: .black.opacity(0.14), radius: 6, x: 2, y: 4)
            }
            .rotationEffect(.degrees(1.5))
    }
}

/// The month as a pricking card: a prick for every day, a pin in that day's thread for a
/// day worked, today ringed. A day not worked is a prick with no pin — nothing more.
struct MonthCard: View {
    let record: Record
    @Environment(\.brand) private var brand

    var body: some View {
        let cal = Calendar.current
        let now = Date.now
        let interval = cal.dateInterval(of: .month, for: now)!
        let first = interval.start
        let days = cal.range(of: .day, in: .month, for: now)!.count
        // Monday first.
        let lead = (cal.component(.weekday, from: first) + 5) % 7
        let today = Play.dayNumber(now)
        let firstDay = Play.dayNumber(first)
        var threads: [Int: ThreadColour] = [:]
        for p in record.pieces where p.day >= firstDay && p.day < firstDay + days { threads[p.day] = p.thread }
        let pinned = threads.count

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                Text(now.formatted(.dateTime.month(.wide)))
                    .brandFont(.title)
                    .foregroundStyle(brand.palette.ink)
                Spacer()
                Text(pinned == 0 ? "" : "\(Words.number(pinned)) pinned").caps()
            }
            if pinned == 0 {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Nothing pinned this month yet").font(.headline).foregroundStyle(brand.palette.ink)
                    Text("A day you work a piece gets a pin here.").font(.subheadline).foregroundStyle(brand.palette.inkSoft)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 18) {
                ForEach(0..<(lead + days), id: \.self) { i in
                    if i < lead {
                        Color.clear.frame(height: 14)
                    } else {
                        let day = firstDay + i - lead
                        ZStack {
                            if let t = threads[day] {
                                PinHead(color: t.color, size: 9)
                            } else {
                                Circle().fill(brand.palette.ink.opacity(0.18)).frame(width: 3.5, height: 3.5)
                            }
                            if day == today {
                                Circle().stroke(brand.palette.accent, lineWidth: 1.5).frame(width: 22, height: 22)
                            }
                        }
                        .frame(height: 22)
                        .accessibilityElement()
                        .accessibilityLabel("\(i - lead + 1)\(threads[day] != nil ? ", a piece worked" : "")\(day == today ? ", today" : "")")
                    }
                }
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(brand.palette.surface)
                .shadow(color: .black.opacity(0.07), radius: 12, x: 0, y: 5)
        }
    }
}

/// One piece, full size on parchment, with its line.
struct PieceView: View {
    let piece: Piece
    @EnvironmentObject private var bench: Bench
    @Environment(\.brand) private var brand

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("\(piece.isToday ? "Today's pattern" : piece.mark) · \(Play.date(ofDay: piece.day).formatted(.dateTime.day().month(.wide)))")
                    .caps()
                PillowBolster {
                    PieceCard(piece: piece, size: 300)
                        .padding(.vertical, 6)
                }
                Text(Voice.headline(piece.runTier, unpicks: piece.unpicks))
                    .brandDisplay(size: 28, relativeTo: .title)
                    .foregroundStyle(brand.palette.highlight)
                Text("\(Words.capitalised(piece.pins)) pins, \(Words.size(piece.side)), the \(piece.ground.name) ground. The longest thread was \(Words.number(piece.longestThread)).")
                    .foregroundStyle(brand.palette.inkSoft)
                SwatchShareLink(piece: piece, record: bench.record)
            }
            .padding(16)
        }
        .linen(ticking: bench.record.ticking)
        .navigationTitle("Piece \(piece.id)")
        .navigationBarTitleDisplayMode(.inline)
    }
}
