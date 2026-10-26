# Plan formats

Shared by `plan-epic` and `plan-changes`. The plan files are the only link
between sessions, so follow these formats exactly.

## Contents

1. Conventions
2. Epic: `epic.md`
3. Ticket stub
4. Full plan
5. Type-specific sections
6. Plan review notes

---

## 1. Conventions

- **Location:** `docs/plan/` at the repo root. It is globally git-ignored:
  plans are never committed.
- **Layout:**
  ```
  docs/plan/
  ├── <epic-slug>/
  │   ├── epic.md
  │   └── <branch-slug>.md        one per ticket
  └── <branch-slug>.md            standalone plans (no epic)
  ```
- **Branch names:** `<type>/<slug>`. Types: `feat`, `fix`, `refactor`, `docs`,
  `chore`. Slugs are lowercase words joined by hyphens (`feat/login-ui`).
- **File names:** the branch's slug (`feat/login-ui` → `login-ui.md`).
- **Lookup key:** the `branch:` field in the frontmatter. Use
  `scripts/find-plan.sh <branch>` to find a plan; never guess.
- **Work types:** `feature`, `enhancement`, `bugfix`, `refactor`. Branch type
  for each: `feature`/`enhancement` → `feat/`, `bugfix` → `fix/`,
  `refactor` → `refactor/`.
- **Statuses:** `stub` (created by an epic) → `approved` (after plan review)
  → `done` (after the user confirms the work is complete).
- **Tickets:** optional metadata only. Leave `ticket:` empty if there is none.
- **Sources:** `@` paths the user gave are only visible in that session.
  Always record source paths in the plan so later sessions can re-read them.
  Summarize what matters; link to the full documents rather than copying them.
- **Numbering:** requirements are `R1, R2, …`; tasks are `T1, T2, …`. Reviews
  refer to these numbers.

## 2. Epic: `epic.md`

```markdown
---
title: <Epic title>
type: epic
slug: <epic-slug>
status: approved
created: <YYYY-MM-DD>
---

# <Epic title>

## Summary
<What is being built and why, in 2–4 sentences.>

## Sources
- PRD: <path or URL>
- TDD: <path or URL>
- Designs: <path(s)>
- Other: <path(s)>

## Goals
- <goal>

## Non-goals
- <explicitly out of scope>

## Key requirements
- R1 <requirement> (<source ref, e.g. PRD §3>)

## Decisions
- <decision> — <reason>

## Affected areas
- <app / remote / library / contract> — <how it is affected>

## Risks
- <risk> — <mitigation>

## Tickets
| # | Title | Type | Branch | Depends on | Status |
|---|---|---|---|---|---|
| 1 | <title> | feature | feat/<slug> | — | stub |
| 2 | <title> | feature | feat/<slug> | 1 | stub |

## Open questions
- <question>

## Plan review notes
<See section 6.>
```

## 3. Ticket stub

Created by `plan-epic`, one per row in the epic's ticket table, in the epic
folder.

```markdown
---
title: <Ticket title>
type: <feature | enhancement | bugfix | refactor>
branch: <type>/<slug>
epic: <epic-slug>
ticket:
status: stub
---

# <Ticket title>

## Goal
<One or two sentences.>

## Scope
- In: <what this ticket covers>
- Not in: <what belongs to other tickets — name them>

## Depends on
- <ticket # and title, or "none">

## Sources
- <only the parts relevant to this ticket, e.g. PRD §3 "Login", designs/auth/login.png>

## Acceptance criteria
- <high-level, checkable>
```

## 4. Full plan

Written by `plan-changes`: either a stub expanded in place (same file, same
frontmatter, `status: approved`) or a new standalone plan.

```markdown
---
title: <Title>
type: <feature | enhancement | bugfix | refactor>
branch: <type>/<slug>
epic: <epic-slug, or empty for standalone>
ticket: <optional>
status: approved
created: <YYYY-MM-DD>
---

# <Title>

## Goal
<What this change achieves, in 1–3 sentences.>

## Context
- Sources: <paths>
- Relevant code: <files, functions, patterns found during research, with paths>

<Type-specific sections — see section 5.>

## Tasks
- [ ] T1 <task> (covers R1)
- [ ] T2 <task>

## Files likely to change
- <path> — <why>

## Testing
- <what to test and how; which test types>

## Acceptance criteria
- <checkable outcome>

## Out of scope
- <what this plan deliberately does not do>

## Open questions
- <question, or "None">

## Plan review notes
<See section 6.>
```

## 5. Type-specific sections

Insert these after `## Context`.

**feature**
```markdown
## Requirements
- R1 <requirement> (<source ref>)
```

**enhancement**
```markdown
## Current behavior
## Desired behavior
## Requirements
- R1 <requirement>
```

**bugfix**
```markdown
## Reproduction
<Steps, expected vs actual.>
## Root cause
<What causes it, with evidence: file:line, logs, or reasoning from the code.
If unconfirmed, say so.>
## Fix
<The approach and why it addresses the root cause.>
## Regression test
<The test that fails before the fix and passes after.>
```

**refactor**
```markdown
## Behavior to preserve
- <observable behavior that must not change>
## Safety-net tests
<Existing tests that protect it, or tests to add first.>
## Migration steps
<Ordered steps, each leaving the code working.>
```

## 6. Plan review notes

While planning (shown to the user in plan review):

```markdown
## Plan review notes
Critic: <ran (model) | skipped — <reason>>

Fixed automatically
- <what the critic found and how the plan now handles it>

Needs your decision
- ❓ <question only the user can answer>
- 🟡 <concern the plan doesn't resolve, with options>
```

When saving the approved plan, trim it to:

```markdown
## Plan review notes
Critic: <ran (model) | skipped — <reason>>
- <decisions the user made during review, and any items still open>
```

Drop "Fixed automatically" on save: those fixes are now part of the plan.
