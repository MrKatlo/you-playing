import bpy
import math
import os

OUTPUT_DIR = r"C:\Users\user\Documents\horror\assets\models\station"
TEXTURE_DIR = r"C:\Users\user\Documents\horror\assets\textures"


def reset_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for datablocks in (bpy.data.materials, bpy.data.meshes, bpy.data.curves):
        for block in datablocks:
            if block.users == 0:
                datablocks.remove(block)


def material(name, color, metallic=0.0, roughness=0.65, emission=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    principled = nodes.get("Principled BSDF")
    principled.inputs["Base Color"].default_value = (*color, 1.0)
    principled.inputs["Metallic"].default_value = metallic
    principled.inputs["Roughness"].default_value = roughness
    if emission:
        principled.inputs["Emission Color"].default_value = (*emission, 1.0)
        principled.inputs["Emission Strength"].default_value = 3.0
    return mat


def textured_material(name, color, texture_filename, metallic=0.0, roughness=0.65):
    mat = material(name, color, metallic, roughness)
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    texture_node = nodes.new("ShaderNodeTexImage")
    texture_node.image = bpy.data.images.load(os.path.join(TEXTURE_DIR, texture_filename), check_existing=True)
    texture_node.interpolation = "Linear"
    principled = nodes.get("Principled BSDF")
    links.new(texture_node.outputs["Color"], principled.inputs["Base Color"])
    return mat


STEEL = None
PANEL_STEEL = None
DARK_STEEL = None
RUST = None
WARNING = None
LAMP = None


def box(name, location, dimensions, mat, bevel=0.015):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0.0:
        modifier = obj.modifiers.new("Edge soften", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    obj.data.materials.append(mat)
    return obj


def cylinder(name, location, radius, depth, mat, vertices=12):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    obj.data.materials.append(mat)
    return obj


def export_model(filename):
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(OUTPUT_DIR, filename),
        export_format="GLB",
        export_materials="EXPORT",
        export_apply=True,
        export_cameras=False,
        export_lights=False,
        export_extras=True,
    )


def add_common_materials():
    global STEEL, PANEL_STEEL, DARK_STEEL, RUST, WARNING, LAMP
    STEEL = material("Painted blue grey steel", (0.16, 0.22, 0.25), 0.75, 0.47)
    PANEL_STEEL = textured_material("Weathered steel wall panels", (0.40, 0.48, 0.52), "station_wall_painted_steel.png", 0.70, 0.63)
    DARK_STEEL = material("Dark structural steel", (0.035, 0.055, 0.067), 0.88, 0.34)
    RUST = material("Oxidized metal", (0.27, 0.09, 0.035), 0.58, 0.78)
    WARNING = material("Warning amber paint", (0.62, 0.24, 0.025), 0.38, 0.55)
    LAMP = material("Cyan work lamp", (0.08, 0.36, 0.34), 0.15, 0.24, (0.12, 0.95, 0.74))


def build_wall_bay():
    reset_scene()
    add_common_materials()
    # Origin: center on the floor line. The wall is 2m wide and 3.2m tall.
    box("Wall panel backing", (0, 0, 1.6), (2.0, 0.18, 3.2), PANEL_STEEL)
    box("Left structural upright", (-0.93, -0.08, 1.6), (0.16, 0.30, 3.2), DARK_STEEL)
    box("Right structural upright", (0.93, -0.08, 1.6), (0.16, 0.30, 3.2), DARK_STEEL)
    box("Top beam", (0, -0.08, 3.04), (2.0, 0.30, 0.16), DARK_STEEL)
    box("Floor beam", (0, -0.08, 0.16), (2.0, 0.30, 0.16), DARK_STEEL)
    for height in (0.72, 1.60, 2.48):
        box("Panel seam", (0, -0.11, height), (1.64, 0.055, 0.035), DARK_STEEL, 0.003)
    for x in (-0.46, 0.46):
        box("Vertical panel seam", (x, -0.11, 1.6), (0.030, 0.055, 2.66), DARK_STEEL, 0.003)
    # A conduit and small cable give every repeated bay a useful industrial silhouette.
    pipe = cylinder("Conduit", (0.67, -0.16, 1.55), 0.052, 2.62, RUST)
    pipe.rotation_euler[0] = 0
    for height in (0.45, 1.45, 2.55):
        box("Conduit bracket", (0.67, -0.20, height), (0.20, 0.07, 0.05), DARK_STEEL, 0.004)
    box("Service label plate", (-0.46, -0.115, 2.73), (0.42, 0.030, 0.18), WARNING, 0.005)
    export_model("station_wall_bay.glb")


def build_grill_gate():
    reset_scene()
    add_common_materials()
    # Origin: middle of the opening on the floor; built for a 4.2m x 3.2m doorway.
    box("Grill top housing", (0, 0, 3.03), (4.2, 0.34, 0.32), DARK_STEEL)
    box("Grill left jamb", (-2.0, 0, 1.50), (0.20, 0.34, 3.0), DARK_STEEL)
    box("Grill right jamb", (2.0, 0, 1.50), (0.20, 0.34, 3.0), DARK_STEEL)
    box("Grill lower rail", (0, 0, 0.22), (3.8, 0.24, 0.18), DARK_STEEL)
    box("Grill middle rail", (0, 0, 1.62), (3.8, 0.16, 0.10), RUST, 0.008)
    for x in (-1.67, -1.18, -0.69, -0.20, 0.29, 0.78, 1.27, 1.66):
        cylinder("Security grille bar", (x, -0.02, 1.52), 0.072, 2.63, STEEL, 10)
    for x in (-1.57, 1.57):
        box("Warning panel", (x, -0.19, 2.77), (0.44, 0.05, 0.14), WARNING, 0.005)
    for x in (-1.78, 1.78):
        cylinder("Status lamp", (x, -0.21, 2.77), 0.075, 0.055, LAMP, 16)
        bpy.context.object.rotation_euler[0] = math.radians(90)
    export_model("security_grill_gate.glb")


def build_ceiling_bay():
    reset_scene()
    add_common_materials()
    # 2m bay, with a recessed cyan strip. Room builder repeats this along corridors.
    box("Ceiling panel", (0, 0, 0), (2.0, 2.0, 0.16), PANEL_STEEL)
    box("Ceiling cross brace", (0, 0.0, -0.10), (0.10, 2.0, 0.16), DARK_STEEL)
    box("Recessed work light", (0.42, 0, -0.13), (0.17, 1.24, 0.05), LAMP, 0.006)
    box("Cable tray", (-0.58, 0, -0.13), (0.22, 1.55, 0.10), DARK_STEEL, 0.006)
    export_model("ceiling_worklight_bay.glb")


def build_control_console():
    reset_scene()
    add_common_materials()
    screen = material("Terminal phosphor", (0.04, 0.24, 0.22), 0.15, 0.24, (0.08, 0.90, 0.72))
    red_lamp = material("Alarm red", (0.38, 0.02, 0.01), 0.20, 0.30, (0.95, 0.05, 0.02))
    # A shoulder-high control terminal: cabinet, sloped control face, screen and service conduit.
    box("Console cabinet", (0, 0.0, 0.48), (1.16, 0.72, 0.96), DARK_STEEL, 0.025)
    box("Console face", (0, -0.16, 1.03), (1.02, 0.48, 0.46), STEEL, 0.02)
    bpy.context.object.rotation_euler[0] = math.radians(-24)
    box("Console display", (0, -0.40, 1.13), (0.64, 0.028, 0.28), screen, 0.008)
    box("Console lower lip", (0, -0.37, 0.88), (0.88, 0.07, 0.075), WARNING, 0.008)
    for x in (-0.36, -0.18, 0.18, 0.36):
        cylinder("Control key", (x, -0.38, 0.98), 0.052, 0.05, STEEL, 12)
        bpy.context.object.rotation_euler[0] = math.radians(90)
    for x in (-0.47, 0.47):
        cylinder("Alarm indicator", (x, -0.39, 1.18), 0.055, 0.05, red_lamp, 16)
        bpy.context.object.rotation_euler[0] = math.radians(90)
    cylinder("Console conduit", (0.46, 0.15, 0.55), 0.055, 1.10, RUST)
    export_model("industrial_control_console.glb")


def build_pump_assembly():
    reset_scene()
    add_common_materials()
    water_lamp = material("Pump status", (0.02, 0.20, 0.26), 0.10, 0.20, (0.04, 0.60, 0.92))
    # Floor-mounted centrifugal pump with motor and large pipe sections.
    box("Pump skid", (0, 0, 0.12), (2.25, 1.05, 0.24), DARK_STEEL, 0.02)
    motor = cylinder("Pump motor", (-0.46, 0, 0.62), 0.36, 0.96, STEEL, 16)
    motor.rotation_euler[1] = math.radians(90)
    for x in (-0.85, -0.46, -0.07):
        box("Motor cooling fin", (x, 0, 0.62), (0.05, 0.78, 0.78), DARK_STEEL, 0.005)
    cylinder("Pump housing", (0.55, 0, 0.62), 0.49, 0.34, RUST, 16)
    bpy.context.object.rotation_euler[1] = math.radians(90)
    cylinder("Pipe intake", (1.02, 0, 0.62), 0.18, 0.74, STEEL, 14)
    bpy.context.object.rotation_euler[1] = math.radians(90)
    cylinder("Pipe outlet", (0.55, 0.0, 1.18), 0.18, 1.10, STEEL, 14)
    box("Pump valve body", (0.55, 0.0, 1.72), (0.42, 0.42, 0.22), RUST, 0.02)
    bpy.ops.mesh.primitive_torus_add(major_radius=0.22, minor_radius=0.045, major_segments=16, minor_segments=8, location=(0.55, -0.24, 1.72))
    bpy.context.object.name = "Valve wheel"
    bpy.context.object.rotation_euler[0] = math.radians(90)
    bpy.context.object.data.materials.append(WARNING)
    cylinder("Pump status lamp", (-0.82, -0.43, 1.02), 0.065, 0.06, water_lamp, 16)
    bpy.context.object.rotation_euler[0] = math.radians(90)
    export_model("pump_assembly.glb")


def build_locker_bank():
    reset_scene()
    add_common_materials()
    for index, x in enumerate((-0.72, 0, 0.72)):
        box("Locker shell", (x, 0.0, 1.20), (0.66, 0.54, 2.40), STEEL, 0.018)
        box("Locker door", (x, -0.29, 1.20), (0.56, 0.038, 2.20), DARK_STEEL, 0.01)
        for z in (0.52, 0.65, 1.78, 1.91):
            box("Locker vent", (x, -0.315, z), (0.34, 0.018, 0.027), RUST, 0.002)
        box("Locker handle", (x + 0.16, -0.34, 1.18), (0.045, 0.035, 0.34), WARNING, 0.005)
        if index == 1:
            box("Missing-person tag", (x - 0.08, -0.32, 1.48), (0.25, 0.014, 0.32), WARNING, 0.003)
    export_model("locker_bank.glb")


def build_pipe_rack():
    reset_scene()
    add_common_materials()
    # A low-poly wall-side pipe cluster that creates silhouette and scale in long corridors.
    for x, z, radius, mat in ((-0.38, 0.55, 0.075, RUST), (0.0, 0.75, 0.11, STEEL), (0.38, 0.48, 0.055, DARK_STEEL)):
        cylinder("Vertical service pipe", (x, 0, z), radius, 1.10, mat, 12)
    for x in (-0.38, 0.0, 0.38):
        box("Pipe bracket", (x, -0.08, 0.18), (0.16, 0.07, 0.045), DARK_STEEL, 0.003)
        box("Pipe bracket", (x, -0.08, 0.92), (0.16, 0.07, 0.045), DARK_STEEL, 0.003)
    box("Pipe tray", (0, 0.0, 1.15), (1.08, 0.22, 0.08), DARK_STEEL, 0.006)
    export_model("service_pipe_rack.glb")


def build_freight_shutter():
    reset_scene()
    add_common_materials()
    # A rolling freight-door shutter. The Godot builder raises the whole model on an opening tween.
    box("Freight shutter top motor", (0, 0, 3.04), (4.20, 0.44, 0.34), DARK_STEEL, 0.025)
    box("Freight shutter left rail", (-2.00, 0, 1.50), (0.18, 0.34, 3.0), DARK_STEEL, 0.018)
    box("Freight shutter right rail", (2.00, 0, 1.50), (0.18, 0.34, 3.0), DARK_STEEL, 0.018)
    for index in range(11):
        height = 0.30 + index * 0.25
        slat_mat = PANEL_STEEL if index % 2 == 0 else STEEL
        box("Rolling shutter slat", (0, -0.03, height), (3.80, 0.22, 0.20), slat_mat, 0.012)
    box("Shutter warning lip", (0, -0.18, 0.24), (3.86, 0.07, 0.16), WARNING, 0.006)
    for x in (-1.56, 1.56):
        cylinder("Shutter lamp", (x, -0.18, 2.73), 0.07, 0.06, LAMP, 16)
        bpy.context.object.rotation_euler[0] = math.radians(90)
    box("Shutter service panel", (1.72, -0.18, 1.54), (0.17, 0.055, 0.38), WARNING, 0.004)
    export_model("freight_elevator_shutter.glb")


build_wall_bay()
build_grill_gate()
build_ceiling_bay()
build_control_console()
build_pump_assembly()
build_locker_bank()
build_pipe_rack()
build_freight_shutter()
