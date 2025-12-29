# Foqos/Components/BlockedProfileCards/StrategyInfoView.swift

## Context
- Inspected: `Foqos/Components/BlockedProfileCards/StrategyInfoView.swift`
- Primary role: Displays the selected blocking strategy’s icon and name.

## Confirmed

### Purpose
- Converts a `strategyId` into a user-visible icon/name via `StrategyManager.getStrategyFromId`.

### Key types/functions
- `struct StrategyInfoView: View`
  - Environment: `@EnvironmentObject var themeManager: ThemeManager`
  - Input: `strategyId: String?`
  - Derived:
    - `blockingStrategyName`: “None” if nil, else `StrategyManager.getStrategyFromId(...).name`
    - `blockingStrategyIcon`: questionmark icon if nil, else `.iconType`
    - `blockingStrategyColor`: gray if nil, else `.color` (computed but not used in the current body)
  - UI:
    - Uses `Image(systemName: blockingStrategyIcon)` but styles it using `themeManager.themeColor`.

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`
- Collaborators referenced:
  - `ThemeManager`
  - `StrategyManager.getStrategyFromId(id:)`
  - Strategy model surfaces: `.name`, `.iconType`, `.color`

### Side-effects
- None.

### Invariants
- Uses `themeManager.themeColor` for icon + background styling regardless of the strategy’s own color.

### Suggested comments/docstrings (suggestions only)
- Either use or remove `blockingStrategyColor` (currently unused).
- Document what `strategyId == nil` means in the product (unset profile? deleted strategy?).

## Unconfirmed
- Whether strategy-specific colors are intentionally ignored here.

## How to confirm
- Check other UI components that display strategies and compare their color behavior.

## Key takeaways
- Strategy display is centrally mapped via `StrategyManager.getStrategyFromId`.
