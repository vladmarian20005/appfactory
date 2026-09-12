import FactoryKit
import SwiftUI

// MARK: - The canvas

/// Newsprint: the brand's lit paper, a fixed grain over it, and the two column rules that are
/// the page's structure. Every screen in the app sits on this, so a crop of any one of them is
/// recognisably the same sheet.
struct PaperCanvas: View {
    @Environment(\.brand) private var brand
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            BrandBackground()
            PaperGrain(ink: brand.palette.ink, opacity: scheme == .dark ? 0.045 : 0.030)
            ColumnRules(ink: brand.palette.ink)
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

/// Fibre: short strokes at a shallow angle, seeded so the sheet is identical on every launch.
/// It never animates — a moving texture is noise, not paper.
struct PaperGrain: View {
    let ink: Color
    let opacity: Double

    var body: some View {
        Canvas { context, size in
            var rng = PaperRandom(seed: 0x51A7_1DA7_2C0F_E551)
            var path = Path()
            for _ in 0..<1400 {
                let x = rng.unit() * size.width
                let y = rng.unit() * size.height
                let length = 2 + rng.unit() * 4
                let angle = (rng.unit() - 0.5) * (24 * .pi / 180)
                path.move(to: CGPoint(x: x, y: y))
                path.addLine(to: CGPoint(x: x + cos(angle) * length, y: y + sin(angle) * length))
            }
            context.stroke(path, with: .color(ink.opacity(opacity)), lineWidth: 1)
        }
    }
}

/// Two hairlines the full height of the page, inset from each edge. The page's margins, and
/// the reason a Quizday screenshot reads as a column of type rather than a list of views.
struct ColumnRules: View {
    let ink: Color

    var body: some View {
        GeometryReader { geo in
            Path { path in
                for x in [20.0, geo.size.width - 20.0] {
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x, y: geo.size.height))
                }
            }
            .stroke(ink.opacity(0.11), lineWidth: 0.5)
        }
    }
}

/// A small deterministic generator, so the grain is the same sheet in every capture.
struct PaperRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    mutating func unit() -> Double { Double(next() >> 11) / Double(1 << 53) }
}

/// A shuffle that gives the same order every launch, for the sample history the captures use.
enum SeededShuffle {
    static func apply<T>(_ items: inout [T], seed: UInt64) {
        guard items.count > 1 else { return }
        var rng = PaperRandom(seed: seed &* 0x9E37_79B9_7F4A_7C15 &+ 0x2545_F491)
        for i in stride(from: items.count - 1, to: 0, by: -1) {
            let j = min(Int(rng.unit() * Double(i + 1)), i)
            items.swapAt(i, j)
        }
    }
}

// MARK: - Rules, boxes, ornaments

/// The brand's second shape. 0.5 pt for structure, 1.2 pt for a box, 2.5 pt under a masthead,
/// 3 pt for the press sweep. Rules do the work borders and shadows do in a template.
struct InkRule: View {
    @Environment(\.brand) private var brand
    var weight: CGFloat = 0.5
    var opacity: Double = 1
    var color: Color?

    var body: some View {
        Rectangle()
            .fill((color ?? brand.palette.ink).opacity(opacity))
            .frame(height: weight)
    }
}

/// The printer's ornament that closes a column: two hairlines with an ink lozenge between
/// them, so a page whose content ends early reads as finished rather than as one that ran out.
struct PrintersOrnament: View {
    @Environment(\.brand) private var brand

    var body: some View {
        HStack(spacing: 9) {
            line
            Rectangle()
                .fill(brand.palette.ink.opacity(0.28))
                .frame(width: 5, height: 5)
                .rotationEffect(.degrees(45))
            line
        }
        .frame(maxWidth: .infinity)
        .accessibilityHidden(true)
    }

    private var line: some View {
        Rectangle()
            .fill(brand.palette.ink.opacity(0.28))
            .frame(width: 54, height: 0.5)
    }
}

