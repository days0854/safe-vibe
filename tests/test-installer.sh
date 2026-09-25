#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODE="${1:-all}"
PASSED=0
TEST_TMP=""

cleanup() {
  if [[ -n "$TEST_TMP" && -d "$TEST_TMP" ]]; then
    rm -rf "$TEST_TMP"
  fi
}
trap cleanup EXIT

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

new_test_home() {
  cleanup
  TEST_TMP="$(mktemp -d "${TMPDIR:-/tmp}/safe-vibe-test.XXXXXX")"
  mkdir -p "$TEST_TMP/home"
}

assert_installed_skill() {
  local dest_root="$1" skill="$2" file
  for file in SKILL.md catalog.json logo.png; do
    cmp "$ROOT/skills/$skill/$file" "$dest_root/skills/$skill/$file" >/dev/null ||
      fail "$dest_root $skill $file does not match payload"
  done
}

run_installer() {
  local home="$1"
  shift
  HOME="$home" bash "$ROOT/install.sh" "$@"
}

test_cursor_install() {
  new_test_home
  run_installer "$TEST_TMP/home" >/dev/null
  assert_installed_skill "$TEST_TMP/home/.cursor" "pipa-privacy"
  assert_installed_skill "$TEST_TMP/home/.cursor" "kisa-secure-coding"
  [[ ! -e "$TEST_TMP/home/.cursor/skills/.safe-vibe-install.lock" ]] ||
    fail "Cursor lock was not removed"
  pass "Cursor payload installs atomically"
}

test_claude_install() {
  new_test_home
  mkdir -p "$TEST_TMP/home/.claude"
  run_installer "$TEST_TMP/home" >/dev/null
  assert_installed_skill "$TEST_TMP/home/.claude" "pipa-privacy"
  assert_installed_skill "$TEST_TMP/home/.claude" "kisa-secure-coding"
  pass "Claude payload installs when configured"
}

copy_package() {
  local destination="$1"
  mkdir -p "$destination"
  cp "$ROOT/install.sh" "$ROOT/manifest.sha256" "$destination/"
  cp -R "$ROOT/skills" "$destination/"
}

test_manifest_rejection() {
  new_test_home
  copy_package "$TEST_TMP/package"
  printf '\n' >> "$TEST_TMP/package/skills/pipa-privacy/catalog.json"
  mkdir -p "$TEST_TMP/home/.cursor/skills/pipa-privacy"
  printf 'original\n' > "$TEST_TMP/home/.cursor/skills/pipa-privacy/marker"
  if HOME="$TEST_TMP/home" bash "$TEST_TMP/package/install.sh" >/dev/null 2>&1; then
    fail "installer accepted a modified payload"
  fi
  [[ "$(cat "$TEST_TMP/home/.cursor/skills/pipa-privacy/marker")" == "original" ]] ||
    fail "destination changed after manifest rejection"
  pass "modified payload is rejected before destination changes"
}

test_lock_rejection() {
  new_test_home
  mkdir -p "$TEST_TMP/home/.cursor/skills/.safe-vibe-install.lock"
  if run_installer "$TEST_TMP/home" >/dev/null 2>&1; then
    fail "installer ignored an active lock"
  fi
  [[ -d "$TEST_TMP/home/.cursor/skills/.safe-vibe-install.lock" ]] ||
    fail "installer removed a lock it did not own"
  pass "concurrent install lock is rejected"
}

test_rollback() {
  new_test_home
  local skill
  for skill in pipa-privacy kisa-secure-coding; do
    mkdir -p "$TEST_TMP/home/.cursor/skills/$skill"
    printf 'original-%s\n' "$skill" > "$TEST_TMP/home/.cursor/skills/$skill/marker"
  done
  if SAFE_VIBE_TESTING=1 SAFE_VIBE_TEST_FAIL_AFTER_FIRST_REPLACE=1 \
    run_installer "$TEST_TMP/home" >/dev/null 2>&1; then
    fail "injected replacement failure unexpectedly succeeded"
  fi
  for skill in pipa-privacy kisa-secure-coding; do
    [[ "$(cat "$TEST_TMP/home/.cursor/skills/$skill/marker")" == "original-$skill" ]] ||
      fail "$skill was not restored after failure"
  done
  pass "replacement failure restores both previous skills"
}

test_rule_preservation() {
  new_test_home
  mkdir -p "$TEST_TMP/project/.cursor/rules"
  printf 'user-owned-rule\n' > "$TEST_TMP/project/.cursor/rules/safe-vibe.mdc"
  (
    cd "$TEST_TMP/project"
    run_installer "$TEST_TMP/home" --with-init >/dev/null
  )
  [[ "$(cat "$TEST_TMP/project/.cursor/rules/safe-vibe.mdc")" == "user-owned-rule" ]] ||
    fail "existing safe-vibe rule was overwritten"
  pass "existing project rule is preserved"
}

test_remote_pipe_refusal() {
  new_test_home
  mkdir -p "$TEST_TMP/empty"
  if (
    cd "$TEST_TMP/empty"
    HOME="$TEST_TMP/home" bash -s < "$ROOT/install.sh"
  ) >"$TEST_TMP/stdout" 2>"$TEST_TMP/stderr"; then
    fail "stdin installer execution unexpectedly succeeded"
  fi
  grep -Eq "release|packaged payload|local payload" "$TEST_TMP/stderr" ||
    fail "stdin refusal did not explain the secure installation requirement"
  pass "remote pipe execution fails closed"
}

test_installer() {
  test_cursor_install
  test_claude_install
  test_manifest_rejection
  test_lock_rejection
  test_rollback
  test_rule_preservation
  test_remote_pipe_refusal
}

test_release() {
  local builder="$ROOT/scripts/build-release.sh"
  local version="v0.1.0"
  local archive="safe-vibe-$version.tar.gz"
  [[ -f "$builder" ]] || fail "release builder is missing"
  new_test_home
  mkdir -p "$TEST_TMP/out-one" "$TEST_TMP/out-two"
  bash "$builder" "$version" "$TEST_TMP/out-one" >/dev/null
  bash "$builder" "$version" "$TEST_TMP/out-two" >/dev/null
  cmp "$TEST_TMP/out-one/$archive" "$TEST_TMP/out-two/$archive" >/dev/null ||
    fail "release archives are not reproducible"
  verify_checksum_file "$TEST_TMP/out-one" "$archive.sha256" ||
    fail "outer release checksum failed"
  mkdir -p "$TEST_TMP/extracted"
  tar -xzf "$TEST_TMP/out-one/$archive" -C "$TEST_TMP/extracted"
  verify_checksum_file "$TEST_TMP/extracted/safe-vibe-$version" "manifest.sha256" ||
    fail "packaged payload manifest failed"
  HOME="$TEST_TMP/home" \
    bash "$TEST_TMP/extracted/safe-vibe-$version/install.sh" >/dev/null
  assert_installed_skill "$TEST_TMP/home/.cursor" "pipa-privacy"
  if bash "$builder" "not-a-version" "$TEST_TMP/invalid" >/dev/null 2>&1; then
    fail "release builder accepted an invalid version"
  fi
  pass "release build is reproducible and independently verifiable"
}

case "$MODE" in
  manifest) test_manifest ;;
  installer) test_installer ;;
  release) test_release ;;
  all) test_manifest; test_installer; test_release ;;
  *) fail "unknown test mode: $MODE" ;;
esac

echo "$PASSED test group(s) passed"
