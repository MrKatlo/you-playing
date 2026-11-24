# Development status

## Underground rail — playable implementation

The two-station loop, manual cart controls, starter repair, industrial terminal,
workshop/shared storage, three-switch safety restoration, animated blind Echo
Hunters, collapse/flood hazards, recovery and schema 12 persistence are built.
The existing cold store and pocket route remain intact. See
[RAIL-IMPLEMENTATION.md](RAIL-IMPLEMENTATION.md) for the play route, file map,
model generator and automated tests/screenshots. The focused rail workflow
passes 111 checks. The full regression run passes **19 suites / 1,552 checks /
zero failures**. Ten rail screenshots were rendered and inspected. Balance still
needs human playtesting.

## Phase C4 — the cold store: COMPLETE (N0–N3)

Built after C3 M1/M2. A root cellar south of the cave corridor, reached on foot
through a cut doorway (`x 15.2–16.8`, z -4.0) with jambs, lintel and threshold.
Footprint `x 13.5–18.5, z -8.5–-4.0`.

### What is in it

- **Four generated props**, built through the Basement pipeline and validated:
  `cold_store_jar_shelf`, `cold_store_cold_frame`, `cold_store_drain_grate`,
  `cold_store_sealed_crate`.
- **Three intact jars**, each a separate single-use target that pays one part.
  The broken jars and the dropped lids are scenery.
- **The sealed crate** pays two parts and one heat gland, once.
- **The drain grate** is the story tell — pushed in from below, open to the dark —
  and is deliberately not interactable.
- **The cold frame** is gated on a real insulation patch. Fitted, it keeps one
  cooked meal; eating that meal grants double hunger hours. This replaces the
  draft's seventh tray: trays stay fixed at six warm-room frames.
- One weak bulb over the door, one cold lamp inside, rugged wall bays and frost.

### Save

Schema 11 adds `cold_store_jars_searched`, `cold_store_crate_opened`,
`cold_frame_installed` and `cold_frame_meal`. Schema ≤10 loads with the room
untouched, and `new_game()` clears all four (they were leaking across shifts).

### Verified

`unit_c4_cold_store` 53 checks / 0 failures; `workflow_c4_cold_store` 37 / 0 —
doorway walked in and out, room walls hold, all three prop targets answer, the
frame's fit/store/eat prompts, and the crate/jar single-payout rules.

## Phase C2 — culture, kitchen, cave orders: COMPLETE (M0–M8 + C2 revision)

### C2 revision — population colonies, net slot 4, kitchen queue (done)

Requested after the first C2 delivery; recorded in `C2-spec.md` §22.

- **Colonies are a population, not a bar.** Each cricket tray stores `population`
  and `growth_minutes`: 6 at start, 27 at 150 growth-minutes (2.5 real minutes on
  the 1 h = 1 min clock), 43 at 300, then an exponential tail to the **120** cap.
  Growth is fed-gated (a hungry colony pauses; a freezing room pauses it too), and
  the clock is real time, so the milestones hold from the cold 15 °C start too.
  `progress` is derived from the count for the room visuals; maggot trays keep
  their old bar.
- **Harvest is `population − 6`**, the breeding reserve, clamped by
  `NET_CAPACITY = 60`; crickets the net cannot carry stay on the curve. Throughput
  upgrades no longer multiply a scoop (they still reward maggot mass).
  `seed_tray()` founds a colony at the 6-cricket floor.
- **Net has its own hotbar slot.** `SLOT_NET = 4` (`slot_4`, key 4). The woven net
  stays on the player at all times: other slots park it in a low right-hip carry,
  and slot 4 draws it up into the netting grip. A tray cannot be netted unless the
  net is the drawn slot; the prompt reads `NET NEEDED (4)` when it is ripe.