extension Masthead {
    /// `THURSDAY 11 SEPTEMBER`. The system's own long form comes out as
    /// "Saturday, September 12" — a comma and the month first, which is a settings screen, not
    /// a masthead. A paper sets the day, the number and the month, in that order.
    static func dateline(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.weekday, .day, .month], from: date)
        let symbols = DateFormatter()
        symbols.calendar = calendar
        symbols.locale = .autoupdatingCurrent
        guard let weekday = parts.weekday, let day = parts.day, let month = parts.month,
              weekday >= 1, weekday <= symbols.standaloneWeekdaySymbols.count,
              month >= 1, month <= symbols.standaloneMonthSymbols.count
        else { return date.formatted(.dateTime.weekday(.wide).day().month(.wide)) }
        return "\(symbols.standaloneWeekdaySymbols[weekday - 1]) \(day) \(symbols.standaloneMonthSymbols[month - 1])"
    }

    /// The short form the share card and the calendar use: `THU 11 SEP`.
    static func shortDateline(for date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.weekday, .day, .month], from: date)
        let symbols = DateFormatter()
        symbols.calendar = calendar
        symbols.locale = .autoupdatingCurrent
        guard let weekday = parts.weekday, let day = parts.day, let month = parts.month,
              weekday >= 1, weekday <= symbols.shortStandaloneWeekdaySymbols.count,
              month >= 1, month <= symbols.shortStandaloneMonthSymbols.count
        else { return date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)) }
        return "\(symbols.shortStandaloneWeekdaySymbols[weekday - 1]) \(day) \(symbols.shortStandaloneMonthSymbols[month - 1])"
    }
}

private struct RuledBoxModifier: ViewModifier {
    @Environment(\.brand) private var brand
    let rule: CGFloat
    let radius: CGFloat
    let padding: CGFloat
    let fill: Color?
    let ruleColor: Color?
    let ruleOpacity: Double

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .padding(padding)
            .background(shape.fill(fill ?? brand.palette.surface))
            .overlay(shape.stroke((ruleColor ?? brand.palette.ink).opacity(ruleOpacity), lineWidth: rule))
    }
}

private struct DatelineModifier: ViewModifier {
    @Environment(\.brand) private var brand
    let size: CGFloat
    let tracking: CGFloat
    let color: Color?

    func body(content: Content) -> some View {
        content
            .scaledFont(size: size, weight: .medium, design: .monospaced, relativeTo: .caption)
            .textCase(.uppercase)
            .tracking(tracking)
            .foregroundStyle(color ?? brand.palette.inkSoft)
    }
}

extension View {
    /// The app's canvas, and the system gray of any `List` or `Form` inside cleared away.
    ///
    /// - Parameter darken: the sheet under the press takes a little more ink. Only the result
    ///   asks for it, and only by 4 %.
    func paper(darken: Double = 0) -> some View {
        scrollContentBackground(.hidden)
            .background {
                ZStack {
                    PaperCanvas()
                    if darken > 0 {
                        Color(light: 0x1B2027, dark: 0x000000)
                            .opacity(darken)
                            .ignoresSafeArea()
                    }
                }
            }
    }

    /// The brand's one shape: a rectangle with an ink rule at radius 6, filled with a fresh
    /// sheet. Answer boxes, panels, the calendar block, the stamp — the same shape at four sizes.
    func ruledBox(rule: CGFloat = 1.2,
                  radius: CGFloat = 6,
                  padding: CGFloat = 0,
                  fill: Color? = nil,
                  ruleColor: Color? = nil,
                  ruleOpacity: Double = 0.85) -> some View {
        modifier(RuledBoxModifier(rule: rule, radius: radius, padding: padding,
                                  fill: fill, ruleColor: ruleColor, ruleOpacity: ruleOpacity))
    }

    /// The third voice: SF Mono, uppercase, tracked. The dateline, the section mark, the answer
    /// letters, the legend, the ledger line. Never a sentence.
    func dateline(_ size: CGFloat = 11, tracking: CGFloat = 2, color: Color? = nil) -> some View {
        modifier(DatelineModifier(size: size, tracking: tracking, color: color))
    }
}

// MARK: - The masthead

/// `QUIZDAY` between its rules. Drawn, not a navigation title: the paper's name is set in type.
struct Masthead: View {
    @Environment(\.brand) private var brand
    let title: String
    var strapline: String?
    var size: CGFloat = 30
    /// A clean sweep doubles the rule under the masthead. The edition looks different because
    /// it is a different edition.
    var doubleRule = false

