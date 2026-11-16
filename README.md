# My Fitness Project

A personal iPhone app with Claude built in. Tell Claude your fitness goal in the app, get a workout routine, log your workouts against it, and get recommendations based on what you actually lifted.

📄 **Full requirements:** [docs/PRD.md](docs/PRD.md)

## How It Works

1. **Chat:** describe your goal to Claude in the app (e.g. "stronger legs for ski season, 3 days a week, full gym").
2. **Routine:** Claude creates a structured routine, which is saved in the app once you confirm it.
3. **Log:** record each set (weight, reps and how many reps you had left). Works offline.
4. **Improve:** Claude reviews your logs and suggests weight/rep increases or routine changes. You accept or decline each one.
5. **Progress:** see your strength trend for each exercise over time.

## Tech Stack

- **Language:** Swift
- **UI:** SwiftUI
- **Storage:** SwiftData (on the phone only)
- **AI:** Claude API (`claude-opus-5-5`), called directly over HTTPS
- **Target:** iOS 17+

## Getting Started

### Requirements

- macOS with the latest version of [Xcode](https://developer.apple.com/xcode/)
- An iPhone (installed with a free Apple account; re-run from Xcode every 7 days, and your data is kept)
- An [Anthropic API key](https://console.anthropic.com/) for the chat and recommendations

### Setup

```bash
git clone https://github.com/michael-pozo/my_fitness_project.git
cd my_fitness_project
open FitnessCoach.xcodeproj
```

Choose your iPhone (or a simulator) in Xcode and press **Run** (⌘R). In the app, open **Settings** and paste your API key.

**First install on an iPhone:** turn on Developer Mode (Settings → Privacy & Security → Developer Mode), and after installing, trust the developer under Settings → General → VPN & Device Management.

### Project settings

The Xcode project is generated from [`project.yml`](project.yml) by [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`). Change project settings in `project.yml`, then run `xcodegen` to regenerate. Settings changed in Xcode's own settings screens are overwritten the next time the project is regenerated.

> **Never commit your API key.** This repo is public. The app stores the key in the iPhone Keychain, not in code.

## Project Status

🚧 Routines can be entered by hand and workouts logged; connecting Claude is next.

## Roadmap

- [x] Create the Xcode project and run it on the iPhone
- [x] Data model and manual routine entry
- [x] Workout logging (sets, reps in reserve, exercise swaps), offline
- [ ] Settings: API key in the Keychain
- [ ] Chat with Claude and routine creation
- [ ] Recommendations with safety checks and Accept/Decline
- [ ] Progress screens
