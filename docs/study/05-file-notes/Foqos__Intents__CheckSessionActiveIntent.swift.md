# Foqos/Intents/CheckSessionActiveIntent.swift

## Context
- Inspected: `Foqos/Intents/CheckSessionActiveIntent.swift`
- Primary role: AppIntent returning whether *any* Foqos session is active.

## Confirmed

### Purpose
- Supports automations/Shortcuts by returning a boolean indicating whether a blocking session is currently active.
- Does not open the app when run (`openAppWhenRun = false`).

### Key types/functions
- `struct CheckSessionActiveIntent: AppIntent`
  - Dependency: `@Dependency(key: "ModelContainer") var modelContainer: ModelContainer`
  - `@MainActor var modelContext` uses `modelContainer.mainContext`
  - Metadata:
    - `title = "Check if Foqos Session is Active"`
    - `description` explains it returns true/false for any active session
    - `openAppWhenRun = false`
  - `perform()` returns `IntentResult & ReturnsValue<Bool> & ProvidesDialog`
    - Calls `StrategyManager.shared.loadActiveSession(context: modelContext)` (comment indicates it “syncs scheduled sessions”)
    - Reads `strategyManager.isBlocking`
    - Provides dialog string based on `isBlocking`

### Dependencies (imports + collaborators)
- Imports: `AppIntents`, `SwiftData`
- Collaborators referenced:
  - `StrategyManager.shared` (`loadActiveSession`, `isBlocking`)
  - SwiftData `ModelContainer`/`ModelContext`

### Side-effects
- Indirect side-effects via `StrategyManager.loadActiveSession(...)` (comment suggests schedule sync).

### Invariants
- Runs on `@MainActor`.
- Returns a boolean derived from `StrategyManager.isBlocking`.

### Suggested comments/docstrings (suggestions only)
- Document whether “active” includes scheduled sessions that started while the app was not running, and what “sync scheduled sessions” means.
- Document expected behavior if user has not granted FamilyControls authorization.

## Unconfirmed
- Whether `loadActiveSession` triggers SwiftData writes and/or DeviceActivity rescheduling.

## How to confirm
- Inspect `StrategyManager.loadActiveSession(context:)` and `StrategyManager.isBlocking` implementation.

## Key takeaways
- This intent is a thin wrapper around `StrategyManager` state.
