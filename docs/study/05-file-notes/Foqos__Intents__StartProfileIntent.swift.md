# Foqos/Intents/StartProfileIntent.swift

## Context
- Inspected: `Foqos/Intents/StartProfileIntent.swift`
- Primary role: AppIntent to start a profile session from Shortcuts/Siri.

## Confirmed

### Purpose
- Provides a “Start Foqos Profile” intent that takes a `Profile` parameter and triggers a background start via `StrategyManager`.

### Key types/functions
- `struct StartProfileIntent: AppIntent`
  - Dependency: `@Dependency(key: "ModelContainer") var modelContainer: ModelContainer`
  - `@MainActor var modelContext` uses `modelContainer.mainContext`
  - Parameter: `@Parameter(title: "Profile") var profile: BlockedProfileEntity`
  - `static var title = "Start Foqos Profile"`
  - `@MainActor func perform()`:
    - `StrategyManager.shared.startSessionFromBackground(profile.id, context: modelContext)`
    - returns `.result()`

### Dependencies (imports + collaborators)
- Imports: `AppIntents`, `SwiftData`
- Collaborators referenced:
  - `BlockedProfileEntity` (intent parameter)
  - `StrategyManager.shared` (starts session)
  - SwiftData `ModelContainer`/`ModelContext`

### Side-effects
- Indirectly starts a session (implementation in `StrategyManager.startSessionFromBackground`).
- Reads/writes SwiftData via `modelContext` depending on `StrategyManager` implementation.

### Invariants
- Runs on `@MainActor`; assumes `StrategyManager` call is safe on main actor and/or quickly returns.

### Suggested comments/docstrings (suggestions only)
- Document expected behavior when the selected profile can’t be found or authorization is missing (FamilyControls/DeviceActivity permissions).
- Clarify whether this is intended to be callable when the app is not foregrounded.

## Unconfirmed
- What `startSessionFromBackground` does (e.g., scheduling DeviceActivity monitors, updating snapshots, Live Activity start).

## How to confirm
- Inspect `Foqos/Utils/StrategyManager.swift` (or similarly named file) for `startSessionFromBackground` implementation.
- Search for `startSessionFromBackground(` across the repo.

## Key takeaways
- Intent is thin: it delegates almost all logic to `StrategyManager` using the app’s SwiftData context.
