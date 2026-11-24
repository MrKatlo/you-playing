# **Underground Rail System — Final Build Specification**

**Status: Planning complete, ready for implementation.**

I'll close the remaining design questions with recommended defaults rather than continuing the interview. This specification consolidates the decisions from Questions 1–47, resolves Question 48, and fills the remaining gaps in progression, controls, encounters, saving, and testing.

The guiding principle is to make the rail system **a required, atmospheric transportation route with meaningful repairs and creature threats**, without turning it into an overly complex vehicle simulator.

## **1. Core experience**

The player discovers a damaged mining cart in the existing cave corridor, repairs it with nearby starter parts, and rides to the cave pocket to access an industrial trading terminal. Advanced parts allow the player to restore the cave pocket workshop and eventually the rail's safety systems.

**Cave corridor**

Starting station

**Stage 1:** Repair cart

**Stage 3:** Restore tunnel safety systems

Outbound tunnel — collapse, flood, creatures

**Cave pocket**

Trading terminal, Stage 2 workshop, shared parts storage

Maintenance return tunnel — creature territory

**Back to cave corridor**

The system uses one continuous, one-directional loop with two stations. The player cannot steer or reverse. They must manually stop at stations or complete another loop.

## **2. Final decisions for remaining open questions**

| Area                      | Final recommendation                                                                                                                |
| ------------------------- | ----------------------------------------------------------------------------------------------------------------------------------- |
| Headlight (Q48)           | **B — Manual on/off toggle.** No battery depletion. Echo Hunters cannot see it; light does not alter their detection.               |
| Story unlock              | Activate when the existing story reaches the **handoff** stage, after the player discovers the cart in the cave corridor.           |
| Rail progression          | Required to reach trading, but independent of beacon restoration.                                                                   |
| Cart controls             | Hold accelerate, release to coast, tap/hold brake, toggle headlight, interact to board/exit.                                        |
| Station stops             | Generous marked platform zones, full stop required, no automatic braking.                                                           |
| Station hold              | Cart remains still after stopping until acceleration resumes.                                                                       |
| Mid-tunnel stops          | Allowed, but player cannot exit.                                                                                                    |
| Cart repair               | Allowed when fully stopped, including inside tunnels.                                                                               |
| Workshop repair           | One mechanical part restores full durability after Stage 2.                                                                         |
| Save behavior             | Persist stable station, durability, repairs, inventory, trading stock, and progression; do not serialize a live ride.               |
| Save during ride          | Disable manual saving until the cart reaches a station or recovery state.                                                           |
| Reload after interruption | Resume at the last confirmed station with persisted durability and inventory; never spawn a cart inside incomplete tunnel geometry. |
| Failure recovery          | Capture returns player and cart to cave corridor; cart at 0 durability on breakdown.                                                |
| Difficulty                | Fair environmental warnings before hazards and Echo Hunter attacks; avoid unavoidable damage.                                       |
| Accessibility             | Adjustable warning audio, subtitles for important sounds, and optional reduced camera shake.                                        |

**Important refinement:** I recommend using the handoff stage as the initial story-unlock target, but checking its actual meaning in `scripts/story_state.gd` before implementation. If handoff occurs too late or conflicts with the trading objective, use the nearest existing earlier stage rather than inventing a new story state unnecessarily.

## **3. World layout and visual direction**

