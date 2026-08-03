# ArmoniK.Infra Documentation

This directory contains the Sphinx documentation for ArmoniK.Infra.

## How It Works

The documentation is automatically generated from the Terraform module READMEs and the Helm chart
READMEs using symlinks and auto-generated category indexes.

Both kinds of README are generated artifacts and are therefore **not committed**: `terraform-docs`
injects its section into the committed module README skeleton (the `pre-commit` hook strips the
injected part back out before a commit), and `helm-docs` writes the chart README in full, so
`charts/*/README.md` is git-ignored altogether. Everything is regenerated at the start of every
ReadTheDocs build.

### Directory Structure

```
.docs/
├── index.md                      # Main documentation index
├── conf.py                       # Sphinx configuration
├── requirements.txt              # Python dependencies
├── _static/
│   └── custom.css                # Widens the content area for the generated tables
│
├── aws/                          # AWS provider
│   ├── storage/
│   │   ├── index.md              # Auto-generated category index
│   │   ├── s3/
│   │   │   └── index.md          # Symlink -> storage/aws/s3/README.md
│   │   ├── efs/
│   │   │   └── index.md          # Symlink -> storage/aws/efs/README.md
│   │   └── ...
│   ├── networking/
│   │   ├── index.md              # Auto-generated category index
│   │   ├── vpc/
│   │   │   └── index.md          # Symlink -> networking/aws/vpc/README.md
│   │   └── ...
│   └── ...
│
├── gcp/                          # GCP provider (same structure)
├── on-premise/                   # On-premise provider (same structure)
├── armonik/                      # ArmoniK module
├── utils/                        # Utility modules
│
└── charts/                       # Helm charts
    ├── index.md                  # Auto-generated category index
    ├── armonik/
    │   └── index.md              # Symlink -> charts/armonik/README.md
    └── ...
```

### Symlink Generation

The `generate-docs-symlinks.sh` script does two things:

1. **Creates symlinks** from `.docs/<provider>/<category>/<module>/index.md` to the actual `README.md` files in the source tree. Chart READMEs keep their path instead, at `.docs/charts/<chart>/index.md`
2. **Generates category index files** (e.g., `.docs/aws/storage/index.md`) with toctrees pointing to all modules in that category

This allows:
- Single source of truth (module READMEs)
- Automatic documentation structure organized by provider
- No manual maintenance of documentation indexes

### ReadTheDocs Build Process

On RTD, the build process (defined in `.readthedocs.yaml`):

1. Downloads the `terraform-docs` and `helm-docs` binaries
2. Generates the Terraform module READMEs with `generate-tf-docs.sh`
3. Generates the Helm chart READMEs with `generate-helm-docs.sh`
4. Runs `generate-docs-symlinks.sh` to create symlinks and category indexes
5. Builds the Sphinx documentation

## Building Documentation Locally

### Prerequisites

```bash
pip install -r requirements.txt
```

### Generate the READMEs and the Symlinks

Before building, generate the READMEs, then the symlinks and category indexes. This needs
`terraform-docs` and `helm-docs` on the `PATH`, or `TFDOCS`/`HELMDOCS` pointing at them:

```bash
# From project root
bash .docs/generate-tf-docs.sh
bash .docs/generate-helm-docs.sh
bash .docs/generate-docs-symlinks.sh
```

### Build HTML Documentation

```bash
# From .docs directory
sphinx-build -b html . _build/html
```

Then open `_build/html/index.html` in your browser.

### Live Preview (Auto-reload)

```bash
make livehtml
```

Then open http://127.0.0.1:8000 in your browser.

### Check Links

```bash
make linkcheck
```

## Adding New Modules and Charts

When you add a new Terraform module:

1. Create the module with a `README.md` (terraform-docs will generate it)
2. Run `generate-docs-symlinks.sh` - it will automatically:
   - Create a symlink for the new module
   - Update the category index to include it
3. No manual documentation changes needed

When you add a new Helm chart:

1. `helm-docs` picks it up on its own, as long as the chart directory has a `Chart.yaml` **and** a
   `values.yaml`. It silently skips a chart missing the latter
2. Add `charts/<chart>/index` to the `Helm Charts` toctree in `index.md`. That list is explicit
   because the charts are ordered by deployment role rather than alphabetically. Forgetting it
   leaves the page orphaned, which Sphinx reports as `document isn't included in any toctree`

To document a chart beyond its metadata and values, add per-value `# -- ` comments in `values.yaml`,
or a `README.md.gotmpl` template in the chart directory.

`charts/_templates.gotmpl` holds the overrides of the helm-docs built-in templates that apply to
every chart, currently the values table, whose cells it escapes so that a default holding a template
pipeline does not spill into the next column.

## Troubleshooting

### Symlinks Not Working

If symlinks appear broken:

```bash
# Regenerate all symlinks
bash generate-docs-symlinks.sh
```

### Build Warnings

Cross-reference warnings from terraform-docs generated content are normal and can be ignored. The build will still succeed.

### Clean Rebuild

```bash
cd .docs
rm -rf _build
sphinx-build -b html . _build/html
```
