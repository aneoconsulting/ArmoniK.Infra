#!/usr/bin/env python3
"""Renders the packaged charts and lists their container images, for trivy.

Every packaged release-root chart is rendered with its defaults and with each
of its ci/*-values.yaml fixtures, and every image of the renders is listed with
the charts whose templates hold it. The chart-checks job of
.github/workflows/linter-helm.yml scans the renders for misconfigurations, the
scan job of .github/workflows/publish.yml the images for vulnerabilities.
Needs helm and mikefarah yq v4, and nothing beyond the standard library: it
runs on the system python3 of a GitHub runner.

An image a user can turn on is listed because a fixture turns it on:
armonik/ci/optional-images-values.yaml and rabbitmq-values.yaml exist for
that. An image tagged 0.0.0-test is a fixture's placeholder and is left out.
operator-images.yaml adds the images an operator picks by itself.

Outputs, under the output directory:
  manifests/<chart>/<case>/<n>.yml  document <n> of a render, one file each so
                                    that a finding names its document
  documents.tsv                     <chart>/<case>/<n>.yml <name>@<version>
                                    <location> <alias-path>, the chart whose
                                    template rendered the document
  renders.tsv                       <chart> <case> <ok|failed> <first error line>
  images.tsv                        <image> <uses> <owners>, both
                                    comma-separated: a use is <chart>/<case>,
                                    <chart>/<case>/test for a helm test pod,
                                    or `operator`; an owner is
                                    <name>@<version>=<location>=<alias-path>,
                                    once a chart, by its longest path from a
                                    release root
  switches.tsv                      with -s: <chart> <image> <on|off> <off
                                    with> <on with>, see "Switches" below

A location is a path in this repository: the template of one of our charts,
or, for a third-party chart, the line of our Chart.yaml that declares it or
its nearest third-party ancestor, where its version is set
(charts/armonik-operators/Chart.yaml#L33).

A failed render is recorded, not fatal: a chart's bare defaults may be
invalid on purpose (armonik-compute-plane has no partition), its fixtures
then covering it. test/matrix.sh is what asserts which renders must succeed.

Warnings are GitHub workflow commands on stdout, one per line.

Switches. Whether a release deploys an image hangs on its values, so -s
measures it on renders of CHART, one change (a probe) at a time:
  - flip: each `enabled` or `deploy` value that is true in CHART's computed
    defaults is set to false, and each entry of a `partitions` map to null;
  - set: each setting of each fixture is applied alone over the defaults;
  - drop: each setting of each fixture is dropped from it, with the maps it
    alone fills.
A flip or a set that removes an image turns it off, one that adds it turns it
on. A drop that brings an image back to what the defaults do with it shows
that the fixture needs the setting to switch the image.
<on|off> is what the defaults do. <off with> and <on with> list the
alternatives, ` | `-separated, each a `<key>=<value>` setting or several
joined by ` & ` that a fixture needs together; <off with> never holds
turning the control or compute plane off, which run in this release or in
their own. A render a change breaks proves nothing. A fixture's file
(ci/<case>-values.yaml) stands for an image none of its settings could be
tied to. Neither list catches a switch that is not a boolean, nor settings
needed together that no fixture holds.

The defaults, the fixtures and every `global` setting are rendered whole.
Any other setting lies under one subchart, the deepest whose alias path
prefixes its keys (its scope), and is rendered on a copy of CHART keeping
every chart and helper but only the templates of that subchart and of those
below it: values, conditions and helpers resolve as in CHART at a fraction of
the cost, the images of the other charts being those of the whole render the
change starts from. A render the copy breaks is retried whole, and a copy
whose defaults miss an image CHART renders is not used. CHART's own settings
are rendered whole when its templates name an image, skipped otherwise.
"""

import argparse
import copy
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from concurrent.futures import ThreadPoolExecutor
from dataclasses import dataclass
from pathlib import Path
from typing import NamedTuple, Optional

ME = sys.argv[0]
HERE = Path(__file__).resolve().parent
REPOSITORY = HERE.parent


def run(*command, stdin=None, check=True):
    """Runs a command, its streams as text."""
    return subprocess.run(
        [str(word) for word in command], input=stdin, check=check,
        capture_output=True, encoding="utf-8", errors="surrogateescape")


