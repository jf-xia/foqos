# Foqos/Components/BlockedProfileCards/BlockedProfileCarousel.swift

## Context
- Inspected: `Foqos/Components/BlockedProfileCards/BlockedProfileCarousel.swift`
- Primary role: Horizontal swipe carousel of `BlockedProfileCard` with a header and page indicators.

## Confirmed

### Purpose
- Displays multiple profiles as swipeable cards.
- Locks the carousel interaction when a session is active (`isBlocking == true`).
- Shows a header via `SectionTitle` with:
  - “Active Profile” + “Emergency” action when blocking
  - “Profile” + “Manage” action when not blocking

### Key types/functions
- `struct BlockedProfileCarousel: View`
  - Inputs:
    - `profiles: [BlockedProfiles]`
    - State flags: `isBlocking`, `isBreakAvailable`, `isBreakActive`
    - Active/session context: `activeSessionProfileId`, `elapsedTime`, `startingProfileId`
    - Callbacks: start/stop/edit/stats/break per-profile + `onManageTapped` + `onEmergencyTapped`
  - State:
    - `currentIndex`, `dragOffset`, `animatingOffset` (declared but not used), gesture thresholds.
  - `initialSetup()` sets `currentIndex` priority:
    1) `activeSessionProfileId`
    2) `startingProfileId`
    3) default 0
  - Gesture:
    - Drag only allowed when `!isBlocking`.
    - Uses `dragThreshold` to decide page changes.
  - `calculateOffset(...)` computes HStack offset to center the active card.
  - Responds to changes: `onAppear` and `.onChange` for `activeSessionProfileId`, `profiles`, `startingProfileId`.

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`, `FamilyControls`
- Collaborators referenced:
  - `BlockedProfileCard`
  - `SectionTitle` (header component)
  - `BlockedProfiles`

### Side-effects
- None directly; emits callbacks.

### Invariants
- When `isBlocking == true`, user cannot swipe and page indicators are hidden.
- `currentIndex` is clamped by checks in gesture end handler.

### Suggested comments/docstrings (suggestions only)
- Remove or document `animatingOffset` if it’s intentionally unused.
- Document what “Emergency” should do and why it only appears during blocking.

## Unconfirmed
- Whether `elapsedTime` is profile-specific or global session elapsed time (passed to all cards).

## How to confirm
- Inspect the parent view that instantiates `BlockedProfileCarousel` and how it computes `elapsedTime`.

## Key takeaways
- Carousel is UI-stateful but business-logic-free; it gates interaction when blocking.
