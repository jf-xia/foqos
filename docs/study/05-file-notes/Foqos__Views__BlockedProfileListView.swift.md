# Foqos/Views/BlockedProfileListView.swift

## Context
- Inspected: `Foqos/Views/BlockedProfileListView.swift`
- Primary role: SwiftUI list UI for viewing, creating, editing, reordering, exporting, and deleting profiles.

## Confirmed

### Purpose
- Shows either an empty-state prompt or a list of `BlockedProfiles`.
- Supports:
  - Create profile (sheet)
  - Edit profile (tap row → sheet)
  - Export data (sheet)
  - Reorder profiles (Edit/Move)
  - Delete profiles (guarded: cannot delete active profile)

### Key types/functions
- `struct BlockedProfileListView: View`
  - Environment:
    - `@Environment(\.modelContext) var context`
    - `@Environment(\.dismiss) var dismiss`
  - Query:
    - `@Query(sort: [order asc, createdAt desc]) var profiles: [BlockedProfiles]`
  - State:
    - `showingCreateProfile`, `showingDataExport`, `profileToEdit`, `showErrorAlert`, `editMode`
  - UI behaviors:
    - If `profiles.isEmpty`: shows `EmptyView(...)` (custom view in repo)
    - Else: `List` with `ForEach(profiles) { ProfileRow(profile: profile) ... }`
      - Tap row sets `profileToEdit` only when `editMode == .inactive`
      - `.onDelete` / `.onMove` are only enabled when `editMode == .active`
    - Toolbars:
      - Leading close button
      - Trailing: edit confirmation, menu (Edit/Move + Export Data), plus button
    - Sheets:
      - Create: `BlockedProfileView()`
      - Edit: `BlockedProfileView(profile: profile)`
      - Export: `BlockedProfileDataExportView()`
    - Alert: “Cannot Delete Active Profile”
- Deletion guard:
  - `deleteProfiles(at:)` fetches `BlockedProfileSession.mostRecentActiveSession(in: context)`
  - Prevents deletion if any selected profile matches `activeSession?.blockedProfile.id`
  - Otherwise calls `BlockedProfiles.deleteProfile(profile, in: context)` for each, then reorders remaining with `fetchProfiles` + `reorderProfiles`
- Reorder:
  - `moveProfiles(from:to:)` reorders array then calls `BlockedProfiles.reorderProfiles(..., in: context)`

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`, `SwiftData`, `FamilyControls`
- Collaborators referenced:
  - `BlockedProfiles`, `BlockedProfileSession`
  - `BlockedProfileView`, `BlockedProfileDataExportView`
  - `ProfileRow`, `EmptyView` (custom views elsewhere)

### Side-effects
- SwiftData writes via `BlockedProfiles.deleteProfile(...)` and `BlockedProfiles.reorderProfiles(...)`.
- The delete path prints errors but does not show UI error besides “active profile” case.

### Invariants
- Delete is disallowed only when the *most recent* active session’s profile matches; assumes that represents the current active profile.
- UI only allows edit sheet selection when not in edit mode.

### Suggested comments/docstrings (suggestions only)
- Clarify whether “active profile” should be computed via `StrategyManager` instead of “most recent active session”, in case multiple sessions exist.
- Consider documenting error-handling expectations (prints only).

## Unconfirmed
- Whether there can be multiple active sessions (the model allows `endTime == nil` per session, but app logic may prevent multiples).

## How to confirm
- Search for session creation logic (likely in `StrategyManager`) to see if it enforces single-active-session.

## Key takeaways
- List view is the hub for profile management.
- Deletion is guarded by checking the active session and then reordering remaining profiles.
