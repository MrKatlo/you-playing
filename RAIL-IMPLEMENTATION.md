# Underground rail — implementation and testing

Implemented in **Basement Farm**, `C:\Users\user\Documents\horror`, from `RAIL-spec.md`.
Riverborn is not a runtime dependency and was not modified.

## Playing the route

1. Finish the existing first-night tutorial. The unlock uses the existing
   `StoryState.STAGE_HANDOFF`, which means that tutorial is complete.
2. In the cave corridor, follow **RAIL > / C-4 PLATFORM** through the new doorway at
   approximately `(22, 0, -4)`, then turn right onto the platform. The cold-store
   doorway at x16 is preserved.
3. Inspect the mining cart. Take the coupling and three parts from the starter
   cabinet, then use the cart again to install the coupling. Use it once more
   to board.
4. **W** accelerates; releasing W coasts quietly. **S or Space** brakes.
   **F** toggles the cart headlight without consuming batteries. **E** boards
   or exits; exit requires a full stop inside a marked platform. **R** repairs
   while fully stopped, including in a tunnel. **Escape** pauses.
5. Brake at the deposit-exchange platform. Search the washed-up salvage, trade
   for the workshop kit, and install it at the workbench. The terminal works
   before the workshop is restored.
6. Buy the safety kit, ride the maintenance return leg, and stop at C-4. Fit
   the kit and throw the three separate LIGHTS / WARNINGS / MOTOR switches.
   They may be operated in any order. The last switch finishes the upgrade.

There is no automatic braking, steering, reverse, or tunnel disembarking.
Missing a platform means another loop. A stopped cart stays stopped.
The old cave pocket, spool, beacon, order drop and foot route remain intact;
the exchange registers the cart only after its first rail arrival.

## Delivered stages

| Stage | Behavior |
| --- | --- |
| Discovery | Story-gated inspection and a directional repair objective |
| Cart repair | Nearby starter coupling, no trading prerequisite, 100 durability |
| Workshop | Protected traded kit; brighter station, full repair for one part, shared 25-part storage |
| Safety | Protected kit and three physical switches with relay sound, indicators and sequential lights |
| Motor upgrade | Acceleration ×1.25, top speed ×1.10, braking ×1.15, lower coasting drag, acceleration-noise range ×1.20 |

The continuous loop is about 146 metres. Its centerline is shared by the cart,
track modules and encounter placements. Platform markers are at distances 2
and 44 metres, with an eight-metre stopping zone at each.

## Encounters, economy and recovery

- Animated Echo Hunters listen and lunge. They detect acceleration noise;
  neither the headlight nor quiet coasting alerts them. A warned attack costs
  25 durability. Each pass schedules 1–2 outbound and 2–3 return opportunities,
  with randomized positions. Opportunities do not guarantee attacks.
- A random outbound collapse warns before damaging a fast cart. Slowing below
  2 m/s avoids its damage. Water is always present and reduces acceleration.
  Safety restoration adds lighting and earlier cues without removing hazards.
- A brief headlight figure and optional splash/flicker are capped at two per
  boarding session; missing a station and circling again does not reset them.
- Existing Echo Scavenger patrol behavior is reused along the maintenance
  margin, with a small Scavenger at the pocket. These ambient animals do not
  add unannounced cart damage. Existing pocket Burrowers remain unchanged;
  their on-foot pounce behavior is not applied to the moving cart. No adult Mimic.
- The terminal uses the costs and stock limits from the spec. Costs and names
  live in `rail_trading.gd`. Mechanical components use existing `farm.parts`.
  New resource and protected-kit inventory belongs to FarmState.
- Accessible platform salvage funds both progression kits and return repairs.
  A completed full loop refreshes ordinary terminal stock and salvage; loading
  or arriving at only one station does not. Kits can only be purchased once.
- Portable repair gives +40 per part; the restored pocket workshop repairs to
  100 for one part. Durability never exceeds 100.
