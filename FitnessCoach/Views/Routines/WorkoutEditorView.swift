import SwiftData
import SwiftUI

/// Edit one workout's name and its exercises. Changes save automatically.
struct WorkoutEditorView: View {
    @Environment(\.modelContext) private var context
    @Bindable var workout: Workout

    @State private var newExercise: PlannedExercise?

    var body: some View {
        Form {
            Section("Workout") {
                TextField("Name", text: $workout.name)
            }

            Section {
                ForEach(workout.sortedExercises) { exercise in
                    NavigationLink(value: exercise) {
                        ExerciseSummaryRow(exercise: exercise)
                    }
                }
                .onDelete(perform: deleteExercises)
                .onMove(perform: moveExercises)

                Button("Add Exercise", systemImage: "plus") {
                    newExercise = workout.addExercise(named: "")
                }
            } header: {
                Text("Exercises")
            } footer: {
                Text("Tap Edit to reorder.")
            }
        }
        .navigationTitle(workout.name.isEmpty ? "Workout" : workout.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .navigationDestination(for: PlannedExercise.self) { exercise in
            ExerciseEditorView(exercise: exercise)
        }
        .navigationDestination(item: $newExercise) { exercise in
            ExerciseEditorView(exercise: exercise)
        }
    }

    private func deleteExercises(at offsets: IndexSet) {
        let sorted = workout.sortedExercises
        for index in offsets {
            let exercise = sorted[index]
            workout.exercises.removeAll { $0 === exercise }
            context.delete(exercise)
        }
    }

    private func moveExercises(from source: IndexSet, to destination: Int) {
        var sorted = workout.sortedExercises
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, exercise) in sorted.enumerated() { exercise.order = index }
    }
}
