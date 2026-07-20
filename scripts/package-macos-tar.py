from __future__ import annotations

import os
import sys
import tarfile
from pathlib import Path


EXECUTABLE_SUFFIXES = {".command", ".sh"}


def file_mode(path: Path) -> int:
    parts = set(path.parts)
    if path.name == "WuZiLauncher" and "MacOS" in parts:
        return 0o755
    if path.suffix in EXECUTABLE_SUFFIXES:
        return 0o755
    return 0o644


def add_path(tar: tarfile.TarFile, source: Path, arcname: str) -> None:
    if source.is_dir():
        info = tarfile.TarInfo(arcname.rstrip("/") + "/")
        info.type = tarfile.DIRTYPE
        info.mode = 0o755
        info.mtime = int(source.stat().st_mtime)
        tar.addfile(info)
        for child in sorted(source.iterdir(), key=lambda p: p.name):
            child_arcname = f"{arcname.rstrip('/')}/{child.name}"
            add_path(tar, child, child_arcname)
        return

    info = tar.gettarinfo(str(source), arcname)
    info.mode = file_mode(source)
    with source.open("rb") as stream:
        tar.addfile(info, stream)


def main() -> int:
    if len(sys.argv) != 3:
        print("Usage: package-macos-tar.py <source_dir> <output_tar_gz>", file=sys.stderr)
        return 1

    source_dir = Path(sys.argv[1]).resolve()
    output_tar = Path(sys.argv[2]).resolve()

    if not source_dir.is_dir():
        print(f"Source directory not found: {source_dir}", file=sys.stderr)
        return 1

    output_tar.parent.mkdir(parents=True, exist_ok=True)
    root_name = source_dir.name

    with tarfile.open(output_tar, "w:gz", format=tarfile.PAX_FORMAT) as tar:
        add_path(tar, source_dir, root_name)

    print(f"Created {output_tar}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
