#!/usr/bin/env bash
#
# Validates a release tag against the application version in pubspec.yaml.
#
# Usage:
#   scripts/verify_release_tag.sh [tag]
#
# Environment:
#   GITHUB_REF_NAME   Used when no tag argument is supplied.
#
# The tag must start with "v". The compared version is the tag without that
# prefix and pubspec.yaml's version without the +build suffix, so a prerelease
# such as v1.4.2-beta.1 matches 1.4.2-beta.1+18.
#
# Both the Pages and Release workflows call this script so a tag cannot deploy
# or publish one artifact while being rejected by the other workflow.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tag="${1:-${GITHUB_REF_NAME:-}}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -n "$tag" ]] || fail "A tag is required (pass an argument or set GITHUB_REF_NAME)"
[[ "$tag" == v* ]] || fail "Tag must start with 'v': $tag"

declared_version="$(awk '
  /^version:[[:space:]]*/ {
    sub(/^version:[[:space:]]*/, "")
    gsub(/"/, "")
    print
    exit
  }
' "$REPO_ROOT/pubspec.yaml")"

[[ -n "$declared_version" ]] ||
  fail "Could not read the application version from pubspec.yaml"

declared_version="${declared_version%%+*}"
declared_version="$(printf '%s' "$declared_version" | tr -d '[:space:]')"
tag_version="$(printf '%s' "${tag#v}" | tr -d '[:space:]')"

[[ -n "$declared_version" ]] ||
  fail "pubspec.yaml declares an empty version in $REPO_ROOT/pubspec.yaml"

if [[ "$tag_version" != "$declared_version" ]]; then
  fail "Tag $tag does not match pubspec.yaml version $declared_version"
fi

echo "OK: tag $tag matches pubspec.yaml version $declared_version"
