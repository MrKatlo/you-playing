# Basement Farm — Cozy Cave Survival Roadmap

**Status:** active implementation. The asset factory is complete; the first home-base slice and the tactical-hunt slice are playable and tested.  
**Scope:** Basement Farm only. The station game and Riverborn remain untouched.  
**Design rule:** *Every trip into the dark should make the warm basement better; every improvement to the basement should make the next trip into the dark possible.*

## 1. Product direction

Basement Farm is no longer primarily an order-fulfilment loop. It is a first-person cozy-horror survival game about turning an abandoned, freezing house into a safe home while exploring the dangerous cave network beneath it.

The player chooses how to spend a session:

```text
prepare at home → hunt / explore / trade / build → return with a haul
      ↑                                                    ↓
      └── craft, repair, cook, decorate, unlock and learn ─┘
```

The current furnace, culture trays, hunt room, bait, butchering, orders, upgrades, crickets, gecko, and blind slime are useful foundations. They will be retained where they serve the new loop, rather than discarded and rebuilt blindly.

### What changes

- The basement becomes a visibly improving home, workshop, farm, and defensive refuge.
- The hunt chamber remains the safe tutorial hunting space, then becomes the gateway to caves.
- Crafting becomes a physical activity at stations, with a small, readable recipe list.
- Caves add expeditions, tracking, scarce resources, environmental hazards, and discovery.
- Creatures have ecological roles. Some are hunted, while others are trapped, captured, avoided, or harvested safely.
- Orders and buyers become optional progression paths, not the only reason to play.

### What does not change

- The setting remains cold fallout, a warm basement, practical salvage, and uncomfortable creature-economy horror.
- The player remains first-person and unnamed.
- Story remains environmental: notes, rooms, nests, buyer messages, and objects rather than cutscene-heavy dialogue.
- The game remains a Godot 4 / GDScript project and keeps code-driven tests and screenshot QA.

### Scope discipline

The old `basement-farm-spec.md` describes the original compact farm prototype. This roadmap expands its product direction. Before implementation begins, the old specification will be reconciled with this roadmap so there is one source of truth for mechanics and save-data changes.

We will build one complete expedition vertical slice before adding multiple biomes, a large house, or every creature family. There will be no empty cave corridors just to make the map larger.

## 2. Experience pillars

| Pillar | Player feeling | Concrete rule |
| --- | --- | --- |
| Warm home versus cold unknown | Relief on return; dread before leaving | The base is bright, legible, personal, and materially improves. Caves are dark, cold, unfamiliar, and costly to enter. |
| Practical survival | "I prepared well and that mattered." | Light, warmth, rations, bait, traps, and medicine create choices, not chores. |
| Living cave ecology | "This creature belongs here." | Every creature has a habitat, senses, counterplay, purpose, reward, and readable animation language. |
| Visible progress | "My place is becoming mine." | Upgrades appear as real walls, shelves, lamps, tools, doors, and rooms—not only menu numbers. |
| Curiosity over checklist work | "What is down that side route?" | Each zone includes a landmark, resource, creature clue, shortcut or secret, and a story fragment. |

## 3. Core systems map

### The home base

The initial basement is damp, sparse, and improvised. It grows into a small survival workshop through repairable walls, insulation, storage, a furnace, workbench, butcher table, packing bench, culture shelves, kitchen/water corner, bed, lights, trophies, and security.

Early upgrades will be physical first: a furnace door and firebox improve heat, wall panels reduce drafts, shelving adds storage, and a workbench unlocks equipment. Decorative objects then allow the player to make the space personal without becoming mandatory progression.

### Hunting and crafting

The hunt chamber teaches bait, containment, timing, traps, melee, bolts, and butchering. Crafting uses a few meaningful stations:

- Butcher table: meat, fat, hide, bone, chitin, venom sacs.
- Furnace: cook, render, smelt, make charcoal.
- Workbench: bolts, weapon repairs, traps, tools, base repairs.
- Packing bench: rations, bait tins, antidotes, repellent.
- Cave camp: temporary light, heat, rest, and field processing.

Recipes remain small and explicit. A crafted item must either solve a known problem, unlock a route, improve a hunt, or visibly improve the base.

