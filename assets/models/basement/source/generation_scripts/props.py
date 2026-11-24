"""Source models for Basement Farm's usable, hand-built base and hunt props.

These are deliberately assembled as objects with a believable purpose instead
of generic cubes.  The salvaged workbench is where the player turns a hunt's
scrap into bolts, medicine, and wall insulation.
"""
from __future__ import annotations

import math

from mesh import Builder


def build_salvaged_workbench() -> Builder:
    """Build a compact, improvised workbench in metres, grounded at y=0.

    The shape tells a small story: rebuilt timber top, an old angle-iron frame,
    a patched lower shelf, a vise for shaping bolt heads, and only the tools
    needed by the current game loop.  It is intentionally asymmetrical so it
    does not read as factory-perfect furniture.
    """
    builder = Builder()

    # Three uneven boards and their darker gaps make the top look reclaimed
    # before any texture pass.  The front lip is a separately repaired plank.
    builder.add_box((-0.29, 0.790, 0.0), (0.56, 0.090, 0.700), "bench_wood",
                    name="top_plank_left")
    builder.add_box((0.295, 0.803, -0.010), (0.57, 0.102, 0.700), "bench_wood_cut",
                    rotate=(0.0, 0.0, -1.2), name="top_plank_center")
    builder.add_box((0.695, 0.782, 0.018), (0.19, 0.078, 0.690), "bench_wood",
                    rotate=(0.0, 0.0, 1.1), name="top_plank_patch")
    builder.add_box((0.0, 0.750, -0.372), (1.66, 0.115, 0.090), "bench_wood_dark",
                    name="front_repair_lip")
    for x in (-0.58, 0.04, 0.61):
        builder.add_box((x, 0.805, -0.006), (0.018, 0.018, 0.705), "bench_wood_dark",
                        name="plank_gap")

    # A heavy, repaired angle-iron frame.  The offset feet and diagonal braces
    # make it feel made from scavenged shelving, not a symmetric kit.
    leg_specs = [
        (-0.70, -0.255, 0.365, "bench_metal"),
        (0.69, -0.255, 0.355, "bench_metal_dark"),
        (-0.68, 0.250, 0.350, "bench_metal_dark"),
        (0.68, 0.245, 0.372, "bench_metal"),
    ]
    for index, (x, z, height, material) in enumerate(leg_specs):
        builder.add_box((x, height, z), (0.095, height * 2.0, 0.095), material,
                        rotate=(0.0, 0.0, -1.3 if index == 1 else 0.8 if index == 2 else 0.0),
                        name="frame_leg_%d" % index)
        builder.add_box((x + (-0.018 if index % 2 else 0.018), 0.032, z),
                        (0.19, 0.050, 0.16), "bench_rust", name="rusted_foot_%d" % index)
    builder.add_box((0.0, 0.680, 0.266), (1.53, 0.075, 0.075), "bench_metal",
                    name="rear_top_rail")
    builder.add_box((0.0, 0.355, 0.255), (1.46, 0.075, 0.075), "bench_metal_dark",
                    name="rear_cross_rail")
    builder.add_tube((-0.68, 0.100, -0.23), (-0.36, 0.655, -0.23), 0.035, 0.035,
                     seg=6, mat="bench_rust", name="left_diagonal_brace")
    builder.add_tube((0.68, 0.095, 0.25), (0.34, 0.610, 0.25), 0.031, 0.031,
                     seg=6, mat="bench_rust", name="right_diagonal_brace")

    # A low shelf holds a rag, scrap and a partly-open drawer.  It keeps the
    # silhouette readable at room scale while giving close inspection detail.
    builder.add_box((-0.05, 0.305, 0.035), (1.38, 0.075, 0.500), "bench_wood_dark",
                    rotate=(0.0, 0.0, 0.6), name="lower_shelf")
    builder.add_box((-0.38, 0.383, -0.020), (0.42, 0.125, 0.255), "bench_canvas",
                    rotate=(0.0, 0.0, -2.0), name="folded_insulation_roll")
    builder.add_box((0.36, 0.402, 0.035), (0.39, 0.180, 0.310), "bench_metal_dark",
                    name="salvage_drawer")
    builder.add_box((0.36, 0.402, -0.145), (0.28, 0.075, 0.026), "bench_rust",
                    name="drawer_pull")
    builder.add_box((0.61, 0.383, -0.055), (0.18, 0.105, 0.225), "bench_rust",
                    rotate=(0.0, 12.0, 0.0), name="scrap_block")

    # A functional vise on the left: base, fixed jaw, sliding jaw and a screw
    # handle.  It makes the bolt recipe legible without needing UI exposition.
    builder.add_box((-0.46, 0.862, -0.045), (0.38, 0.070, 0.300), "bench_metal_dark",
                    name="vise_base")
    builder.add_box((-0.58, 0.965, -0.055), (0.095, 0.180, 0.245), "bench_metal",
                    name="vise_fixed_jaw")
    builder.add_box((-0.35, 0.955, -0.055), (0.080, 0.150, 0.245), "bench_metal",
                    name="vise_sliding_jaw")
    builder.add_box((-0.46, 1.055, -0.055), (0.31, 0.025, 0.045), "bench_rust",
                    name="vise_jaw_faces")
    builder.add_tube((-0.35, 0.890, -0.31), (-0.35, 0.890, -0.55), 0.026, 0.026,
                     seg=7, mat="bench_metal", name="vise_screw")
    builder.add_tube((-0.35, 0.890, -0.59), (-0.35, 0.890, -0.72), 0.036, 0.036,
                     seg=7, mat="bench_tool_handle", name="vise_handle")

    # Right-side supplies: wire spool, sharpened bolt bundle, cloth tool roll,
    # and a hand lamp. These are primitive forms but each is a named source part
    # that can later be swapped or textured without touching gameplay.
    builder.add_tube((0.34, 0.857, 0.100), (0.34, 0.976, 0.100), 0.105, 0.105,
                     seg=12, mat="bench_metal", name="wire_spool_core")
    builder.add_tube((0.34, 0.848, 0.100), (0.34, 0.862, 0.100), 0.155, 0.155,
                     seg=12, mat="bench_rust", name="wire_spool_lower_flange")
    builder.add_tube((0.34, 0.972, 0.100), (0.34, 0.986, 0.100), 0.155, 0.155,
                     seg=12, mat="bench_rust", name="wire_spool_upper_flange")
    for index, x in enumerate((0.50, 0.555, 0.610)):
        builder.add_tube((x, 0.850, -0.235), (x, 0.850, -0.020), 0.012, 0.012,
                         seg=5, mat="bench_metal", name="bolt_shaft_%d" % index)
        builder.add_cone((x, 0.850, -0.270), 0.031, 0.067, seg=5, mat="bench_metal",
                         tilt=(90.0, 0.0, 0.0), name="bolt_head_%d" % index)
    builder.add_box((0.16, 0.858, -0.205), (0.31, 0.038, 0.190), "bench_canvas",
                    rotate=(0.0, 0.0, 2.2), name="tool_roll")
    for index, x in enumerate((0.055, 0.135, 0.215)):
        builder.add_tube((x, 0.885, -0.205), (x + 0.045, 0.920, -0.205), 0.014, 0.014,
                         seg=5, mat="bench_metal_dark", name="tool_shaft_%d" % index)
        builder.add_tube((x - 0.024, 0.867, -0.205), (x + 0.010, 0.892, -0.205),
                         0.023, 0.023, seg=6, mat="bench_tool_handle",
                         name="tool_handle_%d" % index)

    # Crooked task lamp: its warm pool distinguishes the craft station from the
    # colder grow trays and gives it a visual role at night.
    builder.add_tube((0.69, 0.845, 0.205), (0.69, 1.300, 0.205), 0.021, 0.021,
                     seg=6, mat="bench_metal_dark", name="lamp_upright")
    builder.add_tube((0.69, 1.300, 0.205), (0.48, 1.315, 0.030), 0.021, 0.021,
                     seg=6, mat="bench_metal_dark", name="lamp_arm")
    builder.add_box((0.46, 1.275, 0.000), (0.175, 0.092, 0.150), "bench_lamp",
                    rotate=(10.0, 0.0, 0.0), name="lamp_shade")
    builder.add_box((0.46, 1.228, -0.010), (0.105, 0.018, 0.085), "bench_lamp_glow",
                    rotate=(10.0, 0.0, 0.0), name="lamp_bulb")

    return builder


