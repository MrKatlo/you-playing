# Freebuff edits — shooting and looting

Record of the work done by the Freebuff agent in this session, kept so the next
person (or the next session) can see what changed, why, and how far it was
verified.

## The request

> "we were adding shooting and looting"

The previous session ended mid-response, so no code had been written yet — the
agent had only read the project. During that read one blocking defect was found:
`scripts/main.gd` called `player.set_riveter_equipped(true)` when the player
picked up the Maintenance Riveter, but `scripts/player.gd` had no such method.
Picking the riveter up therefore threw at runtime, and `rivet_gun` /
`rivet_rounds` existed in the inventory dictionary with no way to equip, fire,
or spend them. The feature was stubbed as far as the pickup props and their
message text ("LEFT CLICK TO FIRE"), and absent everywhere else.

This pass finishes that half-built feature: shooting with the riveter, an ammo
count you have to loot, and the UI/save plumbing around both.

## What changed

### Shooting

- **Equip state.** `player.gd` now owns `riveter_equipped` and a
  `riveter_cooldown` timer, plus the `set_riveter_equipped(value)` setter the
  pickup code was already calling. The crash at `main.gd` is gone.
- **Input.** New `fire` action in `project.godot`, bound to left mouse button
  (`InputEventMouseButton`, `button_index: 1`). `player.gd` routes
  `is_action_pressed("fire")` to `game.player_fire()` in `_unhandled_input`,
  next to the existing `pulse` / `craft` / `interact` bindings.
- **Firing.** `main.gd: player_fire()` guards on equipped, cooldown (0.62 s) and
  ammo, spends one round, then cone-checks every `EchoScavenger` within 22 m and
  0.9 dot-product of the camera forward vector. A hit calls the existing
  `scavenger.stun(9.5)`, so rivets are a longer-range stun than the arc pulse
  but cost a scarce resource.
