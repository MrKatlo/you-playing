# Basement Farm — Phase C2 specification

**Status:** implemented — M0–M8 plus the C2 revision landed. Shipped state and test counts live in `DEVELOPMENT_STATUS.md`; the balance table below is shipped, not proposed. The revision (population colonies, net on hotbar slot 4, kitchen queue) is recorded in §22 and supersedes the matching rows below.
**Drafted:** 2026-11-20 from a nine-round design interview (all answers captured below).
**Phase rule:** implement C2 only; stop and report before starting C3.

---

## 1. One-paragraph summary

C2 turns the abstract cricket tray into a working insect farm: mature trays are split to found new colonies, harvested with a crafted net into a live count, dressed and cooked or cured at a new kitchen station into **cricket meal** and **cricket jerky**, wrapped at the packaging bench, and sold either through the safe base hatch or through a **new trade drop** at the far end of a newly extended cave. Cave work is better paid but must be fetched in person, and the drop sits beside a **breach in the cave wall** that pushes a heavier, dark-orange burrower variant into the room when the player makes noise or light there.

---

## 2. Locked decisions (from the interview)

| # | Question | Decision |
| --- | --- | --- |
| 1 | What C2 is deepest at | **All three, thin but end-to-end**: husbandry, processing, delivery |
| 2 | Colony model | ~~Keep the progress bar~~ → **population count on a schedule** (§22); still no per-insect simulation |
| 3 | Order channel | **Both, with a tradeoff**: base hatch is safe and pays less; cave drop is dangerous and pays more |
| 4 | Harvest | **Trap/net first** — a crafted net is required to move live crickets |
| 5 | Processing location | **New kitchen station** (new prop, its own recipes) |
| 6 | "Multiply" | **Split a mature colony**: net a mature tray, carry the starter to an empty tray, new tray starts partial |
| 7 | Feed depth | **Keep plain feed units** — no feed grades, no moisture; growth stays temperature/feed gated |
| 8 | Meal vs jerky | **Bulk food vs preserve**: meal is cheap bulk food, jerky is slow to make, high value, travels |
| 9 | Spoilage | **Nothing spoils** — deadlines create pressure, not timers |
| 10 | Cave station | **New path and pocket** in the cave, "a bit of a walk" |
| 11 | Buyer | **Never seen** — fresh paper, dropped satchel, wet bootprints, a sound cue |
| 12 | Cave payment | **Goods now, pay later** — payment appears in the drop on a later trip |
| 13 | Cave reward | **Better pay only** (no rare goods, no extra standing tier) |
| 14 | Cave path scope | **A real new pocket** with its own light, soundscape and creature risk |
| 15 | Kitchen placement | **Reuse a free wall** — no new room, no floorplan change to the warm room |
| 16 | Net durability | **Craft once, keep forever** |
| 17 | Order paper | **Carry it home** — the paper becomes a slate entry |
| 18 | Unfilled cave order | **Expires with standing loss**; paper found torn next trip |
| 19 | New food's use | **Both anywhere**: meal restores the most hunger, jerky less, rations least |
| 20 | Hands-on beats | **Four**: net → kitchen dress → cook/cure → wrap at packing bench |
| 21 | New props | **Generated GLBs via the existing Basement asset pipeline** (approval for generation follows spec approval) |
| 22 | Tests | **Two new suites** (one unit, one workflow) |
| 23 | Pocket threat | **New burrower variant**: fast, heavy knockback on the player when struck, dark orange, splits into two on death, larger loot, new materials |
| 24 | Timing | **Quick turnaround**: processing under one in-game hour total, several batches per day |
| 25 | Open cave orders | **Unlimited, daily** — one paper per in-game day while the pocket can hold it; unfilled ones expire |
| 26 | Clone splits | **No further splits** — the two clones are ordinary burrowers |
| 27 | Variant loot | **Ember chitin always, heat gland rare** |
| 28 | New materials' use | **One recipe each**: ember chitin → sturdier snare; heat gland → portable lamp |
| 29 | Pocket gate | Not a key: the pocket is dark and the variant is a **constant threat**; they come from a **hole in the side wall** |
| 30 | Hole interaction | **Look inside** — a prompt that reveals a glimpse (glow, movement, sound) |
| 31 | Threat cadence | **Reacts to noise/light**: it emerges when the player uses the drop or lingers near the hole |
| 32 | Lamp resource | **Burns fuel** (same units as the furnace) |
| 33 | Payout mechanism | **Payment appears in the box** on a later trip |
| 34 | Numbers | **I propose them** — see §7, review and edit |
| 35 | Pocket size | **≈3× the current cave's walkable area** |
| 36 | Scope fence | **Nothing outside the loop**: no changes to the heat model, gaps, insulation, storage rack, cave heat reclaimer, C1 levers or hunt-chamber rules |

---

## 3. Current state audit (what C2 builds on)

