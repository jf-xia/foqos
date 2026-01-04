---
agent: 'agent'
description: 'Create an iOS module map (UI/state/data/side-effects) and output docs/study/03-module-map.md with boundaries and learning order.'
---

# iOS Module Map (UI / State / Data / Side-effects)

## Goal

Create `docs/study/03-module-map.md` explaining how the codebase is partitioned and how data/side-effects flow.

## Inputs to inspect

- Folder structure under the main app target
- Search for common patterns:
  - SwiftUI entry (`@main`, `Scene`, root views)
  - State (`Observable`, `@State`, `@StateObject`, `@Environment`, reducers/stores)
  - Persistence (SwiftData/CoreData/SQLite/files)
  - Networking (URLSession, clients)
  - Side-effects (notifications, background tasks, NFC, widgets, app intents, StoreKit)

## Output (write a file)

Create **exactly one** file:
- `docs/study/03-module-map.md`

Must include:

1) **Module list** (not necessarily SwiftPM modules; logical modules are ok)
- Responsibility
- Key files
- Inputs/outputs

2) **Data flow**
- What is the canonical source of truth?
- How state reaches UI

3) **Side-effect boundaries**
- Where OS integrations happen
- How permissions/entitlements constrain behavior

4) **Learning order**
- A recommended reading sequence of modules

5) **Confirmed vs Unconfirmed + How to confirm**
