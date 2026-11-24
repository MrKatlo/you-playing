# Basement Farm — specification

**Status:** decision-complete draft — interview closed, all open questions resolved in §12
**Short name:** `basement-farm`
**Date:** 2026-11-15
**Relationship to The Last Signal:** a second, self-contained experience inside the same Godot project. The station horror game stays playable and untouched; this is a new entry point from the title screen.
**Engine:** Godot 4.7, Compatibility renderer, GDScript (same as the station game).

---

## 1. Pitch

A cold-fallout survival game set in the basement of the player's own house. You are an
unnamed survivor running a two-line insect farm — protein rations for people, creature bait
for hunters — in a world where the only heat that matters is the heat you can make yourself.
Creature meat feeds the trays; creature fat, skin and bone feed the furnace; creature chitin
becomes parts. Neighbours leave orders on sticks planted outside. You pack the box, leave it in
the shutter hole, and find payment waiting the next night.

The horror is not the creatures. It is how quickly a dead animal becomes inventory, and how
normal the bookkeeping feels by the third order.

**Tone:** darkly comic small business. Receipts, hand-written price notes, "fresh protein,
ground this morning", deadpan copy over genuinely grim material. The comedy comes from
treating the apocalypse as a supply-chain problem, never from winking at the player.

---

## 2. Setting and premise

### 2.1 Climate: cold fallout

The surface froze or died of cold; the exact catastrophe stays unexplained. What matters:

- Heat is survival, currency and production input at the same time.
- The basement is warm because the player keeps it warm. That warmth is also what attracts
  creatures and what makes the insect cultures viable.
- Neighbours want the player's protein because their own food is cold, spoiled or gone.
- The player's furnace is the single most important object in the game.

### 2.2 The house

- **Basement:** the whole playable space in v1. Furnace, butcher table, culture shelves,
  packaging bench, order shutter, bed, stair door.
- **Top floor:** visible as a locked door at the top of the stairs only. It is a promise, not a
  space. It must read as "you will go up there eventually", not as a broken door.
- **Outside:** never directly playable in v1. The world reaches the player through order
  sticks and, occasionally, an in-person customer at the shutter.

### 2.3 The player

Unnamed survivor. No name in the HUD, no backstory logs, no link to Aster Station or the Echo
Lock. First person. Voice is expressed through the interaction copy and the ledger, not
through dialogue trees.

### 2.4 The creatures: blind burrowers

New fauna, unrelated to the station's Resonant.

- Nearly blind, heat- and smell-driven. They come for warmth and for fat.
- They nest in the ground beneath the house and push in through gaps on cold nights.
- They are malicious toward the player: contact causes venom, not just damage.
- They are also the farm's raw material. Every corpse is meat, fat, hide, bone and chitin.

---

## 3. Core loop

```
                 ┌──────────────────────────────────────────────┐
                 │  NIGHT ROUNDS                                │
                 │  read order sticks · check trays · seal gaps │
                 └───────────────────┬──────────────────────────┘
                                     ▼
   bait the hook  ──►  crank the shutter  ──►  kill the burrower
   (fat + warmth)      (exposed, loud, slow)    (melee / trap / ranged)
                                     │
                                     ▼
                          butcher at the table
             meat → trays   fat/skin/bone → furnace   chitin → parts
                                     │
                     ┌───────────────┴───────────────┐
                     ▼                               ▼
             feed & warm trays                 heat the basement
                     │                         (and yourself)
                     ▼
              harvest insect mass
                     │
                     ▼
        pack rations (people) / bait tins (hunters)
                     │
                     ▼
        leave the box in the shutter hole  ──►  payment next night
                                        parts · goods · standing
                     │
                     ▼
        upgrades (throughput · labour · quality · heat)  +  antidote stock
                     │
                     ▼
              sleep → fast-forward → new cycle
```

### One cycle, concretely

