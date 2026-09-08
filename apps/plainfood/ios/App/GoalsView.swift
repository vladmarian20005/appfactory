import FactoryKit
import SwiftUI

struct GoalsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("goal.calories") private var calories = 2000
    @AppStorage("goal.protein") private var protein = 150
    @AppStorage("goal.carbs") private var carbs = 200
    @AppStorage("goal.fat") private var fat = 65

    var body: some View {
        NavigationStack {
            Form {
                budgetSection
                macroSection
                presetSection
            }
            .navigationTitle("Goals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
        }
    }

    private var macroKcal: Int { protein * 4 + carbs * 4 + fat * 9 }

    private var budgetSection: some View {
        Section("Daily budget") {
            Stepper(value: $calories, in: 800...6000, step: 50) {
                LabeledContent("Calories", value: "\(calories) kcal")
            }
        }
    }

    private var macroSection: some View {
        Section {
            Stepper(value: $protein, in: 20...400, step: 5) { LabeledContent("Protein", value: "\(protein) g") }
            Stepper(value: $carbs, in: 20...600, step: 5) { LabeledContent("Carbs", value: "\(carbs) g") }
            Stepper(value: $fat, in: 10...300, step: 5) { LabeledContent("Fat", value: "\(fat) g") }
        } header: {
            Text("Macros")
        } footer: {
            Text("Macros add up to \(macroKcal) kcal. Presets set common splits; adjust freely.")
        }
    }

    private var presetSection: some View {
        Section("Presets") {
            PresetButton(title: "Maintain · 2000 kcal, 150P / 200C / 65F") { apply(2000, 150, 200, 65) }
            PresetButton(title: "Cut · 1600 kcal, 150P / 130C / 50F") { apply(1600, 150, 130, 50) }
            PresetButton(title: "Bulk · 2800 kcal, 180P / 330C / 85F") { apply(2800, 180, 330, 85) }
        }
    }

    private func apply(_ c: Int, _ p: Int, _ cb: Int, _ f: Int) {
        Haptics.tap()
        calories = c
        protein = p
        carbs = cb
        fat = f
    }
}

private struct PresetButton: View {
    let title: String
    let action: () -> Void
    var body: some View { Button(title, action: action) }
}
