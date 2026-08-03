#!/bin/sh
# POSIX-compliant script to generate helm-docs for all charts
set -eu

HELMDOCS="${HELMDOCS:-helm-docs}"

# A template file given as a bare name is looked up in each chart directory, one
# prefixed with ./ is relative to the search root. Neither has to exist: without
# any of them helm-docs falls back to its built-in template.
"$HELMDOCS" \
    --chart-search-root=charts \
    --template-files=./_templates.gotmpl \
    --template-files=README.md.gotmpl