- **Kitchen quantity and queue.** The panel shows what can start now, a batch
  stepper, and the front job's progress and wait behind it. `queue_kitchen(kind,
  n)` pays portions and fuel at queue time; finished batches wait in
  `ready_meals` / `ready_jerky` until `collect_kitchen()`, so ingredients can
  never be spent twice and the board keeps working while the panel is closed.
- **Creature colour.** The plain slime keeps its authored green (the forced orange
  multiply is gone); the shutter lure is a painted red variant on the same rig and
  brain, spawned with its own 2 health and 4.2 speed. No global recolour.
- **Readouts.** HUD chip `07/60 IN NET   02 DRESSED`; tray label
  `CULTURE TRAY 1 — 27/120 LIVE · HARVEST`; a press reports population, feed state
  and seconds to the next scoop; the room shows 2–8 cricket rigs as it grows.
- **Save schema 9.** `population`, `growth_minutes`, the kitchen queue and both
  ready piles persist; schema 8 and 7 saves load at safe defaults.

Spec: `C2-spec.md`. Build sequence: nine modules in `C2-spec.md` §17.

### M0 — state contract (done)

- `FarmState` schema 8 (now 9, see the revision above): `live_crickets`, `dressed_crickets`, `meals`, `jerky`, both
  batch grades, `net_crafted`, and the reserved later-module fields (ember chitin,
  heat glands, lantern state, cave papers/drop/payout). A schema 7 save loads with
  safe defaults; trays, orders and inventory are untouched.
- Cricket trays are harvested alive and refuse without the net (the yield was
  12 / 24 / 36 by throughput when M0 landed; the revision above replaces it with
  population − reserve). Maggot trays still harvest `mass` for rations/bait.
- `seed_tray()` founds a colony from 6 carried crickets (35% progress at M0; the revision starts it at the 6 floor); it also
  revives a dead tray, with the 3-part starter kept as the fallback.
- Kitchen rules: `dress_crickets()` (6 live → 2 dressed, 0.1 h), `cook_meal()`
  (2 dressed + 1 fuel, lit furnace → 2 meal, 0.5 h), `cure_jerky()` (2 dressed →
  2 jerky, 1.0 h, no fuel); since the revision these are one-batch queue wrappers. `eat("meal"|"jerky"|"ration")` = 36 / 22 / 30 h,
  and an empty store is refused before appetite is. Batch grade follows
  `tray_grade(0)`.
- The workbench gains the permanent `cricket_net` recipe (2 parts + 1 hide).

### M1 — crickets become real (done)

- All six culture frames are now physically real from the first shift (body,
  generated model, slot-number stencil and `SEED A COLONY` station), so the shelf
  is a construction progression rather than two boxes and four invisible slots.
- Tray press order: mature → net (crickets) / harvest (maggots); empty with a
  starter carried → seed; dead → seed or the 3-part starter; growing → feed.
- A seeded frame grows four live imported crickets that wander and hop on the
  same loop as the first tray, and its dormant `02` stencil clears.

### M2 — the kitchen station (done)

- New `kitchen_bench` prop built through the Blender pipeline (1.68 × 1.57 × 0.87 m,
  2262 tris): board, pot, knife block, wire curing rack, furnace-line coupling, and
  a wear pass — greyed and splintered boards, a scrubbed dressing block, dried
  water rings on the shelf, a grease fan and soot over the pot, a chalk tally, hand
  driven nail heads, and a chipped enamel mug with a bent spoon left on the shelf.
- The bench stands on the free west wall at `(-5.37, 0.0, 1.55)`, clear of the
  butcher table and the cot, with its own low warm light. It is a normal
  interactable: the prompt reads `COOK`, and pressing it opens the kitchen panel.
- The panel runs the whole chain from one screen — dress six live into two
  portions, cook two portions into two meals (one fuel, lit furnace), cure two
  portions into two jerky (one hour, no fire) — with the live stores in the
  header and the refusal text kept in the panel.
- Balance retuned at M2 (spec §7, decision 11): the first draft turned a 30 h
  tray into 216 h of hunger against a maggot tray's 75 h, so the loss moved to
  the dressing step. A tray now yields 144 h of meals (2 fuel) or 88 h of jerky
  (no fuel), which keeps fuel, feed and the net worth spending.
- Both products are physical: a plate of meals and a jerky bundle appear on the
  board only while their store is above zero, and cooking puffs three short bits
  of steam over the pot.
- The bench lamp breathes: two slow sine layers drive the omni light and the
  emissive chip under the hood, so the station is never a flat lit prop. The pot
  steams by itself whenever the furnace line is hot (a cold line means a cold pot),
  and cooking thickens the steam for a few seconds instead of toggling it.
- The HUD gains a culture chip under the heat readouts (`07/60 IN NET  02 DRESSED`)
  that shows up as soon as the player has a net or anything to carry, so the live
  count is visible while working rather than only in messages.

### M3 — the products reach the economy (done)

- The packing bench wraps `meal` and `jerky` exactly like rations and hides, and the
  box carries the grade the batch was cooked or cured at (`meal_grade` / `jerky_grade`)
  rather than the live tray's grade. Short stores are refused by name.
- The slate names the new goods (`CRICKET MEALS`, `CRICKET JERKY`) and marks cave
  papers `CAVE ...`, so a paper carried home is distinguishable from a hatch paper.
- Dawn replaces the hatch slate only: a cave paper survives into the next day and
  runs to its own due hour (its expiry is M5's job).
- The ration crate is now a food crate: pressing it opens a panel with all three
  foods, the hours of appetite left, and the refusal rule (`EAT_HUNGER_LIMIT` = 12 h)
  stated on the page. Eating runs through `game.food_action()`, the same path a
  button click uses.
- Two new glyphs carry the panel: a strapped ration brick and an hourglass.
- Cave papers show in the HUD objective block: a slim slate strip under the
  objective panel reads `2 JERKY  DUE DAY 2 14:00` (with `+1` for further papers),
  and while one is owed the objective itself becomes `PACK CAVE` pointing at the
  packing bench instead of the hatch. `farm.cave_orders()` / `cave_slate_text()`
  own the text so the scene does not re-derive it.

### M4 — the deposit pocket (done)

- The old collapse is dug through rather than removed: two rubble shoulders and a
  lintel leave a 1.3 m squeeze at the end of the frozen tunnel, stencilled
  `ROUTE C-4  //  DUG THROUGH`. The return route and the cave-side wheel are
  untouched.
