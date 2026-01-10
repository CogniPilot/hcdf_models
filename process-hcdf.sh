#!/bin/bash
# Process new HCDF files: compute SHA, rename, and update symlinks
#
# Usage: ./process-hcdf.sh
#
# This script finds all files matching "new-*.hcdf" in board/device folders,
# computes their SHA256, renames them to "{sha}-{name}.hcdf", and updates
# the symlink "{name}.hcdf" to point to the new version.
#
# Example:
#   Before: mr_mcxn_t1/optical-flow/new-optical-flow.hcdf
#   After:  mr_mcxn_t1/optical-flow/a1b2c3d4-optical-flow.hcdf
#           mr_mcxn_t1/optical-flow/optical-flow.hcdf -> a1b2c3d4-optical-flow.hcdf

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

found=0

# Find all new-*.hcdf files
while IFS= read -r -d '' new_file; do
    found=1
    dir=$(dirname "$new_file")
    filename=$(basename "$new_file")

    # Extract the base name (remove "new-" prefix)
    base_name="${filename#new-}"
    name="${base_name%.hcdf}"

    # Compute SHA256 (first 8 characters)
    sha=$(sha256sum "$new_file" | cut -c1-8)

    # New filename with SHA prefix
    sha_filename="${sha}-${base_name}"
    sha_path="${dir}/${sha_filename}"
    symlink_path="${dir}/${base_name}"

    # Check if this SHA version already exists
    if [ -f "$sha_path" ]; then
        echo "Warning: $sha_path already exists, skipping $new_file"
        continue
    fi

    # Rename new file to SHA-prefixed version
    mv "$new_file" "$sha_path"
    echo "Renamed: $new_file -> $sha_path"

    # Update symlink to point to new version
    rm -f "$symlink_path"
    ln -sf "$sha_filename" "$symlink_path"
    echo "Symlink: $symlink_path -> $sha_filename"

    echo ""
done < <(find . -name "new-*.hcdf" -print0)

if [ $found -eq 0 ]; then
    echo "No new-*.hcdf files found."
    echo ""
    echo "To add a new HCDF version:"
    echo "  1. Create/edit: {board}/{device}/new-{device}.hcdf"
    echo "  2. Run: ./process-hcdf.sh"
    echo ""
    echo "Example:"
    echo "  cp mr_mcxn_t1/optical-flow/optical-flow.hcdf mr_mcxn_t1/optical-flow/new-optical-flow.hcdf"
    echo "  # Edit new-optical-flow.hcdf"
    echo "  ./process-hcdf.sh"
fi