    var body: some View {
        VStack(spacing: 7) {
            InkRule(weight: 0.5, opacity: 0.32)
            Text(title)
                .brandDisplay(size: size, relativeTo: .title)
                .textCase(.uppercase)
                .tracking(6)
                .foregroundStyle(brand.palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            VStack(spacing: 2.5) {
                InkRule(weight: 2.5)
                if doubleRule { InkRule(weight: 2.5) }
            }
            if let strapline {
                Text(strapline).dateline(10, tracking: 2.4)
            }
        }
        // Display type stops growing at accessibility2: past that a masthead set in 30 pt
        // becomes four letters a line and the page stops being a page. Body copy, datelines
        // and every label the reader actually reads scale the whole way.
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(strapline.map { "\(title). \($0)" } ?? title)
    }
}

// MARK: - The tally

/// Ten squares at the top of the sheet, legible from across a room: a hit is solid ink, a miss
/// is ruled and struck through in pencil, a question not yet reached is a faint rule.
struct Tally: View {
    @Environment(\.brand) private var brand
    /// One entry per question answered so far.
    let flags: [Bool]
    var total: Int = 10
    var height: CGFloat = 30
    /// Set on the result, where the squares print one at a time.
    var stagger: Double?

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<total, id: \.self) { index in
                square(at: index)
                    .frame(height: height)
                    .modifier(OptionalPopIn(delay: stagger.map { $0 + Double(index) * 0.034 }))
            }
        }
        .accessibilityElement()
        .accessibilityLabel("\(flags.filter { $0 }.count) of \(total) correct")
    }

    @ViewBuilder
    private func square(at index: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)
        if index >= flags.count {
            shape.stroke(brand.palette.ink.opacity(0.20), lineWidth: 1)
        } else if flags[index] {
            shape.fill(brand.palette.ink)
        } else {
            shape
                .stroke(brand.palette.ink, lineWidth: 1.4)
                .overlay {
                    GeometryReader { geo in
                        Path { path in
                            path.move(to: CGPoint(x: 3, y: geo.size.height - 3))
                            path.addLine(to: CGPoint(x: geo.size.width - 3, y: 3))
                        }
                        .stroke(brand.palette.miss, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                    }
                }
        }
    }
}

/// The run, set as a line of ink lozenges under the tally: one for every answer still standing.
/// It is the only thing in the app that can be lost, and losing it costs this edition's headline
/// and nothing else — no life, no streak, no tomorrow. A miss strikes it out in the same pencil
/// the wrong answer gets, and the next right answer starts another.
struct RunLine: View {
    @Environment(\.brand) private var brand
    let chain: Int
    let isClean: Bool
    /// The chain this answer just broke, drawn struck through before it goes.
    var broken: Int = 0
    /// 0…1, so the strike draws itself with the correction rather than appearing.
    var strike: CGFloat = 0

    private var shown: Int { broken > 0 ? broken : chain }

    var body: some View {
        HStack(spacing: 8) {
            Text(broken > 0 ? "Run broken" : "Run")
                .dateline(10, tracking: 2,
                          color: brand.palette.ink.opacity(broken > 0 ? 0.5 : 0.75))
            lozenges
            Spacer(minLength: 8)
            if isClean, broken == 0, chain > 0 {
                Text("Clean copy")
                    .dateline(10, tracking: 2, color: brand.palette.highlight)
            }
        }
        .frame(minHeight: 14)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }

    @ViewBuilder
    private var lozenges: some View {
        if shown == 0 {
            // An empty run still takes its line, so the sheet does not jump when one starts.
            Rectangle()
                .fill(brand.palette.ink.opacity(0.18))
                .frame(width: 22, height: 0.5)
        } else {
            HStack(spacing: 5) {
                ForEach(0..<min(shown, 10), id: \.self) { _ in
                    Rectangle()
                        .fill(broken > 0 ? brand.palette.miss : brand.palette.ink)
                        .frame(width: 7, height: 7)
                        .rotationEffect(.degrees(45))
                }
            }
            .frame(height: 12)
            .overlay {
                if broken > 0 {
                    PencilStrike()
                        .trim(to: strike)
                        .stroke(brand.palette.miss,
                                style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
                        .padding(.horizontal, -5)
                }
            }
        }
    }

    private var label: String {
        if broken > 0 { return "The run of \(broken) is broken" }
        if chain == 0 { return "No run yet" }
        return isClean ? "A clean run of \(chain)" : "A run of \(chain)"
    }
}

/// `popIn` only where a delay was given, so the same view serves a still sheet and a printing one.
struct OptionalPopIn: ViewModifier {
    let delay: Double?

    func body(content: Content) -> some View {
        if let delay {
            content.popIn(delay: delay)
        } else {
            content
        }
    }
}

// MARK: - The stamp

/// The verdict stamp: a double-ruled box, the line inside it set in italic serif, dropped
/// off-axis so it never looks mechanical. **Red either way** — praise and near-miss both — so
/// the colour that dominates the sheet carries no judgement.
struct Stamp: View {
    @Environment(\.brand) private var brand
    let text: String
    var color: Color?
    var size: CGFloat = 13
    /// A blank sheet gets a blank stamp: ruled, unprinted.
    var empty = false
    /// The width a stamp is cut to when it is a headline rather than a mark. The tier stamp on
    /// the front page came out about half the page wide and read as a caption; the mock slams it
    /// across three quarters of the sheet, which is what makes it a headline.
    var stretch: CGFloat?

