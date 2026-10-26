#!/usr/bin/env bash
# Usage: find-plan.sh [branch]
# Finds the plan for a branch in <repo root>/docs/plan/ and prints its path
# relative to the repo root. Defaults to the current branch.
#
# Lookup:
#   1. A plan whose frontmatter has `branch: <branch>`
#   2. Otherwise a file named after the branch's last segment
#      (feat/login-ui -> login-ui.md)
#
# Exit codes:
#   0  found: prints one path
#   1  not found: prints nothing
#   2  ambiguous: prints every candidate, one per line
#   3  not in a git repository, or no branch (detached HEAD)
set -uo pipefail

root="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "Not in a git repository." >&2
  exit 3
}
branch="${1:-$(git branch --show-current 2>/dev/null)}"
if [ -z "$branch" ]; then
  echo "No branch name (detached HEAD?)." >&2
  exit 3
fi

plan_dir="$root/docs/plan"
[ -d "$plan_dir" ] || exit 1

print_results() {
  local count="$#"
  [ "$count" -eq 0 ] && return 1
  for f in "$@"; do
    echo "${f#"$root"/}"
  done
  [ "$count" -eq 1 ] && exit 0
  exit 2
}

# 1. Frontmatter match: `branch: <branch>` between the opening and closing ---.
matches=()
while IFS= read -r -d '' file; do
  if awk -v want="$branch" '
    { sub(/\r$/, "") }
    NR == 1 { if ($0 != "---") exit; in_fm = 1; next }
    in_fm && $0 == "---" { exit }
    in_fm && /^branch:/ {
      value = $0
      sub(/^branch:[ \t]*/, "", value)
      sub(/[ \t]+(#.*)?$/, "", value)
      gsub(/^["\047]|["\047]$/, "", value)
      if (value == want) { found = 1; exit }
    }
    END { exit !found }
  ' "$file"; then
    matches+=("$file")
  fi
done < <(find "$plan_dir" -type f -name '*.md' -print0 | sort -z)

if [ "${#matches[@]}" -gt 0 ]; then
  print_results "${matches[@]}"
fi

# 2. File name match on the branch's last segment.
slug="${branch##*/}"
matches=()
while IFS= read -r -d '' file; do
  matches+=("$file")
done < <(find "$plan_dir" -type f -name "$slug.md" ! -name 'epic.md' -print0 | sort -z)

if [ "${#matches[@]}" -gt 0 ]; then
  print_results "${matches[@]}"
fi

exit 1
