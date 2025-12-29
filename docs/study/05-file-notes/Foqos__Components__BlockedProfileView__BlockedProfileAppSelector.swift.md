# Foqos/Components/BlockedProfileView/BlockedProfileAppSelector.swift

## Context
- Inspected: `Foqos/Components/BlockedProfileView/BlockedProfileAppSelector.swift`
- Primary role: Form row that launches the FamilyActivity app picker and summarizes current selection.

## Confirmed

### Purpose
- Displays a button (“Select Apps to Restrict/Allow”) and a short summary:
  - Disabled message when editing is locked
  - “No apps selected” when count is zero
  - Count text + optional warning for allow mode category expansion

### Key types/functions
- `struct BlockedProfileAppSelector: View`
  - Environment: `@EnvironmentObject var themeManager: ThemeManager`
  - Inputs:
    - `selection: FamilyActivitySelection` (passed by value)
    - `buttonAction: () -> Void`
    - `allowMode: Bool`, `disabled: Bool`, `disabledText: String?`
  - Derived via `FamilyActivityUtil`:
    - `countSelectedActivities(selection, allowMode:)`
    - `getCountDisplayText(selection, allowMode:)`
    - `shouldShowAllowModeWarning(selection, allowMode:)`
  - Shows a warning string when `shouldShowWarning` is true: “Allow mode: Categories expand to individual apps (50 limit applies)”

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`, `FamilyControls`
- Collaborators referenced:
  - `ThemeManager` for theme color
  - `FamilyActivityUtil` utilities

### Side-effects
- None directly; triggers `buttonAction`.

### Invariants
- Selection summary assumes `FamilyActivityUtil` counts are consistent with picker semantics.
- Disabled state controls both button disabling and whether `disabledText` displays.

### Suggested comments/docstrings (suggestions only)
- Document what “50 limit applies” refers to (OS limitation for expanded app list) and where it’s enforced.
- Consider removing unused `title` property (currently computed but never used).

## Unconfirmed
- Whether allow-mode category expansion is enforced client-side or by OS.

## How to confirm
- Inspect `FamilyActivityUtil.shouldShowAllowModeWarning` and related selection building logic.

## Key takeaways
- This component delegates selection logic and warning rules to `FamilyActivityUtil`.