| Area | Today | Location |
| --- | --- | --- |
| Trays | 6 slots, `START_TRAYS = 1` active, cricket tray 0 + unfinished maggot frame | `FarmState.TRAY_SLOTS`, `basement.gd::_build_trays` |
| Growth | progress per tray; `CRICKET_MATURATION_HOURS = 30`, `MAGGOT_MATURATION_HOURS = 12`; fed flag from a shared `feed` pool at 1 unit / 4 h; health falls when unfed or cold; dead colony revives for 3 parts | `farm_state.gd::_grow_trays`, `feed_tray` |
| Harvest | mature tray → **generic `mass`** (1/2/3 by throughput tier), tray health −0.15, progress reset | `farm_state.gd::harvest_tray` |
| Tray interaction | open lid, then feed or harvest in the same press | `basement.gd::_use_tray`, `_open_tray_lid` |
| Crickets | rigged cricket GLB with an `AnimationPlayer`, 3 animated crickets per cricket tray | `cricket.glb`, `basement.gd::_build_cricket_colony`, `_update_crickets` |
| Packing | `pack()` mass → rations / bait tins; `pack_for_order()` boxes ration/bait/hide; `leave_box()` puts the box in the **delivery hatch** | `farm_state.gd::pack`, `pack_for_order`, `leave_box` |
| Orders | `_dawn()` generates 1–2 hatch orders (ration/bait/hide, due +20 h, pay 3–8 parts + qty, water 0–2, standing 3–6); settled at the next dawn with grade/late checks | `farm_state.gd::_dawn`, `_deliver_settlement`, `tray_grade` |
| Standing | 0–100, thresholds used at 20/25/50 | `FarmState.standing` |
| Cave | hunt-chamber shutter → 14×4 m frozen maintenance gallery (x 10→24) + a 4×3 m side pocket; return wheel; B-01 marker; salvageable C-4 regulator; **no orders, no drop, no second pocket** | `basement.gd::_build_cave_access`, `CAVE_MARKER_SPOT`, `cave_cart` |
| Burrower | `Burrower` class: health 2, speed 4.2, stalk 1.35, leap/bite/reflex guard; `on_burrower_killed(creature, method, position)` spawns guts + a carcass whose grade depends on the kill method; butchering yields hide/chitin/meat | `scripts/burrower.gd`, `basement.gd::on_burrower_killed`, `_spawn_carcass` |
| Player knockback | `player.take_damage(amount, from_position, knockback)` already pushes the player | `scripts/player.gd::take_damage` |
| Save | `SAVE_VERSION = 7`, plain dictionary, `from_save()` with per-field defaults | `farm_state.gd` |

---

## 4. The loop, end to end

```text
BASE                                                          CAVE
────                                                          ────

mature cricket tray
      │ net (12 live)
      ├──────────────► seed an empty tray (6 live) ──► colony starts at 35%
      │
      └──────────────► live crickets (6)
                             │ dress at kitchen
                             ▼
                     2 dressed crickets
                        │            │
                    cook (1 fuel)  cure (free)
                        │            │
                        ▼            ▼
                   2 cricket meal  2 cricket jerky
                        │            │
                        └────┬───────┘
                             │ wrap at packing bench
                             ▼
                        packed box
                             │                       ┌── deposit ──► trade drop
                             ├── deliver ───────────┤
                             │   (base hatch)        └── payment on a later trip
                             │
           paper order ◄─────┘   carried home, becomes a slate entry
           (found in the cave drop)
```

Player-facing beats in one session:

1. Open a mature cricket tray, net a load of live crickets.
2. Either seed an empty tray with half of them, or carry the load to the kitchen.
3. At the kitchen: dress the load, then cook (meal) or cure (jerky).
4. At the packing bench: wrap the batch for a hatch order, or walk the cave, take a paper, bring it home and wrap for that.
5. Deliver: hatch (safe) or cave drop (better pay, a fight on the way).
6. Next cave trip: collect the payment from the box.

---

## 5. Husbandry and harvest

### 5.1 Harvest replaces mass for cricket trays only

- A mature **cricket** tray yields **live crickets** into the net (no `mass`).
- A mature **maggot** tray keeps yielding `mass` as today (mass → rations / bait tins is unchanged).
- Harvest still resets `progress` and costs tray health (−0.15, floor 0.55), unchanged.
- Throughput tier still multiplies the harvest: **12 / 18 / 24** live crickets at tiers 1/2/3 (instead of 1/2/3 mass). Net capacity is not a limit; the count is carried.

### 5.2 Net

- New workbench recipe: **Cricket net** — 2 parts + 1 hide, crafted once, permanent (`net_crafted`).
- Without a net, harvesting a cricket tray opens the lid and reports "You need a net to take them alive."
- The net is a hand tool: while it is the equipped tool slot, the player model shows a simple net; no new tool slot system, it rides the existing tool selection.

### 5.3 Multiplication (split)

- With **≥ 6 live crickets** carried, an **empty or inactive** tray can be seeded: −6 live crickets, tray becomes `active`, `progress = 0.35`, `health = 1.0`, `species = "cricket"`.
- Seeding a dead tray revives it this way instead of the 3-part starter (the 3-part starter stays as the fallback when no crickets are carried).
- This is the only way new trays start, so tray count (throughput upgrades) and cricket supply are coupled.
- No passive spreading, no auto-seeding.

### 5.4 Feed and growth

- Unchanged mechanics: feed units at 1/4 h per active tray, top-up costs 1 unit, health −0.05/min unfed, cold penalties, death at 0 health.
- Unchanged constants: cricket 30 h, maggot 12 h, temperature bands 26/20/14.

### 5.5 Tray interaction order (physical, one key)

| Tray state | Press |
| --- | --- |
| mature | open lid → net (crickets) / harvest (maggots) |
| carrying ≥6 crickets and tray empty | open lid → seed colony |
| dead | open lid → starter culture (3 parts) or seed from carried crickets |
| growing | open lid → top up feed |

---

## 6. Kitchen: dress, cook, cure

### 6.1 Station

- New **kitchen bench** against the free west wall (no new room, no floorplan change). It is present from the first shift as improvised clutter: a board, a knife block, a pot, a drying rack.
- Interaction: one key opens a small kitchen panel (same visual language as the workbench panel): **Dress**, **Cook**, **Cure**, **Close**.
- Everything is physical: the tray of dressed crickets sits on the board, the pot steams when cooking, the rack fills with strips when curing.

### 6.2 Beats

| Beat | Cost | Result | In-game time |
| --- | --- | --- | --- |
| Dress | 6 live crickets | 2 dressed crickets | 0.1 h |
| Cook | 2 dressed + 1 fuel | 2 cricket meal | 0.5 h |
| Cure | 2 dressed | 2 cricket jerky | 1.0 h |
| Wrap (bench) | product units equal to the order quantity | packed box | instant |

