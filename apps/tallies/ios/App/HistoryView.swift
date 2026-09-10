import FactoryKit
import SwiftData
import SwiftUI

/// Screen 3, Pro: every tap across every counter, newest first, grouped by day, over a
/// per-counter total for the week and the month.
struct HistoryView: View {
    @EnvironmentObject private var store: Store
    @Binding var showPaywall: Bool

    @Query(sort: \Tap.at, order: .reverse) private var entries: [Tap]
    @Query(sort: \Counter.createdAt, order: .forward) private var counters: [Counter]

    var body: some View {
        Group {
            if !store.isProUnlocked {
                lockedState
            } else if entries.isEmpty {
                ContentUnavailableView("No taps yet",
                                       systemImage: "clock.arrow.circlepath",
                                       description: Text("Count something and it shows up here, with the day it happened."))
            } else {
                list
            }
        }
        .navigationTitle("History")
    }

    private var lockedState: some View {
        ContentUnavailableView {
            Label("History is Pro", systemImage: "lock.fill")
        } description: {
            Text("Every tap across every counter, grouped by day, with a total for the week and the month.")
        } actions: {
            Button("See Pro") { showPaywall = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private var list: some View {
        List {
            if !totals.isEmpty {
                Section("This week and this month") {
                    ForEach(totals) { row in
                        HStack {
                            Image(systemName: "circle.fill")
                                .font(.footnote)
                                .foregroundStyle(row.color)
                            Text(row.name).lineLimit(1)
                            Spacer(minLength: 8)
                            Text("\(row.week)").monospacedDigit()
                            Text("/").foregroundStyle(.tertiary)
                            Text("\(row.month)").monospacedDigit().foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel("\(row.name): \(row.week) this week, \(row.month) this month")
                    }
                }
            }

            ForEach(days, id: \.day) { group in
                Section(group.day.formatted(.dateTime.weekday(.wide).day().month(.wide))) {
                    ForEach(group.entries) { entry in
                        TapRow(tap: entry)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private struct TotalRow: Identifiable {
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
                     color: $0.swatch.color,
                     week: $0.total(since: weekStart),
                     month: $0.total(since: monthStart))
        }
    }

    private struct DayGroup {
        let day: Date
        let entries: [Tap]
    }

    /// Newest day first, and newest entry first inside each day.
    private var days: [DayGroup] {
        let calendar = Calendar.current
        let buckets = Dictionary(grouping: entries) { calendar.startOfDay(for: $0.at) }
        return buckets.keys.sorted(by: >).map { DayGroup(day: $0, entries: buckets[$0] ?? []) }
    }
}

struct TapRow: View {
    let tap: Tap

    private var counter: Counter? { tap.counter }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: tap.delta >= 0 ? "plus.circle.fill" : "minus.circle.fill")
                .foregroundStyle(counter?.swatch.color ?? .secondary)
                .symbolRenderingMode(.hierarchical)
            VStack(alignment: .leading, spacing: 2) {
                Text(counter?.name ?? "Deleted counter")
                    .font(.subheadline)
                    .lineLimit(1)
                Text(tap.at.formatted(date: .omitted, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            Text(tap.delta >= 0 ? "+\(tap.delta)" : "\(tap.delta)")
                .font(.subheadline.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(tap.delta >= 0 ? .primary : .secondary)
        }
        .accessibilityElement(children: .combine)
    }
}
