#!/usr/bin/env python3
"""Turns the trivy image reports of publish.yml's scan job into a job summary,
a SARIF file for code scanning and a CSV file. Report-only: findings never
fail it.

Reads, under <scan-dir>:
  renders.tsv, images.tsv   charts/scan-inputs.py
  switches.tsv              charts/scan-inputs.py -s <umbrella chart>; without
                            it the report has no deployment tag
  image-status.tsv          .github/scripts/trivy-images.sh
  reports/images/<n>.json   trivy image report of images.tsv line <n>
Writes the markdown summary to <summary-file>, a warning annotation to
stdout when an image was not scanned, and under <scan-dir>:
  sarif/images.sarif
  reports/vulnerabilities.csv   every vulnerability, one row per image and
                                affected package

SARIF_SEVERITY (default HIGH,CRITICAL) filters the SARIF file only, which
code scanning rejects past 25,000 results: the CSV file keeps every
severity.
"""

import json
import os
import re
import subprocess
import sys
import tempfile
from dataclasses import dataclass, field
from pathlib import Path
from typing import NamedTuple

from trivy_lib import (
    Owner, append_summary, cell, emoji, not_rendered, owners_cell, read_tsv, report_arguments, trivy_version,
    write_csv)

# The rows of an image's critical and high vulnerabilities in the summary,
# which GitHub drops whole past 1 MiB.
CAP = 30

# The severities of the summary's columns, unknown folded into low.
COLUMNS = {"CRITICAL": ["CRITICAL"], "HIGH": ["HIGH"], "MEDIUM": ["MEDIUM"], "LOW": ["LOW", "UNKNOWN"]}


class ImageRow(NamedTuple):
    """A line of images.tsv."""
    image: str
    uses: str       # comma-separated: <chart>/<case>[/test] or `operator`
    owners: str


class StatusRow(NamedTuple):
    """A line of image-status.tsv."""
    image: str
    status: str     # ok, not-found, denied, rate-limited or error
    reason: str


class SwitchRow(NamedTuple):
    """A line of switches.tsv."""
    chart: str
    image: str
    default: str    # on or off
    off_with: str   # the values removing the image, ` | `-separated
    on_with: str    # the values deploying it


class Vulnerability(NamedTuple):
    """A vulnerability of a package of an image."""
    id: str
    package: str
    path: str
    installed: str
    fixed: str
    status: str
    severity: str
    title: str
    url: str


@dataclass
class Image:
    """An image of the charts, from the umbrella chart's point of view."""
    number: int             # its line in images.tsv
    name: str
    owners: list
    helm_test: bool         # only helm test pods run it
    deployed: str           # always, opt-out, opt-in, or empty when unknown
    removed_by: str         # opt-out: the values removing it
    deployed_with: str      # opt-in: what deploys it
    status: str
    reason: str
    vulnerabilities: list = field(default_factory=list)

    @property
    def label(self):
        """The image with its tags, the deployment tag showing the values
        switching the image when hovered."""
        label = f"<code>{self.name}</code>"
        if self.helm_test:
            label += " <sub>helm test</sub>"
        if self.deployed in ("opt-out", "opt-in"):
            hover = f"Removed by {self.removed_by}" if self.deployed == "opt-out" else (
                f"Deployed with {self.deployed_with or '-'}")
            label += f' <sub title="{attribute(hover.replace(" | ", " or "))}">{self.deployed}</sub>'
        return label

    def count(self, column, fixable=False):
        """The vulnerabilities of a summary column, or the fixable ones."""
        return sum(
            1 for vulnerability in self.vulnerabilities
            if vulnerability.severity in COLUMNS[column] and (vulnerability.fixed or not fixable))


def attribute(text):
    """A title attribute inside a table cell."""
    return text.replace("&", "&amp;").replace('"', "&quot;").replace("<", "&lt;").replace("|", "&#124;")


