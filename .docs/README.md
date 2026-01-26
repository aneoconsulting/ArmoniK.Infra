# ArmoniK.Infra Documentation

This directory contains the Sphinx documentation for ArmoniK.Infra.

## How It Works

The documentation is automatically generated from the Terraform module READMEs using symlinks and auto-generated category indexes.

### Directory Structure

```
.docs/
├── index.md                      # Main documentation index
├── conf.py                       # Sphinx configuration
├── requirements.txt              # Python dependencies
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
├── armonik/                      # ArmoniK charts
└── utils/                        # Utility modules
```

### Symlink Generation

The `generate-docs-symlinks.sh` script (in the project root) does two things:

1. **Creates symlinks** from `.docs/<provider>/<category>/<module>/index.md` to the actual `README.md` files in the source tree
2. **Generates category index files** (e.g., `.docs/aws/storage/index.md`) with toctrees pointing to all modules in that category

This allows:
- Single source of truth (module READMEs)
- Automatic documentation structure organized by provider
- No manual maintenance of documentation indexes

### ReadTheDocs Build Process

On RTD, the build process (defined in `.readthedocs.yaml`):

1. Generates Terraform documentation with `terraform-docs`
2. Runs `generate-docs-symlinks.sh` to create symlinks and category indexes
3. Builds the Sphinx documentation

## Building Documentation Locally

### Prerequisites

```bash
pip install -r requirements.txt
```

### Generate Symlinks

Before building, generate the symlinks and category indexes:

```bash
# From project root
bash generate-docs-symlinks.sh
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

## Adding New Modules

When you add a new Terraform module:

1. Create the module with a `README.md` (terraform-docs will generate it)
2. Run `generate-docs-symlinks.sh` - it will automatically:
   - Create a symlink for the new module
   - Update the category index to include it
3. No manual documentation changes needed

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
