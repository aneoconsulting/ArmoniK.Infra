#! /usr/bin/env python3

import sys
import re

FORBIDDEN = re.compile(
    r"<!-- BEGIN_TF_DOCS -->\n.*\n<!-- END_TF_DOCS -->",
    re.DOTALL
)
REPLACE = "<!-- BEGIN_TF_DOCS -->\n<!-- END_TF_DOCS -->"

def main(argv=None):
    argv = argv or sys.argv
    failed = []
    for filename in argv[1:]:
        with open(filename, "r+", encoding="utf-8") as f:
            content = f.read()
            content, n = FORBIDDEN.subn(REPLACE, content)
            if n > 0:
                f.seek(0)
                f.write(content)
                f.truncate()
                print(f"Removed generated docs in {filename}")
                failed.append(filename)
    return failed

if __name__ == "__main__":
    if main():
        sys.exit(1)
