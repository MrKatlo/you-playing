# Basement Farm: automated testing

Work only in this project:

```text
C:\Users\user\Documents\horror
```

Do not drive the user's desktop to test the game. Every suite here instantiates
the real production scene and drives real game code in-process.

## Three levels

| level | what it answers | cost |
| --- | --- | --- |
| **unit** (`tools/tests/unit_*.tscn`) | does one mechanic's model behave? Runs `FarmState` directly, no scene, no frames. | < 1 s each |
| **workflow** (`tools/tests/workflow_*.tscn`) | does one gameplay procedure work end to end? Boots the real basement and drives real input/APIs. | 1–15 s each |
| **e2e** (`tools/tests/e2e_gameplay.tscn`) | do the systems still work together in one continuous shift? | ~40 s |

The end-to-end run is **built from the workflow modules**, so it cannot drift away
from them. `tools/test_basement_farm.tscn` is kept as an alias and still runs the
full sequence.

## Commands

```powershell
# what exists
Godot --headless --path . res://tools/tests/run_tests.tscn -- --list

# by level
Godot --headless --path . res://tools/tests/run_tests.tscn -- --level=unit
Godot --headless --path . res://tools/tests/run_tests.tscn -- --level=workflow
Godot --headless --path . res://tools/tests/run_tests.tscn -- --level=e2e

# one or more suites, in a chosen order
Godot --headless --path . res://tools/tests/run_tests.tscn -- --module=workflow_weapons,workflow_creatures
Godot --headless --path . res://tools/tests/run_tests.tscn -- --module=workflow_ui --order=reverse

# the suites a change reaches
Godot --headless --path . res://tools/tests/run_tests.tscn -- --changed=scripts/burrower.gd

# everything
Godot --headless --path . res://tools/tests/run_tests.tscn -- --all

# a single suite on its own, no runner
Godot --headless --path . res://tools/tests/workflow_crafting.tscn
```

Exit code is `0` only when every selected check passed, so a shell can gate on it.

## Suites

Rail verification is registered as `workflow_rail` (schema 12, both stations,
cart controls, trade/repair progression, hazards, and recovery). Its focused
render runner is `tools/rail_shots.tscn`, which writes `tools/shots/rail/*.png`
and exits. Both run through game code, without desktop automation. See
[RAIL-IMPLEMENTATION.md](RAIL-IMPLEMENTATION.md) for exact commands and controls.

