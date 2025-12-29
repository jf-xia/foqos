# Foqos/Intents/StopProfileIntent.swift

## Context
- Inspected: `Foqos/Intents/StopProfileIntent.swift`
- Primary role: AppIntent to stop a profile session from Shortcuts/Siri.

## Confirmed

### Purpose
- Provides a “Stop Foqos Profile” intent that takes a `Profile` parameter and triggers a background stop via `StrategyManager`.

### Key types/functions
- `struct StopProfileIntent: AppIntent`
  - Dependency: `@Dependency(key: "ModelContainer") var modelContainer: ModelContainer`
  - `@MainActor var modelContext` uses `modelContainer.mainContext`
  - Parameter: `@Parameter(title: "Profile") var profile: BlockedProfileEntity`
  - `static var title = "Stop Foqos Profile"`
  - `@MainActor func perform()`:
    - `StrategyManager.shared.stopSessionFromBackground(profile.id, context: modelContext)`
    - returns `.result()`

### Dependencies (imports + collaborators)
- Imports: `AppIntents`, `SwiftData`
- Collaborators referenced:
  - `BlockedProfileEntity` (intent parameter)
  - `StrategyManager.shared` (stops session)

### Side-effects
- Indirectly stops a session (implementation in `StrategyManager.stopSessionFromBackground`).

### Invariants
- Runs on `@MainActor`; assumes stop is safe to initiate from main actor.

### Suggested comments/docstrings (suggestions only)
- Document expected behavior if there is no active session for the chosen profile.
- Document whether it also removes schedule timers / unblocks apps (depends on `StrategyManager`).

## Unconfirmed
- Exact stop semantics (e.g., does it end breaks, clear SharedData active session, remove ManagedSettings shields?).

## How to confirm
- Inspect `StrategyManager.stopSessionFromBackground` implementation and related utilities.
- Search for where “stop session” updates `SharedData` or `DeviceActivityCenterUtil`.

## Key takeaways
- Intent is a delegation layer to `StrategyManager`, using the selected profile’s UUID.
