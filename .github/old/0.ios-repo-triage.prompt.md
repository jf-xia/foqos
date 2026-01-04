---
agent: 'agent'
description: 'Triage an iOS app repository: identify entry points, main user flows, targets, key frameworks, and produce docs/study/00-project-map.md (evidence-driven).'
---

# iOS Repo Triage (Evidence-driven)

## Goal

Create `docs/study/00-project-map.md` that explains what the app is, how it is structured, and where to start reading.

## Inputs (you must inspect)

- README and any docs
- Xcode project: `*.xcodeproj/project.pbxproj` (or `.xcworkspace` if present)
- Top-level folders and key Swift files (`App` entry, root views)

## Output (write a file)

Create **exactly one** file:
- `docs/study/00-project-map.md`

The file must include:

1) **App purpose & primary user journeys** (Confirmed / Unconfirmed)

2) **Entry points**
- Where app starts (`@main` App, AppDelegate, SceneDelegate)
- Root view/controller

3) **Project shape**
- Targets overview (names only if you can confirm)
- Folder layout summary

4) **Key frameworks**
- SwiftUI/UIKit, persistence, networking, background, widgets, intents, NFC, StoreKit, etc.

5) **Start-here reading path**
- 5–12 files/folders to read in order, with reasons

6) **Open questions**
- Put any uncertainty into `docs/study/99-open-questions.md` (append if exists)

## Rules

- Be explicit about evidence (which files support each claim).
- If you cannot verify, mark as **Unconfirmed** and add “How to confirm”.
