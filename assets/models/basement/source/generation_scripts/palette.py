"""Material palette for Basement Farm generated assets.

Colours live here rather than in gameplay code so a creature can be rebuilt,
previewed, and exported without opening Godot.  Values are sRGB hex strings;
the GLB exporter converts them to linear colour space.
"""
from __future__ import annotations


# name: (sRGB hex, roughness, metallic, double_sided)
MATERIALS = {
    "slime_membrane":      ("#314D22", 0.76, 0.0, False),
    "slime_membrane_dark": ("#182B15", 0.84, 0.0, False),
    "slime_mottle":        ("#526333", 0.78, 0.0, False),
    "slime_core":          ("#973D20", 0.54, 0.0, False),
    "slime_pit":           ("#17160C", 0.62, 0.0, False),
    "slime_seam":          ("#24100D", 0.62, 0.0, False),
    "slime_glint":         ("#8EA34A", 0.34, 0.0, False),
    # Salvaged workbench.  These intentionally sit away from the slime palette:
    # the station should read as old wood, cold steel, soot and work-light, not
    # as another green prop swallowed by the basement lighting.
    "bench_wood":          ("#4A2D1D", 0.92, 0.0, False),
    "bench_wood_cut":      ("#7A4A27", 0.86, 0.0, False),
    "bench_wood_dark":     ("#261A14", 0.97, 0.0, False),
    "bench_metal":         ("#44515A", 0.34, 0.86, False),
    "bench_metal_dark":    ("#20292D", 0.58, 0.78, False),
    "bench_rust":          ("#713020", 0.88, 0.54, False),
    "bench_oil":           ("#16120F", 0.32, 0.15, False),
    "bench_canvas":        ("#786846", 0.95, 0.0, False),
    "patch_canvas":        ("#8B7851", 0.96, 0.0, False),
    "patch_hide":          ("#51351E", 0.92, 0.0, False),
    "bench_tool_handle":   ("#A86D2C", 0.72, 0.0, False),
    # Kitchen bench aging.  The bench has been scrubbed, scalded and knifed for
    # years: bleached grain, pale splinters, water rings, soot, and chalk tally
    # marks left by whoever kept the count.
    "bench_wood_grey":     ("#5A5044", 0.95, 0.0, False),
    "bench_wood_worn":     ("#8A5B33", 0.90, 0.0, False),
    "bench_stain":         ("#2B1C12", 0.42, 0.08, False),
    "bench_soot":          ("#141210", 0.96, 0.0, False),
    "bench_chalk":         ("#B9B3A2", 0.88, 0.0, False),
    "bench_enamel":        ("#7C7E6E", 0.52, 0.10, False),
    "bench_lamp":          ("#D9822D", 0.40, 0.45, False),
    "bench_lamp_glow":     ("#FFD070", 0.26, 0.05, False),
    # Frozen maintenance tunnel.  This deliberately extends the Basement
    # palette instead of borrowing bright fantasy-cave colours: corroded
    # municipal steel, old concrete, frost, and one tired sodium warning lamp.
    "cave_steel":          ("#42525A", 0.42, 0.88, False),
    "cave_steel_dark":     ("#1C282D", 0.66, 0.74, False),
    "cave_rust":           ("#663326", 0.90, 0.48, False),
    "cave_concrete":       ("#4C504C", 0.94, 0.02, False),
    "cave_ice":            ("#5D8790", 0.70, 0.02, False),
    "cave_warning":        ("#B66A22", 0.66, 0.32, False),
    # C2 // cave trade drop and the nest breach.  The drop is municipal steel with
    # a coat of faded buyer paint; the breach is the warm throat of something else.
    "drop_paint":          ("#A8976C", 0.82, 0.0, False),
    "drop_paper":          ("#C9C0A4", 0.90, 0.0, False),
    "breach_glow":         ("#8A3B14", 0.55, 0.0, False),
    "breach_soot":         ("#191512", 0.97, 0.0, False),
    "cave_lamp":           ("#D99A3C", 0.42, 0.35, False),
    "cave_lamp_glow":      ("#FFD68A", 0.22, 0.03, False),
    # C2 // the gland lantern and the cricket net.  The lantern holds a heat gland
    # behind chitin bars, so its light is warm and low rather than a flame.
    "lantern_cage":        ("#9A7A3E", 0.58, 0.62, False),
    "lantern_cage_dark":   ("#4E3A1C", 0.72, 0.55, False),
    "lantern_core":        ("#C9702A", 0.34, 0.0, False),
    "lantern_glow":        ("#FFD694", 0.20, 0.02, False),
    "net_handle":          ("#8A5A2C", 0.74, 0.0, False),
    "net_hoop":            ("#7C8580", 0.44, 0.72, False),
    "net_gauze":           ("#B9B49C", 0.92, 0.0, True),
    # C2 // cinder burrower variant: the same body under the breach, burnt orange
    # with seams that hold their own heat.
    "cinder_membrane":     ("#8A3A0F", 0.42, 0.02, False),
    "cinder_membrane_dark":("#4A1D07", 0.55, 0.02, False),
    "cinder_mottle":       ("#B4551A", 0.38, 0.02, False),
    "cinder_core":         ("#FF8A2A", 0.30, 0.0, False),
    "cinder_pit":          ("#220D04", 0.80, 0.0, False),
    "cinder_seam":         ("#FF6A18", 0.30, 0.0, False),
    # C4 // the cold store: a root cellar with shelving, a cold frame, a drain and
    # a sealed crate. Bare timber, cold glass and galvanised iron.
    "cold_timber":         ("#6B4A2B", 0.82, 0.0, False),
    "cold_timber_dark":    ("#3E2B18", 0.86, 0.0, False),
    "cold_glass":          ("#A9C4C0", 0.12, 0.0, False),
    "cold_jar_lid":        ("#8E6A3A", 0.55, 0.30, False),
    "cold_soil":           ("#2E2418", 0.96, 0.0, False),
    "cold_frame_glass":    ("#8FB5AE", 0.10, 0.0, True),
    "cold_iron":           ("#5E6661", 0.48, 0.70, False),
    "cold_iron_rust":      ("#7A4A2A", 0.78, 0.35, False),
    "cold_crate":          ("#7D6A4C", 0.70, 0.0, False),
    "cold_seal":           ("#B8B2A0", 0.60, 0.20, False),
    # Order parcel: kraft card, pale tape and a paper label for the buyer.
    "parcel_kraft":        ("#9C7A4E", 0.88, 0.0, False),
    "parcel_tape":         ("#D9C9A0", 0.55, 0.0, False),
    "parcel_label":        ("#E6DCC4", 0.80, 0.0, False),
}


