#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
command -v python3 >/dev/null 2>&1 || {
  echo "python3 is required to build release artifacts" >&2
  exit 1
}
python3 "$ROOT/scripts/build_release.py" "$@"