1. Wake (or continue) at the current in-game hour.
2. Walk the basement: tray status, furnace fuel, shutter integrity, gaps.
3. If an order stick is due, read it from the slate by the stair door.
4. Hang bait, crank the shutter open, wait in the dark, crank it shut behind the creature.
5. Kill it — method decides hide quality.
6. Butcher: assign meat / fat-skin-bone / chitin.
7. Feed the trays, top the furnace.
8. Harvest matured trays, pack product to order.
9. Put the box in the shutter hole; take any payment left from last night.
10. Spend parts on an upgrade, brew antidote if venom is active, or sleep to skip ahead.

There is **no fixed session length**. The farm idles, orders accumulate, and the player
decides when a shift ends. Nothing forces a stop; consequences arrive with the clock.

---

## 4. Time model

**Hybrid: continuous real time while playing, fast-forward on sleep.**

| Element | Rule |
| --- | --- |
| In-game clock | 24-hour day. 1 in-game hour = 1 real minute while playing. |
| Trays | Grow against the in-game clock, continuously. |
| Furnace | Burns continuously; fuel consumption is per in-game hour. |
| Breaches | Rolled at night hours (20:00–05:00) on a per-night basis, weighted by cold and by unsealed gaps. |
| Order sticks | Appear at dawn; collection deadline is an in-game hour, not a real-time timer. |
| Sleeping | Opens a summary: hours skipped, trays matured, feed consumed, fuel burned, orders missed, gaps that opened. Then the new cycle begins. |
| Pausing | The pause menu stops the clock. Reading a menu is never punished. |
| Game closed | The clock stops completely. No offline progress, no offline punishment (decision 4). |

Sleeping is the only way to skip time, and it is never free: trays keep consuming feed, the
furnace keeps burning, and unfulfilled orders expire.

---

## 5. Systems

### 5.1 Heat and the furnace

The furnace is the spine of the game.

- **Fuel:** fat, skin and bone from burrowers are the primary fuel. Tier 1 burns 1 fuel unit
  per 6 in-game hours.
- **Basement temperature** is derived from fuel burn rate and insulation tier, shown as a
  number and a band, not a hidden variable.
- **Bands:**
  | Band | Range | Effect |
  | --- | --- | --- |
  | Warm | 26–30 °C | Cultures at full speed; player comfortable |
  | Cool | 20–25 °C | Culture growth −40%; player fine |
  | Cold | 14–19 °C | Growth −80%; die-off begins after 4 hours; player hands slow |
  | Freezing | below 14 °C | Colonies die within 2 hours; player loses health and focus |
- **Player warmth** is separate from room warmth: standing away from the furnace in a cold
  basement drains a "warmth" meter that recovers near the stove.
- **Upgrades:** insulation (slower loss), better stove (more heat per unit), heat recovery from
  the packaging press (reuses waste heat).

### 5.2 Carcass and butchering

Every burrower is a resource bundle. Butchering happens at the table and takes in-game time
(20 minutes base, reduced by upgrades).

| Part | Use | Notes |
| --- | --- | --- |
| Meat | Feed for trays | Bulk feed; spoils if left unprocessed |
| Fat | Fuel + bait | The best fuel per unit, and the lure ingredient |
| Skin / hide | Sale (premium) + fuel | Quality is set by kill method |
| Bone | Fuel + tool parts | Poor fuel, useful material |
| Chitin | Crafting, upgrades, antidote | The "parts" material |
| Venom sac | Antidote ingredient | Optional, risky to harvest, valuable |

**Catch quality — the important rule (from the interview):**

- **Melee kill:** hide intact. Best skin price.
- **Trap / environmental kill:** hide damaged by the mechanism; middle grade.
- **Ranged kill:** hide ruined (holes). Meat and fat still fine, skin nearly worthless.
- **Crush gate:** hide destroyed.

So the safe option and the profitable option pull in opposite directions. Killing at range is
a panic button that costs money; killing up close risks venom.

### 5.3 Cultures (roach + maggot trays)

- Two species with different profiles, both starting from a small starter population:
  **roach trays** (slower, richer, more resilient) and **maggot trays** (fast, cheap, fragile).