| suite | level | covers |
| --- | --- | --- |
| `unit_survival` | unit | fuel burn rate, heat target, hunger, venom/antidote, tray growth, butcher yields, upgrade gate, save round trip |
| `unit_crafting` | unit | recipe catalog, ammunition kill-gate, exact costs and yields, shortfall refusals, antidote singleton, driver repair, one-shot installs, insulation patch |
| `unit_weapons` | unit | per-type ammunition counts, loadout cycle, consumption of the selected pool, empty-pool refusal, driver wear clamp, snare arm/spring |
| `workflow_interaction` | workflow | shift start, station interactables, cave threshold collision, real walk input, furnace open → feed → close, doorway clearance, shutter containment |
| `workflow_survival` | workflow | harvest, butcher, ledger order pack/pay, survival save shape and old-save migration |
| `workflow_crafting` | workflow | workbench gating, crafting at the real bench, visible upgrades, driver/broadhead/tether/snare loadout, real shots through `player_fire()` |
| `workflow_weapons` | workflow | tool slot rules, blade draw/holster, three swing variants, swing interruption, damage and kill, hit feedback |
| `workflow_creatures` | workflow | tray animals, bulkhead-gated senses, telegraph → pounce, step-dodge, landing guard, hunt pressure, bite recoil, death/respawn survival |
| `workflow_ui` | workflow | HUD readout, title menu behaviour, pause menu freeze |
| `unit_c2_culture` | unit | C2 culture model: net gate, live harvest tiers, colony seeding, dress/cook/cure, eating, cooked goods wrapped into orders with their own grade, cave papers surviving dawn, the paper lifecycle (one per day with a cap of six, take-to-slate, cave-first benching, deposit, delayed payout, expiry and torn paper), cinder butchery (1 ember chitin always, gland on the roll), the gland lantern (craft cost, fuel per ten in-game minutes, dry relight refusal), the ember snare (craft, arm-first, one-trigger reuse), net recipe, schema 8 save and schema 7 migration; since the C2 revision also the 6 → 27 → 43 → 120 population schedule, reserve-clamped harvest against net capacity, the queue/collect kitchen model and schema 9 with its older-save path |
| `workflow_c2_culture` | workflow | C2 culture workflow: the bare frame as a station, netting a mature tray through the real bench and interaction, seeding a colony that visibly lives, the wall kitchen (panel, dress/cook/cure with the retuned 6→2 yields, plate/bundle, steam), the HUD culture chip, all six culture frames built and seedable, the bench lamp flicker and the furnace-fed pot steam, the food crate panel and eating a meal, a cooked meal wrapped into an order at the real bench, the cave slate strip and PACK CAVE objective, and the M4 pocket: walk through the dug collapse, the corridor's walled end and the bend north, the gallery opening into the chamber, the bootprints/satchel/chalk, the trade drop prompt and its paper (visible sheet, taken sheet, torn halves), the drop soundscape (draft loop, positional drips, the clamp tone, menu ducking), the breach glimpse and its light flare, and the full trade loop: read the paper, wrap at the bench, deposit, collect an hour later, a missed paper tearing with standing loss, the clamp prompt spelling out paper/payment/box/torn states without touching them, and the cinder burrower: stirred by the drop, three health and a larger orange body, the 1.2 m shove on a landed strike, A-grade remains, the two-way split into ordinary bodies, ember loot at the table, the two-alive cap and the leash home, and both new tools in the real room: the lantern built at the bench, lit and shut from the tool control, six metres of warm light that draws fuel, and the ember snare springing a real creature and coming back as a plain snare, plus the M7 presentation: the pocket readout spelling lantern state and clamp state, the belt lantern appearing only while carried and its light stuttering on the last two minutes of fuel, the net both leaning by the bench and carried in the hand from the moment it is woven, stowed at the hip for another slot and lifted on slot four, the raise-and-sweep playing when a tray is taken, the gauze swish firing and the chirp following on the next beat, and the swing settling back to the carry, the cinder body using the generated model, and the order-note texture landing on the clamp papers; the C2 revision adds net hotbar slot 4 (stowed unless drawn), the population/feed readout on the tray and HUD, and the kitchen batch stepper, queue line and collect button |
| `workflow_c1_controls` | workflow | the three wall levers: presence and parts, inner door open/close, shutter open/close plus cooldown, snare arm/disarm and kit gate, use range and prompt, two sounds per throw, no throw during travel, cave-wheel sync, shift reset |
| `e2e_gameplay` | e2e | every gameplay module above except the C1 controls phase, in one continuous shift |

The C1 lever phase stays out of the e2e orchestrator deliberately: it walks one
wall of controls and would repeat in every later module. It is still reachable
from the orchestrator through `dependencies.json` (`e2e_gameplay` lists it in
`depends_on`, so `--changed=scripts/mechanical_lever.gd` runs both).

`tools/test_creature_ai.tscn` remains the deep hunt-loop run (43 checks) for the
creature's own loop; it is independent of the rest and is run by hand.

## Adding a suite

1. Copy an existing `workflow_*.gd` next to it and extend the base:
   `extends "res://tools/tests/test_base.gd"`.
2. In `_init()`, set `suite_name`, `suite_level` (and `needs_scene = false` for a
   unit suite).
3. Implement `run_phases()`; call `begin_case("id", "name")` / `end_case()` per
   procedure.
4. Assert with `_ok(condition, label, detail)` or `_eq(actual, expected, label)`.
5. Add a `.tscn` twin (three lines, see any existing one).
6. Register it in `tools/tests/dependencies.json` with the game files it
   exercises and the suites it builds on.

## Preparing state without faking the procedure

