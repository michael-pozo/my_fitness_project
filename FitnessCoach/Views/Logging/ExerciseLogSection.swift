import SwiftData
import SwiftUI

/// One exercise during a workout: the sets logged so far, and a row for logging the next set.
/// Logging a set takes one tap: choose how many reps were left in the tank.
struct ExerciseLogSection: View {
    @Environment(\.modelContext) private var context

    let planned: PlannedExercise
    let session: Session
    let onEditSet: (SetLog) -> Void

    /// The exercise actually being done (differs from `planned.name` after a swap).
    @State private var performedName: String
    @State private var weight: Double?
    @State private var reps: Int?
    @State private var seconds: Int?
    @State private var addingExtraSet = false
    @State private var loggedCount = 0

    init(planned: PlannedExercise, session: Session, onEditSet: @escaping (SetLog) -> Void) {
        self.planned = planned
        self.session = session
        self.onEditSet = onEditSet

        // Pre-fill from the last set logged for this exercise, otherwise from the plan.
        let last = session.sortedSets.last { $0.plannedExerciseName == planned.name }
        _performedName = State(initialValue: last?.exerciseName ?? planned.name)
        _weight = State(initialValue: last?.weight ?? (planned.kind == .weighted ? planned.targetWeight : nil))
        _reps = State(initialValue: last?.reps ?? planned.repsLow)
        _seconds = State(initialValue: last?.seconds ?? planned.targetSeconds)
    }

    private var loggedSets: [SetLog] {
        session.sortedSets.filter { $0.plannedExerciseName == planned.name }
    }

    private var isSwapped: Bool { performedName != planned.name }
    private var isTimed: Bool { planned.kind == .timed }

    private var canLog: Bool {
        isTimed ? (seconds ?? 0) > 0 : (reps ?? 0) > 0
    }

    var body: some View {
        Section {
            ForEach(Array(loggedSets.enumerated()), id: \.element.id) { index, set in
                Button { onEditSet(set) } label: {
                    LoggedSetRow(number: index + 1, set: set)
                }
                .tint(.primary)
            }

            if loggedSets.count < planned.sets || addingExtraSet {
                inputRow
            } else {
                Button("Add Set", systemImage: "plus") { addingExtraSet = true }
            }
        } header: {
            header
        }
    }

    // MARK: Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline) {
                Text(performedName.isEmpty ? "Unnamed exercise" : performedName)
                    .font(.title3.bold())
                    .foregroundStyle(Color.primary) // section headers are grey by default
                Spacer()
                if !planned.alternatives.isEmpty {
                    swapMenu
                }
            }
            if isSwapped {
                Text("Instead of \(planned.name)")
                    .font(.caption)
            }
            Text(targetText)
                .font(.subheadline)
            if !planned.notes.isEmpty {
                Text(planned.notes)
                    .font(.caption)
            }
        }
        .textCase(nil)
        .padding(.bottom, 4)
    }

    private var targetText: String {
        var text = "Target: \(planned.prescription)"
        if let rest = planned.restSeconds { text += " · rest \(rest) s" }
        return text
    }

    private var swapMenu: some View {
        Menu {
            ForEach([planned.name] + planned.alternatives, id: \.self) { name in
                Button {
                    swap(to: name)
                } label: {
                    if name == performedName {
                        Label(name, systemImage: "checkmark")
                    } else {
                        Text(name)
                    }
                }
            }
        } label: {
            Label("Swap", systemImage: "arrow.triangle.2.circlepath")
                .font(.subheadline)
        }
    }

    private func swap(to name: String) {
        guard name != performedName else { return }
        performedName = name
        // Use the last weight logged for this exercise today; otherwise the plan's weight
        // (only for the planned exercise; an alternative's weight is unknown).
        let last = session.sortedSets.last { $0.exerciseName == name }
        if planned.kind == .weighted {
            weight = last?.weight ?? (name == planned.name ? planned.targetWeight : nil)
        }
    }

    // MARK: Input row

    private var inputRow: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Set \(loggedSets.count + 1)")
                    .font(.subheadline.bold())
                if loggedSets.count >= planned.sets {
                    Text("extra").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if addingExtraSet {
                    Button("Cancel") { addingExtraSet = false }
                        .buttonStyle(.borderless)
                        .font(.subheadline)
                }
            }

            HStack {
                if isTimed {
                    NumberStepper(label: "Seconds", value: $seconds.asDouble, step: 5)
                } else {
                    if planned.kind == .weighted {
                        NumberStepper(label: "Weight (lb)", value: $weight, step: 5, allowsDecimals: true)
                    }
                    NumberStepper(label: "Reps", value: $reps.asDouble, step: 1)
                }
            }

            Text(isTimed ? "How much was left in the tank? Tap to log." : "Reps left in the tank? Tap to log.")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 8) {
                ForEach(0...4, id: \.self) { value in
                    Button {
                        logSet(repsInReserve: value)
                    } label: {
                        Text(SetLog.repsInReserveLabel(value))
                            .font(.headline)
                            .frame(maxWidth: .infinity, minHeight: 36)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityLabel("Log set with \(SetLog.repsInReserveLabel(value)) reps left")
                }
            }
            .disabled(!canLog)
        }
        .padding(.vertical, 6)
        .sensoryFeedback(.success, trigger: loggedCount)
    }

    private func logSet(repsInReserve: Int) {
        let set = SetLog(
            exerciseName: performedName,
            setNumber: loggedSets.count + 1,
            weight: planned.kind == .weighted ? weight : nil,
            reps: isTimed ? nil : reps,
            seconds: isTimed ? seconds : nil,
            repsInReserve: repsInReserve,
            swappedFrom: isSwapped ? planned.name : nil
        )
        context.insert(set)
        set.session = session
        addingExtraSet = false
        loggedCount += 1
    }
}

/// A completed set, e.g. "Set 2   135 lb × 8   2 left ✓".
struct LoggedSetRow: View {
    let number: Int
    let set: SetLog

    var body: some View {
        HStack {
            Text("Set \(number)")
                .foregroundStyle(.secondary)
                .frame(width: 52, alignment: .leading)
            Text(set.summary)
                .monospacedDigit()
            Spacer()
            if let rir = set.repsInReserveText {
                Text(rir)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
        }
        .contentShape(Rectangle())
    }
}
