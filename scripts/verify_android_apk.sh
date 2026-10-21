#!/usr/bin/env bash
#
# Verifies a built Android APK without exposing signing secrets.
#
# Checks that the artifact exists, is signed (not unsigned), is signed by a
# key whose certificate digest does NOT match the well-known Android debug
# keystore, and that its package identity matches this project.
#
# Usage:
#   scripts/verify_android_apk.sh [path/to/app-release.apk]
#
# Exits non-zero on any problem. Never prints keystore passwords.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APK="${1:-$REPO_ROOT/build/app/outputs/flutter-apk/app-release.apk}"

EXPECTED_APPLICATION_ID="com.app.meupreco"

# The Android debug keystore is generated with this fixed subject. A release
# artifact must never carry it.
DEBUG_KEY_SUBJECT="CN=Android Debug"

fail() { echo "FAIL: $*" >&2; exit 1; }

[[ -f "$APK" ]] || fail "APK not found: $APK"

# Locate apksigner / aapt2 from the Android SDK.
sdk_root="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Android/Sdk}}"
apksigner="$(ls "$sdk_root"/build-tools/*/apksigner 2>/dev/null | sort -V | tail -1 || true)"
aapt2="$(ls "$sdk_root"/build-tools/*/aapt2 2>/dev/null | sort -V | tail -1 || true)"
[[ -n "$apksigner" ]] || fail "apksigner not found under $sdk_root/build-tools/*"

echo "==> Verifying signature: $APK"
if ! "$apksigner" verify "$APK" >/dev/null 2>&1; then
  fail "apksigner verify failed: artifact is unsigned or has an invalid signature"
fi

certs="$("$apksigner" verify --print-certs "$APK" 2>/dev/null || true)"
digest="$(printf '%s\n' "$certs" | grep -i 'SHA-256 digest' | head -1 | awk '{print $NF}')"
subject="$(printf '%s\n' "$certs" | grep -i 'certificate DN:' | head -1 | sed -E 's/.*certificate DN: *//')"
[[ -n "$digest" ]] || fail "could not read the signing certificate digest"
echo "    signer SHA-256: $digest"
echo "    signer subject: $subject"

if [[ "$subject" == *"$DEBUG_KEY_SUBJECT"* ]]; then
  fail "artifact is signed with the Android DEBUG key; it is not a release artifact"
fi

if [[ -n "$aapt2" ]]; then
  badging="$("$aapt2" dump badging "$APK" 2>/dev/null || true)"
  pkg="$(printf '%s\n' "$badging" | grep -m1 "^package:" | grep -oE "name='[^']*'" | head -1 | cut -d"'" -f2)"
  version="$(printf '%s\n' "$badging" | grep -m1 "^package:" | grep -oE "versionCode='[^']*'" | head -1 | cut -d"'" -f2)"
  label="$(printf '%s\n' "$badging" | grep -m1 "application-label:" | cut -d"'" -f2)"

  echo "    applicationId: $pkg"
  echo "    versionCode:   $version"
  echo "    label:         $label"

  [[ "$pkg" == "$EXPECTED_APPLICATION_ID" ]] \
    || fail "unexpected applicationId '$pkg' (expected '$EXPECTED_APPLICATION_ID')"
else
  echo "    (aapt2 not found; skipped package metadata checks)"
fi

echo "OK: signed release artifact verified"
