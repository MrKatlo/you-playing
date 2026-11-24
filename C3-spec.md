# Basement Farm — Phase C3 specification (draft for approval)

**Status:** proposal — nothing in this document is implemented. Written after C2 was
approved; C2 shipped state and test counts live in `DEVELOPMENT_STATUS.md`.
**Drafted:** 2026-11-22 from the story sequence in `HANDOVER_2026-11-17.md` §"Next
milestone" plus the systems that already exist in the build.
**Phase rule:** approve or edit this document first; implement C3 only after that,
then stop and report before starting C4.

---

## 1. One-paragraph summary

C3 is the **first night**: the scripted opening that turns the current sandbox into a
story. The tools are in the bedside kit, the furnace is lit, and then something starts
hitting the outer shutter from the hunt chamber. The inner bulkhead needs a **hand
crank** to raise, the two creatures that got into the chamber have to be killed with
the machete because there are still no bolts, and the fight **snaps the shutter chain**,
so the hunt room stays sealed until a **new chain link** is crafted from the chitin
those two kills drop and fitted at the warm-side lever. Opening the shutter again draws
two more, and the beat ends by **proving the trap from the safe side** — arming the
floor snare with the lever while a creature is inside, watching it hold, then finishing
the kill through the closed bulkhead with the first bolts the player has ever made. From
there the C2 loop (butcher, feed, net, kitchen, orders) is fully open and nothing in C3
ever gates it again.

---

## 2. Locked decisions (carried over from the handover)

| # | Decision | Source |
| --- | --- | --- |
| 1 | The sequence plays in this order: crank the inner door while two creatures bang outside → kill them → craft a part that repairs the shutter chain → open the hunt room → face two more → restore controllable trapping from the safe side | `HANDOVER_2026-11-17.md` §"Next milestone" |
| 2 | Butchering, feeding the colony, packing and submitting an order follow the story beat rather than being part of it | same |
| 3 | Content only, no new systems that C2 already covers: no new weapons, no new rooms, no new creature classes | C2 §18 fence, kept |
| 4 | The hunt trap stays a full sealed room, and the blind/slime hunting logic is not replaced by a scripted "creatures stop at a line" trick | handover §"Next milestone", closing note |
| 5 | Generated assets only (existing Blender pipeline), nothing downloaded | C2 §15, C1 §"No new assets" |
| 6 | Every beat must be completable with what the player can make in that room; no beat may require an item the beat itself has not yet given | new, this spec |

---

## 3. Current state audit (what C3 builds on)

| Area | Today | Location |
| --- | --- | --- |
| Opening | `new_shift()` wakes the player in the cot, furnace out, room at 15 °C; `opening_state` runs `wake → tend_fire → kit → complete` | `basement.gd::_start_wake_sequence`, `_use_furnace`, `_use_bedside_kit` |
| Bedside kit | First press gives torch + machete + bolt driver and selects the blade; the driver arrives with **0 bolts** | `basement.gd::_use_bedside_kit` |
| Inner bulkhead | Rolling collision gate lifted by a wall **lever** (`INNER BULKHEAD LEVER`), 0.72 s travel | `basement.gd::_toggle_hunt_bulkhead`, `_move_hunt_bulkhead` |
| Outer shutter | Rolling collision gate lifted by a wall **lever** (`OUTER SHUTTER LEVER`); the cave-side wheel can also lift it | `basement.gd::_crank`, `_use_cave_return_wheel` |
| Floor snare | Wall lever arms a built trap; needs a carried snare, refuses before the handle moves; triggers within 0.62 m of the bait spot | `basement.gd::_toggle_hunt_snare`, `try_trigger_hunt_snare`, `farm_state.gd::arm_snare` |
| Hunt chamber | 8 × 4 m sealed room between the two doors, bait chute, red lure, spawn at `OUTER_HUNT_SPAWN` (11.7, 0, −2) | `HUNT_CHAMBER_CENTER`, `_bait_hook`, `_spawn_burrower` |
| Burrower | health 2, speed 4.2, stalk 1.35, pounce-first; machete kills in 2 clean swings, carcass grade by method | `scripts/burrower.gd`, `basement.gd::on_burrower_killed` |
| Crafting | Registry of 12 recipes, `WORKBENCH_RECIPE_ORDER`; no chain or machine-part recipe exists | `farm_state.gd::WORKBENCH_RECIPES` |
| Save | `SAVE_VERSION = 9`, per-field defaults, schema 7/8/9 all load | `farm_state.gd::from_save` |
| Tests | 13 suites, 1209 checks; gameplay suites call `new_shift(false)` to skip the real-time intro | `tools/tests/` |

