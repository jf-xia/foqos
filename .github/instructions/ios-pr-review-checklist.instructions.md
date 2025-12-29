---
description: 'PR review checklist for iOS Swift/SwiftUI apps (concurrency, state, privacy/capabilities, extensions, data, testing).'
applyTo: '**/*.swift, **/*.plist, **/*.entitlements, **/*.pbxproj, **/*.xcconfig'
---

# iOS PR Review Checklist

## Correctness

- Entry points updated correctly for the affected target(s)
- No unintended behavior changes across extensions (Widget/Intents/etc.)
- Errors are handled (user-visible messages vs silent failures are intentional)

## SwiftUI & State

- State ownership is clear (single source of truth)
- Avoid heavy side-effects in view bodies; side-effects are scoped (e.g. `task`, actions)
- View updates are deterministic (no accidental infinite updates)

## Concurrency

- UI updates on main actor when required
- No data races in shared state; actor/locking boundaries are explicit
- Background work is cancelable when appropriate

## Privacy, Capabilities, Entitlements

- Capabilities match actual usage
- `Info.plist` privacy strings present for any sensitive API
- Background modes are justified and minimal

## Data & Persistence

- Data model changes have migration/compatibility plan (if applicable)
- App Group / shared container paths are correct (if shared between targets)

## Testing & Observability

- New logic is testable; seams exist (protocols, injected dependencies)
- Logging/metrics are appropriate for debugging (without leaking personal data)
