class_name StoryState
extends RefCounted

## Phase C3 // the first night. Pure model: no scene access, no nodes.
##
## The opening is a seven-stage chain. Every stage is earned by an action in the
## room, never by a timer, and the machine only ever moves forward one step, so a
## reload, a double interact or a lost frame can never skip a beat or undo one.
##
##   0 DORMANT         wake, fire, tool kit (already shipped)
##   1 BANGING         two burrowers hit the sealed shutter; the chain snaps
##   2 FIRST WAVE      bulkhead cranked; the pair fought one at a time
##   3 CHAIN SNAPPED   both dead; the shutter lever refuses until a link is fitted
##   4 ROOM REOPENED   shutter lifted; two more drawn; arm the snare from the warm side
##   5 TRAP PROVEN     the snare holds one; craft bolts and finish it
##   6 HANDOFF         C3 ends; the C2 loop runs free
##
## The chain fields live here because they are story state, not inventory: a
## snapped chain is a property of the opening, not an item the player owns.

const STAGE_DORMANT := 0
const STAGE_BANGING := 1
const STAGE_FIRST_WAVE := 2
const STAGE_CHAIN_SNAPPED := 3
const STAGE_ROOM_REOPENED := 4
const STAGE_TRAP_PROVEN := 5
const STAGE_HANDOFF := 6
const STAGE_COUNT := 7

## One stage may only be reached from the one before it. A stage that has already
## been reached is a no-op rather than an error, so a retried action is harmless.
const TRANSITIONS := {
	STAGE_DORMANT: [STAGE_BANGING],
	STAGE_BANGING: [STAGE_FIRST_WAVE],
	STAGE_FIRST_WAVE: [STAGE_CHAIN_SNAPPED],
	STAGE_CHAIN_SNAPPED: [STAGE_ROOM_REOPENED],
	STAGE_ROOM_REOPENED: [STAGE_TRAP_PROVEN],
	STAGE_TRAP_PROVEN: [STAGE_HANDOFF],
	STAGE_HANDOFF: [],
}

## The line the HUD carries while the player is on that stage. One line at a
## time, no panel: if the strip is empty the room's plate or lever tag is saying
## the same thing in the world.
const STAGE_LINES := {
	STAGE_DORMANT: "",
	STAGE_BANGING: "SOMETHING IS HITTING THE OUTER SHUTTER",
	STAGE_FIRST_WAVE: "TURN THE BULKHEAD CRANK — HOLD E",
	STAGE_CHAIN_SNAPPED: "SHUTTER CHAIN SNAPPED — CRAFT A CHAIN LINK",
	STAGE_ROOM_REOPENED: "CRANK THE SHUTTER — THEN ARM THE SNARE FROM HERE",
	STAGE_TRAP_PROVEN: "CRAFT BOLTS AND FINISH THE ONE IN THE SNARE",
	STAGE_HANDOFF: "THE FARM IS YOURS — NET, KITCHEN, ORDERS",
}

const STAGE_NAMES := {
	STAGE_DORMANT: "dormant",
	STAGE_BANGING: "banging",
	STAGE_FIRST_WAVE: "first wave",
	STAGE_CHAIN_SNAPPED: "chain snapped",
	STAGE_ROOM_REOPENED: "room reopened",
	STAGE_TRAP_PROVEN: "trap proven",
	STAGE_HANDOFF: "handoff",
}

var stage := STAGE_DORMANT
## True from the moment the chain snaps until one crafted link is fitted. The
## shutter lever refuses to travel while this is set.
var chain_broken := false
## Crafted chain links in the pack, not yet fitted at the shutter.
var links := 0
## The scripted pair has already been put in the chamber once, so a reload never
## re-spawns them into a room the player already fought through.
var banging_done := false


func reset() -> void:
	stage = STAGE_DORMANT
	chain_broken = false
	links = 0
	banging_done = false


func is_complete() -> bool:
	return stage >= STAGE_HANDOFF


func guidance() -> String:
	return str(STAGE_LINES.get(stage, ""))


func stage_name() -> String:
	return str(STAGE_NAMES.get(stage, "unknown"))


func can_advance_to(next_stage: int) -> bool:
	if next_stage == stage:
		return true
	if not TRANSITIONS.get(stage, []).has(next_stage):
		return false
	# The repaired chain is what reopens the room, so the repair is part of the
	# transition: a fit the player has not made cannot be skipped by a stage move.
	if next_stage == STAGE_ROOM_REOPENED and chain_broken:
		return false
	return true


## Move one step forward. Advancing to the stage already reached is allowed and
## changes nothing; skipping, retreating or leaving the last stage is refused.
func advance_to(next_stage: int) -> bool:
	if not can_advance_to(next_stage):
		return false
	stage = next_stage
	# The chain is the banging pair's doing: it snaps as the first beat starts,
	# not when the last of them dies, so the repair has a visible cause.
	if stage >= STAGE_BANGING and stage < STAGE_ROOM_REOPENED:
		chain_broken = true
	return true


## Convenience for the beats that just move to the next number.
func advance() -> bool:
	return advance_to(stage + 1)


## The chain repairs: one carried link is spent and the shutter lever works again.
func fit_link() -> bool:
	if not chain_broken or links <= 0:
		return false
	links -= 1
	chain_broken = false
	return true


func to_save() -> Dictionary:
	return {
		"stage": stage,
		"chain_broken": chain_broken,
		"links": links,
		"banging_done": banging_done,
	}


## A missing story block is a schema <= 9 save: that farm predates the opening,
## so it loads finished with an intact chain rather than being sent back through
## a tutorial it has already outgrown.
func from_save(data: Dictionary) -> void:
	if data.is_empty():
		stage = STAGE_HANDOFF
		chain_broken = false
		links = 0
		banging_done = true
		return
	stage = clampi(int(data.get("stage", STAGE_DORMANT)), STAGE_DORMANT, STAGE_HANDOFF)
	chain_broken = bool(data.get("chain_broken", false))
	links = maxi(0, int(data.get("links", 0)))
	banging_done = bool(data.get("banging_done", false))
	# A save can never describe a broken chain after the room is reopened: the
	# repair is what reopened it.
	if stage >= STAGE_ROOM_REOPENED:
		chain_broken = false