**Gap:** nothing in the build knows that a first night happened. There is no story
stage, no scripted spawn, no chain state, no crank, and no guidance from the tool kit to
the hunt loop.

---

## 4. The sequence, end to end

```text
STAGE 0  ASLEEP          (already shipped: wake → tend fire → open kit)
   │  kit opened
   ▼
STAGE 1  BANGING         two burrowers arrive in the hunt chamber, hit the shutter;
   │                     chain visibly snaps at the lever; lever refuses
   │  crank the inner bulkhead (hold E, 1.35 s)
   ▼
STAGE 2  FIRST WAVE      bulkhead up; the two are in reach; one at a time
   │  both killed with the machete (0 bolts in the world)
   ▼
STAGE 3  CHAIN SNAPPED   two carcasses, chitin in hand; shutter lever reads CHAIN SNAPPED
   │  craft CHAIN LINK at the workbench (1 part + 1 chitin), fit it at the shutter (1.4 s)
   ▼
STAGE 4  ROOM REOPENED   shutter lifts; two more drawn to the bait; snare still stowed
   │  arm the snare with the warm-side lever while they are in the chamber
   ▼
STAGE 5  TRAP PROVEN     the snare holds one; craft bolts, shoot it through the
   │                     closed bulkhead, seat the shutter
   ▼
STAGE 6  HANDOFF         C3 ends; the C2 loop runs free (trays, net, kitchen, orders, cave)
```

Stages advance **only** on the action that earns them, never on a timer, and never
backwards. Each stage has one guidance line on the HUD and one physical tell in the
room, so a player who walks away and comes back can read where they are.

---

## 5. Beat 1 — the banging (stage 1)

- Trigger: `opening_state` reaches `complete` (kit opened). A 3 s delay, then the beat
  starts: two `Burrower`s spawn at `OUTER_HUNT_SPAWN` with a scripted order — walk to
  the shutter, hit it, wait — not the ordinary stalk the player.
- Behaviour: they cannot open the shutter (the shutter body is a collision gate and
  `_crank` is the only control). They strike on a ~1.6 s cadence: shutter shudder
  (0.03 m, 0.12 s), a pitched `metal_hit.ogg` thump from the far side, dust off the
  frame, and one of four short HUD lines. The room's temperature does not change.
- Nothing can enter the warm room during this beat: the shutter is a collision gate
  and the bulkhead is still down, and the scripted pair never paths around the chamber.
- The player is never attacked and never timed. The beat ends when the bulkhead crank
  has been turned, i.e. stage 2.

## 6. Beat 2 — the crank (stage 1 → 2)

- New prop: `bulkhead_crank.glb` (generated), a geared hand wheel bolted beside the
  bulkhead on the same east-wall mounting plane as the C1 levers
  (`x = 5.825`, at about `z = −2.0`), with the C1 plate family and a stencilled
  `INNER BULKHEAD — CRANK`.
- **The bulkhead lever is retired.** The door keeps its collision gate, tween and
  sound; the control becomes a crank that is *held*, not thrown:
  - press and hold `E` for **1.35 s**; the wheel turns, a ratchet ticks each quarter
    turn, the gate lifts 2.6 m over 0.72 s on completion;
  - releasing early leaves the gate where it started (no partial opening), and the
    wheel springs back over 0.25 s;
  - the crank refuses while the shutter is being cranked, matching the current lever
    refusal rules.
- The shutter and the snare keep their C1 levers; only the bulkhead's control changes.
  `workflow_c1_controls` is updated to assert the crank and to keep asserting the other
  two levers unchanged.

## 7. Beat 3 — the first wave (stage 2 → 3)