- **Starting configuration: 3 trays — 2 maggot, 1 roach** (decision 3). Two trays leaves
  nothing to decide on the first night; four makes feed and heat trivial from minute one.
  Three forces one real feed decision immediately and leaves visible room for the throughput
  upgrade.
- **Feed:** trays consume feed units over time. Underfed trays lose yield; fully starved trays
  begin to die.
- **Temperature:** the growth rate is a function of the current band (5.1).
- **Growth:** real numbers compressed for play (see §8). Research basis: black soldier fly
  larvae reach harvest in 10–14 days at 27–30 °C and convert roughly 4.5–10 kg of waste into
  1 kg of larvae; cockroach meal peaks around 90 days with 81–91% survival.
- **Harvest:** a matured tray yields a batch of raw insect mass; harvesting early yields less,
  harvesting late risks escape and contamination.
- **Failure (confirmed in interview): colonies can die outright.** A cold snap or a missed
  feeding can wipe a tray. Restart requires a starter population, which costs parts or a
  favour.
- **Contamination:** a secondary risk — a bad carcass or a dirty tray can spread mould/mites to
  neighbouring trays unless quarantined.

### 5.4 Packaging

Raw mass becomes two product lines:

1. **Ration blocks** — pressed protein for people. Cheap, high volume, low standing gain.
2. **Bait tins** — creature lure for hunters. Higher value, uses fat, and carries an ironic
   cost: you are selling the same trick that keeps your own basement stocked.

Packaging is manual at first (a hand press, one block at a time, takes time). The powered press
is a labour upgrade. Grade (A/B/C) comes from culture health and processing speed: rushed or
starved product grades lower.

### 5.5 Orders, delivery and payment

**Two channels (from the interview):**

- **Order sticks (regulars).** A stick with a note is planted near the house; the player reads
  it from the slate at the stair door. Orders specify product, quantity, grade, deadline and
  payment. Delivery is asynchronous: leave the box in the shutter hole, and the goods vanish
  with payment left behind.
- **In-person buyers (special orders).** A knock at the shutter at a set hour. The buyer is
  visible through the slot, can negotiate, and can see the player. Special orders pay better
  and can unlock schematics, but they expose the player and can be refused or undersold.

**Order record fields:** id, buyer name, product, quantity, minimum grade, deadline (hour),
payment (parts / goods / standing), special flag.

**Payment is a mix of three things (from the interview):**

| Payment | Feeds |
| --- | --- |
| Parts (scrap, motors, valves, glass, wire, chitin) | Upgrades |
| Goods (clean water, coal, medicine, antidote ingredients, food) | Survival |
| Standing | Access to better buyers and special orders |

**Standing:** 0–100. Delivery on time adds standing; a missed or short order subtracts more
than a delivery adds. Tiers at 0 / 25 / 50 / 75 unlock order types and in-person buyers.

**Theft and short orders:** an order delivered late is refused; a box left with the wrong
grade is paid less. Payment left for you is never stolen.

A box left in the shutter longer than **2 in-game hours** past the buyer's window can be taken.
The chance depends on standing, because a buyer with a reason to trust you waits:
`standing 0–24: 40%`, `25–49: 20%`, `50+: 5%`. A theft costs the product, the order, and
3 standing on top of the missed-delivery penalty.

### 5.6 Creatures, luring, the shutter, and killing

**Lure:** hang rendered fat on the bait hook just inside the shutter. The hook is a consumable
cost (fat you could have burned or sold). Heat leak from the open shutter does the rest.

**The shutter:** a hand-crank beside the door. Cranking is slow, loud, and exposes the player
within reach of whatever is coming. It jams if a crate or a corpse blocks the track. A powered
shutter operated from a bench with a view slot is a later upgrade.

**Intrusion:** the house has gaps, and cold nights push creatures in. Breaches are rolled at
night, worsen if ignored, and can become nests inside the basement. Sealing gaps costs parts
and time; patrolling costs the attention the farm needs.

**Killing (three kill methods, plus live capture as an optional upgrade):**

