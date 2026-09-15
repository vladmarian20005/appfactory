import FactoryKit
import SwiftUI

/// The line: today's plate, everything pulled, and the run of days. What remembers her, and
/// it is shown unasked — no flame, no number that goes back to zero, and nothing anywhere
/// that mentions a day she did not play.
struct LineView: View {
    @ObservedObject var bench: Bench
    @Binding var showPaywall: Bool
    @Binding var tab: RootView.Tab
    @Environment(\.brand) private var brand

    private var pulls: [Pull] { bench.record.pulls.reversed() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    hero
                    today
                    dayBook
                    caps
                }
                .padding(.horizontal, 14)
                .padding(.top, 4)
                .padding(.bottom, 30)
            }
            .shopBackground()
            .navigationTitle("The line")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if let image = shareCard, let pull = bench.record.pulls.last {
                        ShareLink(item: image, preview: SharePreview("Plate \(pull.number)", image: image)) {
                            Image(systemName: "square.and.arrow.up")
                                .accessibilityLabel("Send the margin")
                        }
                    }
                }
            }
        }
    }

    // MARK: The hero, and the prints on the cord

    private var hero: some View {
        VStack(spacing: -22) {
            VStack(spacing: 0) {
                Text("Plates pulled")
                    .plateCaps(size: 10)
                    .foregroundStyle(brand.palette.inkSoft)
                Text("\(bench.record.platesPulled)")
                    .brandDisplay(size: 108)
                    .foregroundStyle(brand.palette.ink)
                    .accessibilityLabel("\(bench.record.platesPulled) plates pulled")
            }
            if pulls.isEmpty {
                emptyLine
            } else {
                dryingLine
            }
        }
    }

    /// Prints pegged on a cord to dry, newest at the left.
    private var dryingLine: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .top, spacing: 9) {
                ForEach(Array(pulls.prefix(24).enumerated()), id: \.element.number) { index, pull in
                    VStack(spacing: 0) {
                        Lozenge()
                            .fill(brand.palette.highlight)
                            .frame(width: 13, height: 8)
                            .zIndex(1)
                        PrintSheet(pull: pull, compact: true, ink: stock(pull))
                            .frame(width: 96, height: 132)
                            .rotationEffect(.degrees(index % 2 == 0 ? -1.4 : 1.1))
                    }
                    .popIn(delay: Double(index) * 0.03)
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 6)
        }
        .background(alignment: .top) {
            Rectangle()
                .fill(brand.palette.highlight.opacity(0.75))
                .frame(height: 1.5)
                .padding(.top, 10)
        }
    }

    /// Chine-collé, earned at seventy-five: every print carries the colour of its day, so a
    /// year on the line reads as a calendar.
    private func stock(_ pull: Pull) -> Color? {
        guard bench.record.hasEarned("chine") else { return nil }
        let inks = brand.palette.extras
        return inks.isEmpty ? nil : inks[pull.ink % inks.count]
    }

    private var emptyLine: some View {
        VStack(spacing: 16) {
            Image("Press")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 190)
                .ambientFloat(distance: 3, period: 4.2)
            Text("The line is empty")
                .brandFont(.title)
                .foregroundStyle(brand.palette.ink)
            Text("The press is wound back, there is damp paper under the board, and today's plate is already on the bed.")
                .brandFont(.callout, weight: .regular)
                .foregroundStyle(brand.palette.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 26)
        .padding(.horizontal, 12)
    }

    // MARK: Today

    @ViewBuilder
    private var today: some View {
        if let pull = bench.todaysPull {
            VStack(alignment: .leading, spacing: 10) {
                Text("Today's is on the line")
                    .brandFont(.title2)
                    .foregroundStyle(brand.palette.ink)
                PrintSheet(pull: pull, ink: stock(pull))
                Text("The next plate in your own run is ruled and waiting on the bench.")
                    .brandFont(.callout, weight: .regular)
                    .foregroundStyle(brand.palette.inkSoft)
                Button {
                    if bench.runIsLocked { showPaywall = true } else { bench.rule(daily: false); tab = .bed }
                } label: {
                    Text("Rule the next plate")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .brandProminent()
            }
        } else {
            HStack(spacing: 14) {
                PlatePortrait(seed: bench.session?.plate.number ?? 214, side: 76)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Today  ·  \(dated)")
                        .plateCaps(size: 9.5)
                        .foregroundStyle(brand.palette.inkSoft)
                    Text(bench.session?.isDaily == true ? bench.session?.plate.title ?? "Today's plate" : "Today's plate")
                        .brandFont(.title3)
                        .foregroundStyle(brand.palette.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
                Button {
                    bench.openBed(daily: true)
                    tab = .bed
                } label: {
                    Text(started ? "Back to the bed" : "Set it on the bed")
                        .font(.headline)
                        .padding(.vertical, 2)
                }
                .brandProminent()
            }
            .padding(14)
            .background {
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(brand.palette.surface)
                    .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
            }
        }
    }

    private var started: Bool {
        (bench.record.dailyBed?.actions.isEmpty == false) || (bench.session?.isDaily == true && bench.session?.hasCut == true)
    }

    private var dated: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: .now)
    }

    // MARK: The day-book

    /// The month as a page of the shop's day-book. A day pulled carries a filled lozenge in
    /// that plate's lead cast ink; today is ringed with the registration cross in it; a day
    /// missed is simply an empty square — no grey, no red, no mark at all.
    private var dayBook: some View {
        let calendar = Calendar.current
        let today = Date()
        let month = calendar.dateInterval(of: .month, for: today) ?? DateInterval(start: today, duration: 0)
        let days = calendar.range(of: .day, in: .month, for: today)?.count ?? 30
        let firstWeekday = (calendar.component(.weekday, from: month.start) + 5) % 7
        let inked = bench.record.pulls.filter { calendar.isDate($0.date, equalTo: today, toGranularity: .month) }
        let byDay = Dictionary(inked.map { (calendar.component(.day, from: $0.date), $0) }, uniquingKeysWith: { a, _ in a })

        return VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(monthName)
                    .brandFont(.title2)
                    .foregroundStyle(brand.palette.ink)
                Spacer(minLength: 0)
                Text("\(Spelled.out(inked.count)) inked")
                    .plateCaps(size: 9.5)
                    .foregroundStyle(brand.palette.inkSoft)
            }
            HStack(spacing: 4) {
                ForEach(Array(["m", "t", "w", "t", "f", "s", "s"].enumerated()), id: \.offset) { _, day in
                    Text(day)
                        .plateCaps(size: 8)
                        .foregroundStyle(brand.palette.inkSoft.opacity(0.8))
                        .frame(maxWidth: .infinity)
                }
            }
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<(firstWeekday + days), id: \.self) { slot in
                    if slot < firstWeekday {
                        Color.clear.frame(height: 42)
                    } else {
                        square(day: slot - firstWeekday + 1,
                               pull: byDay[slot - firstWeekday + 1],
                               isToday: slot - firstWeekday + 1 == calendar.component(.day, from: today))
                    }
                }
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(brand.palette.surface)
                .shadow(color: .black.opacity(0.10), radius: 8, x: 0, y: 4)
        }
    }

    private func square(day: Int, pull: Pull?, isToday: Bool) -> some View {
        let inks = brand.palette.extras
        return ZStack {
            Rectangle()
                .strokeBorder(isToday ? brand.palette.accent : brand.palette.ink.opacity(0.15),
                              lineWidth: isToday ? 1.4 : 1)
            if let pull {
                Lozenge()
                    .fill(inks.isEmpty ? brand.palette.accent : inks[pull.ink % inks.count])
                    .frame(width: 18, height: 9)
            } else if isToday {
                RegistrationCross()
                    .stroke(brand.palette.accent, lineWidth: 1.1)
                    .frame(width: 14, height: 14)
            }
        }
        .frame(height: 42)
        .accessibilityLabel(pull == nil ? "\(monthName) \(day), bare copper" : "\(monthName) \(day), pulled")
    }

    private var monthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter.string(from: .now)
    }

    // MARK: What remembers her

    private var caps: some View {
        Text("\(bench.record.platesPulled) pulled  ·  \(bench.record.daysRunning) days running  ·  longest \(bench.record.bestLine)")
            .plateCaps(size: 10)
            .foregroundStyle(brand.palette.inkSoft)
            .frame(maxWidth: .infinity)
            .padding(.top, 2)
    }

    private var shareCard: Image? {
        guard let pull = bench.record.pulls.last else { return nil }
        return ShareImage.render(size: CGSize(width: 360, height: 450)) {
            ShareCard(pull: pull, strip: (0..<pull.points).map { $0 % 7 != 3 || pull.isClean })
                .brand(AppBrand.brand)
        }
    }
}

/// The printer's own registration mark: a fine cross in a circle.
struct RegistrationCross: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addEllipse(in: rect.insetBy(dx: rect.width * 0.28, dy: rect.height * 0.28))
        return path
    }
}