def build_wall_insulation_patch() -> Builder:
    """Build an improvised wall repair panel, grounded at its lower edge.

    The player makes these at the workbench from hide and scrap, so it needs to
    read as a layered repair rather than a clean construction panel: hide under
    cloth, warped timber battens, rusted straps, and obvious nail heads.
    """
    builder = Builder()

    # The soft backing seals the draft. Offset sections stop its outline being a
    # perfect rectangle and leave the fasteners visibly responsible for holding
    # it in place.
    builder.add_box((-0.11, 0.510, 0.018), (0.80, 1.020, 0.040), "patch_canvas",
                    rotate=(0.0, 0.0, -1.4), name="quilted_hide_backing")
    builder.add_box((0.380, 0.485, 0.020), (0.18, 0.910, 0.042), "patch_hide",
                    rotate=(0.0, 0.0, 1.8), name="torn_backing_edge")
    builder.add_box((-0.08, 0.160, -0.016), (0.78, 0.210, 0.060), "patch_hide",
                    rotate=(0.0, 0.0, 2.3), name="lower_overlap")

    # Scavenged battens and straps: three distinct directions make this feel
    # patched by a person with whatever materials were left in the basement.
    builder.add_box((-0.360, 0.565, -0.035), (0.090, 1.105, 0.090), "bench_wood",
                    rotate=(0.0, 0.0, 1.8), name="left_batten")
    builder.add_box((0.310, 0.595, -0.040), (0.078, 1.005, 0.086), "bench_wood_cut",
                    rotate=(0.0, 0.0, -2.6), name="right_batten")
    builder.add_box((0.0, 0.720, -0.057), (0.895, 0.075, 0.075), "bench_rust",
                    rotate=(0.0, 0.0, -3.2), name="upper_metal_strap")
    builder.add_box((-0.020, 0.345, -0.060), (0.850, 0.065, 0.072), "bench_metal_dark",
                    rotate=(0.0, 0.0, 2.1), name="lower_metal_strap")
    builder.add_tube((-0.385, 0.100, -0.055), (0.335, 1.030, -0.060), 0.022, 0.022,
                     seg=6, mat="bench_rust", name="diagonal_wire_lash")

    # Large nail heads are deliberately legible at first-person scale. Small
    # raw hide folds give the panel depth without relying on transparency.
    for index, (x, y) in enumerate(((-0.35, 0.13), (-0.35, 0.98), (0.31, 0.18),
                                    (0.32, 0.90), (0.00, 0.69), (-0.03, 0.34))):
        builder.add_sphere((x, y, -0.095), (0.032, 0.032, 0.018), seg=7, rings=4,
                           mat="bench_metal", name="nail_head_%d" % index,
                           smooth=True)
    for index, (x, y, sx) in enumerate(((-0.08, 0.48, 0.19), (0.16, 0.57, 0.13),
                                         (-0.16, 0.87, 0.12))):
        builder.add_sphere((x, y, -0.026), (sx, 0.022, 0.024), seg=7, rings=4,
                           mat="patch_hide", name="hide_fold_%d" % index,
                           smooth=True)
    return builder


def build_hunt_snare() -> Builder:
    """Build a reusable bait-side floor snare, grounded at y=0.

    It is not a miniature cage. The full hunt room and its doors remain the
    containment system; this is a low wire loop that briefly catches prey at
    the bait mark, giving a careful hunter a clean melee option.
    """
    builder = Builder()

    # An irregular octagonal wire loop, with alternating clean and corroded
    # segments, reads as tensioned cord rather than a flat decal.
    points = []
    radii = (0.60, 0.53, 0.57, 0.51, 0.59, 0.52, 0.56, 0.50)
    for index in range(8):
        angle = math.tau * index / 8.0 + math.radians(12.0)
        points.append((math.cos(angle) * radii[index], 0.038, math.sin(angle) * radii[index]))
    for index in range(8):
        p0 = points[index]
        p1 = points[(index + 1) % 8]
        material = "bench_metal" if index in (1, 2, 6) else "bench_rust"
        builder.add_tube(p0, p1, 0.019, 0.019, seg=6, mat=material,
                         name="wire_loop_%d" % index)

    # Bait plate and a visible hook at the center make it clear why the player
    # arms this at the lure point instead of expecting it to catch prey anywhere.
    builder.add_box((0.0, 0.026, 0.0), (0.31, 0.040, 0.24), "bench_metal_dark",
                    rotate=(0.0, 14.0, 0.0), name="bait_plate")
    builder.add_tube((0.0, 0.050, -0.035), (0.0, 0.155, -0.035), 0.018, 0.018,
                     seg=6, mat="bench_metal", name="bait_hook_stem")
    builder.add_sphere((0.0, 0.145, -0.035), (0.037, 0.026, 0.037), seg=7, rings=4,
                       mat="bench_lamp_glow", name="bait_glint", smooth=True)

    # Two anchor stakes and a tension spool explain how the floor loop tightens
    # without pretending the animal is held by invisible game logic.
    for index, (x, z) in enumerate(((-0.61, -0.08), (0.56, 0.19))):
        builder.add_cone((x, 0.0, z), 0.055, 0.260, seg=6, mat="bench_metal_dark",
                         name="anchor_stake_%d" % index)
        builder.add_box((x, 0.035, z), (0.15, 0.045, 0.15), "bench_rust",
                        rotate=(0.0, 0.0, 8.0 if index == 0 else -7.0),
                        name="anchor_plate_%d" % index)
    builder.add_tube((-0.60, 0.115, -0.08), (-0.40, 0.060, -0.18), 0.016, 0.016,
                     seg=6, mat="bench_metal", name="left_tension_wire")
    builder.add_tube((0.56, 0.115, 0.19), (0.37, 0.060, 0.18), 0.016, 0.016,
                     seg=6, mat="bench_metal", name="right_tension_wire")
    builder.add_tube((0.46, 0.040, 0.30), (0.46, 0.135, 0.30), 0.085, 0.085,
                     seg=10, mat="bench_metal", name="tension_spool")
    builder.add_tube((0.46, 0.035, 0.30), (0.46, 0.047, 0.30), 0.126, 0.126,
                     seg=10, mat="bench_rust", name="spool_lower_flange")
    builder.add_tube((0.46, 0.130, 0.30), (0.46, 0.142, 0.30), 0.126, 0.126,
                     seg=10, mat="bench_rust", name="spool_upper_flange")
    builder.add_box((0.39, 0.085, 0.36), (0.22, 0.042, 0.058), "bench_tool_handle",
                    rotate=(0.0, 22.0, 0.0), name="tension_handle")

    # A few low guide teeth stop the loop from reading as decoration and imply
    # its direction of travel when the trigger releases.
    for index, (x, z, rotation) in enumerate(((-0.23, -0.47, -22.0), (0.20, -0.46, 18.0),
                                               (-0.34, 0.38, 28.0), (0.30, 0.40, -26.0))):
        builder.add_box((x, 0.048, z), (0.16, 0.052, 0.034), "bench_metal_dark",
                        rotate=(0.0, rotation, 0.0), name="guide_tooth_%d" % index)
    return builder


def build_warm_storage_rack() -> Builder:
    """Build a furnace-fed storage rack with a small heat lamp, grounded at y=0.

    This is a home improvement rather than another abstract inventory flag. The
    player scavenges it together from bent angle iron, uneven shelves, crates,
    jars and a lamp tapped into the furnace line. It creates a visibly warmer
    rest point in the safe room without pretending that the lamp replaces the
    real furnace.
    """
    builder = Builder()

    # The frame is deliberately a little crooked: mismatched front and rear
    # uprights, visibly plated feet, and cross-braces make it look built from a
    # collapsed shop shelf rather than bought new.
    upright_specs = [
        (-0.76, 0.16, 0.99, "bench_metal"),
        (0.76, 0.16, 0.96, "bench_metal_dark"),
        (-0.74, -0.20, 0.94, "bench_metal_dark"),
        (0.74, -0.20, 1.02, "bench_metal"),
    ]
    for index, (x, z, height, material) in enumerate(upright_specs):
        builder.add_box((x, height, z), (0.072, height * 2.0, 0.072), material,
                        rotate=(0.0, 0.0, -1.0 if index == 1 else 0.8 if index == 2 else 0.0),
                        name="rack_upright_%d" % index)
        builder.add_box((x, 0.030, z), (0.185, 0.052, 0.140), "bench_rust",
                        rotate=(0.0, 0.0, 5.0 if index % 2 else -4.0),
                        name="rack_foot_%d" % index)
    for index, (y, z, material) in enumerate(((0.23, 0.17, "bench_metal_dark"),
                                                (0.83, 0.19, "bench_metal"),
                                                (1.42, 0.16, "bench_metal_dark"),
                                                (1.84, 0.18, "bench_rust"))):
        builder.add_box((0.0, y, z), (1.60, 0.060, 0.070), material,
                        rotate=(0.0, 0.0, 0.7 if index == 2 else 0.0),
                        name="rack_rear_rail_%d" % index)
    builder.add_tube((-0.70, 0.08, 0.17), (-0.36, 1.52, 0.17), 0.024, 0.024,
                     seg=6, mat="bench_rust", name="rack_left_cross_brace")
    builder.add_tube((0.69, 0.09, 0.17), (0.34, 1.44, 0.17), 0.022, 0.022,
                     seg=6, mat="bench_rust", name="rack_right_cross_brace")

    # Three reclaimed timber shelves, each assembled from differently coloured
    # boards. The open fronts make the stored supplies readable in first person.
    shelf_levels = (0.29, 0.91, 1.51)
    for shelf_index, y in enumerate(shelf_levels):
        builder.add_box((-0.31, y, -0.010), (0.82, 0.075, 0.50), "bench_wood",
                        rotate=(0.0, 0.0, 0.9 if shelf_index == 1 else -0.6),
                        name="rack_shelf_left_%d" % shelf_index)
        builder.add_box((0.42, y + 0.006, 0.004), (0.61, 0.082, 0.49), "bench_wood_cut",
                        rotate=(0.0, 0.0, -1.3 if shelf_index == 2 else 0.5),
                        name="rack_shelf_right_%d" % shelf_index)
        builder.add_box((0.0, y - 0.058, -0.238), (1.56, 0.085, 0.055), "bench_metal_dark",
                        name="rack_shelf_front_lip_%d" % shelf_index)

    # Lower shelf: ration crates and a rolled hide. Middle shelf: scavenged
    # jars and boxed hardware. Top shelf: a tool roll and a fuel-line coil.
    builder.add_box((-0.39, 0.495, -0.025), (0.52, 0.315, 0.335), "bench_wood_dark",
                    rotate=(0.0, 0.0, -1.4), name="ration_crate")
    builder.add_box((-0.40, 0.645, -0.205), (0.38, 0.060, 0.030), "bench_rust",
                    name="ration_crate_handle")
    builder.add_box((0.37, 0.485, 0.025), (0.48, 0.285, 0.330), "patch_hide",
                    rotate=(0.0, 0.0, 2.0), name="rolled_hide_bundle")
    for index, (x, height, radius) in enumerate(((-0.47, 0.29, 0.072), (-0.22, 0.22, 0.058),
                                                   (0.12, 0.32, 0.066), (0.36, 0.25, 0.053))):
        builder.add_tube((x, 1.00, -0.055), (x, 1.00 + height, -0.055), radius, radius,
                         seg=10, mat="bench_canvas" if index % 2 == 0 else "bench_metal",
                         name="supply_jar_%d" % index)
        builder.add_tube((x, 1.00 + height, -0.055), (x, 1.00 + height + 0.018, -0.055),
                         radius * 1.12, radius * 1.12, seg=10, mat="bench_rust",
                         name="supply_jar_lid_%d" % index)
    builder.add_box((0.52, 1.080, 0.025), (0.32, 0.250, 0.320), "bench_metal_dark",
                    rotate=(0.0, 0.0, -1.2), name="parts_tin")
    builder.add_box((0.52, 1.080, -0.155), (0.22, 0.052, 0.028), "bench_tool_handle",
                    name="parts_tin_pull")
    builder.add_box((-0.36, 1.615, -0.035), (0.56, 0.080, 0.340), "bench_canvas",
                    rotate=(0.0, 0.0, 1.8), name="top_tool_roll")
    builder.add_tube((0.33, 1.560, 0.020), (0.33, 1.730, 0.020), 0.110, 0.110,
                     seg=12, mat="bench_metal", name="heat_line_coil")
    builder.add_tube((0.33, 1.552, 0.020), (0.33, 1.567, 0.020), 0.158, 0.158,
                     seg=12, mat="bench_rust", name="heat_line_coil_lower")
    builder.add_tube((0.33, 1.723, 0.020), (0.33, 1.738, 0.020), 0.158, 0.158,
                     seg=12, mat="bench_rust", name="heat_line_coil_upper")

    # The warm lamp is clamped to the shelf rather than floating in space. The
    # exposed conduit visibly leads to the heat coil, explaining its place in
    # the base upgrade and creating a second small, comforting light pool.
    builder.add_tube((0.67, 1.56, 0.07), (0.67, 1.92, 0.07), 0.024, 0.024,
                     seg=6, mat="bench_metal_dark", name="lamp_upright")
    builder.add_tube((0.67, 1.92, 0.07), (0.42, 1.93, -0.20), 0.024, 0.024,
                     seg=6, mat="bench_metal_dark", name="lamp_arm")
    builder.add_box((0.39, 1.885, -0.245), (0.245, 0.115, 0.180), "bench_lamp",
                    rotate=(10.0, 0.0, 0.0), name="heat_lamp_shade")
    builder.add_box((0.39, 1.828, -0.255), (0.145, 0.020, 0.100), "bench_lamp_glow",
                    rotate=(10.0, 0.0, 0.0), name="heat_lamp_bulb")
    builder.add_tube((0.49, 1.72, 0.015), (0.63, 1.84, 0.070), 0.014, 0.014,
                     seg=6, mat="bench_tool_handle", name="lamp_power_cable")

    return builder


