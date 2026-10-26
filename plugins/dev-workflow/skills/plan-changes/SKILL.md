---
name: plan-changes
description: Plans a single ticket, story, task, bug fix, refactor, or enhancement for the current git branch, with an automatic plan check for gaps and breaking changes before the user reviews it, then saves the approved plan to docs/plan/. Use when the user asks to plan a ticket, story, task, fix, refactor, or change, says "plan this", wants to expand a ticket stub from an epic, or before implementing a non-trivial change. For breaking a whole epic or PRD into tickets, use plan-epic instead.
allowed-tools: Bash(git status *) Bash(git branch *) Bash(git log *) Bash(git rev-parse *) Bash(${CLAUDE_SKILL_DIR}/scripts/find-plan.sh *)
---

# Plan changes

Produce one implementable plan for one branch, check it, let the user review it,
and save it to `docs/plan/` — where `review-changes` will find it later.

**Key rules (keep these in mind for the whole session):**
- The plan file is saved **only after the user approves the plan**, exactly
  once, from the **final approved text**. Plannotator may trigger plan approval
  more than once; never save an intermediate version.
- The plan you present for approval is the **complete file content**:
  frontmatter plus every section, following `references/plan-formats.md`.
- `docs/plan/` is never committed. Never `git add` plan files.

## Step 1: Branch

Run `git branch --show-current`.

- On `main`, `master`, `develop`, or a release branch: suggest a branch name
  `<type>/<slug>` based on what the user wants to plan, and offer to create it
  (`git switch -c <name>`). Plans are keyed by branch, so don't save a plan
  without one. If the user declines, stop.
- Otherwise, continue with the current branch.

## Step 2: Find the existing plan

Run `${CLAUDE_SKILL_DIR}/scripts/find-plan.sh`.

| Result | What to do |
|---|---|
| Exit 0, `status: stub` | Expand the stub. Read it, the `epic.md` in the same folder, and the sources the stub lists. |
| Exit 0, `status: approved` or `done` | A plan exists. Ask whether to revise it or keep it. |
| Exit 1 (none) | New standalone plan at `docs/plan/<branch-slug>.md`. |
| Exit 2 (several) | List the candidates and ask which one belongs to this branch. |

Inputs for a new plan: the user's prompt and any `@` paths they gave. If the
type of work (`feature`, `enhancement`, `bugfix`, `refactor`) isn't clear, ask.

## Step 3: Research and draft (in plan mode)

Enter plan mode (use the EnterPlanMode tool if you aren't already in it).

1. Research narrowly: the exact files, functions, and tests this change
   touches; existing patterns to follow; consumers of anything shared it
   changes. Read the sources the plan depends on.
2. Draft the full plan following `references/plan-formats.md`: the full-plan
   template plus the sections for its type. Record source paths under
   `## Context`. Number requirements (R1…) and tasks (T1…).

## Step 4: Check the plan (before the user sees it)

**Decide whether the critic runs.** Run it if any of these is true:
- The plan touches shared contracts (e.g. `contracts/`), shared libraries,
  exported APIs, routes, env vars, config, CI, or build.
- It has more than 5 tasks.
- It's a bug fix whose root cause isn't confirmed.

Skip it if the plan has 3 tasks or fewer and stays inside one app without
touching anything shared. The user can override: "quick plan" skips the critic;
"plan with review" forces it. Record the decision in `## Plan review notes`.

**Run the critic.** Start one subagent with the Agent tool
(`subagent_type: "general-purpose"`, `model: "sonnet"`). Prompt:

```
You are the plan critic.

Repo root: <path>
Plan type: <type>   Branch: <branch>
Sources: <paths>
Epic: <path to epic.md, or "none">
Files the author researched: <list>
Claims to verify: <the risky claims — e.g. "contracts/auth.ts is only consumed
by shell", "RemoteLoader is only rendered in app.tsx">

Draft plan:
<the full draft>

As a first step, read
${CLAUDE_SKILL_DIR}/references/plan-critic.md
and follow it exactly. You are read-only.
```

**Revise.**
1. Fix every 🔴 finding, and each 🟡 finding that has a clear fix.
2. If there were 🔴 findings, run the critic **once more** on the revised
   sections only (include its earlier findings in the prompt). Never more than
   two rounds.
3. Write `## Plan review notes` (format in `references/plan-formats.md`
   section 6): what was fixed, and what needs the user's decision.

## Step 5: User review

Exit plan mode with the full plan (ExitPlanMode). If Plannotator is installed,
the plan opens in the browser; otherwise Claude Code shows its own approval
prompt.

- **Feedback:** revise the plan and exit plan mode again. Don't re-run the
  critic unless the user asks or the revision changes a shared contract or the
  breaking-change picture.
- **Approved:** go to step 6.

## Step 6: Save

1. Write the **final approved text** to the plan file:
   - Stub → overwrite the stub file in place.
   - New → `docs/plan/<branch-slug>.md` (create `docs/plan/` if needed).
2. Set `status: approved` and today's `created` date. Trim
   `## Plan review notes` as described in `references/plan-formats.md`
   section 6.
3. If the plan belongs to an epic, update this ticket's `Status` in the epic's
   `## Tickets` table to `approved`.
4. Confirm the path to the user. Then implement only if the user asked for
   implementation, not just a plan.
