"""Rewrite manifest.sha256 for the current skill payload."""
from __future__ import annotations

import hashlib
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATHS = (
    "skills/kisa-secure-coding/SKILL.md",
    "skills/kisa-secure-coding/catalog.json",
    "skills/kisa-secure-coding/logo.png",
    "skills/kisa-secure-coding/cases.json",
    "skills/pipa-privacy/SKILL.md",
    "skills/pipa-privacy/catalog.json",
    "skills/pipa-privacy/logo.png",
    "skills/pipa-privacy/cases.json",
)


def main() -> int:
    lines = []
    for relative in PATHS:
        digest = hashlib.sha256((ROOT / relative).read_bytes()).hexdigest()
        lines.append(f"{digest}  {relative}")
    (ROOT / "manifest.sha256").write_text(
        "\n".join(lines) + "\n",
        encoding="utf-8",
        newline="\n",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