def build_frozen_maintenance_portal() -> Builder:
    """Build one damaged support bay for the first cave entrance.

    This is a real, editable Basement prop rather than a runtime stack of
    anonymous cubes.  Repeating it down the tunnel gives the player a useful
    scale reference and tells the story of an old service route below the
    house: municipal steel, patched concrete, freezing pipes, and an emergency
    lamp that still has a little power.  It is open in the middle so collision
    remains a separate, simple gameplay shell in Godot.
    """
    builder = Builder()

    # Two uneven welded jambs, each made from layered plate rather than a clean
    # manufactured I-beam.  The local X span becomes tunnel width in Godot.
    for index, (x, lean, material) in enumerate((
            (-1.73, -1.3, "cave_steel"), (1.71, 1.0, "cave_steel_dark"))):
        builder.add_box((x, 1.38, 0.0), (0.22, 2.76, 0.62), material,
                        rotate=(0.0, 0.0, lean), name="support_jamb_%d" % index)
        builder.add_box((x + (0.07 if x < 0 else -0.06), 0.76, -0.345),
                        (0.32, 1.30, 0.085), "cave_rust",
                        rotate=(0.0, 0.0, lean * 1.6),
                        name="jamb_repair_plate_%d" % index)
        builder.add_box((x + (-0.03 if x < 0 else 0.025), 0.080, 0.015),
                        (0.43, 0.12, 0.78), "cave_rust",
                        rotate=(0.0, 0.0, -2.0 if x < 0 else 1.4),
                        name="jamb_foot_%d" % index)
        # Big bolts make the repair legible from first-person distance.
        for bolt_index, height in enumerate((0.42, 1.24, 2.03)):
            builder.add_sphere((x + (0.13 if x < 0 else -0.13), height, -0.405),
                               (0.050, 0.050, 0.026), seg=7, rings=4,
                               mat="cave_steel_dark", name="jamb_bolt_%d_%d" % (index, bolt_index),
                               smooth=True)

    # Header, a sagging internal rail, and diagonal gussets make this an actual
    # load-bearing maintenance frame instead of a decorative doorway.
    builder.add_box((0.0, 2.82, 0.0), (3.72, 0.26, 0.65), "cave_steel",
                    rotate=(0.0, 0.0, -0.6), name="header_beam")
    builder.add_box((-0.11, 2.57, -0.335), (3.25, 0.14, 0.090), "cave_rust",
                    rotate=(0.0, 0.0, 0.8), name="header_repair_strip")
    builder.add_tube((-1.55, 2.53, 0.05), (-0.72, 2.78, 0.05), 0.048, 0.043,
                     seg=7, mat="cave_steel_dark", name="left_gusset")
    builder.add_tube((1.55, 2.51, 0.05), (0.68, 2.78, 0.05), 0.044, 0.040,
                     seg=7, mat="cave_steel_dark", name="right_gusset")

    # Cold water lines cross the ceiling and one has ruptured, so the player
    # understands the ice as a physical problem rather than blue decoration.
    for index, (z, radius, material) in enumerate(((-0.22, 0.080, "cave_steel_dark"),
                                                     (0.14, 0.058, "cave_steel"))):
        builder.add_tube((-1.53, 2.35, z), (1.56, 2.35, z), radius, radius,
                         seg=10, mat=material, name="frozen_pipe_%d" % index)
        for collar_index, x in enumerate((-0.92, 0.08, 1.02)):
            builder.add_box((x, 2.35, z), (0.060, radius * 2.62, radius * 2.62),
                            "cave_rust", name="pipe_collar_%d_%d" % (index, collar_index))
    builder.add_tube((-1.05, 2.34, -0.22), (-0.98, 1.72, -0.20), 0.026, 0.020,
                     seg=7, mat="cave_ice", name="frozen_drip")
    builder.add_cone((-0.98, 1.73, -0.20), 0.080, 0.34, seg=7, mat="cave_ice",
                     tilt=(180.0, 0.0, 0.0), name="icicle")

    # A broken service stencil: deliberately abstract in the GLB, with a
    # readable Label3D supplied by the live level only at the first entrance.
    builder.add_box((0.10, 2.10, -0.365), (1.34, 0.42, 0.060), "cave_warning",
                    rotate=(0.0, 0.0, -1.8), name="service_stencil_plate")
    builder.add_box((0.10, 2.10, -0.402), (0.95, 0.125, 0.020), "cave_steel_dark",
                    rotate=(0.0, 0.0, -1.8), name="stencil_scrape")
    builder.add_box((0.64, 2.10, -0.425), (0.14, 0.25, 0.028), "cave_rust",
                    rotate=(0.0, 0.0, 4.0), name="stencil_break")

    # Caged warning lamp on the right.  It is small but intentionally bright
    # enough to become the return landmark when the warm basement vanishes.
    builder.add_box((1.36, 2.02, -0.41), (0.30, 0.31, 0.090), "cave_steel_dark",
                    name="lamp_housing")
    builder.add_sphere((1.36, 2.02, -0.475), (0.095, 0.095, 0.040), seg=9, rings=5,
                       mat="cave_lamp_glow", name="lamp_lens", smooth=True)
    for bar_index, offset in enumerate((-0.09, 0.0, 0.09)):
        builder.add_tube((1.36 + offset, 1.87, -0.51), (1.36 + offset, 2.17, -0.51),
                         0.012, 0.012, seg=6, mat="cave_steel", name="lamp_guard_bar_%d" % bar_index)
    builder.add_tube((1.21, 2.02, -0.51), (1.51, 2.02, -0.51), 0.012, 0.012,
                     seg=6, mat="cave_steel", name="lamp_guard_cross")

    # Frost has crept up the cold-side jamb and pooled along the floor.  Faceted
    # clusters retain a dirty, mineral appearance instead of clean glass.
    for index, (x, y, z, sx, sy, sz) in enumerate((
            (-1.50, 0.29, -0.36, 0.25, 0.30, 0.075),
            (-1.32, 0.15, -0.31, 0.34, 0.16, 0.10),
            (1.53, 0.13, -0.32, 0.30, 0.14, 0.090),
            (1.63, 0.46, -0.34, 0.18, 0.38, 0.070),
            (-0.78, 0.055, -0.25, 0.48, 0.070, 0.13),
            (0.86, 0.055, -0.25, 0.54, 0.075, 0.13))):
        builder.add_ico((x, y, z), (sx, sy, sz), subdiv=1, jitter=0.18,
                        seed=70 + index, mat="cave_ice", name="frost_cluster_%d" % index)

    return builder