- Dressing is where the waste sits: six crickets lose shells, legs and gut and leave two portions, so a net load is worth two batches of one product, not six.
- Total processing per net load (12 live → 4 dressed → 4 of one product) is **1.2 h** (meal) or **3.2 h** (jerky) of in-game time, so several batches fit in a day. Time advances the farm clock and therefore fuel burn, hunger and colony growth — processing competes with the day, not with the player's patience.
- No spoilage of any kind.
- Cooking requires the furnace to be lit; curing does not (it is a dry rack), which makes jerky the cold-day product.

### 6.3 Grades

`tray_grade(0)` continues to grade the batch (quality upgrades and tray health matter), and the grade is recorded on the meal/jerky units at cook/cure time.

---

## 7. Balance table (shipped — matches the code at M8)

| Quantity | Value |
| --- | --- |
| Cricket harvest | population − 6 breeding reserve, clamped by net capacity 60 (throughput tiers no longer change it) |
| Cricket growth | 6 at start → 27 at 150 growth-minutes (2.5 real min) → 43 at 300 → asymptote to 120; fed only (freezing pauses) |
| Seed an empty tray | 6 live → a new colony at the 6-cricket floor |
| Dress (retuned, M2) | 6 live → 2 dressed, 0.1 h |
| Cook (retuned, M2) | 2 dressed + 1 fuel → 2 meal, 0.5 h |
| Cure (retuned, M2) | 2 dressed → 2 jerky, 1.0 h |
| Cricket meal hunger | 36 h (best) |
| Cricket jerky hunger | 22 h |
| Ration hunger | 30 h (unchanged) |
| Meal order price (cave) | `qty * 3 + rng(4..9)` parts, water 0–2, standing 3–6 |
| Jerky order price (cave) | `qty * 4 + rng(5..10)` parts, water 0–2, standing 3–6 |
| Hatch order price (unchanged) | `rng(3..8) + qty` parts, water 0–2, standing 3–6 |
| Cave order due | +14 h (hatch stays +20 h) |
| Cave order expiry | due + 2 h → standing −2, paper torn |
| Cave papers on the ground at once | max 6, one added per in-game day |
| Payment delay | present on the next visit at least 1 in-game hour after the drop |
| Net recipe | 2 parts + 1 hide |
| Ember snare (workbench) | 1 ember chitin + 1 snare → 1 snare that survives its first trigger |
| Gland lantern (workbench) | 1 heat gland + 2 parts + 1 chitin |
| Lantern burn | 1 fuel per 10 in-game minutes of use, 6 m warm light |
| Cinder burrower health | 3 (normal burrower 2) |
| Cinder burrower speed | 4.8 (normal 4.2) |
| Cinder burrower knockback | 1.2 m push on the player per landed strike on it |
| Cinder burrower loot | carcass grade A; butcher yields 1 ember chitin + 25% heat gland + normal hide/chitin/meat |
| Cinder burrower spawn | max 2 alive, 60 s cooldown, leashed to the pocket |

---

## 8. Orders

### 8.1 Two channels

| | Base hatch (existing) | Cave trade drop (new) |
| --- | --- | --- |
| Source | `_dawn()` rolls | a paper in the cave pocket, one per day |
| Due | +20 h | +14 h |
| Goods | ration / bait / hide | meal / jerky / (10%) ration / bait / hide |
| Pay | as today | ~1.8× as today |
| Risk | none | the walk and the variant |
| Failure | existing late/under-grade rules | same, plus expiry at due + 2 h → standing −2 |

The hatch path is **not** modified: same generation, same settlement, same penalties. Only the cave channel is new.

### 8.2 Paper lifecycle

1. A new paper appears in the drop **once per in-game day** while fewer than 6 papers are on the ground.
2. Interacting with the drop while papers are present **reads the top paper and takes it**; the order is added to `farm.orders` with `source = "cave"`, so the slate and the packing bench can use it.
3. Carry it home, wrap the required goods at the packing bench (the paper must have been taken; packing for a cave order you have not collected is refused with a clear message).
4. Interacting with the drop carrying a packed cave box deposits it.
5. On a later visit (≥1 in-game hour after the drop), the drop holds the payment: parts + water. Taking it credits the account and clears the field.
6. If an order passes due + 2 h unfilled, it is removed from the slate, standing −2, and the next visit shows that paper torn under the clamp.

### 8.3 What the cave looks like

- A trade drop: a bolted steel box with a clamp and a paper slot, marked with faded buyer paint, standing on a pallet.
- Evidence of people: wet bootprints converging on the box, a dropped satchel, a stub of pencil, chalk tally on the wall, three hollow knocks as a sound cue when the player first enters the deposit chamber.
- Nobody is ever visible and nothing talks.

---

## 9. The new cave pocket

### 9.1 Size and layout (≈3× the current cave)

The current cave is about **68 m²** of walkable floor (14×4 m gallery plus a 4×3 m side pocket). The new pocket targets **≈220 m²**, extending beyond the existing cave's far end (x ≈ 24):

| Space | Size | Purpose |
| --- | --- | --- |
| Approach corridor | 10 × 4 m (40 m²) | a bend, broken maintenance bays, a cold draft, first bootprints |
| Gallery | 20 × 5 m (100 m²) | two support bays, an ice-fall landmark, failing emergency lights |
| Deposit chamber | 10 × 7 m (70 m²) | the trade drop on its pallet at the far wall, the wall breach in the dark side wall |
| Side dead end | 4 × 3 m (12 m²) | the breach itself, debris, a glimpse further in (hint of the deeper cave) |

