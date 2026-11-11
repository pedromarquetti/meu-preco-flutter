#!/usr/bin/env bash
#
# Verifies a Flutter Web bundle before it is published or uploaded.
#
# Usage:
#   scripts/verify_web_bundle.sh [bundle-dir] [expected-base-href]
#
# Environment overrides:
#   BUNDLE_DIR   Bundle directory (default: build/web)
#   BASE_HREF    Expected <base href> value
#
# Exits non-zero when a required entrypoint is missing, the base href is wrong,
# a source map is present, or a credential-like value is found. Matching values
# are never printed, only the affected file names.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE="${1:-${BUNDLE_DIR:-$REPO_ROOT/build/web}}"
EXPECTED_BASE_HREF="${2:-${BASE_HREF:-}}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -d "$BUNDLE" ]] || fail "Web bundle directory not found: $BUNDLE"

for required in index.html flutter_bootstrap.js main.dart.js; do
  [[ -s "$BUNDLE/$required" ]] \
    || fail "Required Web entrypoint is missing or empty: ${required}"
done

if [[ -n "$EXPECTED_BASE_HREF" ]]; then
  if ! grep -Fq "<base href=\"$EXPECTED_BASE_HREF\"" "$BUNDLE/index.html"; then
    fail "index.html does not declare the expected base href: $EXPECTED_BASE_HREF"
  fi
fi

# Public Pages must not expose source maps. They can be uploaded separately as
# private diagnostics when needed.
map_file="$(find "$BUNDLE" -type f -name '*.map' -print -quit)"
if [[ -n "$map_file" ]]; then
  fail "Source map found in public bundle: ${map_file#"$BUNDLE"/}"
fi

# Reject common credential formats without ever echoing the matched value.
credential_patterns=(
  "private key|-----BEGIN [A-Z ]*PRIVATE KEY-----"
  "GitHub token|gh[pousr]_[A-Za-z0-9]{20,}"
  "GitHub fine-grained token|github_pat_[A-Za-z0-9_]{20,}"
  "AWS access key|(AKIA|ASIA)[0-9A-Z]{16}"
  "Google API key|AIza[0-9A-Za-z_-]{35}"
  "Slack token|xox[baprs]-[A-Za-z0-9-]{10,}"
  "Stripe live key|(sk|rk)_live_[0-9A-Za-z]{16,}"
  "JSON Web Token|eyJ[A-Za-z0-9_-]{10,}\\.[A-Za-z0-9_-]{10,}\\.[A-Za-z0-9_-]{10,}"
)

for entry in "${credential_patterns[@]}"; do
  label="${entry%%|*}"
  pattern="${entry#*|}"
  matches="$(grep -R -I -l -E -e "$pattern" "$BUNDLE" || true)"
  if [[ -n "$matches" ]]; then
    echo "FAIL: Credential-like value found in public bundle ($label):" >&2
    while IFS= read -r file; do
      [[ -n "$file" ]] && echo "  ${file#"$BUNDLE"/}" >&2
    done <<< "$matches"
    exit 1
  fi
done

echo "OK: Web bundle verified at $BUNDLE"