def read_yaml(path=None, text=None, expression="."):
    """The documents of a YAML file or text, which yq hands over as JSON."""
    source = "-" if path is None else path
    output = run("yq", "-o=json", "-I=0", expression, source, stdin=text).stdout
    return [json.loads(line) for line in output.splitlines()]


def read_values(path):
    """A values file, without any value when it is empty or not YAML: the
    render of an invalid fixture is what gets reported."""
    try:
        return (read_yaml(path) or [None])[0] or {}
    except subprocess.CalledProcessError:
        return {}


def append_row(path, *fields):
    with open(path, "a", encoding="utf-8", errors="surrogateescape") as file:
        file.write("\t".join(fields) + "\n")


def warn(title, message):
    """A workflow command: GitHub Actions shows it as an annotation."""
    print(f"::warning title={title}::{message}", flush=True)


def helm_template(chart, kube_version, *arguments):
    # stderr apart: helm warnings would corrupt the manifest stream.
    return run("helm", "template", "scan", chart, "--kube-version", kube_version, *arguments, check=False)


# ---- Images


def normalize(reference):
    """One spelling per image: "docker.io/library/busybox", "busybox" and
    "busybox:latest" are one image."""
    reference = re.sub(r"^(index\.)?docker\.io/", "", reference)
    reference = re.sub(r"^library/", "", reference)
    if "@" not in reference and ":" not in reference.split("/")[-1]:
        reference += ":latest"
    return reference


def is_image(reference):
    """Anything that is not one reference (a template leftover, prose) is not
    an image, nor is a fixture's placeholder."""
    return (re.fullmatch(r"[A-Za-z0-9][A-Za-z0-9._/:@-]*", reference) is not None
            and not reference.endswith(":0.0.0-test"))


def is_disabled(node):
    return isinstance(node, dict) and node.get("enabled") is False


def without_disabled(node):
    """A block marked `enabled: false` deploys nothing: a CR names the image
    of a component it leaves off (the PerconaServerMongoDB's backup)."""
    if isinstance(node, dict):
        return {key: without_disabled(value) for key, value in node.items() if not is_disabled(value)}
    if isinstance(node, list):
        return [without_disabled(value) for value in node if not is_disabled(value)]
    return node


def nodes(node):
    """A YAML node and every node below it."""
    yield node
    if isinstance(node, (dict, list)):
        for child in node.values() if isinstance(node, dict) else node:
            yield from nodes(child)


IMAGE_FLAG = re.compile(r"--(([a-z0-9-]*-)?image|prometheus-config-reloader)=")
TEST_HOOK = re.compile(r"(^|,) *test(-success)? *(,|$)")


def image_candidates(document):
    """Where an image hides in a document: beyond the `image` fields of pod
    specs and of CRs (percona's PerconaServerMongoDB, the Prometheus CR),
    operators take the images of what they spawn as flags (cert-manager's ACME
    solver, prometheus-operator's config reloader) or env."""
    for node in nodes(document):
        if isinstance(node, dict):
            yield node.get("image")
            yield node.get("imageName")
            name = node.get("name")
            if "value" in node and isinstance(name, str) and re.search("image", name, re.IGNORECASE):
                yield node["value"]
        elif isinstance(node, str):
            flag = IMAGE_FLAG.match(node)
            if flag:
                yield node[flag.end():]


def document_images(document):
    """The images of a rendered document, and whether it is a helm test."""
    if is_disabled(document):
        return set(), False
    document = without_disabled(document)
    hook = ""
    if isinstance(document, dict):
        hook = ((document.get("metadata") or {}).get("annotations") or {}).get("helm.sh/hook") or ""
    images = {
        normalize(candidate) for candidate in image_candidates(document)
        if isinstance(candidate, str) and is_image(candidate)}
    return images, TEST_HOOK.search(str(hook)) is not None


def manifest_documents(manifest):
    """The documents of a render with their index in it. CRDs are skipped:
    their schemas carry `image` keys that are documentation."""
    expression = 'select(.kind != "CustomResourceDefinition") | {"index": di, "document": .}'
    return [(entry["index"], entry["document"]) for entry in read_yaml(text=manifest, expression=expression)]


