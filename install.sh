#!/usr/bin/env bash
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/days0854/safe-vibe/main"
SKILLS=(pipa-privacy kisa-secure-coding)
FILES=(SKILL.md logo.png catalog.json)

usage() {
  echo "Usage: bash install.sh [--with-init]"
  echo "  Installs pipa-privacy and kisa-secure-coding into Cursor (and Claude Code if present)."
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

ROOT=""
_src="${BASH_SOURCE[0]:-}"
if [[ -n "$_src" && "$_src" != "-" && -f "$_src" ]]; then
  _dir="$(cd "$(dirname "$_src")" && pwd)"
  if [[ -f "$_dir/skills/pipa-privacy/SKILL.md" ]]; then
    ROOT="$_dir"
  fi
fi
if [[ -z "$ROOT" && -f "./skills/pipa-privacy/SKILL.md" ]]; then
  ROOT="$(pwd)"
fi

TMP=""
cleanup() {
  if [[ -n "${TMP:-}" && -d "$TMP" ]]; then
    rm -rf "$TMP"
  fi
}
trap cleanup EXIT

fetch() {
  # fetch <relative-path> <dest-file>
  local rel="$1" dest="$2"
  if [[ -n "$ROOT" && -f "$ROOT/$rel" ]]; then
    cp "$ROOT/$rel" "$dest"
  else
    curl -fsSL "$REPO_RAW/$rel" -o "$dest"
  fi
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

if [[ -z "$ROOT" ]]; then
  if ! need_cmd curl; then
    echo "curl is required to download skills" >&2
    exit 1
  fi
  TMP="$(mktemp -d "${TMPDIR:-/tmp}/safe-vibe.XXXXXX")"
fi

install_one() {
  # install_one <dest-root>   dest-root is ~/.cursor or ~/.claude
  local dest_root="$1"
  local skill rel dest
  mkdir -p "$dest_root/skills"
  for skill in "${SKILLS[@]}"; do
    dest="$dest_root/skills/$skill"
    mkdir -p "$dest"
    for f in "${FILES[@]}"; do
      rel="skills/$skill/$f"
      fetch "$rel" "$dest/$f"
      echo "  wrote $dest/$f"
    done
  done
}

echo "Safe Vibe installer (OS=$OS)"
if [[ -n "$ROOT" ]]; then
  echo "source: local $ROOT"
else
  echo "source: $REPO_RAW"
fi

mkdir -p "$HOME/.cursor/skills"
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
  cat > .cursor/rules/safe-vibe.mdc << 'MDC'
---
description: Safe Vibe — 개인정보보호·시큐어코딩 스킬을 쓸 것
alwaysApply: true
---

웹 가입·동의·처리방침·쿠키·제3자·탈퇴·아동 흐름을 만들 때는 pipa-privacy 스킬과 catalog.json을 본다.
애플리케이션 코드를 쓰거나 리뷰할 때는 kisa-secure-coding 스킬과 catalog.json을 본다.
법률 자문이 아니며 원문 PDF·조문 전문을 인용하지 않는다.
MDC
  echo "  wrote $(pwd)/.cursor/rules/safe-vibe.mdc"
fi

echo "done"
