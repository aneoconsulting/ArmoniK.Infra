#!/bin/sh
# shellcheck shell=sh

set -eu

# =============================================================================
# Configuration
# =============================================================================
DOCS_DIR=".docs" # Cannot contains slashes

# Check if a string is a known provider
is_provider() {
    case "$1" in
        aws|gcp|onpremise|armonik) return 0 ;;
        *) return 1 ;;
    esac
}

# Get display name for provider
get_provider_display_name() {
    local provider="$1"
    case "$provider" in
        aws) echo "AWS" ;;
        gcp) echo "GCP" ;;
        onpremise) echo "On-Premise" ;;
        armonik) echo "ArmoniK" ;;
        *) echo "$provider" ;;
    esac
}

# =============================================================================
# Helpers
# =============================================================================

# Convert string to title case (e.g., "my-category" -> "My Category")
to_title_case() {
    echo "$1" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g'
}

# =============================================================================
# Path Resolution
# =============================================================================


# Main path resolver - determines symlink path based on README location
# Strategy: find the provider in the path, move it to the front, keep the rest
symlink_readme() {
    local readme_path result part
    readme_path="$1"

    link=""
    target="$readme_path"
    while true; do
        # Split on first / and exit loops if none left
        part="${readme_path%%/*}"
        [ "$part" != "$readme_path" ] || break
        readme_path="${readme_path#*/}"

        if is_provider "$part"; then
            link="$part${link:+/}$link"
        else
            link="$link${link:+/}$part"
        fi
        target="../$target"
    done

    mkdir -p "$DOCS_DIR/$link"
    ln -s "../$target" "$DOCS_DIR/$link/index.md"
}

# =============================================================================
# Index Generation
# =============================================================================

# Generate an index file for a directory using glob pattern
generate_index_file() {
    local dir_path="$1"
    local index_file="$dir_path/index.md"

    # Skip if index already exists (symlink or file)
    [ ! -e "$index_file" ] || return 0

    # Check if directory has subdirectories with index files
    [ "$(find . -maxdepth 2 -type f -name 'index.md')" != "" ] || return 0

    # Extract provider from path (first component after .docs/)
    local rel_path="${dir_path#$DOCS_DIR/}"
    local first_component="${rel_path%%/*}"
    local provider_display=""

    # Check if first component is a provider
    provider_display="$(get_provider_display_name "$first_component")"

    # Generate title from directory name
    local dir_name title
    dir_name="$(basename "$dir_path")"
    title="$(to_title_case "$dir_name")"

    # Prepend provider if applicable and not the provider directory itself
    if [ -n "$provider_display" -a "$dir_name" != "$first_component" ]; then
        title="$provider_display $title"
    fi

    cat > "$index_file" << EOF
# $title

\`\`\`{toctree}
:maxdepth: 2
:glob:

*/index
\`\`\`
EOF
}

# Recursively generate missing index files for all directories
generate_missing_indexes() {
    local base_dir="$1"

    # Process directories bottom-up (deepest first) so parent indexes include children
    find "$DOCS_DIR" -depth -type d -and -not -path '*examples*' | while IFS= read -r dir; do
        generate_index_file "$dir"
    done
}

# =============================================================================
# Main Script
# =============================================================================

main() {

    # Validate docs directory exists
    if [ ! -d "$DOCS_DIR" ]; then
        exit 1
    fi

    # Clean up existing symlinks and empty directories
    find "$DOCS_DIR" -type l -delete 2>/dev/null || true
    find "$DOCS_DIR" -type d -empty -delete 2>/dev/null || true

    find . -type f -name "README.md" \
            -not -path "./README.md" \
            -not -path "./.docs/*" \
            -not -path "./.git/*" \
            -not -path "./build/*" \
            -not -path "./_build/*" \
            -not -path "./node_modules/*" \
            -not -path "./terraform-docs/*" \
            -not -path "./charts/*" |
        while IFS= read -r readme_path; do
        # Strip leading ./
        readme_path="${readme_path#./}"

        symlink_readme "$readme_path"
    done

    # Generate missing index files for all directories
    generate_missing_indexes "$DOCS_DIR"
}

# Run main function
main "$@"