- Beyond it the deposit pocket is three connected spaces — a 16 × 4 m approach
  corridor that bends north, a 28 × 5 m gallery, and a 10 × 7 m dark chamber —
  plus a 3 × 3 m nest nook behind the breach. That is about 285 m² of new floor,
  four of the old cave, dressed with frost and sparser repaired-wall bays than home.
  The length is the point: the trip out is a walk with nothing to do on it.
- Somebody else walks this route: 26 bootprints converge on the drop, a satchel
  and a pencil stub lie where they were set down, and a chalk tally on the chamber
  wall counts seven and two.
- **Presentation pass.** The chamber holds three silhouettes the eye can keep from
  the drop: a dead ore hopper just inside the mouth (solid, with a rubble spill),
  a cable spool with its conduit coiled out behind it, and a leaning stack of split
  pallets under the breach. A hung hand lamp on a bent post marks the mouth, and it
  is the only light the chamber owns.
- The way back is painted, because there is no map: about 35 worn floor dashes leave
  the drop, pass the hopper, cross the gallery and turn down the corridor at the
  bend, and two stencils — `C-4 / OUT <` over the mouth, `FURNACE <` at the bend —
  answer "which way is out" from the wrong side of either room.
- Light is the route's clock: one strip in the corridor, one warm lamp spilling at
  the bend, three strips in the gallery fading east (0.40 → 0.11), and a dead strip
  in the middle of the gallery so the gap reads as a failure rather than a shorter
  room. The chamber has nothing overhead at all.
