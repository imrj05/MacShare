#!/usr/bin/env bash
#
# Creates and pushes the tag v<MARKETING_VERSION> when the app version changes.
#
# A tag pushed with the default GITHUB_TOKEN does not start other workflows, so
# the caller must invoke the release pipeline directly after this script runs;
# this script only produces the tag.
#
# Env:
#   GITHUB_EVENT_NAME  'workflow_dispatch' bypasses the version-change check
#   GITHUB_OUTPUT      when set (Actions), receives tag= and skipped=
#   PBXPROJ            path to the project file (default below)
#
set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PBXPROJ="${PBXPROJ:-MacShare.xcodeproj/project.pbxproj}"
EVENT="${GITHUB_EVENT_NAME:-push}"

VERSION="$("${SCRIPT_DIR}/read-version.sh" "$PBXPROJ")"
TAG="v${VERSION}"

echo "Project version: ${VERSION} -> tag ${TAG}"

emit() {
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    echo "$1" >> "$GITHUB_OUTPUT"
  fi
}

skip() {
  echo "$1"
  emit "tag=${TAG}"
  emit "skipped=true"
  exit 0
}

if git rev-parse -q --verify "refs/tags/${TAG}" >/dev/null 2>&1 \
  || git ls-remote --exit-code --tags origin "refs/tags/${TAG}" >/dev/null 2>&1; then
  skip "Tag ${TAG} already exists - nothing to do."
fi

if [ "${EVENT}" = "workflow_dispatch" ]; then
  echo "Manual run: skipping the version-change check."
else
  PREV_FILE="$(mktemp)"
  trap 'rm -f "$PREV_FILE"' EXIT
  PREV_VERSION=""
  if git show "HEAD^:${PBXPROJ}" > "$PREV_FILE" 2>/dev/null; then
    PREV_VERSION="$("${SCRIPT_DIR}/read-version.sh" "$PREV_FILE" 2>/dev/null || true)"
  fi
  rm -f "$PREV_FILE"
  trap - EXIT
  if [ -n "${PREV_VERSION}" ] && [ "${PREV_VERSION}" = "${VERSION}" ]; then
    skip "MARKETING_VERSION is still ${VERSION} - no change to tag."
  fi
  if [ -z "${PREV_VERSION}" ]; then
    echo "No readable previous version; treating this as a version change."
  else
    echo "Version changed: ${PREV_VERSION} -> ${VERSION}"
  fi
fi

git config user.name "${GIT_AUTHOR_NAME:-github-actions[bot]}"
git config user.email "${GIT_AUTHOR_EMAIL:-41898282+github-actions[bot]@users.noreply.github.com}"
git tag -a "${TAG}" -m "Mac Share ${VERSION}"
git push origin "refs/tags/${TAG}"

echo "Created and pushed ${TAG}"
emit "tag=${TAG}"
emit "skipped=false"
