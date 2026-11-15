#!/usr/bin/env bash
#
# Builds a reproducible Flutter Web bundle for GitHub Pages.
#
# Usage:
#   scripts/build_web_pages.sh [options]
#
# Options:
#   --base-href <path>      Override the derived repository base path.
#                           Must start and end with "/".
#   -h, --help              Show this help.
#
# Environment:
#   BASE_HREF               Same as --base-href.
#   GITHUB_REPOSITORY       owner/repository used by Actions to derive the
#                           Pages sub-path.
#
# No API origin is baked into the bundle: every browser asks for a server on
# first launch and reuses the saved origin afterwards.
#
# The repository name is derived from GITHUB_REPOSITORY or the local git
# remote, so forks deploy under their own Pages path without editing the build.
# The pinned Flutter version is taken from pubspec.yaml and verified against the
# installed toolchain; CI installs it with .github/actions/setup-flutter.
#
# The bundle is validated for entrypoints, secrets, and GitHub Pages-style
# routing before this script exits.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BASE_HREF="${BASE_HREF:-}"

usage() {
  sed -n '2,27p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base-href)
      [[ $# -ge 2 ]] || fail "--base-href requires a value"
      BASE_HREF="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "Unknown argument: $1 (use --help)"
      ;;
  esac
done

if [[ -z "$BASE_HREF" ]]; then
  repository_slug="${GITHUB_REPOSITORY:-}"
  if [[ -z "$repository_slug" ]] \
    && git -C "$REPO_ROOT" remote get-url origin >/dev/null 2>&1; then
    remote_url="$(git -C "$REPO_ROOT" remote get-url origin)"
    remote_url="${remote_url%.git}"
    remote_url="${remote_url%/}"
    repository_slug="${remote_url##*[:/]}"
  fi
  [[ -n "$repository_slug" ]] \
    || fail "Could not derive the repository name; set BASE_HREF (for example /my-repo/)"
  BASE_HREF="/${repository_slug##*/}/"
fi

[[ "$BASE_HREF" == /* ]] || fail "BASE_HREF must start with '/'"
[[ "$BASE_HREF" == */ ]] || fail "BASE_HREF must end with '/'"
[[ "$BASE_HREF" != *"//"* ]] || fail "BASE_HREF must not contain '//'"
[[ "$BASE_HREF" != *".."* ]] || fail "BASE_HREF must not contain '..'"
[[ "$BASE_HREF" != *[[:space:]]* ]] \
  || fail "BASE_HREF must not contain whitespace"
[[ "$BASE_HREF" != *'"'* && "$BASE_HREF" != *'<'* && "$BASE_HREF" != *'>'* ]] \
  || fail "BASE_HREF contains characters that are not valid in an HTML attribute"

command -v flutter >/dev/null 2>&1 || fail "flutter is not available on PATH"

declared_flutter="$(awk '
  /^environment:[[:space:]]*$/ { in_environment = 1; next }
  in_environment && /^[^[:space:]]/ { exit }
  in_environment && /^[[:space:]]+flutter:[[:space:]]*/ {
    sub(/^[[:space:]]+flutter:[[:space:]]*/, "")
    gsub(/"/, "")
    print
    exit
  }
' "$REPO_ROOT/pubspec.yaml")"
[[ -n "$declared_flutter" ]] \
  || fail "pubspec.yaml must declare an exact environment.flutter version"

installed_flutter="$(
  flutter --version --machine 2>/dev/null \
    | sed -n 's/.*"frameworkVersion"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
    | head -n 1
)"
[[ -n "$installed_flutter" ]] || fail "Could not determine the installed Flutter version"
[[ "$installed_flutter" == "$declared_flutter" ]] \
  || fail "Installed Flutter $installed_flutter does not match pubspec.yaml ($declared_flutter)"
[[ -s "$REPO_ROOT/pubspec.lock" ]] \
  || fail "pubspec.lock is missing; run flutter pub get --enforce-lockfile"

# A clean output directory prevents stale files (including source maps) from a
# previous local build leaking into the published artifact.
rm -rf "$REPO_ROOT/build/web"

echo "==> Building Flutter Web release bundle"
echo "    Base href:   $BASE_HREF"
echo "    Flutter:     $installed_flutter"

(
  cd "$REPO_ROOT"
  flutter build web \
    --release \
    --no-web-resources-cdn \
    --base-href="$BASE_HREF"
)

# web/index.html ships a development-friendly baseline so `flutter run` and a
# plain local build work. Replace it with the stricter policy for the public
# bundle before anything is uploaded or deployed.
"$REPO_ROOT/scripts/apply_web_csp.sh" "$REPO_ROOT/build/web"

"$REPO_ROOT/scripts/verify_web_bundle.sh" \
  "$REPO_ROOT/build/web" \
  "$BASE_HREF"

"$REPO_ROOT/scripts/verify_web_routing.sh" \
  "$REPO_ROOT/build/web" \
  "$BASE_HREF"

echo "OK: GitHub Pages Web bundle ready at build/web"
