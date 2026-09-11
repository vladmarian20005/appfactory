import SwiftUI

/// One tube: a glass column with the liquid stacked bottom-first.
///
/// Drawn rather than assembled out of controls, because it is content, not a control — the
/// standard components are kept for everything the system owns (buttons, lists, sheets,
/// toolbars) so the iOS 26 SDK can style them.
struct TubeView: View {
    let contents: [Int]
    let style: BoardStyle
    let width: CGFloat
    let unitHeight: CGFloat
    var isSelected = false
    /// The tube the hint wants liquid to come out of.
    var isHintSource = false
    /// The tube the hint wants it to go into.
    var isHintTarget = false

    private var hinted: Bool { isHintSource || isHintTarget }

    private var shape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: width * 0.16,
                               bottomLeadingRadius: width * 0.46,
                               bottomTrailingRadius: width * 0.46,
                               topTrailingRadius: width * 0.16,
                               style: .continuous)
    }

    private var outline: Color {
        if isSelected || hinted { return .accentColor }
        return Color.primary.opacity(0.12)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            shape.fill(Color(.secondarySystemGroupedBackground))
            VStack(spacing: 0) {
                ForEach(Array(contents.enumerated()).reversed(), id: \.offset) { slot, color in
                    unit(color, isFloor: slot == 0)
                }
            }
            .frame(width: width)
            .clipShape(shape)
        }
        .frame(width: width, height: unitHeight * CGFloat(Board.capacity))
        .overlay {
            shape.strokeBorder(outline, lineWidth: isSelected || hinted ? 3 : 1.5)
        }
        .overlay(alignment: .top) {
            // An arrow out of one tube and into the other says which way the hint pours;
            // two accent borders on their own do not.
            if hinted {
                Image(systemName: isHintSource ? "arrow.up" : "arrow.down")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(5)
                    .background(Color.accentColor, in: Circle())
                    .offset(y: -unitHeight * 0.42)
            }
        }
        // A lift rather than a bounce: the capture tooling waits for the screen to stop
        // moving, and a tube that never stops moving is a blank screenshot.
        .offset(y: isSelected ? -unitHeight * 0.34 : 0)
        .animation(.easeOut(duration: 0.16), value: isSelected)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
        .accessibilityHint(isSelected ? "Selected. Tap a tube to pour into it."
                                      : "Tap to pour from this tube.")
    }

    @ViewBuilder
    private func unit(_ color: Int, isFloor: Bool) -> some View {
        Rectangle()
            .fill(style.color(color))
            .frame(height: unitHeight)
            .overlay {
                if let symbol = style.symbol(color) {
                    Image(systemName: symbol)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }
            .overlay(alignment: .top) {
                if !isFloor {
                    Rectangle().fill(.black.opacity(0.10)).frame(height: 1)
                }
            }
    }

    private var label: String {
        guard !contents.isEmpty else { return "Empty tube" }
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
        return "Tube: from the bottom, \(described)."
    }
}

/// Lays the tubes out in at most two rows, so even the widest board fits a phone in portrait
/// without scrolling.
struct BoardView: View {
    let board: Board
    let style: BoardStyle
    let selection: Int?
    let hint: Move?
    let onTap: (Int) -> Void

    private var columns: Int {
        min(5, max(3, Int((Double(board.tubes.count) / 2).rounded(.up))))
    }

    private var rows: [[Int]] {
        var out: [[Int]] = []
        var row: [Int] = []
        for index in board.tubes.indices {
            row.append(index)
            if row.count == columns { out.append(row); row = [] }
        }
        if !row.isEmpty { out.append(row) }
        return out
    }

    var body: some View {
        GeometryReader { geo in
            let spacing = max(10.0, geo.size.width * 0.035)
            let available = geo.size.width - spacing * CGFloat(columns - 1)
            let width = min(82, available / CGFloat(columns))
            let unit = min(width * 0.95, (geo.size.height / CGFloat(rows.count) - spacing * 2) / CGFloat(Board.capacity))
            VStack(spacing: spacing * 1.6) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    HStack(spacing: spacing) {
                        ForEach(row, id: \.self) { index in
                            TubeView(contents: board.tubes[index],
                                     style: style,
                                     width: width,
                                     unitHeight: max(18, unit),
                                     isSelected: selection == index,
                                     isHintSource: hint?.from == index,
                                     isHintTarget: hint?.to == index)
                                .onTapGesture { onTap(index) }
                        }
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}
