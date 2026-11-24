import bpy
import math
import os


ROOT = r"C:\Users\user\Documents\horror"
MODEL_DIR = os.path.join(ROOT, "assets", "models", "basement")
TEXTURE_DIR = os.path.join(ROOT, "assets", "textures")


def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    # Materials are shared by the three exports below. Keep them alive while
    # replacing geometry between models; Blender otherwise invalidates the
    # Python material references before the next builder uses them.
    for collection in (bpy.data.meshes, bpy.data.curves):
        for item in collection:
            if item.users == 0:
                collection.remove(item)


def hash_noise(x, y, seed=0.0):
    return math.sin(x * 12.9898 + y * 78.233 + seed * 37.719) * 43758.5453 % 1.0


def make_texture(name, width, height, writer):
    os.makedirs(TEXTURE_DIR, exist_ok=True)
    image = bpy.data.images.get(name)
    if image is not None:
        bpy.data.images.remove(image)
    image = bpy.data.images.new(name, width=width, height=height, alpha=True)
    pixels = [0.0] * (width * height * 4)
    for y in range(height):
        for x in range(width):
            r, g, b, a = writer(x / (width - 1), y / (height - 1))
            index = (y * width + x) * 4
            pixels[index:index + 4] = (r, g, b, a)
    image.pixels.foreach_set(pixels)
    image.filepath_raw = os.path.join(TEXTURE_DIR, name + ".png")
    image.file_format = "PNG"
    image.save()
    return image


def generate_textures():
    def metal(u, v):
        broad = hash_noise(u * 7.0, v * 7.0, 1.0)
        fine = hash_noise(u * 78.0, v * 78.0, 2.0)
        streak = 0.5 + 0.5 * math.sin(v * 165.0 + broad * 4.0)
        rust = max(0.0, (hash_noise(u * 9.0, v * 11.0, 5.0) - 0.68) * 3.1)
        base = 0.085 + broad * 0.085 + fine * 0.025
        r = base + rust * 0.34 + streak * rust * 0.08
        g = base + rust * 0.075
        b = base + rust * 0.018
        return min(r, 1.0), min(g, 1.0), min(b, 1.0), 1.0

    def wall(u, v):
        broad = hash_noise(u * 5.0, v * 5.0, 9.0)
        fine = hash_noise(u * 45.0, v * 45.0, 11.0)
        damp = max(0.0, math.sin((u * 2.7 + v * 6.5) * math.pi) - 0.50) * 0.18
        rust = max(0.0, (hash_noise(u * 10.0, v * 8.0, 14.0) - 0.74) * 2.5)
        base = 0.16 + broad * 0.13 + fine * 0.025 - damp
        return min(base + rust * 0.32, 1.0), min(base * 0.86 + rust * 0.08, 1.0), min(base * 0.73, 1.0), 1.0

    def glass(u, v):
        grain = hash_noise(u * 68.0, v * 68.0, 21.0)
        broad = hash_noise(u * 7.0, v * 9.0, 25.0)
        vertical = max(0.0, math.sin((u * 18.0 + broad * 2.0) * math.pi) - 0.86) * 1.6
        grime = max(0.0, (broad - 0.60) * 1.8) + vertical
        alpha = min(0.22 + grain * 0.05 + grime * 0.34, 0.70)
        return 0.22 + grime * 0.22, 0.29 + grime * 0.12, 0.24 + grime * 0.045, alpha

    def smoke(u, v):
        dx = u - 0.50
        dy = v - 0.52
        cloud = math.exp(-(dx * dx * 4.6 + dy * dy * 3.3) * 3.5)
        cloud += 0.55 * math.exp(-((u - 0.34) ** 2 * 18.0 + (v - 0.43) ** 2 * 14.0))
        cloud += 0.45 * math.exp(-((u - 0.66) ** 2 * 20.0 + (v - 0.66) ** 2 * 18.0))
        feather = 0.70 + hash_noise(u * 20.0, v * 20.0, 31.0) * 0.30
        alpha = min(1.0, cloud * feather) * 0.47
        return 0.18, 0.16, 0.13, alpha

    return {
        "metal": make_texture("basement_metal_grime", 256, 256, metal),
        "wall": make_texture("basement_wall_grit", 256, 256, wall),
        "glass": make_texture("basement_glass_grime", 256, 256, glass),
        "smoke": make_texture("basement_smoke", 128, 128, smoke),
    }