A suite may set up the world: place the player, seed resources, spawn a creature,
open a bulkhead, install an upgrade it is not testing. Standard helpers live in
`tools/tests/test_base.gd` (`boot()`, `_aim_player_at`, `_place_burrower_on_view_ray`,
`_clear_burrowers`, `_frames`).

It may **not** skip the mechanic under test. A crafting suite may seed salvage,
but the craft still goes through `game.craft_workbench_recipe()`; a weapon suite
may place a target, but the shot still goes through `game.player_fire()`.

Two real examples of why this matters:

- the broadhead check used to pass only because the player was still falling from
  a teleport; the camera pitch is recoil-only, so a level bolt can never hit a
  floor slime. The target is now placed on the sightline at eye height, where a
  pouncer actually is.
- lighting the furnace with the *last* fuel unit snuffs it on the next tick, so
  the furnace step now starts with two units and asserts the one-unit spend.

## Reading a failure

```text
  FAIL  second interaction feeds fuel and lights the furnace  lit=false fuel=0.00
FAILURE DETAIL
  [workflow_interaction/player_input] second interaction feeds fuel and lights the furnace
    expected: condition true
    actual:   lit=false fuel=0.00
  report: C:/Users/user/Documents/horror/tools/test_reports/workflow_interaction.json
WORKFLOW_INTERACTION RESULT: 102 checks, 1 failures (10.7s)
```

A failing suite writes `tools/test_reports/<suite>.json` with suite, case, failed
step, expected, actual, per-case timing and boot time. A green run deletes its own
stale report, so a report on disk is always current.

Every suite has a hard timeout (40 s unit, 360 s workflow, 600 s e2e). A timeout is
reported as a failure attributed to the case that was running, never a silent hang.

## Selection and the dependency map

`tools/tests/dependencies.json` lists, per suite, the game files it exercises
(`files`) and the suites whose behaviour it builds on (`depends_on`). `--changed`
matches whole path fragments against `files`, then walks `depends_on` in reverse so
a change to a shared model selects everything above it.

Example: `--changed=scripts/burrower.gd` selects `workflow_weapons`,
`workflow_creatures` and `e2e_gameplay`.

If a change does not map cleanly (a new file, shared scene wiring), run `--all`
rather than guessing.

## Screenshot playthrough

```powershell
Godot --path . --rendering-driver opengl3 res://tools/basement_shots.tscn
```

Writes PNGs to `tools/shots/basement/`. Add a staged capture with
`await _stage(Vector3(x,y,z), Vector3(lx,ly,lz))` then `await _shot("name")`.

The C2 block is 13a–13i (order note, clamp paper, lit lantern in the breach, the
breach, the cinder burrower, the belt lantern, the carried net, the net mid-sweep).
`05`/`05a` (culture trays) and `07` (contained hunt slime) show the revision: the red
lure and the four-slot hotbar with the net in slot 4. It needs a real display, so it
does not run headless; the pass was run windowed and the frames reviewed by eye.

## Asset generation workflow

Source of truth: `assets/models/basement/source/generation_scripts/`.

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python build.py
```

After generator changes run `tools/test_basement_slime_asset.tscn`,
`tools/test_basement_workbench_asset.tscn`, then `--all`, then the screenshot runner.
The pipeline itself validates every GLB's structure and animation keys and raises on a
bad file, which is what covers the C2 additions (gland lantern, cricket net, cinder
burrower); the note texture is a plain PNG from `note.py`, and `workflow_c2_culture`
asserts the runtime wiring — net prop, cinder model, paper texture.

## Known limits of this testing system

- It is headless: it proves state, not how anything looks or feels.
- There is no magazine/reload step, no firearm crafting and no inventory grid with
  mouse-wheel navigation in this build, so no suite claims to test them. Eating is
  the food crate's panel (`farm.eat(kind)`), not a raw inventory click.
- The pocket is tested for reachability, for both fixtures' answers, for the cinder's
  rules and for the trade loop; the walk's pacing and how the generated assets look
  are not covered — the suites assert that a prop or model is present and wired, not
  that it reads well on screen.
- Frame counts are real physics frames, not wall time; a busy machine changes
  duration, not outcomes.
