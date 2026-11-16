import Foundation
import SwiftData

/// One logged workout: when it happened and every set that was done.
/// (The logging screens are built in milestone 3.)
@Model
final class Session {
    var startedAt: Date
    var finishedAt: Date?
    /// Copied from the workout so history still reads correctly if the routine changes or is deleted.
    var workoutName: String
    var routineName: String
    var workout: Workout?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.session)
    var sets: [SetLog] = []

    init(workoutName: String, routineName: String, startedAt: Date = .now) {
        self.startedAt = startedAt
        self.workoutName = workoutName
        self.routineName = routineName
    }

    /// Creates, saves and links a new session for `workout`.
    /// (Relationships are set after inserting, which SwiftData handles most reliably.)
    static func start(_ workout: Workout, in context: ModelContext) -> Session {
        let session = Session(workoutName: workout.name, routineName: workout.routine?.name ?? "")
        context.insert(session)
        session.workout = workout
        return session
    }

    var sortedSets: [SetLog] {
        sets.sorted { $0.completedAt < $1.completedAt }
    }

    /// e.g. "52 min". Nil while the session is still in progress.
    var durationText: String? {
        guard let finishedAt else { return nil }
        let seconds = max(0, finishedAt.timeIntervalSince(startedAt))
        return Duration.seconds(seconds).formatted(.units(allowed: [.hours, .minutes], width: .abbreviated))
    }

    /// Exercise names in the order they were first logged.
    var exerciseNamesInOrder: [String] {
        var seen = Set<String>()
        return sortedSets.map(\.exerciseName).filter { seen.insert($0).inserted }
    }
}

/// One set as actually performed.
@Model
final class SetLog {
    /// Exercise name at the time it was done (the swapped-in exercise, if swapped).
    var exerciseName: String
    /// The planned exercise this set was done for, if it was swapped.
    var swappedFrom: String?
    var setNumber: Int
    /// Pounds. `nil` for bodyweight and timed exercises.
    var weight: Double?
    var reps: Int?
    var seconds: Int?
    /// Reps in reserve: how many more reps were left in the tank. 4 means "4 or more".
    var repsInReserve: Int?
    var completedAt: Date
    var session: Session?

    init(
        exerciseName: String,
        setNumber: Int,
        weight: Double? = nil,
        reps: Int? = nil,
        seconds: Int? = nil,
        repsInReserve: Int? = nil,
        swappedFrom: String? = nil,
        completedAt: Date = .now
    ) {
        self.exerciseName = exerciseName
        self.setNumber = setNumber
        self.weight = weight
        self.reps = reps
        self.seconds = seconds
        self.repsInReserve = repsInReserve
        self.swappedFrom = swappedFrom
        self.completedAt = completedAt
    }

    /// The planned exercise this set counts toward (the original, if swapped).
    var plannedExerciseName: String { swappedFrom ?? exerciseName }

    /// e.g. "135 lb × 8", "12 reps" or "45 s".
    var summary: String {
        if let seconds { return "\(seconds) s" }
        let repsPart = reps.map { "\($0)" } ?? "?"
        if let weight { return "\(PlannedExercise.formatWeight(weight)) lb × \(repsPart)" }
        return "\(repsPart) reps"
    }

    /// e.g. "2 left" or "4+ left".
    var repsInReserveText: String? {
        repsInReserve.map { Self.repsInReserveLabel($0) + " left" }
    }

    static func repsInReserveLabel(_ value: Int) -> String {
        value >= 4 ? "4+" : "\(value)"
    }
}
