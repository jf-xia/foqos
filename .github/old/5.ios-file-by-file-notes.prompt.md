---
agent: 'agent'
description: 'Produce file-by-file study notes for iOS Swift code without mass-editing source: summaries, responsibilities, key symbols, and suggested comments. Writes into docs/study/05-file-notes/.'
---

# iOS File-by-file Notes (No mass code edits)

## Goal

Create study notes for Swift files so you can “replay” understanding later, without polluting source code with excessive comments.

## Inputs

- A folder (or file list) to process
- The main target context (App vs extension)

## Output

For each input Swift file, create one note file:
- `docs/study/05-file-notes/{path-as-slug}.md`

Each note must include:

1) **Purpose**
2) **Key types/functions** (public surfaces and important private ones)
3) **Dependencies** (imports + collaborators)
4) **Side-effects** (permissions, IO, background, system APIs)
5) **Invariants** (what must always be true)
6) **Suggested comments/docstrings** (as suggestions, not direct edits)
7) **Open questions** + How to confirm

Rules:
- Do not edit the Swift file unless explicitly requested.
- Be concise but precise; prefer pointers to specific symbols.
