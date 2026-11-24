"""Build, preview, and structurally validate Basement Farm generated assets.

Run from this directory using Blender's bundled Python, which has the NumPy
runtime this project needs:

    blender --background --python build.py
"""
from __future__ import annotations

import datetime
import json
import os
import sys

import numpy as np

# Blender's --python mode does not consistently put the script directory on
# sys.path, unlike a normal `python build.py` invocation.
HERE = os.path.dirname(os.path.abspath(__file__))
if HERE not in sys.path:
    sys.path.insert(0, HERE)

import note
import validate
import verify_anim
from creature_anims import build_slime_clips
from creatures import build_cinder_burrower, build_slime
from model import Model
from props import (build_bedside_survival_kit, build_frozen_maintenance_cart, build_frozen_maintenance_portal,
                    build_cave_trade_drop, build_cricket_net, build_furnace_heat_reclaimer,
                    build_gland_lantern, build_hunt_snare,
                    build_kitchen_bench, build_nest_breach,
                    build_salvaged_workbench, build_wall_insulation_patch, build_warm_storage_rack,
                    build_jar_shelf, build_cold_frame, build_drain_grate, build_sealed_crate,
                    build_parcel)

try:
    import preview
except ModuleNotFoundError:
    # The build still creates a valid GLB under Blender's bundled Python, which
    # has NumPy but no Pillow. Visual QA then comes from the Godot screenshot
    # runner; a Pillow-enabled interpreter additionally writes the contact
    # sheet below.
    preview = None


BASEMENT_MODELS = os.path.abspath(os.path.join(HERE, "..", ".."))
GENERATED = os.path.join(BASEMENT_MODELS, "generated")
SLIME_RELATIVE = os.path.join("creatures", "slime", "basement_slime.glb")
WORKBENCH_RELATIVE = os.path.join("props", "salvaged_workbench.glb")
INSULATION_PATCH_RELATIVE = os.path.join("props", "wall_insulation_patch.glb")
HUNT_SNARE_RELATIVE = os.path.join("props", "hunt_snare.glb")
WARM_STORAGE_RACK_RELATIVE = os.path.join("props", "warm_storage_rack.glb")
FROZEN_MAINTENANCE_PORTAL_RELATIVE = os.path.join("props", "frozen_maintenance_portal.glb")
FROZEN_MAINTENANCE_CART_RELATIVE = os.path.join("props", "frozen_maintenance_cart.glb")
FURNACE_HEAT_RECLAIMER_RELATIVE = os.path.join("props", "furnace_heat_reclaimer.glb")
BEDSIDE_KIT_CLOSED_RELATIVE = os.path.join("props", "bedside_survival_kit_closed.glb")
BEDSIDE_KIT_OPEN_RELATIVE = os.path.join("props", "bedside_survival_kit_open.glb")
KITCHEN_BENCH_RELATIVE = os.path.join("props", "kitchen_bench.glb")
CAVE_TRADE_DROP_RELATIVE = os.path.join("props", "cave_trade_drop.glb")
NEST_BREACH_RELATIVE = os.path.join("props", "nest_breach.glb")
GLAND_LANTERN_RELATIVE = os.path.join("props", "gland_lantern.glb")
CRICKET_NET_RELATIVE = os.path.join("props", "cricket_net.glb")
JAR_SHELF_RELATIVE = os.path.join("props", "cold_store_jar_shelf.glb")
COLD_FRAME_RELATIVE = os.path.join("props", "cold_store_cold_frame.glb")
DRAIN_GRATE_RELATIVE = os.path.join("props", "cold_store_drain_grate.glb")
SEALED_CRATE_RELATIVE = os.path.join("props", "cold_store_sealed_crate.glb")
PARCEL_RELATIVE = os.path.join("props", "order_parcel.glb")
CINDER_BURROWER_RELATIVE = os.path.join("creatures", "cinder_burrower", "cinder_burrower.glb")