Walk from the shutter to the drop is about **45 m one way** — 13 s at walking speed, longer when carrying a fight.

### 9.2 The wall breach

- A ragged hole in the side wall of the deposit chamber: broken blockwork, stained ice, a warm orange glow from inside, low breathing.
- **Look inside** prompt (`LOOK INTO BREACH`): a glimpse of glowing mass and something shifting, one sound cue, no combat, no gate.
- It is the variant's spawn point; it is never sealed in C2.

### 9.3 Threat cadence

- A variant crawls out of the breach when the player **uses the drop** (read/take/deposit/collect) or **lingers within 2.5 m of the breach for 4 s**.
- Max 2 variants alive, 60 s cooldown between spawns, leashed to the pocket (they give up at the corridor mouth rather than following into the old cave).
- The deposit is therefore the risk: doing business makes noise and shows light.

### 9.4 Darkness and the lamp

- The pocket's own fixtures are dead or failing: two dim emergency strips in the gallery, nothing in the deposit chamber.
- The gland lantern is the intended tool: 6 m warm light, burns 1 fuel / 10 in-game minutes, toggled from the tool slot.
- Without it the chamber is navigable but the breach and the paper slot are hard to see, and the flashlight's narrow cone is not enough to work by — the pocket is playable but hostile.

---

## 10. The Cinder Burrower (variant)

- **Appearance:** dark orange, emissive seams, slightly larger than the normal burrower (×1.15), same rig and clip set so animation work is a recolour plus scale.
- **Stats:** health 3, gait 4.8 m/s, otherwise the same sense range, leap and bite behaviour. No AI rewrite: a `variant` configuration on `Burrower` (`max_health`, `speed`, `body_colour`, `knockback_on_hit`, `splits_on_death`, `loot_table`).
- **Knockback:** every player strike that lands on it pushes the **player** back 1.2 m (a `player` impulse, not damage), so melee means re-approaching after each hit. No contact knockback, no charge attack.
- **Split:** on death it splits into **two ordinary burrowers** at ±0.7 m, both at full health (2), and **neither can split**. The variant's own death is a one-time doubling, so killing it can be worse than avoiding it.
- **Sound:** a distinct wet tearing split (pitched metal-hit plus a low body burst) layered on the existing death cue.
- **Loot:** carcass grade A, butcher yields **1 ember chitin** always plus a **25% heat gland**, alongside the normal hide/chitin/meat. Both new materials are stackable inventory counts.
- **Placement:** only the new pocket's breach, never the base gaps or the hunt chamber.

---

## 11. New recipes and materials

| Recipe | Station | Cost | Effect |
| --- | --- | --- | --- |
| Cricket net | Workbench | 2 parts + 1 hide | permanent net; enables cricket harvest and seeding |
| Ember snare | Workbench | 1 ember chitin + 1 snare | a snare that survives its first trigger (reusable once) |
| Gland lantern | Workbench | 1 heat gland + 2 parts + 1 chitin | permanent hand lantern that burns fuel |

---

## 12. Eating

- `farm.eat()` becomes a choice of carried food: **meal** (36 h, best), **ration** (30 h, unchanged), **jerky** (22 h).
- All three can be eaten anywhere (base or cave) — no location gate.
- Hunger rules are otherwise unchanged (no death from hunger; movement and interaction penalties stay).

---

## 13. Data and save

### 13.1 New `FarmState` state

```text
live_crickets : int      # netted, carried
dressed_crickets : int   # kitchen output awaiting cook/cure
meals : int
jerky : int
meal_grade : String      # grade of the current meal batch
jerky_grade : String
ember_chitin : int
heat_glands : int
net_crafted : bool
lantern_crafted : bool
lantern_on : bool
lantern_fuel_seconds : float
ember_snares : int
cave_papers : Array      # [{id, buyer, product, qty, min_grade, due_hour, pay_*, torn, taken}]
cave_drop : Dictionary   # {product, qty, grade, order_id, hour_left, due}
cave_payout : Dictionary # {parts, water, standing, ready_hour}
```

### 13.2 New/extended API

```text
harvest_tray(index)                  # cricket → live_crickets, maggot → mass (unchanged signature)
seed_tray(index)                     # −6 live → active tray at 0.35 (falls back to 3 parts)
dress_crickets()                     # −6 live → +2 dressed, 0.1 h
cook_meal()                          # −2 dressed, −1 fuel, furnace lit → +2 meal, 0.5 h
cure_jerky()                         # −2 dressed → +2 jerky, 1.0 h
eat(kind := "ration")                # meal / ration / jerky
craft_at_workbench(...)              # + net, ember snare, lantern recipes
toggle_lantern() / tick_lantern(min) # fuel drain, on/off
roll_cave_papers()                   # called once per day
take_cave_paper()                    # paper → orders entry (source "cave")
pack_for_order()                     # extended to meal / jerky / cave orders
drop_cave_box()                      # deposit a packed cave box
collect_cave_payout()                # credit parts/water, clear field
```

### 13.3 Save schema

- `SAVE_VERSION` → **8**.
- `from_save()` adds defaults for every new field, so a v7 save loads: no net, no live crickets, no papers, the existing trays/orders untouched.
- New save round-trip and v7→v8 migration checks go in the new unit suite.

---

## 14. Presentation

| Moment | Feedback |
| --- | --- |
| Net a tray | lid opens (existing), net swipe, crickets scatter inside the rim, sound |
| Seed a tray | the starter is tipped in, three crickets appear and begin their existing crawl loop |
| Kitchen dress | board knock, a wet chop, dressed pile appears on the board |
| Cook | pot lid, steam, warm light on the bench, a soft bubbling loop |
| Cure | rack slides out, strips hang, dry air hiss |
| Wrap / pack | paper folds, string pull, box lid |
| Drop box in the cave | metal lid, clamp snap, three knocks answer from the breach |
| Payment collected | a small tin of parts, water flask, weight |
| Breach | breathing, shifting gravel, a fade-in orange glow before the variant appears |
| Variant death | wet tearing split, both halves land with separate splashes |
| Paper taken | paper rustle, slate entry sound reuse |

