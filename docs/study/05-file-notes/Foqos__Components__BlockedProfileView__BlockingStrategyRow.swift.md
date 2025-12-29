# Foqos/Components/BlockedProfileView/BlockingStrategyRow.swift

## Context
- Inspected: `Foqos/Components/BlockedProfileView/BlockingStrategyRow.swift`
- Primary role: A single selectable row representing one blocking strategy.

## Confirmed

### Purpose
- Displays strategy icon/name/description and a selection indicator.

### Key types/functions
- `struct StrategyRow: View`
  - Environment: `@EnvironmentObject var themeManager: ThemeManager`
  - Inputs: `strategy: BlockingStrategy`, `isSelected: Bool`, `onTap: () -> Void`
  - UI:
    - Left icon: `strategy.iconType`
    - Text: `strategy.name` and `strategy.description` (lineLimit 3)
    - Right indicator: checkmark circle when selected else empty circle, tinted with theme color when selected
  - Uses `.buttonStyle(PlainButtonStyle())` to keep row-like appearance.

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`
- Collaborators referenced:
  - `ThemeManager`
  - `BlockingStrategy` fields: `iconType`, `name`, `description`

### Side-effects
- None directly; calls `onTap`.

### Invariants
- Assumes `strategy.iconType` is a valid SF Symbols name.

### Suggested comments/docstrings (suggestions only)
- Document whether strategy descriptions should be localized.

## Unconfirmed
- Whether `BlockingStrategy` supports localization for `name`/`description`.

## How to confirm
- Inspect `BlockingStrategy` implementations and how they build strings.

## Key takeaways
- Single-row strategy renderer; selection highlighting uses theme color.
