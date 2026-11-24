extends "res://tools/tests/test_base.gd"

## LEVEL 1 — Phase C3 // the first night: the stage machine, the chain and the save.
##
## No scene, no frames. The opening is a seven-stage chain whose whole rule set is
## "one step forward, never back, and only on the action that earns it", so the
## machine is pinned here in a second instead of being inferred from a playthrough.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/unit_c3_story.tscn


func _init() -> void:
	suite_name = "unit_c3_story"
	suite_level = "unit"
	needs_scene = false
	timeout_seconds = 40.0


func run_phases() -> void:
	_test_stage_machine()
	_test_chain_state()
	_test_guidance_lines()
	_test_save_v10()
	_test_legacy_save()


func _state() -> FarmState:
	var fresh := FarmState.new()
	fresh.new_game()
	return fresh


## Walk the story one earned step at a time. The machine refuses a skip on purpose,
## so a test that wants a later stage has to pass through the ones before it.
func _walk(story: StoryState, target: int) -> void:
	while story.stage < target:
		if not story.advance():
			return


## Repair the chain the way a player does: carry one link, then fit it.
func _fit(story: StoryState) -> void:
	story.links += 1
	story.fit_link()


# ------------------------------------------------------------- stage machine

func _test_stage_machine() -> void:
	begin_case("stage_machine", "the story moves one earned step at a time and never back")
	var story := StoryState.new()
	_eq(story.stage, StoryState.STAGE_DORMANT, "a fresh story starts dormant")
	_ok(not story.is_complete(), "and it is not finished")

	_ok(not story.can_advance_to(StoryState.STAGE_FIRST_WAVE), "stage 0 cannot skip to the first wave")
	_ok(not story.advance_to(StoryState.STAGE_FIRST_WAVE), "a skipped stage is refused")
	_eq(story.stage, StoryState.STAGE_DORMANT, "and the stage stays where it was")

	_ok(story.advance_to(StoryState.STAGE_BANGING), "the banging starts on its own beat")
	_ok(story.chain_broken, "the chain snaps as the banging begins")
	_ok(story.advance_to(StoryState.STAGE_BANGING), "advancing to the stage already reached is a no-op")
	_ok(not story.advance_to(StoryState.STAGE_DORMANT), "the story never walks backwards")

	_walk(story, StoryState.STAGE_CHAIN_SNAPPED)
	_ok(not story.advance(), "the room cannot reopen on a snapped chain")
	_eq(story.stage, StoryState.STAGE_CHAIN_SNAPPED, "so the stage holds at the repair")
	_fit(story)
	_ok(story.advance(), "the fitted chain reopens the room")
	for _step in 10:
		story.advance()
	_eq(story.stage, StoryState.STAGE_HANDOFF, "repeated advances stop at the handoff")
	_ok(story.is_complete(), "the handoff is the finished stage")
	_ok(not story.advance(), "advancing past the handoff is refused")

	# Every stage on the way through keeps the chain broken until the repair.
	var walk := StoryState.new()
	_walk(walk, StoryState.STAGE_CHAIN_SNAPPED)
	_fit(walk)
	_walk(walk, StoryState.STAGE_ROOM_REOPENED)
	_eq(walk.stage, StoryState.STAGE_ROOM_REOPENED, "the whole chain reaches the reopened room")
	_ok(not walk.chain_broken, "and the room is only reopened with the chain intact")
	end_case()


# ---------------------------------------------------------------- chain state

func _test_chain_state() -> void:
	begin_case("chain", "the shutter chain only repairs with one carried link")
	var story := StoryState.new()
	_ok(not story.chain_broken, "a fresh story has a whole chain")
	_ok(not story.fit_link(), "there is nothing to fit on a whole chain")

	story.advance_to(StoryState.STAGE_BANGING)
	_ok(story.chain_broken, "the banging snaps it")
	_ok(not story.fit_link(), "a snapped chain cannot be fitted without a link")
	_ok(story.chain_broken, "and stays snapped")

	story.links = 1
	_ok(story.fit_link(), "one carried link repairs the chain")
	_ok(not story.chain_broken, "the lever works again")
	_eq(story.links, 0, "the fitted link is spent")
	_ok(not story.fit_link(), "and a second fit is refused")

	# The farm carries the same machine, so the room and the save cannot disagree.
	var survivor: FarmState = _state()
	var carried := StoryState.new()
	_walk(carried, StoryState.STAGE_CHAIN_SNAPPED)
	carried.links = 2
	survivor.story = carried
	_ok(survivor.story.fit_link(), "the farm's story fits a link the same way")
	_eq(survivor.story.links, 1, "leaving the spare in the pack")
	end_case()