HUD: the existing slate gains "CAVE" tagged lines; the objective arrow points at the trade drop when a cave box is carried and at the hatch otherwise.

---

## 15. Assets to generate (pipeline)

All generated through `assets/models/basement/source/generation_scripts/` and registered in the build manifest, with structural validation, animation verification where rigged, a Godot import probe and screenshot coverage — the existing definition of done.

| Asset | Path | Notes |
| --- | --- | --- |
| Kitchen bench | `generated/props/kitchen_bench.glb` | board, knife block, pot, drying rack, worn enamel, and a wear pass (greyed grain, splintered lip, water rings, grease fan, soot, chalk tally, hand-driven nails, enamel mug and bent spoon) so the station reads used rather than new |
| Trade drop box | `generated/props/cave_trade_drop.glb` | bolted steel box, clamp, paper slot, pallet |
| Wall breach | `generated/props/nest_breach.glb` | ragged blockwork, stained ice, warm inner glow socket |
| Gland lantern | `generated/props/gland_lantern.glb` | hand lantern with a glowing gland core |
| Cricket net | `generated/props/cricket_net.glb` | handle + hoop + mesh (small; may fall back to primitives) |
| Order note | `generated/props/order_note.png` | paper texture + handwritten order (also used for the torn state) |
| Cinder burrower | `generated/creatures/cinder_burrower/cinder_burrower.glb` | burrower body recoloured dark orange with emissive seams, same rig/clips |

Audio: reuse existing clips (furnace creak, metal hit, chain, door, hurt) with pitch variation; **new clips only if a beat is unserved**, and each new clip will be listed for approval before download.

---

## 16. Testing plan

### 16.1 New suites (two)

**`unit_c2_culture`** (unit, no scene, <5 s)
1. Cricket harvest yields live crickets above the 6-cricket reserve; maggot harvest still yields mass.
2. Population schedule: 6 → 27 at 150 minutes → 43 at 300, capacity 120, growth pauses when unfed or cold.
3. No net → harvest refused with the right message and no state change.
4. Seeding: 6 live → active tray at 0.35/health 1.0; refused under 6; refused on a growing tray; dead tray seeded instead of the 3-part starter.
5. Dress/cook/cure yields, fuel and furnace gates, dressed shortfall refusals.
6. In-game hours advanced match the table (0.1 / 0.5 / 1.0).
7. Eating: meal 36 h, ration 30 h, jerky 22 h; each consumes one unit; refusal at full hunger.
8. Hatch order generation is byte-identical to today (no regression), cave order generation favours meal/jerky, pays the cave formula, dues +14 h.
9. Paper lifecycle: daily roll, cap 6, take → order with `source "cave"`, packing refused before taking, expiry at due + 2 h → standing −2 and torn flag.
10. Drop/payout: drop stores the box, payout not present immediately, present after ≥1 h, collecting credits once and clears.
11. Lantern: burn rate, toggle, refusal with no fuel.
12. Ember snare: survives one trigger, then behaves as a normal snare.
13. Save: v8 round-trip for every new field; v7 save migrates with defaults and keeps trays/orders.

**`workflow_c2_culture`** (workflow, real scene, ~25–40 s)
1. Real tray interaction nets a mature cricket tray and the carried count rises.
2. Seeding a real empty tray through `player_interact()` makes the new colony visible and animated.
3. Kitchen: walk to it, dress, cook (furnace lit) and cure through the real panel; visuals change; clock advances.
4. Packing bench: wrap a meal batch for a cave order (refused before the paper is taken).
5. Walk the new pocket: breach is reachable, `LOOK INTO BREACH` prompt appears, the drop is the nearest interactable at the box.
6. Paper: take it, the slate shows the cave order.
7. Variant: using the drop spawns one from the breach; a landed strike pushes the player back; killing it produces two clones; clones do not split; loot contains ember chitin and (seeded RNG) a gland.
8. Drop the box, leave, wait ≥1 h in game, return: payment is in the box; collecting credits it exactly once.
9. Lamp: fuel drains while on; off stops the drain.
10. Expiry: a cave order left unfilled past due + 2 h is gone, standing is −2, the paper reads torn.
11. Nothing in the warm room or the old cave regressed (levers, hatch, trays, hunt room all still work).

Both suites register in `tools/tests/dependencies.json`; `e2e_gameplay.depends_on` gains both (same pattern as `workflow_c1_controls`).

### 16.2 Existing suites that must stay green

`unit_survival`, `unit_crafting`, `unit_weapons`, `workflow_interaction`, `workflow_survival`, `workflow_crafting`, `workflow_weapons`, `workflow_creatures`, `workflow_ui`, `workflow_c1_controls`, `e2e_gameplay` — full run must report 0 failures, and any check count that changes must be explained in the delivery report.

---

## 17. Modular build plan (break into pieces, check as we go)

Nine modules. Each one is a **vertical slice that leaves the game playable**, has its own
check gate, and is small enough to review in one report. Nothing in a later module is
needed for an earlier one to be judged.

