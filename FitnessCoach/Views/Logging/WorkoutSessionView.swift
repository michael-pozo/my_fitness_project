import SwiftData
import SwiftUI

/// The full-screen workout in progress. Everything saves as you go, so the app can be
/// closed mid-workout and resumed later. Works without internet.
struct WorkoutSessionView: View {
    @Environment(\.dismiss) private var dismiss

    let session: Session
    /// Called when the user discards the workout; the parent deletes it after this screen closes.
    let onDiscard: () -> Void

    @State private var editingSet: SetLog?
    @State private var confirmingDiscard = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Label {
                            Text(session.startedAt, style: .timer).monospacedDigit()
                        } icon: {
                            Image(systemName: "timer")
                        }
                        Spacer()
                        Text("\(session.sets.count) set\(session.sets.count == 1 ? "" : "s") logged")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                }

                if let workout = session.workout {
                    ForEach(workout.sortedExercises) { planned in
                        ExerciseLogSection(planned: planned, session: session) { editingSet = $0 }
                    }
                } else {
                    Section {
                        Text("This workout was removed from its routine. Sets already logged are kept.")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(session.workoutName)
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Menu("More", systemImage: "ellipsis") {
                        Button("Discard Workout", systemImage: "trash", role: .destructive) {
                            confirmingDiscard = true
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Finish", action: finish)
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { hideKeyboard() }
                }
            }
            .confirmationDialog(
                session.sets.isEmpty ? "No sets logged. Discard this workout?" : "Discard this workout?",
                isPresented: $confirmingDiscard,
                titleVisibility: .visible
            ) {
                Button("Discard Workout", role: .destructive, action: onDiscard)
            } message: {
                if !session.sets.isEmpty {
                    Text("All \(session.sets.count) logged sets will be deleted.")
                }
            }
            .sheet(item: $editingSet) { set in
                EditSetView(set: set)
            }
        }
        // Keep the screen on during the workout.
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }

    private func finish() {
        if session.sets.isEmpty {
            confirmingDiscard = true
        } else {
            session.finishedAt = .now
            dismiss()
        }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