| Method | Risk | Hide quality | Notes |
| --- | --- | --- | --- |
| Improvised melee (hook, cleaver, spear) | High — within reach, venom risk | Best | Silent, free |
| Environmental trap (crush gate, electrified grate) | Medium — needs setup and baiting onto the plate | Middle | Expensive to build, spectacular when it works |
| Ranged tool (compressed-air bolt driver) | Low — but loud, which pulls more creatures | Ruined | Scarce bolts; panic button. Shares the station riveter's shot and impact code, but not its fiction (decision 7) |

**Live capture (optional — decision 6):** the tier-2 environmental trap is a holding pit. A
burrower caught alive can be kept for up to 24 in-game hours, killed at the table when
convenient, and yields a grade-A hide plus a live-feed bonus. Buildable in v1, not required by
the acceptance criteria.

### 5.7 Venom and recovery

Confirmed in interview: a creature wound **poisons** the player.

- **Effect:** blurred vision (vignette pulse, slight sway), slower movement, and **slow hands**
  — interaction and cranking speed drop significantly. Precision work (butchering, packing,
  grading) takes longer, which is exactly how it costs production.
- **Recovery A — brew:** chitin + clean water + venom sac (or a substitute) + a heat unit,
  made at the bench. Fast, no time lost, consumes resources.
- **Recovery B — sleep:** collapse into bed. Venom clears, but time passes and the farm pays
  for it: trays unfed, fuel burned, orders missed.
- Venom does not kill directly; it makes you slow enough to lose money and to get hit again.

### 5.8 Upgrades

Four axes, tiers 1–3, paid for with parts and schematics (from the interview: all four axes
matter; v1 can ship tier 1 of each).

| Axis | Tier 1 | Tier 2 | Tier 3 |
| --- | --- | --- | --- |
| Throughput | 2 extra trays | Faster growth (+25%) | Third shelf; larger batches |
| Labour | Hand press → lever press | Auto-feeder | Powered shutter + auto-harvest tray |
| Quality | Thermometer + tray lids | Clean-room bench (grade floor B) | Grade A across the line |
| Heat efficiency | Insulated walls | Better stove | Waste-heat recovery from the press |

Environmental traps share the labour axis: tier 1 is a crush gate, tier 2 is the holding pit
(decision 6, live capture), tier 3 is an electrified grate.

Schematics come from special orders and from scavenging, and gate the higher tiers.

### 5.9 Failure and consequences

- No hard game over in v1. Failure is economic and physical: dead colonies, lost standing,
  no antidote, a nest inside the basement.
- A colony wipe is recoverable but expensive.
- Standing can fall to 0, which cuts off regular orders until the player rebuilds by selling
  bait cheaply to whoever is left.
- If the player is killed by a burrower, they wake at the bed with a time cost and a lost
  carcass — the same shape as the station game's checkpoint, without the horror reset.

### 5.10 The survivor's own needs (hunger — decision 1)

- One ration block feeds the survivor for ~30 in-game hours. Missing a meal is not death: it
  slows movement and interaction and stops the warmth meter recovering.
- Eating your own stock is the point: every block you eat is a block you cannot sell, and a
  short order costs standing. The farm feeds you, or it feeds the market, rarely both.
- Bait tins are not food. Attempting it is refused, with one line of copy, once.
- Deliberately the lightest meter in the game: a reminder, not a survival sim. It exists so the
  product has a cost and the ledger has teeth.

### 5.11 Hunter traffic (decision 2)

- Every bait tin sold raises **traffic**, a hidden neighbourhood counter: `traffic += 1` per tin.
- Traffic decays by 1 per in-game day, adds one extra breach roll per 3 traffic, and raises
  breach severity.
- The upside is real: high-traffic buyers order bait in bulk and pay in schematics, so a bait
  line funds the farm and then starts costing it. Selling no bait for a few days lets it cool.
- Traffic is never shown as a number. It shows as consequences: more clawing at the gaps, a
  heavier hiss from below, and a line in the sleep summary.

---

## 6. Presentation

### 6.1 HUD (borrowing the station game's minimal style)

