#!/usr/bin/env bash
set -euo pipefail
umask 077

SKILLS=(pipa-privacy kisa-secure-coding)
FILES=(SKILL.md logo.png catalog.json cases.json)
EXPECTED_MANIFEST_PATHS=(
  "skills/kisa-secure-coding/SKILL.md"
  "skills/kisa-secure-coding/catalog.json"
  "skills/kisa-secure-coding/logo.png"
  "skills/kisa-secure-coding/cases.json"
  "skills/pipa-privacy/SKILL.md"
  "skills/pipa-privacy/catalog.json"
  "skills/pipa-privacy/logo.png"
  "skills/pipa-privacy/cases.json"
)

usage() {
  echo "Usage: bash install.sh [--with-init] [--recover]"
  echo "  Installs pipa-privacy and kisa-secure-coding into Cursor (and Claude Code if present)."
  echo "  --recover rolls back an interrupted transaction whose recorded process is no longer running."
}

die() {
  echo "error: $*" >&2
  exit 1
}

WITH_INIT=0
RECOVER=0
for arg in "$@"; do
  case "$arg" in
    --with-init) WITH_INIT=1 ;;
    --recover) RECOVER=1 ;;
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

require_commands() {
  local command_name
  for command_name in awk basename cat cmp cp dirname grep ln mkdir mv rm rmdir uname; do
    command -v "$command_name" >/dev/null 2>&1 ||
      die "required command is missing: $command_name"
  done
  if ! command -v sha256sum >/dev/null 2>&1 &&
    ! command -v shasum >/dev/null 2>&1; then
    die "sha256sum or shasum is required"
  fi
}

require_commands

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
TXN_LOCK_OWNED=0
TXN_INSTALLED_JOURNAL=""
TXN_BACKUP_JOURNAL=""
RULE_TMP=""

known_skill() {
  case "$1" in
    pipa-privacy|kisa-secure-coding) return 0 ;;
    *) return 1 ;;
  esac
}

journal_is_safe() {
  local journal="$1" skill
  [[ -f "$journal" ]] || return 0
  while IFS= read -r skill; do
    [[ -z "$skill" ]] && continue
    known_skill "$skill" || return 1
  done < "$journal"
}

remove_owned_lock() {
  if [[ "$TXN_LOCK_OWNED" -eq 1 ]]; then
    rm -rf "$TXN_LOCK"
    TXN_LOCK_OWNED=0
  fi
}

rollback_transaction() {
  local skill restore_failed=0
  [[ "$TXN_ACTIVE" -eq 1 ]] || return 0
  if [[ -f "$TXN_DIR/committed" ]]; then
    rm -rf "$TXN_DIR"
    remove_owned_lock
    TXN_ACTIVE=0
    return 0
  fi
  journal_is_safe "$TXN_INSTALLED_JOURNAL" &&
    journal_is_safe "$TXN_BACKUP_JOURNAL" ||
    die "transaction journal contains an unexpected skill name"
  if [[ -f "$TXN_INSTALLED_JOURNAL" ]]; then
    while IFS= read -r skill; do
      [[ -z "$skill" ]] && continue
      rm -rf "$TXN_PARENT/$skill"
    done < "$TXN_INSTALLED_JOURNAL"
  fi
  if [[ -f "$TXN_BACKUP_JOURNAL" ]]; then
    while IFS= read -r skill; do
      [[ -z "$skill" ]] && continue
      if [[ -e "$TXN_BACKUP/$skill" || -L "$TXN_BACKUP/$skill" ]]; then
        mv "$TXN_BACKUP/$skill" "$TXN_PARENT/$skill" || {
          restore_failed=1
          echo "error: could not restore $TXN_PARENT/$skill" >&2
        }
      fi
    done < "$TXN_BACKUP_JOURNAL"
  fi
  if [[ "$restore_failed" -eq 0 ]]; then
    rm -rf "$TXN_DIR"
    remove_owned_lock
  else
    echo "error: recovery files retained at $TXN_DIR" >&2
    echo "error: resolve the filesystem problem, then rerun with --recover" >&2
  fi
  TXN_ACTIVE=0
}