- The two scripted burrowers are ordinary burrowers (health 2, no variant, no
  stat changes) — the fight is fair because of the room, not because they are weakened.
- They engage **one at a time**: the second waits at the far end until the first dies,
  so a player with 0 bolts and a blade is never in a two-on-one. This is a spawn-order
  rule on the scripted pair only; the ordinary bait loop keeps spawning as it does now.
- Killing both completes the stage. The carcasses are ordinary carcasses with the
  ordinary grade rules; the player is expected to butcher them, which is where the
  chitin for the next beat comes from.
- If a creature somehow reaches the warm room (it cannot in this beat), the beat is not
  failed and no reset happens; the existing downed rules apply.

## 8. Beat 4 — the snapped chain (stage 3 → 4)

- On stage 1 the shutter lever gains a **broken chain** tell: the chain hangs off its
  sprocket, a loose link sits on the floor under the lever, and the plate tag turns
  dull. From then until repair, `_crank` refuses with `CHAIN SNAPPED — REBUILD IT AT THE
  WORKBENCH` and the handle does not travel.
- New recipe `chain_link`: **1 part + 1 chitin → 1 chain link**, description
  "Re-cut a length of shutter chain and rivet a new link into it." It appears in
  `WORKBENCH_RECIPE_ORDER` after `basic_bolts`, so a new player meets it while holding
  the chitin from the two kills.
- Fitting: the shutter lever becomes a second interactable while a link is carried
  (`FIT CHAIN`, 1.4 s, tools-in-hand animation and the existing chain sound). Fitting
  consumes the link, restores the lever, and completes the stage.
- The cave-side wheel is unaffected: it is on the other end of the same shaft and
  already lifts the shutter, which keeps a player who is in the cave from being
  stranded.
- Parts budget: the player starts with 4 parts, spends 1 on the chain, and still has
  enough for a floor snare (2) and salvage bolts (1) before the next wave; the spec's
  balance table in §10 holds that budget.

## 9. Beat 5 — the room reopened and the trap proven (stage 4 → 5 → 6)

- Seating/opening the repaired shutter draws **two** burrowers on the ordinary lure
  path (the existing `_crank` branch). They are ordinary burrowers.
- The floor snare is unchanged mechanically, but this is the first time the game asks
  for it: arming it while a creature is inside the chamber completes the "trap armed"
  half of the beat, and the snare holding a creature completes the other half. If the
  snare is armed before the creatures arrive, the beat still completes when it catches
  one — the stage tracks the *trap proving itself*, not the order of the two presses.
- The kill that ends the beat: the player seats the shutter or stands at the warm side,
  crafts `basic_bolts` (1 part + 1 chitin → 3), and puts a bolt through the open
  bulkhead into the held creature. Any kill of a held creature counts — bolts are the
  intended route because the beat has just introduced crafting, not because other
  weapons are refused.
- Seating the shutter with the room empty also ends the beat if the snare proof already
  happened, so a player who wastes a load is never stuck.
- Stage 6 hands off to C2 with a single line (`THE FARM IS YOURS — NET, KITCHEN,
  ORDERS`) and no further locks. Every C2 system is already open at this point; C3
  never gates it.

## 10. Balance numbers (proposed — edit freely)

| Value | Proposal | Why |
| --- | --- | --- |
| Banging delay after kit | 3.0 s | long enough to read the kit line |
| Bang cadence | 1.6 s | reads as an animal, not a metronome |
| Crank hold | 1.35 s | tense with three bangs overhead, short enough to retry |
| Crank spring-back | 0.25 s | refusal must be visible |
| First wave | 2 burrowers, health 2, one at a time | 0 bolts at this point; blade only |
| Chain link cost | 1 part + 1 chitin | exactly affordable from two carcasses |
| Chain fit | 1.4 s | same order as the crank |
| Second wave | 2 burrowers | matches the handover's "two more" |
| Parts after the beat | ≥ 1 unspent | the player must be able to make bolts without a detour |
| Story stages | 7 (`0`–`6`) | one per beat, nothing hidden |

No new resource, no new currency, no new food value.

---

## 11. Data and save

`SAVE_VERSION` goes to **10**.

