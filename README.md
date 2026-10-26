# claude-dev-workflow

A Claude Code plugin for the full loop of a change: **plan → write → review → commit**.

| Skill | What it does |
|---|---|
| `plan-epic` | Breaks an epic, PRD or TDD into tickets, each with a branch name and a stub plan in `docs/plan/<epic>/`. |
| `plan-changes` | Plans one ticket for the current branch, has a critic check it for gaps and breaking changes, and saves it to `docs/plan/`. |
| `writing-clean-javascript` | Opinionated JS/TS conventions (Node, React, Express, tests), plus lint and test-config helpers. The project's own config always wins. |
| `review-changes` | Reviews changes on three separate axes (correctness, standards, plan conformance) with parallel reviewers. |
| `commit-changes` | Splits work into atomic Conventional Commits and adds the ticket reference from the branch name. |

The skills work alone, and they also work together: `plan-epic` creates stubs that `plan-changes` expands, and `review-changes` checks the code against those plans and the clean-code rules.

## Install

```
/plugin marketplace add eldrego/claude-dev-workflow
/plugin install dev-workflow@dev-workflow
```

Update later with `/plugin marketplace update dev-workflow`.

## Notes

- Plans are written to `docs/plan/`. Add it to your global gitignore if you don't want plans committed.
- `commit-changes` reads ticket keys such as `SB-142` or `#123` from the branch name. To limit matches to your Jira keys, run `git config --global commit-changes.ticketKeys "ABC,XYZ"`.
- The scripts need `bash` and `git`. The lint helper uses Biome and/or ESLint if your project has them.

## License

MIT
