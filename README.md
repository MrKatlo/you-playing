# The Last Signal

Standalone first-person 3D survival horror prototype for Godot 4. It does not use the Riverborn project, Okavango setting, or any of its assets.

## Technology choice

This project uses **Godot 4 with the Compatibility renderer**. It is lighter than a browser-based 3D stack for this game because it provides the first-person controller, physics, dynamic lights, spatial scene graph, and standalone desktop export in one small project. The prototype has no model, texture, or audio download requirements: its environment, creature, and horror soundtrack are generated at runtime.

## Play it

1. Open `project.godot` in Godot 4.3 or newer.
2. Press **F6** or **F5** to run.

Controls: `WASD` move, `Shift` run, mouse look, `E` interact, `C` craft, `F` flashlight, `Esc` release/capture the mouse.

## What is playable

- A complete small 3D station route: entry, operations, pumps, maintenance, and the ridge beacon.
- First-person movement, metal footsteps, flashlight battery, collision, interactive consoles, checkpoints, and a visible inventory HUD.
- A guided progression loop: find a keycard, unlock Operations, repair the generator, activate the freight elevator, drain the pumps, craft a lure, divert the Mimic, and activate the beacon.
- The Mimic begins hidden, then stalks, investigates noise, chases a player who shines a light at it, and sends the player to a checkpoint when caught.
- Nix, a harmless tunnel rat, is an optional ally. Give Nix the protein snack for a complete flashlight recharge; the main story never requires this trade.
- An understated procedural tension bed plus CC0 metal footsteps, door, generator, elevator, interaction, and creature effects.
- A compact tracker and a small cyan locator light identify the current key item or console without covering the 3D world with arrows.
- A title screen and pause menu with new game, save, load, instructions, master-volume, brightness, and exit controls.
- Scripted tension beats and a final survival ending.

## Project structure

| Path | Purpose |
| --- | --- |
| `scenes/main.tscn` | Minimal entry scene. |
| `scripts/main.gd` | Builds the station, progression, crafting, HUD, scares, and objectives. |
| `scripts/player.gd` | First-person controller, flashlight, movement sound, and interaction input. |
| `scripts/mimic.gd` | The Mimic's hidden reveal, stalking, investigation, chase, diversion, and capture reset. |
| `scripts/horror_audio.gd` | Runtime-generated adaptive horror music. |
| `scripts/scavenger.gd` | Nix, the optional tunnel-rat ally. |
| `scripts/game_menu.gd` | Title screen, pause menu, save/load, instructions, and settings. |
| `assets/audio/` | CC0 sound effects used for gameplay feedback; see `CREDITS.md`. |
| `assets/models/station/` | Blender-authored wall, grille-door, ceiling, console, pump, locker, and pipe modules used by the station builder. |
| `assets/models/characters/` | Blender-authored Mimic prototype model used by the creature controller. |
| `tools/create_station_assets.py` | Rebuilds the first station-asset kit through Blender 5.2. |
| `tools/create_mimic_model.py` | Rebuilds the grounded Mimic prototype through Blender 5.2. |
| `documentation/one-year-production-plan.md` | Modular-asset strategy and one-year production schedule. |
| `The-Last-Signal-Concept.md` | Full game concept and level design. |

## Build plan

### Prototype now

The current build proves the core experience: dark 3D exploration, doors and keys, readable objectives, crafting, an optional creature ally, a reactive threat, and an ending.

### Next production pass

1. Replace runtime blockout meshes with authored station modules, decals, and set dressing.
2. Add recorded station dialogue, radio effects, foley, and licensed or original music stems.
3. Give the Mimic navigation-aware routes, search animations, hiding places, and more varied voice imitation.
4. Add a menu, saved progress, graphics/accessibility settings, subtitles, and a proper ending sequence.
5. Export a Windows build first; add Web export only after testing the audio and lighting budget in browsers.

## Design choices

The game keeps one primary creature so players can learn its behavior: it follows loud movement and light, and it can be diverted through the sound system. Crafting stays small and purposeful. Each crafted item advances the escape route instead of creating a large survival inventory. Scares occur after clues and remain tied to the station's story.
# you-playing
