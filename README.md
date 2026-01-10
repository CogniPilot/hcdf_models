# CogniPilot HCDF Models

Hardware Configuration Descriptive Format (HCDF) files and 3D models for CogniPilot hardware. These files are served via GitHub Pages at [hcdf.cognipilot.org](https://hcdf.cognipilot.org).

## Purpose

This repository hosts HCDF fragment files and associated GLB 3D models that are fetched by [Dendrite](https://github.com/CogniPilot/dendrite) for hardware visualization. Devices report their HCDF URL via MCUmgr, and Dendrite downloads and caches the files.

## Directory Structure

Models are stored in a flat `models/` directory with SHA-prefixed filenames for deduplication and version coexistence:

```
/
├── index.html                      # Landing page
├── CNAME                           # Custom domain configuration
├── models/                         # All GLB models (flat, SHA-prefixed)
│   ├── {short_sha}-{name}.glb
│   └── ...
├── {board}/                        # HCDF fragments per board
│   ├── {app}.hcdf
│   └── default.hcdf                # Fallback for unknown apps
```

Example:
```
models/
├── fbf4836d-mcxnt1hub.glb
├── 72eef172-optical_flow.glb
└── 47b58869-rtk_f9p.glb
mr_mcxn_t1/
├── optical-flow.hcdf
├── rtk-gnss.hcdf
└── default.hcdf
```

## SHA-Prefixed Model Names

Model files use the format `{short_sha}-{name}.glb` where:
- `short_sha` is the first 8 characters of the file's SHA256 hash
- `name` is the original model filename

Benefits:
- **Deduplication**: Same content = same SHA = single file
- **Version coexistence**: Multiple versions of the same logical model can exist
- **Cache-friendly**: Filename encodes content identity

## URL Format

Devices report their HCDF URL via MCUmgr:

```
https://hcdf.cognipilot.org/{board}/{app}.hcdf
```

Example: `https://hcdf.cognipilot.org/mr_mcxn_t1/optical-flow.hcdf`

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

## Adding New Models (Automated)

The easiest way to add new models is using the `process_request/` folder:

1. Add your `.glb` and `.hcdf` files to `process_request/`
2. Name HCDF files as `{board}-{app}.hcdf` (e.g., `mr_mcxn_t1-optical-flow.hcdf`)
3. Reference models in HCDF with just the filename (no SHA prefix needed)
4. Push to main branch

The GitHub Action will automatically:
- Compute SHA256 for each GLB file
- Rename GLBs to `{short_sha}-{name}.glb`
- Move GLBs to `models/` directory
- Update HCDF files with correct `href` and `sha` attributes
- Move HCDFs to `{board}/` directory
- Remove processed files from `process_request/`

Example input HCDF (before processing):
```xml
<visual name="board">
  <model href="mcxnt1hub.glb"/>
</visual>
```

After processing, it becomes:
```xml
<visual name="board">
  <model href="models/fbf4836d-mcxnt1hub.glb" sha="fbf4836d0f08..."/>
</visual>
```

## Adding New Models (Manual)

1. Compute SHA256: `sha256sum model.glb`
2. Rename with short SHA: `mv model.glb {first8chars}-model.glb`
3. Move to `models/` directory
4. Reference in HCDF with full path and SHA

## Adding a New Board

1. Create a directory: `mkdir {board_name}`
2. Add HCDF fragments: `{board_name}/{app}.hcdf`
3. Add models to `models/` with SHA-prefixed names
4. Update HCDF files to reference the models
5. Push to main branch (auto-deploys via GitHub Pages)

Or use the automated workflow by adding files to `process_request/`.

## Local Caching

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

## License

Apache 2.0 - See [LICENSE](LICENSE)
