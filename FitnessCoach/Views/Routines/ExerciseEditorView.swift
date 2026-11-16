import SwiftUI

/// Edit one planned exercise: target, rest, notes and alternatives. Changes save automatically.
struct ExerciseEditorView: View {
    @Bindable var exercise: PlannedExercise

    @State private var newAlternative = ""

    var body: some View {
        Form {
            Section {
                TextField("Exercise name", text: $exercise.name)
                Picker("Type", selection: $exercise.kind) {
                    ForEach(ExerciseKind.allCases) { kind in
                        Text(kind.label).tag(kind)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Stepper("Sets: \(exercise.sets)", value: $exercise.sets, in: 1...20)

                if exercise.kind == .timed {
                    numberField("Seconds per set", value: $exercise.targetSeconds, unit: "s")
                } else {
                    numberField("Reps", value: $exercise.repsLow, unit: nil)
                    numberField("Up to (optional)", value: $exercise.repsHigh, unit: nil)
                }

                if exercise.kind == .weighted {
                    LabeledContent("Weight") {
                        HStack {
                            TextField("0", value: $exercise.targetWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                            Text("lb").foregroundStyle(.secondary)
                        }
                    }
                }

                numberField("Rest", value: $exercise.restSeconds, unit: "s")
            } header: {
                Text("Target")
            } footer: {
                Text(exercise.prescription)
            }

            Section("Notes") {
                TextField("Cues, tempo, per-leg reps…", text: $exercise.notes, axis: .vertical)
            }

            Section {
                ForEach(exercise.alternatives, id: \.self) { alternative in
                    Text(alternative)
                }
                .onDelete { offsets in
                    exercise.alternatives.remove(atOffsets: offsets)
                }

                HStack {
                    TextField("Add an alternative", text: $newAlternative)
                        .onSubmit(addAlternative)
                    Button("Add", action: addAlternative)
                        .disabled(trimmedAlternative.isEmpty)
                }
            } header: {
                Text("Alternatives")
            } footer: {
                Text("Exercises you can swap to, e.g. when a machine is taken. Aim for 2–3.")
            }
        }
        .navigationTitle(exercise.name.isEmpty ? "New Exercise" : exercise.name)
        .navigationBarTitleDisplayMode(.inline)
        .scrollDismissesKeyboard(.interactively)
    }

    private var trimmedAlternative: String {
        newAlternative.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addAlternative() {
        let name = trimmedAlternative
        guard !name.isEmpty, !exercise.alternatives.contains(name) else { return }
        exercise.alternatives.append(name)
        newAlternative = ""
    }

    /// A labeled number field for optional whole numbers.
    private func numberField(_ label: String, value: Binding<Int?>, unit: String?) -> some View {
        LabeledContent(label) {
            HStack {
                TextField("–", value: value, format: .number)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.trailing)
                if let unit { Text(unit).foregroundStyle(.secondary) }
            }
        }
    }
}
