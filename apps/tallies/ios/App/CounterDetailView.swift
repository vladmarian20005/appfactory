import Charts
import FactoryKit
import SwiftData
import SwiftUI

/// Screen 2: one counter, big. The number, the two taps, the goal ring, and what the last
/// fortnight actually looked like.
struct CounterDetailView: View {
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var store: Store
    @Bindable var counter: Counter
    @Binding var showPaywall: Bool

    @State private var confirmingResetToday = false
    @State private var confirmingResetAll = false

    private var chartDays: Int {
        store.isProUnlocked ? AppInfo.proHistoryDays : AppInfo.freeHistoryDays
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                counterCard
                chartCard
                resetCard
            }
            .padding(FactoryTheme.padding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(counter.name)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var counterCard: some View {
        VStack(spacing: 20) {
            Text("\(counter.total)")
                .scaledFont(size: 84, weight: .bold, design: .rounded, relativeTo: .largeTitle)
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(counter.swatch.color)
                .accessibilityLabel("\(counter.total) in total")

            if counter.dailyGoal > 0 {
                goalRing
            } else {
                Text("\(counter.todayTotal) today")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 16) {
                stepButton(symbol: "minus", label: "Take one away", action: decrement)
                    .disabled(counter.total == 0)
                stepButton(symbol: "plus", label: "Add one", action: increment)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .factoryCard()
    }

    private var goalRing: some View {
        VStack(spacing: 8) {
            Gauge(value: Double(min(counter.todayTotal, counter.dailyGoal)), in: 0...Double(counter.dailyGoal)) {
                Text("Goal")
            } currentValueLabel: {
                Text("\(counter.todayTotal)").monospacedDigit()
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(counter.swatch.color)

            Text(counter.todayTotal >= counter.dailyGoal
                 ? "Goal met — \(counter.todayTotal) of \(counter.dailyGoal) today"
                 : "\(counter.todayTotal) of \(counter.dailyGoal) today")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .accessibilityElement(children: .combine)
    }

    private func stepButton(symbol: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.title.weight(.semibold))
                .frame(width: 76, height: 76)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.circle)
        .tint(counter.swatch.color)
        .accessibilityLabel(label)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Last \(chartDays) days").font(.headline)
                Spacer()
                if !store.isProUnlocked {
                    Button("Show \(AppInfo.proHistoryDays)") { showPaywall = true }
                        .font(.footnote)
                }
            }

            let totals = counter.dailyTotals(days: chartDays)
            Chart(totals) { day in
                BarMark(
                    x: .value("Day", day.day, unit: .day),
                    y: .value("Count", day.count)
                )
                .foregroundStyle(counter.swatch.color)
                .cornerRadius(4)
            }
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: chartDays > 7 ? 3 : 2)) { value in
                    AxisValueLabel(format: .dateTime.day().month(.defaultDigits))
                }
            }
            .frame(height: 180)
            .accessibilityLabel("Daily counts for the last \(chartDays) days")

            Text(summaryLine(for: totals))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .factoryCard()
    }

    private func summaryLine(for totals: [DayTotal]) -> String {
        let sum = totals.reduce(0) { $0 + $1.count }
        guard !totals.isEmpty else { return "Nothing counted yet." }
        let average = Double(sum) / Double(totals.count)
        return "\(sum) in \(chartDays) days, \(average.formatted(.number.precision(.fractionLength(0...1)))) a day on average."
    }

    private var resetCard: some View {
        VStack(spacing: 0) {
            Button(role: .destructive) { confirmingResetToday = true } label: {
                Label("Reset today", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .disabled(counter.todayTotal == 0)
            .padding(.vertical, 12)

            Divider()

            Button(role: .destructive) { confirmingResetAll = true } label: {
                Label("Reset everything", systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .disabled(counter.entries.isEmpty)
            .padding(.vertical, 12)
        }
        .factoryCard()
        .confirmationDialog("Clear today's \(counter.todayTotal) for \(counter.name)?",
                            isPresented: $confirmingResetToday, titleVisibility: .visible) {
            Button("Reset today", role: .destructive) { resetToday() }
            Button("Cancel", role: .cancel) {}
        }
        .confirmationDialog("Delete every tap for \(counter.name)?",
                            isPresented: $confirmingResetAll, titleVisibility: .visible) {
            Button("Reset everything", role: .destructive) { resetAll() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private func increment() {
        Haptics.tap()
        context.insert(Tap(delta: 1, counter: counter))
        try? context.save()
    }

    private func decrement() {
        Haptics.tap()
        context.insert(Tap(delta: -1, counter: counter))
        try? context.save()
    }

    private func resetToday() {
        let start = Calendar.current.startOfDay(for: .now)
        for entry in counter.entries where entry.at >= start { context.delete(entry) }
        try? context.save()
    }

    private func resetAll() {
        for entry in counter.entries { context.delete(entry) }
        try? context.save()
    }
}
