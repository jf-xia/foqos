# Foqos/Views/BlockedProfileDataExportView.swift

## Context
- Inspected: `Foqos/Views/BlockedProfileDataExportView.swift`
- Primary role: UI to export selected profiles’ sessions to a CSV via iOS file exporter.

## Confirmed

### Purpose
- Lets user:
  - Select one or more profiles
  - Choose session sort order (ascending/descending)
  - Choose timestamp time zone (UTC/local)
  - Export resulting sessions as CSV (`.commaSeparatedText`) via `fileExporter`

### Key types/functions
- `struct BlockedProfileDataExportView: View`
  - Environment:
    - `@EnvironmentObject var themeManager: ThemeManager`
    - `@Environment(\.modelContext) var context`
  - Query:
    - `@Query(sort: [order asc, createdAt desc]) var profiles: [BlockedProfiles]`
  - State:
    - `selectedProfileIDs: Set<UUID>`
    - `sortDirection: DataExportSortDirection`
    - `timeZone: DataExportTimeZone`
    - Export UI state: `isExportPresented`, `exportDocument: CSVDocument`, `isGenerating`, `errorMessage`
  - Computed:
    - `isExportDisabled` (generating or no selection)
    - `defaultFilename` uses epoch seconds: `foqos_sessions_{timestamp}`
  - Export flow:
    - `generateAndExport()`:
      - sets `isGenerating = true`
      - calls `DataExporter.exportSessionsCSV(forProfileIDs:in:sortDirection:timeZone:)`
      - assigns `exportDocument = CSVDocument(text: csv)` and presents exporter
      - captures error message
      - sets `isGenerating = false`
  - Selection helper: `toggleSelection(for:)`

### Dependencies (imports + collaborators)
- Imports: `SwiftUI`, `SwiftData`
- Collaborators referenced:
  - `ThemeManager`
  - `DataExporter.exportSessionsCSV(...)`
  - Types: `CSVDocument`, `DataExportSortDirection`, `DataExportTimeZone`
  - Uses `fileExporter` modifier with `UTType.commaSeparatedText`

### Side-effects
- Reads SwiftData through `DataExporter.exportSessionsCSV(...)` (implementation determines query strategy).
- Triggers iOS document export UI via `fileExporter`.

### Invariants
- Export is disabled when no profiles selected or while generating.
- Timestamp formatting is described as ISO 8601; actual formatting depends on `DataExporter`.

### Suggested comments/docstrings (suggestions only)
- Document CSV schema (columns) near `DataExporter.exportSessionsCSV` call site (or link to where it’s defined).
- Consider documenting performance expectations (large session histories).

## Unconfirmed
- The exact CSV columns and whether it includes breaks, tags, strategy, etc.

## How to confirm
- Inspect `Foqos/Utils/DataExporter.swift` and `CSVDocument` definition.

## Key takeaways
- Export UI is mostly orchestration around `DataExporter` + `fileExporter`.
