import SwiftUI

/// The function from a `Table` to the position, size and z of every card. Fifty-two views whose
/// positions are a pure function of state: a move changes state and every card animates to its
/// new place.
struct TableLayout {
    enum Place: Equatable {
        case stock(Int), waste(Int), foundation(Int, Int), column(Int, Int)
    }

    struct Spot {
        var center: CGPoint
        var z: Double
        var faceUp: Bool
        var place: Place
    }

    let size: CGSize
    let leftHanded: Bool
    let cardW: CGFloat
    let cardH: CGFloat
    let gap: CGFloat = 6
    let margin: CGFloat = 12
    let tableauY: CGFloat

    init(size: CGSize, leftHanded: Bool) {
        self.size = size
        self.leftHanded = leftHanded
        cardW = max(30, (size.width - 24 - 36) / 7)
        cardH = cardW * 1.4
        tableauY = cardH + 16
    }

    func x(col: Int) -> CGFloat { margin + CGFloat(col) * (cardW + gap) + cardW / 2 }

    var stockCol: Int { leftHanded ? 6 : 0 }
    var wasteCol: Int { leftHanded ? 5 : 1 }
    func foundationCol(_ suit: Int) -> Int { leftHanded ? suit : 3 + suit }

    var stockCenter: CGPoint { CGPoint(x: x(col: stockCol), y: cardH / 2) }
    var wasteCenter: CGPoint { CGPoint(x: x(col: wasteCol), y: cardH / 2) }
    func foundationCenter(_ suit: Int) -> CGPoint { CGPoint(x: x(col: foundationCol(suit)), y: cardH / 2) }
    func columnTop(_ c: Int) -> CGPoint { CGPoint(x: x(col: c), y: tableauY + cardH / 2) }

    /// The frame a dropped run is judged against: the full height of the column.
    func columnFrame(_ c: Int) -> CGRect {
        CGRect(x: x(col: c) - cardW / 2 - gap / 2, y: tableauY - cardH * 0.4,
               width: cardW + gap, height: max(cardH, size.height - tableauY + cardH * 0.4))
    }

    var foundationRow: CGRect {
        let a = x(col: foundationCol(0)), b = x(col: foundationCol(3))
        return CGRect(x: min(a, b) - cardW / 2 - gap / 2, y: -cardH * 0.3,
                      width: abs(b - a) + cardW + gap, height: cardH * 1.3 + 8)
    }

    /// Spacing down a column: face-down 8 pt, face-up 28 % of the height, compressing toward
    /// 18 % as the column grows, and further only if it must.
    func offsets(down: Int, up: Int) -> (down: CGFloat, up: CGFloat) {
        let avail = size.height - tableauY - cardH - 4
        var d: CGFloat = 8
        var u = cardH * 0.28
        guard up > 1 || down > 0 else { return (d, u) }
        let need = CGFloat(down) * d + CGFloat(max(0, up - 1)) * u
        if need > avail, up > 1 {
            u = max(cardH * 0.18, (avail - CGFloat(down) * d) / CGFloat(up - 1))
            let again = CGFloat(down) * d + CGFloat(up - 1) * u
            if again > avail {
                d = max(4, (avail - CGFloat(up - 1) * u) / CGFloat(max(1, down)))
                u = max(cardH * 0.14, (avail - CGFloat(down) * d) / CGFloat(up - 1))
            }
        }
        return (d, u)
    }

    func spots(_ t: Table) -> [UInt8: Spot] {
        var out: [UInt8: Spot] = [:]
        for (i, c) in t.stock.enumerated() {
            out[c.code] = Spot(center: stockCenter, z: Double(i), faceUp: false, place: .stock(i))
        }
        let fanFrom = t.draw == 3 ? max(0, t.waste.count - 3) : t.waste.count
        for (i, c) in t.waste.enumerated() {
            var p = wasteCenter
            if i >= fanFrom { p.x += CGFloat(i - fanFrom) * 14 * (leftHanded ? -1 : 1) }
            out[c.code] = Spot(center: p, z: 100 + Double(i), faceUp: true, place: .waste(i))
        }
        for s in 0..<4 {
            for (i, c) in t.foundations[s].enumerated() {
                out[c.code] = Spot(center: foundationCenter(s), z: 200 + Double(i), faceUp: true, place: .foundation(s, i))
            }
        }
        for col in 0..<7 {
            let cards = t.columns[col]
            let down = t.faceDown[col]
            let o = offsets(down: down, up: cards.count - down)
            var y = tableauY + cardH / 2
            for (i, c) in cards.enumerated() {
                out[c.code] = Spot(center: CGPoint(x: x(col: col), y: y), z: 300 + Double(i),
                                   faceUp: i >= down, place: .column(col, i))
                y += i < down ? o.down : o.up
            }
        }
        return out
    }

    /// Where the next card would sit on column `c`, for the drop ghost.
    func nextSpot(on c: Int, in t: Table) -> CGPoint {
        let cards = t.columns[c]
        guard !cards.isEmpty else { return columnTop(c) }
        let down = t.faceDown[c]
        let o = offsets(down: down, up: cards.count - down + 1)
        var y = tableauY + cardH / 2
        for i in 0..<cards.count { y += i < down ? o.down : o.up }
        return CGPoint(x: x(col: c), y: y)
    }
}