def _bounds(builder) -> dict:
    lows = [piece.verts.min(axis=0) for piece in builder.pieces]
    highs = [piece.verts.max(axis=0) for piece in builder.pieces]
    low = lows[0].copy()
    high = highs[0].copy()
    for value in lows[1:]:
        low = np.minimum(low, value)
    for value in highs[1:]:
        high = np.maximum(high, value)
    dimensions = high - low
    return {
        "min_m": [round(float(value), 4) for value in low],
        "max_m": [round(float(value), 4) for value in high],
        "dimensions_m": {
            "width_x": round(float(dimensions[0]), 4),
            "height_y": round(float(dimensions[1]), 4),
            "length_z": round(float(dimensions[2]), 4),
        },
    }


def _write_previews(model: Model, clips) -> str | None:
    if preview is None:
        print("Preview sheet skipped: Pillow is unavailable in this Python runtime.")
        return None
    output = os.path.join(GENERATED, "documentation", "previews")
    os.makedirs(output, exist_ok=True)
    images = []
    for clip in clips:
        for fraction in (0.0, 0.5):
            time = clip.duration * fraction
            image = preview.render(
                model, None, yaw=-34, pitch=14, size=(460, 340), ss=1,
                pose=clip.pose_fn(time),
            )
            images.append(image)
    path = os.path.join(output, "basement_slime_poses.png")
    preview.contact_sheet(images, 3, path)
    return path


def _build_slime_entry() -> dict:
    """Build the rigged creature and return its manifest record."""
    builder, rig = build_slime()
    model = Model("BasementSlime", builder, rig)
    clips = build_slime_clips()
    for clip in clips:
        model.add_clip(clip)

    output_path = os.path.join(GENERATED, SLIME_RELATIVE)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    export = model.export(output_path)
    check = validate.validate(output_path)
    if not check["ok"]:
        raise RuntimeError("GLB validation failed: " + "; ".join(check["issues"]))
    animation_check = verify_anim.verify(output_path, verbose=False)
    if not animation_check["ok"]:
        raise RuntimeError("Animation verification failed: %.5f mm" %
                           animation_check["worst_key_error_mm"])

    preview_path = _write_previews(model, clips)
    return {
        "id": "basement_slime",
        "file": SLIME_RELATIVE.replace("\\", "/"),
        "name": "Blind heat slime",
        "kind": "creature",
        "description": "A blind, warmth- and scent-seeking cave prey animal.",
        "rigged": True,
        "triangles": export["triangles"],
        "vertices": export["vertices"],
        "bones": export["bones"],
        "animations": [{"name": clip.name, "duration_s": clip.duration,
                        "loop": clip.loop, "description": clip.description}
                       for clip in clips],
        "validation": {"ok": check["ok"], "issues": check["issues"]},
        "animation_verification": animation_check,
        "preview": (os.path.relpath(preview_path, GENERATED).replace("\\", "/")
                    if preview_path else None),
        **_bounds(builder),
    }


def _build_static_entry(asset_id: str, name: str, kind: str, description: str,
                        relative_path: str, model_name: str, builder) -> dict:
    """Export one static generated prop and return its manifest record."""
    model = Model(model_name, builder)
    output_path = os.path.join(GENERATED, relative_path)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    export = model.export(output_path)
    check = validate.validate(output_path)
    if not check["ok"]:
        raise RuntimeError("GLB validation failed: " + "; ".join(check["issues"]))
    return {
        "id": asset_id,
        "file": relative_path.replace("\\", "/"),
        "name": name,
        "kind": kind,
        "description": description,
        "rigged": False,
        "triangles": export["triangles"],
        "vertices": export["vertices"],
        "bones": export["bones"],
        "animations": [],
        "validation": {"ok": check["ok"], "issues": check["issues"]},
        "animation_verification": None,
        "preview": None,
        **_bounds(builder),
    }


def _build_workbench_entry() -> dict:
    """Build the static physical crafting station and return its manifest record."""
    return _build_static_entry(
        "salvaged_workbench", "Salvaged workbench", "base_prop",
        "A rebuilt timber and angle-iron bench for shaping bolts, medicine, and insulation.",
        WORKBENCH_RELATIVE, "SalvagedWorkbench", build_salvaged_workbench())