# ---- Charts


@dataclass(frozen=True)
class Chart:
    """A chart of an unpacked archive."""
    path: str       # its aliases from the release root: armonik/operators/keda
    id: str         # <name>@<version>
    base: str       # where its documents are located, see chart_graph
    directory: Path


@dataclass(frozen=True)
class Owner:
    """The chart whose template rendered a document."""
    chart: str      # <name>@<version>
    location: str   # path in this repository
    path: str       # alias path of the chart

    def __str__(self):
        return f"{self.chart}={self.location}={self.path}"


@dataclass(frozen=True)
class Found:
    """An image in a rendered document."""
    image: str
    use: str        # <chart>/<case>, or <chart>/<case>/test in a helm test
    owner: Owner


def dependency_line(chart_yaml, alias):
    """The line the list item of a dependency starts at, read from the text:
    yq's line numbers drift after a head comment."""
    key = re.compile(r"""^ *(- )?(name|alias): *["']?%s["']? *(#.*)?$""" % re.escape(alias))
    start = line = ""
    for number, text in enumerate(chart_yaml.read_text(encoding="utf-8").splitlines(), 1):
        if re.match(r" *- ", text):
            start = number
        if key.match(text):
            line = start
    return line


def chart_graph(directory, path, inherited=""):
    """Every chart of an unpacked chart, by alias path. Our charts are the
    directories next to this script: the base of one is its own, a template
    path completing it. The base of a third-party chart is where its nearest
    ancestor of ours declares the dependency leading to it."""
    (metadata,) = read_yaml(directory / "Chart.yaml")
    ours = (HERE / metadata["name"] / "Chart.yaml").is_file()
    base = f"charts/{metadata['name']}" if ours else inherited
    graph = {path: Chart(path, f"{metadata['name']}@{metadata['version']}", base, directory)}
    for dependency in metadata.get("dependencies") or []:
        alias = dependency.get("alias") or dependency["name"]
        subchart = directory / "charts" / dependency["name"]
        if not subchart.is_dir():
            continue
        below = base
        if ours:
            below = f"{base}/Chart.yaml#L{dependency_line(REPOSITORY / base / 'Chart.yaml', alias)}"
        graph.update(chart_graph(subchart, f"{path}/{alias}", below))
    return graph


def unpack(archive, directory):
    """The root directory of a packaged chart unpacked under a directory."""
    directory.mkdir(parents=True)
    run("tar", "-xzf", archive, "-C", directory)
    (root,) = directory.iterdir()
    return root


def document_owners(manifest, graph):
    """The owner of each document of a render. helm heads every document with
    the template it comes from, whose path holds the alias path of the owning
    chart: armonik/charts/operators/charts/kube-prometheus/templates/x.yaml is
    templates/x.yaml of armonik/operators/kube-prometheus."""
    lines = manifest.splitlines()
    sources = [line[len("# Source: "):] for line in lines if line.startswith("# Source: ")]
    if len(sources) != lines.count("---"):
        return None
    owners = []
    for source in sources:
        cut = source.find("/templates/")
        template = source[cut:] if cut >= 0 else source
        path = source[:len(source) - len(template)].replace("/charts/", "/")
        chart = graph.get(path)
        if chart is None:
            owners.append(Owner("", template, path))
        else:
            owners.append(Owner(chart.id, chart.base if "/Chart.yaml" in chart.base else chart.base + template, path))
    return owners


def render(archive, use, fixture, graph, out, kube_version):
    """Renders one case of a chart into the output directory. Returns the
    images found in it."""
    chart, case = use.split("/")
    result = helm_template(archive, kube_version, *(["-f", fixture] if fixture else []))
    if result.returncode != 0:
        errors = result.stderr.splitlines()
        reason = next((line for line in errors if "error" in line.lower()), errors[0] if errors else "")
        append_row(out / "renders.tsv", chart, case, "failed", reason)
        # A fixture is a valid render by contract; defaults need not be.
        if case != "defaults":
            warn(f"{use} did not render", reason)
        return []
    append_row(out / "renders.tsv", chart, case, "ok", "")
    owners = document_owners(result.stdout, graph)
    if owners is None:
        sys.exit(f'{ME}: {use}: not one "# Source:" line per document')

    manifests = out / "manifests" / use
    manifests.mkdir(parents=True)
    run("yq", "-s", f'"{manifests}/" + $index', "-", stdin=result.stdout)
    for index, owner in enumerate(owners):
        append_row(out / "documents.tsv", f"{use}/{index}.yml", owner.chart, owner.location, owner.path)

    found = []
    for index, document in manifest_documents(result.stdout):
        images, is_test = document_images(document)
        found += [Found(image, use + "/test" if is_test else use, owners[index]) for image in sorted(images)]
    return found


