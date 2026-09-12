import FactoryKit
import SwiftUI

/// What goes into a group chat: a picture of your own wall, not a score.
///
/// Two people's cards look different at a glance, because the picture *is* the progress. This
/// is the one place in the app a frozen point size is right — `ShareImage.render` draws into
/// an `ImageRenderer` at a fixed pixel size, where there is no Dynamic Type to scale against.
struct ShareCard: View {
    @Environment(\.brand) private var brand

    let known: Int
    let today: Int
    let newest: Word?
    let firings: [Int: Firing]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                Text("\(known)")
                    .font(.system(size: 96, weight: .semibold).width(.expanded))
                    .monospacedDigit()
                    .foregroundStyle(brand.palette.ink)
                Text(Deck.totalMark)
                    .font(.system(size: 12, weight: .semibold))
                    .tracking(1.8)
                    .foregroundStyle(brand.palette.inkSoft)
                if today > 0 {
                    Text("+\(today) TODAY")
                        .font(.system(size: 12, weight: .semibold))
                        .tracking(1.8)
                        .foregroundStyle(brand.palette.highlight)
                        .padding(.top, 5)
                }
            }
            .padding(.top, 26)

            WallMosaic(firings: firings, maxTile: 7, gap: 1.5, panelGap: 9)
                .frame(height: 196)
                .padding(.horizontal, 26)
                .padding(.top, 16)

            Spacer(minLength: 10)

            HStack(alignment: .bottom, spacing: 14) {
                if let newest {
                    ZStack {
                        GlazedTile(glaze: AppBrand.glaze(newest.theme), radius: 8, bevel: 2)
                        Text(newest.word)
                            .font(.system(size: 15, weight: .semibold).width(.expanded))
                            .foregroundStyle(brand.palette.onAccent)
                            .minimumScaleFactor(0.5)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(6)
                    }
                    .frame(width: 96, height: 96)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Spacer(minLength: 0)
                    Text(dateline)
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1.6)
                        .foregroundStyle(brand.palette.inkSoft)
                    Text("THOUSAND")
                        .font(.system(size: 15, weight: .semibold).width(.expanded))
                        .tracking(1.6)
                        .foregroundStyle(brand.palette.ink)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 26)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { BrandBackground() }
    }

    private var dateline: String {
        let f = DateFormatter()
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: Date()).uppercased()
    }

    /// 1080 × 1350, the shape chat apps show without cropping. The card renders outside the
    /// app's hierarchy, so it carries the brand in with it.
    @MainActor
    static func image(known: Int, today: Int, newest: Word?, firings: [Int: Firing]) -> Image? {
        ShareImage.render(size: CGSize(width: 360, height: 450)) {
            ShareCard(known: known, today: today, newest: newest, firings: firings)
                .brand(AppBrand.brand)
        }
    }
}
