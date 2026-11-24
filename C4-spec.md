# Basement Farm — Phase C4: the cold store

**Status:** BUILT, N0–N3. Approved 2026-11-22 and implemented the same day.
**Checks:** `unit_c4_cold_store` 53/0, `workflow_c4_cold_store` 37/0, plus the
existing suites unchanged.
**Deviations from the draft below:**
1. The room sits south of the cave corridor at `x 13.5–18.5, z -8.5–-4.0`. The
   draft's `z -4.0–0.0` is the corridor itself; the room needed its own footprint.
   The corridor's south wall is cut at `x 15.2–16.8` with jambs, a lintel and a
   threshold, so the store is entered on foot from the corridor.
2. The cold frame's reward is **meal preservation**, not a seventh culture tray.
   Trays are fixed at the six warm-room frames, and adding a seventh would have
   forced the tray, lid, colony and kitchen rules apart. A fitted frame keeps one
   cooked meal and eating it grants double hunger hours (`MEAL_HUNGER_HOURS × 2`),
   using the existing meal item and hunger rule instead of a new resource.
3. Each intact jar pays one part; the crate pays two parts and one heat gland.
**Drafted:** 2026-11-22 in answer to "make a new place of your choosing fitting to
the story".

---

## 1. The place

**The cold store** — a bricked-under root cellar sitting between the hunt chamber
and the cave, on the far side of the outer shutter.

The story already implies it: the banging comes from *somewhere* beyond the shutter,
and the shutter currently opens onto a bare corridor to the cave. The cold store
gives that side of the door a reason to exist: it is where the previous tenant kept
what the house ate before the farm, and it is where the burrowers come in through a
collapsed floor drain.

- **Where:** a 5 × 4 m room hung off the corridor at roughly
  `x 13.5–18.5, z -4.0–0.0`, between `OUTER_HUNT_SPAWN` and the cave junction. It
  does not touch the warm room, the hunt chamber's geometry, or the C2 cave pocket.
- **Reached by:** a short rubble-and-cart passage from the shutter corridor. One
  low doorway, one blind corner, one way in and out.
- **Cost to the player:** nothing to enter. It is the first place that pays for
  curiosity rather than for upkeep.

## 2. Why it fits the story

| Beat | What the cold store does |
| --- | --- |
| First night | Explains the banging: a drain grate at the back has been pushed in from below |
| After stage 6 | Opens as a second, colder foraging route beside the cave |
| The farm economy | Holds salvaged jars, a broken cold frame and one sealed crate — parts, not food |
| The burrower | Shows where the drawn animal actually comes from, without changing its AI |

## 3. What is in it

- **Shelf of jars** (generated prop): three intact, two broken. Breaking one gives
  water; the intact ones are searchable once.
- **Cold frame** (generated prop): a timber box with a cracked pane. Fitting one
  insulation patch secures it; it then keeps one cooked meal cold, and that meal
  is worth double hunger hours. The only new mechanical reward, built on the
  existing meal and hunger rules.
- **The drain** (generated grate + hole): the story tell. It is where the banging
  pair came from and it cannot be permanently sealed; it is scenery, not a spawner.
- **A sealed crate** (generated prop): one `heat gland` and two `parts`, once.
  It is the reason to walk in the first time.
- **Lighting:** one dead bulb over the door and the corridor's existing orange
  lamps. No new light rig.

## 4. Fences

- No new creature, no new AI, no new combat verb.
- No new resource, currency, or food value.
- No change to the warm room, trays, kitchen, orders, net, cave pocket, or the
  C3 first-night beats.
- The cold store is optional: a player who never opens the shutter loses nothing
  they need, only the crate and the second culture slot.
- Generated assets only, through the existing pipeline.

## 5. Shape of the work

| Module | Work | Check |
| --- | --- | --- |
| N0 | room shell, collision, doorway, lighting, reachability | `workflow_interaction` walks in and out |
| N1 | props: jar shelf, cold frame, drain grate, sealed crate | asset validation + manifest |
| N2 | searches, crate loot, cold-frame install, save fields (schema 11) | `unit_c4_cold_store` |
| N3 | screenshots, docs, full gate | `workflow_c4_cold_store`, gate green |

## 6. What I need from you

Approved and built. C3 M3–M6 remain open in their own phase; the cold store does
not arm the story and does not touch the first-night beats.
