"""Export the supplied Riverborn cricket and gecko source assets for Basement Farm.

Riverborn's gecko intentionally uses its low water-snake rig.  Both source GLBs
also carry Blender's default cube, camera, light and a large preview icosphere;
those objects are removed here while preserving the animal armature, materials,
and animation clips.  The Riverborn project itself is never modified.
"""

import bpy
import os


HORROR_ROOT = r"C:\Users\user\Documents\horror"
RIVERBORN_ROOT = r"C:\Users\user\Documents\new-game-project\riverborn"
ANIMALS = {
    "cricket": (
        os.path.join(RIVERBORN_ROOT, "otter_lowpoly_asset_pack", "animals", "cricket", "cricket.glb"),
        os.path.join(HORROR_ROOT, "assets", "models", "basement", "riverborn_animals", "cricket.glb"),
    ),
    "gecko": (
        os.path.join(RIVERBORN_ROOT, "otter_lowpoly_asset_pack", "animals", "water_snake", "water_snake.glb"),
        os.path.join(HORROR_ROOT, "assets", "models", "basement", "riverborn_animals", "gecko.glb"),
    ),
}
PREVIEW_OBJECTS = {"Cube", "Camera", "Light", "Icosphere"}


def clear_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    # The Blender process exports both animals in one run.  Animation actions
    # survive object deletion, so clear them as well; otherwise cricket tracks
    # are offered against the gecko rig during the second export.
    for action in list(bpy.data.actions):
        bpy.data.actions.remove(action)


def export_animal(label: str, source: str, output: str) -> None:
    clear_scene()
    bpy.ops.import_scene.gltf(filepath=source)
    for obj in list(bpy.context.scene.objects):
        if obj.name in PREVIEW_OBJECTS:
            bpy.data.objects.remove(obj, do_unlink=True)

    armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if len(armatures) != 1 or len(meshes) != 1:
        raise RuntimeError(
            "%s source was expected to contain one rig and one animal mesh; got %d rigs / %d meshes"
            % (label, len(armatures), len(meshes))
        )

    os.makedirs(os.path.dirname(output), exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=output,
        export_format="GLB",
        export_materials="EXPORT",
        export_animations=True,
        export_apply=True,
        export_cameras=False,
        export_lights=False,
        export_extras=True,
    )
    print("Prepared %s -> %s" % (label, output))


def main() -> None:
    for label, (source, output) in ANIMALS.items():
        if not os.path.isfile(source):
            raise FileNotFoundError(source)
        export_animal(label, source, output)


if __name__ == "__main__":
    main()