def build_frozen_maintenance_cart() -> Builder:
    """Build the abandoned service cart that anchors the Cold Junction.

    It is not loot disguised as a crate.  The cart has a specific former job:
    carry a battery, hose reels, canisters, and repair tools through the frozen
    service route.  In the first cave slice it is a physical story clue and a
    readable turning landmark; later it can grow into a repair/expedition hook.
    """
    builder = Builder()

    # Four damaged trolley wheels, short axles, and a mismatched frame establish
    # scale before the player reads the individual tools piled on the deck.
    for index, (x, z, material) in enumerate((
            (-0.61, -0.45, "cave_steel_dark"), (0.61, -0.45, "cave_steel"),
            (-0.61, 0.43, "cave_steel"), (0.61, 0.43, "cave_steel_dark"))):
        builder.add_tube((x - 0.075, 0.175, z), (x + 0.075, 0.175, z), 0.170, 0.170,
                         seg=10, mat=material, name="cart_wheel_%d" % index)
        builder.add_tube((x - 0.091, 0.175, z), (x + 0.091, 0.175, z), 0.055, 0.055,
                         seg=8, mat="cave_rust", name="cart_hub_%d" % index)
    for index, (x, z, height) in enumerate((
            (-0.58, -0.43, 0.42), (0.57, -0.43, 0.39),
            (-0.56, 0.41, 0.41), (0.59, 0.40, 0.44))):
        builder.add_box((x, 0.31, z), (0.075, height, 0.075), "cave_steel_dark",
                        rotate=(0.0, 0.0, -1.2 if index == 1 else 0.8 if index == 2 else 0.0),
                        name="cart_upright_%d" % index)
    builder.add_box((0.0, 0.51, 0.0), (1.42, 0.095, 1.06), "cave_steel",
                    rotate=(0.0, 0.0, -0.7), name="cart_deck")
    builder.add_box((0.0, 0.448, -0.47), (1.47, 0.075, 0.070), "cave_rust",
                    name="cart_front_lip")
    builder.add_box((0.0, 0.448, 0.47), (1.47, 0.075, 0.070), "cave_rust",
                    name="cart_back_lip")

    # Folded handle on the basement-facing end.  One loose grip and one intact
    # grip make it read as scavenged equipment, not a pristine prop kit.
    builder.add_tube((-0.55, 0.55, -0.46), (-0.82, 1.10, -0.46), 0.034, 0.034,
                     seg=7, mat="cave_steel_dark", name="handle_left_stem")
    builder.add_tube((0.55, 0.55, -0.46), (0.78, 1.04, -0.46), 0.034, 0.034,
                     seg=7, mat="cave_steel", name="handle_right_stem")
    builder.add_tube((-0.82, 1.10, -0.46), (0.78, 1.04, -0.46), 0.040, 0.040,
                     seg=7, mat="cave_rust", name="handle_crossbar")
    builder.add_box((-0.38, 1.072, -0.46), (0.34, 0.070, 0.105), "bench_tool_handle",
                    rotate=(0.0, 0.0, -2.0), name="handle_grip")

    # A dead battery, two service canisters, and an imperfect tool tray explain
    # why this cart was sent underground. Their irregular placement prevents a
    # symmetric, toy-like silhouette at gameplay distance.
    builder.add_box((-0.26, 0.74, 0.03), (0.58, 0.42, 0.54), "cave_steel_dark",
                    rotate=(0.0, 0.0, 1.6), name="dead_battery")
    builder.add_box((-0.26, 0.97, -0.18), (0.34, 0.045, 0.085), "cave_warning",
                    rotate=(0.0, 0.0, 1.6), name="battery_warning_plate")
    builder.add_tube((0.44, 0.56, 0.13), (0.44, 1.04, 0.13), 0.135, 0.135,
                     seg=10, mat="cave_steel", name="service_canister_tall")
    builder.add_tube((0.44, 1.04, 0.13), (0.44, 1.08, 0.13), 0.164, 0.164,
                     seg=10, mat="cave_rust", name="service_canister_tall_cap")
    builder.add_tube((0.63, 0.56, -0.20), (0.63, 0.88, -0.20), 0.107, 0.107,
                     seg=10, mat="cave_steel_dark", name="service_canister_short")
    builder.add_tube((0.63, 0.88, -0.20), (0.63, 0.915, -0.20), 0.130, 0.130,
                     seg=10, mat="cave_rust", name="service_canister_short_cap")
    builder.add_box((0.13, 0.61, -0.30), (0.54, 0.16, 0.28), "cave_rust",
                    rotate=(0.0, 0.0, -2.3), name="open_tool_tray")
    for index, x in enumerate((-0.03, 0.11, 0.24)):
        builder.add_tube((x, 0.71, -0.31), (x + 0.055, 0.76, -0.31), 0.019, 0.019,
                         seg=6, mat="cave_steel_dark", name="tool_%d" % index)

    # Cable reel and a severed frozen hose lead the eye toward the collapse,
    # while the small lamp makes the cart visible as a useful landmark.
    builder.add_tube((-0.52, 0.55, 0.34), (-0.52, 0.82, 0.34), 0.130, 0.130,
                     seg=12, mat="cave_steel_dark", name="cable_reel_core")
    builder.add_tube((-0.52, 0.545, 0.34), (-0.52, 0.565, 0.34), 0.188, 0.188,
                     seg=12, mat="cave_rust", name="cable_reel_lower")
    builder.add_tube((-0.52, 0.805, 0.34), (-0.52, 0.825, 0.34), 0.188, 0.188,
                     seg=12, mat="cave_rust", name="cable_reel_upper")
    builder.add_tube((-0.52, 0.68, 0.34), (-0.13, 0.57, 0.50), 0.026, 0.020,
                     seg=7, mat="cave_steel_dark", name="severed_hose")
    builder.add_tube((0.13, 0.63, 0.42), (0.13, 1.17, 0.42), 0.022, 0.022,
                     seg=7, mat="cave_steel", name="cart_lamp_stem")
    builder.add_box((0.13, 1.18, 0.37), (0.28, 0.14, 0.18), "cave_lamp",
                    rotate=(8.0, 0.0, 0.0), name="cart_lamp_housing")
    builder.add_box((0.13, 1.12, 0.31), (0.16, 0.026, 0.095), "cave_lamp_glow",
                    rotate=(8.0, 0.0, 0.0), name="cart_lamp_lens")

    # Frost connects it visually to the tunnel while remaining dirty and
    # localized around the wheels, canisters, and failed battery seam.
    for index, (x, y, z, sx, sy, sz) in enumerate((
            (-0.58, 0.16, -0.45, 0.19, 0.12, 0.19),
            (0.61, 0.15, 0.42, 0.17, 0.11, 0.17),
            (-0.26, 0.96, 0.16, 0.22, 0.055, 0.19),
            (0.43, 1.04, 0.15, 0.15, 0.065, 0.13))):
        builder.add_ico((x, y, z), (sx, sy, sz), subdiv=1, jitter=0.16,
                        seed=140 + index, mat="cave_ice", name="cart_frost_%d" % index)

    return builder


def build_furnace_heat_reclaimer() -> Builder:
    """Build the recovered C-4 heat reclaimer, grounded at y=0.

    This is intentionally small enough to ride on the service cart, then bolt
    beside the home furnace.  Its anatomy explains its job at a glance: a
    scarred heat-exchanger body, exposed recovery pipes, a pressure gauge,
    service valves, and uneven mounting feet.  It is a real expedition reward,
    not an invisible percentage upgrade.
    """
    builder = Builder()

    # The main body is an old industrial exchanger: dark pressure housing,
    # lighter access face, and a crooked warning panel.  The shallow depth lets
    # it mount beside the furnace without becoming a new hallway obstacle.
    builder.add_box((0.0, 0.58, 0.0), (0.92, 1.16, 0.30), "cave_steel_dark",
                    rotate=(0.0, 0.0, -1.0), name="pressure_housing")
    builder.add_box((0.0, 0.62, -0.175), (0.72, 0.88, 0.075), "cave_steel",
                    rotate=(0.0, 0.0, 0.7), name="service_faceplate")
    builder.add_box((0.03, 0.98, -0.224), (0.49, 0.12, 0.026), "cave_warning",
                    rotate=(0.0, 0.0, -1.7), name="heat_warning_stencil")
    builder.add_box((-0.19, 0.30, -0.224), (0.25, 0.095, 0.028), "cave_rust",
                    rotate=(0.0, 0.0, 2.6), name="scraped_service_plate")

    # Four mounting ears and oversized bolts make its eventual furnace fit feel
    # practical, while the distinct feet keep it readable as a carried module
    # when it is still sitting on the service cart.
    for index, (x, y) in enumerate(((-0.48, 0.15), (0.48, 0.15),
                                    (-0.48, 1.02), (0.48, 1.02))):
        builder.add_box((x, y, 0.04), (0.13, 0.13, 0.38), "cave_rust",
                        rotate=(0.0, 0.0, 2.0 if index % 2 else -1.2),
                        name="mounting_ear_%d" % index)
        builder.add_sphere((x, y, -0.225), (0.044, 0.044, 0.020), seg=7, rings=4,
                           mat="cave_steel_dark", name="mount_bolt_%d" % index,
                           smooth=True)
    builder.add_box((-0.29, 0.065, 0.04), (0.22, 0.09, 0.36), "cave_rust",
                    rotate=(0.0, 0.0, -2.0), name="left_mounting_foot")
    builder.add_box((0.31, 0.060, 0.04), (0.26, 0.10, 0.36), "cave_rust",
                    rotate=(0.0, 0.0, 1.3), name="right_mounting_foot")

    # The exposed paired recovery pipes deliberately use alternating steel and
    # rust.  Their return bends turn abstract machinery into something that can
    # plausibly reclaim furnace heat instead of just being another black box.
    pipe_points = [
        ((-0.27, 0.17, -0.255), (-0.27, 0.78, -0.255)),
        ((-0.27, 0.78, -0.255), (0.18, 0.78, -0.255)),
        ((0.18, 0.78, -0.255), (0.18, 0.29, -0.255)),
        ((0.18, 0.29, -0.255), (0.36, 0.29, -0.255)),
        ((-0.37, 0.24, -0.240), (-0.37, 0.98, -0.240)),
        ((-0.37, 0.98, -0.240), (0.30, 0.98, -0.240)),
        ((0.30, 0.98, -0.240), (0.30, 0.54, -0.240)),
    ]
    for index, (start, end) in enumerate(pipe_points):
        builder.add_tube(start, end, 0.032, 0.029, seg=8,
                         mat="bench_metal" if index in (1, 4, 6) else "bench_rust",
                         name="recovery_pipe_%d" % index)
    for index, (x, y) in enumerate(((-0.27, 0.78), (0.18, 0.29),
                                    (-0.37, 0.98), (0.30, 0.54))):
        builder.add_tube((x, y - 0.035, -0.255), (x, y + 0.035, -0.255),
                         0.053, 0.053, seg=9, mat="cave_steel_dark",
                         name="pipe_collar_%d" % index)

    # A physical gauge, glass-like warm indicator, two valves, and a low drain
    # make the module feel serviceable.  The indicator is modestly emissive in
    # the shared palette and is amplified by a real Godot light only once the
    # unit is installed and the furnace is burning.
    builder.add_tube((0.16, 0.50, -0.295), (0.16, 0.50, -0.330), 0.115, 0.115,
                     seg=14, mat="cave_steel", name="pressure_gauge_housing")
    builder.add_sphere((0.16, 0.50, -0.338), (0.074, 0.074, 0.018), seg=10, rings=5,
                       mat="bench_lamp_glow", name="pressure_gauge_face", smooth=True)
    builder.add_tube((0.16, 0.50, -0.355), (0.205, 0.535, -0.355), 0.010, 0.010,
                     seg=5, mat="cave_steel_dark", name="gauge_needle")
    for index, (x, y) in enumerate(((-0.49, 0.83), (0.43, 0.72))):
        builder.add_tube((x, y - 0.055, -0.25), (x, y + 0.055, -0.25), 0.070, 0.070,
                         seg=10, mat="bench_tool_handle", name="valve_hub_%d" % index)
        builder.add_box((x, y, -0.315), (0.24, 0.045, 0.028), "bench_tool_handle",
                        rotate=(0.0, 0.0, 35.0 if index == 0 else -24.0),
                        name="valve_handle_%d" % index)
    builder.add_tube((-0.06, 0.06, -0.04), (-0.06, -0.10, -0.04), 0.026, 0.026,
                     seg=7, mat="cave_rust", name="drain_stub")
    builder.add_cone((-0.06, -0.10, -0.04), 0.055, 0.11, seg=7, mat="cave_rust",
                     tilt=(180.0, 0.0, 0.0), name="drain_cap")

    # Dirt and frost remain local to seams and feet, tying the recovered unit
    # to the maintenance tunnel even after it becomes part of the warm room.
    for index, (x, y, z, sx, sy, sz) in enumerate((
            (-0.40, 0.10, -0.18, 0.14, 0.08, 0.06),
            (0.41, 0.14, -0.17, 0.12, 0.06, 0.05),
            (-0.30, 1.08, -0.18, 0.16, 0.045, 0.04))):
        builder.add_ico((x, y, z), (sx, sy, sz), subdiv=1, jitter=0.14,
                        seed=190 + index, mat="cave_ice", name="reclaimer_frost_%d" % index)

    return builder