- **Top left:** in-game clock, day counter, basement temperature band.
- **Under the clock:** a thin hunger pip, visible only when the survivor is hungry.
- **Top right:** standing, with the current tier name.
- **Bottom left:** compact inventory line — feed, fuel, chitin, water, antidote, ration
  blocks, bait tins.
- **Bottom centre:** interaction prompt (`[E] Butcher`, `[E] Feed tray`, `[E] Crank shutter`).
- **Centre top:** current order summary (product, quantity, deadline) as a single line.
- **Crosshair:** replaced by a small interaction dot; no combat reticle needed except when the
  ranged tool is drawn.
- **Venom state:** an amber vignette and a "HANDS SLOW / VENOM 01:12" readout.

### 6.2 Interaction model

Single interact key, consistent with the station game. Long actions (butchering, cranking,
packing) are hold-to-act with a small progress indicator. Nothing is a QTE in v1.

### 6.3 Audio (code-generated, as the station game already does)

- Furnace: low roar plus metal tick as it cools.
- Trays: dense insect hiss, louder with healthy trays, thin and quiet when a colony is dying.
- Shutter: chain rattle, heavy slide, a hydraulic thud when it seats.
- Burrower: wet breathing, claws on concrete, a smell-driven snuffle.
- Order stick: paper and wood click; a soft knock at the shutter for in-person buyers.
- Music: no melody. A low bed that thickens when the basement is cold or a nest is near.

---

## 7. Technical plan (mapped to the existing project)

Nothing here changes the station game; the basement is additive.

### 7.1 Scene and entry point

- New scene `scenes/basement.tscn` with a single root node running `scripts/basement.gd`
  (same pattern as `scenes/main.tscn` + `scripts/main.gd`).
- Title screen (`scripts/game_menu.gd`) gains one entry: **THE BASEMENT**. The existing
  NEW GAME flow is untouched.
- Player controller: reuse `SignalRunner` (`scripts/player.gd`) with the flashlight kept, and
  the station-specific noise plumbing redirected to the basement's own `make_noise`
  equivalent (creature hearing, not the Resonant).
- Ranged tool: the station riveter stays in the station game. The basement ships a **bolt
  driver** that reuses the shot, impact, decal, spark, audio and recoil code path with its own
  model, ammo and copy, so the two experiences share engineering but not fiction (decision 7).

### 7.2 Proposed scripts

| Script | Responsibility |
| --- | --- |
| `scripts/basement.gd` | Builds the room, owns game state, clock, save/load, HUD |
| `scripts/farm_state.gd` | `RefCounted`: trays, inventories, standing, upgrades, clock — pure model, unit-testable |
| `scripts/culture_tray.gd` | One tray's growth, feed, temperature response, die-off, harvest |
| `scripts/burrower.gd` | Blind creature: heat/smell seeking, breach behaviour, venom attack, death |
| `scripts/shutter.gd` | Crank progress, obstruction/jam, sealing state |
| `scripts/butcher_table.gd` | Carcass holding, part split, quality by kill method |
| `scripts/order_board.gd` | Order generation, sticks, deadlines, payments, standing |
| `scripts/furnace.gd` | Fuel burn, temperature bands, player warmth |

### 7.3 Layout (basement blockout)

Built from the existing station kit where possible (`station_wall_bay.glb`,
`ceiling_worklight_bay.glb`, `locker_bank.glb`, `service_pipe_rack.glb`) plus box-mesh props:

```
 ┌───────────────────────────── stairs (locked door) ─────────────────────────────┐
 │  order slate   │  shutter + crank  │   furnace   │  bed                       │
 │                                                                                │
 │   butcher table      culture shelves (6 trays)      packaging bench            │
 │                                                                                │
 └─────────────────────────  gaps / breach points  ──────────────────────────────┘
```

Roughly 12 × 10 m: big enough that the shutter is a real walk from the bench, small enough
that the player learns it in one cycle.

### 7.4 Save

Separate file: `user://basement_farm_save.json`. Do not touch
`user://last_signal_save.json`. Suggested shape:

