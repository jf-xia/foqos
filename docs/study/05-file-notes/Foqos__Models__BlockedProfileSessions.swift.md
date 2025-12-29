# Foqos/Models/BlockedProfileSessions.swift

## Context
- Inspected: `Foqos/Models/BlockedProfileSessions.swift`
- Primary role: SwiftData model for a single “blocked profile session”, with break support and snapshot syncing.

## Confirmed

### Purpose
- Represents one run/session of a `BlockedProfiles` configuration, including start/end times and optional break window.
- Provides helpers to create/lookup sessions and to “upsert” from a shared snapshot.

### Key types/functions
- `@Model class BlockedProfileSession`
  - Identity: `id: String` (`@Attribute(.unique)`) created from `UUID().uuidString` by default
  - Session fields: `tag`, `startTime`, `endTime`, `forceStarted`
  - Break fields: `breakStartTime`, `breakEndTime`
  - Relationship: `@Relationship var blockedProfile: BlockedProfiles`
  - Computed:
    - `isActive` → `endTime == nil`
    - `isBreakAvailable` → `blockedProfile.enableBreaks == true && breakEndTime == nil`
    - `isBreakActive` → `enableBreaks` + `breakStartTime != nil` + `breakEndTime == nil`
    - `duration` → time interval from `startTime` to `endTime ?? Date()`
  - Init side-effect: appends itself into `blockedProfile.sessions`
- Session lifecycle:
  - `startBreak()` sets `breakStartTime = Date()` and calls `SharedData.setBreakStartTime(date:)`
  - `endBreak()` sets `breakEndTime = Date()` and calls `SharedData.setBreakEndTime(date:)`
  - `endSession()` sets `endTime = Date()`, calls `SharedData.setEndTime(date:)`, then `SharedData.flushActiveSession()`
- Snapshot integration:
  - `toSnapshot()` returns `SharedData.SessionSnapshot`
  - `createSession(in:withTag:withProfile:forceStart:)` creates model, calls `SharedData.createActiveSharedSession(for:)`, inserts into context
  - `upsertSessionFromSnapshot(in:withSnapshot:)`:
    - Finds profile by snapshot profile id (`BlockedProfiles.findProfile`)
    - If session exists, overwrites fields and `try? context.save()`
    - Otherwise creates a new session, overwrites id/timestamps with snapshot, inserts
- Queries:
  - `mostRecentActiveSession(in:)` fetches latest `endTime == nil`
  - `findSession(byID:in:)`
  - `recentInactiveSessions(in:limit:)` fetches sessions with `endTime != nil`, sorted by end time

### Dependencies (imports + collaborators)
- Imports: `SwiftData`, `Foundation`
- Collaborators referenced:
  - `SharedData` (active-session/break tracking)
  - `BlockedProfiles` (relationship, lookups)

### Side-effects
- Writes to shared session storage via `SharedData.*` in break/session functions.
- Persists session updates with `ModelContext.save()` in the “update existing session from snapshot” path.
- Inserts new sessions into `ModelContext`.

### Invariants
- A session is “active” iff `endTime == nil`.
- Break logic assumes “break ends” are represented solely by setting `breakEndTime`.
- `upsertSessionFromSnapshot` assumes a `BlockedProfiles` with id `snapshot.blockedProfileId` exists; otherwise it prints and returns.

### Suggested comments/docstrings (suggestions only)
- On `init`: explain why it mutates `blockedProfile.sessions` directly (vs relying on SwiftData relationship management).
- On `upsertSessionFromSnapshot`: document expected calling context (extension/app) and why one path forces `context.save()`.
- Clarify semantics of `tag` (user-visible label? source of session start?)

## Unconfirmed
- What `SharedData.flushActiveSession()` does (clears app group data? triggers something?).
- Whether session snapshots are used by extensions (Device Monitor / Shield / Widget) or only app.

## How to confirm
- Inspect `Foqos/Models/Shared.swift` for `SharedData` methods used here.
- Search for `createActiveSharedSession` and `flushActiveSession` call sites to see which targets consume them.

## Key takeaways
- `BlockedProfileSession` tracks both session timing and optional breaks.
- Session/break events mirror into `SharedData`, likely for cross-process continuity.
- Snapshot upsert is defensive but relies on profile existence.
