import FactoryKit
import SwiftData
import SwiftUI

struct TodayView: View {
    @State private var day = Calendar.current.startOfDay(for: .now)
    var body: some View {
        DayView(day: day)
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { shift(-1) } label: { Image(systemName: "chevron.left") }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { shift(1) } label: { Image(systemName: "chevron.right") }
                        .disabled(Calendar.current.isDateInToday(day))
                }
            }
    }

    private var title: String {
        if Calendar.current.isDateInToday(day) { return "Today" }
        if Calendar.current.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    private func shift(_ n: Int) {
        Haptics.tap()
        day = Calendar.current.date(byAdding: .day, value: n, to: day) ?? day
    }
}

struct DayView: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [FoodEntry]
    @AppStorage("goal.calories") private var goalCalories = 2000
    @AppStorage("goal.protein") private var goalProtein = 150
    @AppStorage("goal.carbs") private var goalCarbs = 200
    @AppStorage("goal.fat") private var goalFat = 65
    @State private var adding: Meal?
    @State private var editing: FoodEntry?
    @State private var showGoals = false
    let day: Date

    init(day: Date) {
        self.day = day
        let start = Calendar.current.startOfDay(for: day)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        _entries = Query(filter: #Predicate<FoodEntry> { $0.date >= start && $0.date < end }, sort: [SortDescriptor(\FoodEntry.date)])
    }

    private var totals: DayTotals { DayTotals(entries) }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryCard
                ForEach(Meal.allCases) { meal in
                    mealCard(meal)
                }
                Text("Logging, barcode and macros are free, always.")
                    .font(.footnote).foregroundStyle(.tertiary).padding(.top, 8)
            }
            .padding(FactoryTheme.padding)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(item: $adding) { meal in AddFoodView(meal: meal, mode: DebugFlags.screen == "scan" ? .scan : .search) }
        .sheet(item: $editing) { entry in EditEntrySheet(entry: entry).presentationDetents([.medium]) }
        .sheet(isPresented: $showGoals) { GoalsView() }
        .onAppear {
            if DebugFlags.screen == "add" || DebugFlags.screen == "scan" { adding = Meal.forNow() }
            if DebugFlags.screen == "goals" { showGoals = true }
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 18) {
            HStack(spacing: 24) {
                CalorieRing(consumed: totals.calories, goal: Double(goalCalories))
                    .frame(width: 150, height: 150)
                VStack(alignment: .leading, spacing: 12) {
                    MacroBar(label: "Protein", value: totals.protein, goal: Double(goalProtein), color: .orange)
                    MacroBar(label: "Carbs", value: totals.carbs, goal: Double(goalCarbs), color: .blue)
                    MacroBar(label: "Fat", value: totals.fat, goal: Double(goalFat), color: .pink)
                }
            }
        }
        .factoryCard()
        .contentShape(Rectangle())
        .onTapGesture { showGoals = true }
    }

    private func mealCard(_ meal: Meal) -> some View {
        let items = entries.filter { $0.meal == meal }
        let kcal = items.reduce(0) { $0 + $1.totalCalories }
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(meal.title, systemImage: meal.symbol).font(.headline)
                Spacer()
                if kcal > 0 { Text("\(kcal.kcal) kcal").foregroundStyle(.secondary).monospacedDigit() }
                Button {
                    Haptics.tap()
                    adding = meal
                } label: { Image(systemName: "plus.circle.fill").font(.title2) }
                .buttonStyle(.plain)
                .foregroundStyle(Color.accentColor)
            }
            if items.isEmpty {
                Text("Nothing logged").font(.subheadline).foregroundStyle(.tertiary)
            } else {
                ForEach(items) { e in
                    Button { editing = e } label: {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(e.name).foregroundStyle(.primary)
                                Text(detail(e)).font(.footnote).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(e.totalCalories.kcal).monospacedDigit().foregroundStyle(.primary)
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions { Button("Delete", role: .destructive) { delete(e) } }
                }
            }
        }
        .factoryCard()
    }

    private func detail(_ e: FoodEntry) -> String {
        var parts: [String] = []
        if let b = e.brand { parts.append(b) }
        if e.servings != 1 { parts.append("\(e.servings.formatted(.number.precision(.fractionLength(0...2)))) × \(e.servingLabel)") } else if e.servingLabel != "serving" { parts.append(e.servingLabel) }
        parts.append("P \(e.totalProtein.grams) · C \(e.totalCarbs.grams) · F \(e.totalFat.grams)")
        return parts.joined(separator: " · ")
    }

    private func delete(_ e: FoodEntry) {
        context.delete(e)
        try? context.save()
    }
}

struct CalorieRing: View {
    let consumed: Double
    let goal: Double
    private var progress: Double { goal > 0 ? min(consumed / goal, 1) : 0 }
    private var over: Bool { consumed > goal }
    var body: some View {
        ZStack {
            Circle().stroke(Color(.tertiarySystemFill), lineWidth: 14)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(over ? Color.red : Color.accentColor, style: StrokeStyle(lineWidth: 14, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 0.5), value: progress)
            VStack(spacing: 2) {
                Text(consumed.kcal).scaledFont(size: 34, weight: .bold, design: .rounded).monospacedDigit()
                Text(over ? "\((consumed - goal).kcal) over" : "\((goal - consumed).kcal) left")
                    .font(.footnote).foregroundStyle(over ? .red : .secondary)
                Text("of \(goal.kcal)").font(.caption2).foregroundStyle(.tertiary)
            }
        }
    }
}

struct MacroBar: View {
    let label: String
    let value: Double
    let goal: Double
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label).font(.subheadline.weight(.medium))
                Spacer()
                Text("\(value.grams) / \(goal.grams)").font(.footnote).foregroundStyle(.secondary).monospacedDigit()
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill))
                    Capsule().fill(color).frame(width: goal > 0 ? geo.size.width * min(value / goal, 1) : 0)
                }
            }
            .frame(height: 8)
        }
    }
}

struct EditEntrySheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Bindable var entry: FoodEntry
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(entry.name).font(.headline)
                    Picker("Meal", selection: Binding(get: { entry.meal }, set: { entry.meal = $0 })) {
                        ForEach(Meal.allCases) { Text($0.title).tag($0) }
                    }
                    Stepper(value: $entry.servings, in: 0.25...20, step: 0.25) {
                        LabeledContent("Amount", value: "\(entry.servings.formatted(.number.precision(.fractionLength(0...2)))) × \(entry.servingLabel)")
                    }
                }
                Section("Totals") {
                    LabeledContent("Calories", value: "\(entry.totalCalories.kcal) kcal")
                    LabeledContent("Protein", value: entry.totalProtein.grams)
                    LabeledContent("Carbs", value: entry.totalCarbs.grams)
                    LabeledContent("Fat", value: entry.totalFat.grams)
                }
                Section {
                    Button("Delete", role: .destructive) {
                        context.delete(entry)
                        try? context.save()
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { try? context.save(); dismiss() } } }
        }
    }
}