def build_bedside_survival_kit(opened: bool = False) -> Builder:
    """Build Mara's low bedside kit, grounded at y=0.

    This is deliberately a practical footlocker rather than a mystery crate:
    it is strapped to the wall beside the cot, reinforced with scavenged steel,
    and holds the first-night flashlight and machete.  Two authored states let
    Godot swap a real closed model for the same kit opened after the player
    claims the tools.
    """
    builder = Builder()

    # Low, asymmetrical timber shell.  The offset base rails and mismatched
    # steel corners make it read as a repaired personal kit, not furniture.
    builder.add_box((0.0, 0.230, 0.0), (1.06, 0.460, 0.680), "bench_wood_dark",
                    rotate=(0.0, 0.0, -0.8), name="kit_timber_shell")
    builder.add_box((0.0, 0.075, 0.0), (1.15, 0.100, 0.750), "bench_wood",
                    rotate=(0.0, 0.0, 0.6), name="kit_base_skid")
    for index, x in enumerate((-0.47, 0.47)):
        builder.add_box((x, 0.255, -0.350), (0.085, 0.425, 0.060),
                        "bench_metal_dark", name="front_corner_guard_%d" % index)
        builder.add_box((x, 0.245, 0.350), (0.075, 0.400, 0.055),
                        "bench_rust", name="rear_corner_guard_%d" % index)
    builder.add_box((0.0, 0.350, -0.372), (0.82, 0.075, 0.045), "bench_metal",
                    rotate=(0.0, 0.0, -1.0), name="front_binding_rail")
    builder.add_box((0.0, 0.540, -0.395), (0.205, 0.115, 0.055), "bench_rust",
                    name="latch_plate")
    builder.add_box((0.0, 0.540, -0.430), (0.062, 0.145, 0.040), "bench_tool_handle",
                    name="latch_pull")
    builder.add_tube((-0.37, 0.525, 0.325), (-0.12, 0.525, 0.325), 0.021, 0.021,
                     seg=7, mat="bench_rust", name="left_hinge")
    builder.add_tube((0.12, 0.525, 0.325), (0.37, 0.525, 0.325), 0.021, 0.021,
                     seg=7, mat="bench_rust", name="right_hinge")

    if not opened:
        # Closed lid has a visible repaired seam, so the player reads it as
        # something to open before a prompt ever names it.
        builder.add_box((0.0, 0.515, 0.0), (1.10, 0.105, 0.720), "bench_wood",
                        rotate=(0.0, 0.0, 1.2), name="kit_closed_lid")
        builder.add_box((-0.12, 0.575, -0.110), (0.58, 0.022, 0.028), "bench_wood_cut",
                        rotate=(0.0, 0.0, -1.3), name="lid_repair_seam")
        builder.add_box((0.39, 0.578, 0.145), (0.22, 0.026, 0.038), "bench_rust",
                        rotate=(0.0, 0.0, 2.1), name="lid_scrap_patch")
        return builder

    # Open state: tipped lid, black lining, flashlight, and a hand-made
    # machete. Their forms make the reward readable even at first-person range.
    builder.add_box((0.0, 0.825, 0.345), (1.10, 0.105, 0.720), "bench_wood",
                    rotate=(-62.0, 0.0, 1.2), name="kit_open_lid")
    builder.add_box((0.0, 0.480, 0.0), (0.900, 0.040, 0.525), "bench_oil",
                    name="kit_oiled_lining")
    # Machete lies diagonally in a cloth loop: steel blade, rusted tang, wood
    # grip and one orange wrap so it belongs to the Basement palette.
    builder.add_box((-0.115, 0.545, -0.015), (0.095, 0.028, 0.650), "bench_metal",
                    rotate=(0.0, 0.0, 72.0), name="machete_blade")
    builder.add_box((0.205, 0.548, -0.110), (0.112, 0.042, 0.210), "bench_rust",
                    rotate=(0.0, 0.0, 72.0), name="machete_tang")
    builder.add_box((0.330, 0.555, -0.155), (0.145, 0.052, 0.230), "bench_tool_handle",
                    rotate=(0.0, 0.0, 72.0), name="machete_grip")
    builder.add_box((0.350, 0.585, -0.160), (0.052, 0.018, 0.242), "bench_canvas",
                    rotate=(0.0, 0.0, 72.0), name="machete_grip_wrap")
    # Flashlight sits beside it with a small warm lens; runtime light still
    # comes from the player, so this remains an honest static asset.
    builder.add_tube((-0.280, 0.535, -0.115), (-0.280, 0.535, 0.135), 0.062, 0.062,
                     seg=10, mat="bench_metal_dark", name="flashlight_body")
    builder.add_tube((-0.280, 0.535, 0.135), (-0.280, 0.535, 0.178), 0.083, 0.083,
                     seg=10, mat="bench_metal", name="flashlight_bezel")
    builder.add_sphere((-0.280, 0.535, 0.185), (0.061, 0.061, 0.020), seg=9, rings=5,
                       mat="bench_lamp_glow", name="flashlight_lens", smooth=True)
    builder.add_box((-0.430, 0.535, 0.125), (0.105, 0.038, 0.145), "bench_canvas",
                    rotate=(0.0, 0.0, -5.0), name="flashlight_canvas_loop")
    return builder


