#!/usr/bin/env bash
#
# Verifies a Flutter Web bundle against GitHub Pages-style static hosting.
#
# Usage:
#   scripts/verify_web_routing.sh [bundle-dir] [expected-base-href]
#
# Environment overrides:
#   BUNDLE_DIR   Bundle directory (default: build/web)
#   BASE_HREF    Expected <base href> value
#
# The bundle is mounted under the expected base path and served without SPA
# rewrites, matching GitHub Pages. The checks prove that the application shell
# loads under the repository sub-path, that assets keep their real content
# types, and that missing paths or assets never receive the application shell.
# Hash routes stay client-side, so a refresh of /repo/#/products/42 only needs
# the shell at /repo/.
#
# Requires curl and python3.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE="${1:-${BUNDLE_DIR:-$REPO_ROOT/build/web}}"
BASE_HREF="${2:-${BASE_HREF:-}}"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -d "$BUNDLE" ]] || fail "Web bundle directory not found: $BUNDLE"
BUNDLE="$(cd "$BUNDLE" && pwd)"

[[ -n "$BASE_HREF" ]] \
  || fail "An expected base href is required (for example /home/)"
[[ "$BASE_HREF" == /* ]] || fail "BASE_HREF must start with '/'"
[[ "$BASE_HREF" == */ ]] || fail "BASE_HREF must end with '/'"
[[ "$BASE_HREF" != *"//"* ]] || fail "BASE_HREF must not contain '//'"
[[ "$BASE_HREF" != *".."* ]] || fail "BASE_HREF must not contain '..'"
[[ "$BASE_HREF" != *[[:space:]]* ]] \
  || fail "BASE_HREF must not contain whitespace"

command -v curl >/dev/null 2>&1 || fail "curl is required"
command -v python3 >/dev/null 2>&1 || fail "python3 is required"

grep -Fq 'src="flutter_bootstrap.js"' "$BUNDLE/index.html" \
  || fail "index.html must load flutter_bootstrap.js relative to the base href"

# A GitHub Pages SPA fallback that publishes the application as 404.html would
# answer missing assets with HTML. The project uses hash routing instead.
if [[ -f "$BUNDLE/404.html" ]] \
  && { grep -Fq "flutter_bootstrap.js" "$BUNDLE/404.html" \
    || grep -Fq "main.dart.js" "$BUNDLE/404.html"; }; then
  fail "404.html serves the application shell; missing assets must not return HTML"
fi

tmp="$(mktemp -d)"
server_pid=""
cleanup() {
  if [[ -n "$server_pid" ]]; then
    kill "$server_pid" 2>/dev/null || true
    wait "$server_pid" 2>/dev/null || true
  fi
  rm -rf "$tmp"
}
trap cleanup EXIT

base_dir="${BASE_HREF#/}"
base_dir="${base_dir%/}"

if [[ -z "$base_dir" ]]; then
  site_root="$BUNDLE"
else
  site_root="$tmp/site"
  mkdir -p "$site_root/$(dirname "$base_dir")"
  ln -s "$BUNDLE" "$site_root/$base_dir"
fi

port="$(
  python3 - <<'PY'
import socket

with socket.socket() as sock:
    sock.bind(("127.0.0.1", 0))
    print(sock.getsockname()[1])
PY
)"
python3 -m http.server "$port" --bind 127.0.0.1 --directory "$site_root" \
  >"$tmp/server.log" 2>&1 &
server_pid=$!

base_url="http://127.0.0.1:$port"
ready=0
for _ in $(seq 1 50); do
  if curl -fsS --max-time 2 -o /dev/null "$base_url$BASE_HREF" 2>/dev/null; then
    ready=1
    break
  fi
  sleep 0.1
done
if [[ "$ready" -ne 1 ]]; then
  cat "$tmp/server.log" >&2 || true
  fail "Local Pages server did not become ready"
fi

STATUS=""
CONTENT_TYPE=""
BODY="$tmp/body"
HEADERS="$tmp/headers"

fetch() {
  local path="$1"
  STATUS="$(curl -sS --max-time 10 -D "$HEADERS" -o "$BODY" -w '%{http_code}' \
    "$base_url$path")"
  CONTENT_TYPE="$(
    tr -d '\r' <"$HEADERS" \
      | awk 'tolower($1) == "content-type:" { print $2; exit }'
  )"
}

expect_response() {
  local label="$1" path="$2" expected_status="$3" expected_type="$4"

  fetch "$path"
  [[ "$STATUS" == "$expected_status" ]] \
    || fail "$label returned HTTP $STATUS (expected $expected_status): $path"

  case "$expected_type" in
    html)
      [[ "$CONTENT_TYPE" == text/html* ]] \
        || fail "$label is not HTML ($CONTENT_TYPE): $path"
      ;;
    not-html)
      [[ "$CONTENT_TYPE" != text/html* ]] \
        || fail "$label was answered with HTML: $path"
      [[ -s "$BODY" ]] || fail "$label body is empty: $path"
      ;;
    *)
      fail "Unknown expected type: $expected_type"
      ;;
  esac
}

expect_response "application shell" "$BASE_HREF" 200 html
grep -Fq "<base href=\"$BASE_HREF\"" "$BODY" \
  || fail "application shell has the wrong base href"
grep -Fq "flutter_bootstrap.js" "$BODY" \
  || fail "application shell does not load flutter_bootstrap.js"

expect_response "Flutter bootstrap" "${BASE_HREF}flutter_bootstrap.js" 200 not-html
expect_response "compiled entrypoint" "${BASE_HREF}main.dart.js" 200 not-html

asset_path="$(find "$BUNDLE/assets" -type f -print -quit 2>/dev/null || true)"
[[ -n "$asset_path" ]] || fail "Web bundle has no assets directory"
asset_path="${asset_path#"$BUNDLE"/}"
expect_response "static asset" "$BASE_HREF$asset_path" 200 not-html

# Missing assets and path-only deep links must not receive the application
# shell; only hash routes are supported on Pages.
for missing in "${BASE_HREF}__missing__/asset.js" "${BASE_HREF}products/42"; do
  fetch "$missing"
  [[ "$STATUS" == "404" ]] \
    || fail "Missing path returned HTTP $STATUS instead of 404: $missing"
  if grep -Fq "flutter_bootstrap.js" "$BODY" \
    || grep -Fq "main.dart.js" "$BODY"; then
    fail "Missing path was answered with the application shell: $missing"
  fi
done

# The fragment never reaches the server; a refresh still only needs the shell.
fetch "${BASE_HREF}#/products/42"
[[ "$STATUS" == "200" ]] \
  || fail "Hash deep-link shell returned HTTP $STATUS"
grep -Fq "flutter_bootstrap.js" "$BODY" \
  || fail "Hash deep-link shell does not load the application"

echo "OK: Web routing verified for base href $BASE_HREF"
