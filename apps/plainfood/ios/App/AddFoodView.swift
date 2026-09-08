import FactoryKit
import SwiftData
import SwiftUI

struct AddFoodView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State var meal: Meal
    @State private var mode: Mode = .search
    @State private var query = ""
    @State private var results: [FoodItem] = []
    @State private var searching = false
    @State private var error: String?
    @State private var picked: FoodItem?
    @State private var barcodeText = ""
    @State private var lookingUp = false
    @Query(sort: \FoodEntry.date, order: .reverse) private var recent: [FoodEntry]

    enum Mode: String, CaseIterable, Identifiable {
        case search = "Search", scan = "Scan", manual = "Manual"
        var id: String { rawValue }
    }

    init(meal: Meal, mode: Mode = .search) {
        _meal = State(initialValue: meal)
        _mode = State(initialValue: mode)
        _query = State(initialValue: DebugFlags.query ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $mode) {
                    ForEach(Mode.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 8)

                switch mode {
                case .search: searchView
                case .scan: scanView
                case .manual: ManualEntryView(meal: meal) { dismiss() }
                }
            }
            .navigationTitle("Add to \(meal.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .principal) {
                    Picker("Meal", selection: $meal) { ForEach(Meal.allCases) { Text($0.title).tag($0) } }
                        .pickerStyle(.menu)
                }
            }
            .sheet(item: $picked) { item in
                PortionSheet(item: item, meal: meal) { dismiss() }
                    .presentationDetents([.medium, .large])
            }
        }
    }

    // MARK: Search

    private var recentItems: [FoodItem] {
        var seen = Set<String>()
        var out: [FoodItem] = []
        for e in recent where seen.insert(e.name).inserted {
            out.append(FoodItem(id: "recent-\(e.name)", name: e.name, brand: e.brand, kcalPer100g: e.calories, proteinPer100g: e.protein, carbsPer100g: e.carbs, fatPer100g: e.fat, servingGrams: 100, barcode: e.barcode))
            if out.count == 12 { break }
        }
        return out
    }

    private var searchView: some View {
        List {
            if query.trimmingCharacters(in: .whitespaces).isEmpty {
                if recentItems.isEmpty {
                    ContentUnavailableView("Search any food", systemImage: "magnifyingglass", description: Text("Try “greek yogurt” or a brand name. Powered by Open Food Facts."))
                } else {
                    Section("Recent") {
                        ForEach(recentItems) { item in foodRow(item, perServing: true) }
                    }
                }
            } else if searching {
                HStack { Spacer(); ProgressView(); Spacer() }
            } else if let error {
                ContentUnavailableView("Could not search", systemImage: "wifi.exclamationmark", description: Text(error))
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                ForEach(results) { item in foodRow(item, perServing: false) }
            }
        }
        .listStyle(.insetGrouped)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Food or brand")
        .onSubmit(of: .search) { Task { await runSearch() } }
        .onChange(of: query) { _, q in
            if q.isEmpty { results = []; error = nil }
        }
        .task(id: query) {
            guard query.count >= 3 else { return }
            try? await Task.sleep(for: .milliseconds(450))
            if !Task.isCancelled { await runSearch() }
        }
    }

    @ViewBuilder
    private func foodRow(_ item: FoodItem, perServing: Bool) -> some View {
        Button {
            Haptics.tap()
            picked = item
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name).foregroundStyle(.primary)
                    Text([item.brand, perServing ? "per serving" : "per 100 g"].compactMap { $0 }.joined(separator: " · "))
                        .font(.footnote).foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(item.kcalPer100g.kcal) kcal").foregroundStyle(.secondary).monospacedDigit()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func runSearch() async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        searching = true
        error = nil
        do {
            results = try await FoodAPI.search(q)
        } catch {
            self.error = "Check your connection and try again."
            results = []
        }
        searching = false
    }

    // MARK: Scan

    private var scanView: some View {
        VStack(spacing: 16) {
            if BarcodeScannerView.isAvailable {
                BarcodeScannerView { code in
                    barcodeText = code
                    Task { await lookup(code) }
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal)
                Text("Point at a barcode").font(.footnote).foregroundStyle(.secondary)
            } else {
                ContentUnavailableView("Camera not available here", systemImage: "barcode.viewfinder", description: Text("Type the barcode number instead."))
                    .frame(height: 220)
            }
            HStack {
                TextField("Barcode number", text: $barcodeText)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                Button {
                    Task { await lookup(barcodeText) }
                } label: {
                    if lookingUp { ProgressView() } else { Text("Look up") }
                }
                .buttonStyle(.borderedProminent)
                .disabled(barcodeText.filter(\.isNumber).count < 8 || lookingUp)
            }
            .padding(.horizontal)
            if let error { Text(error).font(.footnote).foregroundStyle(.secondary) }
            Spacer()
        }
        .padding(.top, 8)
    }

    private func lookup(_ code: String) async {
        lookingUp = true
        error = nil
        defer { lookingUp = false }
        do {
            if let item = try await FoodAPI.product(barcode: code) {
                Haptics.success()
                picked = item
            } else {
                error = "No product found for \(code). Try search or manual entry."
            }
        } catch {
            self.error = "Check your connection and try again."
        }
    }
}