### Cave expeditions

The first cave zone is a deliberate hand-authored network of roughly 5–10 rooms, not procedural filler. Its loop is:

1. Choose equipment at home.
2. Cross the hunt chamber and enter a cave entrance.
3. Read tracks, smell, sound, heat, slime trails, hazards, and landmarks.
4. Hunt, avoid, capture, harvest, or scavenge.
5. Decide when the haul is worth the risk of going farther.
6. Return to convert discoveries into base capability.

The planned biome order is: frozen maintenance tunnels first, fungal caves second, nest tunnels third, flooded tunnels fourth, and deep warm vents last. Each must introduce a new decision, not only a different wall colour.

### Progression and story

Short-term goals are useful work today; medium goals unlock a room, recipe, creature, or cave route; long-term goals repair the house, map the caves, learn the source of the creatures, and choose an ending: exploit, coexist, or escape.

The exact player history and the cave-source reveal are a design-lock task. No lore log or creature will be added until it answers one of these questions: why this house, why this cave, why the warmth attracts life, and what the player can choose to do about it.

## 4. Adopted model and animation pipeline

### What was inspected in Riverborn

The supplied Riverborn pack has a strong, reproducible asset workflow in:

`C:\Users\user\Documents\new-game-project\riverborn\otter_lowpoly_asset_pack\source\generation_scripts\`

Its useful structure is:

| Riverborn step | Basement Farm adoption |
| --- | --- |
| `animals.py` builds anatomical mesh pieces using lofts, tubes, blades, spheres, proportions, and a material palette. | New Basement props and creatures get named, editable source builders instead of one-off runtime primitive piles. |
| `Rig` definitions give limbs, heads, antennae, tails, and bodies purposeful bones. | Every animated creature gets a skeleton designed around its movement and silhouette. |
| `anims.py` and `small_life_anims.py` define named behaviour clips. | Idle, locomotion, alert, attack/use, hurt, death, and species-specific clips will be authored before gameplay integration. |
| `Model.export()` writes a self-contained GLB. | Godot consumes stable generated GLBs, not live source geometry from Riverborn. |
| `build.py` creates a pack, manifest, previews, documentation, and archive. | A Basement build script will make its own asset pack and manifest. |
| `validate.py`, `verify_anim.py`, and Godot import checks test output. | Every generated asset is checked structurally, visually, and in the live Godot importer before it is called complete. |

Riverborn itself does not need to be present when Basement Farm runs. We will use its source/build/validation pattern as the baseline and keep a self-contained Basement copy with clear provenance.

### Proposed Basement asset source tree

```text
assets/models/basement/
  source/generation_scripts/
    mesh.py · model.py · gltf.py · palette.py · shading.py
    creatures.py · creature_anims.py · props.py
    build.py · validate.py · verify_anim.py · preview.py
  generated/
    creatures/ · props/ · documentation/