    var body: some View {
        let tint = color ?? brand.palette.accent
        let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)
        Text(empty ? "" : text)
            .scaledFont(size: size, weight: .bold, design: .serif, relativeTo: .footnote)
            .italic()
            .textCase(.uppercase)
            .tracking(1.6)
            .foregroundStyle(tint)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 14)
            .padding(.vertical, stretch == nil ? 8 : 12)
            .frame(minWidth: stretch)
            .frame(minHeight: empty ? 34 : 0)
            .background(shape.fill(brand.palette.canvas.opacity(0.86)))
            .overlay(shape.stroke(tint, lineWidth: 2))
            .overlay(shape.inset(by: 3).stroke(tint, lineWidth: 0.8))
            // A rubber stamp is a mark, not copy: at 310 % text it would cover the whole
            // answer it is stamped over. It is read out in full either way — the line is on
            // the stamp's accessibility label, and the verdict is also in each answer's hint.
            .dynamicTypeSize(...DynamicTypeSize.xxLarge)
            .accessibilityLabel(empty ? "A blank sheet" : text)
    }
}

// MARK: - The pencil

/// A hand-drawn ring: two offset loops that overshoot, the way a subeditor circles the right
/// answer on a proof. Animated with `.trim(to:)` so it draws itself.
struct PencilEllipse: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addEllipse(in: rect.insetBy(dx: 2, dy: 1))
        path.addEllipse(in: rect.insetBy(dx: 5, dy: -1.5).offsetBy(dx: 2, dy: 2))
        return path
    }
}

/// One line struck through the answer she picked. Never a red border.
struct PencilStrike: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 6, y: rect.midY + 3))
        path.addQuadCurve(to: CGPoint(x: rect.maxX - 6, y: rect.midY - 2),
                          control: CGPoint(x: rect.midX, y: rect.midY + 6))
        return path
    }
}

// MARK: - The ribbon

/// A printed banner with a notched end, in brass. The run is the only score that carries, and
/// this is the one place the second voice gets to speak.
struct RibbonShape: Shape {
    var notch: CGFloat = 18

    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX + notch, y: rect.midY))
        path.closeSubpath()
        return path
    }
}

/// The streak, as the banner that unrolls across the lower right of the front page.
struct StreakRibbon: View {
    @Environment(\.brand) private var brand
    let days: Int
    var numberSize: CGFloat = 44

    var body: some View {
        // The ribbon fits its number. Drawn at a fixed width it came out as a wide brass slab
        // around a small "1"; a banner is cut to the length of what is printed on it.
        HStack(alignment: .firstTextBaseline, spacing: 9) {
            Text("\(days)")
                .brandDisplay(size: numberSize, relativeTo: .title)
                .foregroundStyle(brand.palette.onAccent)
            Text(days == 1 ? "day\nrunning" : "days\nrunning")
                .dateline(11, tracking: 1.6, color: brand.palette.onAccent.opacity(0.9))
                .fixedSize()
        }
        .padding(.leading, 34)
        .padding(.trailing, 18)
        .padding(.vertical, 10)
        .background(RibbonShape().fill(brand.palette.highlight))
        .dynamicTypeSize(...DynamicTypeSize.accessibility2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(days) days running")
    }
}

// MARK: - The section line

/// Today's sections as a printers' section line: names in mono, each led by a tick in its own
/// section ink, between two hairlines. Not chips in a card.
struct SectionLine: View {
    @Environment(\.brand) private var brand
    let categories: [String]
    /// The edition's make-up — `4 easy · 4 medium · 2 hard`. A paper prints its own contents,
    /// and this is the one line on any screen that shows the ladder moving: at edition 1 it
    /// reads four easy, at edition 200 one, and six hard where there were two.
    var shape: String?

    var body: some View {
        VStack(spacing: 9) {
            InkRule(weight: 0.5, opacity: 0.22)
            FlowRow(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    HStack(spacing: 6) {
                        Rectangle()
                            .fill(AppBrand.ink(for: category))
                            .frame(width: 3, height: 11)
                        Text(category).dateline(10, tracking: 1.6, color: brand.palette.ink.opacity(0.75))
                    }
                }
            }
            if let shape {
                InkRule(weight: 0.5, opacity: 0.14)
                Text(shape)
                    .dateline(10, tracking: 1.6)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            InkRule(weight: 0.5, opacity: 0.22)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Today's sections: \(categories.joined(separator: ", "))."
                            + (shape.map { " The edition is \($0)." } ?? ""))
    }
}

/// Wrapping row. The section names vary in length, so a fixed grid would leave holes.
struct FlowRow: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: proposal.width ?? x, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
