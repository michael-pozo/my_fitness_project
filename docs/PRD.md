# Product Requirements Document: Fitness Coach App (v1)

| | |
|---|---|
| **Status** | Draft v2 (simplified) |
| **Owner** | Mike Pozo |
| **Last updated** | 2026-11-16 |
| **Source** | Design interview, 2026-11-11; scope simplified 2026-11-16 |

## 1. Overview

A personal iPhone app with Claude built in. You tell Claude your fitness goal in an in-app chat, and Claude creates a workout routine that's saved straight into the app. You log your workouts against that routine, and Claude recommends improvements based on what you've actually done.

**v1 in one line:** chat with Claude, get a routine, log workouts, get improvement suggestions.

### What changed from Draft v1
The first draft had the app generate each day's workout itself, following a ski-specific phased program with a season countdown. That's been replaced with a simpler loop: **Claude writes the routine in conversation, and the app tracks it.** Skiing is now just one goal you might bring to the chat. Removed: the phased program, the season date and countdown, the daily "Train now" generator, and the gap-handling rules.

## 2. Problem

Claude can already write a good routine in a chat, but the routine then stays in that chat. There's nowhere to follow it session by session, log what you did, or have Claude look at your real results and adjust. The app closes that loop.

## 3. Target User

- **One user: the owner.** Not distributed and not on the App Store.
- Installed from Xcode with a free Apple account (see §8).

## 4. Goals & Success Criteria

| Goal | Signal |
|---|---|
| Routines move from conversation to tracking with zero copy and paste | A routine created in chat appears in the app, ready to log |
| Logging is fast enough to use in the gym | A set can be logged in one or two taps |
| Recommendations reflect what was actually done | Suggestions cite logged weights, reps and effort |
| The owner keeps using it | Used for a full routine cycle without falling back to notes |

## 5. Scope

### In scope (v1)
- An in-app chat with Claude for describing goals and discussing the routine
- Claude creates a **structured routine** that's saved in the app
- Logging workouts against the routine (sets, reps, weight, effort)
- Claude recommends **weight/rep increases** and **routine changes**, which the user accepts or declines
- Progress view: strength over time for each exercise

### Out of scope (v1)
- The app generating workouts without Claude (no rules engine)
- Phased programs, season dates and countdowns
- Cardio tracking (distance, pace, heart rate)
- Apple Health integration
- Backup, export or iCloud sync
- Pain or injury handling
- Multiple users, accounts or App Store release

## 6. User Stories

1. I open **Chat**, tell Claude my goal (e.g. "get my legs ready for ski season, 3 days a week, full gym"), and answer any follow-up questions.
2. Claude proposes a routine. I can ask for changes in the chat, and when I'm happy, it's **saved as my active routine**.
3. I open today's workout from the routine and see each exercise with its sets, reps and target weight.
4. I log each set in one or two taps and rate how many reps I had left in the tank.
5. If a machine is taken, I swap to an alternative Claude listed for that exercise.
6. After a workout (or whenever I ask), Claude reviews my logs and suggests weight/rep increases or routine changes. **Nothing changes until I approve it.**
7. I can see whether my lifts are going up over time.

## 7. Functional Requirements

### 7.1 Chat with Claude
- **FR-1.** A chat screen where the user converses with Claude about goals, preferences, schedule, equipment and limitations.
- **FR-2.** Claude may ask clarifying questions before proposing a routine.
- **FR-3.** Chat history is saved on the device so later conversations have context.

### 7.2 Routine creation
- **FR-4.** When the user and Claude agree on a routine, Claude returns it as **structured data** (not just text) in a fixed schema (§9), which the app saves.
- **FR-5.** The app shows the proposed routine for confirmation before it becomes the **active routine**.
- **FR-6.** A routine contains workouts (e.g. "Day A – Legs"), each with ordered exercises. Each exercise has sets, a rep target, a starting/target weight (or bodyweight/time), rest time, notes, and **2–3 alternative exercises**.
- **FR-7.** Only one routine is active at a time. Earlier routines are kept for history.

### 7.3 Logging
- **FR-8.** The user picks a workout from the active routine to start a session.
- **FR-9.** Each set is pre-filled with the target. The user confirms it, or edits the actual weight and reps.
- **FR-10.** Each set gets an effort rating as **reps in reserve** (reps left in the tank): `0`, `1`, `2`, `3`, `4+`.
- **FR-11.** The user can swap an exercise to one of its listed alternatives.
- **FR-12.** Logging works **without internet**. Only chat and recommendations need a connection.

