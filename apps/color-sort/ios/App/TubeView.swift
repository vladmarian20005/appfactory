import FactoryKit
import SwiftUI

/// One vial: hand-blown glass standing in the wet flat, holding light rather than paint.
///
/// Drawn rather than assembled out of controls, because it is content, not a control — the
/// standard components are kept for everything the system owns (buttons, navigation, sheets,
/// toolbars) so the iOS 26 SDK can style them.
struct TubeView: View {
    let contents: [Int]
    let style: BoardStyle
    let width: CGFloat
    let unitHeight: CGFloat
    /// How deep this vial is. The rack gets deeper from level 50 on, so the glass cannot be
    /// drawn against a constant.
    var capacity: Int = Board.baseCapacity
    var isSelected = false
    /// The vial the hint wants liquid to come out of.
    var isHintSource = false
    /// The vial the hint wants it to go into.
    var isHintTarget = false
    /// How many of the top units have just arrived, and how far they have risen.
    var rising = 0
    var riseProgress: Double = 1
    /// How many of the top units are on their way out of the tipped mouth, and how far gone
    /// they are. Without this the vial in the air goes empty the instant the arc starts, and
    /// the pour reads as a glass being waved about.
    var draining = 0
    var drainProgress: Double = 0
    /// Full, one colour, done. It keeps a glow on the flat and grows a frond.
    var isComplete = false
    /// The first move of the verified solution, before this player has ever poured. The ring
    /// under the glass breathes; nothing is written anywhere.
    var isTeaching = false

    @Environment(\.brand) private var brand

