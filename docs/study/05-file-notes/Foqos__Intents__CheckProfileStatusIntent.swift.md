# Foqos/Intents/CheckProfileStatusIntent.swift

## Context
- Inspected: `Foqos/Intents/CheckProfileStatusIntent.swift`
- Primary role: AppIntent returning whether a *specific* profile is currently active.

## Confirmed

### Purpose
- Returns a boolean indicating whether the currently active session (if any) belongs to the specified profile.

### Key types/functions
- `struct CheckProfileStatusIntent: AppIntent`
  - Dependency: `@Dependency(key: "ModelContainer") var modelContainer: ModelContainer`
  - `@MainActor var modelContext` uses `modelContainer.mainContext`
  - Parameter: `@Parameter(title: "Profile") var profile: BlockedProfileEntity`
  - Metadata:
    - `title = "Foqos Profile Status"`
    - `description` describes returning boolean active/inactive
  - `perform()`:
    - Calls `StrategyManager.shared.loadActiveSession(context: modelContext)`
    - Computes `isActive = strategyManager.activeSession?.blockedProfile.id == profile.id`
    - Returns boolean and a dialog message

### Dependencies (imports + collaborators)
- Imports: `AppIntents`, `SwiftData`
- Collaborators referenced:
  - `BlockedProfileEntity`
  - `StrategyManager.shared` (`loadActiveSession`, `activeSession`)

### Side-effects
- Indirect side-effects via `StrategyManager.loadActiveSession(...)`.

### Invariants
- Runs on `@MainActor`.
- If `activeSession` is `nil`, `isActive` evaluates to `false`.

### Suggested comments/docstrings (suggestions only)
- Document whether this should treat “scheduled but not yet started” as inactive.
- Document whether `activeSession?.blockedProfile` is always present when `activeSession` exists.

## Unconfirmed
- Whether `activeSession` is derived from SwiftData, shared snapshots, or both.

## How to confirm
- Inspect `StrategyManager.activeSession` and `loadActiveSession(context:)` implementation.

## Key takeaways
- Intent compares the active session’s profile id against the selected entity id.