### 7.4 Recommendations
- **FR-13.** After a session is finished (and on demand from the chat), the app sends Claude the active routine and recent logs.
- **FR-14.** Claude returns structured recommendations of two kinds:
  - **Progression:** change the weight or reps for a specific exercise, with a short reason that cites the logs.
  - **Routine change:** swap, add or remove an exercise, or change sets, with a reason.
- **FR-15.** Each recommendation is shown with **Accept** / **Decline**. Accepting updates the active routine; declining leaves it unchanged. Nothing is applied automatically.
- **FR-16.** **Safety checks in code** reject recommendations outside sane limits (e.g. a weight jump above a maximum step; limits TBD) before they're shown.

### 7.5 Progress
- **FR-17.** For each exercise, show **estimated max over time** (a one-rep max estimated from logged weight, reps and RIR) and the best set.
- **FR-18.** Show a history list of completed sessions.

### 7.6 Settings
- **FR-19.** A settings screen to paste the **Anthropic API key**, which is saved to the iPhone **Keychain**.

## 8. Non-Functional Requirements

| Area | Requirement |
|---|---|
| **Platform** | Native iPhone app: Swift, SwiftUI, SwiftData |
| **Distribution** | Installed from Xcode with a free Apple account. Re-run from Xcode every 7 days; data is kept. |
| **AI** | Claude API, model `claude-opus-5-5`. Swift has no official Anthropic SDK, so the app calls the Messages API over HTTPS. |
| **Data storage** | On the phone only, with no sync or backup. Deleting the app or losing the phone loses the data (accepted risk). |
| **Security** | The API key is never stored in code or git, because the repo is **public**. It lives in the Keychain only. |
| **Connectivity** | Chat and recommendations need internet. Logging and progress work offline. |
| **Usability** | Logging a set takes one or two taps. |
| **Cost** | API usage is pay-per-use, billed to the owner's Anthropic API account. |

## 9. Architecture (high level)

```
 ┌──────────── Chat ────────────┐
 │ user goal ⇄ Claude (API)     │
 │        │                     │
 │        ▼ structured routine  │
 └────────┼─────────────────────┘
          ▼
   Confirm → Active Routine (SwiftData)
          │
          ▼
   Log session (offline OK): sets, reps, weight, RIR, swaps
          │
          ▼
   Send routine + recent logs → Claude → structured recommendations
          │
          ▼
   Safety checks (code) → Accept / Decline → update routine
          │
          ▼
   Progress (estimated max per exercise, history)
```

**Structured output from Claude:** routines and recommendations are returned through a tool definition with a strict JSON schema, so the app always gets data it can parse and validate, never free text it has to interpret.

**Core data (draft):**
- `Routine` (name, goal, created date, active flag) → `Workout` → `PlannedExercise` (sets, reps, weight, rest, notes, alternatives)
- `Session` (date, workout) → `SetLog` (exercise, weight, reps, RIR, swapped-from)
- `Recommendation` (type, target exercise, proposed change, reason, status: pending/accepted/declined)
- `ChatMessage` (role, content, date)

## 10. Risks

| Risk | Impact | Mitigation / status |
|---|---|---|
| Claude suggests an unsafe jump or exercise | Injury | Safety checks in code (FR-16) plus user approval (FR-15) |
| API key leaks into the public repo | Unauthorized charges | Keychain only; never commit keys |
| No internet in the gym | Can't chat or get recommendations | Logging works offline (FR-12) |
| App deleted or phone lost | History lost | **Accepted** for v1 |
| Claude returns a routine that doesn't match the schema | Import fails | Strict tool schema plus validation; show an error and let the user retry |
| Owner is new to iOS development | Slower build | Claude writes most of the code, in small, testable steps |

## 11. Future Considerations

- Cardio logging and Apple Health import
- Backup / export, or iCloud sync (needs the paid Apple Developer Program)
- Multiple active routines, or scheduling routines on a calendar
- A "this hurts" button that steers Claude away from a movement
- Charts for volume and consistency

## 12. Open Questions

- [ ] **Safety limits:** the maximum weight change per recommendation, and other bounds
- [ ] **When recommendations run:** automatically after every session, or only when asked? (Draft assumes after each session plus on demand.)
- [ ] **Chat context:** how much past chat and log history to send Claude each time (affects cost)

## 13. Milestones

1. Xcode project; "hello world" running on the iPhone
2. Data model plus manual routine entry (lets logging be tested before AI is wired in)
3. Logging screens (sets, RIR, swaps), working offline
4. Settings: API key in the Keychain
5. Chat with Claude, plus structured routine creation and confirmation
6. Recommendations with safety checks and Accept / Decline
7. Progress screens