def _build_insulation_patch_entry() -> dict:
    """Build the visible base-repair result and return its manifest record."""
    return _build_static_entry(
        "wall_insulation_patch", "Wall insulation patch", "base_upgrade",
        "A hide, cloth, timber and scrap repair panel installed over a basement draft.",
        INSULATION_PATCH_RELATIVE, "WallInsulationPatch", build_wall_insulation_patch())


def _build_hunt_snare_entry() -> dict:
    """Build the bait-side tactical trap and return its manifest record."""
    return _build_static_entry(
        "hunt_snare", "Hunt floor snare", "hunt_prop",
        "A bait-side wire loop and tension spool that briefly holds prey in the hunt chamber.",
        HUNT_SNARE_RELATIVE, "HuntSnare", build_hunt_snare())


def _build_warm_storage_rack_entry() -> dict:
    """Build the visible storage/heat-lamp home upgrade and return its record."""
    return _build_static_entry(
        "warm_storage_rack", "Warm storage rack", "base_upgrade",
        "A salvaged shelf with ration crates, supplies, a furnace-line coil, and a small heat lamp.",
        WARM_STORAGE_RACK_RELATIVE, "WarmStorageRack", build_warm_storage_rack())


def _build_frozen_maintenance_portal_entry() -> dict:
    """Build the reusable, physical landmark at the first cave entrance."""
    return _build_static_entry(
        "frozen_maintenance_portal", "Frozen maintenance portal", "cave_prop",
        "A damaged support bay with frozen pipes and a weak emergency lamp, marking the route beneath the house.",
        FROZEN_MAINTENANCE_PORTAL_RELATIVE, "FrozenMaintenancePortal",
        build_frozen_maintenance_portal())


def _build_frozen_maintenance_cart_entry() -> dict:
    """Build the Cold Junction's authored service-cart landmark."""
    return _build_static_entry(
        "frozen_maintenance_cart", "Frozen maintenance cart", "cave_prop",
        "An abandoned service cart with a dead battery, frozen canisters, and a severed route cable.",
        FROZEN_MAINTENANCE_CART_RELATIVE, "FrozenMaintenanceCart",
        build_frozen_maintenance_cart())


def _build_furnace_heat_reclaimer_entry() -> dict:
    """Build the first recoverable cave component and visible base retrofit."""
    return _build_static_entry(
        "furnace_heat_reclaimer", "C-4 furnace heat reclaimer", "expedition_upgrade",
        "A recovered maintenance heat exchanger that makes the home furnace burn longer and warmer.",
        FURNACE_HEAT_RECLAIMER_RELATIVE, "FurnaceHeatReclaimer",
        build_furnace_heat_reclaimer())


def _build_kitchen_bench_entry() -> dict:
    """Build the C2 culture kitchen station and return its manifest record."""
    return _build_static_entry(
        "kitchen_bench", "Cricket kitchen bench", "base_prop",
        "A scavenged prep board, furnace-fed pot, knife block and coat-wire curing rack.",
        KITCHEN_BENCH_RELATIVE, "KitchenBench", build_kitchen_bench())


def _build_cave_trade_drop_entry() -> dict:
    """Build the C2 cave trade drop and return its manifest record."""
    return _build_static_entry(
        "cave_trade_drop", "Cave trade drop", "base_prop",
        "Bolted steel drop box on a pallet, with a clamp, a paper slot and faded buyer paint.",
        CAVE_TRADE_DROP_RELATIVE, "CaveTradeDrop", build_cave_trade_drop())


def _build_nest_breach_entry() -> dict:
    """Build the C2 nest breach and return its manifest record."""
    return _build_static_entry(
        "nest_breach", "Nest breach", "base_prop",
        "A ragged hole of broken blockwork, stained ice and a warm throat behind it.",
        NEST_BREACH_RELATIVE, "NestBreach", build_nest_breach())