| Field | Type | Default | Meaning |
| --- | --- | --- | --- |
| `story_stage` | int | `0` | 0 dormant … 6 handed off |
| `shutter_chain_broken` | bool | `false` | true from stage 1 until the link is fitted |
| `chain_links` | int | `0` | crafted links not yet fitted |
| `story_banging_done` | bool | `false` | the scripted pair was spawned (so a reload never re-bangs an empty room) |

Migration rules:

- schema ≤ 9 saves load at **stage 6** with the chain intact: an existing farm is not
  sent back through a tutorial it has already outgrown.
- `new_shift()` starts at stage 0 with the chain intact and no links.
- Loading mid-story resumes at the saved stage; scripted creatures are **not**
  re-spawned. A resumed stage 2 simply puts the pair back in the chamber at their
  spawn point, un-engaged and without the bang loop, and the stage completes on the
  same kills.

---

## 12. Presentation

- **Crank:** generated GLB, same wear language as the C1 levers — bolted plate, stencil,
  grease at the gear, a torn glove print on the wheel.
- **Chain:** a short chain run from the lever into the wall, a broken stub, one loose
  link on the floor; on repair the stub is replaced and the loose link disappears.
- **Banging:** shutter shake, dust puffs at the frame seam, four HUD lines, the existing
  metal hit pitched down and reverb-less. No camera shake in the warm room (it reads as
  a bug at that distance).
- **HUD:** one story line at a time in the message strip, no new panel, no marker on
  the compass. The plate text and the crank plate do the wayfinding.
- **Sound:** reuse `metal_hit.ogg`, `door_open.ogg`, `furnace_door_creak.ogg`; the
  ratchet is the existing chain sound at 1.15× pitch, ticked per quarter turn.

## 13. Assets to generate (approval requested)

1. `assets/models/basement/generated/props/bulkhead_crank.glb` — wall crank with gear
   housing and plate (target ≈ 2.5 k tris).
2. `assets/models/basement/generated/props/shutter_chain.glb` — mounted chain run with a
   broken stub (≈ 1.2 k tris).
3. `assets/models/basement/generated/props/chain_link.glb` — the fitted link / carried
   part (≈ 150 tris).

Manifest entries and `.import` files via the existing `tools/` pipeline; no textures
beyond the current material set.

---

## 14. Testing plan

Two new suites, plus targeted updates to two existing ones.

| Suite | Level | Covers |
| --- | --- | --- |
| `unit_c3_story` (new) | unit | stage machine (allowed transitions, no backwards moves), chain state, `chain_link` recipe cost/output, save at schema 9 → stage 6, schema 10 round trip, every stage's guidance line exists |
| `workflow_c3_story` (new) | workflow | real scene: banging spawns two, bulkhead crank hold/early-release/refusal, first wave one-at-a-time, chain snapped refusal, craft + fit, second wave, snare proof, bolt kill, handoff |
| `workflow_c1_controls` | update | bulkhead is now a crank; shutter and snare levers unchanged; lever plane/reach/facing checks kept for the two levers |
| `e2e_gameplay` | update | fast-forward the story to stage 6 before the existing shift, then assert the C2 loop still runs (no count loss) |

Rules kept from A0/C1/C2: every suite runs alone, no suite depends on wall-clock
timing, and the scripted spawns are reachable through an explicit test hook
(`advance_story_for_test(stage)`) rather than by waiting.

Expected gate: 15 suites, roughly 1330–1370 checks, 0 failures.

## 15. Modular build plan

| Module | Work | Check before moving on |
| --- | --- | --- |
| M0 | schema 10, `story_stage`, chain fields, migration, `unit_c3_story` skeleton | `unit_c3_story` green; old saves load at stage 6 |
| M1 | crank prop + hold interaction, bulkhead lever retired, C1 suite updated | `workflow_c1_controls` green |
| M2 | banging pair, shutter shudder/dust/lines, crank gate | `workflow_c3_story` banging + crank cases green |
| M3 | first wave ordering, kills, stage 3 | those cases + `workflow_creatures` unchanged |
| M4 | chain visual, snapped refusal, `chain_link` recipe, fit interact | chain cases + `unit_crafting`/`workflow_crafting` unchanged |
| M5 | second wave, snare proof, bolt kill, handoff | full `workflow_c3_story` green |
| M6 | screenshots (`14a` banging, `14b` crank, `14c` chain snapped, `14d` trap proof), docs, `e2e` update | full gate green, gallery inspected |

