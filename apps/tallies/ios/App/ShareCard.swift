import FactoryKit
import SwiftUI

/// What goes into somebody else's chat: the limewash ground, the stave with every gate on
/// it, the total burned in, a fortnight of strip and the app's own mark at the foot.
///
/// Every size here is asked for through `brandDisplay(size:)` or a text style, never a frozen
/// point size. `ShareImage.render` pins Dynamic Type to `.large` for the render, so the card
/// gets exactly the size it asks for on its fixed canvas and lays out the same for everybody.
/// The sizes are quoted in points of a 360 × 450 canvas, which renders at 1080 × 1350.
struct StaveShareCard: View {
    let name: String
    let total: Int
    let marks: [Mark]
    let strip: [Record.StripDay]
    let pigment: Color
    let daysKept: Int
    let clean: Bool

    @Environment(\.brand) private var brand

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(name.uppercased())
                .brandFont(.title3)
                .foregroundStyle(brand.palette.ink.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text("\(total)")
                .brandDisplay(size: 100)
                .monospacedDigit()
                .foregroundStyle(brand.palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
                .padding(.top, -6)

            StaveBoard(pigment: pigment) {
                ZStack(alignment: .topLeading) {
                    Color.clear.frame(height: 72)
                    StaveMarks(marks: marks, notchDepth: 13)
                        .padding(.leading, 20)
                        .padding(.trailing, 12)
                        .padding(.top, 8)
                }
            }
            .rotationEffect(.degrees(-2.5))
            .padding(.top, 14)

            StripView(days: strip, pigment: pigment, ruled: true)
                .padding(.top, 22)

            Spacer(minLength: 0)

            Text("Kept \(daysKept) days · \(clean ? "not one wax on this stave" : "an honest stave")")
                .stencilCaps()
                .foregroundStyle(brand.palette.inkSoft)

            HStack(spacing: 7) {
                ForEach(0..<3, id: \.self) { _ in
                    NotchMark(mark: .cut, width: 7, depth: 13)
                }
                Text("Tallies")
                    .brandFont(.subheadline)
                    .foregroundStyle(brand.palette.ink.opacity(0.6))
            }
            .padding(.top, 12)
        }
        .padding(26)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { BenchCanvas() }
    }
}
