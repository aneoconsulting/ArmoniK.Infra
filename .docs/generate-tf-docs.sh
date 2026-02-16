#!/bin/sh
# POSIX-compliant script to generate terraform-docs for all modules
set -eu

TFDOCS="${TFDOCS:-terraform-docs}"

find . -name "*.tf" -type f \
    -not -path "*/.terraform/*" \
    -not -path "*/charts/*" \
    -not -path "*/.docs/*" \
    -exec dirname {} \; |
    sort -u |
    while read -r dir; do
        case "$dir" in */examples/*) indent=3;; *) indent=2;; esac
        "$TFDOCS" markdown table \
            --lockfile=false \
            --output-mode inject \
            --output-file README.md \
            --header-from main.tf \
            --indent "$indent" \
            "$dir"
    done
