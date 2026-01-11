#!/bin/bash
set -e

# Collect all board/device pairs
ENTRIES=""
for hcdf in $(find . -name "*.hcdf" -type f ! -path "./process_request/*" | sort); do
  # Skip symlinks
  [ -L "$hcdf" ] && continue

  dir=$(dirname "$hcdf")
  device=$(basename "$dir")
  board=$(basename "$(dirname "$dir")")

  [ "$board" = "." ] && continue
  [ -z "$board" ] && continue

  ENTRIES="$ENTRIES$board|$device\n"
done

# Get unique board/device pairs
UNIQUE_ENTRIES=$(echo -e "$ENTRIES" | sort -u | grep -v '^$')

# Collect models
MODELS=$(ls -1 models/*.glb 2>/dev/null | xargs -I{} basename {} | sort)

# Generate index.html
cat > index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CogniPilot HCDF Models</title>
    <style>
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
            max-width: 800px;
            margin: 0 auto;
            padding: 2rem;
            background: #f5f5f5;
            color: #333;
        }
        h1 { color: #1a1a1a; }
        h2 { color: #444; margin-top: 2rem; }
        .board {
            background: white;
            border-radius: 8px;
            padding: 1.5rem;
            margin: 1rem 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .board h3 { margin-top: 0; color: #2563eb; }
        .files { font-family: monospace; font-size: 0.9rem; }
        .files a { color: #2563eb; text-decoration: none; }
        .files a:hover { text-decoration: underline; }
        code { background: #e5e5e5; padding: 0.2rem 0.4rem; border-radius: 4px; }
        pre { background: #e5e5e5; padding: 1rem; border-radius: 4px; overflow-x: auto; }
    </style>
</head>
<body>
    <h1>CogniPilot HCDF Models</h1>
    <p>
        Hardware Configuration Descriptive Format (HCDF) files and 3D models for CogniPilot hardware.
        These files are used by <a href="https://github.com/CogniPilot/dendrite">Dendrite</a> for 3D visualization.
    </p>

    <h2>Repository Structure</h2>
    <p>
        HCDF files are organized by board and device type, with SHA-prefixed versions for immutability:
    </p>
    <pre>{board}/{device}/{sha}-{device}.hcdf   # SHA-prefixed version (immutable)
{board}/{device}/{device}.hcdf          # Symlink to latest version</pre>
    <p>
        Models are stored in a flat <code>models/</code> directory with SHA-prefixed filenames:
    </p>
    <pre>models/{short_sha}-{name}.glb</pre>

    <h2>Available Boards</h2>
EOF

# Group by board and add sections
current_board=""
for entry in $UNIQUE_ENTRIES; do
  board=$(echo "$entry" | cut -d'|' -f1)
  device=$(echo "$entry" | cut -d'|' -f2)

  if [ "$board" != "$current_board" ]; then
    # Close previous board section if any
    if [ -n "$current_board" ]; then
      echo "            </ul>" >> index.html
      echo "        </div>" >> index.html
      echo "    </div>" >> index.html
    fi

    # Start new board section
    display_name=$(echo "$board" | tr '_' '-' | tr '[:lower:]' '[:upper:]')
    echo "" >> index.html
    echo "    <div class=\"board\">" >> index.html
    echo "        <h3>$display_name</h3>" >> index.html
    echo "        <div class=\"files\">" >> index.html
    echo "            <p><strong>HCDF Fragments:</strong></p>" >> index.html
    echo "            <ul>" >> index.html
    current_board="$board"
  fi

  echo "                <li><a href=\"$board/$device/$device.hcdf\">$device/$device.hcdf</a></li>" >> index.html
done

# Close last board section
if [ -n "$current_board" ]; then
  echo "            </ul>" >> index.html
  echo "        </div>" >> index.html
  echo "    </div>" >> index.html
fi

# Add models section
echo "" >> index.html
echo "    <h2>Models</h2>" >> index.html
echo "    <div class=\"board\">" >> index.html
echo "        <div class=\"files\">" >> index.html
echo "            <ul>" >> index.html
for model in $MODELS; do
  echo "                <li><a href=\"models/$model\">$model</a></li>" >> index.html
done
echo "            </ul>" >> index.html
echo "        </div>" >> index.html
echo "    </div>" >> index.html

# Add footer
cat >> index.html << 'EOF'

    <h2>URL Format</h2>
    <p>
        Devices report their HCDF URL via MCUmgr. URL formats:
    </p>
    <pre># Latest version (uses symlink):
https://hcdf.cognipilot.org/{board}/{device}/{device}.hcdf

# Pinned version (immutable):
https://hcdf.cognipilot.org/{board}/{device}/{sha}-{device}.hcdf</pre>
    <p>
        Models are referenced from HCDF files with their SHA-prefixed paths:
    </p>
    <pre>&lt;model href="models/{short_sha}-{name}.glb" sha="{full_sha}"/&gt;</pre>

    <h2>HCDF Schema</h2>
    <p>
        HCDF files follow the <a href="https://github.com/CogniPilot/cps_describe">CPS Describe</a> schema.
        Each fragment defines visuals (3D models) and reference frames for a specific board/application combination.
    </p>

    <footer style="margin-top: 3rem; padding-top: 1rem; border-top: 1px solid #ddd; color: #666; font-size: 0.9rem;">
        <p>CogniPilot Project - <a href="https://cognipilot.org">cognipilot.org</a></p>
    </footer>
</body>
</html>
EOF

echo "Updated index.html"