/// Pick the amount and save.
struct PortionSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    let item: FoodItem
    let meal: Meal
    let onSaved: () -> Void
    @State private var grams: Double
    @State private var useServings = false
    @State private var servings = 1.0

    init(item: FoodItem, meal: Meal, onSaved: @escaping () -> Void) {
        self.item = item
        self.meal = meal
        self.onSaved = onSaved
        _grams = State(initialValue: item.servingGrams ?? 100)
        _useServings = State(initialValue: item.servingGrams != nil)
    }

    private var effectiveGrams: Double { useServings ? (item.servingGrams ?? 100) * servings : grams }
    private var totals: (kcal: Double, p: Double, c: Double, f: Double) { item.scaled(grams: effectiveGrams) }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name).font(.headline)
                        if let b = item.brand { Text(b).font(.subheadline).foregroundStyle(.secondary) }
                    }
                }
                Section("Amount") {
                    if let s = item.servingGrams {
                        Toggle("Use servings (\(s.grams) each)", isOn: $useServings)
                    }
                    if useServings {
                        Stepper(value: $servings, in: 0.25...20, step: 0.25) {
                            LabeledContent("Servings", value: servings.formatted(.number.precision(.fractionLength(0...2))))
                        }
                    } else {
                        Stepper(value: $grams, in: 5...2000, step: 5) { LabeledContent("Grams", value: grams.grams) }
                    }
                }
                Section("This adds") {
                    LabeledContent("Calories", value: "\(totals.kcal.kcal) kcal")
                    LabeledContent("Protein", value: totals.p.grams)
                    LabeledContent("Carbs", value: totals.c.grams)
                    LabeledContent("Fat", value: totals.f.grams)
                }
            }
            .navigationTitle("Add to \(meal.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Back") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) { Button("Add") { save() }.bold() }
            }
        }
    }

    private func save() {
        let t = totals
        let label = useServings ? "serving" : "\(effectiveGrams.grams)"
        let entry = FoodEntry(meal: meal, name: item.name, brand: item.brand, calories: t.kcal, protein: t.p, carbs: t.c, fat: t.f, servings: 1, servingLabel: label, barcode: item.barcode)
        context.insert(entry)
        try? context.save()
        Haptics.success()
        dismiss()
        onSaved()
    }
}

struct ManualEntryView: View {
    @Environment(\.modelContext) private var context
    let meal: Meal
    let onSaved: () -> Void
    @State private var name = ""
    @State private var calories = ""
    @State private var protein = ""
    @State private var carbs = ""
    @State private var fat = ""
    @State private var servings = 1.0

    var body: some View {
        Form {
            Section("Food") {
                TextField("Name", text: $name)
            }
            Section("Per serving") {
                LabeledContent("Calories") { TextField("kcal", text: $calories).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                LabeledContent("Protein") { TextField("g", text: $protein).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                LabeledContent("Carbs") { TextField("g", text: $carbs).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
                LabeledContent("Fat") { TextField("g", text: $fat).keyboardType(.decimalPad).multilineTextAlignment(.trailing) }
            }
            Section {
                Stepper(value: $servings, in: 0.25...20, step: 0.25) {
                    LabeledContent("Servings", value: servings.formatted(.number.precision(.fractionLength(0...2))))
                }
                Button("Add to \(meal.title)") { save() }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || Double(calories) == nil)
            }
        }
    }

    private func save() {
        let entry = FoodEntry(meal: meal, name: name.trimmingCharacters(in: .whitespaces), calories: Double(calories) ?? 0, protein: Double(protein) ?? 0, carbs: Double(carbs) ?? 0, fat: Double(fat) ?? 0, servings: servings)
        context.insert(entry)
        try? context.save()
        Haptics.success()
        onSaved()
    }
}
