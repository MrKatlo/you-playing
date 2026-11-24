"""Clean the supplied cockroach download for runtime use in Basement Farm.

The downloaded GLB includes Blender's default cube, camera and light alongside
the actual Model mesh.  This script keeps only that mesh and re-exports a
self-contained GLB, leaving the original user-provided download untouched.
"""

import bpy
import os


ROOT = r"C:\Users\user\Documents\horror"
SOURCE = os.path.join(
    ROOT,
    "assets",
    "models",
    "basement",
    "cockroach",
    "source",
    "Cockroach 3d model free.glb",
)
OUTPUT = os.path.join(
    ROOT,
    "assets",
    "models",
    "basement",
    "cockroach",
    "cockroach_clean.glb",
)


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def main():
    clear_scene()
    bpy.ops.import_scene.gltf(filepath=SOURCE)

    # The downloadable asset's real geometry is the mesh named Model. Keep the
    # selection deliberately strict so the default Cube is never a passenger in
    # the in-game colony.
    source_mesh = bpy.data.objects.get("Model")
    if source_mesh is None or source_mesh.type != "MESH":
        raise RuntimeError("The supplied cockroach GLB did not contain its Model mesh.")

    for obj in list(bpy.context.scene.objects):
        if obj != source_mesh:
            bpy.data.objects.remove(obj, do_unlink=True)

    source_mesh.name = "CockroachMesh"
    source_mesh.data.name = "CockroachMeshGeometry"
    source_mesh.parent = None
    # The mesh keeps its source orientation. The Godot colony controller rotates
    # the model once into tray space, then handles the scuttling motion.
    bpy.context.view_layer.objects.active = source_mesh
    source_mesh.select_set(True)

    os.makedirs(os.path.dirname(OUTPUT), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=OUTPUT,
        export_format="GLB",
        export_materials="EXPORT",
        export_apply=True,
        export_cameras=False,
        export_lights=False,
        export_extras=True,
    )
    print("Clean cockroach GLB written to", OUTPUT)


if __name__ == "__main__":
    main()
