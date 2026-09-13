import FactoryKit
import SwiftUI

/// DESIGN.md's Tokens, unchanged. The bench under a north window at eleven in the morning;
/// at night the same bench under one clipped tungsten lamp, so the wall goes cold and the
/// wood stays warm. Dark is designed, not inverted.
enum AppBrand {
    static let brand = Brand(
        palette: BrandPalette(
            canvas: Color(light: 0xC3B9A3, dark: 0x13161A),
            surface: Color(light: 0xF0E5CC, dark: 0x262117),
            ink: Color(light: 0x221A0F, dark: 0xF1E7D3),
            inkSoft: Color(light: 0x4C4334, dark: 0xA79C87),
            accent: Color(light: 0x17506A, dark: 0x6FBADD),
            onAccent: Color(light: 0xFFF3E8, dark: 0x1E0B05),
            highlight: Color(light: 0xA2361B, dark: 0xF0885F),
            success: Color(light: 0x2C6650, dark: 0x6FC0A0),
            miss: Color(light: 0x6B5C43, dark: 0x9B8E76),
            extras: [
                Color(light: 0xA2361B, dark: 0xF0885F),   // keel red
                Color(light: 0x17506A, dark: 0x6FBADD),   // chalk blue
                Color(light: 0x2C6650, dark: 0x6FC0A0),   // verdigris
                Color(light: 0x7E5C12, dark: 0xE0B455),   // ochre
                Color(light: 0x5C3A6B, dark: 0xB491C6),   // logwood
                Color(light: 0x3E4247, dark: 0xA8AEB5),   // graphite
            ]
        ),
        type: BrandType(display: .default,
                        displayWidth: .compressed,
                        displayWeight: .heavy,
                        body: .default),
        corner: 5,
        canvas: .glow(Color(light: 0xD8CFBC, dark: 0x232A30),
                      at: UnitPoint(x: 0.24, y: 0.02))
    )
}