    private var hinted: Bool { isHintSource || isHintTarget }

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: width * 0.16,
                               bottomLeadingRadius: width * 0.46,
                               bottomTrailingRadius: width * 0.46,
                               topTrailingRadius: width * 0.16,
                               style: .continuous)
    }

    private var height: CGFloat { unitHeight * CGFloat(capacity) }

    /// The rim: mint when it is chosen or charted, kelp when it is done, otherwise the faint
    /// edge of wet glass.
    private var rim: Color {
        if isSelected || hinted { return brand.palette.accent }
        // The first vial the charted line wants, before this player has ever poured. It is lit
        // and its ring breathes; that is the whole of the teaching, and there is no sentence.
        if isTeaching { return brand.palette.accent.opacity(0.7) }
        if isComplete { return brand.palette.success.opacity(0.75) }
        return brand.palette.ink.opacity(0.16)
    }

    private var rimWidth: CGFloat {
        if isSelected || hinted { return 2.6 }
        return isTeaching ? 2 : 1.2
    }

    /// The colour of whatever is in the glass, for the ring it throws on the flat. The vial
    /// being taught throws mint, so the eye goes to it.
    private var poolColor: Color {
        if isTeaching { return brand.palette.accent }
        guard let top = contents.last else { return brand.palette.accent }
        return style.liquid(top).glow
    }

    /// How hard the vial burns on the wet flat. A vial that has come good throws the most
    /// light; the one the charted line wants throws nearly as much, so the eye lands on it
    /// before the breathing ring has finished a single cycle; a plain vial only wets the
    /// stone under it.
    private var ringStrength: Double {
        if isComplete { return 0.55 }
        if isTeaching { return 0.5 }
        return 0.3
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            glass
            liquid
            specular
        }
        .frame(width: width, height: height)
        .overlay { shape.strokeBorder(rim, lineWidth: rimWidth) }
        .background(alignment: .bottom) { flat }
        .overlay(alignment: .top) { hintArrow }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isSelected ? "Selected. Tap a vial to pour into it."
                                      : "Tap to pour from this vial.")
    }

    // MARK: - The glass

    private var glass: some View {
        shape
            .fill(LinearGradient(colors: [brand.palette.surface.opacity(0.92),
                                          brand.palette.surface.opacity(0.55)],
                                 startPoint: .top, endPoint: .bottom))
    }

    /// A specular stripe down the left sixth of the glass — the light of the sky on a wet
    /// curve. It sits over the liquid, which is what makes it read as glass and not as a gap.
    private var specular: some View {
        Capsule(style: .continuous)
            .fill(LinearGradient(colors: [.white.opacity(0.42), .white.opacity(0.04)],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: max(2, width * 0.075), height: height * 0.52)
            .offset(x: -width * 0.30, y: -height * 0.2)
            .frame(width: width, height: height)
            .allowsHitTesting(false)
    }

    private var liquid: some View {
        VStack(spacing: 0) {
            ForEach(Array(contents.enumerated()).reversed(), id: \.offset) { slot, color in
                unit(color,
                     isSurface: slot == contents.count - 1,
                     isRising: slot >= contents.count - rising,
                     isDraining: slot >= contents.count - draining)
            }
        }
        .frame(width: width)
        // Inset from the rim, so the glass shows as a wall around the light rather than the
        // liquid reading as a solid pill.
        .clipShape(shape.inset(by: width * 0.055))
        .shadow(color: poolColor.opacity(0.55), radius: 10)
    }

    @ViewBuilder
    private func unit(_ color: Int, isSurface: Bool, isRising: Bool, isDraining: Bool = false) -> some View {
        let liquid = style.liquid(color)
        let h: CGFloat = {
            if isDraining { return unitHeight * max(0, 1 - drainProgress) }
            if isRising { return unitHeight * max(0, riseProgress) }
            return unitHeight
        }()
        Rectangle()
            .fill(LinearGradient(colors: [liquid.top, liquid.color, liquid.bottom],
                                 startPoint: .top, endPoint: .bottom))
            .frame(height: h)
            .overlay(alignment: .top) {
                // The meniscus: the lit curve of the surface where the air meets the light.
                if isSurface {
                    Ellipse()
                        .fill(LinearGradient(colors: [liquid.top.opacity(0.95),
                                                      liquid.top.opacity(0.25)],
                                             startPoint: .top, endPoint: .bottom))
                        .frame(height: min(9, unitHeight * 0.26))
                        .padding(.horizontal, width * 0.08)
                        .offset(y: -min(4, unitHeight * 0.1))
                } else {
                    Rectangle().fill(.white.opacity(0.08)).frame(height: 1)
                }
            }
            .overlay {
                if let symbol = style.symbol(color), h > unitHeight * 0.6 {
                    Image(systemName: symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(style.markerColor(color))
                }
            }
    }

    // MARK: - The flat underneath

    /// The ring of light the vial throws on the wet flat, and the frond that grows under one
    /// that has come good.
    @ViewBuilder
    private var flat: some View {
        ZStack {
            Ellipse()
                .fill(RadialGradient(colors: [poolColor.opacity(ringStrength),
                                              poolColor.opacity(0)],
                                     center: .center, startRadius: 0, endRadius: width * 0.72))
                .frame(width: width * (isTeaching ? 1.9 : 1.6), height: width * 0.5)
                .breathingIf(isTeaching)
            if isComplete {
                Frond()
                    .stroke(poolColor.opacity(0.9), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: width * 0.62, height: width * 0.34)
                    .offset(y: width * 0.1)
                    .transition(.scale(scale: 0.3, anchor: .top).combined(with: .opacity))
            }
        }
        .offset(y: width * 0.24)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var hintArrow: some View {
        // An arrow out of one vial and into the other says which way the charted line pours;
        // two lit rims on their own do not.
        if hinted {
            Image(systemName: isHintSource ? "arrow.up" : "arrow.down")
                .font(.footnote.weight(.bold))
                .foregroundStyle(brand.palette.onAccent)
                .padding(5)
                .background(brand.palette.accent, in: Circle())
                .shadow(color: brand.palette.accent.opacity(0.6), radius: 8)
                // Held at its drawn size: a marker that grows with the text setting sits over
                // the mouth of the vial it is pointing at. The direction is in the label below
                // as well, so VoiceOver loses nothing by this.
                .dynamicTypeSize(DynamicTypeSize.large)
                .offset(y: -min(30, unitHeight * 0.3))
        }
    }

    private var label: String {
        guard !contents.isEmpty else { return "Empty vial" }
        let names = contents.map { style.name($0) }
        var runs: [(String, Int)] = []
        for name in names {
            if var last = runs.last, last.0 == name {
                last.1 += 1
                runs[runs.count - 1] = last
            } else {
                runs.append((name, 1))
            }
        }
        let described = runs.map { $0.1 == 1 ? $0.0 : "\($0.1) \($0.0)" }.joined(separator: ", then ")
        return "Vial: from the bottom, \(described)."
            + (isComplete ? " Finished." : "")
            + (isHintSource ? " The charted line pours out of this one." : "")
            + (isHintTarget ? " The charted line pours into this one." : "")
    }
}

/// Five arcs out of one point: the frond that grows under a vial that has come good.
struct Frond: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let root = CGPoint(x: rect.midX, y: rect.maxY)
        for i in -2...2 {
            let spread = CGFloat(i) / 2
            let tip = CGPoint(x: rect.midX + spread * rect.width * 0.48,
                              y: rect.minY + abs(spread) * rect.height * 0.42)
            let control = CGPoint(x: rect.midX + spread * rect.width * 0.16, y: rect.midY)
            path.move(to: root)
            path.addQuadCurve(to: tip, control: control)
        }
        return path
    }
}

private extension View {
    /// Breathing only when it should be — the teaching ring under the first vial the charted
    /// line wants, and nothing else.
    @ViewBuilder
    func breathingIf(_ condition: Bool) -> some View {
        if condition { self.breathing(amount: 0.13, period: 2.4) } else { self }
    }
}
