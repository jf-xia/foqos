# Foqos/Components/BlockedProfileView/BlockedProfileScheduleSelector.swift

## Context
- Inspected: `Foqos/Components/BlockedProfileView/BlockedProfileScheduleSelector.swift`
- Primary role: Form row that opens schedule picker and summarizes schedule state.

## Confirmed

### Purpose
- Shows a button (“Set schedule”) and a summary:
  - Disabled text if locked
  - “No Schedule Set” if `schedule.days` is empty
  - Otherwise shows `schedule.summaryText`

### Key types/functions
- `struct BlockedProfileScheduleSelector: View`
  - Environment: `@EnvironmentObject var themeManager: ThemeManager`
  - Inputs: `schedule: BlockedProfileSchedule`, `buttonAction`, `disabled`, `disabledText`
  - Uses `schedule.days.count` and `schedule.summaryText`.

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`
- Collaborators referenced:
  - `ThemeManager`
  - `BlockedProfileSchedule` (including `summaryText`)

### Side-effects
- None directly; triggers `buttonAction`.

### Invariants
- Treats “no schedule” as “no days selected”.

### Suggested comments/docstrings (suggestions only)
- Document whether schedule “active/inactive” is derived solely from `days.count` or also from another flag (this view checks only days).

## Unconfirmed
- Exact definition of `BlockedProfileSchedule.summaryText` and whether it includes time range.

## How to confirm
- Inspect `Foqos/Models/Schedule.swift` or wherever `BlockedProfileSchedule` is defined.

## Key takeaways
- Schedule selector is a thin wrapper around `BlockedProfileSchedule` summary formatting.
