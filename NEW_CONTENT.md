# New content added in the C3 "first night" session

Every addition made in this session, for your review.

## Story (C3)
- Six-stage first-night chain in `scripts/story_state.gd`: banging, first wave, chain snapped, room reopened, trap proven, handoff.
- Scripted banging pair and first-wave logic in `scripts/basement.gd` (`_begin_banging`, `_update_first_wave`).
- Second-wave creature drawn in when the chain is fitted (`story_second_wave`).
- Bulkhead crank (`scripts/bulkhead_crank.gd`) replaces the old bulkhead lever.

## Items and crafting
- **Chain link**: new workbench recipe (1 parts + 1 chitin). Fitted at the outer shutter lever to repair the snapped chain. Saved as `chain_links` in `scripts/farm_state.gd`.

## Characters
- **THE RIVET**: a new buyer added to the order list (`BUYERS` in `scripts/farm_state.gd`).

## Not built in this session
- No new creature, place or upgrade beyond the items above. These were requested but not finished.

## Logbook
- **Mara's logbook line**: shown once at the handoff (`MARA_LOGBOOK_LINE` in `scripts/basement.gd`).

## Creatures
- **Rust burrower** (data variant): a tougher, slower slime on the existing slime body and AI, with 4 health, speed 3.6, and heavier knockback (`_rust_config` in `scripts/basement.gd`). It has no new model, so it reuses the slime mesh and paint.

## Upgrades
- **Rivet gun** (fifth upgrade track, `AXES` and `AXIS_NAMES` in `scripts/farm_state.gd`): saved and loaded with the other tracks. Its effect is not wired to gameplay yet, so buying it does nothing in play.