def material(name, color, metallic=0.0, roughness=0.65, texture=None, alpha=1.0, emission=None):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    bsdf = nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, alpha)
    bsdf.inputs["Metallic"].default_value = metallic
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Alpha"].default_value = alpha
    mat.diffuse_color = (*color, alpha)
    if texture is not None:
        image = nodes.new("ShaderNodeTexImage")
        image.image = texture
        image.interpolation = "Linear"
        links.new(image.outputs["Color"], bsdf.inputs["Base Color"])
        if alpha < 1.0 or texture.depth == 32:
            links.new(image.outputs["Alpha"], bsdf.inputs["Alpha"])
    if emission is not None:
        bsdf.inputs["Emission Color"].default_value = (*emission, 1.0)
        bsdf.inputs["Emission Strength"].default_value = 3.2
    if alpha < 1.0 or texture is not None and texture.depth == 32:
        try:
            mat.surface_render_method = "DITHERED"
        except AttributeError:
            try:
                mat.blend_method = "BLEND"
            except AttributeError:
                pass
    return mat


def box(name, location, dimensions, mat, bevel=0.0, rotation=None):
    bpy.ops.mesh.primitive_cube_add(location=location)
    obj = bpy.context.object
    obj.name = name
    obj.dimensions = dimensions
    if rotation is not None:
        obj.rotation_euler = rotation
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    if bevel > 0.0:
        modifier = obj.modifiers.new("Softened worn edge", "BEVEL")
        modifier.width = bevel
        modifier.segments = 2
    obj.data.materials.append(mat)
    return obj


def cylinder(name, location, radius, depth, mat, vertices=12, rotation=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=location)
    obj = bpy.context.object
    obj.name = name
    if rotation is not None:
        obj.rotation_euler = rotation
    obj.data.materials.append(mat)
    return obj


def bolt(location, mat, rotation=None):
    return cylinder("Rivet", location, 0.035, 0.025, mat, 10, rotation)


def pivot(name, location):
    bpy.ops.object.empty_add(type="PLAIN_AXES", location=location)
    obj = bpy.context.object
    obj.name = name
    return obj


def parent_keep_world(child, parent):
    child.parent = parent
    child.matrix_parent_inverse = parent.matrix_world.inverted()


def export_model(filename):
    os.makedirs(MODEL_DIR, exist_ok=True)
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(
        filepath=os.path.join(MODEL_DIR, filename),
        export_format="GLB",
        export_materials="EXPORT",
        export_apply=True,
        export_cameras=False,
        export_lights=False,
        export_extras=True,
    )


def common_materials(textures):
    return {
        "metal": material("Pitted furnace iron", (0.14, 0.16, 0.16), 0.82, 0.49, textures["metal"]),
        "dark": material("Coal black steel", (0.035, 0.032, 0.028), 0.76, 0.44),
        "rust": material("Flaking orange rust", (0.32, 0.075, 0.018), 0.50, 0.83),
        "ash": material("Ash and soot", (0.045, 0.039, 0.032), 0.03, 1.0),
        "ember": material("Furnace coals", (0.55, 0.09, 0.006), 0.08, 0.46, emission=(1.0, 0.16, 0.012)),
        "flame": material("Yellow fire core", (0.95, 0.30, 0.012), 0.0, 0.32, emission=(1.0, 0.34, 0.018)),
        "amber": material("Hazard amber", (0.68, 0.20, 0.018), 0.38, 0.52),
        "glass": material("Grimy salvaged observation glass", (0.20, 0.29, 0.23), 0.0, 0.18, textures["glass"], alpha=0.46),
        "wall": material("Damp patched basement wall", (0.24, 0.20, 0.16), 0.20, 0.91, textures["wall"]),
        "concrete": material("Broken concrete", (0.18, 0.17, 0.15), 0.04, 0.96),
        "compost": material("Wet tray substrate", (0.105, 0.085, 0.042), 0.0, 0.95),
        "larva": material("Pale moving culture", (0.46, 0.43, 0.31), 0.0, 0.81),
        "wood": material("Splintered cutting timber", (0.20, 0.075, 0.020), 0.0, 0.91),
        "stain": material("Old brown work stain", (0.115, 0.014, 0.006), 0.0, 0.96),
        "cloth": material("Threadbare canvas", (0.18, 0.19, 0.155), 0.0, 0.98),
        "cardboard": material("Damp shipping board", (0.31, 0.18, 0.070), 0.0, 0.93),
        "paper": material("Greasy label paper", (0.55, 0.43, 0.20), 0.0, 0.96),
    }


