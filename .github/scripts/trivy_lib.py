"""Helpers of the trivy report scripts, standard library only.

The reports read the scan.json of charts/scan-inputs.py, which describes it.
"""

import argparse
import csv
import json
import re
import subprocess
from pathlib import Path


def report_arguments(description):
    """The arguments of a report script: the scan directory, its scan.json,
    the summary file and the URL browsing the repository at the scanned
    commit, if any."""
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("directory", type=Path, metavar="<scan-dir>")
    parser.add_argument("summary", type=Path, metavar="<summary-file>")
    parser.add_argument("blob", nargs="?", default="", metavar="<blob-url>",
                        help="https://github.com/<owner>/<repo>/blob/<sha>; owners link there when set")
    options = parser.parse_args()
    scan = json.loads((options.directory / "scan.json").read_text(encoding="utf-8"))
    return options.directory, scan, options.summary, options.blob


def write_csv(path, header, rows):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as file:
        csv.writer(file, quoting=csv.QUOTE_ALL, lineterminator="\n").writerows([header, *rows])


def append_summary(path, lines):
    with open(path, "a", encoding="utf-8") as file:
        file.write("\n".join(lines) + "\n")


def trivy_version(key="Version"):
    """A line of `trivy --version`, the first with this key, empty when
    unknown."""
    output = subprocess.run(["trivy", "--version"], capture_output=True, encoding="utf-8", check=False).stdout
    found = re.search(rf"^ *{key}: (.*)$", output, re.MULTILINE)
    return found.group(1) if found else ""


def emoji(severity):
    return {
        "CRITICAL": ":red_circle:", "HIGH": ":orange_circle:", "MEDIUM": ":yellow_circle:",
        "LOW": ":large_blue_circle:"}.get(severity, ":white_circle:")


def cell(text):
    """A table cell: no pipe, no tag, no line break."""
    return re.sub(r"[\t\n]", " ", text.replace("|", "\\|").replace("<", "&lt;"))


def owners_cell(owners, blob):
    """Owners as one table cell, a line each: the template of one of our
    charts, or the name and version of a third-party chart, linked to its
    location when <blob> is set, the path of the chart from the release root
    as the link title."""
    lines = []
    for owner in owners:
        text = owner["chart"].replace("@", " ", 1)
        if "/templates/" in owner["location"]:
            text = re.sub(r"^charts/", "", owner["location"]).replace("/templates/", ": ", 1)
        title = owner["path"].replace("/", " > ")
        lines.append(f'[{text}]({blob}/{owner["location"]} "{title}")' if blob else text)
    return "<br>".join(lines)


def not_rendered(scan):
    """The renders that failed, as a summary section: a chart whose bare
    defaults are invalid on purpose is covered by its fixtures."""
    failed = [render for render in scan["renders"] if render["error"] is not None]
    if not failed:
        return []
    return [
        "", "### Not rendered", "", "Left out; bare defaults may be invalid on purpose.", "",
        "| Render | Reason |", "|-|-|",
        *(f"| `{render['render']}` | {cell(render['error'])} |" for render in failed)]