# ------------------------------------------------------------------ guidance

func _test_guidance_lines() -> void:
	begin_case("guidance", "every stage has one readable line and a name")
	var story := StoryState.new()
	var seen: Dictionary = {}
	for stage in StoryState.STAGE_COUNT:
		story.stage = stage
		var line: String = story.guidance()
		var label: String = story.stage_name()
		_ok(StoryState.STAGE_LINES.has(stage), "stage %d has a line entry" % stage)
		_ok(not label.is_empty() and label != "unknown", "stage %d has a name" % stage)
		if stage != StoryState.STAGE_DORMANT:
			_ok(not line.is_empty(), "stage %d carries a line" % stage)
			_ok(not seen.has(line), "stage %d's line is not a duplicate" % stage)
			seen[line] = true
	_ok(story.guidance().begins_with("THE FARM IS YOURS"), "the handoff line names what is open", story.guidance())
	_eq(StoryState.STAGE_LINES[StoryState.STAGE_DORMANT], "", "the dormant stage shows nothing")
	end_case()


# ---------------------------------------------------------------- save shape

func _test_save_v10() -> void:
	begin_case("save", "current schema stores the story and round-trips it")
	var survivor: FarmState = _state()
	_walk(survivor.story, StoryState.STAGE_FIRST_WAVE)
	survivor.story.links = 1
	survivor.story.banging_done = true
	var saved: Dictionary = survivor.to_save()
	# C4 raised the schema to 11; the story block is unchanged by that bump.
	_eq(int(saved.get("version", 0)), FarmState.SAVE_VERSION, "the save declares the current schema")
	_ok(saved.get("story", null) is Dictionary, "the story is written as its own block")

	var restored := FarmState.new()
	_ok(restored.from_save(saved), "the current save schema loads")
	_eq(restored.story.stage, StoryState.STAGE_FIRST_WAVE, "the stage survives the save")
	_ok(restored.story.chain_broken, "the snapped chain survives the save")
	_eq(restored.story.links, 1, "a crafted link survives the save")
	_ok(restored.story.banging_done, "so does the fact that the pair already came")

	# A finished shift writes a finished story with nothing left broken.
	var done: FarmState = _state()
	_walk(done.story, StoryState.STAGE_CHAIN_SNAPPED)
	_fit(done.story)
	_walk(done.story, StoryState.STAGE_HANDOFF)
	var done_save: Dictionary = done.to_save()
	var done_load := FarmState.new()
	done_load.from_save(done_save)
	_eq(done_load.story.stage, StoryState.STAGE_HANDOFF, "a finished story loads finished")
	_ok(not done_load.story.chain_broken, "with no chain to repair")

	# The story is part of new_game, not a leftover from the previous shift.
	var fresh: FarmState = _state()
	_eq(fresh.story.stage, StoryState.STAGE_DORMANT, "a new shift starts at stage 0")
	_ok(not fresh.story.chain_broken and fresh.story.links == 0, "with a whole chain and no links")
	end_case()


func _test_legacy_save() -> void:
	begin_case("legacy", "a schema 9 save loads finished instead of being sent back through the opening")
	var survivor: FarmState = _state()
	survivor.parts = 9
	survivor.chitin = 4
	var saved: Dictionary = survivor.to_save()
	saved["version"] = 9
	saved.erase("story")

	var restored := FarmState.new()
	_ok(restored.from_save(saved), "a schema 9 save still loads")
	_eq(restored.story.stage, StoryState.STAGE_HANDOFF, "an existing farm resumes after the first night")
	_ok(not restored.story.chain_broken, "its shutter chain is intact")
	_ok(restored.story.banging_done, "and the scripted pair never arrives")
	_ok(restored.story.is_complete(), "the C2 loop owns it from the first frame")
	_eq(restored.parts, 9, "nothing in the old inventory is lost")
	_eq(restored.chitin, 4, "including chitin from before the story existed")
	end_case()