def _build_gland_lantern_entry() -> dict:
    """Build the carried gland lantern and return its manifest record."""
    return _build_static_entry(
        "gland_lantern", "Gland lantern", "tool_prop",
        "A chitin cage around one heat gland, with a wire bail for the belt.",
        GLAND_LANTERN_RELATIVE, "GlandLantern", build_gland_lantern())


def _build_cricket_net_entry() -> dict:
    """Build the cricket net and return its manifest record."""
    return _build_static_entry(
        "cricket_net", "Cricket net", "tool_prop",
        "A worn wooden shaft, a steel hoop and a slack gauze bag for taking a tray alive.",
        CRICKET_NET_RELATIVE, "CricketNet", build_cricket_net())


def _build_jar_shelf_entry() -> dict:
    """Build the cold store's jar shelf and return its manifest record."""
    return _build_static_entry(
        "cold_store_jar_shelf", "Cold store jar shelf", "base_prop",
        "Timber shelving in the root cellar, holding sealed jars of preserved stock.",
        JAR_SHELF_RELATIVE, "ColdStoreJarShelf", build_jar_shelf())


def _build_cold_frame_entry() -> dict:
    """Build the cold store's cold frame and return its manifest record."""
    return _build_static_entry(
        "cold_store_cold_frame", "Cold store cold frame", "base_prop",
        "A low timber frame under a sloped glass lid, for holding a bed of cold-hardy greens.",
        COLD_FRAME_RELATIVE, "ColdStoreColdFrame", build_cold_frame())


def _build_drain_grate_entry() -> dict:
    """Build the cold store's floor drain grate and return its manifest record."""
    return _build_static_entry(
        "cold_store_drain_grate", "Cold store drain grate", "cave_prop",
        "A flush iron grate over the cellar drain, two slats rusted through.",
        DRAIN_GRATE_RELATIVE, "ColdStoreDrainGrate", build_drain_grate())


def _build_sealed_crate_entry() -> dict:
    """Build the cold store's sealed crate and return its manifest record."""
    return _build_static_entry(
        "cold_store_sealed_crate", "Cold store sealed crate", "cave_prop",
        "A timber crate with iron bands and a pale wax seal, left untouched in the cellar.",
        SEALED_CRATE_RELATIVE, "ColdStoreSealedCrate", build_sealed_crate())


def _build_cinder_burrower_entry() -> dict:
    """Build the breach variant of the slime and return its manifest record."""
    builder, rig = build_cinder_burrower()
    model = Model("CinderBurrower", builder, rig)
    clips = build_slime_clips()
    for clip in clips:
        model.add_clip(clip)

    output_path = os.path.join(GENERATED, CINDER_BURROWER_RELATIVE)
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    export = model.export(output_path)
    check = validate.validate(output_path)
    if not check["ok"]:
        raise RuntimeError("GLB validation failed: " + "; ".join(check["issues"]))
    animation_check = verify_anim.verify(output_path, verbose=False)
    if not animation_check["ok"]:
        raise RuntimeError("Animation verification failed: %.5f mm" %
                           animation_check["worst_key_error_mm"])
    return {
        "id": "cinder_burrower",
        "file": CINDER_BURROWER_RELATIVE.replace("\\", "/"),
        "name": "Cinder burrower",
        "kind": "creature",
        "description": "The breach variant: the same blind burrower, burnt orange with hot seams.",
        "rigged": True,
        "triangles": export["triangles"],
        "vertices": export["vertices"],
        "bones": export["bones"],
        "animations": [{"name": clip.name, "duration_s": clip.duration,
                        "loop": clip.loop, "description": clip.description}
                       for clip in clips],
        "validation": {"ok": check["ok"], "issues": check["issues"]},
        "animation_verification": animation_check,
        "preview": None,
        **_bounds(builder),
    }


