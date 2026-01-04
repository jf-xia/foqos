---
agent: 'agent'
description: 'From an existing iOS feature/module, derive an implementation guide to build a similar capability in another app. Writes into docs/study/06-clone-guides/.'
---

# iOS Similar Feature Implementation Guide

## Goal

Turn understanding into reusable ability: derive an implementation guide for a similar feature.

## Input

- Feature/module to clone (e.g. Widget timeline, App Intents action, FamilyControls policy, NFC flow)
- Constraints (minimum iOS version, SwiftUI vs UIKit, persistence choice)

## Output

Create:
- `docs/study/06-clone-guides/{feature-slug}.md`

Guide sections:

1) **What you’re building**
- User story + non-goals

2) **Pre-requisites**
- Capabilities/entitlements
- `Info.plist` privacy keys
- Dependencies (third-party, if any)

3) **Architecture sketch**
- State ownership
- Data model
- Side-effect boundary

4) **Step-by-step implementation**
- Minimal happy path first
- Then edge cases

5) **Testing strategy**
- What to unit test vs integration vs UI

6) **Common pitfalls**
- Concurrency, background limits, extension constraints

Rules:
- If you reference behavior, anchor it to the source repo evidence; otherwise mark Unconfirmed.