def values_list(alternatives):
    """The values switching an image, settings as code and prose as it is."""
    if not alternatives:
        return "-"
    if "=" not in alternatives and not alternatives.startswith("ci/"):
        return alternatives
    return "`" + cell(alternatives).replace(" \\| ", "` or `").replace(" & ", "` & `") + "`"


def deployment(row, switch):
    """Whether the umbrella chart deploys an image always, by default
    (opt-out, a value removing it) or on request (opt-in: a value, or a request
    to an operator), as <deployed> <removed by> <deployed with>."""
    if switch and switch.default == "on":
        return ("opt-out" if switch.off_with else "always"), switch.off_with, ""
    if switch and switch.default == "off":
        return "opt-in", "", switch.on_with
    if row.uses == "operator":
        return "opt-in", "", "a resource having its operator run it, see charts/operator-images.yaml"
    return "", "", ""


def load_images(scan):
    """Every image of images.tsv with its scan status and its deployment."""
    rows = read_tsv(scan / "images.tsv", ImageRow)
    statuses = read_tsv(scan / "image-status.tsv", StatusRow)
    switches = {}
    if (scan / "switches.tsv").is_file():
        switches = {switch.image: switch for switch in read_tsv(scan / "switches.tsv", SwitchRow)}
    images = []
    for number, row in enumerate(rows, 1):
        if number > len(statuses) or statuses[number - 1].image != row.image:
            sys.exit(f"images.tsv and image-status.tsv disagree on line {number}")
        status = statuses[number - 1]
        helm_test = all(use.endswith("/test") for use in row.uses.split(","))
        images.append(Image(
            number, row.image, Owner.parse(row.owners), helm_test, *deployment(row, switches.get(row.image)),
            status.status, status.reason))
    return images


def load_vulnerabilities(report):
    """One entry per vulnerability and affected package of a trivy image
    report, the most severe first, then the fixable: trivy repeats a package
    found in several layers."""
    unique = {}
    for result in report.get("Results") or []:
        for found in result.get("Vulnerabilities") or []:
            vulnerability = Vulnerability(
                found.get("VulnerabilityID") or "", found.get("PkgName") or "", found.get("PkgPath") or "",
                found.get("InstalledVersion") or "", found.get("FixedVersion") or "", found.get("Status") or "",
                found.get("Severity") or "UNKNOWN", found.get("Title") or "", found.get("PrimaryURL") or "")
            unique.setdefault(vulnerability[:4], vulnerability)
    ranks = {"CRITICAL": 0, "HIGH": 1, "MEDIUM": 2, "LOW": 3}
    return sorted(unique.values(), key=lambda v: (ranks.get(v.severity, 4), not v.fixed, *v[:4]))


def csv_rows(image):
    names = "; ".join(owner.chart.replace("@", " ", 1) for owner in image.owners)
    for vulnerability in image.vulnerabilities:
        yield (image.name, names, image.deployed, image.removed_by, image.deployed_with, vulnerability.severity,
               vulnerability.id, vulnerability.package, *vulnerability[2:6], vulnerability.title, vulnerability.url)


def sarif_runs(image, report, work):
    """The SARIF runs of an image. Every location is rewritten to name its
    image: trivy locates an OS package at the image repository, without its
    registry, and any other package at its path inside the image, which
    collides between images once merged. The tag is left out so an alert
    survives an image bump."""
    converted = work / f"{image.number}.sarif"
    subprocess.run([
        "trivy", "convert", "--quiet", "--format", "sarif",
        "--severity", os.environ.get("SARIF_SEVERITY") or "HIGH,CRITICAL",
        "--output", str(converted), str(report)], check=True)
    runs = json.loads(converted.read_text(encoding="utf-8"))["runs"]
    prefix = re.sub(r":[^:/]*$", "", image.name.partition("@")[0])
    repository = re.sub(r"^[^/]*[.:][^/]*/", "", prefix)
    for run in runs:
        for result in run.get("results") or []:
            for location in result.get("locations") or []:
                artifact = location["physicalLocation"]["artifactLocation"]
                if artifact["uri"] in (repository, "library/" + repository):
                    artifact["uri"] = prefix
                else:
                    artifact["uri"] = f"{prefix}/{artifact['uri']}"
    return runs


