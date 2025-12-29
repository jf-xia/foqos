---
agent: 'agent'
description: 'Audit iOS app dependencies (SPM/CocoaPods/Carthage/manual) and produce docs/study/02-dependencies.md with purpose and risk notes.'
---

# iOS Dependency Audit

## Goal

Create `docs/study/02-dependencies.md` listing:
- Dependency manager(s)
- Third-party libraries and their purpose
- Apple frameworks used heavily
- Upgrade and risk notes

## Inputs to inspect

- SPM: `Package.resolved`, `Package.swift` (if present)
- CocoaPods: `Podfile`, `Podfile.lock`
- Carthage: `Cartfile`, `Cartfile.resolved`
- Xcode project references

## Output (write a file)

Create **exactly one** file:
- `docs/study/02-dependencies.md`

Include:

1) **Dependency manager detection (Confirmed)**

2) **Third-party dependencies**
- Name
- Where declared
- Where used (example import or folder)
- Why it exists (what capability it provides)
- Risk notes (abandonware, permissions, security)

3) **Apple framework hotspots**
- List major Apple frameworks and where they appear

4) **Open questions**
- Anything missing goes to `docs/study/99-open-questions.md`
