#!/usr/bin/env bash
#
# Generates a Markdown changelog section for a release, grouped by commit type.
#
# Usage: changelog.sh <rev> [previous-rev]
#   <rev>           tag or commit to document (e.g. v0.1.0)
#   [previous-rev]  previous tag; defaults to the most recent other tag
#
# Env: GITHUB_REPOSITORY=owner/repo adds a "Full Changelog" compare link.
#
set -eo pipefail

REV="${1:?usage: changelog.sh <rev> [previous-rev]}"
PREV="${2:-}"

if [ -z "$PREV" ]; then
  # Nearest tag reachable from REV's parent: correct even when documenting an
  # older release, and empty for the very first release.
  PREV="$(git describe --tags --abbrev=0 "${REV}^" 2>/dev/null || true)"
fi

if [ -n "$PREV" ]; then
  RANGE="${PREV}..${REV}"
else
  RANGE="${REV}"
fi

if ! git rev-parse -q --verify "${REV}^{commit}" >/dev/null; then
  echo "error: '$REV' is not a known revision" >&2
  exit 1
fi

printf '## %s — %s\n\n' "$REV" "$(date -u +%Y-%m-%d)"

git log "$RANGE" --no-merges --pretty=format:'%h%x09%s%x09%an' | awk '
  BEGIN { FS = "\t" }
  function section(subject) {
    if (subject ~ /^feat(\(|:)/)                   return "Features"
    if (subject ~ /^fix(\(|:)/)                    return "Fixes"
    if (subject ~ /^perf(\(|:)/)                   return "Performance"
    if (subject ~ /^refactor(\(|:)/)               return "Refactoring"
    if (subject ~ /^docs(\(|:)/)                   return "Documentation"
    if (subject ~ /^test(\(|:)/)                   return "Tests"
    if (subject ~ /^(build|ci|chore|style)(\(|:)/) return "Maintenance"
    return "Other Changes"
  }
  NF >= 2 {
    count++
    s = section($2)
    lines[s] = lines[s] "- " $2 " (`" $1 "`)"
    if (NF >= 3 && $3 != "") lines[s] = lines[s] " — " $3
    lines[s] = lines[s] "\n"
  }
  END {
    if (count == 0) {
      print "_No changes recorded for this release._"
      exit
    }
    # "|"-separated so the two-word "Other Changes" stays a single label
    # (splitting on " " would yield "Other" and "Changes" and lose the bucket).
    n = split("Features|Fixes|Performance|Refactoring|Documentation|Tests|Maintenance|Other Changes", order, "|")
    for (i = 1; i <= n; i++) {
      s = order[i]
      if (s in lines) printf "### %s\n%s\n", s, lines[s]
    }
  }
'

if [ -n "$PREV" ] && [ -n "${GITHUB_REPOSITORY:-}" ]; then
  printf '**Full Changelog**: https://github.com/%s/compare/%s...%s\n' \
    "$GITHUB_REPOSITORY" "$PREV" "$REV"
fi