- The trade drop (`cave_trade_drop.glb`, 368 tris) stands against the chamber's
  east wall at `(74.85, 0.0, 2.60)` — about 65 m from the outer shutter in a
  straight line and roughly 75 m on the real route, so arriving is an event. It is
  a normal interactable with the prompt `TRADE DROP`; since M5 it is where the
  cave's papers and payments live.
- The nest breach (`nest_breach.glb`, 402 tris) is cut into the chamber's north
  wall at `(70.50, 0.0, 5.90)`, with a warm omni light behind it. `LOOK INSIDE`
  gives a glimpse — warm air, something breathing — and flares that light for a
  second. Since M6 it is also where the pocket's cinder burrower comes from.
- The pocket has its own synthesised soundscape (`scripts/pocket_audio.gd`): a draft
  loop pinned to the corridor bend, four positional drip sources across the gallery
  and chamber ceilings on long uneven gaps, and a low beating dyad at the clamp that
  is the only pitched thing out there. All three beds duck with the pause menu like
  the basement's.

### M5 — orders at the drop (done)

- A paper is waiting under the clamp on the first shift, and one more lands at each
  dawn while fewer than six are lying there. The paper is a real object on the clamp:
  a sheet above the box, a second sheet when there is a queue, and two pulled-apart
  halves when the paper has torn.
- Reading the clamp takes the top paper and puts it on the slate with
  `source = "cave"`: product, quantity, grade floor, `+14 h` due, and the cave price
  (meal `qty × 3 + 4..9`, jerky `qty × 4 + 5..10`, ration/bait/hide `rng(3..8) + qty`,
  0–2 water, 3–6 standing). Torn papers are read and discarded instead.
- The benching rule is the point of the channel: while a cave paper is owed, the
  bench wraps for it before any hatch order, the box is stamped `source = "cave"`,
  and the delivery hatch refuses it by name. Packing for a paper that is still under
  the clamp is refused, so the walk cannot be skipped.
- Depositing at the clamp settles grade and deadline immediately but leaves the
  money there. Payment is collectable on a visit at least **1 in-game hour** later:
  parts + water + standing, or half pay and −2 standing for an under-grade box.
  Until then the clamp answers "shut".
- An unfilled cave paper expires at **due + 2 h**: it leaves the slate, standing −2,
  and the next visit finds it torn under the clamp. The hatch channel's generation,
  settlement and penalties are untouched, and dawn no longer clears cave papers.
- Still placeholders by plan: the buyer is never visible (by design), the Cinder
  gland lantern landed in M7, so the chamber can now be worked by its 6 m warm
  light instead of the failing strips and the beacon.

### M6 — the Cinder Burrower (done)

- `Burrower` now takes a variant configuration before it enters the tree
  (`variant`, `max_health`, `speed`, `knockback_on_hit`, `splits_on_death`,
  `loot_table`, `body_colour`, `body_scale`, `leash_center`, `leash_radius`). The
  plain slime is still the default and its numbers and behaviour are untouched, so
  the base hunt room plays exactly as before.
- The cinder body: 3 health, 4.8 m/s gait, ×1.15 size, every surface tinted dark
  orange with a low emission so the seams read once the lights fail, and a collision
  sphere that scales with the body.
- Knockback: a landed blade shoves the hunter 1.2 m away from the body as a timed
  push (0.26 s of forced velocity, no damage). It stops dead when spent, so the hit
  costs exactly the ground it advertises and melee means closing again.
- Death: always A-grade remains (`CINDER REMAINS`), orange gel, and two ordinary
  burrowers at ±0.7 m with full 2 health, neither able to split again. The table
  gives the cinder's normal loot plus 1 ember chitin always and a heat gland on a
  25% roll.
- Placement: stirred only in the pocket — using the drop, looking into the breach,
  or standing in front of the breach for two seconds. Max two alive, 60 s cooldown,
  and a 22 m leash around the breach: past that line it drops the hunt and runs home,
  so the corridor and gallery stay a way out.
