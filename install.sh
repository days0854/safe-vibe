#!/usr/bin/env bash
set -euo pipefail
umask 077

SKILLS=(pipa-privacy kisa-secure-coding)
FILES=(SKILL.md logo.png catalog.json)
EXPECTED_MANIFEST_PATHS=(
  "skills/kisa-secure-coding/SKILL.md"
  "skills/kisa-secure-coding/catalog.json"
  "skills/kisa-secure-coding/logo.png"
  "skills/pipa-privacy/SKILL.md"
  "skills/pipa-privacy/catalog.json"
  "skills/pipa-privacy/logo.png"
)

usage() {
  echo "Usage: bash install.sh [--with-init]"
  echo "  Installs pipa-privacy and kisa-secure-coding into Cursor (and Claude Code if present)."
}

die() {
  echo "error: $*" >&2
  exit 1
}

WITH_INIT=0
for arg in "$@"; do
  case "$arg" in
    --with-init) WITH_INIT=1 ;;
    -h|--help) usage; exit 0 ;;
    "") ;;
    *) echo "unknown arg: $arg" >&2; usage; exit 1 ;;
  esac
done

OS="$(uname -s 2>/dev/null || echo unknown)"
case "$OS" in
  Darwin|Linux) ;;
  MINGW*|MSYS*|CYGWIN*) ;;
  *)
    echo "unsupported OS: $OS (need macOS, Linux, or WSL)" >&2
    exit 1
    ;;
esac

_src="${BASH_SOURCE[0]:-}"
[[ -n "$_src" && "$_src" != "-" && -f "$_src" ]] ||
  die "remote pipe execution is disabled; use the verified release archive"
ROOT="$(cd "$(dirname "$_src")" && pwd)"
[[ -f "$ROOT/manifest.sha256" && -d "$ROOT/skills" ]] ||
  die "local packaged payload is incomplete; use the verified release archive"

verify_manifest_layout() {
  local actual expected
  actual="$(awk 'NF { print $2 }' "$ROOT/manifest.sha256")"
  expected="$(printf '%s\n' "${EXPECTED_MANIFEST_PATHS[@]}")"
  [[ "$actual" == "$expected" ]] ||
    die "manifest contains an unexpected payload layout"
}

verify_manifest_hashes() {
  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$ROOT" && sha256sum --quiet -c manifest.sha256) ||
      die "payload checksum verification failed"
  elif command -v shasum >/dev/null 2>&1; then
    (cd "$ROOT" && shasum -a 256 -c manifest.sha256 >/dev/null) ||
      die "payload checksum verification failed"
  else
    die "sha256sum or shasum is required"
  fi
}

verify_manifest_layout
verify_manifest_hashes

TXN_ACTIVE=0
TXN_PARENT=""
TXN_DIR=""
TXN_BACKUP=""
TXN_LOCK=""
TXN_INSTALLED=()
TXN_BACKED_UP=()
RULE_TMP=""

rollback_transaction() {
  local skill restore_failed=0
  [[ "$TXN_ACTIVE" -eq 1 ]] || return 0
  for skill in "${TXN_INSTALLED[@]}"; do
    rm -rf "$TXN_PARENT/$skill"
  done
  for skill in "${TXN_BACKED_UP[@]}"; do
    if [[ -e "$TXN_BACKUP/$skill" || -L "$TXN_BACKUP/$skill" ]]; then
      mv "$TXN_BACKUP/$skill" "$TXN_PARENT/$skill" || {
        restore_failed=1
        echo "error: could not restore $TXN_PARENT/$skill" >&2
      }
    fi
  done
  if [[ "$restore_failed" -eq 0 ]]; then
    rm -rf "$TXN_DIR"
  else
    echo "error: recovery files retained at $TXN_DIR" >&2
  fi
  rmdir "$TXN_LOCK" 2>/dev/null || true
  TXN_ACTIVE=0
}

on_exit() {
  local status=$?
  trap - EXIT
  rollback_transaction
  if [[ -n "$RULE_TMP" ]]; then
    rm -f "$RULE_TMP"
  fi
  exit "$status"
}
trap on_exit EXIT
trap 'exit 129' HUP
trap 'exit 130' INT
trap 'exit 143' TERM

