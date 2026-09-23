import FactoryKit
import SwiftUI

/// A print: the answer, engraved, the cast marks ranged in their solved rows, with the margin
/// under it carrying the date and the plate number. The same sheet hangs on the drying line.
struct PrintSheet: View {
    let pull: Pull
    var compact = false
    var ink: Color?
    /// The pencil, when she has it and the print is in her hands: a name in the margin.
    var onName: ((String) -> Void)?
    @Environment(\.brand) private var brand
    @Environment(\.aquatint) private var aquatint
    @State private var draft = ""
    /// The names' column grows with the type, so a name never breaks mid-word.
    @ScaledMetric(relativeTo: .callout) private var nameWidth: CGFloat = 62

    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 6 : 10) {
            if compact {
                rows
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, pull.isEditioned ? 9 : 0)
                Spacer(minLength: 0)
                if let name = pull.name {
                    Text(name)
                        .italic()
                        .brandFont(.caption, weight: .regular)
                        .foregroundStyle(brand.palette.ink.opacity(0.78))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, alignment: .center)
                }
                Text(dated)
                    .plateCaps(size: 8)
                    .foregroundStyle(brand.palette.inkSoft)
                    .frame(maxWidth: .infinity, alignment: .center)
            } else {
                HStack(spacing: 8) {
                    Text("Crosshatch")
                        .plateCaps(size: 9)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    Spacer(minLength: 0)
                    Text("\(numbered)  ·  \(dated)")
                        .plateCaps(size: 9)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                }
                .foregroundStyle(brand.palette.inkSoft)
                Text(pull.title)
                    .brandFont(.title3)
                    .foregroundStyle(brand.palette.ink)
                pencil
                rule
                rows
                rule
                HStack(spacing: 8) {
                    Lozenge().fill(brand.palette.highlight).frame(width: 11, height: 7)
                    Text("\(Spelled.out(pull.points)) points  ·  line of \(Spelled.out(pull.longestLine))")
                        .plateCaps(size: 9)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundStyle(brand.palette.highlight)
                    Lozenge().fill(brand.palette.highlight).frame(width: 11, height: 7)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            }
        }
        .padding(compact ? 9 : 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            let shape = RoundedRectangle(cornerRadius: 3, style: .continuous)
            shape
                .fill(brand.palette.surface)
                .overlay {
                    // Chine-collé: a leaf of coloured stock under the pull, so the print
                    // carries the colour of its day. Paper first, then the tint — a wash on
                    // nothing is a grey sheet.
                    if let ink { shape.fill(ink.opacity(0.13)) }
                }
                .shadow(color: .black.opacity(0.16), radius: 9, x: 2, y: 5)
        }
        .overlay(alignment: .topTrailing) {
            // The edition number, in the corner of the sheet the way it is pencilled on a
            // real print.
            if compact, pull.isEditioned {
                Text("№ \(pull.number)")
                    .plateCaps(size: 7)
                    .tracking(0.6)
                    .foregroundStyle(brand.palette.highlight)
                    .padding(.top, 5)
                    .padding(.trailing, 6)
            }
        }
        .overlay(alignment: .topLeading) {
            // Every scar prints. A burnished plate comes up clean; the plate remembers.
            if !pull.isClean && !pull.burnished {
                ForEach(0..<min(3, pull.scars), id: \.self) { index in
                    Path { path in
                        path.move(to: CGPoint(x: 18 + CGFloat(index) * 26, y: 42 + CGFloat(index) * 58))
                        path.addLine(to: CGPoint(x: 52 + CGFloat(index) * 26, y: 30 + CGFloat(index) * 58))
                    }
                    .stroke(brand.palette.miss.opacity(0.5), lineWidth: 0.9)
                }
            }
        }
        // A print is a fixed object, like the plate: it holds its layout at the first
        // accessibility size, and a print hanging on the line is a thumbnail of one.
        .dynamicTypeSize(...(compact ? DynamicTypeSize.xLarge : .accessibility1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("A print of plate \(pull.number), \(pull.title), \(pull.points) points, longest line \(pull.longestLine)\(pull.isClean ? ", not a scar" : ", \(pull.scars) scars")")
    }

    private var rule: some View {
        Rectangle().fill(brand.palette.ink.opacity(0.18)).frame(height: 0.5)
    }

    private var numbered: String {
        pull.isEditioned ? "№ \(pull.number)" : "plate \(pull.number)"
    }

    /// Her name for it, in pencil under the plate's title. With the pencil in hand the line
    /// is a field; otherwise it is only what she wrote.
    @ViewBuilder
    private var pencil: some View {
        if let onName {
            TextField("name it in pencil", text: $draft)
                .italic()
                .brandFont(.callout, weight: .regular)
                .foregroundStyle(brand.palette.ink.opacity(0.8))
                .submitLabel(.done)
                .onAppear { draft = pull.name ?? "" }
                .onSubmit { onName(draft) }
                .onChange(of: draft) { _, value in onName(value) }
                .accessibilityLabel("Name this print")
                .accessibilityHint("Pencils a name in the print's margin, under the plate's title.")
        } else if let name = pull.name {
            Text(name)
                .italic()
                .brandFont(.callout, weight: .regular)
                .foregroundStyle(brand.palette.ink.opacity(0.8))
        }
    }

    /// A cast mark as it prints. Past the aquatint box a fine tone is bitten in under each
    /// figure, so they come up out of a ground rather than sitting on bare paper.
    private func figure(_ glyph: Glyph, size: CGFloat, weight: CGFloat) -> some View {
        EngravedMark(glyph: glyph, size: size, color: brand.palette.ink, lip: nil, weight: weight)
            .background {
                if aquatint {
                    CutShading(progress: 1, spacing: 2.6, weight: 0.8, tone: 0.25)
                        .frame(width: size * 1.35, height: size * 1.35)
                        .clipShape(Circle())
                }
            }
    }

    private var rows: some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 0) {
            ForEach(Array(pull.rows.prefix(compact ? 2 : pull.rows.count).enumerated()), id: \.offset) { index, row in
                if compact {
                    HStack(spacing: 10) {
                        ForEach(Array(row.prefix(2).enumerated()), id: \.offset) { _, glyph in
                            figure(glyph, size: 26, weight: 2.1)
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        Text(index < pull.names.count ? pull.names[index] : "")
                            .brandFont(.callout)
                            .foregroundStyle(brand.palette.ink)
                            .lineLimit(1)
                            .frame(width: nameWidth, alignment: .leading)
                        ForEach(Array(row.dropFirst().enumerated()), id: \.offset) { position, glyph in
                            if position > 0 { leader }
                            figure(glyph, size: 24, weight: 2.2)
                        }
                        Spacer(minLength: 0)
                    }
                    .padding(.vertical, 7)
                    if index < pull.rows.count - 1 { rule }
                }
            }
        }
    }

    private var leader: some View {
        Line()
            .stroke(brand.palette.inkSoft.opacity(0.55),
                    style: StrokeStyle(lineWidth: 1, dash: [1.5, 3.5]))
            .frame(height: 1)
            .frame(maxWidth: .infinity)
    }

    private var dated: String {
        let formatter = DateFormatter()
        formatter.dateFormat = compact ? "d MMM" : "d MMMM"
        return formatter.string(from: pull.date)
    }
}

