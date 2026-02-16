#!/bin/sh
# POSIX-compliant script to create symlinks for ReadTheDocs
# Maps module READMEs to .docs/<provider>/<category>/<module>/index.md
set -eu

is_provider() {
    case "$1" in aws|gcp|onpremise|armonik) return 0;; esac
    return 1
}

symlink_readme() {
    readme="$1"
    link=""
    target="$readme"

    # Parse path and move provider to front
    while true; do
        part="${readme%%/*}"
        [ "$part" != "$readme" ] || break
        readme="${readme#*/}"

        if is_provider "$part"; then
            link="$part${link:+/}$link"  # Provider goes first
        else
            link="${link:+$link/}$part"  # Others append
        fi
        target="../$target"
    done

    mkdir -p ".docs/$link"
    ln -s "../$target" ".docs/$link/index.md"
}

generate_index() {
    dir="$1"
    index="$dir/index.md"

    # Skip if index already exists
    [ ! -e "$index" ] || return 0

    # Skip if no subdirectories
    [ "$(find "$dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)" ] || return 0

    # Generate title from directory name (convert hyphens to spaces, capitalize)
    dirname=$(basename "$dir")
    title=$(echo "$dirname" | tr '-' ' ' | awk '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)}} 1')

    # Create toctree index
    cat > "$index" << EOF
# $title

\`\`\`{toctree}
:maxdepth: 2
:glob:

*/index
\`\`\`
EOF
}

# Clean old symlinks
find .docs -type l -delete
find .docs -type d -empty -delete

# Find all module READMEs and create symlinks
find . -name "README.md" \
    -not -path "./README.md" \
    -not -path "./.docs/*" \
    -not -path "./.git/*" \
    -not -path "./build/*" \
    -not -path "./_build/*" \
    -not -path "./node_modules/*" \
    -not -path "./terraform-docs/*" \
    -not -path "./charts/*" |
    while read -r f; do
        symlink_readme "${f#./}"
    done

# Generate category index files (bottom-up for nested structure)
find .docs -depth -type d -not -path '*examples*' |
    while read -r d; do
        generate_index "$d"
    done