| Module | Delivers | Game after it | Gate (what must pass before the next module) |
| --- | --- | --- | --- |
| **M0 — state contract** | `FarmState`: `live_crickets`, `dressed_crickets`, `meals`, `jerky`, grades, save v8 + migration, harvest split (cricket → live, maggot → mass), `seed_tray`, `dress_crickets`, `cook_meal`, `cure_jerky`, `eat(kind)`. No visuals. | unchanged to the player except tray harvest text | new `unit_c2_culture` (rules half) + `unit_survival` + `workflow_survival` updated to the new rule + `unit_weapons` |
| **M1 — real crickets in the room** | net recipe, net in hand, tray interaction (net / seed / feed / revive) through `player_interact()`, visible starters in a new tray, HUD lines | you can net a mature tray and found a second colony | `workflow_c2_culture` (husbandry cases) + `workflow_interaction` + `e2e_gameplay` |
| **M2 — kitchen** | generated kitchen bench, panel (Dress / Cook / Cure / Close), time costs, steam/rack visuals | you can turn crickets into meal and jerky | `workflow_c2_culture` (kitchen cases) + `unit_crafting` + `workflow_crafting` |
| **M3 — products in the economy** | meal/jerky eating, grades, wrapping at the bench, slate lines, hatch order acceptance rules | you can eat a meal and fill an order with jerky | `unit_c2_culture` (product half) + `workflow_survival` + `workflow_ui` |
| **M4 — the walk** | new cave pocket geometry, lights, breach prop, trade drop prop, bootprints/satchel, route from the old cave. The drop exists but does nothing yet. | you can walk to the drop and look into the breach | `workflow_c2_culture` (walk cases) + `workflow_interaction` + `e2e_gameplay` |
| **M5 — orders at the drop** | daily papers, take-to-slate, cave packing, deposit, payout on a later trip, expiry and standing loss | the full C2 loop is playable end to end | `unit_c2_culture` (order half) + `workflow_c2_culture` (loop cases) + `workflow_survival` |
| **M6 — the Cinder Burrower** | variant config on `Burrower`, dark-orange materials, hit knockback, death split, loot, breach spawn cadence and leash | the drop trip has its threat | `workflow_c2_culture` (variant cases) + `workflow_creatures` + `tools/test_creature_ai.tscn` |
| **M7 — new materials and tools** | ember snare, gland lantern, fuel drain, the generated assets, the HUD readout, screenshots | everything in the spec is reachable | full `--all` run |
| **M8 — docs and balance** | `DEVELOPMENT_STATUS.md` C2 section, `AUTOMATED_QA.md` table, asset notes, shipped numbers | — | docs read correctly against the code |

### 17.0 Landed modules

| Module | Landed | Gate result |
| --- | --- | --- |
| M0 | yes | `unit_c2_culture` 86 / 0, `unit_survival` 57 / 0 |
| M1 | yes | `workflow_c2_culture` 97 / 0 at the time, full run 883 checks / 0 |
| M2 | yes | kitchen cases green, balance retuned (decision 11) |
| M3 | yes | product cases green; cave slate strip in the HUD |
| M4 | yes | `workflow_c2_culture` 114 / 0 at the gate, 120 / 0 after the presentation pass; prop assets 41 / 0; full run 983 checks / 0 in 87 s |
| M5 | yes | `unit_c2_culture` 125 / 0, `workflow_c2_culture` 153 / 0; full run 1061 checks / 0 in ~97 s |
| M6 | yes | `unit_c2_culture` 131 / 0, `workflow_c2_culture` 189 / 0, `workflow_creatures` 68 / 0, creature AI 43 / 0; full run 1103 checks / 0 in 97 s |
| M7 | yes | `unit_c2_culture` 160 / 0, `workflow_c2_culture` 221 / 0; prop assets 41 / 0, slime assets 22 / 0; full run 1168 checks / 0 in 102 s |
| M8 | yes | §7 checked against the shipped constants line by line, no retune; docs updated to the M8 run |

M4 shipped: the collapse dug through into a 16 × 4 m corridor, a 28 × 5 m gallery and a
10 × 7 m chamber (plus a 3 × 3 m nest nook) at the same floor level as the old cave, about
285 m² of new floor; the drop at `(74.85, 0.0, 2.60)` answers an empty clamp, the breach at
`(70.50, 0.0, 5.90)` flares its light on `LOOK INSIDE`. A presentation pass then gave the
chamber three landmark silhouettes (ore hopper, cable spool, pallet stack), a beacon lamp at
its mouth, and a worn paint line with two return stencils so the unlit walk back is readable.
M5 shipped the clamp's paper lifecycle: a paper at each dawn (cap 6), take-to-slate with
`source = "cave"`, cave-first benching and a hatch that refuses cave boxes, deposit with
payment collectable an hour later, and expiry at due + 2 h for standing −2 and a torn paper
under the clamp.

M6 shipped the pocket's threat: the same `Burrower` brain under a variant configuration
(3 health, 4.8 m/s, ×1.15, dark orange with glowing seams), a 1.2 m shove on the hunter for
every landed strike, a death that leaves A-grade remains and splits into two ordinary
bodies that cannot split again, cinder loot at the table (1 ember chitin, 25% heat gland),
and a breach cadence of max 2 alive, 60 s cooldown, stirred by the drop, the breach look or
two seconds of lingering, leashed 22 m around the breach.

M7 shipped the materials' tools: the ember snare (1 ember chitin + 1 snare, armed first,
one trigger before it folds back as a plain snare) and the gland lantern (1 heat gland +
2 parts + 1 chitin, a 6 m warm omni toggled from the light control, burning 1 fuel per ten
in-game minutes and going out when the store is empty), the pocket HUD readout (lantern
state plus the clamp line), the four generated assets (belt lantern, bench-and-hand net,
cinder model, order-note texture), the lantern's stride swing and low-fuel gutter, and the
13a–13i screenshot pass.

M8 closed the phase: the §7 table was checked against the code and no number moved, so
the table above is shipped balance rather than a proposal, and `DEVELOPMENT_STATUS.md`,
this module table and `AUTOMATED_QA.md` now carry the final counts.

### 17.1 Checkpoint protocol

