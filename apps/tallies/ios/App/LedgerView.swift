import FactoryKit
import SwiftData
import SwiftUI

/// Screen 3, the ledger (Pro): every cut, by the day it was made. A day is legible as a
/// shape — the notches sit where in the day they happened — rather than as forty identical
/// rows of circle, name and time.
struct LedgerView: View {
    @EnvironmentObject private var store: Store
    @Binding var showPaywall: Bool

    @Query(sort: \Tap.at, order: .reverse) private var entries: [Tap]
    @Query(sort: \Counter.createdAt, order: .forward) private var counters: [Counter]
    @State private var opened: Date?

    var body: some View {
        Group {
            if !store.isProUnlocked {
                locked
            } else if entries.isEmpty {
                empty
            } else {
                ledger
            }
        }
        .benchBackground()
        .navigationTitle("Ledger")
    }

    private var locked: some View {
        emptyBench(art: "Rack",
                   headline: "The rack is behind the bench",
                   line: "Every cut you have made, by the day you made it, with the week and the month beside it.",
                   button: "See what Pro opens") { showPaywall = true }
    }

    private var empty: some View {
        emptyBench(art: "Gate",
                   headline: "No cuts yet",
                   line: "The ledger fills itself the moment a blade goes into anything.",
                   button: nil, action: nil)
    }

    private func emptyBench(art: String, headline: String, line: String,
                            button: String?, action: (() -> Void)?) -> some View {
        VStack(spacing: 0) {
            BenchEdge()
            ScrollView {
                VStack(spacing: 18) {
                    Image(art)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 280)
                        .ambientFloat(distance: 3, period: 4.4)
                    Text(headline)
                        .brandFont(.largeTitle)
                        .foregroundStyle(.brandInk)
                        .multilineTextAlignment(.center)
                    Text(line)
                        .brandFont(.body, weight: .regular)
                        .foregroundStyle(.brandInkSoft)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    if let button, let action {
                        Button(button, action: action)
                            .brandProminent()
                            .padding(.top, 6)
                    }
                }
                .padding(.horizontal, 26)
                .padding(.vertical, 24)
            }
        }
    }

    private var ledger: some View {
        VStack(spacing: 0) {
            BenchEdge()
            List {
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: 12) {
                            ForEach(totals) { row in
                                LedgerStave(row: row)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 10, trailing: 20))
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                }

                ForEach(days, id: \.day) { group in
                    DayGate(day: group.day,
                            taps: group.entries,
                            open: opened == group.day,
                            onToggle: { withMotion(Motion.snappy) { opened = opened == group.day ? nil : group.day } })
                        .listRowInsets(EdgeInsets(top: 6, leading: 20, bottom: 6, trailing: 20))
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .listStyle(.plain)
            .benchBackground()
        }
    }

    struct TotalRow: Identifiable {
        let id: PersistentIdentifier
        let name: String
        let color: Color
        let week: Int
        let month: Int
    }

    private var totals: [TotalRow] {
        let calendar = Calendar.current
        let now = Date.now
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        return counters.map {
            TotalRow(id: $0.persistentModelID,
                     name: $0.name,
                     color: $0.pigment.color,
                     week: max(0, $0.total(since: weekStart)),
                     month: max(0, $0.total(since: monthStart)))
        }
    }

    private struct DayGroup {
        let day: Date
        let entries: [Tap]
    }

    private var days: [DayGroup] {
        let calendar = Calendar.current
        let buckets = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.at) }
        return buckets.keys.sorted(by: >).map { DayGroup(day: $0, entries: buckets[$0] ?? []) }
    }
}

/// The week and the month for one stave, drawn rather than tabulated — explicitly not a row
/// of identical number tiles with grey captions, which is what the category leader ships.
private struct LedgerStave: View {
    let row: LedgerView.TotalRow

    var body: some View {
        StaveBoard(pigment: row.color) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.name.uppercased())
                    .stencilCaps()
                    .foregroundStyle(.brandInkSoft)
                    .lineLimit(1)
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(row.week)")
                        .brandDisplay(size: 34, relativeTo: .title)
                        .monospacedDigit()
                        .foregroundStyle(.brandInk)
                    Text("\(row.month)")
                        .brandFont(.callout)
                        .monospacedDigit()
                        .foregroundStyle(.brandInkSoft)
                }
            }
            .padding(.leading, 22)
            .padding(.trailing, 14)
            .padding(.vertical, 10)
            .frame(minWidth: 120, alignment: .leading)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(row.name): \(row.week) this week, \(row.month) this month")
    }
}

/// One day: a gate cut into a rule with the date beside it, and that day's cuts placed on an
/// ash strip by the time they happened. Tapping it opens the individual times.
private struct DayGate: View {
    let day: Date
    let taps: [Tap]
    let open: Bool
    let onToggle: () -> Void

    private var cuts: Int { taps.reduce(0) { $0 + max(0, $1.delta) } }
    private var waxes: Int { taps.reduce(0) { $0 + max(0, -$1.delta) } }

    var body: some View {
        Button(action: onToggle) {
            StaveBoard(pigment: nil) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
                            .stencilCaps()
                            .foregroundStyle(.brandInkSoft)
                        Spacer()
                        Text("\(cuts)")
                            .brandFont(.headline)
                            .monospacedDigit()
                            .foregroundStyle(.brandInk)
                    }
                    DayStrip(taps: taps)
                    if open {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(taps.sorted { $0.at < $1.at }) { tap in
                                HStack(spacing: 8) {
                                    NotchMark(mark: tap.delta > 0 ? .cut : .wax, width: 6, depth: 11)
                                    Text(tap.at.formatted(date: .omitted, time: .shortened))
                                        .brandFont(.caption, weight: .regular)
                                        .monospacedDigit()
                                        .foregroundStyle(.brandInkSoft)
                                    Text(tap.counter?.name ?? "")
                                        .brandFont(.caption, weight: .regular)
                                        .foregroundStyle(.brandInkSoft.opacity(0.8))
                                        .lineLimit(1)
                                }
                            }
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(14)
            }
        }
        .buttonStyle(.pressable(scale: 0.99))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(day.formatted(.dateTime.weekday(.wide).day().month(.wide))): \(cuts) cut\(waxes > 0 ? ", \(waxes) waxed" : "")")
        .accessibilityHint("Opens the times")
    }
}

/// A day as a shape: each cut a notch on an ash rule, standing where in the day it landed.
private struct DayStrip: View {
    let taps: [Tap]

    @Environment(\.brand) private var brand

    var body: some View {
        Canvas { context, size in
            context.fill(Path(CGRect(x: 0, y: 12, width: size.width, height: 1.2)),
                         with: .color(brand.palette.ink.opacity(0.22)))
            let calendar = Calendar.current
            for tap in taps {
                let day = calendar.startOfDay(for: tap.at)
                let fraction = min(1, max(0, tap.at.timeIntervalSince(day) / 86_400))
                let x = 2 + (size.width - 6) * fraction
                let colour = tap.delta > 0 ? brand.palette.ink.opacity(0.55) : brand.palette.miss.opacity(0.55)
                context.fill(Path(CGRect(x: x, y: 0, width: 2, height: 13)), with: .color(colour))
            }
        }
        .frame(height: 14)
        .accessibilityHidden(true)
    }
}