[Buildings into bomb shelters: Germany eyes WWII-like bunker revival amid Russia threat](https://images.openai.com/static-rsc-4/3yOKmHChqp8mXi6IYUnXrCHt-oRCEriTMxh50aD6vp3EA-ssjVXo1_U89rClEOi0rcEc_gytp6bvccXCJIS80TS0XGOOCsx7dXJcsMC9ccMjydFQ-7oNw_LRipl7o8O9Sdz0tJsYXUPOi9fM-p918BAt_rk8cg_YGhkYB0M_2_A?purpose=inline)

Outbound tunnel

Cold concrete, exposed rails, dripping water, damaged supports and uneven lighting.

[ロンドンの地下を走る秘密の郵便運送用鉄道「メールレール」に乗ってみた - エキサイトニュース](https://images.openai.com/static-rsc-4/hqB2D6kn3FH1hOq3hlEUllwdlqgzbYw-fFmipTkFJchlRiyUD6bmcsCvltyPBsGpdMSJk_vngOktoSWPF68go71I4mjn3B2hUWF0uRcPNYyg9u9e-ky-7piszucX5jHvu2PKvaXs9bshz6LLw48YQmZzHmcOjBZuvSeqcdSu9Yk?purpose=inline)

Maintenance return tunnel

Disused service machinery, narrow passages, old tools and signs of creature activity.

These are visual references, not required production assets.

**Cave corridor:** Place the starting station near the existing outer shutter and shaft access, while preserving cave access and keeping the south-wall cold store doorway unobstructed. Include the damaged cart, starter repair point, emergency parts cabinet, Stage 3 safety panel, and later the shared-storage cabinet.

**Cave pocket:** Preserve the existing spool, beacon, and wayfinding elements. Add a platform, automated trading terminal, damaged workshop, and shared-storage cabinet. The terminal must be usable before Stage 2.

**Outbound tunnel:** Feature a potentially active collapse, a persistent flooded section, and 1–2 creature encounter opportunities per pass. Include the headlight figure scare and optional flood scare, capped at 1–2 scripted scares per ride.

**Return tunnel:** Use abandoned maintenance equipment, scraping sounds, vibration cues, and 2–3 creature encounter opportunities per pass. Mechanical hazards should be less prominent here.

Build both tunnel legs with modular sections so their lengths and encounter positions can be adjusted during playtesting.

## **4. Repair and progression specification**

| Stage                 | Location      | Requirements                                 | Permanent result                                                     |
| --------------------- | ------------- | -------------------------------------------- | -------------------------------------------------------------------- |
| 0 — Discovered        | Cave corridor | Reach story unlock and inspect cart          | Repair objective appears                                             |
| 1 — Cart repaired     | Cave corridor | Nearby starter parts                         | Cart becomes driveable                                               |
| 2 — Workshop restored | Cave pocket   | Traded Stage 2 kit                           | Workshop, station lighting and shared storage                        |
| 3 — Safety restored   | Cave corridor | Traded Stage 3 kit and three manual switches | Tunnel lighting, collapse warnings, flood warnings and motor upgrade |

The Stage 3 switches must be individually activated. Each triggers a short industrial startup sequence with relay clunks, electrical humming, progressive lights, and updated panel indicators. Completing the third switch permanently finishes Stage 3.

All advanced repair kits are protected progression items: they cannot be dropped, destroyed, or lost on capture. Installing a kit consumes it.

### **Permanent motor upgrade**

| Property                                       | Improvement |
| ---------------------------------------------- | ----------- |
| Acceleration                                   | +25%        |
| Maximum speed                                  | +10%        |
| Braking strength                               | +15%        |
| Coasting efficiency                            | Improved    |
| Echo Hunter detection range while accelerating | +20%        |
| Durability maximum                             | Still 100   |

The noise penalty applies only during acceleration, not quiet coasting.

## **5. Cart durability and emergency recovery**

**Cart durability**

## **100 / 100**

Illustrative full-durability state

- Echo Hunter attack: **−25 durability**.
- Normal stopped-cart repair: **one mechanical part restores +40**, capped at 100.
- Stage 2 workshop repair: **one mechanical part restores the cart fully**.
- Durability persists between rides and across saves.
- At zero durability, the cart breaks down, triggering capture/recovery at the cave corridor.
- The player keeps inventory, and the shift clock continues running.

The emergency cabinet normally holds up to three emergency mechanical parts after a breakdown, with normal replenishment after a successful full loop. Its anti-softlock guarantee overrides that ordinary limit when necessary: it supplies enough repair capacity to bring a broken cart back to 100 after accounting for usable carried and stored parts.

**Additional safeguard:** If the player arrives at the cave pocket without enough resources to trade or repair, allow ordinary scavenged resources to be gathered in accessible cave pocket areas. Progression must never depend on resources obtainable only after completing Stage 3.

## **6. Trading and resource economy**

The cave pocket terminal uses a worn industrial interface, indicator lamps, mechanical buttons, and a dispenser. No trader NPC is needed.

| Item               | Exchange cost                                   | Stock             |
| ------------------ | ----------------------------------------------- | ----------------- |
| Mechanical part    | 3 scrap metal + 1 wiring                        | 10                |
| Stage 2 repair kit | 5 scrap + 2 wiring + 1 mechanical component     | 1 until purchased |
| Stage 3 repair kit | 5 scrap + 2 batteries + 2 mechanical components | 1 until purchased |

Mechanical-part stock replenishes after a successfully completed full loop. Progression kits never restock after purchase.

The Stage 2 workshop unlocks shared mechanical-parts storage, accessible from cabinets at both stations, with a **25-part capacity**. Shared storage is distinct from carried inventory and emergency cabinet supplies.

**Implementation recommendation:** Make the resource names and trade costs data-driven so balancing them later does not require rewriting terminal logic.

## **7. Creatures, scares, and hazards**

[ArtStation - Cave Giant, Elliot Ward | Monster art, Creepy monster, Alien concept art](https://images.openai.com/static-rsc-4/gPF0CK1SYVDIrgZgRujYmi243-e5G8n6LLQug_VjpC9NgaAks3AiXR04YjpbJTBg7H7grfoG8QHMbuXxqZs3C4xCBPhnQ0wlW18QgrMVC3lF60-zFhXNz9wwy_7k250IP4sW1UyAcVpT-LBJndyxjk-kYQq8-U-cgCf3sRpvlkc?purpose=inline)

**Echo Hunter — primary rail threat**

A pale gray, blind creature with oversized ears and elongated limbs. It detects vibration and motor noise, ambushing carts that accelerate too close. Quiet coasting is the principal counterplay.

**Existing creatures**

Reuse Echo Scavengers, Burrowers, and Scavengers where their current behavior suits the tunnel. The adult Mimic remains excluded from version 1.

### **Encounter rules**

- Outbound: 1–2 encounter opportunities per pass.
- Return: 2–3 encounter opportunities per pass.
- Total: approximately 3–5 opportunities per complete loop, not guaranteed attacks.
- Randomize eligible creature positions on each new pass.
- Provide warning through flickering bulbs, rattling metal, scraping, and movement.
- Avoid spawning threats directly on top of the cart.
- Maintain a viable response window for quiet coasting or braking.

The collapse may trigger randomly on each outbound pass, with an audible creaking warning. The flooded section is always present and reduces acceleration. Stage 3 adds clearer warnings and lighting but **does not remove hazards or creatures**.

The scripted headlight figure scare should be brief, with a metallic stinger. The optional flood flicker/splash scare must respect the 1–2-scares-per-ride limit. Do not trigger scripted scares repeatedly on every extra loop caused by a missed station.

## **8. Save schema version 12**

Increment `SAVE_VERSION` in `scripts/farm_state.gd` from 11 to 12.

Recommended persistent fields:

| Field                        | Purpose                                |
| ---------------------------- | -------------------------------------- |
| `rail_unlocked`              | Story unlock                           |
| `rail_repair_stage`          | Highest completed repair stage, 0–3    |
| `rail_completed_repairs`     | Permanent repair flags                 |
| `rail_first_ride_completed`  | First journey milestone                |
| `rail_destination`           | Stable station destination/state       |
| `rail_station_restored`      | Stage 2 workshop completion            |
| `rail_safety_restored`       | Stage 3 completion                     |
| `rail_safety_switches`       | Three individual switch states         |
| `rail_cart_durability`       | 0–100                                  |
| `rail_motor_upgraded`        | Permanent performance upgrade          |
| `rail_shared_parts`          | Shared storage quantity, 0–25          |
| `rail_emergency_parts`       | Cabinet supply                         |
| `rail_recovery_pending`      | Breakdown recovery bookkeeping         |
| `rail_terminal_parts_stock`  | Current terminal mechanical-part stock |
| `rail_stage2_kit_purchased`  | Protected kit purchase status          |
| `rail_stage3_kit_purchased`  | Protected kit purchase status          |
| `rail_last_safe_station`     | Reload fallback                        |
| `rail_loop_completion_count` | Restock and progression tracking       |

Use the existing inventory serialization for protected kits where possible, rather than duplicating their inventory state in separate save fields.

For version 11 migrations, initialize rail fields to their safe default values and leave existing basement/story progress intact. Validate and clamp durability, storage, and stock counts on load.

## **9. Suggested Godot implementation structure**

Use existing project conventions, with scripts under `scripts/` and tests under `tools/tests/`.

| Component                    | Responsibility                                         |
| ---------------------------- | ------------------------------------------------------ |
| `scripts/rail_system.gd`     | Loop state, progression, station transitions           |
| `scripts/rail_cart.gd`       | Acceleration, coasting, braking, durability, headlight |
| `scripts/rail_station.gd`    | Platform zones, boarding, disembarking                 |
| `scripts/rail_encounters.gd` | Creature encounter scheduling and scares               |
| `scripts/rail_trading.gd`    | Terminal trades, stock, protected kits                 |
| `scripts/rail_workshop.gd`   | Stage 2 services and shared storage                    |
| `scripts/rail_safety.gd`     | Stage 3 switches, lighting and warnings                |
| `scripts/echo_hunter.gd`     | Noise detection, ambush and attacks                    |

Integrate with existing `basement.gd`, `story_state.gd`, `farm_state.gd`, `player.gd`, `basement_audio.gd`, and existing creature scripts. Avoid duplicating inventory or story-state ownership.

Generate or assemble rail assets using the existing basement asset pipeline at `assets/models/basement/source/generation_scripts/`.

## **10. Recommended build order**

IMPLEMENTATION CHECKLIST

0 of 9 phases checked

Reset

**1. Foundation**

Inspect current scenes, story states, inventory, save structure, and asset conventions.

**2. Rail geometry**

Build both stations and the continuous outbound/return loop without blocking existing entrances.

**3. Cart controls**

Implement boarding, acceleration, coasting, braking, headlight, stopping zones and stationary hold.

**4. First journey**

Implement story unlock, starter repairs, station warnings and reliable loop traversal.

**5. Economy**

Add cave pocket terminal, resource trades, protected kits, workshop and shared storage.

**6. Safety restoration**

Add Stage 3 panel, three switches, industrial startup feedback and upgraded motor.

**7. Threats**

Implement Echo Hunter, existing creature encounters, collapse, flooding and limited scares.

**8. Persistence**

Add schema 12 migration, round-trip serialization and recovery safeguards.

**9. Polish and QA**

Tune audio, lighting, collision, braking distances, encounter fairness and performance.

## **11. Acceptance tests before release**

The implementation should not be considered complete until these scenarios pass:

- The first cart repair is possible without visiting the trading terminal.
- The cart completes the full cave corridor → cave pocket → cave corridor loop.
- The player can stop at both stations and cannot exit mid-tunnel.
- Missing a stop forces another loop.
- The cart remains stationary after stopping.
- The Stage 2 terminal, workshop, and shared storage work correctly.
- All three Stage 3 switches activate independently and persist.
- The motor upgrade applies the agreed performance and noise multipliers.
- Echo Hunters respond to acceleration noise but not to the headlight.
- Breakdown recovery cannot permanently strand the player.
- Trading stock replenishes only after a completed loop.
- Protected kits survive capture, save/load, and inventory operations.
- Save version 11 migrates correctly to 12.
- Version 12 saves survive round-trip serialization.
- Existing tests remain green using `run_tests.tscn -- --all`.

## **12. Scope boundaries**

To keep the first build achievable, defer multiplayer, rail branching, steering, reversing, battery depletion, gas hazards, electrical hazards, adult Mimics, NPC traders, elaborate vehicle physics, and cinematic cutscenes.

The first playable milestone should be **a fully traversable two-station rail loop with a functioning cart and manual stops**. Add trading and progression only after that core journey works reliably.

**Specification complete — ready to build**

All 47 confirmed decisions are preserved, and the remaining gaps now have recommended implementation defaults. The numerical values are initial balancing targets, not promises of perfect gameplay tuning.

**No code or project files have been changed.** This is the completed planning specification, ready to use as the implementation brief.