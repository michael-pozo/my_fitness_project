import SwiftUI

@main
struct FitnessCoachApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // Saves routines and workout logs on the phone.
        .modelContainer(for: [Routine.self, Session.self])
    }
}
