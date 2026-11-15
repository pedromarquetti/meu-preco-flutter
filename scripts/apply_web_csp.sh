#!/usr/bin/env bash
#
# Applies the production Content-Security-Policy to a built Web shell.
#
# Usage:
#   scripts/apply_web_csp.sh [bundle-dir]
#
# Environment overrides:
#   BUNDLE_DIR   Bundle directory (default: build/web)
#
# web/index.html carries the development/local baseline policy so that
# `flutter run` and a plain local build keep working. The published bundle must
# not ship eval, inline scripts, broad HTTP/WebSocket sources, or the CanvasKit
# CDN, so this script replaces that single meta tag with the production policy.
# It fails if the shell does not contain exactly one CSP meta tag.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE="${1:-${BUNDLE_DIR:-$REPO_ROOT/build/web}}"
INDEX="$BUNDLE/index.html"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

[[ -s "$INDEX" ]] || fail "Web shell not found: $INDEX"
command -v python3 >/dev/null 2>&1 || fail "python3 is required"

# Keep this in sync with scripts/verify_web_bundle.sh and the README.
#
# - script-src: same-origin bootstrap/entrypoint plus the reviewed mobile_scanner
#   zxing-wasm helper. 'wasm-unsafe-eval' is required for CanvasKit and zxing-wasm.
# - style-src: Flutter creates inline styles while rendering.
# - connect-src: runtime-selected HTTPS API origins, the zxing-wasm binary, and
#   localhost HTTP only for testing a production bundle locally.
# - worker-src/child-src: CanvasKit blob workers.
# - object-src 'none', base-uri 'self', form-action 'self': reduce the attack surface.
# - frame-ancestors/sandbox/report-uri are intentionally absent: browsers ignore
#   them when CSP is delivered with a meta element.
PRODUCTION_CSP="default-src 'self'; script-src 'self' 'wasm-unsafe-eval' https://cdn.jsdelivr.net; style-src 'self' 'unsafe-inline'; img-src 'self' data: blob:; font-src 'self' data: https://fonts.gstatic.com; connect-src 'self' https: http://localhost:* http://127.0.0.1:*; media-src 'self' blob:; worker-src 'self' blob:; child-src 'self' blob:; object-src 'none'; base-uri 'self'; form-action 'self';"

python3 - "$INDEX" "$PRODUCTION_CSP" <<'PY'
import re
import sys

path, policy = sys.argv[1], sys.argv[2]
with open(path, encoding="utf-8") as handle:
    shell = handle.read()

pattern = re.compile(
    r'<meta\s+http-equiv="Content-Security-Policy"\s+content="[^"]*"\s*/?>',
    re.DOTALL,
)
replacement = (
    '<meta http-equiv="Content-Security-Policy" '
    f'content="{policy}" />'
)
updated, count = pattern.subn(replacement, shell, count=1)
if count != 1:
    raise SystemExit(
        f"FAIL: expected exactly one Content-Security-Policy meta tag in {path}, "
        f"found {count}"
    )

with open(path, "w", encoding="utf-8") as handle:
    handle.write(updated)
PY

echo "OK: production CSP applied to $INDEX"
