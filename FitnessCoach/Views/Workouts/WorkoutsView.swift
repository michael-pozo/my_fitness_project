import SwiftData
import SwiftUI

/// Screens the Workouts tab can open that aren't a single saved item.
enum WorkoutsRoute: Hashable {
    case history
}

/// The Workouts tab: shows the active routine, starts workouts, and links to history.
struct WorkoutsView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Routine> { $0.isActive }) private var activeRoutines: [Routine]
    @Query(filter: #Predicate<Session> { $0.finishedAt == nil }, sort: \Session.startedAt, order: .reverse)
    private var openSessions: [Session]

    /// Every screen pushed in this tab goes through this path. (Mixing `isPresented:`/`item:`
    /// destinations with value-based ones froze the app when opening History.)
    @State private var path = NavigationPath()
    @State private var showingRoutines = false
    @State private var loggingSession: Session?
    @State private var sessionToDiscard: Session?

    var body: some View {
        NavigationStack(path: $path) {
            Group {
                if let routine = activeRoutines.first {
                    ActiveRoutineView(
                        routine: routine,
                        openSession: openSessions.first,
                        onStart: start,
                        onResume: { loggingSession = $0 }
                    )
                } else {
                    emptyState
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Routines", systemImage: "list.bullet") { showingRoutines = true }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button("History", systemImage: "clock.arrow.circlepath") { path.append(WorkoutsRoute.history) }
                    if let routine = activeRoutines.first {
                        Button("Edit") { path.append(routine) }
                    }
                }
            }
            .navigationDestination(for: WorkoutsRoute.self) { route in
                switch route {
                case .history: HistoryView()
                }
            }
            .navigationDestination(for: Routine.self) { routine in
                RoutineEditorView(routine: routine)
            }
            .navigationDestination(for: Session.self) { session in
                SessionDetailView(session: session)
            }
            .sheet(isPresented: $showingRoutines) {
                RoutinesView()
            }
            .fullScreenCover(item: $loggingSession, onDismiss: deleteDiscardedSession) { session in
                WorkoutSessionView(session: session) {
                    sessionToDiscard = session
                    loggingSession = nil
                }
            }
        }
        .onAppear(perform: seedForTesting)
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
                path.append(routine)
            }
            .buttonStyle(.borderedProminent)

            Button("Add Sample Routine") {
                RoutineStore.addSampleRoutine(to: context)
            }
        }
    }

    private func start(_ workout: Workout) {
        loggingSession = Session.start(workout, in: context)
    }

    /// A discarded session is deleted only after its screen has closed.
    private func deleteDiscardedSession() {
        if let session = sessionToDiscard {
            context.delete(session)
            sessionToDiscard = nil
        }
    }

    /// Debug builds can be launched with test data, to check screens in the simulator:
    /// `-seedSample` adds the sample routine; `-startWorkout` also opens a workout with two sets logged.
    private func seedForTesting() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-showHistory"), path.isEmpty { path.append(WorkoutsRoute.history) }
        guard arguments.contains("-seedSample") || arguments.contains("-startWorkout") else { return }
        if ((try? context.fetchCount(FetchDescriptor<Routine>())) ?? 0) == 0 {
            RoutineStore.addSampleRoutine(to: context)
        }
        guard arguments.contains("-startWorkout"),
              openSessions.isEmpty,
              let workout = activeRoutines.first?.sortedWorkouts.first ?? (try? context.fetch(FetchDescriptor<Workout>()))?.first,
              let first = workout.sortedExercises.first
        else { return }
        let session = Session.start(workout, in: context)
        for (index, reps) in [8, 7].enumerated() {
            let set = SetLog(exerciseName: first.name, setNumber: index + 1, weight: first.targetWeight,
                             reps: reps, repsInReserve: 2 - index)
            context.insert(set)
            set.session = session
        }
        loggingSession = session
        #endif
    }
}

/// The active routine: each workout with a Start button, and its exercises.
struct ActiveRoutineView: View {
    let routine: Routine
    let openSession: Session?
    let onStart: (Workout) -> Void
    let onResume: (Session) -> Void

    var body: some View {
        List {
            if let openSession {
                Section {
                    Button {
                        onResume(openSession)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Resume \(openSession.workoutName)").font(.headline)
                                Text("Started \(openSession.startedAt.formatted(.relative(presentation: .named))) · \(openSession.sets.count) sets logged")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "play.circle.fill").font(.title)
                        }
                    }
                }
            }

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
                Section {
                    if workout.exercises.isEmpty {
                        Text("No exercises yet").foregroundStyle(.secondary)
                    }
                    ForEach(workout.sortedExercises) { exercise in
                        ExerciseSummaryRow(exercise: exercise)
                    }
                } header: {
                    HStack {
                        Text(workout.name)
                        Spacer()
                        Button("Start") { onStart(workout) }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                            .disabled(openSession != nil || workout.exercises.isEmpty)
                    }
                    .textCase(nil)
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
