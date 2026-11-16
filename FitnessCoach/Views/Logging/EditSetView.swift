import SwiftData
import SwiftUI

/// Correct or delete a logged set.
struct EditSetView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Bindable var set: SetLog

    /// Deleting happens after the sheet closes, so nothing tries to show a deleted set.
    @State private var deleteOnClose = false

    var body: some View {
        NavigationStack {
            Form {
                Section(set.exerciseName) {
                    if set.seconds != nil {
                        NumberStepper(label: "Seconds", value: $set.seconds.asDouble, step: 5)
                    } else {
                        HStack {
                            if set.weight != nil {
                                NumberStepper(label: "Weight (lb)", value: $set.weight, step: 5, allowsDecimals: true)
                            }
                            NumberStepper(label: "Reps", value: $set.reps.asDouble, step: 1)
                        }
                    }
                }

                Section("Left in the tank") {
                    Picker("Left in the tank", selection: $set.repsInReserve) {
                        ForEach(0...4, id: \.self) { value in
                            Text(SetLog.repsInReserveLabel(value)).tag(Optional(value))
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                Section {
                    Button("Delete Set", role: .destructive) {
                        deleteOnClose = true
                        dismiss()
                    }
                }
            }
            .navigationTitle("Edit Set")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onDisappear {
            if deleteOnClose { context.delete(set) }
        }
    }
}