def build_furnace(materials):
    clear_scene()
    metal = materials["metal"]
    dark = materials["dark"]
    rust = materials["rust"]
    ash = materials["ash"]
    ember = materials["ember"]
    flame = materials["flame"]
    amber = materials["amber"]

    # Floor-origin, 1.45 m wide. The front is the local negative Y face.
    box("Furnace main welded body", (0.0, 0.0, 0.92), (1.36, 0.92, 1.66), metal, 0.045)
    box("Furnace sloped crown", (0.0, 0.0, 1.78), (1.14, 0.78, 0.24), dark, 0.035, (math.radians(-8), 0.0, 0.0))
    box("Ember throat", (0.0, -0.487, 1.02), (0.80, 0.022, 0.82), ember, 0.005)
    # The door and its heavy plate are a named pivot so the farm can actually
    # swing it open before fuel is loaded.
    door_pivot = pivot("FurnaceDoorPivot", (-0.47, -0.575, 1.02))
    door_parts = []
    door_parts.append(box("Heavy fire door", (0.0, -0.525, 1.02), (0.94, 0.075, 0.98), dark, 0.028))
    door_parts.append(box("Door heat shield", (0.0, -0.573, 1.10), (0.69, 0.021, 0.58), metal, 0.012))
    door_parts.append(box("Door peephole glow", (0.0, -0.590, 1.08), (0.16, 0.018, 0.22), ember, 0.004))
    door_parts.append(box("Door pull handle", (0.31, -0.635, 0.87), (0.22, 0.052, 0.06), amber, 0.007))
    for part in door_parts:
        parent_keep_world(part, door_pivot)
    flame_pivot = pivot("FurnaceFlameCore", (0.0, -0.50, 1.00))
    for index, x in enumerate((-0.20, 0.0, 0.20)):
        bpy.ops.mesh.primitive_cone_add(vertices=6, radius1=0.17 - index * 0.01, radius2=0.025, depth=0.42 + (index % 2) * 0.10, location=(x, -0.52, 0.98 + (index % 2) * 0.05))
        fire = bpy.context.object
        fire.name = "Furnace flame"
        fire.data.materials.append(flame if index == 1 else ember)
        parent_keep_world(fire, flame_pivot)
    box("Fuel hatch", (0.41, -0.570, 0.46), (0.34, 0.060, 0.25), rust, 0.015)
    box("Fuel hatch handle", (0.41, -0.632, 0.47), (0.20, 0.055, 0.050), amber, 0.008)
    box("Ash drawer", (-0.30, -0.556, 0.30), (0.50, 0.055, 0.19), ash, 0.012)
    box("Ash drawer pull", (-0.30, -0.607, 0.30), (0.18, 0.045, 0.040), metal, 0.006)
    for x in (-0.48, 0.48):
        box("Door hinge", (x, -0.572, 1.15), (0.10, 0.055, 0.28), rust, 0.009)
    for x in (-0.40, 0.0, 0.40):
        for z in (0.67, 1.48):
            bolt((x, -0.621, z), amber, (math.radians(90), 0.0, 0.0))
    for x in (-0.52, 0.52):
        for y in (-0.33, 0.33):
            box("Furnace foot", (x, y, 0.12), (0.15, 0.15, 0.24), dark, 0.010)
    # The chimney is deliberately oversized, improvised from mismatched pipe sections.
    cylinder("Lower smoke pipe", (0.32, 0.10, 2.20), 0.135, 0.76, metal, 16)
    cylinder("Smoke pipe collar", (0.32, 0.10, 1.90), 0.172, 0.12, rust, 16)
    cylinder("Smoke pipe collar", (0.32, 0.10, 2.47), 0.168, 0.11, rust, 16)
    cylinder("Bent chimney cap", (0.32, 0.10, 2.65), 0.182, 0.12, dark, 14)
    box("Chimney cap plate", (0.32, 0.10, 2.75), (0.46, 0.34, 0.055), dark, 0.008)
    box("Side tool rack", (-0.86, 0.12, 0.93), (0.08, 0.60, 1.10), rust, 0.014)
    for z in (0.52, 0.88, 1.25):
        box("Rack tooth", (-0.91, -0.22, z), (0.07, 0.16, 0.045), amber, 0.004)
    # Thin rust straps and plate repairs keep the silhouette from reading as one clean cube.
    box("Diagonal repair strap", (-0.55, -0.493, 1.47), (0.10, 0.020, 0.72), rust, 0.003, (0.0, math.radians(0.0), math.radians(-20)))
    box("Patch plate", (0.52, 0.474, 1.28), (0.24, 0.020, 0.45), rust, 0.006)
    export_model("makeshift_furnace.glb")