Screenshot pass uses the existing `tools/basement_shots.gd` runner and a new
`--story` set of frames, so the C3 beats are visible next to the C2 ones.

## 16. Scope fences (explicit non-goals)

- No new creature type, no stat change to the burrower, no change to the C2 cave/variant.
- No dialogue system, no voice, no cutscene camera beyond the existing wake sequence.
- No timed pressure, no fail state, no restart of the story on death.
- No change to trays, net, kitchen, orders, standing, heat model, gaps, insulation,
  storage rack, heat reclaimer, or the C2 cave pocket.
- No story on an existing save; no way to replay stage 1–5 without a new shift.
- No new hotbar slot and no new weapon.

## 17. Acceptance criteria

1. A new shift plays the whole sequence without a guide document: every stage's next
   action is readable from the room and the HUD line.
2. The bulkhead cannot be opened by a lever pull; it opens by the crank and by nothing
   else, and an early release leaves it closed.
3. The shutter cannot be cranked while the chain is snapped, and fitting one crafted
   link restores it.
4. The first wave cannot two-on-one the player, and both die to the blade alone.
5. The trap proves itself from the safe side; the beat never requires entering the
   chamber with a live creature loose.
6. After stage 6 every C2 action (net, dress, cook, cure, pack, order, cave) works with
   no story prompt.
7. Schema ≤ 9 saves load at stage 6 and lose nothing; schema 10 round-trips.
8. Full gate green, and `workflow_c1_controls` still proves the two remaining levers.

## 18. Decisions I made on your behalf (confirm or overrule)

1. **The bulkhead lever becomes a crank**, rather than a crank being added next to a
   working lever. Two controls on one door made the C1 suite's "one handle per
   mechanism" rule lie.
2. **The chain snaps at stage 1, not at the kill.** The player sees the failure while
   the banging is happening, so the repair recipe has a visible cause.
3. **The scripted pair is ordinary, not weakened**, and fairness comes from the
   one-at-a-time order and the chokepoint.
4. **No ammo before the beat.** The first bolts are crafted during the trap proof,
   which is what makes the workbench part of the story instead of a menu.
5. **The story is new-shift only.** Existing saves resume as finished; the alternative
   (forcing the sequence onto a returning farm) breaks every C2 save in the repo.
6. **Six stages, one guidance line each.** No checklist panel, no quest log.
7. **The cave-side wheel is not chained.** A broken chain that strands a player in the
   cave would be a bug, not a lesson.
8. **Screenshots and docs are part of the delivery**, as in C1 and C2.

## 19. Questions for you

1. **Crank or keep the lever?** If you want the C1 bulkhead lever kept as a latch with
   the crank raising the gate, say so and I will make the crank a second control that
   only works after the latch is thrown (and add the C1 exception).
2. **How hard should the first wave be?** Proposal: two ordinary burrowers, one at a
   time, 0 bolts. The alternative is one creature plus one that flees, which is softer.
3. **Should the chain repair be a craft or a salvage fix?** Proposal: a workbench
   recipe (1 part + 1 chitin). The alternative is fitting the dropped link straight
   from the floor with no crafting, which skips the workbench beat.
4. **Should the story be replayable?** Proposal: no. A `new shift` is the only way back
   in, which keeps saves simple.
5. **Do you want the banging pair to be killable through the closed bulkhead** (a bolt
   through the gap), or only once it is cranked up? Proposal: only after cranking —
   the crank is the beat.

## 20. Delivery format when C3 is complete

1. Summary of the first-night sequence as shipped.
2. Files added and modified, with the module each change belongs to.
3. Assets generated (pipeline output + manifest entries) and anything still awaiting
   approval.
4. Test results: both new suites, the two updated suites, and the full run with check
   counts and timings.
5. Screenshots `14a`–`14d` and the balance numbers as shipped.
6. Known issues and anything that came in under the proposal.
7. **Stop and wait for approval before C4.**
