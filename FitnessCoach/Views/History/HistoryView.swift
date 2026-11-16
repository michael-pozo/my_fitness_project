import SwiftData
import SwiftUI

/// Finished workouts, newest first.
struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Query(filter: #Predicate<Session> { $0.finishedAt != nil }, sort: \Session.startedAt, order: .reverse)
    private var sessions: [Session]

    var body: some View {
        List {
            if sessions.isEmpty {
                ContentUnavailableView(
                    "No Workouts Yet",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Finished workouts will appear here.")
                )
            }
            ForEach(sessions) { session in
                NavigationLink(value: session) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(session.workoutName)
                        Text(subtitle(for: session))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .onDelete { offsets in
                for index in offsets { context.delete(sessions[index]) }
            }
        }
        .navigationTitle("History")
        // Note: the destination for tapping a session (SessionDetailView) is registered by
        // WorkoutsView. Registering it here caused an endless redraw loop (frozen app).
    }

    private func subtitle(for session: Session) -> String {
        var parts = [session.startedAt.formatted(date: .abbreviated, time: .shortened)]
        parts.append("\(session.sets.count) sets")
        if let duration = session.durationText { parts.append(duration) }
        return parts.joined(separator: " · ")
    }
}

/// Every set from one finished workout, grouped by exercise. Tap a set to correct it.
struct SessionDetailView: View {
    let session: Session

    @State private var editingSet: SetLog?

    var body: some View {
        List {
            Section {
                LabeledContent("Date", value: session.startedAt.formatted(date: .complete, time: .shortened))
                if let duration = session.durationText {
                    LabeledContent("Duration", value: duration)
                }
                if !session.routineName.isEmpty {
                    LabeledContent("Routine", value: session.routineName)
                }
            }

            ForEach(session.exerciseNamesInOrder, id: \.self) { name in
                let sets = session.sortedSets.filter { $0.exerciseName == name }
                Section {
                    ForEach(Array(sets.enumerated()), id: \.element.id) { index, set in
                        Button { editingSet = set } label: {
                            LoggedSetRow(number: index + 1, set: set)
                        }
                        .tint(.primary)
                    }
                } header: {
                    if let original = sets.first?.swappedFrom {
                        Text("\(name) (instead of \(original))")
                    } else {
                        Text(name)
                    }
                }
            }
        }
        .navigationTitle(session.workoutName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editingSet) { set in
            EditSetView(set: set)
        }
    }
}