- **Trade-off by design.** Every shot calls
  `make_noise(player.global_position, 17.0, "rivet")`. The Resonant hears it,
  so shooting to solve a scavenger problem can pull the Mimic down on you. This
  is deliberate and matches the existing fair-hunting rules in
  `documentation/story-and-threat-redesign.md` ("running, machinery, dropped
  metal ... create a much larger [trail]").
- **No kill.** The rivet cannot damage or kill the Mimic. The design docs are
  explicit on this point ("No craftable weapon kills the creature", "must
  remain optional and never turn the game into a shooter"), and `mimic.gd` has
  no health model to hook into. The weapon's power is *time and distance*, not
  damage.

### Looting

- **Ammo economy.** `rivet_rounds` was already tracked and serialised; it is now
  spent and displayed. The existing entry-bay "RIVET ROUND CASE" (8 rounds) is
  the starting supply, and a new case in the lower wing
  (`medical_rounds`, 6 rounds, at `(4.6, 0.42, -59.6)`, past the scavenger
  nests) means the mid-game fight can be resupplied by exploring. An empty
  riveter prints "RIVETER EMPTY // Loot rivet round cases in the station."
- **HUD.** The inventory line now shows `RIVETS %d` alongside scrap, wire, fuse,
  cell, battery and lure, so looting ammo is visible without opening a menu.

### Controls, instructions and saves

- The on-screen hint gained a `LMB FIRE RIVETER` line (label grown from 50 to
  66 px tall and nudged up so it does not clip the window edge).
- The in-game INSTRUCTIONS screen documents left click and warns that the shot
  is very loud.
- `load_game()` re-applies the equip state from `inventory.rivet_gun`, so a save
  taken after picking the riveter up does not reload into an unequipped player.

## Files edited

| File | What was changed | Why |
| --- | --- | --- |
| `scripts/player.gd` | Added `riveter_equipped`, `riveter_cooldown`, `set_riveter_equipped()`; decrement cooldown in `_physics_process`; route `fire` to `player_fire()` behind an `InputMap.has_action()` guard | Fixes the missing-method crash from the riveter pickup, provides the input/state layer for firing, and avoids error spam if the input map is stale |
| `scripts/main.gd` | Added `RIVETER_RANGE` / `RIVETER_STUN` / `RIVETER_COOLDOWN`; new `player_fire()` and `_riveter_hits()`; lower-wing ammo case; `RIVETS` in HUD; equip restore on load; extra hint line; player added to the tree before being positioned | Implements the shot, the ammo spend, the loot, and the readout; the spawn fix removes a startup error that left Mara at the origin |
| `project.godot` | New `fire` action bound to left mouse button; removed the stale `[dotnet]` section | Firing needs an input action; the `[dotnet]` block made the .NET build look for a C# assembly this GDScript project does not have |
| `scripts/game_menu.gd` | INSTRUCTIONS text now lists left click and calls the shot loud | The control has to be discoverable in-game |
| `freebuff-edits.md` | This document | Requested record of the changes |

No other files were touched. `scripts/mimic.gd`, `scripts/echo_scavenger.gd`,
`scripts/scavenger.gd`, `scripts/rpg_progression.gd` and `scripts/horror_audio.gd`
were read but left alone — the riveter reuses their existing `stun()`, `hear()`
and noise APIs rather than adding new ones.

## Tests involved

The repository has **no test suite** (no test files, no framework, no CI). A
Godot 4.7.2 build was later located on this machine and the game was actually
launched, so this record contains both static checks and real runs. Static
checks first:

A Python cross-check was run over the edited tree. It verified:

1. Every `X.method()` call in `main.gd` resolves to a `func` in the matching
   script (`player`, `mimic`, `nix`, `rpg`, `horror_audio`, `game_menu`).
2. Every `_get_game().method()` call in `player.gd` resolves to a function in
   `main.gd`.
3. Every `player.attribute` read in `main.gd` exists as a var or func in
   `player.gd`.
4. The riveter path's dependencies on `EchoScavenger` exist and are public
   (`active`, `stunned_timer`, `stun()`).
5. All new symbols are present (`player_fire`, `_riveter_hits`,
   `set_riveter_equipped`, `riveter_equipped`, `riveter_cooldown`,
   `RIVETER_COOLDOWN`) and the `fire` action is actually wired to
   `game.player_fire()`.
6. `project.godot` registers 12 actions including `fire`, every action block
   closes correctly, and no `Object(...)` line has unbalanced quotes or parens.
7. The scripts stay tab-indented with trailing newlines (Godot style).
8. `RIVETS %d` appears in the HUD string and `LEFT CLICK` in the instructions.

Result of the final run: **12 actions, 0 problems, exit code 0.**

The first run reported 8 problems; all 8 were false positives in the checker
itself (Node built-ins such as `get_meta`/`set_meta`, the literal
`"res://scripts/player.gd"` preload path matching `player.gd`, and methods
missing from the attribute allowlist). The checker was corrected and re-run
rather than the source being "fixed" — see the review notes below.

### Runtime verification (performed)

Using the standard (non-.NET) Godot 4.7.2 build, `4.7.2.stable.official.ed1daf0bf`:

| Run | Command shape | Result |
| --- | --- | --- |
| Editor opens and imports the project | `--headless --editor --quit-after 200` | exit 0, no errors |
| Game, no GPU | `--headless --quit-after 120` | exit 0, no errors (one benign `ObjectDB` leak warning at exit) |
| Game, windowed, OpenGL compatibility | `--quit-after 200` | exit 0, no errors, no crash |
| Game, windowed, ANGLE / D3D11 | `--rendering-driver opengl3_angle --quit-after 200` | exit 0, no errors |

These runs confirm the project loads with the new `fire` action and the
shooting code present, and that the pre-fix startup error is gone.

### Still not verified

- Actual firing behaviour: hit feel, spread, whether 0.9 dot over 22 m is too
  generous, and whether a 17 m noise radius makes the riveter a trap rather than
  a tool.
- Whether the 9.5 s rivet stun trivialises the scavenger encounter.
- The user's .NET (mono) Godot build could not be run here, so its signal 11 was
  not reproduced directly — see the crash section below for the evidence-based
  diagnosis and the recommended build.

Manual pass still worth doing: pick up the riveter, confirm the equip message,
left click and check the ammo drops and the shot is audible; empty the case and
confirm the empty message; confirm a fired shot moves the Mimic toward you; stun
a scavenger through the nests; save, reload, and confirm the riveter is still
equipped with the saved ammo count.

## Launch crash (signal 11) — diagnosis and fix

After the shooting work, the project would not start. Reported symptom: the run
prints engine and renderer lines, then a `CrashHandlerException: Program crashed
with signal 11` backtrace, then the process closes. The reported engine was
`4.7.2.stable.mono.official`.

### What the evidence showed

- The log stops right after `OpenGL API 3.3.0 ... Intel Iris Xe`, which *looks*
  like a GPU fault. It is not: the same project, machine and driver ran to
  completion (exit 0) under the standard 4.7.2 build, with both OpenGL and ANGLE.
- The project contains no C# at all — no `.csproj`, no `.sln`, no `.cs` — yet
  `project.godot` carried `[dotnet] project/assembly_name="The Last Signal"`. A
  .NET build tries to resolve a managed project assembly that does not exist.
- Zero-byte `*.tmp` files were sitting in `.godot/imported/` and were removed
  as cleanup. After the editor re-ran they came back, so Godot writes them
  during texture import: they are transient artifacts, not corruption. The
  final `.ctex` outputs were complete either way.
- None of the shooting/looting code is on the startup path. The only
  startup-reachable changes were the `fire` input action and one extra ammo
  pickup; everything else runs on input or on load.

### Fixes applied

1. Removed the stale `[dotnet]` section from `project.godot`. The project is pure
   GDScript, so the block only asked the .NET build to load a non-existent
   assembly. Run the project with the standard Godot build.
2. Fixed a real startup bug the runs exposed: `main.gd` set
   `player.global_position` *before* `add_child(player)`, which raised
   `Condition "!is_inside_tree()" is true. Returning: Transform3D()` and left
   the player at the world origin instead of the checkpoint. The child is now
   added first and positioned after.
3. Deleted the zero-byte import `.tmp` files as hygiene. Godot recreates them
   during import, so this is cleanup, not a crash fix.
4. Guarded the new binding with `InputMap.has_action("fire")` so a stale input
   map cannot spam "nonexistent action" errors every frame.

### If it still crashes

Run the standard build installed on this machine:

```
"C:\Users\user\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64_console.exe" --path .
```

If that also crashes, add `--verbose` and keep the last lines *before* the
backtrace: a GDScript error names its file and line, and that detail is missing
from the report above. Do not try to debug from the C++ backtrace — a release
build carries no symbols for it.

## Shooting pass 2 — sound, real projectiles and impact feedback

This section supersedes the shooting details in "What changed" above; that
first pass had no audio, no impact, and no projectile.

The user's verdict was blunt and correct: "there's no sound ... there must be
something that is created on the wall ... there must be some physics for
shooting". That covers five separate failures:

1. No shot sound at all.
2. Nothing appeared where the rivet landed.
3. No physics — the shot was a distance/cone check, so it passed through walls.
4. The creature showed no reaction when hit.
5. Nothing died.

### What was rebuilt

- **Real projectile.** `player_fire()` casts from the camera through the
  crosshair with `PhysicsRayQueryParameters3D` + `intersect_ray`, excluding the
  player's own body. Walls, gates, lockers and consoles stop the rivet, and the
  hit point and surface normal come from the physics engine. The old
  `_riveter_hits()` cone check is gone.
- **Synthesised gunshot.** `_build_shot_stream()` generates a 460 ms 16-bit WAV
  at startup: noise transient, 74 Hz chamber thump, 1.21 kHz metal ring, body
  and room tail. A dry-fire click and a short impact tick are generated the same
  way. No audio asset was downloaded; the sound ships as code.
- **Impact on surfaces.** `_spawn_impact()` places a puncture decal oriented to
  the surface normal (procedural 32×32 hole texture, unshaded, alpha), fires a
  one-shot `CPUParticles3D` spark burst, and plays a 3D impact tick at the hit
  point. Decals are capped at 96, oldest freed first.
- **Muzzle flash and recoil.** A muzzle `OmniLight3D` flashes for ~70 ms and a
  camera recoil offset kicks pitch/yaw and lerps back.
- **Hit markers.** Crosshair flips to an amber `×` on a creature hit, a neutral
  `·` on a miss, then back to `+`.
- **Creatures take damage.** `EchoScavenger` has 2 health, `take_rivet_hit()`,
  knockback along the shot direction, a red damage flash, a death collapse, and
  a `game.scavenger_killed()` callback.
- **Loot.** A dead scavenger drops 2 rivet rounds as a real pickup with a unique
  persistent id, plus 18 XP.
- **The Resonant reacts.** `Mimic.take_rivet_hit()` flares its throat rings,
  staggers for 0.55 s, is knocked back, and enters CHASE toward the shooter.
- **Ammo state in the HUD.** The readout ends with `RIVETER READY / CYCLING /
  EMPTY / STOWED`; cycle time is 0.85 s.
- **Aim tolerance.** Scavengers are ~0.5 m tall, so one hairline ray made them a
  coin flip. If the centre ray misses a creature, two rays offset +0.10 m and
  -0.12 m vertically are tried. A surface hit is never upgraded, so shooting a
  wall next to a scavenger does not hit the scavenger.

### Why the Resonant still does not die

The project's own documents say "No craftable weapon kills the creature" and
that scavengers "must remain optional and never turn the game into a shooter".
Killing the Mimic would also delete the game's threat. A rivet therefore now
produces a violent, readable reaction — throat flare, stagger, knockback,
chase — without a health bar. Killing it is one constant and one branch away if
that is the intended design, but it changes what the game is.

### Verification

A temporary harness (`tools/_riveter_smoke.gd`, created and then deleted)
booted the real scene headless and fired the tool:

| Check | Result |
| --- | --- |
| Ammo after a wall shot | 5 → 4 |
| Impact decal spawned | 1 |
| Spark burst node spawned | 1 |
| Shot stream length | 460 ms, 20,286 bytes |
| Decal texture generated | true |
| Scavenger health after first hit | 2 → 1 |
| Scavenger health after second hit | 1 → 0, `dead = true` |
| Rivet round pickups on map | 2 → 3 (dropped loot) |
| Mimic mode after hit | 3 (CHASE), stagger 0.55 s |
| Empty-tool shot | ammo stays 0, no error |

Two harness bugs nearly produced a false "broken" result and are recorded here
because they are easy to repeat: it placed a scavenger and raycast in the same
frame (the physics space had not updated yet), and it ran while the title menu
had the tree paused, so physics never stepped at all.

The full project still loads clean: editor import, headless run and windowed
OpenGL run all exit 0 with no script errors. The harness prints "2 resources
still in use at exit" on quit — an artifact of quitting mid-frame with live
audio and particle nodes, not a gameplay error.

### Files edited in this pass

| File | Change |
| --- | --- |
| `scripts/main.gd` | Raycast projectile, generated shot/click/impact audio, decals + sparks + impact sound, hit markers, loot drop on kill, HUD riveter state, aim tolerance |
| `scripts/player.gd` | Muzzle light, camera recoil (`apply_shot_recoil`), recoil decay |
| `scripts/echo_scavenger.gd` | Health, `take_rivet_hit()`, knockback, death collapse, loot callback |
| `scripts/mimic.gd` | `take_rivet_hit()`: throat flare, stagger, knockback, immediate chase; stagger handling in physics |

## Review notes — what was revised and why

- **First draft reused the arc-pulse path.** The initial idea was to let the
  riveter share `player_pulse()`'s cone check. That would have tied ammo to a
  single `arc_charge` counter and lost the separate round inventory, so firing
  got its own function and its own resource.
- **Skill coupling removed.** An early version extended stun time with the
  `charged_pulse` skill. That skill is documented as arc-pulse-only, so the
  riveter was decoupled from it; rivet stun is a flat 9.5 s.
- **Tuning constants moved to `main.gd`.** `RIVETER_COOLDOWN` started life in
  `player.gd`; the player script now only runs the timer, so all balance
  numbers sit together in `main.gd` next to the other gameplay constants.
- **Save path fixed during review.** Losing the equip state on load was spotted
  while writing the load logic, hence the `inventory.rivet_gun` restore.
- **Checker, not code, was wrong.** The 8 initial failures were fixed by
  correcting the analysis script; no source was suppressed, weakened or
  commented out to make the check pass.

## User feedback recorded

- The user's instruction for this pass was "we were adding shooting and
  looting", which is what set the scope: finish the riveter and give the ammo a
  source, rather than introducing a new weapon or a generic loot system.
- The user also asked for this document explicitly, so the changes and their
  verification state are not lost when a session ends mid-response again.
- The user's project docs constrain the feature (no lethal weapon, no shooter
  drift, loud actions feed the Resonant); those constraints were treated as
  requirements, not suggestions.

## Known gaps / sensible next steps

- `README.md` still lists the old control set and still claims the Mimic tracks
  flashlight light, which `mimic.gd` does not do. Worth correcting in a docs
  pass.
- Superseded by "Shooting pass 2" above: muzzle flash, recoil, impact decals,
  sparks, shot audio, Mimic stagger and scavenger loot all now exist.
- Still open: no reload animation or ejected casing, impacts stop at the first
  surface, and the tool has no world model in the player's hands.
- `main.gd:_check_scares()` still re-triggers the pump-room scare every frame
  while the Mimic is dormant, independent of this work.

---

## Basement farm — v1 implementation

A second, additive experience built from `basement-farm-spec.md`. The station
game is untouched apart from one title-screen button.

### Files added

| File | Purpose |
| --- | --- |
| `scenes/basement.tscn` | Entry scene: one `Node3D` running `basement.gd` |
| `scripts/basement.gd` | Room build, stations, HUD, interactions, creatures, save/load |
| `scripts/farm_state.gd` | Pure `RefCounted` economy: clock, heat, trays, orders, standing, upgrades |
| `scripts/burrower.gd` | Blind heat-seeking creature with venom attack and death |
| `scripts/basement_menu.gd` | Self-contained title / pause / upgrades / settings menu |

### Files edited

| File | Change |
| --- | --- |
| `project.godot` | Added `melee` action bound to R |
| `scripts/game_menu.gd` | Title screen gains "THE BASEMENT"; title panel grown to fit the extra button |

### What works in v1

The twelve acceptance criteria in the spec, plus the two decisions that added
systems:

1. Walkable basement; HUD shows day, clock, temperature band, standing, inventory and warmth.
2. Order slate reads buyer, product, quantity, minimum grade and due day/hour.
3. Bait hook (1 fuel), hand-crank shutter, lured burrower, and three kill paths: melee (R), bolt driver (LMB), crush gate.
4. Butcher table splits a carried carcass into +4 feed, +4 fuel, +2 chitin, +1 hide; hide grade A for melee, B for traps, C for bolts.
5. Three starting trays (2 maggot, 1 roach), feeding and warmth, 12 h maggot / 30 h roach maturation, harvest to raw mass.
6. Rations and bait tins packed at the bench; bait additionally costs chitin.
7. Box packed for the current order, left in the shutter, settled at dawn for parts, water and standing.
8. Four upgrade axes with three tiers each, paid in parts; throughput opens trays 4–6.
9. Antidote brewed from chitin and water, drunk to clear venom, or slept off at the cost of a cycle.
10. Four gaps with nightly breach rolls weighted by open gaps and traffic; sealing costs 2 parts.
11. Save and load to `user://basement_farm_save.json`, separate from the station save.
12. Locked stair door, visible, not enterable.
13. Hunger: one ration per 30 in-game hours; eating takes stock out of the orders.
14. Hunter traffic rises with every bait tin sold and feeds the breach rolls; it is never printed as a number.

### Verification

A temporary harness (`tools/_basement_sim.gd`, created then deleted) booted the
real scene and drove the loop: **38 checks, 0 failures, exit 0**. Highlights:
tray matured in 12 h; butcher yielded +4 feed / +4 fuel / +2 chitin / +1 hide;
dawn produced *"THE TANNER: 5 x RATIONS (min B) due DAY 2 20:00"*; delivery
settled parts 4 → 15 and standing 10 → 14; throughput opened all six trays;
brew + drink cleared venom; eating restored hunger; sleep landed at 06:00;
save/load restored clock and parts; a burrower died and dropped a grade-A
carcass; the crush gate cost 6 parts; a gap seal cost 2 parts.

Runs: basement headless (0 errors), basement windowed on the real OpenGL path
(exit 0), station game headless and windowed (exit 0) as a regression check.

### Bugs found and fixed while testing

- `FarmState.advance_minutes()` had a fast-forward guard that broke the loop
after one minute, so 12 h of growth and every dawn event silently never
happened. Removed.
- `basement_menu.gd` inferred a type from the untyped `game` reference
(`var cost := ...`), which failed to compile and took the whole scene down with
it. Typed explicitly.
- `_spawn_burrower()` set `global_position` before `add_child()`, raising
`!is_inside_tree()` and leaving the creature at the origin.
- Three `:=` inferences against untyped model calls in `basement.gd`; typed.

### Known gaps

- Burrowers walk in straight lines; no navigation, so they can clip props.
- No contamination model yet; tray risk is feed, cold and the dead state only.
- Live capture is the labour-tier-2 branch on the crush gate, not a separate pit prop.
- In-person buyers are specified but not built; all trade is stick orders for now.
- Broadcast sound is reused (`metal_hit`, `door_open`); insect hiss, furnace roar and the shutter chain are still to be synthesized.
- Temperature is a single room value, not per-tray.

---

## Basement farm — its own sound

The basement had borrowed the station's `metal_hit` and `door_open` samples, which
made a furnace room sound like a rivet line. It now has a synthesised voice of
its own, built the same way the station's shot and horror bed are: generated in
GDScript at load, no new sample assets.

### Files

| File | Change |
| --- | --- |
| `scripts/basement_audio.gd` | New. Six streams, two state-driven beds, four one-shots |
| `scripts/basement.gd` | Owns the audio node, feeds it farm state, routes crank and bolt to it |

### The streams

| Sound | Length | Behaviour |
| --- | --- | --- |
| Furnace roar | 4.00 s loop | 29/41/61.5 Hz partials, filtered rumble, grit, slow breath. Silent when the fire is out; ticks at random once the metal cools |
| Tray hiss | 3.00 s loop | Broadband hiss over a moving floor, 17 Hz swarm tremble, 3.1 kHz and 4.7 kHz stridulation |
| Shutter chain | 1.45 s one-shot | Irregular link clicks over the slide, then a hydraulic thud as it seats |
| Bolt driver | 0.45 s one-shot | Vented air, 94 Hz thump, 1.74 kHz metal crack, room tail |
| Dry click | 0.12 s one-shot | Striker falling on an empty driver |
| Cooling tick | 0.30 s one-shot | Contracting metal: strike, two rings, low clank |

### State mapping

- **Furnace:** lit and fuelled → roar from 0.62 up to 1.0 as the room warms; out of
  fuel → fades to silence and starts ticking. Eases at 0.8/s, so a fire going out
  is heard as a decay rather than a cut.
- **Trays:** density is live colonies over the three starting trays, so six trays
  are no louder than three but two dead ones are audibly thinner. Average colony
  health raises a high-pass on the tray bus from 150 Hz to 820 Hz and lifts the
  pitch, so a starving colony hisses thin and quiet before it dies.
- **Ducking:** the beds drop 22 dB while the pause menu is up, and the audio node
  runs on `PROCESS_MODE_ALWAYS` so that holds even while the tree is paused.
- **Crank and bolt** are triggered from the same code paths as the old samples.

### Fixes made while testing

- The chain one-shot was 1.20 s, which cut the seating thud while it was still
  ringing. Extended to 1.45 s.
- One-shots ended on a non-zero sample. `_to_wav()` now applies a 30 ms fade-out
  to every non-looping stream; the chain now ends at 0.0 exactly.
- Looping beds fold a generated tail back over the head, so the loop point is
  continuous (furnace seam jump 0.012, against 0.011 for an ordinary step).

### Verification

Temporary harness (`tools/_audio_sim.gd`, created then deleted): **60 checks, 0
failures, exit 0**, driving the real scene. It measured length, loop mode, peak,
DC offset and zero-crossing rate per stream (furnace 680/s, tray hiss 10,766/s —
low roar versus dense insects), confirmed the chain rattle decays into a seat
thud and ends at 0.0, that the bolt is a front-loaded crack, that the beds reach
their targets (-8 dB furnace, -16 dB trays) and duck under the menu, that a
fuelled furnace drives the bed and an empty one silences it, that two dead trays
plus a sick one took density to 0.33 and the high-pass to 820 Hz, and that the
crank, bolt and empty-driver paths each fire their own stream.

Synthesis costs **236 ms** and 301 KB of buffers at load, once, on the scene's
`_ready`. Windowed run on the real audio driver: exit 0, 0 errors. Station game
windowed: exit 0, 0 errors.

### Known gaps

- The melee hook and burrower itself are still silent; only the four requested
  sounds plus their two support one-shots exist.
- Everything plays non-positionally. Firing a bolt and cranking the shutter sound
  the same wherever you stand.
- No music bed yet; the spec's "low bed that thickens when cold" is unbuilt.
- Order sticks and in-person knocks have no sound, as those interactions are not
  built yet.
