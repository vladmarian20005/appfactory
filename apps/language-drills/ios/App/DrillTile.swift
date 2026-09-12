import FactoryKit
import SwiftUI

/// Three arcs leaving a point: hear it. Drawn, because an SF Symbol on a hand-painted tile is
/// a sticker on a wall.
struct SoundArcs: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let origin = CGPoint(x: rect.minX + rect.width * 0.22, y: rect.midY)
        for i in 1...3 {
            let radius = rect.width * (0.19 * Double(i) + 0.06)
            path.move(to: CGPoint(x: origin.x + radius * cos(.pi / 3.4),
                                  y: origin.y - radius * sin(.pi / 3.4)))
            path.addArc(center: origin, radius: radius,
                        startAngle: .degrees(-53), endAngle: .degrees(53), clockwise: false)
        }
        return path
    }
}

/// The chime on the tile's back: a drawn glyph in a glaze-tinted well.
struct ChimeGlyph: View {
    let glaze: Color
    var diameter: CGFloat = 44

    var body: some View {
        ZStack {
            Circle().fill(glaze.opacity(0.13))
            SoundArcs()
                .stroke(glaze, style: StrokeStyle(lineWidth: diameter * 0.06, lineCap: .round))
                .frame(width: diameter * 0.52, height: diameter * 0.52)
                .offset(x: -diameter * 0.06)
        }
        .frame(width: diameter, height: diameter)
    }
}

/// The amber lozenge painted where two glaze bands meet — the mark every azulejo border has
/// at its corners.
struct CornerMotif: View {
    let color: Color
    var size: CGFloat = 11

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size)
            .rotationEffect(.degrees(45))
            .frame(width: size * 1.45, height: size * 1.45)
    }
}

/// The tile on the bench, turning.
///
/// It is `Animatable` on the angle so the body is re-evaluated every frame of the turn: the
/// sheen tracks the rotation, and the hairline of unglazed clay shows as the tile goes edge-on.
/// That is what makes it read as a glazed object catching a window rather than a card flipping.
struct TurningTile: View, Animatable {
    var angle: Double
    let word: Word
    let glaze: Color
    let showRank: Bool
    let onChime: () -> Void

    @Environment(\.brand) private var brand
    @Environment(\.dynamicTypeSize) private var typeSize

    var animatableData: Double {
        get { angle }
        set { angle = newValue }
    }

    /// How far past the edge the tile has gone, 0…1.
    private var turned: Bool { angle >= 90 }
    /// 1 exactly edge-on, falling away either side: what the clay hairline fades on.
    private var edgeOn: Double { max(0, 1 - abs(angle - 90) / 12) }

