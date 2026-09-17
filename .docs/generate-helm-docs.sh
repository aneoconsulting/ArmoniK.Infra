#!/bin/sh
# POSIX-compliant script to generate helm-docs for all charts
set -eu

HELMDOCS="${HELMDOCS:-helm-docs}"

# A template file given as a bare name is looked up in each chart directory, one
# prefixed with ./ is relative to the search root. Neither has to exist: without
# any of them helm-docs falls back to its built-in template.
#
# --document-dependency-values only reaches dependencies helm-docs can read from
# disk, so our own file:// subcharts are documented and the third-party ones,
# vendored as archives, are not. Their values belong to their upstream docs anyway.
"$HELMDOCS" \
    --chart-search-root=charts \
    --template-files=./_templates.gotmpl \
    --template-files=README.md.gotmpl \
    --document-dependency-values \
    --skip-version-footer