def build_culture_tray(materials):
    clear_scene()
    metal = materials["metal"]
    dark = materials["dark"]
    rust = materials["rust"]
    glass = materials["glass"]
    compost = materials["compost"]
    larva = materials["larva"]
    amber = materials["amber"]

    # Floor-origin, transparent salvage panels around a visible wet culture bed.
    box("Tray lower steel cradle", (0.0, 0.0, 0.27), (1.06, 0.68, 0.10), dark, 0.018)
    box("Tray substrate", (0.0, 0.0, 0.36), (0.88, 0.50, 0.13), compost, 0.009)
    for x in (-0.48, 0.48):
        for y in (-0.29, 0.29):
            box("Tray stand leg", (x, y, 0.14), (0.075, 0.075, 0.28), metal, 0.009)
    # Four continuous metal corners make the glass read as a makeshift food-safe box.
    for x in (-0.50, 0.50):
        for y in (-0.31, 0.31):
            box("Tray corner brace", (x, y, 0.61), (0.055, 0.055, 0.52), rust, 0.005)
    box("Front dirty glass", (0.0, -0.325, 0.62), (0.93, 0.018, 0.50), glass, 0.002)
    box("Back dirty glass", (0.0, 0.325, 0.62), (0.93, 0.018, 0.50), glass, 0.002)
    box("Left dirty glass", (-0.515, 0.0, 0.62), (0.018, 0.59, 0.50), glass, 0.002)
    box("Right dirty glass", (0.515, 0.0, 0.62), (0.018, 0.59, 0.50), glass, 0.002)
    box("Tray front rail", (0.0, -0.355, 0.88), (1.08, 0.055, 0.065), metal, 0.006)
    box("Tray back rail", (0.0, 0.355, 0.88), (1.08, 0.055, 0.065), metal, 0.006)
    box("Tray front ID plate", (0.0, -0.390, 0.67), (0.28, 0.020, 0.12), amber, 0.004)
    for x in (-0.39, 0.39):
        bolt((x, -0.386, 0.78), rust, (math.radians(90), 0.0, 0.0))
    # Static low-poly larvae make the contents legible before the colony-growth overlay updates.
    larva_positions = [(-0.27, -0.12), (-0.10, 0.13), (0.10, -0.08), (0.29, 0.14), (0.23, -0.21), (-0.31, 0.20)]
    for index, (x, y) in enumerate(larva_positions):
        cylinder("Culture larva", (x, y, 0.47 + (index % 2) * 0.018), 0.055, 0.18, larva, 10, (0.0, math.radians(90), 0.0))
    # The lid pivots from the rear rail. It is a real hierarchy rather than a
    # painted suggestion, so the game can lift it while a player tends a tray.
    lid_pivot = pivot("CultureLidPivot", (0.0, 0.325, 0.94))
    lid_parts = []
    lid_parts.append(box("Salvaged mesh lid", (0.0, 0.0, 0.935), (1.02, 0.64, 0.018), glass, 0.002))
    lid_parts.append(box("Mesh lid rail", (0.0, 0.0, 0.93), (1.06, 0.69, 0.035), rust, 0.004))
    for x in (-0.30, 0.0, 0.30):
        lid_parts.append(box("Mesh lid bar", (x, 0.0, 0.958), (0.030, 0.60, 0.018), metal, 0.002))
    lid_parts.append(cylinder("Lid hinge tube", (0.0, 0.325, 0.94), 0.040, 0.94, dark, 12, (0.0, math.radians(90), 0.0)))
    lid_parts.append(box("Lid pull tab", (0.0, -0.355, 0.95), (0.18, 0.055, 0.055), amber, 0.004))
    for part in lid_parts:
        parent_keep_world(part, lid_pivot)
    export_model("grimy_culture_tray.glb")


