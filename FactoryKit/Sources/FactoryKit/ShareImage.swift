import SwiftUI

/// Renders a SwiftUI view to an image for `ShareLink`, so a result travels as a picture —
/// the brand, the score, the day — rather than a line of text nobody taps.
///
///     if let image = ShareImage.render { ResultCard(result: r).brand(AppBrand.brand) } {
///         ShareLink(item: image, preview: SharePreview("Round 13", image: image)) { … }
///     }
///
/// The view renders outside the app's hierarchy, so it inherits nothing: apply
/// `.brand(AppBrand.brand)` inside, and a color scheme if it should not follow the phone's.
public enum ShareImage {
    /// - Parameters:
    ///   - size: the card in points. 360×450 at scale 3 is 1080×1350, a shape chat apps show
    ///     without cropping.
    @MainActor
    public static func render<Content: View>(size: CGSize = CGSize(width: 360, height: 450),
                                             scale: CGFloat = 3,
                                             @ViewBuilder _ content: () -> Content) -> Image? {
        let renderer = ImageRenderer(content: content().frame(width: size.width, height: size.height))
        renderer.scale = scale
        renderer.isOpaque = true
        guard let image = renderer.uiImage else { return nil }
        return Image(uiImage: image)
    }
}
