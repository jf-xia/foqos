---
agent: 'agent'
description: 'Generate a feature learning card for an iOS app module/feature and save it under docs/study/04-feature-cards/ (entry points, data flow, key APIs, pitfalls, tests, how to reproduce).'
---

# iOS Feature Slice Learning Card

## Goal

For a chosen feature/module, create one card file under `docs/study/04-feature-cards/`.

## Input

- Feature name and the primary user journey it supports
- The files/folders that implement it (search to locate)

## Output (write a file)

Create:
- `docs/study/04-feature-cards/{feature-slug}.md`

Card sections (in order):

1) **Feature summary** (1–3 sentences)
2) **Entry points**
- UI entry (views/screens)
- Non-UI entry (App Intent, background task, widget refresh, notification)
3) **Data flow**
- State owners
- Persistence
- Network calls (if any)
4) **Key Apple frameworks/APIs**
- What’s used and why
5) **Edge cases & pitfalls**
- Permissions, background limits, concurrency, error handling
6) **How to validate**
- Manual steps
- Suggested tests (unit/integration/UI)
7) **What to learn next**
- Links to other cards / modules

Rules:
- If a section cannot be verified from code, mark it Unconfirmed and add “How to confirm”.
