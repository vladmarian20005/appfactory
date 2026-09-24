import FactoryKit
import SwiftUI

/// The swatch: 1080 × 1350, and it spoils nothing. The finished figure is the day's answer,
/// so the card never shows the piece — it shows a five-by-five window cut from its centre,
/// which looks like lace and gives nothing away.
struct ShareCard: View {
    let piece: Piece
    let initials: String
    @Environment(\.brand) private var brand

    var body: some View {
        ZStack {
            Linen()
            VStack(spacing: 14) {
                HStack(spacing: 10) {
                    Rectangle().fill(brand.palette.ink.opacity(0.3)).frame(height: 0.6)
                    Text("Lacework").caps(.caption, tracking: 3)
                    PinHead(size: 5)
                    Rectangle().fill(brand.palette.ink.opacity(0.3)).frame(height: 0.6)
                }
                Text("\(Play.date(ofDay: piece.day).formatted(.dateTime.day().month(.wide))) · \(Words.size(piece.side)) · \(piece.ground.name) ground")
                    .caps(.caption2, tracking: 1.6)
                    .multilineTextAlignment(.center)
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(piece.longestThread)")
                        .brandDisplay(size: 80)
                        .foregroundStyle(brand.palette.ink)
                    Text("Pins").caps(.caption, tracking: 2)
                }
                swatch
                    .frame(width: 150, height: 150)
                VStack(spacing: 4) {
                    Text(piece.isClean ? "One thread · worked clean" : "One thread · picked out \(Words.times(piece.unpicks))")
                        .caps(.caption2, tracking: 1.6)
                    Text("Longest thread \(piece.longestThread)").caps(.caption2, tracking: 1.6)
                }
                HStack(spacing: 6) {
                    Capsule().fill(piece.thread.color).frame(width: 18, height: 2)
                    PinHead(color: AppBrand.Workbox.brass, size: 6)
                    Capsule().fill(piece.thread.color).frame(width: 18, height: 2)
                    if !initials.isEmpty {
                        Text(initials).caps(.caption2, tracking: 2).padding(.leading, 6)
                    }
                }
            }
            .padding(22)
            .background {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(brand.palette.surface)
                    .shadow(color: .black.opacity(0.12), radius: 8, x: 2, y: 4)
            }
            .rotationEffect(.degrees(1.5))
            .padding(20)
        }
    }

    /// The central five by five of the piece, as thread, on parchment with a hairline frame.
    private var swatch: some View {
        Canvas { gc, size in
            let path = piece.path.map(Int.init)
            let side = piece.side
            let lo = max(0, (side - 5) / 2), hi = lo + min(5, side)
            let window = min(5, side)
            let layout = CardLayout(side: window, size: size.width)
            // Keep only the thread inside the window, in runs.
            var segment: [Int] = []
            func flush() {
                if segment.count >= 2 {
                    gc.drawThread(segment, plaits: ThreadGeometry.plaits(in: segment, taken: segment.count),
                                  layout: layout,
                                  style: ThreadStyle(color: piece.thread.color, twist: piece.thread.twist, width: 3.4))
                }
                segment = []
            }
            for c in path {
                let r = c / side, col = c % side
                if r >= lo, r < hi, col >= lo, col < hi {
                    segment.append((r - lo) * window + (col - lo))
                } else {
                    flush()
                }
            }
            flush()
            if piece.picot { gc.drawPicot(layout: layout, color: AppBrand.Workbox.gold, scallops: 24) }
        }
        .overlay { Rectangle().stroke(brand.palette.ink.opacity(0.25), lineWidth: 0.6) }
    }

    static func text(for piece: Piece) -> String {
        let day = Play.date(ofDay: piece.day).formatted(.dateTime.day().month(.wide))
        return "Lacework · \(day) · \(piece.longestThread) pins in one thread\(piece.isClean ? ", worked clean" : "")."
    }
}

/// "Send a swatch": the card rendered to an image, with the line as the fallback.
struct SwatchShareLink: View {
    let piece: Piece
    let record: Record
    var compact = false
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let text = ShareCard.text(for: piece)
        if let image = ShareImage.render({
            ShareCard(piece: piece, initials: record.hasEarned("initials") ? record.initials : "")
                .brand(AppBrand.brand)
                .environment(\.colorScheme, scheme)
        }) {
            ShareLink(item: image, message: Text(text), preview: SharePreview("A swatch from Lacework", image: image)) {
                label
            }
            .swatchButtonStyle(compact)
        } else {
            ShareLink(item: text) { label }
                .swatchButtonStyle(compact)
        }
    }

    @ViewBuilder
    private var label: some View {
        if compact {
            Image(systemName: "square.and.arrow.up").accessibilityLabel("Send a swatch")
        } else {
            Text("Send a swatch")
                .font(.headline)
                .lineLimit(1)
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
        }
    }
}

extension View {
    @ViewBuilder
    func swatchButtonStyle(_ compact: Bool) -> some View {
        if compact { self } else { self.buttonStyle(.bordered).buttonBorderShape(.capsule).controlSize(.large) }
    }
}