install_one() {
  local dest_root="$1"
  local skill file installed_count=0
  TXN_PARENT="$dest_root/skills"
  TXN_LOCK="$TXN_PARENT/.safe-vibe-install.lock"
  TXN_DIR="$TXN_PARENT/.safe-vibe-transaction.$$.$RANDOM"
  TXN_BACKUP="$TXN_DIR/backup"
  TXN_INSTALLED=()
  TXN_BACKED_UP=()

  mkdir -p "$TXN_PARENT"
  if ! mkdir "$TXN_LOCK" 2>/dev/null; then
    die "another Safe Vibe installation is active at $TXN_PARENT"
  fi
  TXN_ACTIVE=1
  mkdir -p "$TXN_DIR/stage" "$TXN_BACKUP"

  for skill in "${SKILLS[@]}"; do
    mkdir -p "$TXN_DIR/stage/$skill"
    for file in "${FILES[@]}"; do
      cp "$ROOT/skills/$skill/$file" "$TXN_DIR/stage/$skill/$file"
      cmp "$ROOT/skills/$skill/$file" "$TXN_DIR/stage/$skill/$file" >/dev/null ||
        die "staging verification failed for $skill/$file"
    done
  done

  for skill in "${SKILLS[@]}"; do
    if [[ -e "$TXN_PARENT/$skill" || -L "$TXN_PARENT/$skill" ]]; then
      mv "$TXN_PARENT/$skill" "$TXN_BACKUP/$skill"
      TXN_BACKED_UP+=("$skill")
    fi
  done

  for skill in "${SKILLS[@]}"; do
    if ! mv "$TXN_DIR/stage/$skill" "$TXN_PARENT/$skill"; then
      echo "error: could not replace $TXN_PARENT/$skill" >&2
      rollback_transaction
      return 1
    fi
    TXN_INSTALLED+=("$skill")
    installed_count=$((installed_count + 1))
    if [[ "${SAFE_VIBE_TESTING:-0}" == "1" &&
      "${SAFE_VIBE_TEST_FAIL_AFTER_FIRST_REPLACE:-0}" == "1" &&
      "$installed_count" -eq 1 ]]; then
      echo "error: injected replacement failure" >&2
      rollback_transaction
      return 1
    fi
    echo "  installed $TXN_PARENT/$skill"
  done

  rm -rf "$TXN_DIR"
  TXN_ACTIVE=0
  if ! rmdir "$TXN_LOCK"; then
    die "installation succeeded but lock cleanup failed at $TXN_LOCK"
  fi
}

echo "Safe Vibe installer (OS=$OS)"
echo "source: verified local payload $ROOT"

echo "Cursor:"
install_one "$HOME/.cursor"

if [[ -d "$HOME/.claude" ]]; then
  echo "Claude Code:"
  install_one "$HOME/.claude"
else
  echo "skip Claude Code (no $HOME/.claude)"
fi

if [[ "$WITH_INIT" -eq 1 ]]; then
  mkdir -p .cursor/rules
  if [[ -e .cursor/rules/safe-vibe.mdc || -L .cursor/rules/safe-vibe.mdc ]]; then
    echo "  kept existing $(pwd)/.cursor/rules/safe-vibe.mdc"
  else
    RULE_TMP=".cursor/rules/.safe-vibe.mdc.$$.$RANDOM"
    cat > "$RULE_TMP" << 'MDC'
---
description: Safe Vibe — 개인정보보호·시큐어코딩 스킬을 쓸 것
alwaysApply: true
---

웹 가입·동의·처리방침·쿠키·제3자·탈퇴·아동 흐름을 만들 때는 pipa-privacy 스킬과 catalog.json을 본다.
애플리케이션 코드를 쓰거나 리뷰할 때는 kisa-secure-coding 스킬과 catalog.json을 본다.
법률 자문이 아니며 원문 PDF·조문 전문을 인용하지 않는다.
MDC
    mv "$RULE_TMP" .cursor/rules/safe-vibe.mdc
    RULE_TMP=""
    echo "  wrote $(pwd)/.cursor/rules/safe-vibe.mdc"
  fi
fi

echo "done"
