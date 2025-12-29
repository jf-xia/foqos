# Foqos/Components/BlockedProfileCards/ProfileTimerButton.swift

## Context
- Inspected: `Foqos/Components/BlockedProfileCards/ProfileTimerButton.swift`
- Primary role: Card footer CTA that shows either “Hold to Start” or a running timer + Stop, plus optional Break CTA.

## Confirmed

### Purpose
- When inactive: shows a full-width long-press “Hold to Start” `GlassButton`.
- When active and `elapsedTime` is present: shows elapsed timer display and a Stop button.
- When breaks are available: shows a long-press Break button with state-dependent label/color.

### Key types/functions
- `struct ProfileTimerButton: View`
  - Environment: `@EnvironmentObject var themeManager: ThemeManager` (used for stroke opacity in timer background)
  - Inputs: `isActive`, `isBreakAvailable`, `isBreakActive`, `elapsedTime`, callbacks for start/stop/break.
  - Derived:
    - `breakMessage` is "Hold to Start Break" or "Hold to Stop Break"
    - `breakColor` is `.orange` when break active
  - Timer UI:
    - `timeString(from:)` formats `TimeInterval` to `HH:MM:SS`.
    - Uses `.contentTransition(.numericText())` and animates on elapsed change.
  - Stop button triggers haptic via `UIImpactFeedbackGenerator(style: .light).impactOccurred()`.

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`
- Collaborators referenced:
  - `GlassButton`
  - `ThemeManager`

### Side-effects
- Haptic feedback when tapping Stop.

### Invariants
- Timer display only appears when `isActive == true` and `elapsedTime != nil`.
- Break button only appears when `isBreakAvailable == true`.

### Suggested comments/docstrings (suggestions only)
- Document the UX contract for long-press start/break (handled by `GlassButton`).
- Clarify whether `elapsedTime` should be nil or 0 when active but timing unknown.

## Unconfirmed
- How `GlassButton.longPressEnabled` is implemented (minimum duration, feedback).

## How to confirm
- Inspect `GlassButton` implementation.

## Key takeaways
- This is a reusable CTA block; parent decides state and provides callbacks.