```json
{
  "version": 1,
  "clock_hours": 31.5,
  "day": 2,
  "temperature_c": 27.0,
  "fuel": 6,
  "feed": 4,
  "parts": 9,
  "goods": {"water": 2, "coal": 1, "medicine": 0},
  "trays": [
    {"id": "t1", "species": "maggot", "progress": 0.42, "health": 0.9, "fed": true, "contaminated": false}
  ],
  "standing": 12,
  "upgrades": {"throughput": 1, "labour": 0, "quality": 0, "heat": 1},
  "orders": [{"id": "o3", "product": "ration", "qty": 4, "grade": "B", "due_hour": 54, "paid": false}],
  "delivered_box": {"product": "ration", "qty": 3, "grade": "B", "hour_left": 52},
  "venom": {"active": true, "seconds_left": 72.0},
  "breaches": [{"id": "g2", "sealed": false, "severity": 0.3}]
}
```

### 7.5 Testing

- `farm_state.gd` must be testable without a scene: feed it hours and assert tray states.
- A headless harness in the style already used for the riveter (`--script` + SceneTree) can
  fast-forward a full cycle and assert: feed consumed, tray matured, product packed, order
  paid, standing changed, venom expiring correctly.
- Acceptance runs: windowed launch with zero script errors, and one scripted 3-cycle run.

---

## 8. First-pass numbers (tuning, not final)

Compressed from the research so a cycle is a session, not a season.

| Value | First pass | Basis |
| --- | --- | --- |
| Maggot tray maturation | 12 in-game hours | BSF harvest at 10–14 days, compressed |
| Roach tray maturation | 30 in-game hours | Roach cycle ~90 days, compressed ~60× |
| Feed consumption | 1 feed unit per tray per 4 hours | — |
| Feed → mass conversion | 5 feed units → 1 batch | BSF 4.5–10 kg waste → 1 kg larvae |
| Burrower carcass yield | 4 meat, 3 fat, 1 hide, 2 bone, 2 chitin | Design |
| Fuel per carcass (fat+skin+bone) | 4–5 units | — |
| Furnace burn | 1 unit / 6 hours at tier 1 | — |
| Batch → product | 3 ration blocks **or** 2 bait tins | Design |
| Ration block price | 1 part (grade B), 1.5 (A) | Design |
| Bait tin price | 2 parts + 1 standing | Design |
| Upgrade cost | tier 1: 6 parts · tier 2: 14 · tier 3: 26 | Design |
| Venom duration | 90 s, −40% move, −50% interaction | Design |
| Antidote | 1 chitin + 1 water + heat, 30 s | Design |
| Standing | +5 on-time delivery, −10 missed, −2 short | Design |
| Hunger | 1 ration block per 30 in-game hours | Design |
| Hunter traffic | +1 per bait tin, −1 per in-game day, 1 extra breach roll per 3 | Decision 2 |
| Shutter theft window | 2 hours past the buyer's window; 40/20/5% by standing | Decision 3 |

Sanity check on the loop: one burrower feeds roughly one tray for a day, heats the basement for
a day, and yields a hide worth about two blocks. That means one kill per day sustains a
one-tray operation, and growth requires either more kills or better conversion. This is the
intended pressure.

---

## 9. Interview record

| Round | Question | Answer |
| --- | --- | --- |
| 1 | Climate premise | Cold fallout — heat is the economy |
| 1 | Technical home | Same project, keep the station game playable |
| 1 | Player identity | A new unnamed survivor |
| 1 | Tone | Darkly comic small business |
| 2 | Product lines | Packaged protein for people; creature bait |
| 2 | Carcass split | Meat → feed; fat/skin/bone → heat; chitin → parts |
| 2 | Upgrade axis | All four: throughput, labour, quality, heat |
| 2 | Can colonies fail | Yes — they can die outright |
| 3 | Creatures | New blind burrowers, unrelated to the station |
| 3 | Lure | Heat and fat smell, bait on a hook inside the door |
| 3 | Shutter | Hand-crank beside the door — exposed, loud, slow |
| 3 | Uninvited entry | Yes — gaps, and cold nights push them in |
| 3 | Kill methods | Melee, environmental traps, ranged tool; hide quality varies |
| 3 | Injury | Venom: blurred vision, slow hands, lost farm focus |
| 4 | Recovery | Brew if stocked, sleep if not |
| 4 | Catch quality | Determined by kill method (hide damage) |
| 4 | Orders | Regulars by stick, special orders in person |
| 4 | Payment | Mix of parts, goods and standing |
| 5 | Time | Hybrid: real time while playing, fast-forward on sleep |
| 5 | V1 scope | All listed systems, top floor as locked door only |
| 5 | Session | No fixed length |
| 5 | Assets | Reuse existing kit and procedural primitives; Blender later |
| 5 | Top floor | Locked door, visible, not enterable |
| — | Follow-up | The seven open questions were resolved after the interview — see §12 for decisions and reasoning |