def build_rugged_wall(materials, variant, filename):
    clear_scene()
    wall = materials["wall"]
    concrete = materials["concrete"]
    metal = materials["metal"]
    dark = materials["dark"]
    rust = materials["rust"]
    amber = materials["amber"]

    # 2 m modular bay, floor-origin. The common shell keeps the room readable,
    # but every variant tells a different repair story instead of repeating a
    # single pipe-and-plate pattern around the whole room.
    box("Broken concrete backing", (0.0, 0.02, 1.60), (2.0, 0.16, 3.20), concrete, 0.008)
    box("Left uneven upright", (-0.93, -0.11, 1.60), (0.12, 0.12, 3.18), dark, 0.014, (0.0, 0.0, math.radians(0.8)))
    box("Right uneven upright", (0.93, -0.11, 1.60), (0.12, 0.12, 3.18), dark, 0.014, (0.0, 0.0, math.radians(-1.1)))
    box("Salvaged lintel", (0.0, -0.12, 3.05), (2.0, 0.15, 0.13), rust, 0.010)
    box("Damp floor skirt", (0.0, -0.105, 0.15), (1.82, 0.040, 0.20), wall, 0.004)

    if variant == 0:
        # A repaired panel with only one short service pipe: this is the least
        # damaged section and keeps a hint of the old utility room.
        for x, z, width, height, degrees in [
            (-0.45, 0.76, 0.66, 0.48, -7),
            (0.31, 1.34, 0.58, 0.38, 4),
            (-0.10, 2.22, 0.74, 0.52, -2),
        ]:
            plate = box("Welded repair plate", (x, -0.125, z), (width, 0.028, height), wall if z > 2.0 else metal, 0.006, (0.0, 0.0, math.radians(degrees)))
            for px in (-width * 0.34, width * 0.34):
                bolt((x + px, -0.151, z - height * 0.30), amber, (math.radians(90), 0.0, 0.0))
        box("Short warm-water pipe", (0.66, -0.17, 1.02), (0.10, 0.10, 1.25), rust, 0.010)
        box("Pipe clamp", (0.66, -0.215, 0.52), (0.22, 0.050, 0.042), dark, 0.003)
        box("Pipe clamp", (0.66, -0.215, 1.48), (0.22, 0.050, 0.042), dark, 0.003)
        box("Loose wall label", (-0.50, -0.155, 2.72), (0.38, 0.021, 0.17), amber, 0.003, (0.0, 0.0, math.radians(-5)))
    elif variant == 1:
        # A ripped-out bay: dark cavities, a loose sheet, and slats where a
        # former occupant nailed whatever material was available.
        box("Missing panel cavity", (0.28, -0.128, 1.72), (0.88, 0.032, 0.92), dark, 0.002)
        box("Left surviving plate", (-0.50, -0.125, 1.42), (0.58, 0.028, 1.66), wall, 0.006, (0.0, 0.0, math.radians(2)))
        box("High bent plate", (0.02, -0.128, 2.72), (1.44, 0.028, 0.40), metal, 0.006, (0.0, 0.0, math.radians(-3)))
        box("Loose hanging plate", (0.60, -0.205, 1.98), (0.52, 0.045, 0.96), rust, 0.008, (0.0, math.radians(-12), math.radians(8)))
        for x, z, width in [(-0.08, 0.42, 1.32), (0.00, 0.70, 1.46), (0.10, 0.98, 1.26)]:
            box("Nailed timber slat", (x, -0.175, z), (width, 0.055, 0.075), rust, 0.004, (0.0, 0.0, math.radians(2)))
        box("Exposed cable", (-0.57, -0.19, 2.24), (0.035, 0.035, 1.22), dark, 0.004, (0.0, 0.0, math.radians(-6)))
        box("Cracked base stone", (0.18, -0.145, 0.24), (0.76, 0.035, 0.28), concrete, 0.004, (0.0, 0.0, math.radians(-4)))
    else:
        # A damp, mostly masonry section with one patch welded over a crack and
        # an old mesh vent. No upright pipe here, so the silhouette changes.
        box("Masonry patch left", (-0.42, -0.120, 1.55), (0.72, 0.030, 2.42), wall, 0.005)
        box("Masonry patch right", (0.48, -0.120, 2.14), (0.60, 0.030, 1.46), wall, 0.005, (0.0, 0.0, math.radians(1.5)))
        box("Dark broken seam", (0.15, -0.150, 1.15), (0.22, 0.018, 1.64), dark, 0.002, (0.0, 0.0, math.radians(-12)))
        box("Mesh vent void", (0.48, -0.155, 0.72), (0.58, 0.018, 0.38), dark, 0.002)
        for x in (0.30, 0.48, 0.66):
            box("Vent mesh bar", (x, -0.172, 0.72), (0.018, 0.015, 0.34), rust, 0.001)
        box("Angled brace", (-0.42, -0.175, 1.98), (0.095, 0.052, 2.08), metal, 0.005, (0.0, 0.0, math.radians(-31)))
        box("Fresh bolt-on patch", (0.45, -0.180, 2.58), (0.48, 0.034, 0.34), rust, 0.006, (0.0, 0.0, math.radians(6)))
        for x in (0.29, 0.61):
            bolt((x, -0.205, 2.58), amber, (math.radians(90), 0.0, 0.0))

    export_model(filename)


