#!/usr/bin/env python3
"""Turns the trivy image reports of publish.yml's scan job into a job summary,
a SARIF file for code scanning and a CSV file. Report-only: findings never
fail it.

Reads, under <scan-dir>: scan.json (charts/scan-inputs.py, whose -s gives the
deployment tags), image-status.json and reports/images/ (trivy-images.py).
Appends the markdown summary to <summary-file>, prints a warning annotation
when an image was not scanned, and writes, under <scan-dir>:
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
import tempfile
from dataclasses import dataclass
from typing import NamedTuple

from trivy_lib import append_summary, cell, emoji, not_rendered, owners_cell, report_arguments, trivy_version, write_csv

# The rows of an image's critical and high vulnerabilities in the summary,
# which GitHub drops whole past 1 MiB.
CAP = 30

# The severities of the summary's columns, unknown folded into low.
COLUMNS = {"CRITICAL": ["CRITICAL"], "HIGH": ["HIGH"], "MEDIUM": ["MEDIUM"], "LOW": ["LOW", "UNKNOWN"]}

# The color of each tag (GitHub's purple, teal, grey), off the severities'
# red, orange, yellow and blue.
TAGS = {"opt-out": "8250df", "opt-in": "0e8a8a", "test": "lightgrey"}


def badge(tag, hover=""):
    """A tag as a shields.io badge centered on its line, GitHub stripping the
    styles that would color text; its alt text stands in when the image does
    not load. The hover text is a title attribute inside a table cell."""
    for character, entity in {"&": "&amp;", '"': "&quot;", "<": "&lt;", "|": "&#124;"}.items():
        hover = hover.replace(character, entity)
    title = f' title="{hover}"' if hover else ""
    src = f"https://img.shields.io/badge/{tag.replace('-', '--')}-{TAGS[tag]}"
    return f'<img src="{src}" alt="{tag}" align="absmiddle"{title}>'


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
    """An image of scan.json with its scan status, from the point of view of
    the umbrella chart, whose switches scan.json holds."""
    number: int             # reports/images/<number>.json
    image: str
    uses: list
    owners: list
    status: str             # ok, or why it was not scanned
    reason: str
    default: str = ""       # on or off, empty when not measured
    off_with: str = ""      # the values removing it
    on_with: str = ""       # what deploys it
    vulnerabilities: tuple = ()

    @property
    def deployed(self):
        """Whether the umbrella deploys the image always, by default
        (opt-out) or on request (opt-in: a value, or a request to an
        operator); empty when unknown."""
        if self.default == "on":
            return "opt-out" if self.off_with else "always"
        return "opt-in" if self.default == "off" or self.on_with else ""

    @property
    def helm_test(self):
        return all(use.endswith("/test") for use in self.uses)

    @property
    def label(self):
        """The image with its tags, the deployment tag showing the values
        switching the image when hovered."""
        label = f"<code>{self.image}</code>"
        if self.helm_test:
            label += " " + badge("test")
        if self.deployed in ("opt-out", "opt-in"):
            hover = f"Removed by {self.off_with}" if self.off_with else f"Deployed with {self.on_with or '-'}"
            label += " " + badge(self.deployed, hover.replace(" | ", " or "))
        return label

    def count(self, column, fixable=False):
        """The vulnerabilities of a summary column, or the fixable ones."""
        return sum(
            1 for vulnerability in self.vulnerabilities
            if vulnerability.severity in COLUMNS[column] and (vulnerability.fixed or not fixable))


def load_images(directory, scan):
    """Every image of scan.json with its scan status. An operator's own
    image is deployed on request to the operator."""
    statuses = json.loads((directory / "image-status.json").read_text(encoding="utf-8"))
    images = [Image(number, **image, **statuses[image["image"]]) for number, image in enumerate(scan["images"], 1)]
    for image in images:
        if not image.default and image.uses == ["operator"]:
            image.on_with = "a resource having its operator run it, see charts/operator-images.yaml"
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
    return sorted(unique.values(), key=lambda found: (ranks.get(found.severity, 4), not found.fixed, *found[:4]))


def sarif_runs(image, report, work):
    """The SARIF runs of an image. Every location is rewritten to name its
    image: trivy locates an OS package at the image repository, without its
    registry, and any other package at its path inside the image, which
    collides between images once merged. The tag is left out so an alert
    survives an image bump."""
    converted = os.path.join(work, f"{image.number}.sarif")
    subprocess.run([
        "trivy", "convert", "--quiet", "--format", "sarif",
        "--severity", os.environ.get("SARIF_SEVERITY") or "HIGH,CRITICAL", "--output", converted, report], check=True)
    with open(converted, encoding="utf-8") as file:
        runs = json.load(file)["runs"]
    prefix = re.sub(r":[^:/]*$", "", image.image.partition("@")[0])
    repository = re.sub(r"^[^/]*[.:][^/]*/", "", prefix)
    for run in runs:
        for result in run.get("results") or []:
            result.pop("ruleIndex", None)  # it points into the rules of this run
            for location in result.get("locations") or []:
                artifact = location["physicalLocation"]["artifactLocation"]
                is_repository = artifact["uri"] in (repository, "library/" + repository)
                artifact["uri"] = prefix if is_repository else f"{prefix}/{artifact['uri']}"
    return runs


def merge_sarif(runs):
    """Code scanning rejects two runs of one tool under one category, so the
    runs are merged into one, rules deduplicated by id. With no image
    scanned, an empty run still clears the alerts no longer found."""
    trivy = {"tool": {"driver": {"name": "Trivy", "informationUri": "https://github.com/aquasecurity/trivy"}}}
    merged = runs[0] if runs else trivy
    merged.pop("properties", None)
    rules = {}
    for run in runs:
        for rule in run["tool"]["driver"].get("rules") or []:
            rules.setdefault(rule["id"], rule)
    results = [result for run in runs for result in run.get("results") or []]
    merged["tool"]["driver"]["rules"] = [rules[rule] for rule in sorted(rules)]
    merged["results"] = results
    return {"$schema": "https://json.schemastore.org/sarif-2.1.0.json", "version": "2.1.0", "runs": [merged]}


def values_list(alternatives):
    """The values switching an image, settings as code and prose as it is."""
    if "=" not in alternatives and not alternatives.startswith("ci/"):
        return alternatives or "-"
    return "`" + cell(alternatives).replace(" \\| ", "` or `").replace(" & ", "` & `") + "`"


def images_table(scanned, failed, blob):
    """A row per scanned image, the most vulnerable first, then the images
    that were not scanned."""
    tags = [("test" if image.helm_test else image.deployed) for image in scanned]
    lines = [
        f"**{len(scanned)} images scanned** ({tags.count('always')} always deployed, {tags.count('opt-out')} opt-out, "
        f"{tags.count('opt-in')} opt-in, {tags.count('test')} only for helm tests): "
        f":red_circle: {sum(1 for image in scanned if image.count('CRITICAL'))} with critical vulnerabilities, "
        f":orange_circle: {sum(1 for image in scanned if image.count('HIGH'))} with high ones"
        + (f"; :x: {len(failed)} not scanned." if failed else "."),
        "",
        "Counts: found (fixable), low including unknown. "
        "Every vulnerability is in `vulnerabilities.csv` of the `trivy-reports` artifact.",
        "",
        f"No tag: always deployed. {badge('opt-out')} deployed by default. {badge('opt-in')} deployed on request. "
        f"{badge('test')} run by `helm test` only. Hover a tag for the values that switch it.",
        "",
        "| Image | Owner | Critical | High | Medium | Low |", "|-|-|-:|-:|-:|-:|"]
    for image in scanned:
        counts = [
            f"{emoji(column)} {image.count(column)} ({image.count(column, fixable=True)})" if image.count(column)
            else "-" for column in COLUMNS]
        lines.append(f"| {image.label} | {owners_cell(image.owners, blob, template_in_title=True)} | {' | '.join(counts)} |")
    if failed:
        lines += [
            "", "### Not scanned", "",
            "Docker Hub answers a repository that does not exist as it does a private one: "
            "a missing Docker Hub image reads as denied.",
            "", "| Image | Owner | Failure | Reason |", "|-|-|-|-|"]
    for image in failed:
        lines.append(f"| {image.label} | {owners_cell(image.owners, blob, template_in_title=True)} | :x: {image.status} "
                     f"| {cell(image.reason or 'no report')} |")
    return lines


def vulnerabilities_details(image):
    """The critical and high vulnerabilities of an image, folded, under the
    values switching the image."""
    rows = []
    for found in image.vulnerabilities:
        row = (f"| {emoji(found.severity)} | [{found.id}]({found.url}) | `{cell(found.package)}` "
               f"| {cell(found.installed)} | {cell(found.fixed) or '-'} | {cell(found.title)} |")
        # One row for the copies of a package that differ by their path only.
        if found.severity in ("CRITICAL", "HIGH") and row not in rows[-1:]:
            rows.append(row)
    if len(rows) > CAP:
        rows[CAP:] = [f"| | ... and {len(rows) - CAP} more in `vulnerabilities.csv` | | | | |"]
    critical, high = image.count("CRITICAL"), image.count("HIGH")
    deployed = {
        "always": ["Always deployed.", ""],
        "opt-out": [f"Deployed by default, removed by {values_list(image.off_with)}.", ""],
        "opt-in": [f"Deployed with {values_list(image.on_with)}.", ""]}
    return [
        f"<details><summary>{emoji('CRITICAL' if critical else 'HIGH')} {image.label}: "
        f"{critical} critical ({image.count('CRITICAL', fixable=True)} fixable), "
        f"{high} high ({image.count('HIGH', fixable=True)} fixable)</summary>",
        "", *deployed.get(image.deployed, []),
        "| | Vulnerability | Package | Installed | Fixed | Title |", "|-|-|-|-|-|-|", *rows, "", "</details>", ""]


def what_deploys(images, chart):
    """Every image, scanned or not, with the values switching it."""
    return [
        "<details><summary>What deploys each image</summary>", "",
        f"Measured on the renders of `{chart}`, one change at a time: "
        "each `enabled` or `deploy` default turned off, each default partition set to null, "
        "each setting of a `ci/*-values.yaml` fixture applied alone or dropped from it. "
        "Settings joined by `&` are needed together; a fixture file stands for all its settings, "
        "when none could be tied to the image. "
        "The control and compute planes count as always deployed, in this release or in their own.",
        "", "| Image | Removed by | Deployed with |", "|-|-|-|",
        *(f"| {image.label} | {values_list(image.off_with)} | {values_list(image.on_with)} |" for image in images),
        "", "</details>"]


def main():
    directory, scan, summary, blob = report_arguments(__doc__.split("\n\n")[0])
    images = load_images(directory, scan)
    scanned, failed, runs, csv_rows = [], [], [], []
    with tempfile.TemporaryDirectory() as work:
        for image in images:
            report = directory / "reports" / "images" / f"{image.number}.json"
            if image.status != "ok" or not report.is_file() or report.stat().st_size == 0:
                failed.append(image)
                continue
            image.vulnerabilities = load_vulnerabilities(json.loads(report.read_text(encoding="utf-8")))
            scanned.append(image)
            runs += sarif_runs(image, report, work)
            names = "; ".join(owner["chart"].replace("@", " ", 1) for owner in image.owners)
            deployment = (image.deployed, image.off_with, image.on_with)
            csv_rows += [
                (image.image, names, *deployment, found.severity, found.id, found.package, found.path,
                 found.installed, found.fixed, found.status, found.title, found.url)
                for found in image.vulnerabilities]

    write_csv(directory / "reports" / "vulnerabilities.csv", (
        "image", "owners", "deployed", "off with", "on with", "severity", "vulnerability", "package", "path",
        "installed", "fixed", "status", "title", "url"), csv_rows)
    (directory / "sarif").mkdir(exist_ok=True)
    with open(directory / "sarif" / "images.sarif", "w", encoding="utf-8") as file:
        json.dump(merge_sarif(runs), file, indent=2, ensure_ascii=False)
        file.write("\n")
    if failed:
        print(f"::warning title={len(failed)} images not scanned::see the job summary")

    scanned.sort(key=lambda image: (*(-image.count(column) for column in COLUMNS), image.label))
    lines = [
        "## Trivy: images",
        "",
        f"Trivy {trivy_version()}, vulnerability database of {trivy_version('UpdatedAt')}. "
        "Report only: nothing here blocks a publication.",
        "",
        *images_table(scanned, failed, blob),
        "", "### Critical and high vulnerabilities", "",
        f"The most severe first, then the fixable, at most {CAP} an image: the rest is in `vulnerabilities.csv`.",
        ""]
    for image in scanned:
        if image.count("CRITICAL") or image.count("HIGH"):
            lines += vulnerabilities_details(image)
    if scan["switch_chart"]:
        lines += what_deploys(images, scan["switch_chart"])
    append_summary(summary, lines + not_rendered(scan))


if __name__ == "__main__":
    main()
