import FactoryKit
import SwiftUI

/// Laying a stave on the bench: name it, pick its pigment, set a goal or do not.
///
/// The hero is a bare stave across the top that takes the name as it is typed, burned in, and
/// takes the pigment band as it is picked — so the thing being made is visible before it
/// exists. Under it the system's `Form`, because a form is chrome and chrome should be the
/// system's.
struct LayStaveView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var colorID = Pigment.default.id
    @State private var hasGoal = false
    @State private var goal = 8

    let onLay: (String, String, Int) -> Void

    private var trimmed: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                preview
                Form {
                    Section {
                        TextField("What is this stave for?", text: $name)
                            .textInputAutocapitalization(.sentences)
                    }

                    Section {
                        pigments
                    } header: {
                        Text("Pigment")
                    }

                    Section {
                        Toggle("A chalk line", isOn: $hasGoal)
                        if hasGoal {
                            Stepper("\(goal) a day", value: $goal, in: 1...500)
                        }
                    } footer: {
                        Text("A goal puts a chalk line on the gauge. Leave it off and the stave just fills.")
                    }
                }
                .benchBackground()
            }
            .benchBackground()
            .navigationTitle("A new stave")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Leave it") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Lay it on the bench") {
                        Haptics.success()
                        onLay(trimmed, colorID, hasGoal ? goal : 0)
                        dismiss()
                    }
                    .disabled(trimmed.isEmpty)
                }
            }
        }
    }

    private var preview: some View {
        StaveBoard(pigment: Pigment.named(colorID).color) {
            ZStack(alignment: .topLeading) {
                Color.clear.frame(height: 78)
                StaveMarks(marks: [.cut, .cut, .cut], capacity: notchesPerGate * 2, notchDepth: 13)
                    .padding(.leading, 22)
                    .padding(.trailing, 14)
                    .padding(.top, 8)
                Text(trimmed.isEmpty ? "" : trimmed.uppercased())
                    .brandFont(.title3)
                    .foregroundStyle(.brandInk.opacity(0.42))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.leading, 24)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
            }
        }
        .rotationEffect(.degrees(-1.6))
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 6)
        .animation(Motion.resolved(Motion.snappy), value: colorID)
        .accessibilityHidden(true)
    }

    /// The six pots, as painted end-grain swatches. The chosen one is marked with a cut, not
    /// a checkmark: the notch is this app's selection mark everywhere it appears.
    private var pigments: some View {
        HStack(spacing: 12) {
            ForEach(Pigment.all) { pigment in
                Button {
                    Haptics.selection()
                    Tones.shared.play(.tap)
                    withMotion(Motion.snappy) { colorID = pigment.id }
                } label: {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(pigment.color)
                        .frame(height: 38)
                        .overlay(alignment: .top) {
                            if colorID == pigment.id {
                                NotchMark(mark: .cut, width: 9, depth: 15)
                                    .padding(.top, -1)
                            }
                        }
                        .overlay {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .strokeBorder(.brandInk.opacity(colorID == pigment.id ? 0.55 : 0.12),
                                              lineWidth: colorID == pigment.id ? 2 : 1)
                        }
                }
                .buttonStyle(.pressable(scale: 0.92, haptic: false))
                .accessibilityLabel(pigment.label)
                .accessibilityAddTraits(colorID == pigment.id ? [.isSelected] : [])
            }
        }
        .padding(.vertical, 4)
        .listRowBackground(Color.clear)
    }
}
