import bpy
import math
import os
from mathutils import Vector

OUTPUT_DIR = r"C:\Users\user\Documents\horror\assets\models\characters"


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)


def make_material(name, color, roughness=0.6, metallic=0.0, emission=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get("Principled BSDF")
    shader.inputs["Base Color"].default_value = (*color, 1.0)
    shader.inputs["Roughness"].default_value = roughness
    shader.inputs["Metallic"].default_value = metallic
    if emission:
        shader.inputs["Emission Color"].default_value = (*emission, 1.0)
        shader.inputs["Emission Strength"].default_value = 1.8
    return mat


def ellipsoid(name, location, scale, mat, subdivisions=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=subdivisions, radius=1.0, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    obj.data.materials.append(mat)
    return obj


def limb(name, start, end, radius, mat, vertices=10):
    start_vector = Vector(start)
    end_vector = Vector(end)
    delta = end_vector - start_vector
    midpoint = (start_vector + end_vector) * 0.5
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=delta.length, location=midpoint)
    obj = bpy.context.object
    obj.name = name
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = delta.to_track_quat("Z", "Y")
    obj.data.materials.append(mat)
    return obj


def claw(name, start, end, mat):
    return limb(name, start, end, 0.028, mat, 7)


def pivot(name, location, parent=None):
    bpy.ops.object.empty_add(type="PLAIN_AXES", location=location)
    obj = bpy.context.object
    obj.name = name
    if parent is not None:
        parent_keep_world(obj, parent)
    return obj


def parent_keep_world(obj, parent):
    # Keep every mesh where the concept sculpt placed it, but give Godot a
    # meaningful joint hierarchy that can be driven procedurally at runtime.
    obj.parent = parent
    obj.matrix_parent_inverse = parent.matrix_world.inverted()


def build_mimic():
    clear_scene()
    skin = make_material("Mimic damp charcoal skin", (0.115, 0.095, 0.105), 0.48)
    scar = make_material("Mimic scar tissue", (0.22, 0.095, 0.105), 0.62)
    throat = make_material("Mimic resonator folds", (0.18, 0.09, 0.12), 0.56)
    claw_material = make_material("Mimic keratin claws", (0.025, 0.021, 0.026), 0.30)
    eye = make_material("Mimic low amber eyes", (0.30, 0.07, 0.01), 0.25, emission=(0.70, 0.10, 0.02))

    # A compact transform rig gives the prototype an intentional animation
    # hierarchy even before it is retopologised into a weighted character mesh.
    # The named pivots are used directly by scripts/mimic.gd.
    rig = pivot("MimicRig", (0, 0, 0))
    hips = pivot("Hips", (0, 0.02, 0.96), rig)
    spine = pivot("Spine", (0, 0.0, 1.53), hips)
    head_pivot = pivot("HeadPivot", (0, -0.015, 2.11), spine)

    # Grounded at zero; overall height is just over 2.2m.
    pelvis = ellipsoid("Pelvis", (0, 0.02, 0.96), (0.29, 0.22, 0.34), skin)
    parent_keep_world(pelvis, hips)
    ribcage = ellipsoid("Ribcage", (0, 0.0, 1.53), (0.38, 0.25, 0.64), skin, 3)
    parent_keep_world(ribcage, spine)
    mantle = ellipsoid("Shoulder mantle", (0, 0.04, 1.93), (0.53, 0.24, 0.20), scar)
    parent_keep_world(mantle, spine)
    head = ellipsoid("Head", (0, -0.015, 2.28), (0.29, 0.27, 0.37), skin, 3)
    parent_keep_world(head, head_pivot)
    jaw = ellipsoid("Jaw", (0, -0.13, 2.08), (0.23, 0.18, 0.19), throat)
    parent_keep_world(jaw, head_pivot)

    # The throat is a stack of flexible resonator rings, the signature silhouette.
    resonator_group = pivot("ResonatorThroat", (0, 0, 2.09), head_pivot)
    for index in range(7):
        height = 1.91 + index * 0.060
        bpy.ops.mesh.primitive_torus_add(major_radius=0.19 + index * 0.003, minor_radius=0.030, major_segments=12, minor_segments=6, location=(0, -0.16, height))
        ring = bpy.context.object
        ring.name = "Resonator throat fold"
        ring.scale = (0.95, 0.70, 1.0)
        ring.data.materials.append(throat)
        parent_keep_world(ring, resonator_group)

    for x in (-0.105, 0.105):
        eye_mesh = ellipsoid("Recessed eye", (x, -0.255, 2.34), (0.036, 0.022, 0.040), eye, 2)
        parent_keep_world(eye_mesh, head_pivot)

    # Long arms hang below the knees. Empty pivots preserve believable elbow
    # and wrist arcs during idle, listening, and chase animation.
    for side in (-1, 1):
        shoulder = (side * 0.43, 0.02, 1.94)
        elbow = (side * 0.57, -0.02, 1.15)
        wrist = (side * 0.64, -0.10, 0.47)
        palm = (side * 0.65, -0.17, 0.31)
        label = "L" if side < 0 else "R"
        upper_pivot = pivot("Arm%sUpper" % label, shoulder, spine)
        upper_mesh = limb("Upper arm %s" % label, shoulder, elbow, 0.105, skin)
        parent_keep_world(upper_mesh, upper_pivot)
        elbow_pivot = pivot("Arm%sElbow" % label, elbow, upper_pivot)
        elbow_mesh = ellipsoid("Elbow %s" % label, elbow, (0.13, 0.11, 0.14), scar)
        parent_keep_world(elbow_mesh, elbow_pivot)
        fore_pivot = pivot("Arm%sFore" % label, elbow, elbow_pivot)
        fore_mesh = limb("Forearm %s" % label, elbow, wrist, 0.085, skin)
        parent_keep_world(fore_mesh, fore_pivot)
        hand_mesh = ellipsoid("Hand %s" % label, palm, (0.13, 0.10, 0.18), skin)
        parent_keep_world(hand_mesh, fore_pivot)
        for finger in (-0.065, 0.0, 0.065):
            finger_claw = claw("Finger claw %s" % label, (side * 0.65 + finger, -0.20, 0.25), (side * 0.69 + finger, -0.34, 0.035), claw_material)
            parent_keep_world(finger_claw, fore_pivot)

    # Reverse-jointed legs: an animal gait while keeping a readable bipedal stance.
    for side in (-1, 1):
        hip = (side * 0.19, 0.02, 0.98)
        knee = (side * 0.30, 0.20, 0.58)
        ankle = (side * 0.22, -0.05, 0.16)
        foot = (side * 0.22, -0.30, 0.075)
        label = "L" if side < 0 else "R"
        upper_pivot = pivot("Leg%sUpper" % label, hip, hips)
        thigh = limb("Thigh %s" % label, hip, knee, 0.14, skin)
        parent_keep_world(thigh, upper_pivot)
        knee_pivot = pivot("Leg%sKnee" % label, knee, upper_pivot)
        knee_mesh = ellipsoid("Knee %s" % label, knee, (0.15, 0.14, 0.14), scar)
        parent_keep_world(knee_mesh, knee_pivot)
        lower_pivot = pivot("Leg%sLower" % label, knee, knee_pivot)
        shin = limb("Shin %s" % label, knee, ankle, 0.10, skin)
        parent_keep_world(shin, lower_pivot)
        ankle_pivot = pivot("Leg%sAnkle" % label, ankle, lower_pivot)
        foot_mesh = ellipsoid("Foot %s" % label, foot, (0.15, 0.31, 0.08), skin)
        parent_keep_world(foot_mesh, ankle_pivot)
        for toe in (-0.07, 0.0, 0.07):
            toe_claw = claw("Toe claw %s" % label, (side * 0.22 + toe, -0.46, 0.06), (side * 0.22 + toe, -0.58, 0.02), claw_material)
            parent_keep_world(toe_claw, ankle_pivot)

    # Subtle spine nodes create a readable back silhouette without heavy polygon cost.
    for index in range(8):
        height = 1.05 + index * 0.14
        spine_node = ellipsoid("Spine node", (0, 0.23, height), (0.06, 0.055, 0.075), scar, 1)
        parent_keep_world(spine_node, spine if height > 1.45 else hips)

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUTPUT_DIR, "the_mimic.glb"),
        export_format="GLB",
        export_materials="EXPORT",
        export_apply=True,
        export_cameras=False,
        export_lights=False,
        export_extras=True,
    )


build_mimic()
