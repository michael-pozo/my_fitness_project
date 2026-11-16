import SwiftUI

/// The app's main screen: one tab for each area in the PRD.
/// Each tab is a placeholder until its milestone is built.
struct ContentView: View {
    var body: some View {
        TabView {
            PlaceholderScreen(
                title: "Workouts",
                systemImage: "dumbbell",
                message: "Your routine and today's workout will appear here."
            )
            .tabItem { Label("Workouts", systemImage: "dumbbell") }

            PlaceholderScreen(
                title: "Coach",
                systemImage: "bubble.left.and.bubble.right",
                message: "Chat with Claude to create your routine."
            )
            .tabItem { Label("Coach", systemImage: "bubble.left.and.bubble.right") }

            PlaceholderScreen(
                title: "Progress",
                systemImage: "chart.line.uptrend.xyaxis",
                message: "Your strength over time will appear here."
            )
            .tabItem { Label("Progress", systemImage: "chart.line.uptrend.xyaxis") }

            PlaceholderScreen(
                title: "Settings",
                systemImage: "gearshape",
                message: "Your API key will be entered here."
            )
            .tabItem { Label("Settings", systemImage: "gearshape") }
        }
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
}