def build_kitchen_bench() -> Builder:
    builder = Builder()

    # Top: three boards with visible gaps, lower and rougher than the workbench,
    # plus a patched front lip where a knife has chewed the edge.
    for index, z in enumerate((-0.285, 0.0, 0.285)):
        builder.add_box((0.0, 0.885, z), (1.66, 0.055, 0.275), "bench_wood",
                        rotate=(0.0, 0.0, 0.7 if index == 1 else 0.0),
                        name="top_board_%d" % index)
    builder.add_box((0.0, 0.875, -0.395), (1.68, 0.070, 0.075), "bench_wood_dark",
                    name="front_lip")
    builder.add_box((-0.30, 0.883, -0.404), (0.34, 0.028, 0.055), "bench_wood_cut",
                    name="chewed_edge_patch")

    # Frame: nailed together, not bolted.
    for index, (x, z) in enumerate(((-0.76, -0.36), (0.76, -0.36),
                                    (-0.76, 0.36), (0.76, 0.36))):
        builder.add_box((x, 0.430, z), (0.075, 0.860, 0.075), "bench_wood_dark",
                        rotate=(0.0, 0.0, 0.6 if index % 2 else -0.4),
                        name="frame_leg_%d" % index)
    builder.add_box((0.0, 0.815, 0.335), (1.52, 0.065, 0.065), "bench_wood_dark",
                    name="rear_top_rail")
    builder.add_box((0.0, 0.300, -0.335), (1.44, 0.060, 0.060), "bench_wood_dark",
                    name="front_low_rail")
    builder.add_box((0.0, 0.285, 0.030), (1.46, 0.045, 0.590), "bench_wood",
                    rotate=(0.0, 0.0, -0.5), name="lower_shelf")

    # Splash board, hood strip and grease runs.
    builder.add_box((0.0, 1.105, 0.412), (1.64, 0.380, 0.035), "bench_wood_dark",
                    name="splash_board")
    builder.add_box((0.0, 1.300, 0.400), (1.00, 0.060, 0.070), "bench_metal_dark",
                    name="flue_hood")
    for index, x in enumerate((-0.36, -0.18, 0.02)):
        builder.add_box((x, 1.055, 0.392), (0.035, 0.240, 0.012), "bench_oil",
                        rotate=(0.0, 0.0, -4.0 + index * 3.0),
                        name="grease_run_%d" % index)

    # Dressing block with a groove worn into it.
    builder.add_box((-0.055, 0.950, 0.020), (0.500, 0.070, 0.460), "bench_wood_cut",
                    name="dressing_block")
    builder.add_box((-0.055, 0.988, -0.020), (0.440, 0.008, 0.026), "bench_oil",
                    name="block_groove")
    builder.add_box((-0.230, 0.995, 0.140), (0.060, 0.010, 0.030), "bench_metal",
                    name="cleaver_rest")

    # Dressed pile left on the board between steps.
    for index, (x, z) in enumerate(((-0.150, -0.010), (-0.090, 0.055),
                                    (-0.045, -0.050), (-0.195, 0.070))):
        builder.add_sphere((x, 0.995, z), (0.030, 0.017, 0.021), seg=7, rings=4,
                           mat="bench_rust", name="dressed_cricket_%d" % index,
                           smooth=True)

    # Pot on an iron ring, fed from the furnace line.
    builder.add_tube((-0.480, 0.930, 0.030), (-0.480, 1.120, 0.030), 0.155, 0.148,
                     seg=16, mat="bench_metal", name="pot_body")
    builder.add_tube((-0.480, 1.118, 0.030), (-0.480, 1.140, 0.030), 0.162, 0.162,
                     seg=16, mat="bench_metal_dark", name="pot_rim")
    builder.add_tube((-0.480, 1.140, 0.030), (-0.480, 1.166, 0.030), 0.160, 0.140,
                     seg=16, mat="bench_metal_dark", name="pot_lid")
    builder.add_sphere((-0.480, 1.178, 0.030), (0.036, 0.024, 0.036), seg=8, rings=5,
                       mat="bench_wood_dark", name="pot_knob", smooth=True)
    builder.add_tube((-0.480, 0.880, 0.030), (-0.480, 0.930, 0.030), 0.052, 0.052,
                     seg=10, mat="bench_rust", name="pot_duct_stub")
    for index, angle in enumerate((0.0, 2.094, 4.189)):
        x = -0.480 + math.cos(angle) * 0.150
        z = 0.030 + math.sin(angle) * 0.150
        builder.add_tube((x, 0.905, z), (x, 0.935, z), 0.013, 0.013,
                         seg=6, mat="bench_rust", name="pot_ring_leg_%d" % index)

    # Bowl of the next load, and the ladle leaning out of the pot.
    builder.add_sphere((0.115, 0.930, -0.030), (0.145, 0.062, 0.145), seg=14, rings=6,
                       mat="bench_canvas", name="dressing_bowl", smooth=True)
    for index, (x, z) in enumerate(((0.085, -0.065), (0.140, 0.010), (0.165, -0.055))):
        builder.add_sphere((x, 0.968, z), (0.026, 0.014, 0.019), seg=6, rings=4,
                           mat="bench_rust", name="bowl_cricket_%d" % index, smooth=True)
    builder.add_tube((-0.330, 1.150, 0.010), (-0.395, 0.965, -0.060), 0.012, 0.012,
                     seg=6, mat="bench_metal_dark", name="ladle_handle")
    builder.add_sphere((-0.398, 0.958, -0.065), (0.048, 0.028, 0.048), seg=9, rings=5,
                       mat="bench_metal", name="ladle_bowl", smooth=True)

    # Knife block with two worn knives.
    builder.add_box((0.590, 0.985, 0.245), (0.150, 0.220, 0.130), "bench_wood_dark",
                    rotate=(12.0, 0.0, 0.0), name="knife_block")
    for index, (x, z, tilt) in enumerate(((0.560, 0.205, -8.0), (0.625, 0.235, 6.0))):
        builder.add_tube((x, 1.090, z), (x, 1.215, z), 0.016, 0.014,
                         seg=6, mat="bench_tool_handle", name="knife_grip_%d" % index)
        builder.add_box((x, 1.255, z), (0.030, 0.140, 0.014), "bench_metal",
                        rotate=(0.0, 0.0, tilt), name="knife_blade_%d" % index)

    # Dry rack bent out of coat wire, with strips hanging.  This is the cure beat.
    for index, x in enumerate((0.480, 0.800)):
        builder.add_tube((x, 1.150, 0.330), (x, 1.560, 0.330), 0.014, 0.012,
                         seg=6, mat="bench_rust", name="rack_upright_%d" % index)
    builder.add_tube((0.470, 1.560, 0.330), (0.810, 1.560, 0.330), 0.012, 0.012,
                     seg=6, mat="bench_rust", name="rack_top_bar")
    for index, x in enumerate((0.505, 0.575, 0.645, 0.715, 0.780)):
        length = 0.180 + (index % 3) * 0.035
        builder.add_box((x, 1.470 - length * 0.5, 0.328), (0.052, length, 0.010),
                        "bench_canvas", rotate=(0.0, 0.0, -3.0 + index * 1.5),
                        name="jerky_strip_%d" % index)

    # Kitchen clutter: rag over the lip, bucket under the shelf, salvage tin.
    builder.add_box((0.700, 0.835, -0.410), (0.180, 0.190, 0.014), "bench_canvas",
                    rotate=(0.0, 0.0, 4.0), name="hanging_rag")
    builder.add_tube((-0.420, 0.120, -0.230), (-0.420, 0.360, -0.230), 0.130, 0.115,
                     seg=12, mat="bench_metal_dark", name="scrap_bucket")
    builder.add_tube((-0.420, 0.355, -0.230), (-0.420, 0.372, -0.230), 0.132, 0.132,
                     seg=12, mat="bench_rust", name="bucket_rim")
    builder.add_tube((0.320, 0.310, 0.120), (0.320, 0.450, 0.120), 0.090, 0.090,
                     seg=10, mat="bench_canvas", name="salvage_tin")

    # One low work light over the board, hooded by bent tin.
    builder.add_tube((0.780, 0.900, 0.360), (0.780, 1.430, 0.360), 0.018, 0.016,
                     seg=6, mat="bench_metal_dark", name="lamp_upright")
    builder.add_tube((0.780, 1.430, 0.360), (0.640, 1.445, 0.150), 0.016, 0.014,
                     seg=6, mat="bench_metal_dark", name="lamp_arm")
    builder.add_box((0.615, 1.408, 0.115), (0.150, 0.070, 0.130), "bench_lamp",
                    rotate=(9.0, 0.0, 0.0), name="lamp_shade")
    builder.add_box((0.615, 1.368, 0.108), (0.092, 0.016, 0.078), "bench_lamp_glow",
                    rotate=(9.0, 0.0, 0.0), name="lamp_glow")

    # Wear pass.  Every mark below is a horizontal surface somebody scrubbed and
    # failed to clean, an edge a knife caught, or a count somebody kept in chalk.
    # It is what separates a kitchen that has been used for years from a bench
    # assembled for a display.  The front of the bench is local -Z.
    builder.add_box((-0.520, 0.890, -0.285), (0.610, 0.058, 0.272), "bench_wood_grey",
                    name="top_greyed_front")
    builder.add_box((0.560, 0.890, 0.285), (0.520, 0.058, 0.272), "bench_wood_grey",
                    rotate=(0.0, 0.0, -0.5), name="top_greyed_rear")

    # Splintered lip where the knife went through the edge and nobody sanded it.
    builder.add_box((-0.640, 0.900, -0.402), (0.150, 0.022, 0.092), "bench_wood_worn",
                    rotate=(0.0, 0.0, 3.5), name="lip_splinter")
    builder.add_box((0.365, 0.899, -0.404), (0.085, 0.018, 0.080), "bench_wood_worn",
                    rotate=(0.0, 0.0, -5.0), name="lip_splinter_second")

    # Scrubbed patch where the block has been washed a thousand times.
    builder.add_box((-0.075, 0.987, 0.075), (0.280, 0.006, 0.230), "bench_wood_worn",
                    name="block_scrub_patch")
    builder.add_box((-0.310, 0.984, 0.150), (0.075, 0.007, 0.060), "bench_wood_grey",
                    rotate=(0.0, 0.0, 8.0), name="block_chip")

    # Dried rings on the lower shelf: somebody set a wet bucket down here for years.
    for index, (x, z, radius) in enumerate(((-0.240, -0.070, 0.092),
                                           (0.070, 0.125, 0.070),
                                           (0.330, -0.150, 0.056))):
        builder.add_tube((x, 0.309, z), (x, 0.313, z), radius, radius, seg=12,
                         mat="bench_stain", name="shelf_water_ring_%d" % index)

    # Grease fan and soot over the pot: the hood catches the smoke, the board
    # under it caught the rest.
    for index, (x, y, tilt) in enumerate(((-0.520, 1.150, -12.0),
                                          (-0.395, 1.055, -3.0),
                                          (-0.620, 1.020, 9.0))):
        builder.add_box((x, y, 0.392), (0.150, 0.170, 0.008), "bench_stain",
                        rotate=(0.0, 0.0, tilt), name="splash_stain_%d" % index)
    builder.add_box((-0.480, 1.268, 0.398), (0.420, 0.062, 0.018), "bench_soot",
                    name="hood_soot")
    builder.add_box((-0.480, 1.196, 0.392), (0.300, 0.088, 0.012), "bench_soot",
                    rotate=(0.0, 0.0, 6.0), name="wall_soot")

    # The count, in chalk, next to the pot: five strokes and a slash through them.
    for index in range(5):
        builder.add_box((-0.150 + index * 0.036, 1.072, 0.390), (0.009, 0.088, 0.006),
                        "bench_chalk", rotate=(0.0, 0.0, 4.0 - index * 1.7),
                        name="chalk_tally_%d" % index)
    builder.add_box((-0.062, 1.044, 0.390), (0.196, 0.009, 0.006), "bench_chalk",
                    rotate=(0.0, 0.0, -14.0), name="chalk_tally_slash")

    # Nails somebody drove by hand, heads proud of the wood.
    for index, x in enumerate((-0.700, -0.360, 0.020, 0.380, 0.720)):
        builder.add_sphere((x, 0.876, -0.436), (0.016, 0.016, 0.010), seg=6, rings=4,
                           mat="bench_metal_dark", name="nail_head_%d" % index,
                           smooth=False)

    # Personality: a chipped enamel mug and a spoon bent out of wire, left where
    # the last shift put them down.
    builder.add_tube((0.640, 0.312, -0.150), (0.640, 0.404, -0.150), 0.052, 0.044,
                     seg=10, mat="bench_enamel", name="enamel_mug")
    builder.add_tube((0.640, 0.312, -0.150), (0.640, 0.318, -0.150), 0.048, 0.048,
                     seg=10, mat="bench_stain", name="mug_inside")
    builder.add_sphere((0.694, 0.368, -0.150), (0.026, 0.026, 0.013), seg=6, rings=4,
                       mat="bench_enamel", name="mug_handle")
    builder.add_tube((0.520, 0.316, -0.020), (0.560, 0.318, 0.060), 0.008, 0.008,
                     seg=5, mat="bench_metal", name="bent_spoon_handle")
    builder.add_sphere((0.566, 0.320, 0.076), (0.026, 0.010, 0.020), seg=7, rings=4,
                       mat="bench_metal", name="bent_spoon_bowl", smooth=True)

    return builder


