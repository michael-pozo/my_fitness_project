import Foundation
import SwiftData

// MARK: - Routine

/// A training plan, e.g. "Ski Legs". Only one routine is active at a time.
@Model
final class Routine {
    var name: String
    /// What the routine is for, in the user's words (e.g. "Stronger legs for ski season").
    var goal: String
    var createdAt: Date
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \Workout.routine)
    var workouts: [Workout] = []

    init(name: String, goal: String = "", isActive: Bool = false, createdAt: Date = .now) {
        self.name = name
        self.goal = goal
        self.isActive = isActive
        self.createdAt = createdAt
    }

    /// SwiftData doesn't keep array order, so workouts are sorted by their `order` field.
    var sortedWorkouts: [Workout] {
        workouts.sorted { $0.order < $1.order }
    }

    @discardableResult
    func addWorkout(named name: String) -> Workout {
        let workout = Workout(name: name, order: (workouts.map(\.order).max() ?? -1) + 1)
        workouts.append(workout)
        return workout
    }
}

// MARK: - Workout

/// One session type within a routine, e.g. "Day A – Legs".
@Model
final class Workout {
    var name: String
    var order: Int
    var routine: Routine?

    @Relationship(deleteRule: .cascade, inverse: \PlannedExercise.workout)
    var exercises: [PlannedExercise] = []

    /// Logged sessions of this workout. They're kept (unlinked) if the workout is deleted.
    @Relationship(deleteRule: .nullify, inverse: \Session.workout)
    var sessions: [Session] = []

    init(name: String, order: Int) {
        self.name = name
        self.order = order
    }

    var sortedExercises: [PlannedExercise] {
        exercises.sorted { $0.order < $1.order }
    }

    @discardableResult
    func addExercise(named name: String) -> PlannedExercise {
        let exercise = PlannedExercise(name: name, order: (exercises.map(\.order).max() ?? -1) + 1)
        exercises.append(exercise)
        return exercise
    }
}

// MARK: - PlannedExercise

/// How an exercise is measured.
enum ExerciseKind: String, CaseIterable, Identifiable {
    case weighted     // sets × reps at a weight
    case bodyweight   // sets × reps, no added weight
    case timed        // sets × seconds (e.g. planks, wall sits)

    var id: String { rawValue }

    var label: String {
        switch self {
        case .weighted: "Weighted"
        case .bodyweight: "Bodyweight"
        case .timed: "Timed"
        }
    }
}

/// An exercise as planned in a workout: what to do, how much, and what to swap to.
@Model
final class PlannedExercise {
    var name: String
    var order: Int
    /// Stored as text because SwiftData handles plain strings more reliably than enums.
    var kindRaw: String
    var sets: Int
    /// Rep target. If `repsHigh` is set and larger, the target is a range (e.g. 8–10).
    var repsLow: Int?
    var repsHigh: Int?
    /// Target duration per set, for timed exercises.
    var targetSeconds: Int?
    /// Target weight in pounds, for weighted exercises.
    var targetWeight: Double?
    var restSeconds: Int?
    var notes: String
    /// Names of exercises that can be swapped in (e.g. when a machine is taken).
    var alternatives: [String]
    var workout: Workout?

    init(
        name: String,
        order: Int,
        kind: ExerciseKind = .weighted,
        sets: Int = 3,
        repsLow: Int? = 10,
        repsHigh: Int? = nil,
        targetSeconds: Int? = nil,
        targetWeight: Double? = nil,
        restSeconds: Int? = 90,
        notes: String = "",
        alternatives: [String] = []
    ) {
        self.name = name
        self.order = order
        self.kindRaw = kind.rawValue
        self.sets = sets
        self.repsLow = repsLow
        self.repsHigh = repsHigh
        self.targetSeconds = targetSeconds
        self.targetWeight = targetWeight
        self.restSeconds = restSeconds
        self.notes = notes
        self.alternatives = alternatives
    }

    var kind: ExerciseKind {
        get { ExerciseKind(rawValue: kindRaw) ?? .weighted }
        set { kindRaw = newValue.rawValue }
    }

    /// A short summary such as "3 × 8–10 @ 135 lb", "3 × 12 · bodyweight" or "3 × 45 s".
    var prescription: String {
        let target: String
        switch kind {
        case .timed:
            target = targetSeconds.map { "\($0) s" } ?? "?"
        case .weighted, .bodyweight:
            target = repsText ?? "?"
        }
        var text = "\(sets) × \(target)"
        switch kind {
        case .weighted:
            if let targetWeight { text += " @ \(Self.formatWeight(targetWeight)) lb" }
        case .bodyweight:
            text += " · bodyweight"
        case .timed:
            break
        }
        return text
    }

    var repsText: String? {
        guard let repsLow else { return nil }
        if let repsHigh, repsHigh > repsLow { return "\(repsLow)–\(repsHigh)" }
        return "\(repsLow)"
    }

    /// Formats 135.0 as "135" and 22.5 as "22.5".
    static func formatWeight(_ weight: Double) -> String {
        weight.formatted(.number.precision(.fractionLength(0...1)))
    }
}
