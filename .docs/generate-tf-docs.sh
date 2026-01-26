#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TFDOCS="${TFDOCS:-terraform-docs}"

# Convert relative path to absolute (resolve from current working directory)
[[ "$TFDOCS" != /* ]] && TFDOCS="$(cd "$(dirname "$TFDOCS")" && pwd)/$(basename "$TFDOCS")"

echo "Generating terraform docs with: $TFDOCS"

find "$PROJECT_ROOT" -name "*.tf" -type f -not -path "*/.terraform/*" -not -path "*/charts/*" -not -path "*/.docs/*" -exec dirname {} \; | sort -u | while read dir; do
  cd "$dir"
  # Use indent 3 for examples, indent 2 for others
  indent=$([[ "$dir" == *"/examples"* ]] && echo "3" || echo "2")
  "$TFDOCS" markdown table --lockfile=false --output-mode inject --output-file README.md --header-from main.tf --indent "$indent" .
done

echo "Done!"