- Breakdown returns the player and broken cart to C-4, retains all inventory,
  advances the shift clock three in-game minutes, and supplies emergency repair
  capacity after accounting for carried and accessible stored parts.
- Settings include warning volume, important-sound captions and reduced shake.

## Save behavior

Schema **12** migrates version 11 with undiscovered rail defaults while keeping
the basement, culture, story and cold store state. Rail counts are validated and
clamped. The three switch states, station, inventory, durability, repair stages,
stock and shared storage round-trip through JSON.

`user://basement_farm_save.json` remains the manual save.
`user://basement_rail_checkpoint.json` is an automatic stable-station snapshot.
Rail actions, purchases, damage, repairs and confirmed arrivals update it using
a temporary write and atomic rename. Continue/Load uses the newest valid save,
falling back to the other file if parsing fails. Manual saving is disabled in a
tunnel. Live speed/distance are never serialized: interruption resumes with the
persisted cargo and durability at the last confirmed station.

The screenshot and workflow runners instantiate the farm under a test parent;
automatic checkpointing is disabled there. The filesystem checkpoint test uses
its own uniquely named temporary file and removes it afterward.

## Files and asset pipeline

`scripts/rail_system.gd` integrates player input, station interactions, HUD,
checkpoints and progression. Supporting scripts are `rail_state`, `rail_world`,
`rail_cart`, `rail_station`, `rail_trading`, `rail_workshop`, `rail_safety`,
`rail_encounters` and `echo_hunter`.

Integration edits are in `basement.gd`, `farm_state.gd`, `player.gd` and
`basement_menu.gd`. The old story model remains the owner of story progression.
Existing audio assets supply the motor, relays, scrapes, creaks and stingers.

Four new GLBs use the existing **Builder → Model/Rig/Clip → validated GLB**
pipeline. The Hunter's exported animation bounds are checked against source
poses. Existing workbench and maintenance portal models are reused.

```powershell
Set-Location 'C:\Users\user\Documents\horror'
& 'C:\Program Files\Blender Foundation\Blender 5.2\5.2\python\bin\python.exe' `
  assets/models/basement/source/generation_scripts/rail_build.py
```

Outputs are under `assets/models/basement/generated/rail/`, with a validation
manifest: cart 1,368 triangles, terminal/cabinet 872 each, Hunter 3,984 with
`listen` and `ambush` clips. Reimport with Godot after rebuilding.

## Automated verification — no desktop control

```powershell
Set-Location 'C:\Users\user\Documents\horror'
$railGodot = 'C:\Users\user\Documents\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe'

# Only the rail workflow (real production scene, controls and physics queries).
& $railGodot --headless --path . res://tools/tests/workflow_rail.tscn

# Every registered regression suite.
& $railGodot --headless --path . res://tools/tests/run_tests.tscn -- --all

# Render PNGs from inside the game, then exit automatically.
& $railGodot --path . --rendering-driver opengl3 res://tools/rail_shots.tscn
```

The rail workflow covers 111 checks, including real W/F/E/R/Escape paths,
manual stops on both legs, missed stops, stationary hold, trading and kit
protection, physical switch selection, Hunter coasting/attack behavior,
collapse counterplay, flood acceleration, breakdown, file replacement,
interrupted rides, a physical walk through the entrance and past the cabinets,
and clearance of the existing cold-store doorway.

Screenshots: `tools/shots/rail/`.
Reports: `tools/test_reports/`; full-run log `rail_full_suite_final.log`.
Baseline before this feature: 18 suites / 1,441 checks / zero failures.
Final regression run: **19 suites / 1,552 checks / zero failures**, including
the 111-check rail workflow. Ten in-game screenshots were rendered and inspected.

## Playtest focus

The implementation is playable; the balance values remain the spec's initial
targets. Human playtesting should judge warning audibility, braking feel,
station readability and how quickly the two kits are earned. The rail geometry
and creature positions are deliberately modular for those adjustments.
