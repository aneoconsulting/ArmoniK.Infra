#!/usr/bin/env python3
"""Turns the trivy config report of linter-helm.yml's chart-checks job into a
job summary and a CSV file. Report-only: findings never fail it.

Reads <scan-dir>/scan.json (charts/scan-inputs.py) and
<scan-dir>/reports/charts.json, the trivy config report of manifests/.
Appends the markdown summary to <summary-file> and writes
<scan-dir>/reports/misconfigurations.csv, every failed check, one row per
document.

A finding is ours when the resource comes from one of our templates, which
we can change, and third-party otherwise, which only the values we pass to
that chart can change.
"""

import json
from typing import NamedTuple

from trivy_lib import append_summary, cell, emoji, not_rendered, owners_cell, report_arguments, trivy_version, write_csv


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


def findings(report, scan):
    """Every failed check of a trivy config report with the document it fails
    on, which scan.json traces to its template."""
    documents = {f"{document['render']}/{document['index']}.yml": document for document in scan["documents"]}
    for result in report.get("Results") or []:
        file = result["Target"].rpartition("manifests/")[2]
        document = documents.get(file)
        if document is None:
            print(f"::warning title=Not a rendered document::trivy checked {result['Target']}, left out of the report")
            continue
        scope = "ours" if "/templates/" in document["location"] else "third-party"
        for check in result.get("Misconfigurations") or []:
            if check["Status"] == "FAIL":
                keys = ("ID", "Severity", "Title", "Resolution", "Message", "PrimaryURL")
                check_id, severity, title, resolution, message, url = [
                    (check.get(key) or "").replace("\t", " ").replace("\n", " ") for key in keys]
                yield Finding(scope, check_id, severity, title, resolution, document["owner"], document["location"],
                              file, message, url, document["path"])


def checks_table(heading, found, blob):
    """One row per failing check, the most severe first, with every template
    (ours) or chart (third-party) it fails on."""
    first = {}
    where = {}  # check -> owner and location -> the owner
    for finding in found:
        first.setdefault(finding.check, finding)
        owner = {"chart": finding.owner, "location": finding.location, "path": finding.path}
        where.setdefault(finding.check, {}).setdefault((finding.owner, finding.location), owner)
    # By the initial of the severity: critical, high, medium, low, unknown.
    checks = sorted(first.values(), key=lambda finding: ("CHMLU".find(finding.severity[:1] or "-"), finding.check))
    lines = ["", f"### {heading}: {len(checks)} failing checks", ""]
    if checks:
        lines += ["| | Check | Title | Resolution | Where |", "|-|-|-|-|-|"]
    for finding in checks:
        lines.append(
            f"| {emoji(finding.severity)} | [{finding.check}]({finding.url}) | {cell(finding.title)} "
            f"| {cell(finding.resolution)} | {owners_cell(where[finding.check].values(), blob)} |")
    return lines


def main():
    directory, scan, summary, blob = report_arguments(__doc__.split("\n\n")[0])
    report = json.loads((directory / "reports" / "charts.json").read_text(encoding="utf-8"))
    found = list(findings(report, scan))
    rows = [finding[:-1] for finding in found]
    write_csv(directory / "reports" / "misconfigurations.csv", Finding._fields[:-1], rows)
    append_summary(summary, [
        "## Trivy: charts",
        "",
        f"Trivy {trivy_version()}, Kubernetes checks on every render. Report only: no finding fails the job. "
        "Each failing resource is in `misconfigurations.csv` of the `trivy-chart-reports` artifact.",
        *checks_table("Our charts", [finding for finding in found if finding.scope == "ours"], blob),
        *checks_table("Third-party charts", [finding for finding in found if finding.scope != "ours"], blob),
        *not_rendered(scan)])


if __name__ == "__main__":
    main()
