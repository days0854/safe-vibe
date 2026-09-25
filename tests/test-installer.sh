#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-all}"
PASSED=0

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

pass() {
  PASSED=$((PASSED + 1))
  echo "PASS: $1"
}

verify_checksum_file() {
  local directory="$1" manifest="$2"
  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$directory" && sha256sum --quiet -c "$manifest")
  elif command -v shasum >/dev/null 2>&1; then
    (cd "$directory" && shasum -a 256 -c "$manifest" >/dev/null)
  else
    fail "sha256sum or shasum is required"
  fi
}

test_manifest() {
  local manifest="$ROOT/manifest.sha256"
  [[ -f "$manifest" ]] || fail "manifest.sha256 is missing"
  [[ "$(awk 'NF { count++ } END { print count + 0 }' "$manifest")" -eq 6 ]] ||
    fail "manifest must contain exactly six entries"
  verify_checksum_file "$ROOT" "manifest.sha256" ||
    fail "manifest verification failed"
  pass "payload manifest verifies six files"
}

case "$MODE" in
  manifest) test_manifest ;;
  all) test_manifest ;;
  *) fail "unknown test mode: $MODE" ;;
esac

echo "$PASSED test group(s) passed"