def build_butcher_table(materials):
    clear_scene()
    metal = materials["metal"]
    dark = materials["dark"]
    rust = materials["rust"]
    wood = materials["wood"]
    stain = materials["stain"]
    amber = materials["amber"]

    # A practical, hand-built processing table: an uneven timber block on a
    # steel frame, with a drain, hook rail and a catch bucket below it.
    box("Butcher timber top", (0.0, 0.0, 0.85), (1.76, 1.06, 0.13), wood, 0.025)
    box("Butcher steel front rim", (0.0, -0.545, 0.87), (1.86, 0.065, 0.18), metal, 0.010)
    box("Butcher steel back rim", (0.0, 0.515, 0.87), (1.86, 0.065, 0.18), dark, 0.010)
    for x in (-0.75, 0.75):
        for y in (-0.42, 0.42):
            box("Butcher table leg", (x, y, 0.42), (0.105, 0.105, 0.82), dark, 0.012)
    box("Low cross brace", (0.0, -0.38, 0.29), (1.58, 0.075, 0.075), rust, 0.006)
    box("Side cross brace", (-0.72, 0.0, 0.38), (0.075, 0.86, 0.075), rust, 0.006)
    box("Thick cutting block", (-0.10, 0.04, 0.955), (0.82, 0.66, 0.105), wood, 0.018)
    box("Old cutting stain", (0.08, -0.05, 1.012), (0.38, 0.25, 0.008), stain, 0.001, (0.0, 0.0, math.radians(-8)))
    box("Drain channel", (0.61, 0.10, 0.956), (0.17, 0.64, 0.040), dark, 0.004)
    box("Drain lip", (0.61, -0.22, 0.992), (0.25, 0.055, 0.035), rust, 0.004)
    cylinder("Catch bucket", (0.57, -0.23, 0.25), 0.20, 0.38, dark, 14)
    cylinder("Bucket wire handle", (0.57, -0.23, 0.48), 0.22, 0.026, metal, 14)
    box("Butcher hook rail", (0.0, 0.47, 1.22), (1.38, 0.060, 0.070), metal, 0.006)
    for x in (-0.46, -0.14, 0.18, 0.50):
        box("Butcher hanging hook", (x, 0.45, 1.09), (0.045, 0.050, 0.27), rust, 0.004)
        box("Butcher hook tooth", (x + 0.055, 0.45, 0.98), (0.13, 0.045, 0.040), amber, 0.003)
    box("Cleaver blade", (-0.34, -0.16, 1.025), (0.10, 0.36, 0.025), metal, 0.002, (0.0, 0.0, math.radians(21)))
    box("Cleaver grip", (-0.47, -0.28, 1.035), (0.12, 0.22, 0.035), rust, 0.006, (0.0, 0.0, math.radians(21)))
    for x in (-0.79, 0.79):
        bolt((x, -0.586, 0.87), amber, (math.radians(90), 0.0, 0.0))
    export_model("butcher_table.glb")


