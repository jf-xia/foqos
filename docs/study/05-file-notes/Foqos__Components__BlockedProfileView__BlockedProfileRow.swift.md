# Foqos/Components/BlockedProfileView/BlockedProfileRow.swift

## Context
- Inspected: `Foqos/Components/BlockedProfileView/BlockedProfileRow.swift`
- Primary role: A list row view for a profile, showing name, relative update time, and selected-items count.

## Confirmed

### Purpose
- Presents a concise summary of a `BlockedProfiles` record for list display.

### Key types/functions
- `struct ProfileRow: View`
  - Input: `profile: BlockedProfiles`
  - Derived:
    - `formattedUpdateTime` uses `RelativeDateTimeFormatter` comparing `profile.updatedAt` to `Date()`
    - `selectedItemsCount` uses `FamilyActivityUtil.countSelectedActivities(profile.selectedActivity)`
  - UI:
    - Left: name + “Updated {relative}”
    - Right: “{count} items”

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`, `FamilyControls`
- Collaborators referenced:
  - `BlockedProfiles`
  - `FamilyActivityUtil.countSelectedActivities(...)`

### Side-effects
- None.

### Invariants
- Relative update time is computed at render time; it will drift as time passes.

### Suggested comments/docstrings (suggestions only)
- Consider renaming file or type for consistency (`ProfileRow` in a file named `BlockedProfileRow.swift`) if a future refactor is planned.
- Document what “items” means (apps only? categories? websites?).

## Unconfirmed
- Whether selected count includes web domains in `FamilyActivitySelection`.

## How to confirm
- Inspect `FamilyActivityUtil.countSelectedActivities`.

## Key takeaways
- Pure display component; it does not handle interactions.