recover_stale_lock() {
  local parent="$1" lock="$2" owner_pid="" recorded_txn=""
  [[ -e "$lock" || -L "$lock" ]] || return 0
  [[ "$RECOVER" -eq 1 ]] ||
    die "another or interrupted Safe Vibe installation exists at $parent; rerun with --recover after confirming no installer is active"
  if [[ -f "$lock" && ! -L "$lock" ]]; then
    owner_pid="$(awk 'NR == 1 { print; exit }' "$lock")"
    recorded_txn="$(awk 'NR == 2 { print; exit }' "$lock")"
  elif [[ -d "$lock" && -f "$lock/pid" ]]; then
    owner_pid="$(cat "$lock/pid")"
    if [[ -f "$lock/transaction" ]]; then
      recorded_txn="$(cat "$lock/transaction")"
    fi
  else
    die "lock metadata is invalid at $lock"
  fi
  case "$owner_pid" in
    ""|*[!0-9]*) die "lock metadata has an invalid process id at $lock" ;;
  esac
  if kill -0 "$owner_pid" 2>/dev/null; then
    die "Safe Vibe installer process $owner_pid is still active"
  fi
  if [[ -n "$recorded_txn" ]]; then
    [[ "$(dirname "$recorded_txn")" == "$parent" &&
      "$(basename "$recorded_txn")" == .safe-vibe-transaction.* ]] ||
      die "lock contains an unsafe transaction path"
    if [[ ! -d "$recorded_txn" ]]; then
      rm -rf "$lock"
      return 0
    fi
    TXN_PARENT="$parent"
    TXN_LOCK="$lock"
    TXN_LOCK_OWNED=1
    TXN_DIR="$recorded_txn"
    TXN_BACKUP="$TXN_DIR/backup"
    TXN_INSTALLED_JOURNAL="$TXN_DIR/installed"
    TXN_BACKUP_JOURNAL="$TXN_DIR/backed-up"
    TXN_ACTIVE=1
    rollback_transaction
  else
    rm -rf "$lock"
  fi
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
  local skill file installed_count=0 lock_candidate
  TXN_PARENT="$dest_root/skills"
  TXN_LOCK="$TXN_PARENT/.safe-vibe-install.lock"
  TXN_DIR="$TXN_PARENT/.safe-vibe-transaction.$$.$RANDOM"
  TXN_BACKUP="$TXN_DIR/backup"
  TXN_INSTALLED_JOURNAL="$TXN_DIR/installed"
  TXN_BACKUP_JOURNAL="$TXN_DIR/backed-up"
  TXN_LOCK_OWNED=0

  mkdir -p "$TXN_PARENT"
  recover_stale_lock "$TXN_PARENT" "$TXN_LOCK"
  mkdir -p "$TXN_DIR/stage" "$TXN_BACKUP"
  TXN_ACTIVE=1
  : > "$TXN_INSTALLED_JOURNAL"
  : > "$TXN_BACKUP_JOURNAL"
  lock_candidate="$TXN_DIR/lock"
  printf '%s\n%s\n' "$$" "$TXN_DIR" > "$lock_candidate"
  if ! ln "$lock_candidate" "$TXN_LOCK" 2>/dev/null; then
    rollback_transaction
    die "another Safe Vibe installation is active at $TXN_PARENT"
  fi
  TXN_LOCK_OWNED=1

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
      printf '%s\n' "$skill" >> "$TXN_BACKUP_JOURNAL"
      mv "$TXN_PARENT/$skill" "$TXN_BACKUP/$skill"
    fi
  done

  if [[ "${SAFE_VIBE_TESTING:-0}" == "1" &&
    "${SAFE_VIBE_TEST_FAIL_AFTER_BACKUP:-0}" == "1" ]]; then
    echo "error: injected post-backup failure" >&2
    rollback_transaction
    return 1
  fi

  for skill in "${SKILLS[@]}"; do
    printf '%s\n' "$skill" >> "$TXN_INSTALLED_JOURNAL"
    if ! mv "$TXN_DIR/stage/$skill" "$TXN_PARENT/$skill"; then
      echo "error: could not replace $TXN_PARENT/$skill" >&2
      rollback_transaction
      return 1
    fi
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

  : > "$TXN_DIR/committed"
  TXN_ACTIVE=0
  rm -rf "$TXN_DIR"
  if ! rm -f "$TXN_LOCK"; then
    die "installation succeeded but lock cleanup failed at $TXN_LOCK"
  fi
  TXN_LOCK_OWNED=0
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
  if ln "$RULE_TMP" .cursor/rules/safe-vibe.mdc 2>/dev/null; then
    rm -f "$RULE_TMP"
    RULE_TMP=""
    echo "  wrote $(pwd)/.cursor/rules/safe-vibe.mdc"
  else
    rm -f "$RULE_TMP"
    RULE_TMP=""
    echo "  kept existing $(pwd)/.cursor/rules/safe-vibe.mdc"
  fi
fi

echo "done"
