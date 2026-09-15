import FactoryKit
import SwiftUI

/// The margin of today's print, as a picture worth sending to somebody — and it spoils
/// nothing: no cast, no marks, no answer. The shape of the solve is legible to anyone and the
/// plate is not.
///
/// Every size here is asked for through `brandDisplay(size:)` or `scaledFont(size:)`.
/// `ShareImage.render` pins Dynamic Type to `.large` for the render, so the card lays out
/// identically for everybody on its fixed canvas.
struct ShareCard: View {
    let pull: Pull
    let strip: [Bool]
    @Environment(\.brand) private var brand

    var body: some View {
        ZStack {
            brand.palette.canvas
            GroundTooth()
            sheet
                .padding(26)
                .rotationEffect(.degrees(1.5))
        }
        .frame(width: 360, height: 450)
        .environment(\.colorScheme, .light)
    }

    private var sheet: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Crosshatch")
                .brandDisplay(size: 30)
                .foregroundStyle(brand.palette.ink)
            Text("plate \(pull.number)  ·  \(dated)")
                .plateCaps(size: 10)
                .foregroundStyle(brand.palette.inkSoft)
            Rectangle().fill(brand.palette.ink.opacity(0.2)).frame(height: 0.7)
            HStack(alignment: .lastTextBaseline, spacing: 10) {
                Text("\(pull.points)")
                    .brandDisplay(size: 88)
                    .foregroundStyle(brand.palette.ink)
                Text("points\ncut")
                    .plateCaps(size: 10)
                    .foregroundStyle(brand.palette.inkSoft)
                    .padding(.bottom, 8)
                Spacer(minLength: 0)
            }
            proof
            Rectangle().fill(brand.palette.ink.opacity(0.2)).frame(height: 0.7)
            Text(foot)
                .plateCaps(size: 10)
                .foregroundStyle(brand.palette.highlight)
            Spacer(minLength: 0)
            mark
        }
        .padding(22)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(brand.palette.surface)
                .shadow(color: .black.opacity(0.2), radius: 10, x: 3, y: 6)
        }
    }

    /// One mark per point in the order they were cut — a filled lozenge for a forced cut, a
    /// hairline scratch for a slip — ranged five to a group.
    private var proof: some View {
        let marks = Array(strip.prefix(40))
        return HStack(alignment: .center, spacing: 7) {
            ForEach(Array(stride(from: 0, to: max(1, marks.count), by: 5)), id: \.self) { start in
                HStack(spacing: 3) {
                    ForEach(start..<min(start + 5, marks.count), id: \.self) { index in
                        if marks[index] {
                            Lozenge()
                                .fill(brand.palette.ink)
                                .frame(width: 11, height: 7)
                        } else {
                            Scratch()
                                .stroke(brand.palette.miss, lineWidth: 1.2)
                                .frame(width: 11, height: 9)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: 14)
    }

    private var mark: some View {
        HStack(spacing: 8) {
            hatchMark
            Lozenge().fill(brand.palette.ink).frame(width: 13, height: 8)
            hatchMark
            Spacer(minLength: 0)
            Text("Crosshatch")
                .plateCaps(size: 9)
                .foregroundStyle(brand.palette.inkSoft)
        }
    }

    private var hatchMark: some View {
        HatchField(degrees: 62, spacing: 3.2)
            .stroke(brand.palette.ink.opacity(0.5), lineWidth: 1)
            .frame(width: 18, height: 10)
            .clipped()
    }

    private var foot: String {
        let scars = pull.isClean
            ? "not a scar"
            : "\(Spelled.out(pull.scars)) scar\(pull.scars == 1 ? "" : "s")"
        return "longest line \(Spelled.out(pull.longestLine))  ·  \(scars)"
    }

    private var dated: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMMM"
        return formatter.string(from: pull.date)
    }
}

/// A slip, as it prints: one hairline scratch.
struct Scratch: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return path
    }
}