def build_cave_trade_drop() -> Builder:
    """Bolted steel drop box on a pallet, with a clamp and a paper slot.

    Nobody is ever visible at it, so the prop has to carry the whole fiction:
    municipal surplus, a coat of buyer paint, a paper wedged under a clamp, and
    enough rust and denting to say it has been used for years by people who
    never met the player.
    """
    builder = Builder()

    # Pallet: three deck boards over two skids, all slightly crooked.
    for index, z in enumerate((-0.30, 0.0, 0.30)):
        builder.add_box((0.0, 0.062, z), (1.18, 0.036, 0.255), "bench_wood_grey",
                        rotate=(0.0, 0.0, 1.4 if index == 1 else 0.0),
                        name="pallet_board_%d" % index)
    for index, x in enumerate((-0.44, 0.00, 0.44)):
        builder.add_box((x, 0.022, 0.0), (0.075, 0.044, 0.900), "bench_wood_dark",
                        name="pallet_skid_%d" % index)

    # Box body: two seams, so it reads as welded plate rather than one lump.
    builder.add_box((0.0, 0.360, 0.0), (1.00, 0.560, 0.700), "cave_steel",
                    name="box_body")
    builder.add_box((0.0, 0.640, 0.0), (1.02, 0.040, 0.720), "cave_steel_dark",
                    name="box_lid")
    for index, x in enumerate((-0.505, 0.505)):
        builder.add_box((x, 0.360, 0.0), (0.030, 0.560, 0.710), "cave_steel_dark",
                        name="box_corner_angle_%d" % index)
    for index, z in enumerate((-0.355, 0.355)):
        builder.add_box((0.0, 0.360, z), (1.010, 0.020, 0.030), "cave_steel_dark",
                        rotate=(0.0, 0.0, 0.0), name="box_weld_seam_%d" % index)

    # Front: hinge pair, clamp bar, padlock, paper slot with a paper in it.
    for index, x in enumerate((-0.34, 0.34)):
        builder.add_box((x, 0.600, -0.365), (0.090, 0.070, 0.024), "cave_rust",
                        name="box_hinge_%d" % index)
    builder.add_box((0.0, 0.575, -0.375), (0.860, 0.052, 0.030), "cave_steel_dark",
                    name="box_clamp_bar")
    builder.add_box((0.0, 0.575, -0.405), (0.070, 0.090, 0.055), "cave_rust",
                    name="box_clamp_handle")
    builder.add_box((0.0, 0.500, -0.398), (0.060, 0.060, 0.036), "bench_metal_dark",
                    name="box_padlock")
    builder.add_box((0.0, 0.410, -0.352), (0.300, 0.090, 0.012), "breach_soot",
                    name="paper_slot")
    builder.add_box((-0.030, 0.430, -0.368), (0.230, 0.130, 0.006), "drop_paper",
                    rotate=(0.0, 0.0, -3.0), name="paper_sheet")

    # Buyer paint and stencil plate: faded, chipped, half gone.
    builder.add_box((0.0, 0.300, -0.353), (0.980, 0.080, 0.006), "drop_paint",
                    name="paint_stripe")
    builder.add_box((-0.300, 0.208, -0.353), (0.240, 0.150, 0.006), "cave_steel_dark",
                    rotate=(0.0, 0.0, 0.0), name="stencil_plate")
    for index, x in enumerate((-0.640, 0.640)):
        builder.add_box((x, 0.420, -0.260), (0.026, 0.026, 0.180), "cave_rust",
                        name="side_bolt_%d" % index)

    # Wear: rust runs, a corner knocked in, a chain stub, boot polish on the lip.
    builder.add_box((0.360, 0.180, -0.352), (0.180, 0.230, 0.005), "cave_rust",
                    rotate=(0.0, 0.0, 7.0), name="rust_run_front")
    builder.add_box((-0.320, 0.660, -0.362), (0.260, 0.026, 0.020), "breach_soot",
                    rotate=(0.0, 0.0, 2.5), name="lip_scuff")
    builder.add_box((0.500, 0.640, 0.190), (0.120, 0.045, 0.140), "cave_steel_dark",
                    rotate=(4.0, 6.0, 0.0), name="corner_dent")
    builder.add_tube((-0.505, 0.330, 0.320), (-0.505, 0.360, 0.320), 0.055, 0.055,
                     seg=8, mat="cave_rust", name="chain_stub_lower")
    builder.add_tube((-0.505, 0.360, 0.320), (-0.470, 0.430, 0.360), 0.012, 0.012,
                     seg=6, mat="cave_rust", name="chain_stub_link")

    return builder


def build_nest_breach() -> Builder:
    """A ragged hole in the pocket's side wall with a warm throat behind it.

    The wall is a ring of broken blocks around an opening rather than a hole cut
    into a slab: the blocks give the silhouette its jagged edge, and the glow
    socket gives the darkness something to be afraid of.
    """
    builder = Builder()

    # Warm throat deep in the wall, and its soot ring.
    builder.add_box((0.0, 1.00, 0.240), (1.300, 1.700, 0.030), "breach_glow",
                    name="breach_throat")
    builder.add_box((0.0, 1.86, 0.170), (1.500, 0.240, 0.040), "breach_soot",
                    name="breach_soot_lip")
    builder.add_box((0.0, 0.110, 0.170), (1.560, 0.220, 0.040), "breach_soot",
                    name="breach_soot_sill")

    # Broken blockwork ring: staggered, rotated, different sizes, plus chips.
    blocks = [
        (-0.860, 0.520, 0.300, 0.700, 8.0), (-0.840, 1.320, 0.360, 0.620, -6.0),
        (-0.780, 2.020, 0.420, 0.380, 3.0), (0.840, 0.470, 0.320, 0.640, -5.0),
        (0.860, 1.240, 0.340, 0.660, 6.0), (0.800, 1.980, 0.400, 0.360, -4.0),
        (0.0, 2.320, 1.700, 0.300, 2.0), (0.0, 0.060, 1.900, 0.160, 0.0),
        (-0.560, 2.180, 0.300, 0.260, 10.0), (0.560, 2.200, 0.280, 0.240, -8.0),
        (-0.680, 0.900, 0.220, 0.240, 12.0), (0.700, 0.880, 0.200, 0.220, -10.0),
    ]
    for index, (x, y, width, height, tilt) in enumerate(blocks):
        builder.add_box((x, y, 0.120), (width, height, 0.240), "cave_concrete",
                        rotate=(0.0, 0.0, tilt), name="breach_block_%d" % index)
    for index, (x, y, tilt) in enumerate(((-0.520, 1.700, 18.0), (0.470, 1.560, -22.0),
                                          (-0.320, 0.360, 30.0), (0.280, 0.300, -26.0))):
        builder.add_box((x, y, 0.035), (0.240, 0.090, 0.070), "cave_concrete",
                        rotate=(0.0, 0.0, tilt), name="breach_chip_%d" % index)

    # Stained ice and the debris that fell when the wall came down.
    for index, (x, y, z, scale) in enumerate(((-0.660, 1.980, 0.010, 0.360),
                                              (0.690, 0.620, 0.010, 0.300),
                                              (-0.240, 2.180, 0.000, 0.260))):
        builder.add_sphere((x, y, z), (scale, scale * 0.34, scale * 0.22), seg=7, rings=4,
                           mat="cave_ice", name="breach_ice_%d" % index, smooth=True)
    for index, (x, z, size) in enumerate(((-0.420, -0.240, 0.140), (-0.180, -0.360, 0.110),
                                          (0.360, -0.280, 0.160), (0.560, -0.430, 0.090))):
        builder.add_box((x, 0.055 + size * 0.4, z), (size, size * 0.7, size * 0.8),
                        "cave_concrete", rotate=(0.0, 24.0 * index, 12.0),
                        name="breach_debris_%d" % index)

    return builder

