#!/usr/bin/env python3
"""Copy the shared libraries that the given ELF files need into a folder.

    bundle_libs.py LIB_DIR SYSTEM_REGEX ELF...

Walks the direct dependencies (DT_NEEDED) from each file. A library whose soname
matches SYSTEM_REGEX is left to the user's system, and so are its own
dependencies: the walk does not go into it. Other libraries are copied into
LIB_DIR under their soname and walked in turn. Libraries are located with ldd,
so LD_LIBRARY_PATH may point at extra library folders.
"""
import re
import shutil
import subprocess
import sys
from pathlib import Path


def needed(path):
    out = subprocess.run(["readelf", "-d", str(path)], capture_output=True, text=True, check=True).stdout
    return re.findall(r"\(NEEDED\)\s+Shared library: \[([^\]]+)\]", out)


def locations(path):
    out = subprocess.run(["ldd", str(path)], capture_output=True, text=True).stdout
    found = {}
    for line in out.splitlines():
        match = re.match(r"\s*(\S+) => (/\S+)", line)
        if match:
            found[match.group(1)] = match.group(2)
    return found


def main():
    lib_dir, system = Path(sys.argv[1]), re.compile(sys.argv[2])
    pending = [Path(p) for p in sys.argv[3:]]
    seen, missing = set(), set()
    while pending:
        path = pending.pop()
        where = locations(path)
        for soname in needed(path):
            if system.match(soname) or soname in seen:
                continue
            seen.add(soname)
            target = lib_dir / soname
            if not target.exists():
                if soname not in where:
                    missing.add(f"{soname} (needed by {path.name})")
                    continue
                shutil.copy2(Path(where[soname]).resolve(), target)
            pending.append(target)
    if missing:
        sys.exit("Unresolved libraries:\n  " + "\n  ".join(sorted(missing)))
    print(f"Bundled {len(seen)} libraries")


if __name__ == "__main__":
    main()