---

## 10. V1 scope — acceptance criteria

The first playable build is done when, in one session, a player can:

1. Walk the basement and read the clock, temperature and tray status.
2. Read an order stick from the slate and know what to make and when it is due.
3. Bait the hook, crank the shutter, trap or kill a burrower, and take venom damage.
4. Butcher the carcass and see meat / fat-skin-bone / chitin split into inventory.
5. Feed and warm a tray, watch it mature, and harvest it.
6. Pack rations and bait tins, with grade affected by culture condition.
7. Leave the box in the shutter and receive payment the following night.
8. Spend parts on at least one upgrade and feel the change.
9. Brew an antidote, or lose a cycle sleeping it off.
10. Survive a breach event or patch the gap that causes one.
11. Save, quit, reload, and continue with clock, trays and standing intact.
12. Get hungry and eat a ration, feeling the cost of eating sellable stock.
13. Sell a bait tin and see the extra pressure at the gaps a day later.
14. See the locked stair door and know it is not yet part of the game.

---

## 11. Out of scope for v1

- Any playable top floor, street, or outdoor area.
- NPCs walking around; buyers exist only at the shutter.
- Multiple customers with full schedules and negotiation dialogue.
- Fluid/heat simulation beyond the band model.
- Market pricing, competing farms, or an abstract currency.
- Co-op, controller support, subtitles (inherited gaps from the station game).
- Authored Blender models for trays, press, burrower and shutter.

---

## 12. Resolved decisions

All seven open questions are closed. Each entry records the decision, the reasoning, and where
it lives in the spec, so implementation does not have to guess.

### Decision 1 — The survivor eats

**Decision:** yes, but lightly. One ration block feeds the survivor for ~30 in-game hours;
missing meals slow movement and interaction and stop warmth recovering, but never kill
directly. Bait tins are not food.

**Why:** the product has to cost something to the person making it. Eating your stock turns
"how much can I sell" into a real question every cycle without adding a second survival sim to
a game that already runs on heat, feed, clock and standing. It also lands the dark joke: the
farmer is the farm's second-best customer.

**Where:** §5.10; HUD pip in §6.1; acceptance criterion 12.

### Decision 2 — Selling bait raises hunter traffic

**Decision:** every bait tin sold adds 1 to a hidden `traffic` counter. Traffic decays by 1 per
in-game day, adds one extra breach roll per 3 traffic, and raises breach severity. High-traffic
buyers are also the ones who order bait in bulk and pay in schematics.

**Why:** it makes the bait line a strategic choice instead of a strictly better product. Selling
the trick that keeps you alive should come back through your own gaps, on a delay long enough
that the player sees cause and effect.

**Where:** §5.11; breach rolls in §5.6; acceptance criterion 13. Never shown as a number.

### Decision 3 — Three starting trays

**Decision:** start with 3 trays — 2 maggot, 1 roach. This replaces the "2 or 4" framing.

**Why:** two trays leaves nothing to decide on the first night; four makes feed and heat
trivial and hides the systems the game is about. Three forces one real feed decision
immediately, keeps the first upgrade visibly useful, and still reads as a small operation
rather than a factory.

**Where:** §5.3; throughput upgrade in §5.8.

### Decision 4 — The clock stops when the game is closed

