#!/usr/bin/env python3
"""Renders the packaged charts and lists their container images, for trivy:
AGENTS.md says which jobs consume what. Needs helm and mikefarah yq v4, and
nothing beyond the standard library.

Every packaged chart is rendered with its defaults and with each of its
ci/*-values.yaml fixtures. A failed render is recorded, not fatal: bare
defaults may be invalid on purpose, the fixtures then covering the chart.
Writes, under the output directory:
  manifests/<chart>/<case>/<n>.yml  document <n> of a render, one file each so
                                    that a finding names its document
  scan.json                         renders: each <chart>/<case> with its first
                                    error line, null when it rendered;
                                    documents: see Document; images: see
                                    image_list and Switches.switch;
                                    switch_chart: the CHART of -s
Warnings are GitHub workflow commands on stdout.

An image a user can turn on is listed because a fixture turns it on. One
tagged 0.0.0-test is a fixture's placeholder and is left out.
operator-images.yaml adds the images an operator picks by itself.

Switches (-s CHART). Whether a release deploys an image hangs on its values,
which is measured on renders of CHART, one change (a probe) at a time:
  flip  each `enabled` or `deploy` value that is true in CHART's computed
        defaults is set to false, and each entry of a `partitions` map to null
  set   each setting of each fixture is applied alone over the defaults
  drop  each setting of each fixture is dropped from it
A flip or a set that removes an image turns it off, one that adds it turns it
on. A drop that brings an image back to what the defaults do with it shows
that the fixture needs the setting to switch the image. A render a change
breaks proves nothing. Neither a switch that is not a boolean is caught, nor
settings needed together that no fixture holds.

A change can only reach the images of its scope, the deepest chart whose alias
path prefixes its keys, so it is rendered on a copy of CHART keeping every
chart and helper but only the templates of the scope and of the charts below
it: values, conditions and helpers resolve as in CHART at a fraction of the
cost, the images of the other charts being those of the whole render the
change starts from. The scope of a global, which any chart may read, is CHART.
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
from dataclasses import asdict, dataclass, field
from pathlib import Path

ME = sys.argv[0]
HERE = Path(__file__).resolve().parent


def run(*command, stdin=None, check=True):
    return subprocess.run(
        [str(word) for word in command], input=stdin, check=check,
        capture_output=True, encoding="utf-8", errors="surrogateescape")


def read_yaml(path="-", text=None, expression="."):
    """The documents of a YAML file or text, which yq hands over as JSON. A
    file that is not YAML has none."""
    output = run("yq", "-o=json", "-I=0", expression, path, stdin=text, check=False).stdout
    return [json.loads(line) for line in output.splitlines()]


def warn(title, message):
    """A workflow command: GitHub Actions shows it as an annotation."""
    print(f"::warning title={title}::{message}", flush=True)


def helm_template(chart, kube_version, *arguments, values=None):
    """Renders a chart, over values given as a file or as a map."""
    stdin = None
    if isinstance(values, Path):
        arguments += ("-f", values)
    elif values is not None:
        arguments += ("-f", "-")
        stdin = json.dumps(values)
    # stderr apart: helm warnings would corrupt the manifest stream.
    return run("helm", "template", "scan", chart, "--kube-version", kube_version, *arguments, stdin=stdin, check=False)


# ---- Images of a render


def normalize(reference):
    """One spelling per image: "docker.io/library/busybox", "busybox" and
    "busybox:latest" are one image."""
    reference = re.sub(r"^(index\.)?docker\.io/", "", reference)
    reference = re.sub(r"^library/", "", reference)
    if "@" not in reference and ":" not in reference.split("/")[-1]:
        reference += ":latest"
    return reference


def nodes(node):
    """A YAML node and every node below it. A block marked `enabled: false`
    deploys nothing and is left out: a CR names the image of a component it
    leaves off (the PerconaServerMongoDB's backup)."""
    if isinstance(node, dict) and node.get("enabled") is False:
        return
    yield node
    if isinstance(node, (dict, list)):
        for child in node.values() if isinstance(node, dict) else node:
            yield from nodes(child)


IMAGE = re.compile(r"[A-Za-z0-9][A-Za-z0-9._/:@-]*")
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
            if "value" in node and re.search("image", str(node.get("name")), re.IGNORECASE):
                yield node["value"]
        elif isinstance(node, str) and IMAGE_FLAG.match(node):
            yield node.partition("=")[2]


def document_images(document):
    """The images of a rendered document, and whether it is a helm test.
    Anything that is not one reference (a template leftover, prose) is not an
    image, nor is a fixture's placeholder."""
    images = {
        normalize(candidate) for candidate in image_candidates(document)
        if isinstance(candidate, str) and IMAGE.fullmatch(candidate) and not candidate.endswith(":0.0.0-test")}
    hook = ""
    if isinstance(document, dict):
        hook = ((document.get("metadata") or {}).get("annotations") or {}).get("helm.sh/hook") or ""
    return sorted(images), TEST_HOOK.search(str(hook)) is not None


def manifest_documents(manifest):
    """The documents of a render, each with its index in it. CRDs are
    skipped: their schemas carry `image` keys that are documentation."""
    expression = 'select(.kind != "CustomResourceDefinition") | {"index": di, "content": .}'
    return read_yaml(text=manifest, expression=expression)


# ---- Renders


@dataclass(frozen=True)
class Chart:
    """A chart of an unpacked archive."""
    id: str             # <name>@<version>
    base: str           # where its documents are located, see chart_graph
    directory: Path


@dataclass
class Document:
    """A document of a render, with the chart whose template rendered it."""
    render: str         # <chart>/<case>: manifests/<render>/<index>.yml
    index: int
    owner: str          # <name>@<version>
    location: str       # in this repository: the template of one of our charts, or for a third-party chart the line
                        # of our Chart.yaml declaring it or its nearest third-party ancestor, where its version is set
    path: str           # the aliases of the owner from the release root: armonik/operators/keda
    images: list = field(default_factory=list)
    helm_test: bool = False


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
    graph = {path: Chart(f"{metadata['name']}@{metadata['version']}", base, directory)}
    for dependency in metadata.get("dependencies") or []:
        alias = dependency.get("alias") or dependency["name"]
        subchart = directory / "charts" / dependency["name"]
        below = base
        if ours:
            below = f"{base}/Chart.yaml#L{dependency_line(HERE.parent / base / 'Chart.yaml', alias)}"
        if subchart.is_dir():
            graph.update(chart_graph(subchart, f"{path}/{alias}", below))
    return graph


def render(archive, name, fixture, graph, out, kube_version):
    """Renders one case of a chart into manifests/. Returns its first error
    line, None when it renders, and its documents."""
    result = helm_template(archive, kube_version, values=fixture)
    if result.returncode != 0:
        errors = result.stderr.splitlines()
        error = next((line for line in errors if "error" in line.lower()), errors[0] if errors else "")
        # A fixture is a valid render by contract; defaults need not be.
        if fixture:
            warn(f"{name} did not render", error)
        return error, []
    manifests = out / "manifests" / name
    manifests.mkdir(parents=True)
    run("yq", "-s", f'"{manifests}/" + $index', "-", stdin=result.stdout)

    # helm heads every document with the template it comes from, whose path
    # holds the alias path of the owner: armonik/charts/operators/charts/keda/
    # templates/x.yaml is templates/x.yaml of armonik/operators/keda.
    lines = result.stdout.splitlines()
    sources = [line[len("# Source: "):] for line in lines if line.startswith("# Source: ")]
    if len(sources) != lines.count("---"):
        sys.exit(f'{ME}: {name}: not one "# Source:" line per document')
    documents = []
    for index, source in enumerate(sources):
        path, _, template = source.partition("/templates/")
        path = path.replace("/charts/", "/")
        chart = graph[path]
        location = chart.base if "/Chart.yaml" in chart.base else f"{chart.base}/templates/{template}"
        documents.append(Document(name, index, chart.id, location, path))
    for entry in manifest_documents(result.stdout):
        document = documents[entry["index"]]
        document.images, document.helm_test = document_images(entry["content"])
    return None, documents


def fixtures(chart):
    """The fixtures of a chart, by case."""
    return {path.name[:-len("-values.yaml")]: path for path in sorted((HERE / chart / "ci").glob("*-values.yaml"))}


def image_list(documents):
    """Every image, sorted, with its uses (<chart>/<case>, <chart>/<case>/test
    in a helm test pod, or `operator`) and its owners: each chart whose
    templates hold it, once, by its longest path from a release root. A chart
    counts once whatever its version, package-charts.sh -v stamping a release
    root but not its copies inside the umbrella. An operator's image also takes
    the operator's owners."""
    images = {}
    for document in documents:
        use = document.render + ("/test" if document.helm_test else "")
        for name in document.images:
            image = images.setdefault(name, {"image": name, "uses": [], "owners": {}})
            if use not in image["uses"]:
                image["uses"].append(use)
            key = document.owner.partition("@")[0]
            known = image["owners"].get(key)
            if known is None or document.path.count("/") > known["path"].count("/"):
                image["owners"][key] = {
                    "chart": document.owner, "location": document.location, "path": document.path}
    for entry in read_yaml(HERE / "operator-images.yaml")[0]:
        name = normalize(entry["image"])
        image = images.setdefault(name, {"image": name, "uses": [], "owners": {}})
        image["uses"].append("operator")
        operator = images.get(normalize(entry["operator"]))
        if operator is None:
            # What only a review can keep true: an operator bump may change
            # the images the operator picks.
            warn("charts/operator-images.yaml is stale",
                 f"no render carries the operator of {image['image']} any more: review the entry")
            unknown = {"chart": "unknown", "location": "charts/operator-images.yaml", "path": ""}
            operator = {"owners": {"unknown": unknown}}
        image["owners"].update(operator["owners"])
    return [{**images[name], "owners": list(images[name]["owners"].values())} for name in sorted(images)]


# ---- Switches (-s), see the head comment.

# Turning a plane off moves it to a release of its own.
ALWAYS_DEPLOYED = {"control-plane.enabled=false", "compute-plane.enabled=false"}


@dataclass
class Probe:
    """One change of values and the images the chart renders with it."""
    kind: str           # flip, set or drop
    fixture: str        # the case a set or a drop comes from
    setting: str        # <key>=<value>
    scope: str          # alias path of the only chart the change can reach
    values: dict        # what the probe renders with
    images: set = None  # None when the probe did not render


def entries(values, path=()):
    """Every entry of a values document outside a list, as <key path>
    <value>, a list counting as one value."""
    for key, value in values.items():
        yield path + (key,), value
        if isinstance(value, dict):
            yield from entries(value, path + (key,))


def settings(values):
    """The settings of a values document: its values that are not maps."""
    return [(path, value) for path, value in entries(values) if value is not None and not isinstance(value, dict)]


def flips(defaults):
    """The changes turning off what the computed defaults turn on. helm
    copies the globals into every subchart: they are flipped at the root."""
    found = [(path, value) for path, value in entries(defaults) if "global" not in path[1:]]
    flipped = [(path, False) for path, value in found if value is True and path[-1] in ("enabled", "deploy")]
    return flipped + [(path, None) for path, value in found if value is not None and path[-2:-1] == ("partitions",)]


def only(path, value):
    """The values document setting one key path."""
    for key in reversed(path):
        value = {key: value}
    return value


def without(values, path):
    """A values document without one setting, nor the maps it alone fills."""
    values = copy.deepcopy(values)
    parent, key = values, path[0]
    for below in path[1:]:
        if len(settings(parent[key])) == 1:
            break
        parent, key = parent[key], below
    del parent[key]
    return values


class Switches:
    """Measures which values of a chart deploy each of its images."""

    def __init__(self, root, graph, documents, work, options):
        self.name, self.root, self.graph, self.work, self.options = root.name, root, graph, work, options
        self.copies = {}
        # The images of each whole render, each with the alias path of its owner.
        self.whole = {}
        for document in documents:
            chart, case = document.render.split("/")
            if chart == self.name:
                for image in document.images:
                    self.whole.setdefault(case, set()).add((image, document.path))
        self.names_images = any(owner == self.name for _, owner in self.whole.get("defaults", ()))

    def images_of(self, case):
        return {image for image, _ in self.whole[case]}

    def scope_of(self, path):
        """The scope of a key path, None for a value of the chart itself when
        its own templates name no image: it cannot switch any."""
        keys = "/".join((self.name, *path, ""))
        scope = max((chart for chart in self.graph if keys.startswith(chart + "/")), key=len)
        return scope if scope != self.name or self.names_images or path[0] == "global" else None

    def plan(self):
        """The probes. A setting several fixtures share, or one that is a
        flip, is applied once."""
        probes, applied = [], set()

        def add(kind, fixture, path, value, values):
            text = re.sub(r"[\t\n]+", " ", value) if isinstance(value, str) else json.dumps(
                value, separators=(",", ":"), ensure_ascii=False)
            probe = Probe(kind, fixture, ".".join(path) + "=" + text, self.scope_of(path), values)
            if probe.scope and (kind == "drop" or probe.setting not in applied):
                applied.add(probe.setting)
                probes.append(probe)

        # The computed defaults, every subchart's under its alias, as a
        # template of the chart prints them.
        template = self.root / "templates" / "scan-values.yaml"
        template.write_text("{{ toJson .Values }}\n")
        defaults = helm_template(self.root, self.options.kube_version, "-s", "templates/scan-values.yaml")
        template.unlink()
        for path, value in flips(json.loads(defaults.stdout.splitlines()[-1])):
            add("flip", "", path, value, only(path, value))
        for case, fixture in fixtures(self.name).items():
            values = next(iter(read_yaml(fixture)), None) or {}
            for path, value in settings(values):
                add("set", case, path, value, only(path, value))
                add("drop", case, path, value, without(values, path))
        return probes

    def copy(self, scope):
        """A copy of the chart rendering only the templates of a scope and of
        the charts below, with the helpers of all. Hard links keep it cheap.
        No .helmignore: the archive is already filtered, and read as a
        directory the root one would apply to every subchart."""
        copied = self.work / scope.replace("/", "_") / self.name
        shutil.copytree(self.root, copied, copy_function=os.link)
        kept = copied / self.graph[scope].directory.relative_to(self.root)
        for directory, _, names in os.walk(copied):
            for name in names:
                file = Path(directory, name)
                is_helper = name.startswith("_") or name.endswith(".tpl")
                is_template = "templates" in file.parent.relative_to(copied).parts
                if name == ".helmignore" or (is_template and not is_helper and kept not in file.parents):
                    file.unlink()
        return copied

    def images(self, values, scope, case="defaults"):
        """The images of the chart over some values, rendered on the copy of
        a scope, then on the whole chart if that breaks; the other charts keep
        the images of the whole render of the case the values start from.
        None when it does not render, or renders no image, which proves
        nothing either."""
        result = helm_template(self.copies[scope], self.options.kube_version, values=values)
        if result.returncode != 0 and scope != self.name:
            scope = self.name
            result = helm_template(self.copies[scope], self.options.kube_version, values=values)
        if result.returncode != 0:
            return None
        images = {image for image, owner in self.whole[case] if not f"{owner}/".startswith(f"{scope}/")}
        for entry in manifest_documents(result.stdout):
            images.update(document_images(entry["content"])[0])
        return images or None

    def measure(self):
        """Runs the probes. A copy whose defaults do not render the images
        of the chart cannot stand in for it: its probes run on the whole
        chart."""
        probes = self.plan()
        scopes = sorted({self.name} | {probe.scope for probe in probes})
        self.copies = {scope: self.copy(scope) for scope in scopes}

        def run_probe(probe):
            # A drop starts from its fixture, which must have rendered.
            case = probe.fixture if probe.kind == "drop" else "defaults"
            if case in self.whole:
                probe.images = self.images(probe.values, probe.scope, case)

        with ThreadPoolExecutor(self.options.jobs) as pool:
            defaults = dict(zip(scopes, pool.map(lambda scope: self.images({}, scope), scopes)))
            for probe in probes:
                if defaults[probe.scope] != self.images_of("defaults"):
                    probe.scope = self.name
            list(pool.map(run_probe, probes))
        return probes

    def switch(self, image, probes):
        """What switches an image: `default`, what the defaults do with it
        (on or off), and `off_with` or `on_with`, the alternatives moving it
        away from that, ` | `-separated: each a <key>=<value> setting, or
        several joined by ` & ` that a fixture needs together."""
        on = image in self.images_of("defaults")
        alternatives, needs = [], {}
        for probe in probes:
            if probe.images is None:
                continue
            moved = (image in probe.images) != on
            if probe.kind == "drop":
                if not moved:
                    needs.setdefault(probe.fixture, []).append(probe.setting)
            elif moved and not (on and probe.setting in ALWAYS_DEPLOYED):
                alternatives.append(probe.setting)
        # A fixture switching the image needs the settings whose drop moves it
        # back: an alternative, unless one of them switches the image alone or
        # an alternative holds them already. The fixture's file stands for an
        # image nothing else could be tied to.
        files = []
        for fixture in dict.fromkeys(probe.fixture for probe in probes if probe.fixture in self.whole):
            if (image in self.images_of(fixture)) != on:
                files.append(f"ci/{fixture}-values.yaml")
                needed = needs.get(fixture, [])
                together = " & ".join(needed)
                if needed and not set(needed) & set(alternatives) and together not in " | ".join(alternatives):
                    alternatives.append(together)
        with_values = " | ".join(alternatives or files)
        return {"default": "on" if on else "off", "off_with": with_values if on else "",
                "on_with": "" if on else with_values}

    def add_to(self, images):
        """Adds its switch to each image the chart deploys, and warns about
        the others: the report takes the chart's point of view, so its
        fixtures must reach every image."""
        probes = self.measure()
        deployed = set().union(*map(self.images_of, self.whole), *(probe.images for probe in probes if probe.images))
        for image in images:
            if image["image"] in deployed:
                image.update(self.switch(image["image"], probes))
            elif image["uses"] != ["operator"]:
                warn(f"{self.name} does not deploy {image['image']}",
                     f"only {','.join(image['uses'])} renders it: extend the ci fixtures of {self.name}")


# ---- Command line


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("-d", dest="dist", type=Path, default=HERE.parent / "dist", metavar="DIR",
                        help="directory holding the packaged charts (default: the repo's dist/)")
    parser.add_argument("-o", dest="out", type=Path, default=HERE.parent / "scan", metavar="DIR",
                        help="output directory, cleared first (default: the repo's scan/)")
    # test/matrix.sh's default: the compute plane refuses anything below 1.29.
    parser.add_argument("-k", dest="kube_version", default="1.31.0", metavar="VERSION",
                        help="Kubernetes version to render for")
    parser.add_argument("-s", dest="switch_chart", metavar="CHART",
                        help="also measure the values deciding which images CHART deploys, "
                             "a few hundred partial renders of it")
    parser.add_argument("-j", dest="jobs", type=int, default=os.cpu_count(), metavar="N",
                        help="renders run at once for -s (default: one per processor)")
    options = parser.parse_args()
    # The Python yq wrapper shares the name and takes jq syntax.
    if shutil.which("yq") is None or "mikefarah" not in run("yq", "--version", check=False).stdout:
        parser.error("needs mikefarah yq v4 (https://github.com/mikefarah/yq)")
    archives = sorted(options.dist.glob("*.tgz"))
    if not archives:
        parser.error(f"no packaged chart in {options.dist}; run package-charts.sh first")
    shutil.rmtree(options.out, ignore_errors=True)
    options.out.mkdir(parents=True)

    with tempfile.TemporaryDirectory() as scratch:
        renders, documents, switches, measured = [], [], None, None
        for archive in archives:
            unpacked = Path(scratch, archive.name)
            unpacked.mkdir()
            run("tar", "-xzf", archive, "-C", unpacked)
            (root,) = unpacked.iterdir()
            graph = chart_graph(root, root.name)
            for case, fixture in {"defaults": None, **fixtures(root.name)}.items():
                name = f"{root.name}/{case}"
                error, rendered = render(archive, name, fixture, graph, options.out, options.kube_version)
                renders.append({"render": name, "error": error})
                documents += rendered
            if root.name == options.switch_chart:
                switches = Switches(root, graph, documents, Path(scratch, "copies"), options)

        if not any(document.images for document in documents):
            sys.exit(f"{ME}: the charts reference no image, which means the extraction broke")
        images = image_list(documents)
        # An image-map repository needs a fixture deploying it.
        (common,) = read_yaml(HERE / "armonik-common" / "values.yaml")
        for repository in common["global"]["armonik"]["imageComponents"]:
            if not any(image["image"].startswith(repository + ":") for image in images):
                warn(f"{repository} is not scanned", "no fixture deploys this global.armonik.imageComponents entry: "
                     "extend armonik/ci/optional-images-values.yaml")
        if options.switch_chart and switches is None:
            parser.error(f"-s {options.switch_chart}: no such packaged chart in {options.dist}")
        if switches and "defaults" not in switches.whole:
            print(f"{ME}: {switches.name} does not render with its defaults, no switch", file=sys.stderr)
        elif switches:
            switches.add_to(images)
            measured = switches.name

    scan = {"renders": renders, "documents": [asdict(document) for document in documents], "images": images,
            "switch_chart": measured}
    (options.out / "scan.json").write_text(json.dumps(scan, indent=1) + "\n", encoding="utf-8")
    print(f"{ME}: {len(renders)} render(s), {len(images)} image(s), in {options.out}", file=sys.stderr)


if __name__ == "__main__":
    main()
