"""Helpers of the trivy report scripts, standard library only.

The reports read the files of charts/scan-inputs.py, whose head comment
describes them.
"""

import argparse
import csv
import re
import subprocess
from pathlib import Path
from typing import NamedTuple


class Render(NamedTuple):
    """A line of renders.tsv."""
    chart: str
    case: str
    status: str     # ok or failed
    reason: str     # first error line of a failed render


class Owner(NamedTuple):
    """The chart holding an image or rendering a document."""
    chart: str      # <name>@<version>
    location: str   # path in this repository, of a template or of a Chart.yaml line
    path: str       # alias path of the chart from the release root

    @classmethod
    def parse(cls, text):
        """The owners of an images.tsv line: <chart>=<location>=<path>,
        comma-separated."""
        return [cls(*entry.split("=")) for entry in text.split(",")]


def report_arguments(description):
    """The arguments of a report script: the scan directory, the summary file
    and the URL browsing the repository at the scanned commit, if any."""
    parser = argparse.ArgumentParser(description=description)
    parser.add_argument("scan", type=Path, metavar="<scan-dir>")
    parser.add_argument("summary", type=Path, metavar="<summary-file>")
    parser.add_argument("blob", nargs="?", default="", metavar="<blob-url>",
                        help="https://github.com/<owner>/<repo>/blob/<sha>; owners link there when set")
    options = parser.parse_args()
    (options.scan / "reports").mkdir(parents=True, exist_ok=True)
    return options.scan, options.summary, options.blob


def read_tsv(path, row):
    """The lines of a tab-separated file as named tuples, a missing trailing
    field being empty."""
    with open(path, encoding="utf-8", errors="surrogateescape") as file:
        lines = [line.rstrip("\n").split("\t") for line in file]
    return [row(*fields, *[""] * (len(row._fields) - len(fields))) for fields in lines]


def write_csv(path, header, rows):
    with open(path, "w", newline="", encoding="utf-8", errors="surrogateescape") as file:
        writer = csv.writer(file, quoting=csv.QUOTE_ALL, lineterminator="\n")
        writer.writerow(header)
        writer.writerows(rows)


def append_summary(path, lines):
    with open(path, "a", encoding="utf-8", errors="surrogateescape") as file:
        file.write("\n".join(lines) + "\n")


def trivy_version():
    """The version of trivy and the date of its vulnerability database, empty
    when unknown."""
    try:
        output = subprocess.run(["trivy", "--version"], capture_output=True, encoding="utf-8", check=False).stdout
    except OSError:
        output = ""
    version = re.search(r"^Version: (.*)$", output, re.MULTILINE)
    updated = re.search(r"^ *UpdatedAt: (.*)$", output, re.MULTILINE)
    return (version.group(1) if version else "", updated.group(1) if updated else "")


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
        text = owner.chart.replace("@", " ", 1)
        if "/templates/" in owner.location:
            text = re.sub(r"^charts/", "", owner.location).replace("/templates/", ": ", 1)
        title = owner.path.replace("/", " > ")
        lines.append(f'[{text}]({blob}/{owner.location} "{title}")' if blob else text)
    return "<br>".join(lines)


def not_rendered(scan):
    """The renders that failed, as a summary section: a chart whose bare
    defaults are invalid on purpose is covered by its fixtures."""
    failed = [render for render in read_tsv(scan / "renders.tsv", Render) if render.status == "failed"]
    if not failed:
        return []
    return [
        "", "### Not rendered", "", "Left out; bare defaults may be invalid on purpose.", "",
        "| Render | Reason |", "|-|-|",
        *(f"| `{render.chart}/{render.case}` | {cell(render.reason)} |" for render in failed)]
