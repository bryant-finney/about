#!/usr/bin/env python3
"""Page-count assertion for Chrome-generated PDFs.

Uses the maximum /Count value in the raw PDF bytes. Chrome writes a flat
page tree whose root /Pages node carries the true total, so max() is
correct for Chrome output; other producers (object streams, outlines) may
defeat this heuristic. tests/selftest.sh pins expectations against the
committed PDFs under assets/pdf/ to keep the heuristic honest.
"""

import pathlib
import re
import sys


def page_count(pdf: pathlib.Path) -> int:
    counts = [int(m) for m in re.findall(rb"/Count\s+(\d+)", pdf.read_bytes())]
    if not counts:
        sys.exit(f"check_pages.py: no /Count in {pdf} (not a Chrome-style PDF?)")
    return max(counts)


def main() -> int:
    if len(sys.argv) not in (2, 3):
        print("usage: check_pages.py <pdf> [expected]", file=sys.stderr)
        return 2
    count = page_count(pathlib.Path(sys.argv[1]))
    print(count)
    if len(sys.argv) == 3 and count != int(sys.argv[2]):
        print(f"check_pages.py: expected {sys.argv[2]} pages, got {count}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