def chart_cases(chart):
    """The renders of a chart as <case> <fixture>: its defaults, then each of
    its fixtures."""
    yield "defaults", None
    for fixture in sorted((HERE / chart / "ci").glob("*-values.yaml")):
        yield fixture.name[:-len("-values.yaml")], fixture


class ImageRow(NamedTuple):
    """A line of images.tsv."""
    image: str
    uses: str       # comma-separated, in the order found
    owners: str     # comma-separated, a chart once; empty for an operator image no render carries the operator of


def write_images(found, out):
    """images.tsv, one line per image. An operator's image takes the
    operator's owners. Returns its rows."""
    uses = {}           # image -> its uses, in the order found
    owners = {}         # image -> chart id -> its owner with the longest path
    for item in found:
        uses.setdefault(item.image, {})[item.use] = None
        known = owners.setdefault(item.image, {}).get(item.owner.chart)
        if known is None or item.owner.path.count("/") > known.path.count("/"):
            owners[item.image][item.owner.chart] = item.owner
    operator_of = {}
    for entry in read_yaml(HERE / "operator-images.yaml")[0]:
        image = normalize(entry["image"])
        uses.setdefault(image, {})["operator"] = None
        operator_of[image] = normalize(entry["operator"])

    rows = []
    for image, image_uses in uses.items():
        image_owners = owners.get(operator_of.get(image, image), {}).values()
        rows.append(ImageRow(image, ",".join(image_uses), ",".join(map(str, image_owners))))
    rows.sort(key="\t".join)
    for row in rows:
        append_row(out / "images.tsv", row.image, row.uses, row.owners or "unknown=charts/operator-images.yaml=")
    return rows


def review_warnings(images):
    """What only a review can keep true: an operator bump may change the
    images the operator picks, and an image-map repository needs a fixture
    deploying it."""
    for row in images:
        if not row.owners:
            warn("charts/operator-images.yaml is stale",
                 f"no render carries the operator of {row.image} any more: review the entry")
    (common,) = read_yaml(HERE / "armonik-common" / "values.yaml")
    for repository in common["global"]["armonik"]["imageComponents"]:
        if not any(row.image.startswith(repository + ":") for row in images):
            warn(f"{repository} is not scanned",
                 "no fixture deploys this global.armonik.imageComponents entry: "
                 "extend armonik/ci/optional-images-values.yaml")


# ---- Switches (-s), see the head comment.

# Turning a plane off moves it to a release of its own.
ALWAYS_DEPLOYED = {"control-plane.enabled=false", "compute-plane.enabled=false"}


@dataclass
class Probe:
    """One change of values and the images the chart renders with it."""
    kind: str       # flip, set or drop
    fixture: str    # the case a set or a drop comes from, "" for a flip
    setting: str    # <key>=<value>
    scope: str      # alias path of the only chart the change can reach, "" for the whole chart
    values: dict    # what the probe renders with
    images: Optional[frozenset] = None  # None when the probe did not render


def leaves(values, path=()):
    """Every value of a values document outside a list, as <key path> <value>,
    a list counting as one value."""
    for key, value in values.items():
        if isinstance(value, dict):
            yield path + (key,), value
            yield from leaves(value, path + (key,))
        else:
            yield path + (key,), value


def settings(values):
    """The settings of a values document: its values that are not maps."""
    return [(path, value) for path, value in leaves(values) if value is not None and not isinstance(value, dict)]


def nested(path, value):
    """The values document setting one key path."""
    for key in reversed(path):
        value = {key: value}
    return value


def without(values, path):
    """A values document without one key path."""
    values = copy.deepcopy(values)
    parent = values
    for key in path[:-1]:
        parent = parent[key]
    del parent[path[-1]]
    return values


