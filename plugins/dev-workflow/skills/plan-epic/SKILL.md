---
name: plan-epic
description: Breaks an epic or large feature into tickets, each with its own branch name, from PRDs, TDDs, designs, and other reference material (@ paths), codebase research, or a prompt. The breakdown is checked automatically for gaps and breaking changes before the user reviews it, then saved as docs/plan/<epic>/epic.md plus one ticket stub per ticket. Use when the user asks to plan or break down an epic, a feature set, a PRD or TDD, or a large change into tickets or stories. For planning a single ticket or change, use plan-changes instead.
allowed-tools: Bash(git status *) Bash(git branch *) Bash(git log *) Bash(git rev-parse *) Bash(${CLAUDE_SKILL_DIR}/../plan-changes/scripts/find-plan.sh *)
---

# Plan epic

Turn a feature into an epic overview and a set of tickets. Each ticket gets a
stub plan with its future branch name, so that later, on that branch,
`plan-changes` finds the stub and expands it.

Formats: `${CLAUDE_SKILL_DIR}/../plan-changes/references/plan-formats.md`
(sections 2 and 3). Read it before drafting.

**Key rules (keep these in mind for the whole session):**
- Files are saved **only after the user approves the epic**, exactly once, from
  the **final approved text**. Plannotator may trigger plan approval more than
  once; never save an intermediate version.
- The approved text is `epic.md`. The ticket stubs are generated from its
  `## Tickets` table after approval.
- `docs/plan/` is never committed. Don't create branches; each ticket's branch
  is created later, when its work starts.

## Step 1: Gather inputs

- **`@` paths** (files or folders): PRDs, TDDs, designs, other references.
  For a folder you see the file list — read what's relevant; images and PDFs
  are readable.
- **The prompt**: what the user wants.
- **No PRD or TDD?** Before researching, ask the questions a PRD would answer:
  the problem, who it's for, what's in and out of scope, success criteria,
  and constraints. Keep it to what you actually need.

Choose an epic slug (lowercase, hyphens). If `docs/plan/<slug>/` already exists,
ask whether to revise that epic or use a new slug.

## Step 2: Research (in plan mode)

Enter plan mode (use the EnterPlanMode tool if you aren't already in it).

Research broadly but efficiently. Start 2–4 **Explore** subagents in parallel
(`subagent_type: "Explore"`), each with one focused question, for example:
- Which apps, remotes, and libraries does this feature touch, and how are they
  structured?
- What existing patterns (state, routing, API calls, auth, testing) should the
  new work follow?
- Which shared contracts, exported APIs, routes, or config would change, and
  who consumes them?

Use their summaries; don't re-read everything they read.

## Step 3: Draft the epic

Follow the `epic.md` format in plan-formats.md:
- Summarize requirements from the sources (R1…) with source references, and
  record every source path under `## Sources`.
- Record decisions with reasons, affected areas, and risks.
- Break the work into tickets in `## Tickets`:
  - Each ticket can ship and be reviewed on its own; split large ones.
  - Each has a type and a unique branch `<type>/<slug>`. Check each branch with
    `find-plan.sh <branch>`: exit 1 means it's free.
  - Order them so dependencies come first. Put contract or migration changes
    before the work that depends on them.

## Step 4: Check the epic (before the user sees it)

The critic always runs for epics. Start one subagent with the Agent tool
(`subagent_type: "general-purpose"`, no `model`, so it uses the session's
model). Prompt:

```
You are the plan critic, reviewing an epic.

Repo root: <path>
Sources: <paths>
Affected areas found in research: <list>
Claims to verify: <the risky claims — e.g. "only the shell consumes
contracts/auth.ts", "the music remote has no auth dependency">

Draft epic:
<the full draft>

As a first step, read
${CLAUDE_SKILL_DIR}/../plan-changes/references/plan-critic.md
and follow the "Epics" checklist. You are read-only.
```

Then revise:
1. Fix every 🔴 finding, and each 🟡 finding that has a clear fix.
2. If there were 🔴 findings, run the critic **once more** on the revised parts
   only (include its earlier findings). Never more than two rounds.
3. Write `## Plan review notes` (plan-formats.md section 6).

## Step 5: User review

Exit plan mode with the full `epic.md` content (ExitPlanMode). Plannotator
opens it if installed; otherwise Claude Code shows its own approval prompt.

- **Feedback:** revise and exit plan mode again. Re-run the critic only if the
  user asks, or if tickets were added, removed, or reordered.
- **Approved:** go to step 6.

## Step 6: Save

1. Write the **final approved text** to `docs/plan/<slug>/epic.md`, with
   `status: approved` and today's `created` date. Trim `## Plan review notes`
   (plan-formats.md section 6).
2. For each row in `## Tickets`, create `docs/plan/<slug>/<branch-slug>.md`
   using the stub format (plan-formats.md section 3): `status: stub`, its
   branch, `epic: <slug>`, and only the sources, scope, and acceptance criteria
   relevant to that ticket, taken from the approved epic.
3. Tell the user what was created, then how to start a ticket:
   `git switch -c <branch>` and ask to "plan this" (runs `plan-changes`).
