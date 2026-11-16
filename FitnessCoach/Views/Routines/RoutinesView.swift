import SwiftData
import SwiftUI

/// All routines (shown as a sheet): pick the active one, create, edit or delete.
struct RoutinesView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Routine.createdAt, order: .reverse) private var routines: [Routine]

    @State private var editingRoutine: Routine?

    var body: some View {
        NavigationStack {
            List {
                if routines.isEmpty {
                    Text("No routines yet.").foregroundStyle(.secondary)
                }
                ForEach(routines) { routine in
                    NavigationLink(value: routine) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(routine.name)
                                Text("\(routine.workouts.count) workout\(routine.workouts.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if routine.isActive {
                                Text("Active")
                                    .font(.caption.bold())
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                    .swipeActions(edge: .leading) {
                        if !routine.isActive {
                            Button("Make Active") { RoutineStore.setActive(routine, in: context) }
                                .tint(.green)
                        }
                    }
                }
                .onDelete { offsets in
                    for index in offsets { context.delete(routines[index]) }
                }
            }
            .navigationTitle("Routines")
            .navigationDestination(for: Routine.self) { routine in
                RoutineEditorView(routine: routine)
            }
            .navigationDestination(item: $editingRoutine) { routine in
                RoutineEditorView(routine: routine)
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu("Add", systemImage: "plus") {
                        Button("New Routine") {
                            let routine = Routine(name: "New Routine")
                            context.insert(routine)
                            if !routines.contains(where: \.isActive) {
                                RoutineStore.setActive(routine, in: context)
                            }
                            editingRoutine = routine
                        }
                        Button("Sample Routine") {
                            RoutineStore.addSampleRoutine(to: context)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    RoutinesView()
        .modelContainer(for: [Routine.self, Session.self], inMemory: true)
}
