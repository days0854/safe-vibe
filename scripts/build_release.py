#!/usr/bin/env python3
"""Build a byte-reproducible Safe Vibe release archive."""

from __future__ import annotations

import gzip
import hashlib
import io
import os
from pathlib import Path
import re
import sys
import tarfile
import tempfile
from typing import NoReturn


VERSION_RE = re.compile(r"^v[0-9]+\.[0-9]+\.[0-9]+$")
PAYLOAD_FILES = (
    "skills/kisa-secure-coding/SKILL.md",
    "skills/kisa-secure-coding/catalog.json",
    "skills/kisa-secure-coding/logo.png",
    "skills/pipa-privacy/SKILL.md",
    "skills/pipa-privacy/catalog.json",
    "skills/pipa-privacy/logo.png",
)


def fail(message: str) -> NoReturn:
    raise SystemExit(f"error: {message}")


def read_manifest(root: Path) -> dict[str, str]:
    entries: dict[str, str] = {}
    for line in (root / "manifest.sha256").read_text(encoding="ascii").splitlines():
        if not line:
            continue
        parts = line.split(maxsplit=1)
        if len(parts) != 2:
            fail("manifest.sha256 contains a malformed line")
        digest, relative = parts
        entries[relative.strip()] = digest
    if tuple(entries) != PAYLOAD_FILES:
        fail("manifest.sha256 contains an unexpected payload layout")
    return entries


def verified_files(root: Path) -> dict[str, bytes]:
    manifest = read_manifest(root)
    files: dict[str, bytes] = {
        "install.sh": (root / "install.sh").read_bytes(),
        "manifest.sha256": (root / "manifest.sha256").read_bytes(),
    }
    for relative in PAYLOAD_FILES:
        data = (root / relative).read_bytes()
        actual = hashlib.sha256(data).hexdigest()
        if actual != manifest[relative]:
            fail(f"payload checksum mismatch: {relative}")
        files[relative] = data
    return files


def add_directory(archive: tarfile.TarFile, name: str) -> None:
    info = tarfile.TarInfo(name.rstrip("/") + "/")
    info.type = tarfile.DIRTYPE
    info.mode = 0o755
    info.uid = 0
    info.gid = 0
    info.uname = ""
    info.gname = ""
    info.mtime = 0
    archive.addfile(info)


def add_file(archive: tarfile.TarFile, name: str, data: bytes) -> None:
    info = tarfile.TarInfo(name)
    info.mode = 0o755 if name.endswith("/install.sh") else 0o644
    info.uid = 0
    info.gid = 0
    info.uname = ""
    info.gname = ""
    info.mtime = 0
    info.size = len(data)
    archive.addfile(info, io.BytesIO(data))


def archive_bytes(version: str, files: dict[str, bytes]) -> bytes:
    package = f"safe-vibe-{version}"
    directories = {package}
    for relative in files:
        parent = Path(package, relative).parent
        while parent.as_posix() != ".":
            directories.add(parent.as_posix())
            if parent.as_posix() == package:
                break
            parent = parent.parent

    tar_buffer = io.BytesIO()
    with tarfile.open(
        fileobj=tar_buffer, mode="w", format=tarfile.USTAR_FORMAT
    ) as archive:
        for directory in sorted(directories):
            add_directory(archive, directory)
        for relative, data in sorted(files.items()):
            add_file(archive, f"{package}/{relative}", data)

    gzip_buffer = io.BytesIO()
    with gzip.GzipFile(
        filename="",
        mode="wb",
        fileobj=gzip_buffer,
        compresslevel=0,
        mtime=0,
    ) as compressed:
        compressed.write(tar_buffer.getvalue())
    return gzip_buffer.getvalue()


def atomic_write(path: Path, data: bytes) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    descriptor, temporary = tempfile.mkstemp(prefix=f".{path.name}.", dir=path.parent)
    try:
        with os.fdopen(descriptor, "wb") as output:
            output.write(data)
            output.flush()
            os.fsync(output.fileno())
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def main() -> None:
    if len(sys.argv) != 3 or not VERSION_RE.fullmatch(sys.argv[1]):
        fail("usage: build_release.py vMAJOR.MINOR.PATCH OUTPUT_DIR")
    version = sys.argv[1]
    output = Path(sys.argv[2]).resolve()
    root = Path(__file__).resolve().parent.parent
    archive_name = f"safe-vibe-{version}.tar.gz"
    archive_path = output / archive_name
    data = archive_bytes(version, verified_files(root))
    digest = hashlib.sha256(data).hexdigest()
    atomic_write(archive_path, data)
    atomic_write(
        output / f"{archive_name}.sha256",
        f"{digest}  {archive_name}\n".encode("ascii"),
    )
    print(f"{digest}  {archive_path}")


if __name__ == "__main__":
    main()
