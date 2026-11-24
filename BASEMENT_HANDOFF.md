# Basement Farm — project handoff

## Scope

This handoff covers **only Basement Farm**, the first-person basement survival / production game in this Godot project. It is a playable, self-contained game mode with its own scene, state, menus, save file, assets, tests, and screenshot runner.

Current status: playable prototype with a complete basic loop, an independent generated-asset pipeline, a visibly improving home base, and a working tactical hunt slice. The last code-driven verification completed **148 checks with 0 failures** across the farm and generated-asset probes.

## What the game is

The player is an unnamed survivor keeping an insect farm warm in a ruined basement. Heat, food production, bait, and hunting are one economy:

1. Keep the furnace supplied.
2. Feed and tend culture trays.
3. Use fat as bait to draw a creature into the hunt chamber.
4. Seal the outer shutter, enter only when ready, kill the prey, and collect its remains.
5. Butcher the remains into feed, fuel, chitin, and hides.
6. Harvest insect mass, pack orders, deliver through the hatch, upgrade, and sleep.

The tone is grimy, practical post-apocalypse rather than supernatural space horror: a small business run from a dangerous warm basement.

## Current visual direction

- **Materials and room:** damp concrete, rusted steel, broken wall plates, soot, salvaged wood, rough repair panels, cold exterior spill, and warm furnace light.
- **Furnace:** a detailed makeshift metal furnace with an opening door, visible fuel throw, fire core, smoke particles / soot puffs, and a fire-light state.
- **Culture area:** six glazed, grimy culture trays with hinged lids. Three begin active; tray 3 is now a moving cricket colony.
- **Hunt area:** clearly distinct from the warmer farm—dark, narrow, rusted, red warning strips, an inner bulkhead, outer rolling shutter, a marked bait / containment slab, and a crafted wire floor snare.
- **Wildlife:** crickets are small, animated production animals. The house gecko is a harmless moving pest hunter in the safe room. The hunt prey is a generated, rigged blind heat-slime with purpose-built locomotion and hit/death clips.
- **Workshop and repair:** the salvaged workbench has a vise, wire spool, hand tools, lower shelf, and warm task lamp. Crafted insulation patches appear as physical layered repair panels on sealed wall gaps. A later crafted storage rack adds uneven shelves, ration crates, supply jars, furnace-line coil, and heat lamp to the rear wall niche.

Visual QA captures are written to:

`res://tools/shots/basement/`

Useful current images:

- `05b_cricket_preview.png`
- `05c_gecko_preview.png`
- `06_hunt_bulkhead_closed.png`
- `06a_floor_snare_armed.png`
- `07_contained_hunt_slime.png`
- `08_slime_guts_and_loot.png`
- `05d_salvage_workbench.png`
- `05e_workbench_menu.png`
- `05f_installed_insulation_patch.png`
- `05g_warm_storage_rack.png`

## World layout and hunt logic

```text
SAFE FARM ROOM
  furnace · trays · butcher table · salvage workbench · packing bench · cot · delivery hatch · warm storage rack
      |
      | inner hunt bulkhead (starts sealed)
      v
HUNT CHAMBER
  bait point · crafted floor snare · marked containment slab · red / cold lighting
      |
      | outer hunt shutter
      v
OUTSIDE / CREATURE ENTRY
```

The former small trap cage was deliberately removed. The room itself is now the trap.

1. Put one fuel unit into the bait chute from the safe side.
2. Turn the outer shutter crank. A slime is drawn to the bait from outside.
3. Close the outer shutter to contain it.
4. Open the inner bulkhead only when ready to hunt it with melee or bolt shots.
5. A killed slime leaves green / red floor guts plus a lootable remains pickup.

Before opening the shutter, the player can craft and arm a floor snare from the safe-side control. A lured slime that reaches the bait springs the loop and is pinned briefly, creating a deliberate opening rather than a free kill.

The slime is blind and follows warmth / smell, not sight. While bait is active and the player remains outside the chamber, it heads for the bait. It starts hunting the player after the player enters the chamber or the bait expires. It does not stop simply because the player is far away; closed doors are the real protection.

