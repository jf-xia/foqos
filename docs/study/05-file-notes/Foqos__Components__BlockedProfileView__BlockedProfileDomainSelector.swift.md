# Foqos/Components/BlockedProfileView/BlockedProfileDomainSelector.swift

## Context
- Inspected: `Foqos/Components/BlockedProfileView/BlockedProfileDomainSelector.swift`
- Primary role: Form row that launches a domain picker and summarizes domain selection.

## Confirmed

### Purpose
- Displays a button (“Select Domains to Restrict/Allow”) and a count summary (“No domains selected” or “N domain(s) selected”).
- Can display a red disabled message when editing is locked.

### Key types/functions
- `struct BlockedProfileDomainSelector: View`
  - Environment: `@EnvironmentObject var themeManager: ThemeManager`
  - Inputs: `domains: [String]`, `buttonAction`, `allowMode`, `disabled`, `disabledText`
  - Summary is based on `domains.count`.

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`
- Collaborators referenced:
  - `ThemeManager`

### Side-effects
- None directly; triggers `buttonAction`.

### Invariants
- Assumes `domains` is already normalized (e.g., lowercase/trimmed) by upstream logic.

### Suggested comments/docstrings (suggestions only)
- Consider removing unused `title` property (computed but not used).
- Consider documenting expected domain format (host only vs full URL).

## Unconfirmed
- Whether domain validation/sanitization occurs in `DomainPicker` or elsewhere.

## How to confirm
- Inspect `DomainPicker` and any domain parsing utilities.

## Key takeaways
- Simple selector/summary UI; domain rules live elsewhere.
