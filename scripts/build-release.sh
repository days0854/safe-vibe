#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-}"
OUTPUT_ARG="${2:-}"

if [[ ! "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "usage: bash scripts/build-release.sh vMAJOR.MINOR.PATCH OUTPUT_DIR" >&2
  exit 1
fi
[[ -n "$OUTPUT_ARG" ]] || {
  echo "output directory is required" >&2
  exit 1
}
command -v tar >/dev/null 2>&1 || {
  echo "GNU tar is required" >&2
  exit 1
}
tar --version 2>/dev/null | grep -q "GNU tar" || {
  echo "GNU tar is required for reproducible archives" >&2
  exit 1
}
command -v gzip >/dev/null 2>&1 || {
  echo "gzip is required" >&2
  exit 1
}

verify_manifest() {
  if command -v sha256sum >/dev/null 2>&1; then
    (cd "$ROOT" && sha256sum --quiet -c manifest.sha256)
  elif command -v shasum >/dev/null 2>&1; then
    (cd "$ROOT" && shasum -a 256 -c manifest.sha256 >/dev/null)
  else
    echo "sha256sum or shasum is required" >&2
    return 1
  fi
}

hash_file() {
  local file="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$file" | awk '{ print $1 }'
  else
    shasum -a 256 "$file" | awk '{ print $1 }'
  fi
}

verify_manifest || {
  echo "payload manifest verification failed" >&2
  exit 1
}

mkdir -p "$OUTPUT_ARG"
OUTPUT="$(cd "$OUTPUT_ARG" && pwd)"
TMP="$(mktemp -d "${TMPDIR:-/tmp}/safe-vibe-release.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

PACKAGE_NAME="safe-vibe-$VERSION"
PACKAGE="$TMP/$PACKAGE_NAME"
ARCHIVE_NAME="$PACKAGE_NAME.tar.gz"
ARCHIVE_TMP="$OUTPUT/.$ARCHIVE_NAME.$$"
mkdir -p "$PACKAGE"
cp "$ROOT/install.sh" "$ROOT/manifest.sha256" "$PACKAGE/"

for skill in pipa-privacy kisa-secure-coding; do
  mkdir -p "$PACKAGE/skills/$skill"
  for file in SKILL.md catalog.json logo.png; do
    cp "$ROOT/skills/$skill/$file" "$PACKAGE/skills/$skill/$file"
  done
done

tar \
  --sort=name \
  --mtime='@0' \
  --owner=0 \
  --group=0 \
  --numeric-owner \
  --format=ustar \
  -C "$TMP" \
  -cf - "$PACKAGE_NAME" |
  gzip -n -9 > "$ARCHIVE_TMP"

mv "$ARCHIVE_TMP" "$OUTPUT/$ARCHIVE_NAME"
DIGEST="$(hash_file "$OUTPUT/$ARCHIVE_NAME")"
printf '%s  %s\n' "$DIGEST" "$ARCHIVE_NAME" > "$OUTPUT/$ARCHIVE_NAME.sha256"
echo "$DIGEST  $OUTPUT/$ARCHIVE_NAME"
