#!/usr/bin/env bash
#
# Performs a non-destructive smoke test against the deployed GitHub Pages shell.
#
# Usage:
#   scripts/verify_pages_deployment.sh <deployment-url> [expected-base-href]
#
# The check intentionally validates only public static resources. It never logs
# in, sends credentials, mutates API data, or follows a link to the API.

set -euo pipefail

URL="${1:-}"
EXPECTED_BASE_HREF="${2:-}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -n "$URL" ]] || fail "A deployed Pages URL is required"
[[ "$URL" == https://* ]] || fail "Pages deployment URL must use HTTPS"
[[ "$URL" != *[[:space:]]* ]] || fail "Pages deployment URL must not contain whitespace"
command -v curl >/dev/null 2>&1 || fail "curl is required"

URL="${URL%/}/"
if [[ -z "$EXPECTED_BASE_HREF" ]]; then
  host_and_path="${URL#https://}"
  EXPECTED_BASE_HREF="/${host_and_path#*/}"
  EXPECTED_BASE_HREF="${EXPECTED_BASE_HREF%%\?*}"
  EXPECTED_BASE_HREF="${EXPECTED_BASE_HREF%%#*}"
  [[ "$EXPECTED_BASE_HREF" == */ ]] || EXPECTED_BASE_HREF="${EXPECTED_BASE_HREF}/"
fi

tmp="$(mktemp -d)"
cleanup() { rm -rf "$tmp"; }
trap cleanup EXIT

# GitHub Pages can serve the previous deployment for a short time after a new
# one is published, so retry until the new shell is visible before failing.
attempts="${DEPLOY_ATTEMPTS:-6}"
delay="${DEPLOY_RETRY_DELAY:-10}"
status=""
for ((attempt = 1; attempt <= attempts; attempt++)); do
  status="$(curl -sS --max-time 20 -L -o "$tmp/index.html" -w '%{http_code}' "$URL" || true)"
  if [[ "$status" == 200 ]] \
    && grep -Fq "<base href=\"$EXPECTED_BASE_HREF\"" "$tmp/index.html"; then
    break
  fi
  if (( attempt < attempts )); then
    echo "Waiting for the Pages deployment to propagate ($attempt/$attempts)..." >&2
    sleep "$delay"
  fi
done

[[ "$status" == 200 ]] || fail "Pages shell returned HTTP $status"
grep -Fq "<base href=\"$EXPECTED_BASE_HREF\"" "$tmp/index.html" \
  || fail "Pages shell has the wrong base href"
grep -Fq 'flutter_bootstrap.js' "$tmp/index.html" \
  || fail "Pages shell does not reference flutter_bootstrap.js"
grep -Fq 'http-equiv="Content-Security-Policy"' "$tmp/index.html" \
  || fail "Pages shell does not contain the CSP meta tag"
grep -Fq "default-src 'self'" "$tmp/index.html" \
  || fail "Pages shell CSP must default to same-origin resources"
grep -Fq "script-src 'self' 'wasm-unsafe-eval' https://cdn.jsdelivr.net" \
  "$tmp/index.html" \
  || fail "Pages shell CSP must allow the bootstrap and reviewed camera helper"
grep -Fq "style-src 'self' 'unsafe-inline'" "$tmp/index.html" \
  || fail "Pages shell CSP must allow Flutter's inline styles"
grep -Fq "connect-src 'self' https:" "$tmp/index.html" \
  || fail "Pages shell CSP must allow configured HTTPS API origins"
grep -Fq "object-src 'none'" "$tmp/index.html" \
  || fail "Pages shell CSP must disable plug-in content"
if grep -Fq "'unsafe-eval'" "$tmp/index.html"; then
  fail "Pages shell CSP must not allow eval"
fi
if grep -Eq "script-src[^;]*'unsafe-inline'" "$tmp/index.html"; then
  fail "Pages shell CSP must not allow inline scripts"
fi
grep -Fq '<meta name="viewport"' "$tmp/index.html" \
  || fail "Pages shell does not contain viewport metadata"

if grep -Eiq '<script[^>]+\b(src|href)=[^>]*https?://' "$tmp/index.html"; then
  fail "Pages shell contains a third-party script reference"
fi

for path in flutter_bootstrap.js main.dart.js; do
  resource_status="$(curl -sS --max-time 20 -L -o "$tmp/$path" -w '%{http_code}' "${URL}${path}")"
  [[ "$resource_status" == 200 ]] || fail "Pages resource returned HTTP $resource_status: $path"
  [[ -s "$tmp/$path" ]] || fail "Pages resource is empty: $path"
done

if find "$tmp" -type f -name '*.map' -print -quit | grep -q .; then
  fail "Deployed smoke-test resources include a source map"
fi

credential_patterns=(
  'eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}'
  '-----BEGIN [A-Z ]*PRIVATE KEY-----'
  'gh[pousr]_[A-Za-z0-9]{20,}'
  'github_pat_[A-Za-z0-9_]{20,}'
)
for pattern in "${credential_patterns[@]}"; do
  if grep -R -I -q -E -e "$pattern" "$tmp"; then
    fail "Credential-like value found in deployed Pages shell"
  fi
done

echo "OK: GitHub Pages deployment verified at $URL (base href $EXPECTED_BASE_HREF)"
