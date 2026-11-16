import SwiftData
import SwiftUI

/// The Workouts tab: shows the active routine, or ways to create one.
struct WorkoutsView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Routine> { $0.isActive }) private var activeRoutines: [Routine]

    @State private var showingRoutines = false
    @State private var editingRoutine: Routine?

    var body: some View {
        NavigationStack {
            Group {
                if let routine = activeRoutines.first {
                    ActiveRoutineView(routine: routine)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Routines", systemImage: "list.bullet") { showingRoutines = true }
                }
                if let routine = activeRoutines.first {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Edit") { editingRoutine = routine }
                    }
                }
            }
            .navigationDestination(item: $editingRoutine) { routine in
                RoutineEditorView(routine: routine)
            }
            .sheet(isPresented: $showingRoutines) {
                RoutinesView()
            }
        }
        .onAppear(perform: seedSampleForTesting)
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Active Routine", systemImage: "dumbbell")
        } description: {
            Text("Create a routine by hand, or add the sample to try things out. Creating routines with Claude in the Coach tab is coming soon.")
        } actions: {
            Button("Create Routine") {
                let routine = Routine(name: "New Routine")
                context.insert(routine)
                RoutineStore.setActive(routine, in: context)
                editingRoutine = routine
            }
            .buttonStyle(.borderedProminent)

            Button("Add Sample Routine") {
                RoutineStore.addSampleRoutine(to: context)
            }
        }
    }

    /// Debug builds launched with `-seedSample` get the sample routine automatically
    /// (used to check the app in the simulator without tapping through it).
    private func seedSampleForTesting() {
        #if DEBUG
        guard ProcessInfo.processInfo.arguments.contains("-seedSample") else { return }
        let count = (try? context.fetchCount(FetchDescriptor<Routine>())) ?? 0
        if count == 0 { RoutineStore.addSampleRoutine(to: context) }
        #endif
    }
}

/// Read-only view of the active routine: each workout and its exercises.
struct ActiveRoutineView: View {
    let routine: Routine

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text(routine.name).font(.title2.bold())
                    if !routine.goal.isEmpty {
                        Text(routine.goal).foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            if routine.workouts.isEmpty {
                Section {
                    Text("This routine has no workouts yet. Tap Edit to add some.")
                        .foregroundStyle(.secondary)
                }
            }

            ForEach(routine.sortedWorkouts) { workout in
                Section(workout.name) {
                    if workout.exercises.isEmpty {
                        Text("No exercises yet").foregroundStyle(.secondary)
                    }
                    ForEach(workout.sortedExercises) { exercise in
                        ExerciseSummaryRow(exercise: exercise)
                    }
                }
            }
        }
    }
}

/// Exercise name with its prescription, e.g. "Back Squat · 4 × 6–8 @ 135 lb".
struct ExerciseSummaryRow: View {
    let exercise: PlannedExercise

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(exercise.name.isEmpty ? "Unnamed exercise" : exercise.name)
            Text(exercise.prescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    WorkoutsView()
        .modelContainer(for: [Routine.self, Session.self], inMemory: true)
}