# Optional glTF properties beyond the shared PBR palette tuple.  The membrane
# is deliberately only slightly transparent: it reveals the core at close
# range without turning the creature into a glass sphere under cave lighting.
GLTF_OPTIONS = {
    "slime_membrane": {"emissive": (0.003, 0.008, 0.001)},
    "slime_core": {"emissive": (0.065, 0.008, 0.002)},
    "slime_glint": {"emissive": (0.012, 0.018, 0.003)},
    "bench_lamp_glow": {"emissive": (0.82, 0.31, 0.045)},
    "cave_lamp_glow": {"emissive": (0.72, 0.32, 0.06)},
    "breach_glow": {"emissive": (0.46, 0.14, 0.03)},
    "lantern_glow": {"emissive": (0.95, 0.55, 0.18)},
    "lantern_core": {"emissive": (0.32, 0.10, 0.03)},
    "cinder_membrane": {"emissive": (0.30, 0.07, 0.01)},
    "cinder_core": {"emissive": (0.55, 0.18, 0.03)},
    "cinder_seam": {"emissive": (0.42, 0.12, 0.02)},
}


def material(name: str):
    """Return (hex, roughness, metallic, double_sided) for an entry."""
    return MATERIALS[name]


def rgb(name: str) -> tuple[float, float, float]:
    """Return the authored sRGB colour as a 0..1 tuple for preview rendering."""
    value = MATERIALS[name][0].lstrip("#")
    return tuple(int(value[index:index + 2], 16) / 255.0
                 for index in (0, 2, 4))


def gltf_options(name: str) -> dict:
    """Return optional GLB material settings without exposing mutable state."""
    return dict(GLTF_OPTIONS.get(name, {}))