- Sound: gel tearing under pressure (pitched flesh under a low slam) on every spawn
  and on the split, so the breach is audible before the body is visible.
- The variant keeps the existing rig and clips, as the spec asked — its model is a
  recolour plus scale over the shared skeleton, so there is still no bespoke animation
  set.

### M7 — new materials and tools (done)

- **Ember snare** (`ember_snare` at the workbench): 1 ember chitin + 1 floor snare
  → 1 ember snare. It is armed before any plain snare, and after its one trigger the
  wire folds back into the pack as an ordinary snare, so the ember quality is spent
  but the trap is not. Disarming a set ember snare returns the ember snare itself.
- **Gland lantern** (`gland_lantern`): 1 heat gland + 2 parts + 1 chitin → carried
  lantern. Toggled with `L` (`lantern` action) or the same path a tool toggle uses;
  the world light is a 6 m warm omni on the body, not a cone, with no shadow cost.
- **Fuel:** lighting spends the first unit, then one unit of furnace fuel per ten
  in-game minutes; an empty store puts the light out, and it will not relight dry.
  `lantern_fuel_seconds` counts 600 in-game seconds per unit, so saves keep the
  exact burn left. A `lantern_minutes_left()` helper is there for HUD work.
- Both recipes are in the workbench list in the same registry as the rest, so the
  panel, save and bench messages needed no special cases.
- **HUD readout.** A `pocket_panel` sits in the right column (252 × 52 at
  `(1004, 148)`, under the purse line) and shows the lantern state on one line —
  `LANTERN ON · 8m LEFT`, `LANTERN OFF · READY`, `LANTERN OFF · DRY` — and the clamp
  line under it, using the same priority the drop prompt does (torn paper, then
  payment, then box, then paper, then nothing). It appears in the pocket
  (`player.x > 21.0`), or anywhere the lantern is lit, the cave box is held, or the
  clamp owes payment, and the string is clamped to the panel width.
- **Generated assets (§15).** The Blender pass is built and wired:
  - `props/gland_lantern.glb` (638 tris) hangs from the player's belt at
    `(-0.46, -0.80, -0.58)`, scale 0.48, tilted so the cage ribs read. It swings on
    a belt pendulum with the stride and settles when the player stops, and while the
    last two in-game minutes burn (`lantern_minutes_left() <= 2.0`) the light gutters
    — a stutter between 0.5× and 1.05× of its 2.4 energy with an occasional catch —
    instead of burning steady.
  - `props/cricket_net.glb` (464 tris) is both the bench prop (while a net exists)
    and the carried net: a second copy stays on the player from the moment it is
    woven — stowed low by the right hip while another tool is drawn, lifted into the
    right-hand carry when slot 4 is drawn. The carried copy darkens its gauze to a
    see-through alpha so it does not become a pale bucket at arm's length. Netting a
    ready tray plays a 0.55 s raise-and-sweep: the hoop lifts upright across the view
    and settles back to the carry. The catch has its own cue: a gauze swish on the
    sweep, then a cricket chirp 0.16 s later once the net closes (`net_swish.wav`,
    `cricket_chirp.wav`, both synthesised by `tools/create_net_audio.py`).
  - `creatures/cinder_burrower/cinder_burrower.glb` (552 tris, 7 bones, 8 clips) is
    the cinder's visual now, chosen by variant; the runtime orange tint is dropped
    because the model carries the palette, and the rig is shared with the plain slime.
  - `props/order_note.png` is drawn procedurally (density field, torn edge, ink
    lines) and mapped onto the clamp papers, so the sheet has writing before it is
    read.
  All four come from the existing `source/generation_scripts` pipeline and the
  manifest gained a `textures` entry for the note.
- **Screenshots.** `tools/basement_shots.gd` gained the C2 block (13a–13i): order
  note, clamp paper, lantern lit in the breach, the breach itself, the cinder
  burrower, the belt lantern in first person, the carried net, and the net mid-sweep.
  They were run windowed on this host and reviewed; the net's hand transform and gauze
  were the one thing retuned from the review.