def build_packaging_bench(materials):
    clear_scene()
    metal = materials["metal"]
    dark = materials["dark"]
    rust = materials["rust"]
    cardboard = materials["cardboard"]
    paper = materials["paper"]
    amber = materials["amber"]

    # A packing bench should feel like a small production line, not a generic
    # desk: shelves, taped parcels, a mechanical scale and a label spool tell
    # the player why this station exists in the farm loop.
    box("Packaging worktop", (0.0, 0.0, 0.85), (1.78, 1.06, 0.115), metal, 0.018)
    box("Packaging top patch", (-0.28, 0.12, 0.918), (0.68, 0.58, 0.022), dark, 0.004)
    for x in (-0.75, 0.75):
        for y in (-0.42, 0.42):
            box("Packaging bench leg", (x, y, 0.41), (0.09, 0.09, 0.82), dark, 0.010)
    box("Packaging lower shelf", (0.0, 0.0, 0.30), (1.52, 0.78, 0.065), rust, 0.008)
    box("Packaging rear brace", (0.0, 0.43, 0.47), (1.62, 0.060, 0.66), metal, 0.006)
    box("Packed ration crate", (0.40, -0.08, 1.08), (0.42, 0.38, 0.30), cardboard, 0.012, (0.0, 0.0, math.radians(-5)))
    box("Parcel tape cross", (0.40, -0.08, 1.242), (0.46, 0.050, 0.022), paper, 0.001)
    box("Parcel tape length", (0.40, -0.08, 1.245), (0.055, 0.42, 0.022), paper, 0.001)
    box("Lower spare box", (-0.42, 0.12, 0.48), (0.48, 0.44, 0.30), cardboard, 0.009, (0.0, 0.0, math.radians(4)))
    box("Crushed lower box", (0.30, -0.16, 0.47), (0.32, 0.34, 0.22), cardboard, 0.008)
    box("Scale base", (-0.48, -0.10, 0.99), (0.38, 0.34, 0.12), dark, 0.008)
    box("Scale upright", (-0.48, 0.05, 1.20), (0.075, 0.075, 0.38), metal, 0.004)
    box("Scale indicator", (-0.48, -0.145, 1.25), (0.19, 0.025, 0.16), amber, 0.003)
    box("Scale tray", (-0.48, 0.04, 1.42), (0.46, 0.40, 0.055), metal, 0.008)
    cylinder("Label paper spool", (0.68, 0.28, 1.03), 0.11, 0.18, paper, 16, (0.0, math.radians(90), 0.0))
    box("Spool stand", (0.68, 0.28, 0.96), (0.06, 0.30, 0.10), rust, 0.004)
    box("Warning label", (0.74, -0.548, 0.76), (0.30, 0.020, 0.15), amber, 0.003)
    export_model("packaging_bench.glb")


def build_salvaged_cot(materials):
    clear_scene()
    metal = materials["metal"]
    dark = materials["dark"]
    rust = materials["rust"]
    cloth = materials["cloth"]
    amber = materials["amber"]

    # An actual sleeping cot gives the sleep interaction a personal, precarious
    # place in the room: bent tubing, thin mattress, blanket and pillow.
    for x in (-0.52, 0.52):
        for y in (-0.77, 0.77):
            cylinder("Cot bent leg", (x, y, 0.25), 0.045, 0.50, dark, 10)
            box("Cot foot pad", (x, y, 0.025), (0.14, 0.14, 0.05), rust, 0.005)
    for y in (-0.81, 0.81):
        cylinder("Cot side rail", (0.0, y, 0.49), 0.045, 1.25, metal, 12, (0.0, math.radians(90), 0.0))
    for x in (-0.54, 0.54):
        cylinder("Cot end rail", (x, 0.0, 0.49), 0.045, 1.72, metal, 12, (math.radians(90), 0.0, 0.0))
    box("Sagging cot mattress", (0.0, 0.0, 0.56), (1.13, 1.72, 0.16), cloth, 0.030)
    box("Folded filthy blanket", (0.0, 0.30, 0.67), (1.08, 0.65, 0.075), rust, 0.020)
    box("Worn pillow", (0.0, -0.57, 0.68), (0.86, 0.38, 0.13), cloth, 0.035)
    box("Mattress repair strap", (0.0, -0.16, 0.66), (1.18, 0.060, 0.040), amber, 0.004)
    box("Raised cot head", (0.0, -0.84, 0.88), (1.20, 0.075, 0.74), rust, 0.008)
    export_model("salvaged_cot.glb")


