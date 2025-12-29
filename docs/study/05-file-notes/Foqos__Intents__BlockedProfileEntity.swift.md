# Foqos/Intents/BlockedProfileEntity.swift

## Context
- Inspected: `Foqos/Intents/BlockedProfileEntity.swift`
- Primary role: AppIntents entity wrapper around `BlockedProfiles` for intent parameters and suggestions.

## Confirmed

### Purpose
- Exposes `BlockedProfiles` as an `AppEntity` so App Shortcuts / Siri / automations can select a profile.
- Provides an `EntityQuery` to resolve identifiers and suggest available profiles.

### Key types/functions
- `struct BlockedProfileEntity: AppEntity, Identifiable`
  - Wraps: `let profile: BlockedProfiles`
  - `id: UUID` and `name: String` derived from wrapped model
  - `typeDisplayRepresentation` fixed to “Profile”
  - `defaultQuery = BlockedProfilesQuery()`
  - `displayRepresentation` uses profile name as title
- `struct BlockedProfilesQuery: EntityQuery`
  - Dependency: `@Dependency(key: "ModelContainer") var modelContainer: ModelContainer`
  - `@MainActor var modelContext` returns `modelContainer.mainContext`
  - `entities(for:)` fetches `BlockedProfiles` matching ids and maps to entities
  - `suggestedEntities()` fetches all profiles sorted by name and maps to entities
  - `defaultResult()` returns first suggested entity

### Dependencies (imports + collaborators)
- Imports: `AppIntents`, `SwiftData`
- Collaborators referenced:
  - SwiftData `ModelContainer` and `ModelContext`
  - `BlockedProfiles` SwiftData model

### Side-effects
- Reads from SwiftData (`modelContext.fetch(...)`).

### Invariants
- Query functions are `@MainActor`, so they assume fetching on the main context is safe/required.

### Suggested comments/docstrings (suggestions only)
- Document how the `ModelContainer` dependency key is registered (where it’s provided for AppIntents).
- Consider clarifying why `mainContext` is used (vs a background context) for intents.

## Unconfirmed
- Which target registers the `ModelContainer` dependency for AppIntents and what store configuration it uses.

## How to confirm
- Search for `DependencyKey` or `AppDependencyManager` / `AppIntents` setup providing `ModelContainer` with key `"ModelContainer"`.
- Inspect `foqosApp.swift` for container initialization.

## Key takeaways
- This file is the bridge between SwiftData profiles and AppIntents parameter resolution/suggestions.
