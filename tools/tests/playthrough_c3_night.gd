extends "res://tools/tests/test_base.gd"

## First night, played end to end through the game's own beats: arm, bang,
## wave, fit, snare, bolt, handoff. Reports each stage it reaches so a break
## shows where the night stops.

func _init() -> void:
	suite_name = "playthrough_c3_night"
	suite_level = "workflow"
	timeout_seconds = 150.0


func run_phases() -> void:
	await _prepare_world()
	await _play_night()


func _prepare_world() -> void:
	game.finish_opening_sequence_for_test()
	game.opening_state = ""
	game.player.is_hidden = false
	game.shutter_open = false
	game.hunt_bulkhead_open = false
	game._move_shutter(0.0)
	game._move_hunt_bulkhead(0.0)
	game._sync_levers_instant()
	await _frames(3)


## Waits, frame by frame, until the story reaches the stage or the cap runs out.
func _until_stage(stage: int, max_frames: int) -> void:
	for _i in max_frames:
		if game.farm.story.stage >= stage:
			return
		await _frames(1)


## Waits until the wave is cleared by state, not by frame count: every story
## creature is either dead or no longer in the burrower list.
func _until_wave_clear(max_frames: int) -> void:
	for _i in max_frames:
		var pending := false
		for creature in game.story_pair:
			if is_instance_valid(creature) and game.burrowers.has(creature):
				pending = true
		if not pending:
			return
		await _frames(1)


func _play_night() -> void:
	begin_case("night", "a new shift plays through to the handoff without a hand-set stage")
	game.new_shift(false)
	game.opening_state = "complete"
	await _frames(3)
	_eq(game.farm.story.stage, StoryState.STAGE_DORMANT, "the night starts dormant")

	game.begin_first_night_for_test(true)
	await _until_stage(StoryState.STAGE_BANGING, 120)
	print("PLAYTHROUGH stage after arming: %s" % game.farm.story.stage_name())
	_eq(game.farm.story.stage, StoryState.STAGE_BANGING, "the pair starts banging")
	_ok(game.farm.story.chain_broken, "the shutter chain snaps")

	game._on_bulkhead_cranked(true)
	await _until_stage(StoryState.STAGE_FIRST_WAVE, 60)
	print("PLAYTHROUGH stage after crank: %s" % game.farm.story.stage_name())
	_eq(game.farm.story.stage, StoryState.STAGE_FIRST_WAVE, "the crank starts the first wave")

	# Clear the wave the way the player does: the creatures come to the bait
	# and die to the blade. The suite stops them only to keep the run short.
	var kills := 0
	for i in 40:
		var alive: Array = []
		for creature in game.story_pair:
			if is_instance_valid(creature) and game.burrowers.has(creature):
				alive.append(creature)
		if alive.is_empty():
			break
		game.on_burrower_killed(alive[0], "melee", alive[0].global_position)
		game.burrowers.erase(alive[0])
		kills += 1
		await _until_wave_clear(10)
	await _until_stage(StoryState.STAGE_CHAIN_SNAPPED, 60)
	print("PLAYTHROUGH wave kills: %d, stage: %s" % [kills, game.farm.story.stage_name()])
	_eq(game.farm.story.stage, StoryState.STAGE_CHAIN_SNAPPED, "both dead, the chain is still snapped")

	game.crank_cooldown = 0.0
	game._crank()
	_ok(game.farm.story.chain_broken, "the crank refuses with no link carried")

	game.farm.parts = 2
	game.farm.chitin = 2
	game.farm.craft_at_workbench("chain_link")
	_eq(game.farm.chain_links, 1, "the bench makes a chain link")
	game.crank_cooldown = 0.0
	game.player.global_position = Vector3(5.0, 0.0, -0.62)
	game.player.velocity = Vector3.ZERO
	_aim_player_at(game.shutter_lever.global_position)
	game._crank()
	await _until_stage(StoryState.STAGE_ROOM_REOPENED, 120)
	print("PLAYTHROUGH stage after fit: %s" % game.farm.story.stage_name())
	_eq(game.farm.story.stage, StoryState.STAGE_ROOM_REOPENED, "the fit reopens the room")
	_ok(game.story_second_wave != null, "and draws the second creature in")

	game.farm.snares = 1
	game._toggle_hunt_snare()
	_ok(game.farm.snare_armed, "the snare arms from the warm side")
	var snared = game.story_second_wave
	snared.global_position = game.HUNT_BAIT_SPOT
	game.try_trigger_hunt_snare(snared)
	await _until_stage(StoryState.STAGE_TRAP_PROVEN, 60)
	print("PLAYTHROUGH stage after snare: %s" % game.farm.story.stage_name())
	_eq(game.farm.story.stage, StoryState.STAGE_TRAP_PROVEN, "the snare proves the trap")

	game.farm.bolts = 1
	game.on_burrower_killed(snared, "standard", snared.global_position)
	await _until_stage(StoryState.STAGE_HANDOFF, 60)
	print("PLAYTHROUGH stage after bolt: %s" % game.farm.story.stage_name())
	_eq(game.farm.story.stage, StoryState.STAGE_HANDOFF, "the bolt hands the farm back")
	_ok(game.farm.story.is_complete(), "the night is complete")
	end_case()
