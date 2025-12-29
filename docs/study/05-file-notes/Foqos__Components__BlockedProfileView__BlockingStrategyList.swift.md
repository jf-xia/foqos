# Foqos/Components/BlockedProfileView/BlockingStrategyList.swift

## Context
- Inspected: `Foqos/Components/BlockedProfileView/BlockingStrategyList.swift`
- Primary role: Form section listing available blocking strategies and allowing selection.

## Confirmed

### Purpose
- Shows a “Blocking Strategy” section with tappable rows.
- When disabled, selection is locked, rows are faded, and an optional disabled message is shown.

### Key types/functions
- `struct BlockingStrategyList: View`
  - Inputs:
    - `strategies: [BlockingStrategy]`
    - `@Binding var selectedStrategy: BlockingStrategy?`
    - `disabled: Bool`, `disabledText: String?`
  - For each strategy:
    - Renders `StrategyRow(strategy:isSelected:onTap:)`
    - If not disabled, tap sets `selectedStrategy = strategy`
    - Applies `.opacity(disabled ? 0.5 : 1)`

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`
- Collaborators referenced:
  - `BlockingStrategy` protocol/type
  - `StrategyRow`

### Side-effects
- Updates bound `selectedStrategy` when enabled.

### Invariants
- Uses `strategy.name` as `ForEach` id; assumes names are unique across strategies.

### Suggested comments/docstrings (suggestions only)
- If strategy names can collide, use a stable id (e.g., `getIdentifier()`) for `ForEach`.

## Unconfirmed
- Whether `BlockingStrategy.name` is guaranteed unique.

## How to confirm
- Inspect `BlockingStrategy` definition and the list `StrategyManager.availableStrategies`.

## Key takeaways
- Strategy selection UI is straightforward; uniqueness assumptions matter for `ForEach` stability.