1. **One module per turn.** I implement a module, then stop and report before touching the next.
2. **Report shape:** what changed (files), what is verified (suite + check counts), what is still a placeholder, and the exact next module.
3. **Targeted by default.** Each module runs the suites named in its gate plus anything
   `--changed=<edited file>` selects. The full `--all` run happens at **M1, M4, M6 and M7** — the
   modules that can quietly reach the hunt room, the cave threshold or shared combat.
4. **Deliberate test rewrites are called out.** Two existing checks assert that a cricket tray
   harvest yields `mass` (`unit_survival` "trays" case, `workflow_survival` "mature tray produces
   insect mass"). M0 changes that by design: those two move to live crickets, and a maggot-tray
   check keeps `mass` covered. Any other changed check count gets an explanation.
5. **No placeholder left behind.** A module's prop is generated or built in the module that needs
   it (kitchen bench in M2, drop/breach in M4), so nothing has to be revisited later.
6. **Go / no-go.** After each report you either approve, or name the change; fine-tuning of
   numbers is allowed at any checkpoint because every value sits in §7.

### 17.2 Why this order

- **Rules before visuals (M0).** The whole loop is data; proving it headless in ~5 s is cheaper
  than discovering a rule conflict through a station UI.
- **The farm before the kitchen (M1, M2).** The kitchen is useless without netted crickets, and
  the husbandry slice is what changes an existing mechanic, so it gets the earliest regression
  pass.
- **Economy before the walk (M3, M4).** Meal and jerky must be sellable before a cave trip to
  sell them is worth building.
- **The walk before the orders (M4, M5).** Geometry can be checked with nothing in it; the order
  logic is then a small, purely data change on a place that already exists.
- **The threat last among mechanics (M6).** A living, lethal variant in a half-built pocket makes
  every earlier test flaky; it lands once the pocket and the loop are stable.
- **Tools and polish last (M7).** The lantern only matters once the pocket exists, and the ember
  snare only matters once the variant drops chitin.

### 17.3 Files each module is expected to touch

| Module | Primary files |
| --- | --- |
| M0 | `scripts/farm_state.gd`, `tools/tests/unit_survival.gd`, `tools/tests/workflow_survival.gd`, new `tools/tests/unit_c2_culture.gd|.tscn` |
| M1 | `scripts/basement.gd` (tray/net/HUD), `scripts/player.gd` (net in hand), `scripts/farm_state.gd` (net recipe), new `tools/tests/workflow_c2_culture.gd|.tscn` |
| M2 | `scripts/basement.gd` (kitchen build + panel), `scripts/menu.gd` (kitchen panel), `scripts/farm_state.gd` (times), `generated/props/kitchen_bench.glb` |
| M3 | `scripts/farm_state.gd` (eat/pack/grades), `scripts/basement.gd` (slate lines), `tools/tests/*` updates |
| M4 | `scripts/basement.gd` (cave geometry, lights, props), `generated/props/cave_trade_drop.glb`, `nest_breach.glb` |
| M5 | `scripts/farm_state.gd` (papers/drop/payout), `scripts/basement.gd` (drop interaction, slate) |
| M6 | `scripts/burrower.gd` (variant config + split hook), `scripts/basement.gd` (spawn cadence), `generated/creatures/cinder_burrower/*` |
| M7 | `scripts/farm_state.gd` (ember snare/lantern), `scripts/basement.gd` (lantern tool), generator sources, manifest |
| M8 | `DEVELOPMENT_STATUS.md`, `AUTOMATED_QA.md`, `C2-spec.md` (shipped numbers) |

### 17.4 First module, concretely

**Start with M0 + M1 together as the first checkpoint, "crickets become real".** That is the
smallest slice that is visibly new: you can walk to a mature tray, net twelve live crickets,
and found a second colony. It contains the save change, the rule change and the first station
interaction, and it is the only module that rewrites existing checks, so getting it signed off
first means every later module builds on an agreed contract.

---

## 18. Scope fences (explicit non-goals)

- No changes to the furnace heat model, fuel burn constants, gaps, insulation patches, warm storage rack, cave heat reclaimer, or the C1 wall levers.
- No changes to hunt-chamber rules, bait, snare arming, step-dodge, landing guard, or player combat numbers beyond the variant's knockback impulse.
- No new player movement, inventory grid, magazine, cooking minigames or base rooms.
- No spoilage timers, no per-insect simulation, no feed grades, no second currency.
- No new biome, no deeper cave content: the pocket is one new area and one dead end.
- No modifications to the base hatch path or its order generation.
- No asset downloads without listing the file and getting approval; generated assets come from the existing pipeline only.

---

## 19. Acceptance criteria

1. A mature cricket tray can be netted only with a crafted net and produces a live count.
2. Six live crickets can found a new colony; progress starts at 0.35 and the colony animates.
3. Feeding, health, cold and death rules are unchanged.
4. The kitchen dresses, cooks and cures with the stated costs, times and outputs; cooking needs a lit furnace, curing does not.
5. Meal restores 36 h hunger, jerky 22 h, ration 30 h, each eaten anywhere, one unit each.
6. Meal and jerky can be wrapped for an order at the packing bench and appear as a packed box.
7. One cave paper appears per in-game day, up to six; taking it adds a `source "cave"` order to the slate.
8. Packing for a cave order is refused until its paper has been taken.
9. The new pocket exists beyond the old cave, ≈3× its walkable area, reachable on foot, with a breach, a trade drop, bootprints and a sound cue.
10. Using the drop or lingering at the breach spawns the variant (max 2, 60 s cooldown, leashed).
11. A landed strike on the variant pushes the player back ~1.2 m.
12. Killing the variant spawns exactly two ordinary burrowers that cannot split.
13. The variant drops 1 ember chitin always and a heat gland 25% of the time, plus normal loot.
14. The trade drop accepts a packed cave box and pays more than the hatch for the same goods.
15. Payment appears in the drop only on a later visit (≥1 in-game hour) and can be collected exactly once.
16. An unfilled cave order expires at due + 2 h with standing −2 and a torn paper.
17. The gland lantern burns fuel while on and stops when off or empty; ember chitin crafts the reusable snare.
18. Save version 8 round-trips every new field and loads a v7 save with safe defaults.
19. Both new suites and every existing suite pass headless with 0 failures.
20. `DEVELOPMENT_STATUS.md` and `AUTOMATED_QA.md` describe C2 and its numbers.
21. Nothing in the C2 fences is touched.

---

## 20. Decisions I made on your behalf (please confirm or overrule)

1. **Maggots keep `mass`** and feed rations/bait; only cricket trays switch to live crickets. Otherwise the whole existing ration loop would need rewriting.
2. **Seed cost 6 of 12** per harvest: a tray can either found a new colony or supply one kitchen load, not both, which makes multiplication a real allocation.
3. **Cave order due +14 h** (tighter than the hatch's +20 h) so the walk has a deadline cost; expiry at due + 2 h matches the hatch's existing lateness buffer.
4. **Payment needs a second trip** (≥1 in-game hour later), which is what makes "goods now, pay later" a real decision rather than a formality.
5. **The drop is a box on a pallet**, with the paper clamped above it, rather than a noticeboard: it keeps the "someone left this" fiction in one prop.
6. **The breach never spawns a variant while the player is at the base**, and the variant never follows into the old cave — fairness over pressure.
7. **Nothing gates entry to the pocket** beyond darkness and the variant, per your "not easy, but not a key" answer.
8. **Cave order mix** is 60% meal / 30% jerky / 10% ration·bait·hide, honouring "anything, favouring new goods" while keeping the new chain the main buyer.
9. **Variant carcass is always grade A**, so the fight is the price of the new materials rather than a second punishment.
10. ~~Throughput steps at upgrade 2 and 3~~ → **superseded by §22.1**: throughput no longer multiplies the scoop; the colony population does. The tier upgrade still rewards maggot mass.
11. **Dressing retuned to 6 live → 2 portions at M2.** The first draft (6 → 3, then 1:1 cook/cure) made one 30 h cricket tray worth 216 h of hunger against a maggot tray's 75 h for the same time, which made fuel, feed and the net meaningless. Splitting the loss off at the dressing step instead of the pot keeps every ritual the interview asked for (one net load dresses once, then one hot and one cold product) while landing a tray at 144 h of meals and 88 h of jerky, with 2 fuel spent per tray. Meal is still the best food and jerky is still the cheap, fireless, better-paying product.
12. **Cooked goods pack at the bench like anything else**, graded by the meal/jerky batch rather than the live tray, and dawn only replaces hatch papers: a paper carried out of the cave runs to its own due hour instead of dying with the hatch slate.

---

## 21. Delivery format when C2 is complete

1. Summary of the implemented loop.
2. Files added and modified.
3. Assets added (pipeline output + manifest entries), and anything still awaiting approval.
4. Test results: both new suites plus the full run with check counts and timings.
5. Known issues and the balance numbers as shipped.
6. **Stop and wait for approval before C3.**


---

## 22. Revision log — population colonies, net slot, kitchen queue

Added after the first C2 delivery, on request. Everything below supersedes the
matching decision, balance row and test step above.

### 22.1 Colony population model

- A cricket tray stores `population` and `growth_minutes` instead of leaning on
  `progress`. `progress` survives only as a derived 0–1 value for the tray
  visuals, so maggot trays keep their old bar and nothing in the room lies.
- Schedule: start 6, 27 at 150 growth-minutes (2.5 real minutes, since 1 game hour
  is 1 real minute), 43 at 300, then an exponential tail to the 120 cap.
  Growth is still fed-gated, and a freezing room pauses it, but the clock is real
  time: 2.5 minutes means 2.5 minutes from a cold start as well as a warm one.
- Harvest takes `population − 6`, capped by `NET_CAPACITY = 60`; the reserve stays
  behind and the remaining crickets keep their place on the curve.
- Seeding founds a colony at 6 and resets the clock. Save schema is **9**; a
  schema 8 or 7 save loads at safe defaults and a live tray at the 6 floor.

### 22.2 Net on hotbar slot 4

- `SLOT_NET = 4` and its own `slot_4` input action. A woven net is on the player
  at all times: another drawn slot parks it in a low right-hip carry, and slot 4
  lifts it into the netting grip. Harvesting a tray requires the net to be the
  drawn slot, and the tray prompt says `NET NEEDED (4)` when it is ripe and the net
  is stowed.

### 22.3 Kitchen quantity and queue

- The kitchen panel shows what can start now (`kitchen_max`), a batch stepper, and
  a queue line (front job percent, hours left, jobs behind it).
- `queue_kitchen(kind, quantity)` pays ingredients and fuel **at queue time** and
  ticks the front job; finished batches wait in `ready_meals` / `ready_jerky`
  until `collect_kitchen()`. Nothing can be spent twice, and closing the panel
  does not stop the board.

### 22.4 Creature colour

- The plain slime keeps its authored green: the forced orange multiply is gone.
- The shutter lure is spawned with its own painted red config on the same rig and
  brain, so the creature behind the bait reads red at a glance and recovers its
  health and speed from its own config rather than defaults.

### 22.5 Presentation

- The HUD chip reads `07/60 IN NET   02 DRESSED`.
- The tray station label carries `CULTURE TRAY 1 — 27/120 LIVE · HARVEST`, and a
  press reports population, feed state and seconds to the next scoop.
- The room shows 2–8 cricket rigs as the colony grows; the number is the truth.