### M8 — final docs and balance (done)

- §7 of `C2-spec.md` was checked line by line against the constants as they shipped at
  M8: `CRICKETS_PER_HARVEST 12` with the same 24 / 36 upgrade steps (the C2 revision
  replaced that row; §22 is the current balance),
  dress 6 → 2, cook 2 + 1 fuel → 2, cure 2 → 2, meal 36 h / jerky 22 h / ration 30 h,
  the cave price formulas, `CAVE_ORDER_DUE_HOURS 14` + `CAVE_ORDER_GRACE_HOURS 2`,
  six papers, the one-hour payment delay, the net at 2 parts + 1 hide, the ember
  snare, the lantern's 1 heat gland + 2 parts + 1 chitin, `LANTERN_FUEL_SECONDS 600`
  at `LANTERN_RANGE 6`, and the cinder's 3 health / 4.8 speed / 1.2 m shove / 25%
  gland / max 2 alive / 60 s / 22 m leash. **No retune was needed**, so the table is
  the shipped balance rather than a proposal.
- The two presentation numbers that did move during the pass are outside §7: the
  belt-lantern transform and the cinder screenshot staging, both cosmetic.
- One menu drawing bug was fixed while reviewing the screenshots: on the title and pause
  panels the compass glyph filled its box rim to rim and its right-hand tick ran into the
  first letter of `SURVIVAL GUIDE`. The row glyphs are now drawn in a 23 px box at
  `(13, 10)`, and `_draw_compass` keeps its ring and ticks at 86 % of the glyph radius, so
  every row's label starts with clear space beside its icon.
