import SwiftUI

/// The app's main screen: one tab for each area in the PRD.
/// Tabs not built yet show a placeholder.
struct ContentView: View {
    enum Tab: Hashable { case workouts, coach, progress, settings }

    @State private var selection: Tab = Self.initialTab

    var body: some View {
        TabView(selection: $selection) {
            WorkoutsView()
                .tabItem { Label("Workouts", systemImage: "dumbbell") }
                .tag(Tab.workouts)

            PlaceholderScreen(
                title: "Coach",
                systemImage: "bubble.left.and.bubble.right",
                message: "Chat with Claude to create your routine."
            )
            .tabItem { Label("Coach", systemImage: "bubble.left.and.bubble.right") }
            .tag(Tab.coach)

            PlaceholderScreen(
                title: "Progress",
                systemImage: "chart.line.uptrend.xyaxis",
                message: "Your strength over time will appear here."
            )
            .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }
            .tag(Tab.progress)

            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape") }
                .tag(Tab.settings)
        }
    }

    /// Debug builds launched with `-openSettings` start on the Settings tab (for simulator checks).
    private static var initialTab: Tab {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-openSettings") { return .settings }
        #endif
        return .workouts
    }
}

/// A simple "coming soon" screen used until each feature is built.
struct PlaceholderScreen: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                title,
                systemImage: systemImage,
                description: Text(message)
            )
            .navigationTitle(title)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Routine.self, Session.self], inMemory: true)
}