```

The first implementation task will establish this tree by adapting the relevant Riverborn generator modules, not by hand-copying static GLBs with no source. Existing imported cricket and gecko assets remain usable while their replacements or additions are built through the new pipeline.

### Definition of done for a living model

Before a creature enters the game, it must have:

1. A one-page creature brief: ecological role, size, habitat, senses, food, behaviour, counter, reward, and non-combat option where relevant.
2. A distinct silhouette at gameplay distance and anatomy that explains how it moves.
3. A grounded, metre-scaled mesh facing Godot's `-Z` forward convention.
4. A purposeful rig with reliable weights; no decorative legs that cannot animate.
5. Named clips tied to real gameplay states. At minimum: idle, locomotion, alert, hurt, death, plus its defining action.
6. A generated GLB, manifest entry, contact-sheet preview, structural validation, and animation verification.
7. A Godot import probe, collision/nav test, and automated screenshot of its actual in-game state.
8. Sound and visual feedback for its important states, so it feels alive before it is seen clearly.

Blender remains available for inspection, render checks, or targeted repair. The source of truth for new generated assets will be the versioned Basement generator, following the Riverborn model rather than ad-hoc visual construction inside gameplay scripts.

### Creature production order

| Order | Creature | Purpose of the first implementation |
| --- | --- | --- |
| 1 | Existing slime, rebuilt as a deliberate squishy creature asset | Validates soft-body silhouette, idle/lure/attack/hurt/death feedback, and current hunt loop. |
| 2 | Crawler | Validates articulated legs, fast movement, wall/ambush readability, traps and bolt counterplay. |
| 3 | Glowing grub | Validates a non-hostile capture/harvest loop and cave lighting ecology. |
| 4 | Burrower | Validates digging/venom behaviour, sealed gaps, and base-security consequences. |
| 5 | Nest guardian and cave stalker | Adds high-risk nest raids and sound/stealth play only after the earlier ecology is fun. |

The supplied crickets remain the farm species and the gecko remains harmless ambience. They are not substitutes for cave prey or hostile cave fauna.

## 5. Technical foundation plan

The current `basement.gd` successfully proves the loop, but it owns room construction, interaction, wildlife, combat, HUD, and save wiring in one file. Before cave content expands, responsibilities need clean seams.

| Area | Planned responsibility |
| --- | --- |
| `FarmState` / save migration | Persistent base, inventory, recipes, upgrades, cave discoveries, map state, and backwards-compatible save versions. |
| Item and recipe data | Single definitions for ingredients, yields, station requirement, stack size, and unlock source. |
| Creature framework | Shared senses, health, loot, state transitions, animation events, sound hooks, and per-species behaviours. |
| Zone scenes | Separate basement, hunt chamber, cave zones, camp sites, and return entrances with explicit persistence. |
| Build system | Snap/placement rules, repair targets, visible upgrade variants, and stored ownership state. |
| UI / journal | Clear interaction prompts, recipes, active expedition supplies, map discoveries, and order ledger. |
| QA tools | Headless integration tests, model validation, Godot import probes, screenshot runners, and save migration tests. |

No existing save should silently break. Each save-schema change will increment the version and include a migration test for the current Farm State saves.

## 6. First implementation sequence

When planning turns into active development, the first work sequence is deliberately narrow:

1. Approve the story/ecology and first-cave decisions.
2. Bring Riverborn's generator pattern into a Basement-owned source folder with a reproducible build command.
3. Produce and validate the revised slime as the first real proof asset.
4. Create data/scene seams needed for a cave entrance and persistent inventory.
5. Improve the home-base interaction slice before building the first cave rooms.
6. Ship the frozen maintenance-tunnel vertical slice and test its full return loop.

This order protects the existing playable Basement Farm while converting it into the larger game one finished loop at a time.

## 7. Decisions to make at the next design gate

These choices matter enough that they should be made before the next content pass, rather than guessed in code:

1. Is the house the player's family home, a bought refuge, or a place they inherited/occupied after the cold?
2. Is the cave source natural, industrial, experimental, or deliberately left ambiguous until late game?
3. Does the game keep the original darkly comic small-business tone as the main voice, or move more fully toward sincere cozy-horror survival?
4. Should the first cave's main discovery be a furnace upgrade, a route upward, an old resident's truth, or a creature-related revelation?

Everything else can proceed from the design rules above without forcing those narrative answers prematurely.

## 8. Implemented progress — 2026-11-16

### Completed: independent Basement asset factory

- Added the self-contained generator under `assets/models/basement/source/generation_scripts/`, following the supplied Riverborn pattern: editable mesh/anatomy source, palette, rig/clip export, GLB generation, structural validation, and animation verification.
- Generated and integrated the rigged blind heat-slime at `generated/creatures/slime/basement_slime.glb`. It has seven bones and six gameplay clips: idle, crawl, lure, strike, hurt, and death.
- Added generated static base props at `generated/props/`: the salvaged workbench, wall-insulation patch, hunt snare, and warm storage rack. Each has editable source and a manifest record rather than being a runtime primitive pile.
- Kept Riverborn out of the runtime dependency chain. Blender is used only to run the local generator on this machine; Godot consumes the resulting GLBs.

### In progress: tactile home-base slice

- Added the physical salvaged workbench to the playable basement, including a warm task light and a dedicated craft menu.
- Replaced the old scene-local bolt count with saved `FarmState` inventory data. The home-base save change was version 3; tactical state moved it to v4, the storage rack moved it to v5, and the current version-6 schema safely persists the cave heat-reclaimer chain for old saves.
- Added three data-driven, usable workbench recipes: a three-bolt salvage bundle, antidote, and insulation patch.
- Insulation patches are no longer an invisible parts deduction: they are crafted from hide and parts, consumed at one named gap, and reveal a generated physical wall-repair model. They persist through save data and refresh on load/new shift.
- Added the one-time warm storage rack recipe. It installs a generated shelf of crates, jars, tools, furnace-line coil, and heat lamp into a dedicated rear-wall niche; the ration interaction moves into its lower bay, and the lit furnace gives that bay a small local warmth effect.
- Preserved distinct station roles: butcher table gives materials, workbench makes survival gear, packaging bench fills orders, furnace handles heat.

### Completed: first tactical-hunt slice

- Added a generated, physical hunt snare: a bait-side wire loop with anchor stakes, tension wire, hook, and bait plate. It is crafted at the workbench, armed from the safe side, springs only when lure-driven prey reaches the bait, and temporarily pins that prey.
- Added distinct combat choices: standard salvage bolts, hard-hitting broadheads, and non-damaging tether bolts. `Q` cycles the active load and the HUD reports every ammunition type.
- Added bolt-driver durability and a data-driven repair recipe. Firing wears the driver; an exhausted driver dry-clicks until repaired at the workbench.
- Persisted alternate ammunition, snares, active load, armed state, and driver durability in FarmState schema version 4. Old saves get safe defaults.
- Kept the room-scale hunt coherent: bait lures blind heat-slime into the chamber, the sealed room contains it, and the snare supplies a short tactical opening instead of an inexplicable chase cutoff.
- Closed the kiting leak without losing the pounce loop: the slime now walks a slow 1.35 m/s stalk at a hunter who stands still (so the crouch still telegraphs and the step-dodge and landing guard still apply) and pours on 4.2 m/s the moment the hunter moves, which outruns a 3.4 m/s walk and orbit but not a 5.8 m/s sprint.
- Restored the hunt loop after it regressed into one pounce and then a walk back to the bait: the bait chute now only steers a creature that cannot sense the hunter (it used to drop the fight whenever the hunter stepped outside a chamber rectangle), engagement is sticky (a full second without a sightline or 9.5 m of distance) so the slime neither flaps between feeding and fighting nor abandons a fight mid-pounce, and the pounce is the attack again - a bite never spends the cooldown the pounce needs, so the slime keeps pouncing instead of parking at the hunter's boots after the first leap.
- Removed the fixed-distance stand-off, which made the creature read as tethered: it no longer mirrors the hunter's position to hold a gap. Pounce range is now the only distance it settles at - it recoils out of contact immediately after a bite (the "venom" beat ended with the body still against the camera before) and then waits out its own bite recovery at leap range, so the whole silhouette stays in frame and the next move is a pounce. During that pause it does not creep after a hunter who backs off: the gap stays open and the next leap covers it. It re-aims in every grounded state (it used to keep the facing it launched a pounce with, and now the telegraph itself cannot start until the body is pointed within 0.35 rad of the hunter), and its two bodies can no longer deadlock touching at 1.16 m - just outside biting distance and too close to leap.
- A death no longer deletes the creature: it stays alive at its own world position (no duplicate, no despawn) and only drops the hunt, so the hunter wakes up out of combat but the survivor is still there to be found and killed.

### In progress: real cave-access foundation

- The hunt chamber's exterior shutter is now the physical cave threshold in the live Basement Farm scene. Opening it exposes a walkable frozen maintenance tunnel; it does not launch a disconnected demo or repurpose the locked upstairs stair door.
- Added a cave-side return wheel so a player cannot be stranded when the shutter is seated behind them. A B-01 return marker explains the orange-lamp route back to the furnace without putting a quest arrow on the HUD.
- Added the first small authored pocket, the Cold Junction: repeated generated maintenance support bays, freezing pipes, dirty frost, a blocked C-4 collapse, and a generated frozen service cart with a dead battery, canisters, tools, and a cut cable as an environmental-story clue.
- Added source-owned generated assets for the frozen maintenance portal and service cart to the Basement build manifest, with Godot imports and screenshot coverage.
- Turned the Cold Junction cart into the first genuine cave return: its visible C-4 thermal regulator can be salvaged from the reachable front edge, carried home, and fitted with two parts at the workbench. The source-owned generated heat-reclaimer model visibly mounts beside the furnace, lengthens fuel burn by 30%, raises furnace target temperature, and extends the furnace's local warmth radius.
- Updated the workbench to use a real scrollable fabrication panel. New expedition recipes no longer clip beneath the screen or hide the Leave action.
- This is intentionally the entrance/return foundation, **not** a complete cave expedition. The remaining cave work is the 5–10-room expedition, resource/reward loop, hazards, Glowing Grub, map/journal, shortcut, and meaningful discovery.

### Verification currently passing

- `tools/test_basement_slime_asset.tscn`: 22 checks, 0 failures. The slime GLB now carries eight clips (idle, crawl, lure, strike, crouch, leap, hurt, death); `crouch` is the pounce wind-up and `leap` the airborne stretch.
- `tools/test_basement_workbench_asset.tscn`: 25 checks, 0 failures.
- `tools/test_creature_ai.tscn`: 43 checks, 0 failures. Drives the whole loop in one run against the production scene: bait, door, creature walks to its feeding spot and settles, hunter enters sense range, creature engages and faces before it coils, first pounce, a second pounce on its own cooldown with the hunter never moved, a landed body keeps its own world position and is parented to the world, a bite in the hunter's face recoils the body out of contact and a retreat during that recovery opens the gap instead of walking the creature along, backing away opens space without dragging it, it keeps tracking inside range and pounces again, it disengages when the hunter leaves and returns to feeding, the killing blow and respawn leave the creature alive at its own spot with no duplicate, it drops the hunt on the revive frame, it re-detects and pounces again, and two machete cuts through the real strike path damage and kill it, leaving remains.
- `tools/test_basement_farm.tscn`: 277 checks, 0 failures. Phase A3 added the step-dodge: input, committed movement, invulnerability window, cooldown, refusal of a pounce that reaches a stepping hunter, and the downed-state lockout. Phase A4 added the landing guard: a missed pounce is armed for its first 0.34 s, a blade inside that tail is swept aside and answered with one counterbite, the guard is spent rather than re-armed, it does not extend past the 2.0 m reach it guards, a pounce that connected lands open, and the guard closes by itself. The hunt-pressure checks pin the two gaits: a still hunter is stalked at 1.35 m/s, a moving hunter is chased at 4.2 m/s, that surge outruns a walk (3.4) and is still outrun by a sprint (5.8), and it drops back to a stalk when the hunter stops. The close-range checks pin the body language: a slime left facing away turns back to face a hunter in front of it, it is parented to the world rather than the hunter, a pinned body is not dragged when the hunter teleports, and a revive ends the hunt while leaving the survivor alive, in place and out of combat.
- `tools/balance_probe.tscn` measures the whole A2-A4 loop: standing still against a 4.6 m approach goes down in 13.68 s to four pounces and two bites; a hunter who starts already in biting range goes down in 15.27 s to the same mix; stepping out of every pounce makes the pounce miss and goes down in 29.93 s to seven landed steps and the bites in between; swinging on the landing frame costs one guard bite (12 health) and a kill at 3.83 s, while waiting out the guard costs nothing and kills at 2.72 s - greed is 1.41x slower and 12 health poorer, and the same sweep shows the guard has to outlast the ~0.25 s it takes a pressed swing to land (0.22 and below never fires). This verifies the locked upstairs remains separate, exterior shutter collision blocks/unblocks the cave threshold, a real first-person player can cross the threshold and return, the cart component is the nearest real interaction point, and the fitted furnace upgrade persists through saves.
- Generated GLB structural validation passes for slime, workbench, insulation patch, hunt snare, warm storage rack, and the C-4 furnace heat reclaimer. The slime animation source-to-bake comparison remains within 0.413 mm maximum error.
- Code-driven screenshots cover the live workbench and its scrollable menu, an installed insulation patch, warm storage rack, furnace heat reclaimer, armed floor snare, contained hunt, and the cave threshold/return marker/Cold Junction/component/collapse under `tools/shots/basement/`.
