"""Source models for Basement Farm cave creatures.

Models are authored in metres, Y up, and face -Z so they can be dropped into a
Godot CharacterBody3D without a corrective rotation.  This module deliberately
contains anatomy and proportions only; movement lives in creature_anims.py and
behaviour lives in the game's GDScript.
"""
from __future__ import annotations

import math

import numpy as np

from mesh import Builder
from skin import Rig


def ground_align(builder: Builder, rig: Rig | None) -> float:
    """Put the lowest generated point at y=0, including skeleton joints."""
    lowest = min(float(piece.verts[:, 1].min()) for piece in builder.pieces)
    if abs(lowest) < 1e-6:
        return 0.0
    shift = np.array([0.0, lowest, 0.0])
    for piece in builder.pieces:
        piece.verts = piece.verts - shift
    if rig is not None:
        for bone in rig.bones:
            bone.pos = bone.pos - shift
            if bone.tip is not None:
                bone.tip = bone.tip - shift
    return -lowest


def _slime_profile(angle: float) -> tuple[float, float]:
    """A soft irregular cross-section, avoiding a featureless ball silhouette."""
    return (
        1.0 + 0.075 * math.sin(angle * 3.0) + 0.035 * math.cos(angle * 5.0),
        1.0 + 0.045 * math.cos(angle * 2.0),
    )


def build_slime(materials: dict | None = None) -> tuple[Builder, Rig]:
    """Build the blind heat-slime used by Basement Farm's hunt loop.

    It is a low, broad animal, not a perfect blob: one continuous mantle grips
    the floor, two side-skirts ripple while it crawls, and dark heat/scent pits
    explain why it tracks bait without normal eyes.
    """
    builder = Builder()

    def _pick(name: str) -> str:
        """Material name, remapped for a variant (the cinder burrower)."""
        return materials.get(name, name) if materials else name

    def body_material(center, normal):
        # Material bands make the wet mantle read as volume even when cave
        # lighting is weak. They are part of the generated geometry, not a
        # painted texture glued on in gameplay code.
        if center[1] < 0.12:
            return _pick("slime_membrane_dark")
        if normal[1] > 0.45 and center[2] > -0.12 and abs(center[0]) < 0.22:
            return _pick("slime_mottle")
        return _pick("slime_membrane")

    # A single mantle runs from the blunt sensing face through a heavy middle
    # to a soft taper. Front/back/core bones deform this as a wave, making it
    # feel like an animal pushing against the floor rather than a scaled sphere.
    builder.add_loft([
        # A broad first cap makes the front a blunt feeding face. A narrow
        # cap reads as a tail when viewed through the hunt-room doorway.
        {"pos": (0.0, 0.220, -0.72), "rx": 0.31, "ry": 0.220},
        {"pos": (0.0, 0.275, -0.54), "rx": 0.37, "ry": 0.260},
        {"pos": (0.0, 0.305, -0.20), "rx": 0.43, "ry": 0.305},
        {"pos": (0.0, 0.285, 0.18), "rx": 0.42, "ry": 0.280},
        {"pos": (0.0, 0.190, 0.52), "rx": 0.28, "ry": 0.180},
        {"pos": (0.0, 0.110, 0.76), "rx": 0.12, "ry": 0.100},
    ], seg=12, mat=body_material,
       bones=["root", "front", "core", "back", "tail"], name="continuous_mantle",
       smooth=True, shape=_slime_profile)

    # Three small dorsal heat glands replace the old floating internal orb.
    # They read as living tissue without depending on unreliable transparency
    # sorting in the Compatibility renderer.
    gland_specs = [
        ((0.0, 0.588, -0.155), (0.082, 0.027, 0.078)),
        ((-0.125, 0.535, 0.088), (0.053, 0.020, 0.058)),
        ((0.130, 0.495, 0.240), (0.040, 0.017, 0.047)),
    ]
    for index, (position, radii) in enumerate(gland_specs):
        builder.add_sphere(position, radii, seg=7, rings=4, mat=_pick("slime_core"),
                           bones=["core", "back"], name="heat_gland_%d" % index,
                           smooth=True)

    # These are scent/heat pores, deliberately grouped asymmetrically so the
    # creature never reads as a generic two-eyed monster.
    builder.add_sphere((-0.160, 0.235, -0.735), (0.032, 0.025, 0.014),
                       seg=7, rings=4, mat=_pick("slime_pit"), bones=["front"],
                       name="lower_scent_pore", smooth=True)
    builder.add_sphere((-0.100, 0.305, -0.730), (0.025, 0.020, 0.012),
                       seg=7, rings=4, mat=_pick("slime_pit"), bones=["front"],
                       name="upper_scent_pore", smooth=True)
    builder.add_sphere((0.185, 0.180, -0.735), (0.022, 0.017, 0.010),
                       seg=7, rings=4, mat=_pick("slime_pit"), bones=["front"],
                       name="side_scent_pore", smooth=True)
    # The feeding aperture is a shallow, wide slit set into the front, not a
    # toothy mouth. It gives the animal a clear function without humanising it.
    builder.add_sphere((-0.005, 0.142, -0.724), (0.155, 0.062, 0.012),
                       seg=9, rings=5, mat=_pick("slime_seam"), bones=["front"],
                       name="feeding_aperture", smooth=True)

    # Rippling side-skirts are part of the locomotion anatomy, not legs. They
    # hug the mantle instead of floating around it as disconnected blobs.
    for side, name in ((-1.0, "skirt_L"), (1.0, "skirt_R")):
        builder.add_loft([
            {"pos": (side * 0.295, 0.125, -0.360), "rx": 0.070, "ry": 0.058},
            {"pos": (side * 0.420, 0.075, -0.060), "rx": 0.080, "ry": 0.042},
            {"pos": (side * 0.370, 0.062, 0.315), "rx": 0.065, "ry": 0.035},
        ], seg=7, mat=_pick("slime_membrane_dark"), bones=[name, "root", "back"],
           name=name, smooth=True, shape=_slime_profile)

    rig = Rig("BasementSlimeArmature")
    rig.add("root", None, (0.0, 0.070, 0.06), tip=(0.0, 0.070, -0.18))
    rig.add("front", "root", (0.0, 0.235, -0.410), tip=(0.0, 0.205, -0.750))
    rig.add("core", "front", (0.0, 0.355, -0.110), tip=(0.0, 0.560, -0.135))
    rig.add("back", "root", (0.0, 0.250, 0.230), tip=(0.0, 0.175, 0.540))
    rig.add("tail", "back", (0.0, 0.175, 0.540), tip=(0.0, 0.100, 0.780))
    rig.add("skirt_L", "root", (-0.280, 0.110, -0.215),
            tip=(-0.430, 0.060, 0.300))
    rig.add("skirt_R", "root", (0.280, 0.110, -0.215),
            tip=(0.430, 0.060, 0.300))

    ground_align(builder, rig)
    return builder, rig


# C2 // the cinder burrower is the same animal under the breach.  The variant is a
# material remap and a scale applied by the game, not a second rig: the clips, the
# bones and the silhouette stay identical so one animation set serves both.
CINDER_MATERIALS = {
    "slime_membrane": "cinder_membrane",
    "slime_membrane_dark": "cinder_membrane_dark",
    "slime_mottle": "cinder_mottle",
    "slime_core": "cinder_core",
    "slime_pit": "cinder_pit",
    "slime_seam": "cinder_seam",
}


def build_cinder_burrower() -> tuple[Builder, Rig]:
    """Build the breach variant: burnt orange mantle, hot seams, same rig."""
    return build_slime(CINDER_MATERIALS)
