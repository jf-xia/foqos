# Foqos/Components/BlockedProfileCards/ProfileIndicators.swift

## Context
- Inspected: `Foqos/Components/BlockedProfileCards/ProfileIndicators.swift`
- Primary role: Compact row of textual indicators (“Breaks”, “Strict”, “Live Activity”, “Reminders”).

## Confirmed

### Purpose
- Shows which key toggles are enabled for a profile.

### Key types/functions
- `struct ProfileIndicators: View`
  - Inputs: `enableLiveActivity`, `hasReminders`, `enableBreaks`, `enableStrictMode`.
  - For each enabled flag, calls `indicatorView(label:)`.
  - `indicatorView(label:)` draws a small dot and caption.

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`

### Side-effects
- None.

### Invariants
- Indicator order is: Breaks → Strict → Live Activity → Reminders.

### Suggested comments/docstrings (suggestions only)
- Consider clarifying in a comment that `hasReminders` is precomputed (e.g., `reminderTimeInSeconds != nil`) so this view stays decoupled from model.

## Unconfirmed
- None.

## How to confirm
- N/A.

## Key takeaways
- Purely presentational; keep business rules outside.
