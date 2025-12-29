# Foqos/Models/BlockedProfiles.swift

## Context
- Inspected: `Foqos/Models/BlockedProfiles.swift`
- Primary role: SwiftData model representing a “blocked profile” configuration.

## Confirmed

### Purpose
- Defines persisted profile configuration (selection, strategy, schedule, options) and provides CRUD helpers (fetch/find/create/update/delete/reorder/clone).
- Maintains a lightweight “snapshot” for cross-process consumption via `SharedData`.

### Key types/functions
- `@Model class BlockedProfiles`
  - Stored properties (selected highlights):
    - Identity & ordering: `id: UUID` (`@Attribute(.unique)`), `order: Int`
    - Profile config: `name`, `selectedActivity: FamilyActivitySelection`, `blockingStrategyId`, `strategyData`
    - Behavior toggles: `enableLiveActivity`, `enableBreaks`, `enableStrictMode`, `enableAllowMode`, `enableAllowModeDomains`, `enableSafariBlocking`, `disableBackgroundStops`
    - Reminders: `reminderTimeInSeconds`, `customReminderMessage`
    - Physical unblock: `physicalUnblockNFCTagId`, `physicalUnblockQRCodeId`
    - Domains + schedule: `domains: [String]?`, `schedule: BlockedProfileSchedule?`
    - Relationship: `@Relationship var sessions: [BlockedProfileSession]`
  - Computed:
    - `activeScheduleTimerActivity`: delegates to `DeviceActivityCenterUtil.getActiveScheduleTimerActivity(for:)`
    - `scheduleIsOutOfSync`: true when `schedule?.isActive == true` but no active schedule timer activity found
- Query helpers:
  - `fetchProfiles(in:)` (sorted by `order` then `createdAt`)
  - `findProfile(byID:in:)`
  - `fetchMostRecentlyUpdatedProfile(in:)`
- Mutations:
  - `updateProfile(_:in:...)` updates fields, sets `updatedAt = Date()`, updates snapshot, then `try context.save()`
  - `createProfile(in:...)` computes next order, creates model, updates snapshot, inserts, saves
  - `cloneProfile(_:in:newName:)` clones most fields, assigns `order = getNextOrder`, inserts, saves
  - `deleteProfile(_:in:)` ends active sessions, deletes sessions, deletes snapshot, removes schedule timer activities, then `context.delete(profile)` (note: does not save)
  - `reorderProfiles(_:in:)` sets `order` sequentially, saves
- Snapshot utilities:
  - `getSnapshot(for:)` builds `SharedData.ProfileSnapshot`
  - `updateSnapshot(for:)` + `deleteSnapshot(for:)`
- Misc:
  - `getProfileDeepLink(_:)` returns `https://foqos.app/profile/{uuid}`
  - Domain helpers: `addDomain(to:context:domain:)`, `removeDomain(from:context:domain:)`

### Dependencies (imports + collaborators)
- Imports: `DeviceActivity`, `FamilyControls`, `ManagedSettings`, `SwiftData`, `Foundation`
- Collaborators referenced:
  - `DeviceActivityCenterUtil` (schedule activity lookup/removal)
  - `SharedData` (snapshot persistence)
  - `NFCBlockingStrategy.id` (default strategy id)
  - `BlockedProfileSchedule` (type used for `schedule`)

### Side-effects
- Persists SwiftData changes via `ModelContext.save()` in `updateProfile`, `createProfile`, `reorderProfiles`, `cloneProfile`.
- Writes/clears snapshot via `SharedData.setSnapshot(...)` / `SharedData.removeSnapshot(...)`.
- On deletion: calls `DeviceActivityCenterUtil.removeScheduleTimerActivities(for:)` and ends any active sessions by calling `session.endSession()`.

### Invariants
- `id` must remain unique.
- `selectedActivity` is always present (non-optional), even if empty.
- `scheduleIsOutOfSync` assumes “active schedule implies active timer activity”; if false, profile is considered out-of-sync.
- `order` represents display/order; `getNextOrder` assumes highest `order` + 1 is safe.

### Suggested comments/docstrings (suggestions only)
- On `deleteProfile`: clarify why it intentionally defers `context.save()` and what caller lifecycle expects.
- On `scheduleIsOutOfSync`: document intended remediation path (who/what re-syncs schedule timer activities).
- On snapshot methods: document storage medium and audience (extensions/widgets) and when snapshots are expected to be updated.

## Unconfirmed
- Whether `SharedData` uses an App Group `UserDefaults` suite vs standard `UserDefaults`.
- What `BlockedProfileSchedule` contains and how schedules are applied to `DeviceActivityCenter`.

## How to confirm
- Inspect `Foqos/Models/Shared.swift` for `SharedData` storage implementation.
- Search for `struct BlockedProfileSchedule` / `class BlockedProfileSchedule` definition.
- Inspect `Foqos/Utils/DeviceActivityCenterUtil.swift` (or similarly named file) for schedule activity behavior.

## Key takeaways
- `BlockedProfiles` is the persisted “source of truth” for a profile plus convenience CRUD.
- Snapshots are written on create/update so other targets (extensions) can read without SwiftData access.
- Deletion is multi-step (end sessions → delete sessions → remove schedule timers → delete profile) and does not save automatically.
