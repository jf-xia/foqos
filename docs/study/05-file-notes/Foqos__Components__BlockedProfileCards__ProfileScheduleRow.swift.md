# Foqos/Components/BlockedProfileCards/ProfileScheduleRow.swift

## Context
- Inspected: `Foqos/Components/BlockedProfileCards/ProfileScheduleRow.swift`
- Primary role: Small schedule/status summary row used inside profile cards.

## Confirmed

### Purpose
- Presents schedule state and warnings:
  - Out-of-sync schedule warning
  - “No Schedule Set” when schedule is inactive/missing
  - “Duration” when active + timer strategy + no schedule
  - Warning for timer strategies combined with schedule (“Unstable Profile with Schedule”)
  - Days + time range when schedule active

### Key types/functions
- `struct ProfileScheduleRow: View`
  - Inputs: `profile: BlockedProfiles`, `isActive: Bool`
  - Derived:
    - `hasSchedule` checks `profile.schedule?.isActive == true`
    - `isTimerStrategy` checks strategy id against `NFCTimerBlockingStrategy.id` or `QRTimerBlockingStrategy.id`
    - `timerDuration` decodes `profile.strategyData` via `StrategyTimerData.toStrategyTimerData(from:)`
    - `daysLine` sorts `schedule.days` by `rawValue` and joins `shortLabel`
    - `timeLine` formats hours/minutes to 12-hour AM/PM string
  - UI shows a red exclamation icon if `profile.scheduleIsOutOfSync` OR `(hasSchedule && isTimerStrategy)`.

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`
- Collaborators referenced:
  - `BlockedProfiles` (uses `schedule`, `scheduleIsOutOfSync`, `blockingStrategyId`, `strategyData`)
  - `NFCTimerBlockingStrategy`, `QRTimerBlockingStrategy`
  - `StrategyTimerData.toStrategyTimerData(from:)`
  - `DateFormatters.formatMinutes(...)`
  - `BlockedProfileSchedule` fields (`days`, `startHour`, etc.) via `profile.schedule`

### Side-effects
- None.

### Invariants
- Assumes `schedule.days` have `rawValue` and `shortLabel`.
- If `strategyData` is missing or unparsable, duration line omits the value.

### Suggested comments/docstrings (suggestions only)
- Document why timer strategies + schedule is labeled “Unstable” and what user should do.
- Document the expected encoding format in `profile.strategyData` consumed by `StrategyTimerData`.

## Unconfirmed
- Whether “unstable” is a product limitation or a known bug.

## How to confirm
- Search for mentions of timer strategy + schedule constraints in strategy code and/or feature docs.

## Key takeaways
- Schedule row is a lightweight policy/status renderer; it relies on `BlockedProfiles` computed `scheduleIsOutOfSync` and strategy ids.