- Docs closed out: this C2 section, the test-state table below, `AUTOMATED_QA.md`
  (both C2 suites' coverage plus the asset and screenshot notes) and the
  module table in `C2-spec.md` §17.

### C2 test state

| suite | result |
| --- | --- |
| `unit_c2_culture` (new) | 187 checks / 0 (adds the paper lifecycle, cinder loot, lantern fuel and ember snare rules, plus their save fields; the revision adds the population schedule, reserve/capacity harvest, queue model and schema 9) |
| `workflow_c2_culture` (new) | 231 checks / 0 (adds the pocket walk, soundscape, trade loop, clamp prompt states, cinder variant, both new tools, the M7 readout and asset wiring, the net in hand plus its netting sweep and catch cue, and the low-fuel gutter; the revision adds net slot 4, the colony/feed readout and the kitchen stepper/queue/collect path) |
| `unit_survival` | 57 / 0 (cricket harvest moved to the new rule, maggot mass kept) |
| `workflow_survival` | 25 / 0 (one added net-craft check) |
| generated-asset suites | prop assets 41 / 0 (adds the cave drop and nest breach), slime assets 22 / 0, creature AI 43 / 0 |
| full run (C2 revision) | 13 suites, 1209 checks, 0 failures, 114 s |

Phase C2 is complete through M8 plus the revision: all eight modules are landed, the
generated assets and screenshots exist, and `C2-spec.md` §7 + §22 describe the shipped
code. The woven net stays on the player (stowed at the right hip, drawn up by slot 4)
with the bench copy kept, and the belt lantern swings with the stride and gutters when
its last two minutes burn.

## Phase C1 — physical wall controls: COMPLETE (awaiting approval)

The three basement controls (inner bulkhead door, outer hunt shutter, floor snare)
were invisible-collision cubes with a floating click target. Each is now a worn,
bolted wall lever with a stencilled plate, a throw arm that visibly changes angle,
and a mechanical sound synced to the travel. Door and snare rules are unchanged.

### What changed

| control | before | now |
| --- | --- | --- |
| inner hunt bulkhead | `_static_box` cube, nearest-distance click | `BulkheadLever` at (5.80, 1.10, -3.30), plate `INNER BULKHEAD` |
| outer hunt shutter | `_static_box` cube, nearest-distance click | `ShutterLever` at (5.80, 1.10, -0.62), plate `OUTER SHUTTER` |
| floor snare | `_static_box` cube, click armed it | `SnareLever` at (5.80, 1.10, -4.00), plate `FLOOR SNARE`, arms and disarms |

All three hang on the warm room's east wall (inner face x = 5.825) on one
mounting plane, clear of the 1.8 m bulkhead opening at z -2.9…-1.1.

- `scripts/mechanical_lever.gd` (new, `class_name MechanicalLever`): plate, lip,
housing, pivot boss, four bolts with washers, rust bleed, grease streak, colour
tag and a `Label3D` stencil, plus a throw arm with a wooden grip. Owns only the
look, the throw animation (0.18 s travel, 0.07 s settle, quad ease so the arm
resists then gives) and the two sound cues. `pull(down)` refuses while moving or
when already in that position and returns whether it accepted, so a handle can
never travel without its mechanism.
- Depth layout: every piece sits a few millimetres clear of the one behind it
  (`PLATE_THICKNESS`, `LIP_FRONT`, `DECAL_Z`, `NAMEPLATE_Z`, `TEXT_Z`). The first
  build had coincident faces — streaks level with the lip, the nameplate buried
  inside it, the stencil level with its tag — so the plate pattern z-fought and
  shimmered as the camera moved. The throw arm also pivots on the boss face now
  (`ARM_PIVOT_Z`), outside the housing, so the handle is visible at rest.
- `scripts/basement.gd`: builds one lever per control, keeps the door/shutter/snare
logic in the existing `_crank()`, `_toggle_hunt_bulkhead()` and the new
`_toggle_hunt_snare()`, and mirrors every state change into the lever. The
cave-side return wheel now syncs the shutter lever too, since it is a second
physical control on the same door. Interaction gained a per-target `reach`
(1.9 m on levers, keeping the old 2.4 m elsewhere) and a `requires_look` facing
check, so the shutter cannot be opened by clicking an unrelated wall or from
across the room. The three old cubes are gone.
- `scripts/farm_state.gd`: `disarm_snare()`, which folds the built trap back into
the pack. Arming still requires a trap in the pack, so the snare cannot arm on
entering the room.
- HUD prompt for all three controls reads `PULL LEVER`, and only appears within
reach and facing the lever.

### No new assets

No models, textures or sounds were downloaded. The lever is built from primitives
with the existing material pattern; the sounds are the existing
`furnace_door_creak.ogg` for the travel and `metal_hit.ogg` for the stop clunk,
pitched per direction. Nothing here needs asset approval.

### Verified

| requirement | result |
| --- | --- |
| levers exist, bolted, labelled, one per control | `workflow_c1_controls` checks presence, parts, plate text and kind |
| levers mounted on the wall, not floating | each plate's rear face is asserted within 20 mm of x = 5.825, and all three share one plane |
| no flickering plane | the suite rejects any two overlapping parts that share a front-face plane, and requires the arm to sit clear of the housing |
| handle follows the mechanism | angle asserted up/down on open, close, arm, disarm, cave wheel; refused throws leave it still |
| both doors reachable and reversible | open + close through `player_interact()`, collision kept while open, cooldown honoured |
| snare needs preparation | refused with empty pack, arms with a trap, disarms back into the pack |
| no interaction spam | second pull during travel refused, handle unsettled and no sound played |
| no sound spam | exactly two cues per throw, none on refusal or on a synced reset |
| use range and facing | out-of-range and facing-away attempts do nothing and show no prompt |
| no regressions | full run: 11 suites, 773 checks, 0 failures, 87 s |

### Known limitations

- The lever phase is not a phase of `e2e_gameplay`; it runs standalone and is
  selected for lever or basement changes through `dependencies.json`.
- The plate stencil uses the built-in font, so it reads as stencilled paint rather
  than a worn engraved plate. A dedicated font or baked texture would need the
  asset approval step.
- The plate pattern is checked geometrically (no shared face planes), not by
  eye; no screenshot pass was run for this fix.
- Levers answer `player_interact()` only; they are not grabbable with the physics
  mouse, matching every other station in the basement.

## Phase A0 — automated testing restructure: COMPLETE (approved)

Restructured the single 1400-line gameplay test into three levels of suites with a
runner, a dependency map and real failure reporting. Gameplay code was not changed
in this phase.

### What exists now

```text
tools/tests/
  test_base.gd            assertions, failure records, per-case timing, timeout, JSON report
  run_tests.tscn|gd       runner: --list/--level/--module/--changed/--all/--order
  dependencies.json       suite -> game files, and suite -> suites it builds on
  unit_survival.tscn|gd   51 checks, no scene, 0.8 s
  unit_crafting.tscn|gd   60 checks, no scene, 0.9 s
  unit_weapons.tscn|gd    31 checks, no scene, 0.5 s
  workflow_interaction    102 checks, real scene, 10.7 s
  workflow_survival        24 checks, real scene, 0.6 s
  workflow_crafting        26 checks, real scene, 3.4 s
  workflow_weapons         44 checks, real scene, 8.4 s
  workflow_creatures       68 checks, real scene, 14.2 s
  workflow_ui              10 checks, real scene, 0.4 s
  workflow_c1_controls     80 checks, real scene, 7.7 s
  e2e_gameplay             277 checks, every module in one shift, ~37 s
  test_reports/            failure JSON, written only when something fails
```

`tools/test_basement_farm.tscn` still works and forwards to `e2e_gameplay`.
Ten suites as of A0; `workflow_c1_controls` was added in C1, so `--all` now runs
11 suites and 773 checks.

### Verified

| requirement | result |
| --- | --- |
| fast unit tests | 142 checks (137 at A0, 5 snare-disarm checks added in C1), 2.2 s for all three, in one process |
| weapon workflow | `workflow_weapons` 44 / 0 standalone |
| survival workflow | `workflow_survival` 24 / 0 standalone |
| interaction / inventory workflow | `workflow_interaction` 102 / 0, `workflow_ui` 10 / 0 |
| independent execution | every suite ran alone from its own scene |
| order independence | `--module=unit_weapons,workflow_ui` and `--order=reverse` both pass |
| failure reporting | forced failure produced the FAIL line, expected/actual detail, JSON report and non-zero exit; suite reverted |
| preserved full run | `e2e_gameplay` 277 checks / 0 — same count as the old suite |
| selective run | `--changed=scripts/burrower.gd` selects `workflow_weapons`, `workflow_creatures`, `e2e_gameplay`: 389 checks / 0 in 59 s |

### Defects found by the restructure (not gameplay regressions)

- The broadhead/tether checks passed only while the player was still settling from
  a teleport. The camera pitch is recoil-only, so a level bolt cannot reach a floor
  slime. Targets are now placed on the sightline at eye height, where a pouncer is.
- The furnace step lit the fire with the last fuel unit, which the next tick snuffs.
  It now starts with two units and asserts the one-unit spend.
- Suites that relied on an earlier suite's state (installed upgrades, released
  wake-up, opened bulkhead) now prepare that state themselves.

### Not implemented, so not tested

Cooking station, magazine reload, firearm crafting, inventory grid and mouse-wheel
navigation do not exist in this build. `farm.eat()` is a ration interaction.

### Commands

```powershell
Godot --headless --path . res://tools/tests/run_tests.tscn -- --level=unit
Godot --headless --path . res://tools/tests/run_tests.tscn -- --changed=scripts/farm_state.gd
Godot --headless --path . res://tools/tests/run_tests.tscn -- --all
```

## Earlier phases

Hunt loop restored (bait priority, sticky engagement, pounce-first attack, aimed
telegraph, bite recoil to pounce range, survivor kept across death) and combat
phases A1–A4 closed: machete, creature combat, step-dodge, landing guard.
`workflow_creatures` and `tools/test_creature_ai.tscn` cover that behaviour.
