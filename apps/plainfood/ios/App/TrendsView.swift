import Charts
import FactoryKit
import SwiftData
import SwiftUI

struct TrendsView: View {
    @EnvironmentObject private var store: Store
    @Query private var entries: [FoodEntry]
    @AppStorage("goal.calories") private var goalCalories = 2000
    @State private var window = 7
    @Binding var showPaywall: Bool

    init(showPaywall: Binding<Bool>) {
        _showPaywall = showPaywall
        let start = Calendar.current.date(byAdding: .day, value: -30, to: Calendar.current.startOfDay(for: .now)) ?? .now
        _entries = Query(filter: #Predicate<FoodEntry> { $0.date >= start }, sort: [SortDescriptor(\FoodEntry.date)])
    }

    private var proActive: Bool { store.isPro || DebugFlags.forcePro }

    struct DayPoint: Identifiable {
        let date: Date
        let calories: Double
        let protein: Double
        let carbs: Double
        let fat: Double
        var id: Date { date }
    }

    private var days: [DayPoint] {
        let cal = Calendar.current
        let today = cal.startOfDay(for: .now)
        return (0..<window).reversed().compactMap { offset in
            guard let d = cal.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let items = entries.filter { cal.isDate($0.date, inSameDayAs: d) }
            let t = DayTotals(items)
            return DayPoint(date: d, calories: t.calories, protein: t.protein, carbs: t.carbs, fat: t.fat)
        }
    }

    private var loggedDays: [DayPoint] { days.filter { $0.calories > 0 } }
    private var average: Double { loggedDays.isEmpty ? 0 : loggedDays.map(\.calories).reduce(0, +) / Double(loggedDays.count) }
    private var streak: Int {
        let cal = Calendar.current
        var n = 0
        var d = cal.startOfDay(for: .now)
        while entries.contains(where: { cal.isDate($0.date, inSameDayAs: d) }) {
            n += 1
            guard let prev = cal.date(byAdding: .day, value: -1, to: d) else { break }
            d = prev
            if n > 365 { break }
        }
        return n
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !proActive {
                    lockedCard
                } else {
                    Picker("Window", selection: $window) {
                        Text("7 days").tag(7)
                        Text("30 days").tag(30)
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: 12) {
                        Stat(title: "Daily average", value: "\(average.kcal)", unit: "kcal")
                        Stat(title: "Versus goal", value: average == 0 ? "—" : "\(((average - Double(goalCalories)) >= 0 ? "+" : ""))\((average - Double(goalCalories)).kcal)", unit: "kcal")
                        Stat(title: "Streak", value: "\(streak)", unit: streak == 1 ? "day" : "days")
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Calories").font(.headline)
                        Chart {
                            ForEach(days) { p in
                                BarMark(x: .value("Day", p.date, unit: .day), y: .value("kcal", p.calories))
                                    .foregroundStyle(p.calories > Double(goalCalories) ? Color.red.gradient : Color.accentColor.gradient)
                                    .cornerRadius(4)
                            }
                            RuleMark(y: .value("Goal", goalCalories))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                                .foregroundStyle(.secondary)
                                .annotation(position: .top, alignment: .trailing) {
                                    Text("goal \(goalCalories)").font(.caption2).foregroundStyle(.secondary)
                                }
                        }
                        .chartXAxis { AxisMarks(values: .stride(by: .day, count: window == 7 ? 1 : 5)) { _ in AxisValueLabel(format: .dateTime.day()); AxisGridLine() } }
                        .frame(height: 200)
                    }
                    .factoryCard()

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Macros").font(.headline)
                        Chart {
                            ForEach(days) { p in
                                BarMark(x: .value("Day", p.date, unit: .day), y: .value("g", p.protein)).foregroundStyle(by: .value("Macro", "Protein"))
                                BarMark(x: .value("Day", p.date, unit: .day), y: .value("g", p.carbs)).foregroundStyle(by: .value("Macro", "Carbs"))
                                BarMark(x: .value("Day", p.date, unit: .day), y: .value("g", p.fat)).foregroundStyle(by: .value("Macro", "Fat"))
                            }
                        }
                        .chartForegroundStyleScale(["Protein": Color.orange, "Carbs": Color.blue, "Fat": Color.pink])
                        .chartXAxis { AxisMarks(values: .stride(by: .day, count: window == 7 ? 1 : 5)) { _ in AxisValueLabel(format: .dateTime.day()); AxisGridLine() } }
                        .frame(height: 200)
                    }
                    .factoryCard()
                }
            }
            .padding(FactoryTheme.padding)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Trends")
    }

    private var lockedCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label("Trends is a Pro feature", systemImage: "chart.bar.xaxis").font(.headline)
            Text("Seven and thirty day calories and macros, weekly averages against your goal, and streaks. Logging, barcode and macros on Today stay free.")
                .foregroundStyle(.secondary)
            Button("See Pro") { showPaywall = true }.buttonStyle(.factoryPrimary)
        }
        .factoryCard()
    }
}

private struct Stat: View {
    let title: String
    let value: String
    let unit: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(value).font(.title3.bold()).monospacedDigit()
                Text(unit).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .factoryCard()
    }
}
