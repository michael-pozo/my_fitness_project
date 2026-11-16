import SwiftData
import SwiftUI

/// Edit a routine's name, goal and workouts. Changes save automatically.
struct RoutineEditorView: View {
    @Environment(\.modelContext) private var context
    @Bindable var routine: Routine

    @State private var newWorkout: Workout?

    var body: some View {
        Form {
            Section("Routine") {
                TextField("Name", text: $routine.name)
                TextField("Goal (optional)", text: $routine.goal, axis: .vertical)
            }

            Section {
                if routine.isActive {
                    Label("Active routine", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.tint)
                } else {
                    Button("Make Active Routine") {
                        RoutineStore.setActive(routine, in: context)
                    }
                }
            }

            Section {
                ForEach(routine.sortedWorkouts) { workout in
                    NavigationLink(value: workout) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(workout.name.isEmpty ? "Unnamed workout" : workout.name)
                            Text("\(workout.exercises.count) exercise\(workout.exercises.count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteWorkouts)
                .onMove(perform: moveWorkouts)

                Button("Add Workout", systemImage: "plus") {
                    newWorkout = routine.addWorkout(named: "Workout \(routine.workouts.count + 1)")
                }
            } header: {
                Text("Workouts")
            } footer: {
                Text("e.g. \"Day A – Legs\". Tap Edit to reorder.")
            }
        }
        .navigationTitle(routine.name.isEmpty ? "Routine" : routine.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
        .navigationDestination(for: Workout.self) { workout in
            WorkoutEditorView(workout: workout)
        }
        .navigationDestination(item: $newWorkout) { workout in
            WorkoutEditorView(workout: workout)
        }
    }

    private func deleteWorkouts(at offsets: IndexSet) {
        let sorted = routine.sortedWorkouts
        for index in offsets {
            let workout = sorted[index]
            routine.workouts.removeAll { $0 === workout }
            context.delete(workout)
        }
    }

    private func moveWorkouts(from source: IndexSet, to destination: Int) {
        var sorted = routine.sortedWorkouts
        sorted.move(fromOffsets: source, toOffset: destination)
        for (index, workout) in sorted.enumerated() { workout.order = index }
    }
}
