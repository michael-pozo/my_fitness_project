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

    init(workout: Workout, startedAt: Date = .now) {
        self.startedAt = startedAt
        self.workoutName = workout.name
        self.routineName = workout.routine?.name ?? ""
        self.workout = workout
    }

    var sortedSets: [SetLog] {
        sets.sorted { $0.completedAt < $1.completedAt }
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
}
