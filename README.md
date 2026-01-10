# CogniPilot HCDF Models

Hardware Configuration Descriptive Format (HCDF) files and 3D models for CogniPilot hardware. These files are served via GitHub Pages at [hcdf.cognipilot.org](https://hcdf.cognipilot.org).

## Purpose

This repository hosts HCDF fragment files and associated GLB 3D models that are fetched by [Dendrite](https://github.com/CogniPilot/dendrite) for hardware visualization. Devices report their HCDF URL via MCUmgr, and Dendrite downloads and caches the files.

## Directory Structure

HCDF files are organized by board and device, with SHA-prefixed versions for content addressing:

```
/
├── index.html                           # Landing page
├── CNAME                                # Custom domain configuration
├── cmake/                               # CMake module for Zephyr builds
│   ├── CMakeLists.txt
│   └── hcdf.cmake
├── zephyr/                              # Zephyr module metadata
│   └── module.yml
├── models/                              # All GLB models (flat, SHA-prefixed)
│   ├── {short_sha}-{name}.glb
│   └── ...
├── process-hcdf.sh                      # Script to process new HCDF files
├── {board}/                             # HCDF fragments per board
│   └── {device}/                        # Device-specific folder
│       ├── {sha}-{device}.hcdf          # SHA-versioned HCDF file
│       └── {device}.hcdf -> ...         # Symlink to current version
```

Example:
```
models/
├── fbf4836d-mcxnt1hub.glb
├── 72eef172-optical_flow.glb
└── 47b58869-rtk_f9p.glb
mr_mcxn_t1/
├── optical-flow/
│   ├── a8321a14-optical-flow.hcdf
│   └── optical-flow.hcdf -> a8321a14-optical-flow.hcdf
├── rtk-gnss/
│   ├── 87950c40-rtk-gnss.hcdf
│   └── rtk-gnss.hcdf -> 87950c40-rtk-gnss.hcdf
└── default/
    ├── 0e9f49cf-default.hcdf
    └── default.hcdf -> 0e9f49cf-default.hcdf
```

## URL Format

Devices report their HCDF URL via MCUmgr:

```
https://hcdf.cognipilot.org/{board}/{device}/{device}.hcdf
```

Example: `https://hcdf.cognipilot.org/mr_mcxn_t1/optical-flow/optical-flow.hcdf`

The symlink resolves to the current SHA-versioned file.

## SHA-Versioned HCDF Files

HCDF files use the format `{short_sha}-{name}.hcdf` where:
- `short_sha` is the first 8 characters of the file's SHA256 hash
- `name` is the device name

Benefits:
- **Content addressing**: Same content = same SHA = easily verifiable
- **Version coexistence**: Multiple versions can exist simultaneously
- **Cache-friendly**: SHA in filename enables reliable caching
- **Symlink for latest**: `{device}.hcdf` symlink always points to current version

## Adding or Updating HCDF Files

### Method 1: Using process-hcdf.sh (Recommended)

1. Create or edit a file with `new-` prefix:
   ```bash
   cp mr_mcxn_t1/optical-flow/optical-flow.hcdf mr_mcxn_t1/optical-flow/new-optical-flow.hcdf
   # Edit new-optical-flow.hcdf
   ```

2. Run the processing script:
   ```bash
   ./process-hcdf.sh
   ```

   The script will:
   - Compute SHA256 of the new file
   - Rename it to `{sha}-{device}.hcdf`
   - Update the symlink to point to the new version

### Method 2: Manual

1. Compute SHA256: `sha256sum new-file.hcdf`
2. Rename with short SHA: `mv new-file.hcdf {first8chars}-device.hcdf`
3. Update symlink: `ln -sf {first8chars}-device.hcdf device.hcdf`

## Using as a Zephyr Module

Add to your `west.yml`:

```yaml
- name: hcdf_models
  remote: cognipilot
  revision: main
  path: modules/lib/hcdf_models
```

### CMake Integration

The module provides a CMake helper to configure HCDF MCUmgr options:

```cmake
# In your application's CMakeLists.txt (after find_package(Zephyr))
include(${ZEPHYR_HCDF_MODELS_MODULE_DIR}/cmake/hcdf.cmake)
hcdf_configure(
  BOARD mr_mcxn_t1
  DEVICE optical-flow
)
```

This automatically:
- Sets `CONFIG_MCUMGR_GRP_HCDF_URL` to the correct URL
- Extracts the SHA from the local symlinked file
- Sets `CONFIG_MCUMGR_GRP_HCDF_SHA` to match

Or configure manually in `prj.conf`:
```
CONFIG_MCUMGR_GRP_HCDF=y
CONFIG_MCUMGR_GRP_HCDF_URL="https://hcdf.cognipilot.org/mr_mcxn_t1/optical-flow/optical-flow.hcdf"
CONFIG_MCUMGR_GRP_HCDF_SHA="a8321a14"
```

## HCDF Fragment Format

Each HCDF file defines visuals (3D models) and reference frames:

```xml
<?xml version="1.0"?>
<hcdf version="1.2">
  <comp name="sensor-assembly" role="sensor">
    <description>Human-readable description</description>

    <visual name="board">
      <pose>x y z roll pitch yaw</pose>
      <model href="models/fbf4836d-mcxnt1hub.glb" sha="fbf4836d0f08..."/>
    </visual>

    <frame name="sensor">
      <description>Reference frame description</description>
      <pose>x y z roll pitch yaw</pose>
    </frame>
  </comp>
</hcdf>
```

- Pose format: `x y z roll pitch yaw` (meters and radians, SDF convention)
- Model href includes SHA-prefixed path
- Full SHA in `sha` attribute for cache validation

## Adding New Models (GLB files)

Use the `process_request/` folder for automated processing:

1. Add your `.glb` and `.hcdf` files to `process_request/`
2. Name HCDF files as `{board}-{device}.hcdf` (e.g., `mr_mcxn_t1-optical-flow.hcdf`)
3. Reference models in HCDF with just the filename (no SHA prefix)
4. Push to main branch

The GitHub Action will automatically:
- Compute SHA256 for each GLB file
- Rename GLBs to `{short_sha}-{name}.glb`
- Move GLBs to `models/` directory
- Update HCDF files with correct `href` and `sha` attributes
- Create device folder and move HCDF with SHA prefix

## Local Caching (Dendrite)

Dendrite caches fetched HCDF files and models in `~/.cache/dendrite/fragments/`:

```
fragments/
├── manifest.json           # Cache index with SHA mappings
├── {hcdf_sha}.hcdf         # Cached HCDF files (named by content SHA)
└── models/                 # Cached models (flat, SHA-prefixed)
    └── {short_sha}-{name}.glb
```

The cache uses SHA-based deduplication - if a model is shared between multiple HCDFs, it's only stored once.

## Available Boards

- **mr_mcxn_t1** - MCU development board with T1 Ethernet
  - `optical-flow` - Optical flow sensor assembly
  - `rtk-gnss` - RTK GNSS receiver
  - `default` - Default/fallback configuration

## License

Apache 2.0 - See [LICENSE](LICENSE)