def build_crush_gate_trap(materials):
    clear_scene()
    metal = materials["metal"]
    dark = materials["dark"]
    rust = materials["rust"]
    amber = materials["amber"]

    # The trap reads as a working improvised machine: recessed pressure plate,
    # raised teeth, guide rails and a hand-operated release lever.
    box("Crush gate pressure plate", (0.0, 0.0, 0.045), (1.58, 1.58, 0.09), metal, 0.015)
    box("Pressure plate inset", (0.0, 0.0, 0.100), (1.23, 1.23, 0.035), dark, 0.006)
    for offset in (-0.45, -0.15, 0.15, 0.45):
        box("Hazard paint stripe", (offset, -0.62, 0.125), (0.13, 0.18, 0.020), amber, 0.002, (0.0, 0.0, math.radians(-28)))
    for x in (-0.71, 0.71):
        cylinder("Gate guide post", (x, 0.0, 0.93), 0.065, 1.72, dark, 12)
        box("Guide post foot", (x, 0.0, 0.13), (0.22, 0.24, 0.09), rust, 0.006)
    # The moving gate has its own named root. Godot lowers this hierarchy when
    # the player pulls the lever, instead of only reporting a text outcome.
    gate_pivot = pivot("CrushGatePivot", (0.0, 0.0, 0.0))
    gate_parts = []
    gate_parts.append(box("Raised crush gate", (0.0, 0.0, 1.46), (1.36, 0.11, 0.72), metal, 0.012))
    for z in (1.19, 1.41, 1.63, 1.85):
        gate_parts.append(box("Gate reinforcing bar", (0.0, -0.075, z), (1.24, 0.045, 0.055), dark, 0.004))
    for x in (-0.50, -0.25, 0.0, 0.25, 0.50):
        gate_parts.append(box("Blunt gate tooth", (x, 0.0, 1.06), (0.10, 0.15, 0.22), rust, 0.004))
    for part in gate_parts:
        parent_keep_world(part, gate_pivot)
    box("Trap winding drum", (0.0, 0.0, 2.02), (1.48, 0.24, 0.15), dark, 0.008)
    cylinder("Trap cable spool", (0.0, -0.16, 2.00), 0.10, 1.20, rust, 14, (0.0, math.radians(90), 0.0))
    box("Trap lever stem", (0.83, -0.48, 0.59), (0.10, 0.10, 0.94), rust, 0.006, (0.0, math.radians(-22), 0.0))
    box("Trap lever grip", (1.00, -0.48, 0.98), (0.24, 0.16, 0.10), amber, 0.012)
    export_model("crush_gate_trap.glb")


def build_shutter_panel(materials):
    clear_scene()
    metal = materials["metal"]
    dark = materials["dark"]
    rust = materials["rust"]
    amber = materials["amber"]

    # Door-only asset. It rides up with the game object's existing shutter
    # animation while a separate fixed frame remains embedded in the wall.
    for index in range(18):
        z = 0.10 + index * 0.165
        box("Corrugated shutter slat", (0.0, 0.0, z), (0.30, 1.72, 0.145), metal if index % 4 else dark, 0.009)
        box("Slat front lip", (-0.166, 0.0, z + 0.038), (0.025, 1.64, 0.025), rust, 0.003)
    for y in (-0.78, 0.78):
        box("Shutter side strap", (-0.17, y, 1.50), (0.055, 0.070, 2.84), dark, 0.007)
    box("Shutter patch plate", (-0.185, -0.22, 1.76), (0.025, 0.55, 0.42), rust, 0.004, (0.0, 0.0, math.radians(5)))
    box("Shutter warning plate", (-0.190, 0.36, 0.72), (0.022, 0.40, 0.20), amber, 0.003)
    for y in (-0.60, 0.60):
        for z in (0.37, 2.62):
            bolt((-0.205, y, z), amber, (0.0, math.radians(90), 0.0))
    export_model("salvaged_rolling_shutter.glb")


def build_shutter_frame(materials):
    clear_scene()
    metal = materials["metal"]
    dark = materials["dark"]
    rust = materials["rust"]

    box("Shutter left guide", (0.0, -0.98, 1.55), (0.42, 0.12, 3.08), dark, 0.010)
    box("Shutter right guide", (0.0, 0.98, 1.55), (0.42, 0.12, 3.08), dark, 0.010)
    box("Shutter roller housing", (0.0, 0.0, 3.05), (0.48, 2.20, 0.30), metal, 0.015)
    cylinder("Shutter roller", (-0.20, 0.0, 2.93), 0.12, 1.76, rust, 16, (math.radians(90), 0.0, 0.0))
    box("Roller support", (-0.24, -0.95, 2.92), (0.12, 0.12, 0.32), rust, 0.006)
    box("Roller support", (-0.24, 0.95, 2.92), (0.12, 0.12, 0.32), rust, 0.006)
    export_model("shutter_frame.glb")


def main():
    textures = generate_textures()
    materials = common_materials(textures)
    build_furnace(materials)
    build_culture_tray(materials)
    build_rugged_wall(materials, 0, "rugged_basement_wall_a.glb")
    build_rugged_wall(materials, 1, "rugged_basement_wall_b.glb")
    build_rugged_wall(materials, 2, "rugged_basement_wall_c.glb")
    build_butcher_table(materials)
    build_packaging_bench(materials)
    build_salvaged_cot(materials)
    build_crush_gate_trap(materials)
    build_shutter_panel(materials)
    build_shutter_frame(materials)
    print("Created Basement Farm models in", MODEL_DIR)


if __name__ == "__main__":
    main()
