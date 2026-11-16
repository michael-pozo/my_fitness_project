import Foundation
import SwiftData

/// Actions that touch more than one routine.
enum RoutineStore {
    /// Makes `routine` the only active routine.
    static func setActive(_ routine: Routine, in context: ModelContext) {
        let all = (try? context.fetch(FetchDescriptor<Routine>())) ?? []
        for other in all where other.isActive && other !== routine {
            other.isActive = false
        }
        routine.isActive = true
    }

    /// Adds a ready-made ski-legs routine, handy for testing. Becomes active if none is.
    @discardableResult
    static func addSampleRoutine(to context: ModelContext) -> Routine {
        let routine = Routine(name: "Ski Legs (Sample)", goal: "Stronger legs and knees for downhill ski season")
        context.insert(routine)

        let dayA = routine.addWorkout(named: "Day A – Strength")
        dayA.exercises = [
            PlannedExercise(name: "Back Squat", order: 0, sets: 4, repsLow: 6, repsHigh: 8, targetWeight: 135, restSeconds: 150,
                            notes: "Control the descent.", alternatives: ["Goblet Squat", "Leg Press", "Hack Squat"]),
            PlannedExercise(name: "Romanian Deadlift", order: 1, sets: 3, repsLow: 8, repsHigh: 10, targetWeight: 115, restSeconds: 120,
                            alternatives: ["Dumbbell RDL", "Hamstring Curl"]),
            PlannedExercise(name: "Walking Lunge", order: 2, sets: 3, repsLow: 10, targetWeight: 25, restSeconds: 90,
                            notes: "Reps per leg; dumbbells in each hand.", alternatives: ["Reverse Lunge", "Split Squat"]),
            PlannedExercise(name: "Wall Sit", order: 3, kind: .timed, sets: 3, repsLow: nil, targetSeconds: 45, restSeconds: 60,
                            alternatives: ["Spanish Squat Hold"]),
        ]

        let dayB = routine.addWorkout(named: "Day B – Stability & Power")
        dayB.exercises = [
            PlannedExercise(name: "Bulgarian Split Squat", order: 0, sets: 3, repsLow: 8, targetWeight: 30, restSeconds: 90,
                            notes: "Reps per leg.", alternatives: ["Step-Up", "Single-Leg Press"]),
            PlannedExercise(name: "Lateral Box Jump", order: 1, kind: .bodyweight, sets: 3, repsLow: 6, restSeconds: 90,
                            notes: "Land softly, knees over toes.", alternatives: ["Skater Jump", "Lateral Bound"]),
            PlannedExercise(name: "Single-Leg RDL", order: 2, sets: 3, repsLow: 10, targetWeight: 25, restSeconds: 60,
                            alternatives: ["Kettlebell RDL", "Back Extension"]),
            PlannedExercise(name: "Side Plank", order: 3, kind: .timed, sets: 3, repsLow: nil, targetSeconds: 30, restSeconds: 45,
                            notes: "Each side.", alternatives: ["Pallof Press", "Copenhagen Plank"]),
        ]

        let hasActive = ((try? context.fetchCount(FetchDescriptor<Routine>(predicate: #Predicate { $0.isActive }))) ?? 0) > 0
        if !hasActive { routine.isActive = true }
        return routine
    }
}