def lone_prefix(values, path):
    """The shortest prefix of a setting's key path holding no other setting:
    dropping the setting drops the maps it alone fills."""
    below = values
    for depth in range(1, len(path)):
        below = below[path[depth - 1]]
        if len(settings(below)) == 1:
            return path[:depth]
    return path


def setting_text(path, value):
    text = re.sub(r"[\t\n]+", " ", value) if isinstance(value, str) else json.dumps(
        value, separators=(",", ":"), ensure_ascii=False)
    return ".".join(path) + "=" + text


def flips(defaults):
    """The changes turning off what the computed defaults turn on, as <key
    path> <value>. helm copies the globals into every subchart: they are
    flipped at the root only."""
    found = [(path, value) for path, value in leaves(defaults) if "global" not in path[1:]]
    for path, value in found:
        if value is True and path[-1] in ("enabled", "deploy"):
            yield path, False
    for path, value in found:
        if value is not None and len(path) > 1 and path[-2] == "partitions":
            yield path, None


def changes(defaults, fixtures):
    """Every change to probe, as <kind> <fixture> <key path> <setting>
    <values>."""
    for path, value in flips(defaults):
        yield "flip", "", path, setting_text(path, value), nested(path, value)
    for case, values in fixtures.items():
        for path, value in settings(values):
            text = setting_text(path, value)
            yield "set", case, path, text, nested(path, value)
            yield "drop", case, path, text, without(values, lone_prefix(values, path))


def plan_probes(defaults, fixtures, subcharts, root_names_images):
    """The probes of a chart, whose subcharts come as <key prefix> <alias
    path>. A setting several fixtures share, or one that
    is a flip, is applied once. A setting can only change the images of the
    deepest subchart its keys lead into, its scope: none, the whole chart, for
    a global, which any chart may read, and for a value of the chart itself,
    which is not probed when its own templates name no image."""
    probes = []
    applied = set()
    for kind, fixture, path, setting, values in changes(defaults, fixtures):
        if kind != "drop":
            if setting in applied:
                continue
            applied.add(setting)
        keys = "/".join(path) + "/"
        scope = max((prefix for prefix in subcharts if keys.startswith(prefix + "/")), key=len, default="")
        if scope or root_names_images or path[0] == "global":
            probes.append(Probe(kind, fixture, setting, subcharts.get(scope, ""), values))
    return probes


def computed_defaults(root, kube_version):
    """The computed defaults of an unpacked chart, every subchart's under its
    alias, as a template of it prints them."""
    template = root / "templates" / "scan-values.yaml"
    template.write_text("{{ toJson .Values }}\n")
    try:
        result = helm_template(root, kube_version, "-s", "templates/scan-values.yaml")
    finally:
        template.unlink()
    if result.returncode != 0:
        sys.exit(f"{ME}: {root.name}: cannot print the computed defaults: {result.stderr.strip()}")
    return json.loads(result.stdout.splitlines()[-1])


def scoped_copy(root, chart, destination):
    """A copy of an unpacked chart rendering only the templates of one of its
    charts and of the charts below, with the helpers of all, so that values,
    conditions and helpers resolve as in the whole chart. Hard links keep it
    cheap. The archive is already filtered: read as a directory, the root
    .helmignore would apply to every subchart."""
    try:
        shutil.copytree(root, destination, copy_function=os.link)
    except OSError:
        shutil.rmtree(destination, ignore_errors=True)
        shutil.copytree(root, destination)
    kept = destination / chart.directory.relative_to(root)
    for directory, _, names in os.walk(destination):
        for name in names:
            file = Path(directory, name)
            is_helper = name.startswith("_") or name.endswith(".tpl")
            is_template = "templates" in file.parent.relative_to(destination).parts
            if name == ".helmignore" or (is_template and not is_helper and kept not in file.parents):
                file.unlink()
    return destination


def rendered_images(chart, values_file, kube_version):
    """The images a chart renders over a values file, None when it does not
    render."""
    result = helm_template(chart, kube_version, "-f", values_file)
    if result.returncode != 0:
        return None
    images = set()
    for _, document in manifest_documents(result.stdout):
        images |= document_images(document)[0]
    return images


