#!/usr/bin/env python3
"""List the resource paths packed into a Godot export.

Usage: pck_paths.py <exe-or-pck>

Godot stores the pack directory as UTF-8 `res://` paths followed by binary
offset/size records. Parsing the directory structurally depends on the pack
format version, so this tool scans the whole file for printable `res://...`
strings and de-duplicates them. That is enough for the hygiene question it
answers (which trees are inside the shipped package), and it cannot silently
miss a packed directory the way a file-size check can.

Exit status is 0 when at least one path is found.
"""

import re
import sys

# Directory entries are plain UTF-8 paths; the engine binary also contains
# fragments like `res://")`, so only a path with a file extension is reported.
PATH_RE = re.compile(
    rb"(?:res://|content/|assets/)[A-Za-z0-9_./-]{1,180}\.[A-Za-z0-9]{1,8}"
)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: pck_paths.py <exe-or-pck>", file=sys.stderr)
        return 2
    with open(sys.argv[1], "rb") as handle:
        data = handle.read()
    seen: set[str] = set()
    ordered: list[str] = []
    for match in PATH_RE.finditer(data):
        text = match.group(0).decode("utf-8", "replace").rstrip("\x00").rstrip(".")
        if text in seen:
            continue
        seen.add(text)
        ordered.append(text)
    for path in ordered:
        print(path)
    return 0 if ordered else 1


if __name__ == "__main__":
    raise SystemExit(main())
