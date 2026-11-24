# Basement Farm generated-asset source

This is the Basement-owned version of the Riverborn asset workflow: source mesh
builders, purposeful rigs, named procedural clips, GLB export, structural
validation, and visual previews. It is source-of-truth for new generated
Basement Farm props and creatures; Godot consumes the generated GLBs.

## Build

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python build.py
```

The build writes generated files under `../../generated/`, beginning with:

- `creatures/slime/basement_slime.glb`
- `props/salvaged_workbench.glb`
- `props/wall_insulation_patch.glb`
- `props/hunt_snare.glb`
- `props/warm_storage_rack.glb`
- `props/frozen_maintenance_portal.glb`
- `props/frozen_maintenance_cart.glb`
- `documentation/asset_manifest.json`

When a Pillow-enabled Python is available, the build also writes
`documentation/previews/basement_slime_poses.png`. The authoritative visual
check remains the Godot screenshot runner, so missing Pillow never blocks GLB
creation or runtime QA.

## Source ownership

The reusable exporter, mesh, rig, shading, validation, and preview modules are
adapted from the supplied Riverborn generator pattern. Basement-specific
palette, creature anatomy, clips, and build registry live alongside them and
do not require Riverborn at game runtime.
