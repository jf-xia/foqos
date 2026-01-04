---
description: 'Evidence-driven instructions for studying and documenting an iOS app codebase (Swift/SwiftUI/Xcode) using Copilot outputs under docs/study/.'
applyTo: '**'
---

# iOS Project Study Instructions (Evidence-driven)

## Goal

Help the user deeply understand an iOS app codebase by producing verifiable documentation artifacts under `docs/study/`.

## Non-negotiables

- **Evidence-driven**: Do not invent details. Every claim must be backed by files in the repo (e.g. `project.pbxproj`, `Info.plist`, `*.entitlements`, `Package.resolved`, `*.swift`, `*.xcconfig`).
- **Confirmed vs Unconfirmed**: For anything not directly supported, mark it as **Unconfirmed** and add a **How to confirm** step.
- **No mass code annotation**: Do not bulk-edit Swift source to add comments unless the user explicitly asks. Prefer writing notes in `docs/study/05-file-notes/`.
- **Respect scope**: The default mode is analysis/documentation only. Make code changes only when requested.

## Output locations

When creating study outputs, use this structure:
- `docs/study/00-project-map.md`
- `docs/study/01-targets-and-capabilities.md`
- `docs/study/02-dependencies.md`
- `docs/study/03-module-map.md`
- `docs/study/04-feature-cards/{feature}.md`
- `docs/study/05-file-notes/{path-as-slug}.md`
- `docs/study/06-clone-guides/{capability-or-feature}.md`
- `docs/study/99-open-questions.md`

## Standard section template

For any analysis document, include these sections in order:

1. **Context**: what you inspected (files, folders)
2. **Confirmed**: facts backed by the repo
3. **Unconfirmed**: plausible but not proven statements
4. **How to confirm**: exact file(s)/search queries to verify
5. **Key takeaways**: what to remember

## iOS-specific checks (always)

- Targets & products: app target, extensions (Widget, Intents/AppIntents, Share, Notification, Shield/DeviceActivity), tests
- Entitlements & capabilities per target: App Groups, Background Modes, NFC, Family Controls, Push, iCloud, Keychain sharing
- Privacy strings in `Info.plist` for any capability used
- Dependency manager: SPM vs CocoaPods vs Carthage vs manual
- Data storage: SwiftData/CoreData/SQLite/files/UserDefaults/Keychain
- Concurrency: main-thread isolation, Task usage, actor boundaries