def merge_sarif(runs):
    """Code scanning rejects two runs of one tool under one category, so the
    runs are merged into one: rules deduplicated by id, ruleIndex dropped
    since it pointed into each run's own rules array. With no image scanned,
    an empty run still clears the alerts no longer found."""
    trivy = {"tool": {"driver": {"name": "Trivy", "informationUri": "https://github.com/aquasecurity/trivy"}}}
    merged = dict(runs[0] if runs else trivy)
    merged.pop("properties", None)
    rules = {}
    results = []
    for run in runs:
        for rule in run["tool"]["driver"].get("rules") or []:
            rules.setdefault(rule["id"], rule)
        for result in run.get("results") or []:
            result.pop("ruleIndex", None)
            results.append(result)
    merged["tool"]["driver"]["rules"] = [rules[rule] for rule in sorted(rules)]
    merged["results"] = results
    return {"$schema": "https://json.schemastore.org/sarif-2.1.0.json", "version": "2.1.0", "runs": [merged]}


def images_table(scanned, blob):
    def count(image, column):
        found = image.count(column)
        return f"{emoji(column)} {found} ({image.count(column, fixable=True)})" if found else "-"

    lines = ["| Image | Owner | Critical | High | Medium | Low |", "|-|-|-:|-:|-:|-:|"]
    for image in scanned:
        counts = " | ".join(count(image, column) for column in COLUMNS)
        lines.append(f"| {image.label} | {owners_cell(image.owners, blob)} | {counts} |")
    return lines


def not_scanned(failed, blob):
    if not failed:
        return []
    lines = [
        "", "### Not scanned", "",
        "Docker Hub answers a repository that does not exist as it does a private one: "
        "a missing Docker Hub image reads as denied.",
        "", "| Image | Owner | Failure | Reason |", "|-|-|-|-|"]
    for image in failed:
        lines.append(f"| {image.label} | {owners_cell(image.owners, blob)} | :x: {image.status} "
                     f"| {cell(image.reason or 'no report')} |")
    return lines


def vulnerabilities_details(image):
    """The critical and high vulnerabilities of an image, folded, under the
    values switching the image."""
    rows = []
    for v in image.vulnerabilities:
        row = (f"| {emoji(v.severity)} | [{v.id}]({v.url}) | `{cell(v.package)}` | {cell(v.installed)} "
               f"| {cell(v.fixed) or '-'} | {cell(v.title)} |")
        # One row for the copies of a package that differ by their path only.
        if v.severity in ("CRITICAL", "HIGH") and row not in rows[-1:]:
            rows.append(row)
    critical, high = image.count("CRITICAL"), image.count("HIGH")
    deployed = {
        "always": ["Always deployed.", ""],
        "opt-out": [f"Deployed by default, removed by {values_list(image.removed_by)}.", ""],
        "opt-in": [f"Deployed with {values_list(image.deployed_with)}.", ""]}
    lines = [
        f"<details><summary>{emoji('CRITICAL' if critical else 'HIGH')} {image.label}: "
        f"{critical} critical ({image.count('CRITICAL', fixable=True)} fixable), "
        f"{high} high ({image.count('HIGH', fixable=True)} fixable)</summary>",
        "", *deployed.get(image.deployed, []),
        "| | Vulnerability | Package | Installed | Fixed | Title |", "|-|-|-|-|-|-|", *rows[:CAP]]
    if len(rows) > CAP:
        lines.append(f"| | ... and {len(rows) - CAP} more in `vulnerabilities.csv` | | | | |")
    return lines + ["", "</details>", ""]


