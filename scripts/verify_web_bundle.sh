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
# Exits non-zero when a required entrypoint is missing, the base href or public
# shell policy is wrong, a source map is present, or a credential-like value is
# found. Matching values are never printed, only the affected file names.

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

grep -Fq '<meta name="viewport" content="width=device-width, initial-scale=1" />' \
  "$BUNDLE/index.html" \
  || fail "index.html is missing the required viewport metadata"

grep -Fq 'http-equiv="Content-Security-Policy"' "$BUNDLE/index.html" \
  || fail "index.html is missing the Content-Security-Policy meta tag"
grep -Fq "default-src 'self'" "$BUNDLE/index.html" \
  || fail "Content-Security-Policy must default to same-origin resources"
grep -Fq "script-src 'self' 'wasm-unsafe-eval' https://cdn.jsdelivr.net" \
  "$BUNDLE/index.html" \
  || fail "Content-Security-Policy must allow the bootstrap and reviewed camera helper"
grep -Fq "style-src 'self' 'unsafe-inline'" "$BUNDLE/index.html" \
  || fail "Content-Security-Policy must allow Flutter's inline styles"
grep -Fq "connect-src 'self' https:" "$BUNDLE/index.html" \
  || fail "Content-Security-Policy must allow configured HTTPS API origins"
grep -Fq "object-src 'none'" "$BUNDLE/index.html" \
  || fail "Content-Security-Policy must disable plug-in content"
grep -Fq "base-uri 'self'" "$BUNDLE/index.html" \
  || fail "Content-Security-Policy must restrict the base element"

if grep -Fq "'unsafe-eval'" "$BUNDLE/index.html"; then
  fail "Production Content-Security-Policy must not allow eval"
fi
if grep -Eq "script-src[^;]*'unsafe-inline'" "$BUNDLE/index.html"; then
  fail "Production Content-Security-Policy must not allow inline scripts"
fi

if grep -Eiq '<script[^>]+\b(src|href)=[^>]*https?://' "$BUNDLE/index.html"; then
  fail "index.html contains a third-party script reference"
fi

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
  'private key|-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'GitHub token|gh[pousr]_[A-Za-z0-9]{20,}'
  'GitHub fine-grained token|github_pat_[A-Za-z0-9_]{20,}'
  'AWS access key|(AKIA|ASIA)[0-9A-Z]{16}'
  'Google API key|AIza[0-9A-Za-z_-]{35}'
  'Slack token|xox[baprs]-[A-Za-z0-9-]{10,}'
  'Stripe live key|(sk|rk)_live_[0-9A-Za-z]{16,}'
  'JSON Web Token|eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
  'Password assignment|password[[:space:]]*[:=][[:space:]]*[A-Za-z0-9_./+=-]{8,}'
  'Refresh token assignment|refresh[_-]?token[[:space:]]*[:=][[:space:]]*[A-Za-z0-9_./+=-]{16,}'
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