## What is implemented

### Core play

- First-person movement, flashlight, interaction prompts, melee, bolt firing, inventory HUD, pause, save, load, title screen, settings, instructions, and upgrades menu.
- Furnace interaction ritual: open door, add fuel, visibly light it.
- Culture tray interaction: open a hinged lid, feed / harvest / restart a dead tray.
- Farming state: heat, fuel burn, feed, tray health, progress, hunger, venom, orders, standing, upgrades, delivery, sleep, breach rolls, and save migration.
- Butchering / loot: dead prey becomes a carried remains pickup; processing yields feed, fuel, chitin, and hide.
- Ranged and melee prey damage; kill method affects grade. Standard bolts are economical, broadheads do more damage, and tether bolts pin prey without damaging it.
- Workbench crafting: salvage bolts, broadhead bolts, tether bolts, floor snares, bolt-driver repairs, antidote, insulation patches, and the one-time warm storage rack use data-driven recipe definitions in `FarmState`.
- Base repair and improvement: a crafted patch is consumed at a named draft gap, while the rack recipe converts the loose ration interaction into a physical shelf bay and small furnace-fed warming point. Tactical inventory, driver durability, selected load, patches, and the built rack are saved in schema version 5; earlier saves migrate safely.
- Built-in generated sound: furnace bed, tray hiss, shutter chain, bolt driver, dry-fire click, and cooling tick.

### Latest wildlife replacement

The old cockroach colony is no longer used in the gameplay scene.

- **Crickets:** tray 3 now spawns four supplied cricket models. They use their real `idle`, `hop`, and `feed` animation clips while moving around the tray.
- **Gecko:** the supplied low ground animation rig is used as a small non-hostile house gecko. It has rest / slither animation, a short warm-room route, dark skin, a four-legged lizard silhouette, and no player interaction prompt, so it never blocks a work-station prompt.
- **Save compatibility:** old save data with a former roach tray is automatically converted to a cricket tray without losing progress or health.

## Important files

| File | Purpose |
| --- | --- |
| `scenes/basement.tscn` | Basement Farm scene entry point. |
| `scripts/basement.gd` | Room construction, stations, interaction, wildlife, hunt chamber, HUD, combat, save wiring. |
| `scripts/farm_state.gd` | Economy and time model: trays, furnace, orders, upgrades, saves. |
| `scripts/burrower.gd` | The hunt slime's visual model, animation, lure state, chase, damage, and death callback. |
| `scripts/basement_menu.gd` | Title, pause, settings, instructions, upgrades, save/load, and workbench UI. |
| `scripts/basement_audio.gd` | Procedurally generated basement audio. |
| `tools/test_basement_farm.gd` | Code-driven integration test of the real production scene. |
| `tools/test_basement_slime_asset.gd` | Headless import / skeleton / animation check for the generated slime. |
| `tools/test_basement_workbench_asset.gd` | Headless import and material-surface check for generated static props. |
| `tools/basement_shots.gd` | Code-driven screenshot capture runner. |
| `assets/models/basement/source/generation_scripts/` | Basement-owned Riverborn-style procedural source, build, validation, and animation verification scripts. |
| `tools/prepare_riverborn_animals.py` | Cleans and exports the supplied cricket and gecko source assets for Basement Farm. |

## Runtime asset locations

| Asset | Runtime location | Notes |
| --- | --- | --- |
| Cricket | `assets/models/basement/riverborn_animals/cricket.glb` | Imported animated cricket; real idle / hop / feed clips. |
| Gecko | `assets/models/basement/riverborn_animals/gecko.glb` | Animated low-ground rig used by the house gecko; basement code adds the lizard silhouette and legs. |
| Blind heat slime | `assets/models/basement/generated/creatures/slime/basement_slime.glb` | Generated 7-bone creature with idle / crawl / lure / strike / hurt / death clips. |
| Workbench / wall patch / hunt snare / warm storage rack | `assets/models/basement/generated/props/` | Generated physical crafting, repair, tactical-hunt, and home-improvement props, with editable local source. |
| Furnace / trays / walls / furniture | `assets/models/basement/` | Blender-made basement props used by the live scene. |
| Textures | `assets/textures/` | Concrete, wall grit, smoke, and other material support. |