def what_deploys(images, chart):
    """Every image, scanned or not, with the values switching it."""
    lines = [
        "<details><summary>What deploys each image</summary>", "",
        f"Measured on the renders of `{chart}`, one change at a time: "
        "each `enabled` or `deploy` default turned off, each default partition set to null, "
        "each setting of a `ci/*-values.yaml` fixture applied alone or dropped from it. "
        "Settings joined by `&` are needed together; a fixture file stands for all its settings, "
        "when none could be tied to the image. "
        "The control and compute planes count as always deployed, in this release or in their own.",
        "", "| Image | Removed by | Deployed with |", "|-|-|-|"]
    for image in images:
        lines.append(f"| {image.label} | {values_list(image.removed_by)} | {values_list(image.deployed_with)} |")
    return lines + ["", "</details>"]


def headline(scanned, failed):
    tags = [("test" if image.helm_test else image.deployed) for image in scanned]
    critical = sum(1 for image in scanned if image.count("CRITICAL"))
    high = sum(1 for image in scanned if image.count("HIGH"))
    return (
        f"**{len(scanned)} images scanned** ({tags.count('always')} always deployed, {tags.count('opt-out')} opt-out, "
        f"{tags.count('opt-in')} opt-in, {tags.count('test')} only for helm tests): "
        f":red_circle: {critical} with critical vulnerabilities, :orange_circle: {high} with high ones"
        + (f"; :x: {len(failed)} not scanned." if failed else "."))


def main():
    scan, summary, blob = report_arguments(__doc__.split("\n\n")[0])
    images = load_images(scan)
    scanned, failed, runs = [], [], []
    with tempfile.TemporaryDirectory() as work:
        for image in images:
            report = scan / "reports" / "images" / f"{image.number}.json"
            if image.status != "ok" or not report.is_file() or report.stat().st_size == 0:
                failed.append(image)
                continue
            image.vulnerabilities = load_vulnerabilities(json.loads(report.read_text(encoding="utf-8")))
            scanned.append(image)
            runs += sarif_runs(image, report, Path(work))

    write_csv(
        scan / "reports" / "vulnerabilities.csv",
        ("image", "owners", "deployed", "off with", "on with", "severity", "vulnerability", "package", "path",
         "installed", "fixed", "status", "title", "url"),
        [row for image in scanned for row in csv_rows(image)])
    (scan / "sarif").mkdir(exist_ok=True)
    with open(scan / "sarif" / "images.sarif", "w", encoding="utf-8") as file:
        json.dump(merge_sarif(runs), file, indent=2, ensure_ascii=False)
        file.write("\n")
    if failed:
        print(f"::warning title={len(failed)} images not scanned::see the job summary")

    # The most vulnerable first.
    scanned.sort(key=lambda image: (*(-image.count(column) for column in COLUMNS), image.label))
    version, database = trivy_version()
    lines = [
        "## Trivy: images",
        "",
        f"Trivy {version}, vulnerability database of {database}. Report only: nothing here blocks a publication.",
        "",
        headline(scanned, failed),
        "",
        "Counts: found (fixable), low including unknown. "
        "Every vulnerability is in `vulnerabilities.csv` of the `trivy-reports` artifact.",
        "",
        "No tag: always deployed. <sub>opt-out</sub>: deployed by default. <sub>opt-in</sub>: deployed on request. "
        "<sub>helm test</sub>: run by `helm test` only. Hover a tag for the values that switch it.",
        "",
        *images_table(scanned, blob),
        *not_scanned(failed, blob),
        "", "### Critical and high vulnerabilities", "",
        f"The most severe first, then the fixable, at most {CAP} an image: the rest is in `vulnerabilities.csv`.",
        ""]
    for image in scanned:
        if image.count("CRITICAL") or image.count("HIGH"):
            lines += vulnerabilities_details(image)
    switches = scan / "switches.tsv"
    if switches.is_file():
        lines += what_deploys(images, switches.read_text(encoding="utf-8").partition("\t")[0])
    append_summary(summary, lines + not_rendered(scan))
    return 0


if __name__ == "__main__":
    sys.exit(main())
