import FactoryKit
import SwiftUI

/// Thousand's look, from DESIGN.md. A tile-setter's workshop: lime plaster, clay and glaze.
enum AppBrand {
    static let brand = Brand(
        palette: BrandPalette(
            canvas:    Color(light: 0xEDE3D6, dark: 0x131826),   // cal — lime plaster
            surface:   Color(light: 0xE0D2C0, dark: 0x1F2536),   // bisque — unfired clay
            ink:       Color(light: 0x2B211A, dark: 0xF1E7D8),   // carbón
            inkSoft:   Color(light: 0x63564A, dark: 0x9AA3B5),   // sombra
            accent:    Color(light: 0x1C5AA6, dark: 0x5C9BE8),   // cobalto
            onAccent:  Color(light: 0xF4ECDD, dark: 0x0B1524),   // cal glaseada
            highlight: Color(light: 0xA8701B, dark: 0xF0B450),   // azafrán — the lamp
            success:   Color(light: 0x2F6B57, dark: 0x4FA084),   // verde de cobre
            miss:      Color(light: 0x9E4630, dark: 0xD2714F),   // almagre
            extras: [
                Color(light: 0x1C5AA6, dark: 0x5C9BE8),   // 0  cobalto        · Everyday
                Color(light: 0x9E4630, dark: 0xD2714F),   // 1  almagre        · People & family
                Color(light: 0x2F6B57, dark: 0x4FA084),   // 2  verde de cobre · Food & drink
                Color(light: 0xA8701B, dark: 0xC9963F),   // 3  ocre           · The house
                Color(light: 0x2A7E8E, dark: 0x46AFC0),   // 4  turquesa       · City & travel
                Color(light: 0x35468C, dark: 0x6376C8),   // 5  índigo         · Work & school
                Color(light: 0xA55A6A, dark: 0xD18B99),   // 6  rosa de barro  · Body & health
                Color(light: 0x6B4E7D, dark: 0x9A79AE),   // 7  manganeso      · Time & number
                Color(light: 0x5E6B2C, dark: 0x93A24C),   // 8  oliva          · Nature & weather
                Color(light: 0x5B3550, dark: 0x8C5C80),   // 9  berenjena      · Going & coming
                Color(light: 0x8F5E12, dark: 0xF0B450),   // 10 azafrán        · Feeling & mind
                Color(light: 0x41505C, dark: 0x7C8896),   // 11 pizarra        · Describing
            ]
        ),
        // Hand-painted tile lettering is wide. Nobody in this category is.
        type: BrandType(display: .default,
                        displayWidth: .expanded,
                        displayWeight: .semibold,
                        body: .default),
        corner: 12,
        // Troweled plaster: daylight from the top-left in light, the workshop lamp
        // top-right at night. Never one flat colour.
        canvas: .mesh([
            Color(light: 0xF5ECE0, dark: 0x161C2C), Color(light: 0xF0E6D9, dark: 0x1A2134), Color(light: 0xF3E8D6, dark: 0x232741),
            Color(light: 0xEDE3D6, dark: 0x121726), Color(light: 0xEADFD0, dark: 0x161B2B), Color(light: 0xE8DCCB, dark: 0x1B2135),
            Color(light: 0xE6D9C7, dark: 0x0F1420), Color(light: 0xE3D6C3, dark: 0x121724), Color(light: 0xE0D2C0, dark: 0x0E1320),
        ])
    )

    /// The clay edge a tile shows when it turns — the one colour that is neither
    /// plaster nor glaze.
    static let clayEdge = Color(light: 0xC7B49B, dark: 0x3A3730)

    /// The cream ground of a tile's answer face. Light in both modes — dimmed at night so it
    /// does not glare — so its text is always `faceInk` and `faceInkSoft`, never the palette's.
    static let tileFace = Color(light: 0xF4ECDD, dark: 0xDCD2C0)
    static let faceInk = Color(hex: 0x2B211A)
    static let faceInkSoft = Color(hex: 0x63564A)

    /// The amber the corner motifs and the fresh mortar ring are painted in.
    static let motif = Color(hex: 0xE0A03C)

    /// The glaze of a theme, by its index in the deck's twelve.
    static func glaze(_ theme: Int) -> Color {
        brand.palette.extras[theme % brand.palette.extras.count]
    }
}
