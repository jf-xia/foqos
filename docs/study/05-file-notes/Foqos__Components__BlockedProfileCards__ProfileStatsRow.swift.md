# Foqos/Components/BlockedProfileCards/ProfileStatsRow.swift

## Context
- Inspected: `Foqos/Components/BlockedProfileCards/ProfileStatsRow.swift`
- Primary role: Shows counts for selected activities, domains, and total sessions.

## Confirmed

### Purpose
- Summarizes the scope of a profile:
  - Number of selected apps/categories/websites in `FamilyActivitySelection`
  - Number of configured domains
  - Total sessions count

### Key types/functions
- `struct ProfileStatsRow: View`
  - Inputs: `selectedActivity: FamilyActivitySelection`, `sessionCount: Int`, `domainsCount: Int`
  - Uses `FamilyActivityUtil.countSelectedActivities(selectedActivity)` to compute activity count.

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`, `FamilyControls`
- Collaborators referenced:
  - `FamilyActivityUtil.countSelectedActivities(...)`

### Side-effects
- None.

### Invariants
- Assumes `FamilyActivityUtil.countSelectedActivities` returns a value consistent with user expectations (apps+categories+websites grouped).

### Suggested comments/docstrings (suggestions only)
- Consider documenting what is included in “Apps & Categories” count (apps only? categories? web domains?).

## Unconfirmed
- Whether “Apps & Categories” includes web domains; label might not match computation.

## How to confirm
- Inspect `Foqos/Utils/FamilyActivityUtil.swift` and how it counts selections.

## Key takeaways
- Stats row is a presentation component; the counting rule lives in `FamilyActivityUtil`.