def build_gland_lantern() -> Builder:
    """Build the carried gland lantern, grounded at y=0.

    It is a short chitin cage around one heat gland, with a wire bail for hanging
    it from the belt. The core is a separate emissive piece so the Godot light and
    the model agree about where the glow comes from.
    """
    builder = Builder()

    # Base plate and the ring the bars seat into.
    builder.add_disc((0.0, 0.012, 0.0), 0.082, seg=14, mat="lantern_cage_dark",
                     name="lantern_base")
    builder.add_tube((0.0, 0.020, 0.0), (0.0, 0.045, 0.0), 0.062, 0.052, seg=14,
                     mat="lantern_cage", name="lantern_base_step")

    # The gland itself: a squat core inside a warm glass column.
    builder.add_tube((0.0, 0.055, 0.0), (0.0, 0.215, 0.0), 0.052, 0.048, seg=14,
                     mat="lantern_glow", name="lantern_glass")
    builder.add_sphere((0.0, 0.132, 0.0), (0.036, 0.052, 0.036), seg=10, rings=7,
                       mat="lantern_core", name="lantern_gland", smooth=True)
    # Two dark ribs run through the gland so it reads as tissue, not a bulb.
    for index, angle in enumerate((0.0, math.pi * 0.5)):
        x = math.cos(angle) * 0.020
        z = math.sin(angle) * 0.020
        builder.add_tube((x, 0.092, z), (x * 1.4, 0.176, z * 1.4), 0.006, 0.004,
                         seg=5, mat="lantern_cage_dark", name="gland_rib_%d" % index)

    # Four corner bars over the glass, plus the top cap and its bail.
    for index in range(4):
        angle = math.tau * index / 4.0 + math.radians(45.0)
        x = math.cos(angle) * 0.062
        z = math.sin(angle) * 0.062
        builder.add_tube((x, 0.040, z), (x, 0.232, z), 0.008, 0.007, seg=6,
                         mat="lantern_cage", name="lantern_bar_%d" % index)
    builder.add_tube((0.0, 0.230, 0.0), (0.0, 0.262, 0.0), 0.070, 0.040, seg=14,
                     mat="lantern_cage", name="lantern_cap")
    builder.add_tube((0.0, 0.262, 0.0), (0.0, 0.272, 0.0), 0.040, 0.026, seg=10,
                     mat="lantern_cage_dark", name="lantern_cap_lip")

    # A bent wire bail: eight short segments over the cap.
    bail_radius = 0.058
    previous = None
    for index in range(9):
        angle = math.pi * index / 8.0
        point = (math.cos(angle) * bail_radius, 0.272 + math.sin(angle) * 0.104, 0.0)
        if previous is not None:
            builder.add_tube(previous, point, 0.006, 0.006, seg=5,
                             mat="lantern_cage_dark", name="lantern_bail_%d" % index)
        previous = point
    return builder


def build_cricket_net() -> Builder:
    """Build the hand net, grounded at y=0, hoop facing -Z (Godot forward)."""
    builder = Builder()

    # Handle: a worn wooden shaft with a metal ferrule where it meets the hoop.
    builder.add_tube((0.0, 0.0, 0.06), (0.0, 0.92, 0.14), 0.019, 0.016, seg=8,
                     mat="net_handle", name="net_shaft")
    builder.add_tube((0.0, 0.905, 0.139), (0.0, 0.955, 0.148), 0.021, 0.019,
                     seg=8, mat="net_hoop", name="net_ferrule")

    # Hoop: a single ring standing in the XY plane at the end of the shaft.
    center = (0.0, 1.130, 0.170)
    radius = 0.205
    ring = []
    for index in range(16):
        angle = math.tau * index / 16.0
        ring.append((center[0] + math.cos(angle) * radius,
                     center[1] + math.sin(angle) * radius, center[2]))
    for index in range(16):
        builder.add_tube(ring[index], ring[(index + 1) % 16], 0.008, 0.008, seg=6,
                         mat="net_hoop", name="net_hoop_%d" % index)

    # Gauze: a shallow bag behind the ring, four quads per quadrant so it reads as
    # slack mesh rather than a lid. Double-sided material keeps the inside visible.
    bag_tip = (center[0], center[1] - 0.045, center[2] + 0.230)
    for index in range(16):
        p0 = ring[index]
        p1 = ring[(index + 1) % 16]
        builder.add_quad(p0, p1, bag_tip, bag_tip, mat="net_gauze",
                         name="net_bag_%d" % index)
    return builder


def build_jar_shelf() -> Builder:
    """Build the cold store's jar shelf: two timber boards on posts, with jars and lids."""
    builder = Builder()
    # Two uprights and three shelf boards, grounded at y=0, backed against -Z.
    for x in (-0.55, 0.55):
        builder.add_box((x, 0.90, -0.14), (0.07, 1.80, 0.07), mat="cold_timber_dark",
                        name="shelf_post")
    for index, y in enumerate((0.42, 0.98, 1.54)):
        builder.add_box((0.0, y, -0.10), (1.22, 0.05, 0.30), mat="cold_timber",
                        name="shelf_board_%d" % index)
    # Jars: a glass body with a lid on each shelf, staggered so the row is not a grid.
    for row, y in enumerate((0.42, 0.98)):
        for col, x in enumerate((-0.42, -0.14, 0.14, 0.42)):
            jx = x + (0.04 if (row + col) % 2 else -0.02)
            builder.add_tube((jx, y + 0.025, -0.10), (jx, y + 0.21, -0.10), 0.055, 0.055,
                             seg=10, mat="cold_glass", name="jar_%d_%d" % (row, col))
            builder.add_tube((jx, y + 0.21, -0.10), (jx, y + 0.235, -0.10), 0.058, 0.058,
                             seg=10, mat="cold_jar_lid", name="jar_lid_%d_%d" % (row, col))
    return builder


def build_cold_frame() -> Builder:
    """Build the cold frame: a low timber box under a sloped, double-sided glass lid."""
    builder = Builder()
    # Timber box, open at the top, with a soil bed inside.
    builder.add_box((0.0, 0.14, 0.0), (1.10, 0.28, 0.70), mat="cold_timber", name="frame_box")
    builder.add_box((0.0, 0.25, 0.0), (1.00, 0.04, 0.60), mat="cold_soil", name="frame_soil")
    # Sloped lid: a glass panel hinged on the back rail and resting on a front rail.
    back = (-0.52, 0.30, 0.34)
    front = (0.52, 0.30, 0.34)
    top_back = (-0.52, 0.52, -0.34)
    top_front = (0.52, 0.42, -0.34)
    builder.add_quad(back, front, top_front, top_back, mat="cold_frame_glass", name="frame_glass")
    builder.add_tube((-0.52, 0.30, 0.34), (0.52, 0.30, 0.34), 0.022, 0.022, seg=6,
                     mat="cold_timber_dark", name="frame_front_rail")
    builder.add_tube((-0.52, 0.30, -0.36), (0.52, 0.30, -0.36), 0.022, 0.022, seg=6,
                     mat="cold_timber_dark", name="frame_back_rail")
    # Four legs.
    for index, (x, z) in enumerate(((-0.50, 0.30), (0.50, 0.30), (-0.50, -0.30), (0.50, -0.30))):
        builder.add_box((x, 0.05, z), (0.06, 0.10, 0.06), mat="cold_timber_dark",
                        name="frame_leg_%d" % index)
    return builder


def build_drain_grate() -> Builder:
    """Build the floor drain grate: a flat iron frame with slats, set flush on y=0."""
    builder = Builder()
    # Square frame.
    half = 0.30
    border = 0.05
    builder.add_box((0.0, 0.02, half - border / 2), (2 * half, 0.04, border), mat="cold_iron",
                    name="grate_front")
    builder.add_box((0.0, 0.02, -half + border / 2), (2 * half, 0.04, border), mat="cold_iron",
                    name="grate_back")
    builder.add_box((half - border / 2, 0.02, 0.0), (border, 0.04, 2 * half), mat="cold_iron",
                    name="grate_right")
    builder.add_box((-half + border / 2, 0.02, 0.0), (border, 0.04, 2 * half), mat="cold_iron",
                    name="grate_left")
    # Slats across the opening, two of them rusted through.
    for index, z in enumerate((-0.18, -0.06, 0.06, 0.18)):
        builder.add_box((0.0, 0.03, z), (2 * half - 2 * border, 0.03, 0.035),
                        mat="cold_iron_rust" if index in (1, 2) else "cold_iron",
                        name="grate_slat_%d" % index)
    return builder


def build_sealed_crate() -> Builder:
    """Build the sealed crate: a timber crate with a wax-sealed iron band and a lid."""
    builder = Builder()
    builder.add_box((0.0, 0.30, 0.0), (0.66, 0.60, 0.48), mat="cold_crate", name="crate_body")
    # Lid is a slightly wider box on top, so the seam reads as a closed lid.
    builder.add_box((0.0, 0.64, 0.0), (0.68, 0.06, 0.50), mat="cold_timber", name="crate_lid")
    # Two iron bands around the body.
    for index, x in enumerate((-0.18, 0.18)):
        builder.add_box((x, 0.30, 0.0), (0.05, 0.62, 0.50), mat="cold_iron",
                        name="crate_band_%d" % index)
    # The seal: a pale wax disc on the front face, where the band crosses it.
    builder.add_disc((0.0, 0.34, 0.245), 0.06, seg=12, mat="cold_seal",
                     rot=(math.pi / 2, 0.0, 0.0), name="crate_seal")
    return builder


def build_parcel() -> Builder:
    """Build the order parcel: a kraft box with tape across the lid and a label."""
    builder = Builder()
    builder.add_box((0.0, 0.11, 0.0), (0.30, 0.22, 0.24), mat="parcel_kraft", name="parcel_body")
    # Tape strip running along the lid and down both long sides.
    builder.add_box((0.0, 0.223, 0.0), (0.04, 0.006, 0.25), mat="parcel_tape", name="parcel_tape_top")
    builder.add_box((0.0, 0.11, 0.0), (0.04, 0.22, 0.248), mat="parcel_tape", name="parcel_tape_front")
    # Paper label on the front face, offset from the tape.
    builder.add_box((-0.07, 0.13, 0.126), (0.13, 0.09, 0.004), mat="parcel_label", name="parcel_label")
    return builder