    var body: some View {
        ZStack {
            if turned {
                answerFace
                    .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
            } else {
                promptFace
            }
        }
        .overlay {
            // The 3 pt of unglazed clay a tile is thick, seen only at the edge.
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(AppBrand.clayEdge)
                .opacity(edgeOn)
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0), perspective: 0.62)
    }

    // MARK: - The Spanish

    private var promptFace: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        return shape
            .fill(LinearGradient(colors: [glaze, glaze.shaded(0.14)], startPoint: .top, endPoint: .bottom))
            .overlay {
                Text(word.word)
                    .brandDisplay(size: promptSize)
                    .foregroundStyle(brand.palette.onAccent)
                    .multilineTextAlignment(.center)
                    .minimumScaleFactor(0.45)
                    .lineLimit(3)
                    .padding(.horizontal, 22)
            }
            .overlay { TileSheen(travel: sheenTravel).clipShape(shape) }
            .overlay { TileBevel(radius: 12, width: 3) }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(word.word)
            .accessibilityHint("Turns the tile over to show the English.")
            .accessibilityAddTraits(.isButton)
    }

    /// 56 at the default setting, stepping down for a long headword the way a painter fits a
    /// long name onto a square. Every one of these scales with Dynamic Type.
    private var promptSize: CGFloat {
        switch word.word.count {
        case ..<11: return 56
        case ..<17: return 40
        default: return 30
        }
    }

    private var answerSize: CGFloat {
        switch word.translation.count {
        case ..<13: return 46
        case ..<21: return 36
        default: return 28
        }
    }

    // MARK: - The English

    private var answerFace: some View {
        let shape = RoundedRectangle(cornerRadius: 12, style: .continuous)
        return shape
            .fill(LinearGradient(colors: [glaze, glaze.shaded(0.14)], startPoint: .top, endPoint: .bottom))
            .overlay { motifs }
            .overlay {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(LinearGradient(colors: [AppBrand.tileFace, AppBrand.tileFace.shaded(0.04)],
                                         startPoint: .top, endPoint: .bottom))
                    .overlay {
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(glaze.opacity(0.75), lineWidth: 1.5)
                    }
                    .overlay { answerContent }
                    .padding(15)
            }
            .overlay { TileSheen(travel: sheenTravel, strength: 0.16).clipShape(shape) }
            .overlay { TileBevel(radius: 12, width: 3) }
    }

    private var motifs: some View {
        VStack {
            HStack {
                CornerMotif(color: AppBrand.motif)
                Spacer()
                CornerMotif(color: AppBrand.motif)
            }
            Spacer()
            HStack {
                CornerMotif(color: AppBrand.motif)
                Spacer()
                CornerMotif(color: AppBrand.motif)
            }
        }
        .padding(3)
    }

    private var answerContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(word.word)
                    .brandFont(.headline)
                    .foregroundStyle(glaze)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Spacer(minLength: 8)
                if showRank {
                    Mark("RANK \(word.rank)")
                        .foregroundStyle(AppBrand.faceInkSoft)
                        .layoutPriority(-1)
                }
            }

            Text(word.translation)
                .brandDisplay(size: answerSize)
                .foregroundStyle(glaze)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.4)
                .lineLimit(2)
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
                .padding(.bottom, 12)

            Rectangle()
                .fill(AppBrand.faceInkSoft.opacity(0.3))
                .frame(height: 1)

            VStack(spacing: 4) {
                Text(word.example)
                    .font(.callout.italic())
                    .foregroundStyle(AppBrand.faceInk)
                Text(word.exampleTranslation)
                    .font(.footnote)
                    .foregroundStyle(AppBrand.faceInkSoft)
            }
            .multilineTextAlignment(.center)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.top, 12)

            Spacer(minLength: 4)

            Button {
                onChime()
            } label: {
                ChimeGlyph(glaze: glaze)
            }
            .buttonStyle(.pressable(scale: 0.9))
            .accessibilityLabel("Hear it in Spanish")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        // A tile is 318 points square whatever the text setting, because it is an object and
        // not a paragraph. Its face scales up to here and then holds, so the word, the example
        // and the chime all stay on the tile instead of falling off the edge of it.
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
    }

    /// The sheen runs the face as the tile turns: a window caught on a glaze, not a card
    /// animation. At rest it sits high on the face, where a window would put it.
    private var sheenTravel: Double {
        let t = min(max(angle, 0), 180) / 180
        return -0.34 + t * 1.35
    }
}

/// The small tracked uppercase written on the bench: `OF A THOUSAND`, `DUE TODAY`,
/// `THE HOUSE · 34 OF 80`. The only uppercase in the app, and it scales like everything else.
struct Mark: View {
    let text: String
    var size: CGFloat = 11

    init(_ text: String, size: CGFloat = 11) {
        self.text = text
        self.size = size
    }

    var body: some View {
        Text(text)
            .scaledFont(size: size, weight: .semibold, relativeTo: .caption)
            .tracking(1.6)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            // These are the marks written on the bench in pencil, beside the work rather than
            // instead of it. They scale — at the largest accessibility size this is still half
            // as big again — but a chalk note that grows to fill the screen has stopped being
            // a note, and it pushes the tile it labels off the bench.
            .dynamicTypeSize(...DynamicTypeSize.accessibility2)
    }
}
