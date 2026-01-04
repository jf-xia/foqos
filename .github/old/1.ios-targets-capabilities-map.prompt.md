---
agent: 'agent'
description: 'Map iOS targets/schemes/products and capabilities/entitlements; produce docs/study/01-targets-and-capabilities.md with confirmed vs unconfirmed items.'
---

# iOS Targets & Capabilities Map

## Goal

Create `docs/study/01-targets-and-capabilities.md` that answers:
- What targets exist (App + extensions + tests)?
- What does each target ship (product type)?
- What capabilities/entitlements does each target require?

## Inputs to inspect

- `*.xcodeproj/project.pbxproj` (required)
- Any `*.entitlements`
- Any `Info.plist`
- Any `*.xcconfig`

## Output (write a file)

Create **exactly one** file:
- `docs/study/01-targets-and-capabilities.md`

Include these sections:

1) **Targets table**
- Target name
- Product type (app, app extension, widget, intents, unit tests, UI tests…)
- Bundle id (if discoverable)

2) **Capabilities / Entitlements by target**
- App Groups
- Background Modes
- Push Notifications
- NFC
- Family Controls / Device Activity / Managed Settings
- Keychain sharing / iCloud / etc.

3) **Privacy strings checklist**
- For each sensitive capability, list the expected `Info.plist` keys to verify.

4) **Shared data boundaries**
- Where targets are expected to share data (App Group container, shared defaults suite)

5) **Confirmed vs Unconfirmed**
- Any item not proven by files must be in Unconfirmed with “How to confirm”.