def within(path, scope):
    return path == scope or path.startswith(scope + "/")


class Switches:
    """Measures which values of a chart deploy each of its images."""

    def __init__(self, chart, archive, root, graph, found, work, kube_version, jobs):
        self.chart = chart
        self.archive = archive
        self.root = root
        self.graph = graph
        self.work = work
        self.kube_version = kube_version
        self.jobs = jobs
        # Each whole render: its images, each with the alias path of its chart.
        self.whole = {}
        for item in found:
            use_chart, case = item.use.split("/")[:2]
            if use_chart == chart:
                self.whole.setdefault(case, set()).add((item.image, item.owner.path))
        self.copies = {}

    def images_of(self, case):
        return frozenset(image for image, _ in self.whole[case])

    def probe_images(self, name, values, scope, case):
        """The images of the chart with some values. A scoped probe renders
        the copy of its scope and takes the images of every other chart from
        the whole render of the case it starts from; a render the copy breaks
        is retried whole."""
        values_file = self.work / "probes" / f"{name}.json"
        values_file.write_text(json.dumps(values), encoding="utf-8")
        try:
            images = None
            if scope:
                images = rendered_images(self.copies[scope], values_file, self.kube_version)
                if images is not None:
                    images |= {image for image, path in self.whole[case] if not within(path, scope)}
            if images is None:
                images = rendered_images(self.archive, values_file, self.kube_version)
            # A render without any image proves nothing either.
            return frozenset(images) if images else None
        finally:
            values_file.unlink()

    def run_probe(self, numbered):
        number, probe = numbered
        # A drop starts from its fixture, which must have rendered.
        case = probe.fixture if probe.kind == "drop" else "defaults"
        if case in self.whole:
            probe.images = self.probe_images(number, probe.values, probe.scope, case)

    def usable_copy(self, scope):
        """A copy whose defaults do not render the images of the chart cannot
        stand in for it."""
        return self.probe_images(scope.replace("/", "_"), {}, scope, "defaults") == self.images_of("defaults")

    def measure(self):
        """Plans and runs the probes."""
        defaults = computed_defaults(self.root, self.kube_version)
        fixtures = {case: read_values(fixture) for case, fixture in chart_cases(self.chart) if fixture}
        subcharts = {path[len(self.chart) + 1:]: path for path in self.graph if path != self.chart}
        root_names_images = any(path == self.chart for _, path in self.whole["defaults"])
        probes = plan_probes(defaults, fixtures, subcharts, root_names_images)

        (self.work / "probes").mkdir()
        scopes = sorted({probe.scope for probe in probes if probe.scope})
        for scope in scopes:
            destination = self.work / "copies" / scope.replace("/", "_") / self.chart
            destination.parent.mkdir(parents=True)
            self.copies[scope] = scoped_copy(self.root, self.graph[scope], destination)
        with ThreadPoolExecutor(self.jobs) as pool:
            usable = dict(zip(scopes, pool.map(self.usable_copy, scopes)))
            for probe in probes:
                if probe.scope and not usable[probe.scope]:
                    probe.scope = ""
            list(pool.map(self.run_probe, enumerate(probes)))
        return probes

    def row(self, image, probes):
        """The switches.tsv row of an image. A change switches the image when
        it moves it away from its default. A fixture that does needs the
        settings whose drop moves it back."""
        on = image in self.images_of("defaults")
        alternatives = []
        needs = {}
        for probe in probes:
            if probe.images is None:
                continue
            moved = (image in probe.images) != on
            if probe.kind == "drop":
                if not moved and probe.setting not in needs.setdefault(probe.fixture, []):
                    needs[probe.fixture].append(probe.setting)
            elif moved and not (on and probe.setting in ALWAYS_DEPLOYED) and probe.setting not in alternatives:
                alternatives.append(probe.setting)

        # A fixture switching the image adds the settings it needs together,
        # unless one of them switches the image alone or an alternative holds
        # them already. Nothing telling its settings apart, the fixture stands
        # for itself.
        files = []
        for fixture in dict.fromkeys(probe.fixture for probe in probes if probe.fixture):
            if fixture not in self.whole or (image in self.images_of(fixture)) == on:
                continue
            files.append(f"ci/{fixture}-values.yaml")
            needed = needs.get(fixture, [])
            together = " & ".join(needed)
            if needed and not set(needed) & set(alternatives) and together not in " | ".join(alternatives):
                alternatives.append(together)
        with_values = " | ".join(alternatives or files)
        return (self.chart, image, "on", with_values, "") if on else (self.chart, image, "off", "", with_values)

    def write(self, out, images):
        """switches.tsv, then a warning for each image the chart does not
        deploy: the report takes the chart's point of view, so its fixtures
        must reach every image."""
        if "defaults" not in self.whole:
            print(f"{ME}: {self.chart} does not render with its defaults, no switches.tsv", file=sys.stderr)
            return
        probes = self.measure()
        deployed = set().union(*(self.images_of(case) for case in self.whole))
        deployed.update(*(probe.images for probe in probes if probe.images))
        rows = sorted((self.row(image, probes) for image in deployed), key="\t".join)
        (out / "switches.tsv").touch()
        for row in rows:
            append_row(out / "switches.tsv", *row)
        for row in images:
            if row.uses != "operator" and row.image not in deployed:
                warn(f"{self.chart} does not deploy {row.image}",
                     f"only {row.uses} renders it: extend the ci fixtures of {self.chart}")