**Decision:** no offline progress, no offline punishment. Time advances only while playing or
when sleeping. Closing the game pauses the world mid-cycle.

**Why:** an idle farm that punishes absence is hostile in a game whose tone is quiet routine.
Sleeping is the only skip, and it is always deliberate and always summarised.

**Where:** §4 table; §5.1 fuel burn; save schema in §7.4.

### Decision 5 — Named, unseen regulars; silhouette buyers in person

**Decision:** regular buyers are named in their notes but never seen — a name, a handwriting
style and a standing relationship. Special buyers appear at the shutter as a silhouette with
one or two lines, and are named too. Environmental text stays grim; the comedy lives in
commercial copy, notes and the ledger, not in jokes attached to horror.

**Why:** keeps the basement claustrophobic with no NPC crowd, while giving the notes a voice
and letting the player form favourites. It also puts the writing budget where it pays — order
sticks, not cutscenes.

**Where:** §5.5; shutter knock and note audio in §6.3; §11.

### Decision 6 — Live capture exists, gated behind the pit

**Decision:** the tier-2 environmental trap is a holding pit. A live burrower can be kept up to
24 in-game hours, killed at the table when convenient, and yields a grade-A hide plus a
live-feed bonus. Buildable in v1, not required by the acceptance criteria.

**Why:** it rewards the safest kill method with the best material and completes the risk curve —
melee is fast and dangerous, traps are safe and expensive, live capture is safest and best but
needs infrastructure. It is also the "catch it a different way, sell the skin" idea from the
interview.

**Where:** §5.6 killing-table note; §5.8 trap tiers.

### Decision 7 — The basement has its own ranged tool

**Decision:** the station riveter does not ship in the basement. The ranged option is a
compressed-air **bolt driver** reusing the existing shot, impact, decal, spark, audio and recoil
code path, with its own model, ammo ("bolts", not rivets) and copy.

**Why:** the two experiences share engineering, not fiction. Reusing the code is free; reusing
the gun would imply a world link the interview rejected when the burrowers were made unrelated
to the station.

**Where:** §5.6 killing table; §7.1 technical plan.

**Consequence check:** with these seven decisions no part of the spec depends on an unanswered
question. What remains open is tuning only, which §8 labels first-pass and the loop-maths risk
in §13 asks to simulate before it is trusted.

---

## 13. Risks

- **Scope:** eight systems in v1 is a lot for one pass. The order above is dependency-correct;
  butchering and trays must work before packaging or orders mean anything.
- **Legibility:** a temperature band plus feed plus clock plus standing is four meters, and
  hunger plus hidden traffic push it further. If the HUD grows past the station game's
  minimalism, the game stops reading as atmospheric. Hunger is therefore a pip and traffic is
  never a number.
- **Tone:** body horror plus bookkeeping jokes is a narrow register. It needs one strong
  writing voice, not jokes sprinkled over grim text.
- **Loop maths:** the §8 numbers must be simulated, not assumed; a bad conversion rate makes
  the farm feel like a treadmill.
- **Bleed into the station game:** new shared scripts must not break the existing save or the
  station main scene. Keep basement state in its own file and its own script.

---

## 14. Research notes

Used for grounding, not copied as mechanics:

- Black soldier fly larvae: harvest in 10–14 days, preferred 27–30 °C, 4.5–10 kg organic waste
  per 1 kg larvae — [ECHOcommunity: BSFL production](https://www.echocommunity.org/en/resources/86a8212a-a048-41c6-ab31-536c111e75ac),
  [Rwanda BSF SOP](https://www.rab.gov.rw/index.php?eID=dumpFile&f=117887&t=f&token=11ea31c93ef2f79bea0d5c5657e9dff729f7996f).
- Temperature thresholds and development models — [PLOS One: threshold temperatures of Hermetia illucens](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0206097).
- Cockroach meal protein content and survival by rearing period — [American Journal of Entomology](https://sciencepublishinggroup.com/article/10.11648/j.aje.20250904.11).
- Insect feed conversion comparison — [PLOS One: feed conversion of four insect species](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0144601).
