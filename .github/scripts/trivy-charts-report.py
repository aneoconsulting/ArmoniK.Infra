#!/usr/bin/env python3
"""Turns the trivy config report of linter-helm.yml's chart-checks job into a
job summary and a CSV file. Report-only: findings never fail it.

Reads, under <scan-dir>:
  renders.tsv, documents.tsv  charts/scan-inputs.py
  reports/charts.json         trivy config report of manifests/
Writes the markdown summary to <summary-file> and
<scan-dir>/reports/misconfigurations.csv, every failed check, one row per
document.

A finding is ours when the resource comes from one of our templates, which
we can change, and third-party otherwise, which only the values we pass to
that chart can change.
"""

import json
import sys
from typing import NamedTuple

from trivy_lib import (
    Owner, append_summary, cell, emoji, not_rendered, owners_cell, read_tsv, report_arguments, trivy_version,
    write_csv)


class Document(NamedTuple):
    """A line of documents.tsv: the chart whose template rendered a document."""
    file: str       # <chart>/<case>/<n>.yml
    chart: str
    location: str
    path: str


class Finding(NamedTuple):
    """A failed check on a document: a row of misconfigurations.csv, then the
    alias path of the owner."""
    scope: str      # ours or third-party
    check: str
    severity: str
    title: str
    resolution: str
    owner: str
    location: str
    document: str
    message: str
    url: str
    path: str


# The initials of the severities, the most severe first.
SEVERITIES = "CHMLU"


def one_line(text):
    return (text or "").replace("\t", " ").replace("\n", " ")


def findings(report, documents):
    """Every failed check of a trivy config report with the document it fails
    on, which documents.tsv traces to its template."""
    found = []
    for result in report.get("Results") or []:
        file = result["Target"].rpartition("manifests/")[2]
        document = documents.get(file, Document(file, "", "", ""))
        scope = "ours" if "/templates/" in document.location else "third-party"
        for check in result.get("Misconfigurations") or []:
            if check["Status"] == "FAIL":
                found.append(Finding(
                    scope, one_line(check.get("ID")), one_line(check.get("Severity")), one_line(check.get("Title")),
                    one_line(check.get("Resolution")), document.chart, document.location, file,
                    one_line(check.get("Message")), one_line(check.get("PrimaryURL")), document.path))
    return found


def checks_table(heading, found, blob):
    """One row per failing check, the most severe first, with every template
    (ours) or chart (third-party) it fails on."""
    first = {}
    where = {}  # check -> owner and location -> the owner
    for finding in found:
        first.setdefault(finding.check, finding)
        owner = Owner(finding.owner, finding.location, finding.path)
        where.setdefault(finding.check, {}).setdefault(owner[:2], owner)
    checks = sorted(first.values(), key=lambda finding: (SEVERITIES.find(finding.severity[:1] or "-"), finding.check))
    lines = ["", f"### {heading}: {len(checks)} failing checks", ""]
    if checks:
        lines += ["| | Check | Title | Resolution | Where |", "|-|-|-|-|-|"]
    for finding in checks:
        lines.append(
            f"| {emoji(finding.severity)} | [{finding.check}]({finding.url}) | {cell(finding.title)} "
            f"| {cell(finding.resolution)} | {owners_cell(where[finding.check].values(), blob)} |")
    return lines


def main():
    scan, summary, blob = report_arguments(__doc__.split("\n\n")[0])
    report = scan / "reports" / "charts.json"
    if not report.is_file() or report.stat().st_size == 0:
        print(f"{sys.argv[0]}: {report} is missing or empty", file=sys.stderr)
        return 1
    documents = {document.file: document for document in read_tsv(scan / "documents.tsv", Document)}
    found = findings(json.loads(report.read_text(encoding="utf-8")), documents)

    write_csv(scan / "reports" / "misconfigurations.csv", Finding._fields[:-1], [finding[:-1] for finding in found])
    append_summary(summary, [
        "## Trivy: charts",
        "",
        f"Trivy {trivy_version()[0]}, Kubernetes checks on every render. Report only: no finding fails the job. "
        "Each failing resource is in `misconfigurations.csv` of the `trivy-chart-reports` artifact.",
        *checks_table("Our charts", [finding for finding in found if finding.scope == "ours"], blob),
        *checks_table("Third-party charts", [finding for finding in found if finding.scope != "ours"], blob),
        *not_rendered(scan)])
    return 0


if __name__ == "__main__":
    sys.exit(main())