# ---- Command line


def arguments():
    parser = argparse.ArgumentParser(
        description="Renders every packaged chart and lists the images of the renders.")
    parser.add_argument("-d", dest="dist", type=Path, default=REPOSITORY / "dist", metavar="DIR",
                        help="directory holding the packaged charts (default: the repo's dist/)")
    parser.add_argument("-o", dest="out", type=Path, default=REPOSITORY / "scan", metavar="DIR",
                        help="output directory, cleared first (default: the repo's scan/)")
    # test/matrix.sh's default: the compute plane refuses anything below 1.29.
    parser.add_argument("-k", dest="kube_version", default="1.31.0", metavar="VERSION",
                        help="Kubernetes version to render for")
    parser.add_argument("-s", dest="switch_chart", metavar="CHART",
                        help="also measure the values deciding which images CHART deploys "
                             "(switches.tsv), a few hundred partial renders of it")
    parser.add_argument("-j", dest="jobs", type=int, default=os.cpu_count() or 2, metavar="N",
                        help="renders run at once for -s (default: one per processor)")
    return parser.parse_args()


def main():
    options = arguments()
    # The Python yq wrapper shares the name and takes jq syntax.
    if shutil.which("yq") is None or "mikefarah" not in run("yq", "--version", check=False).stdout:
        print(f"{ME}: needs mikefarah yq v4 (https://github.com/mikefarah/yq)", file=sys.stderr)
        return 2
    archives = sorted(options.dist.glob("*.tgz"))
    if not archives:
        print(f"{ME}: no packaged chart in {options.dist}; run package-charts.sh first", file=sys.stderr)
        return 2

    out = options.out
    shutil.rmtree(out, ignore_errors=True)
    (out / "manifests").mkdir(parents=True)
    (out / "renders.tsv").touch()
    with tempfile.TemporaryDirectory() as scratch:
        work = Path(scratch)
        found = []
        switches = None
        for archive in archives:
            root = unpack(archive, work / "charts" / archive.name)
            chart = root.name
            graph = chart_graph(root, chart)
            for case, fixture in chart_cases(chart):
                found += render(archive, f"{chart}/{case}", fixture, graph, out, options.kube_version)
            if chart == options.switch_chart:
                switches = Switches(chart, archive, root, graph, found, work, options.kube_version, options.jobs)

        images = write_images(found, out)
        if not images:
            print(f"{ME}: the charts reference no image, which means the extraction broke", file=sys.stderr)
            return 1
        review_warnings(images)
        if options.switch_chart:
            if switches is None:
                print(f"{ME}: -s {options.switch_chart}: no such packaged chart in {options.dist}", file=sys.stderr)
                return 2
            switches.write(out, images)

    renders = len((out / "renders.tsv").read_text(encoding="utf-8", errors="surrogateescape").splitlines())
    print(f"{ME}: {renders} render(s), {len(images)} image(s), in {out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
