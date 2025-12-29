# Foqos/Components/BlockedProfileCards/BlockedProfileCard.swift

## Context
- Inspected: `Foqos/Components/BlockedProfileCards/BlockedProfileCard.swift`
- Primary role: UI card summarizing a profile and exposing start/stop/edit/stats/break actions.

## Confirmed

### Purpose
- Renders a “profile card” with:
  - Profile name
  - Feature indicators (live activity, reminders, breaks, strict)
  - Strategy + schedule summary
  - Counts for selected activities, domains, and total sessions
  - Primary CTA area to start/stop and optionally trigger a break
  - Overflow menu for edit/stats and start/stop

### Key types/functions
- `struct BlockedProfileCard: View`
  - Inputs:
    - `profile: BlockedProfiles`
    - State-like flags passed in: `isActive`, `isBreakAvailable`, `isBreakActive`, `elapsedTime`
    - Callbacks: `onStartTapped`, `onStopTapped`, `onEditTapped`, `onStatsTapped` (default empty), `onBreakTapped`
  - Uses `CardBackground(isActive:customColor:)` via a computed `cardBackground` property.
  - Layout:
    - Header: profile name + `ProfileIndicators` + menu.
    - Middle: `StrategyInfoView(strategyId:)` + divider + `ProfileScheduleRow(profile:isActive:)`, then `ProfileStatsRow(...)`.
    - Footer: `ProfileTimerButton(...)`.
  - Menu actions trigger `UIImpactFeedbackGenerator(style: .light).impactOccurred()` before delegating.

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`, `FamilyControls`
- Collaborators referenced:
  - `BlockedProfiles`
  - Views/components: `CardBackground`, `ProfileIndicators`, `StrategyInfoView`, `ProfileScheduleRow`, `ProfileStatsRow`, `ProfileTimerButton`
  - `ThemeManager` via `@EnvironmentObject`

### Side-effects
- Haptic feedback via `UIImpactFeedbackGenerator` in menu actions.

### Invariants
- UI is purely driven by passed-in `isActive`/break flags; it does not compute active status itself.

### Suggested comments/docstrings (suggestions only)
- Document expected semantics of `elapsedTime` (e.g., seconds since session start) and how it should behave when nil.
- Document what “Stats for Nerds” should open (call site responsibility).

## Unconfirmed
- The visual design rules of `CardBackground` (active styling, color usage).

## How to confirm
- Inspect `CardBackground` implementation and its callers.

## Key takeaways
- This component is a presentational wrapper: it renders data and emits callbacks; business logic lives elsewhere.
