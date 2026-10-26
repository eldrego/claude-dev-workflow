---
name: review-changes
description: Reviews code changes on three separate axes — correctness (bugs, edge cases, security), standards (my clean-code rules, code smells, repo conventions), and plan conformance (against the plan in the repo's docs/plan directory) — using parallel reviewers, then reports them side by side with a verdict. Use when the user asks to review their changes, a branch, a PR, or work in progress, or before committing or opening a PR.
allowed-tools: Bash(git status *) Bash(git diff *) Bash(git log *) Bash(git branch *) Bash(git rev-parse *) Bash(git merge-base *) Bash(git ls-files *) Bash(${CLAUDE_SKILL_DIR}/../plan-changes/scripts/find-plan.sh *)
---

# Review changes

Review a set of changes on three **separate** axes, each handled by its own
reviewer subagent running in parallel:

| Axis | Question | Reviewer instructions |
|---|---|---|
| **Correctness** | Does the code work? Bugs, edge cases, security, breaking changes | `references/correctness-reviewer.md` |
| **Standards** | Does it follow my rules, avoid code smells, and match the repo's conventions? | `references/standards-reviewer.md` |
| **Plan** | Does it do what the plan in `docs/plan/` asked — no more, no less? | `references/plan-reviewer.md` |

The axes stay separate on purpose: code can follow every standard and still
build the wrong thing, or match the plan exactly and still be buggy. Merging
them lets one hide the other.

This skill runs in the main conversation and coordinates. It does not review
code itself, and it never changes git state or edits code. The only file edit
it may make is a plan's status, after the user confirms (step 6).

## Step 1: Pin the scope

Use what the user named: a commit, branch, tag, range, or files. Otherwise:

- **Working tree has changes** → review uncommitted work against `HEAD`:
  - Diff: `git diff HEAD` (staged and unstaged together)
  - New files: `git ls-files --others --exclude-standard` (reviewers read
    these in full)
- **Working tree is clean** → review the branch against its base:
  - Base: `git merge-base HEAD main` (or `master` / `develop`)
  - Diff: `git diff <base>...HEAD`
  - Commits: `git log <base>..HEAD --oneline`

Record: repo root (`git rev-parse --show-toplevel`), branch name, the exact
diff command(s), the list of changed and new files, and the commit list if any.

**Fail early:** if a ref doesn't resolve or the diff is empty, tell the user
and stop. Don't start reviewers on nothing.

## Step 2: Find the plan

Plans live in `docs/plan/` at the repo root (git-ignored, never committed) and
are keyed by branch.

1. If the user gave a plan path, use it.
2. Otherwise run
   `${CLAUDE_SKILL_DIR}/../plan-changes/scripts/find-plan.sh`
   (current branch, or pass the branch under review). It matches the plan's
   `branch:` frontmatter field, then falls back to the file name.
   - Exit 0: that's the plan.
   - Exit 1: no plan.
   - Exit 2: several candidates.
3. If the plan's `status` is `stub`, it was never expanded: treat it as the
   plan, but warn "⚠ Plan is still a stub — plan-changes was not run".
4. If the plan has an `epic:` field, also pass the `epic.md` in the same folder
   to the Plan reviewer, so it can tell when an unplanned change belongs to
   another ticket.

No plan, or several candidates: **don't guess and don't stop.** Record a
warning — "⚠ No plan found in docs/plan/ — implementation-only review"
(listing candidates if there were several) — skip the Plan reviewer, and
continue with the other two.

## Step 3: Collect standards sources

List, without reading in depth:

- Repo docs on how to write code: `CODING_STANDARDS.md`, `CONTRIBUTING.md`,
  `docs/*standard*`, `docs/*convention*`, and similar.
- Tooling config: `biome.json(c)`, ESLint config, Prettier config,
  `tsconfig*.json`.
- My personal standards (always included):
  - `${CLAUDE_SKILL_DIR}/../writing-clean-javascript/SKILL.md`
  - `${CLAUDE_SKILL_DIR}/../writing-clean-javascript/references/conventions.md`
  - `${CLAUDE_SKILL_DIR}/../writing-clean-javascript/references/code-smells.md`

## Step 4: Start the reviewers in parallel

Start all reviewers **in a single message** with the Agent tool
(`subagent_type: "general-purpose"`) so they run at the same time. Each
reviewer gets a short prompt that points to its instruction file — don't
paste the instructions in.

| Reviewer | Model | When |
|---|---|---|
| Correctness | session default (omit `model`) | always |
| Standards | `sonnet` | always |
| Plan | `sonnet` | only when a plan was found |

Prompt template (fill in every field):

```
You are the <Correctness | Standards | Plan> reviewer.

Repo root: <path>
Branch: <branch>
Scope: <uncommitted changes vs HEAD | branch vs <base> | as requested>
Diff command(s): <exact commands>
New (untracked) files to read in full: <list or "none">
Changed files: <list>
Commits: <list or "none">

[Standards only] Standards sources: <list from step 3>
[Plan only] Plan: <path to the plan file>
[Plan only] Epic: <path to epic.md, or "none">

As a first step, read
${CLAUDE_SKILL_DIR}/references/<axis>-reviewer.md
and follow it exactly. You are read-only: never edit files or change git state.
```

## Step 5: Report

Present the reviewers' reports under their own headings, verbatim or lightly
cleaned. **Don't merge or re-rank findings across axes.**

```
# Review: <branch> — <scope>, <N> files

⚠ <warnings: no plan found / ambiguous plan candidates>   (omit if none)

## Correctness
<report>

## Standards
<report>

## Plan
<report, or "Skipped — no plan found in docs/plan/.">

## Summary
- Correctness: <counts by severity> — worst: <one line, or "none">
- Standards: <counts by severity> — worst: <one line, or "none">
- Plan: <coverage counts> — worst: <one line, or "skipped">

**Verdict:** ✅ Ready to commit | ❌ Fix blocking items first
```

Verdict rules:
- Only 🔴 **blocking** findings block, and they can come from any axis.
- Warnings never block: no plan found, plan items missing, unplanned changes,
  and code smells (always judgement calls).

## Step 6: Offer next steps

Ask whether the user wants you to fix the blocking or should-fix items. Don't
fix anything until they say so. When everything is resolved, they can commit
with the `commit-changes` skill.

**Plan status.** If the Plan reviewer reports every task and requirement
implemented (no ❌ missing, no ⚠️ wrong) and there are no 🔴 findings, suggest
marking the plan done. Only after the user confirms:
- set `status: done` in the plan's frontmatter, and
- if it belongs to an epic, set this ticket's `Status` to `done` in the
  epic's `## Tickets` table.

These are the only edits this skill ever makes, and only with confirmation.
