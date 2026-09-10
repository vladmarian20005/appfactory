import FactoryKit
import SwiftUI

/// The new-counter sheet: a name, a colour from the fixed palette, an optional daily goal.
struct AddCounterView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var colorID = CounterPalette.default.id
    @State private var hasGoal = false
    @State private var goal = 8

    let onCreate: (String, String, Int) -> Void

    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name") {
                    TextField("What are you counting?", text: $name)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Colour") {
                    Picker("Colour", selection: $colorID) {
                        ForEach(CounterPalette.all) { swatch in
                            Label {
                                Text(swatch.label)
                            } icon: {
                                Image(systemName: "circle.fill").foregroundStyle(swatch.color)
                            }
                            .tag(swatch.id)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }

                Section {
                    Toggle("Daily goal", isOn: $hasGoal)
                    if hasGoal {
                        Stepper("\(goal) a day", value: $goal, in: 1...500)
                    }
                } footer: {
                    Text("A goal draws a ring on the counter. Leave it off and Tallies just counts.")
                }
            }
            .navigationTitle("New counter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        Haptics.tap()
                        onCreate(trimmedName, colorID, hasGoal ? goal : 0)
                        dismiss()
                    }
                    .disabled(trimmedName.isEmpty)
                }
            }
        }
    }
}
