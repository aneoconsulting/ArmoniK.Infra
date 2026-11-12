#!/usr/bin/env python3
"""Scans every image of charts/scan-inputs.py's scan.json with trivy, for
publish.yml's scan job, and records why an image could not be scanned.

Writes, under <scan-dir>:
  reports/images/<n>.json  trivy image report of image <n> of scan.json,
                           counted from 1
  image-status.json        per image, its status (ok, not-found, denied,
                           rate-limited or error) and the reason of a failure

The vulnerability databases must already be in place: no scan updates them.
"""

import argparse
import json
import re
import subprocess
import time
from pathlib import Path

# What the answer of a registry holds, by status, the first match winning.
ANSWERS = {
    "rate-limited": r"TOOMANYREQUESTS|status code 429",
    "not-found": r"MANIFEST_UNKNOWN|NAME_UNKNOWN|NOT_FOUND|status code 404",
    "denied": r"UNAUTHORIZED|DENIED|status code 40[13]",
    "error": r""}


def scan(image, report, config):
    """Scans an image into a report. Returns its status and the reason of a
    failure: the answer of the registry trivy tried last, the origin, a
    mirror missing an image it has not cached being no verdict. A Docker Hub
    repository that does not exist answers like a private one, so it reads as
    denied."""
    for attempt in (1, 2, 3):
        result = subprocess.run(
            ["trivy", "image", *config, "--image-src", "remote", "--scanners", "vuln", "--skip-db-update",
             "--skip-java-db-update", "--format", "json", "--output", str(report), image],
            stdin=subprocess.DEVNULL, stderr=subprocess.PIPE, encoding="utf-8", errors="replace", check=False)
        if result.returncode == 0:
            return {"status": "ok", "reason": ""}
        lines = [line for line in result.stderr.splitlines() if line.strip()]
        reason = re.sub(r"^ *\* ", "", lines[-1].replace("\t", " ")) if lines else ""
        reason = re.sub(r"^remote error: ", "", reason)
        if len(reason) >= 300:
            reason = "..." + reason[-300:]
        status = next(status for status, answer in ANSWERS.items() if re.search(answer, reason))
        # The registry's final answers are not retried.
        if status in ("rate-limited", "error") and attempt < 3:
            time.sleep(attempt * 10)
        else:
            return {"status": status, "reason": reason}


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("directory", type=Path, metavar="<scan-dir>")
    parser.add_argument("config", nargs="?", metavar="<trivy-config>")
    options = parser.parse_args()
    images = json.loads((options.directory / "scan.json").read_text(encoding="utf-8"))["images"]
    reports = options.directory / "reports" / "images"
    reports.mkdir(parents=True, exist_ok=True)
    config = ["--config", options.config] if options.config else []
    statuses = {
        image["image"]: scan(image["image"], reports / f"{number}.json", config)
        for number, image in enumerate(images, 1)}
    (options.directory / "image-status.json").write_text(json.dumps(statuses, indent=1) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