The animal preparation script is only needed when rebuilding those two GLBs. Normal gameplay loads the already-exported assets directly.

## Controls

| Input | Action |
| --- | --- |
| `WASD` | Move |
| Mouse | Look |
| `E` | Use nearby station / interactable |
| `R` | Melee swing |
| Left mouse | Fire bolt driver |
| `Q` | Cycle standard, broadhead, and tether bolt loads |
| `C` | Drink an antidote; craft new antidote at the salvage workbench |
| `F` | Toggle flashlight |
| `Esc` | Pause menu |

## How to run and verify

Godot executable currently used for verification:

```powershell
C:\Users\user\Documents\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe
```

Run the Basement Farm integration suite:

```powershell
& 'C:\Users\user\Documents\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe' --headless --path 'C:\Users\user\Documents\horror' res://tools/test_basement_farm.tscn
```

Expected current result:

```text
BASEMENT FARM RESULT: 110 checks, 0 failures
```

Capture visual QA screenshots without desktop control:

```powershell
& 'C:\Users\user\Documents\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe' --path 'C:\Users\user\Documents\horror' res://tools/basement_shots.tscn
```

Rebuild generated Basement assets (Blender provides the approved NumPy runtime on this machine):

```powershell
& 'C:\Program Files\Blender Foundation\Blender 5.2\blender.exe' --background --python 'C:\Users\user\Documents\horror\assets\models\basement\source\generation_scripts\build.py'
```

Then run the two focused asset probes:

```powershell
& 'C:\Users\user\Documents\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe' --headless --path 'C:\Users\user\Documents\horror' res://tools/test_basement_slime_asset.tscn
& 'C:\Users\user\Documents\Godot_v4.7.2-stable_mono_win64\Godot_v4.7.2-stable_mono_win64_console.exe' --headless --path 'C:\Users\user\Documents\horror' res://tools/test_basement_workbench_asset.tscn
```

## Current handoff state

The latest completed work combines the tactical hunt foundation with a visible home-base payoff: crafted broadhead/tether ammo, driver wear/repair, an armable room-scale floor snare, and a persistent warm storage rack that relocates rations into the upgraded shelf. The prior physical workbench / wall-repair loop and the cricket/gecko replacement remain complete and retained.

There is no required editor-only setup remaining. The project should run from `scenes/basement.tscn`; the test and screenshot commands above exercise the real production scene rather than a separate mock-up.

## Recommended next work

Ordered by value:

1. **Finish the remaining home-base quality-of-life slice.** Add batch feed/craft actions, a simple physical furnace or door upgrade, and a useful sleep summary before treating menu numbers as progression.
2. **Choose the story decisions before cave lore.** Lock the house relationship, cave source, tone, and first discovery; they are intentionally not guessed in runtime code yet.
3. **Build one authored frozen maintenance-tunnel expedition.** It needs a prepared entry, retreat route, landmark, resource return, and one non-hostile creature interaction—not a long empty corridor.
4. **Add the Crawler through the local asset factory.** It needs a distinct counterplay loop rather than merely being a faster slime.
5. **Improve hunt-room tension and pathing.** The slime still uses direct steering, so a future navigation pass is needed before complex cave layouts.

## Known limitations

- The house gecko is ambience / pest-control flavour only. It is deliberately not a required objective or a competing interaction target.
- The slime's route logic is direct steering, not navigation-mesh pathfinding.
- The hunt chamber has one physical floor snare, but not yet a broader trap network, bait variants, or persistent sprung-snare state across a save/load.
- The creature death aftermath is visual goo plus a lootable remains object; it is not yet a full dismemberment system.
- The current game save stores the farm state, not live enemies or door positions; loading returns the player to the normal safe setup.
- The warm storage rack creates a physical ration bay and local furnace-fed warm point; it is not yet a finite-capacity inventory or a fully separate power system.
- There is not yet a full cave expedition or an authored cave-zone scene. The current workbench/repair loop is the home-base foundation for that next vertical slice.