private struct AquatintKey: EnvironmentKey {
    static let defaultValue = false
}

extension EnvironmentValues {
    /// The aquatint box is down: every print's figures come up in tone. Set once at the root
    /// from the record, so every print in the app agrees.
    var aquatint: Bool {
        get { self[AquatintKey.self] }
        set { self[AquatintKey.self] = newValue }
    }
}

struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return path
    }
}

/// A small portrait of the plate as it comes off the bed: inked, wiped, and still carrying
/// every cut. It stands behind the print on the win and behind today's row on the line.
struct PlatePortrait: View {
    let seed: Int
    var side: CGFloat = 96
    var inked = true

    var body: some View {
        let cells = 6
        let unit = side / CGFloat(cells)
        ZStack {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(AppBrand.Plate.bevel)
                .offset(x: 2, y: 2)
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(LinearGradient(colors: [AppBrand.Plate.faceTop, AppBrand.Plate.faceBottom],
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
            ForEach(0..<(cells * cells), id: \.self) { index in
                let row = index / cells, column = index % cells
                let state = (row * 7 + column * 3 + seed) % 5
                Group {
                    if state == 0 {
                        Lozenge()
                            .fill(AppBrand.Plate.trough)
                            .frame(width: unit * 0.62, height: unit * 0.36)
                    } else if state < 3 && inked {
                        CutShading(progress: 1, spacing: 3.1, weight: 0.9)
                            .frame(width: unit, height: unit)
                    }
                }
                .position(x: (CGFloat(column) + 0.5) * unit, y: (CGFloat(row) + 0.5) * unit)
            }
            Canvas { context, size in
                var path = Path()
                for step in 1..<cells {
                    let offset = CGFloat(step) * unit
                    path.move(to: CGPoint(x: offset, y: 0))
                    path.addLine(to: CGPoint(x: offset, y: size.height))
                    path.move(to: CGPoint(x: 0, y: offset))
                    path.addLine(to: CGPoint(x: size.width, y: offset))
                }
                context.stroke(path, with: .color(AppBrand.Plate.trough.opacity(0.22)), lineWidth: 0.5)
            }
        }
        .frame(width: side, height: side)
        .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
        .accessibilityHidden(true)
    }
}

/// The pull. The last point is cut and the plate is inked, wiped and printed while she
/// watches; the print goes up on the line, and the margin names what is waiting.
struct PullView: View {
    @ObservedObject var bench: Bench
    let session: Session
    @Binding var showPaywall: Bool
    @Environment(\.brand) private var brand

    private var stage: PullStage { bench.stage }
    private var showPrint: Bool { stage >= .peel }

    var body: some View {
        GeometryReader { geo in
            ScrollView {
                VStack(spacing: 18) {
                    press(width: geo.size.width)
                    headline
                    if stage >= .settled { card }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 62)
                .frame(minHeight: geo.size.height, alignment: .top)
            }
        }
        // Filings and paper dust, heavy and falling fast — never party confetti. It fires on
        // appear as well as on the trigger, because this view only exists while a plate is
        // being pulled: a launch that lands on the win has already fired the trigger.
        .confetti(trigger: bench.pullBursts,
                  colors: [AppBrand.Plate.lip, AppBrand.Plate.faceTop, brand.palette.ink, brand.palette.surface],
                  from: UnitPoint(x: 0.5, y: 0.42),
                  count: filings.count,
                  power: filings.power,
                  onAppear: true)
        .transition(.opacity)
    }

    private var filings: (count: Int, power: CGFloat) {
        switch bench.tier {
        case .best: return (96, 1.4)
        case .clean: return (60, 1.0)
        case .good: return (36, 0.6)
        case .finished: return (26, 0.45)
        }
    }

    // MARK: The bed, the plate, the sheet

    /// Where the plate sits on the bed: in the middle under the paper, travelling ten points
    /// through the rollers on the press, then set aside to the right once the print is off it.
    private var plateTop: CGFloat {
        if showPrint { return 196 }
        return stage >= .press ? 96 : 86
    }

    /// The paper lies on the plate, goes through the press with it, and peels up and back off
    /// it — leaving the ghost numeral's top showing above the print.
    private var printTop: CGFloat {
        if showPrint { return 104 }
        return stage >= .press ? 96 : 86
    }

    private func press(width: CGFloat) -> some View {
        ZStack(alignment: .top) {
            // The count, as a ghost numeral behind everything.
            VStack(spacing: 2) {
                Text("Points cut")
                    .plateCaps(size: 10)
                    .foregroundStyle(brand.palette.highlight.opacity(0.5))
                CountUp(to: session.plate.totalPoints, duration: 0.7) { step in
                    Haptics.impact(0.28 + 0.045 * CGFloat(step))
                    Tones.shared.play(.step(step))
                }
                .brandDisplay(size: 132)
                .foregroundStyle(brand.palette.highlight.opacity(0.16))
            }
            // The numeral is a watermark behind the print, not reading matter; past the first
            // accessibility size it would only push the print off the screen.
            .dynamicTypeSize(...DynamicTypeSize.accessibility1)
            .accessibilityHidden(true)
            .zIndex(0)

            // The plate on the bed, inked and wiped.
            PlatePortrait(seed: session.plate.number, side: min(190, width * 0.5))
                .overlay {
                    // Inking sweeps a dark wash across every cut; wiping pulls it back off the
                    // surface, which is exactly what an intaglio plate does.
                    Rectangle()
                        .fill(AppBrand.Plate.trough)
                        .opacity(stage == .inking ? 0.82 : (stage == .wiping ? 0.22 : 0))
                        .animation(Motion.resolved(Motion.gentle), value: stage)
                }
                .scaleEffect(stage == .press ? 0.985 : 1)
                .offset(x: showPrint ? 52 : 0)
                .padding(.top, plateTop)
                .zIndex(1)

            // The paper comes down, the press turns, and the print peels back off the plate.
            Group {
                if stage >= .paper, let pull = bench.pulled {
                    ZStack(alignment: .topLeading) {
                        if bench.tier == .best {
                            // A best is pulled twice: a fainter artist's proof, off register.
                            PrintSheet(pull: pull)
                                .opacity(0.4)
                                .offset(x: -3, y: -3)
                        }
                        PrintSheet(pull: pull, ink: stock)
                    }
                    .overlay(alignment: .top) {
                        // Pegged: the print has gone up on the line. The cord runs out past
                        // both edges and the peg bites the top of the sheet.
                        if stage >= .hung {
                            ZStack {
                                Rectangle()
                                    .fill(brand.palette.highlight.opacity(0.75))
                                    .frame(height: 1.5)
                                    .padding(.horizontal, -40)
                                Lozenge()
                                    .fill(brand.palette.highlight)
                                    .frame(width: 16, height: 10)
                            }
                            .offset(y: -3)
                            .transition(.scale(scale: 0.2, anchor: .center).combined(with: .opacity))
                            .accessibilityHidden(true)
                        }
                    }
                    .frame(width: min(300, width * 0.8))
                    // Peeled from the left: the sheet lifts off at an angle and settles.
                    .rotationEffect(.degrees(showPrint ? -1.5 : (stage >= .press ? 0 : -4)),
                                    anchor: .trailing)
                    .offset(x: -14)
                    .opacity(stage == .paper ? 0.55 : 1)
                    .scaleEffect(showPrint ? 1 : 0.97, anchor: .topLeading)
                    .padding(.top, printTop)
                    .animation(Motion.resolved(Motion.bouncy), value: stage)
                }
            }
            .zIndex(2)
        }
        .padding(.bottom, 10)
        .frame(maxWidth: .infinity)
    }

    /// Past chine-collé every pull takes the colour of its day.
    private var stock: Color? {
        guard bench.record.hasEarned("chine"), let pull = bench.pulled else { return nil }
        let inks = brand.palette.extras
        return inks.isEmpty ? nil : inks[pull.ink % inks.count]
    }

    private var headline: some View {
        VStack(spacing: 10) {
            Text(bench.headline)
                .brandDisplay(size: 30)
                .textCase(.uppercase)
                .foregroundStyle(brand.palette.highlight)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(stage >= .peel ? 1 : 0)
                .scaleEffect(stage >= .peel ? 1 : 0.92)
            // The engraver speaks a beat after the headline, as the card comes up.
            Text("“\(bench.praise)”")
                .brandFont(.title3, weight: .regular)
                .foregroundStyle(brand.palette.inkSoft)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(stage >= .settled ? 1 : 0)
        }
        .animation(Motion.resolved(Motion.gentle), value: stage)
    }

    // MARK: The margin card

    private var card: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("The margin")
                .plateCaps(size: 9.5)
                .foregroundStyle(brand.palette.inkSoft)
            Text(bench.marginCard)
                .brandFont(.title3, weight: .regular)
                .foregroundStyle(brand.palette.ink)
                .fixedSize(horizontal: false, vertical: true)
            if let milestone = bench.earnedNow {
                HStack(alignment: .top, spacing: 9) {
                    Lozenge().fill(brand.palette.highlight).frame(width: 13, height: 8).padding(.top, 6)
                    Text(milestone.blurb)
                        .brandFont(.callout, weight: .regular)
                        .foregroundStyle(brand.palette.highlight)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            LozengeRule(count: 18, color: brand.palette.ink.opacity(0.35), width: 9)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(proofCaps)
                .plateCaps(size: 9.5)
                .foregroundStyle(brand.palette.highlight)
            // Stacked rather than side by side: "Rule the next plate" is the one thing to do
            // next and it sets on one line at every size.
            VStack(spacing: 10) {
                Button {
                    if bench.runIsLocked { showPaywall = true } else { bench.rule(daily: false) }
                } label: {
                    Text("Rule the next plate")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .brandProminent()
                if let image = shareCard, let pull = bench.pulled {
                    ShareLink(item: image,
                              preview: SharePreview("Plate \(pull.number)", image: image)) {
                        Text("Send the margin")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(brand.palette.accent)
                    .background {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(brand.palette.ink.opacity(0.07))
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(brand.palette.surface)
                .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 6)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var proofCaps: String {
        let forced = session.strip.filter { $0 }.count
        let slips = session.strip.count - forced
        if slips == 0 { return "\(Spelled.out(forced)) forced  ·  not one guess" }
        return "\(Spelled.out(forced)) forced  ·  \(Spelled.out(slips)) ahead of the evidence"
    }

    private var shareCard: Image? {
        guard let pull = bench.pulled else { return nil }
        return ShareImage.render(size: CGSize(width: 360, height: 450)) {
            ShareCard(pull: pull, strip: session.strip)
                .brand(AppBrand.brand)
        }
    }
}