def _build_bedside_kit_entries() -> tuple[dict, dict]:
    """Build the closed and opened states of the first-night survival kit."""
    closed = _build_static_entry(
        "bedside_survival_kit_closed", "Closed bedside survival kit", "base_prop",
        "A low repaired footlocker beside the cot, holding the first-night tools.",
        BEDSIDE_KIT_CLOSED_RELATIVE, "BedsideSurvivalKitClosed",
        build_bedside_survival_kit(False))
    opened = _build_static_entry(
        "bedside_survival_kit_open", "Opened bedside survival kit", "base_prop",
        "The opened bedside kit with the flashlight and machete laid out inside.",
        BEDSIDE_KIT_OPEN_RELATIVE, "BedsideSurvivalKitOpen",
        build_bedside_survival_kit(True))
    return closed, opened


def build() -> dict:
    """Build all current Basement-generated assets and return their manifest."""
    slime_entry = _build_slime_entry()
    workbench_entry = _build_workbench_entry()
    patch_entry = _build_insulation_patch_entry()
    snare_entry = _build_hunt_snare_entry()
    storage_rack_entry = _build_warm_storage_rack_entry()
    maintenance_portal_entry = _build_frozen_maintenance_portal_entry()
    maintenance_cart_entry = _build_frozen_maintenance_cart_entry()
    heat_reclaimer_entry = _build_furnace_heat_reclaimer_entry()
    bedside_kit_closed_entry, bedside_kit_open_entry = _build_bedside_kit_entries()
    kitchen_bench_entry = _build_kitchen_bench_entry()
    trade_drop_entry = _build_cave_trade_drop_entry()
    nest_breach_entry = _build_nest_breach_entry()
    gland_lantern_entry = _build_gland_lantern_entry()
    cricket_net_entry = _build_cricket_net_entry()
    cinder_burrower_entry = _build_cinder_burrower_entry()
    jar_shelf_entry = _build_jar_shelf_entry()
    cold_frame_entry = _build_cold_frame_entry()
    drain_grate_entry = _build_drain_grate_entry()
    sealed_crate_entry = _build_sealed_crate_entry()
    parcel_entry = _build_static_entry(
        "order_parcel", "Order parcel", "prop",
        "A kraft parcel taped shut with a paper label, packed for a cave order.",
        PARCEL_RELATIVE, "OrderParcel", build_parcel())
    note_relative = os.path.join("props", "order_note.png")
    note.build_order_note(os.path.join(GENERATED, note_relative))
    manifest = {
        "pack": "Basement Farm Generated Assets",
        "version": "0.5.0",
        "generated": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "engine": "Godot 4 / glTF 2.0",
        "units": "metres",
        "axes": {"up": "+Y", "forward": "-Z (Godot forward)", "right": "+X"},
        "source_pipeline": "Riverborn-style procedural mesh, Rig, Clip, GLB export, validation, preview",
        "assets": [slime_entry, workbench_entry, patch_entry, snare_entry, storage_rack_entry,
                   maintenance_portal_entry, maintenance_cart_entry, heat_reclaimer_entry,
                   bedside_kit_closed_entry, bedside_kit_open_entry, kitchen_bench_entry,
                   trade_drop_entry, nest_breach_entry, gland_lantern_entry,
                   cricket_net_entry, cinder_burrower_entry, jar_shelf_entry, cold_frame_entry,
                   drain_grate_entry, sealed_crate_entry, parcel_entry],
        "textures": [{
            "id": "order_note",
            "file": "props/order_note.png",
            "name": "Cave order note",
            "kind": "texture",
            "description": "Ruled paper with handwritten order lines, stains, a fold and a torn corner.",
        }],
    }
    documentation = os.path.join(GENERATED, "documentation")
    os.makedirs(documentation, exist_ok=True)
    manifest_path = os.path.join(documentation, "asset_manifest.json")
    with open(manifest_path, "w", encoding="utf-8", newline="\n") as handle:
        json.dump(manifest, handle, indent=2)
        handle.write("\n")

    print("Built:", os.path.join(GENERATED, SLIME_RELATIVE))
    print("Built:", os.path.join(GENERATED, WORKBENCH_RELATIVE))
    print("Built:", os.path.join(GENERATED, INSULATION_PATCH_RELATIVE))
    print("Built:", os.path.join(GENERATED, HUNT_SNARE_RELATIVE))
    print("Built:", os.path.join(GENERATED, WARM_STORAGE_RACK_RELATIVE))
    print("Built:", os.path.join(GENERATED, FROZEN_MAINTENANCE_PORTAL_RELATIVE))
    print("Built:", os.path.join(GENERATED, FROZEN_MAINTENANCE_CART_RELATIVE))
    print("Built:", os.path.join(GENERATED, FURNACE_HEAT_RECLAIMER_RELATIVE))
    print("Built:", os.path.join(GENERATED, BEDSIDE_KIT_CLOSED_RELATIVE))
    print("Built:", os.path.join(GENERATED, BEDSIDE_KIT_OPEN_RELATIVE))
    print("Built:", os.path.join(GENERATED, KITCHEN_BENCH_RELATIVE))
    print("Gland lantern:", os.path.join(GENERATED, GLAND_LANTERN_RELATIVE))
    print("Cricket net:", os.path.join(GENERATED, CRICKET_NET_RELATIVE))
    print("Cinder burrower:", os.path.join(GENERATED, CINDER_BURROWER_RELATIVE))
    print("Cold store jar shelf:", os.path.join(GENERATED, JAR_SHELF_RELATIVE))
    print("Cold store cold frame:", os.path.join(GENERATED, COLD_FRAME_RELATIVE))
    print("Cold store drain grate:", os.path.join(GENERATED, DRAIN_GRATE_RELATIVE))
    print("Cold store sealed crate:", os.path.join(GENERATED, SEALED_CRATE_RELATIVE))
    print("Order parcel:", os.path.join(GENERATED, PARCEL_RELATIVE))
    print("Order note:", os.path.join(GENERATED, note_relative))
    print("Manifest:", manifest_path)
    print("Slime: %d triangles; %d bones; %d clips" % (
        slime_entry["triangles"], slime_entry["bones"], len(slime_entry["animations"])))
    print("Workbench: %d triangles; %d bones" % (
        workbench_entry["triangles"], workbench_entry["bones"]))
    print("Insulation patch: %d triangles; %d bones" % (
        patch_entry["triangles"], patch_entry["bones"]))
    print("Hunt snare: %d triangles; %d bones" % (
        snare_entry["triangles"], snare_entry["bones"]))
    print("Warm storage rack: %d triangles; %d bones" % (
        storage_rack_entry["triangles"], storage_rack_entry["bones"]))
    print("Frozen maintenance portal: %d triangles; %d bones" % (
        maintenance_portal_entry["triangles"], maintenance_portal_entry["bones"]))
    print("Frozen maintenance cart: %d triangles; %d bones" % (
        maintenance_cart_entry["triangles"], maintenance_cart_entry["bones"]))
    print("Furnace heat reclaimer: %d triangles; %d bones" % (
        heat_reclaimer_entry["triangles"], heat_reclaimer_entry["bones"]))
    print("Bedside kit (closed/open): %d/%d triangles" % (
        bedside_kit_closed_entry["triangles"], bedside_kit_open_entry["triangles"]))
    print("Kitchen bench: %d triangles; %d bones" % (
        kitchen_bench_entry["triangles"], kitchen_bench_entry["bones"]))
    print("Trade drop: %d triangles; %d bones" % (
        trade_drop_entry["triangles"], trade_drop_entry["bones"]))
    print("Nest breach: %d triangles; %d bones" % (
        nest_breach_entry["triangles"], nest_breach_entry["bones"]))
    print("Gland lantern: %d triangles; %d bones" % (
        gland_lantern_entry["triangles"], gland_lantern_entry["bones"]))
    print("Cricket net: %d triangles; %d bones" % (
        cricket_net_entry["triangles"], cricket_net_entry["bones"]))
    print("Cinder burrower: %d triangles; %d bones; %d clips" % (
        cinder_burrower_entry["triangles"], cinder_burrower_entry["bones"],
        len(cinder_burrower_entry["animations"])))
    return manifest


if __name__ == "__main__":
    build()
