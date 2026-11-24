extends "res://tools/tests/test_base.gd"

## LEVEL 2 — Phase C3 // the first night, beat by beat.
##
## Each case stages one beat of the opening in the real scene and proves the
## thing the player would see or hear. The scripted pair is spawned by the game's
## own story path, not by the suite; the suite only fast-forwards the three-second
## wait so the run stays inside the timing budget.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/workflow_c3_story.tscn


func _init() -> void:
	suite_name = "workflow_c3_story"
	suite_level = "workflow"
	timeout_seconds = 120.0


func run_phases() -> void:
	await _prepare_world()
	await _test_arming()
	await _test_banging()
	await _test_pair_holds_the_chamber()
	await _test_crank_stops_the_banging()
	await _test_first_wave()
	await _test_chain_fit()
	await _test_snare_and_handoff()
	await _test_new_buyer()
	await _test_logbook()
	await _test_rust_variant()
	await _test_rivet_upgrade()


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


func _chamber_pair() -> Array:
	var inside: Array = []
	for creature in game.burrowers:
		if not is_instance_valid(creature):
			continue
		var spot: Vector3 = creature.global_position
		if spot.x > 6.15 and spot.x < 9.85 and spot.z > -3.85 and spot.z < -0.15:
			inside.append(creature)
	return inside


func _line_is_story(text: String) -> bool:
	for line in game.STORY_BANG_LINES:
		if text == str(line):
			return true
	return false


# ----------------------------------------------------------------- the beats

func _test_arming() -> void:
	begin_case("arming", "the opening waits for a real new shift and a beat of quiet")
	game.new_shift(false)
	# new_shift(false) leaves the opening at the fire lesson, which is exactly
	# where a real player would be. The story only arms after the kit.
	game.opening_state = "complete"
	await _frames(3)
	_eq(game.farm.story.stage, StoryState.STAGE_DORMANT, "a suite shift starts dormant")
	_ok(not game.story_enabled, "and the story is not armed by new_shift(false)")

	game.begin_first_night_for_test(false)
	_eq(game.story_wait, game.STORY_BANG_DELAY, "arming waits three seconds before the first hit")
	await _frames(30)
	_eq(game.farm.story.stage, StoryState.STAGE_DORMANT, "nothing has happened yet")
	_eq(game.burrowers.size(), 0, "and the chamber is still empty")
	end_case()


func _test_banging() -> void:
	begin_case("banging", "two creatures arrive and work the sealed shutter")
	game.begin_first_night_for_test(true)
	await _frames(4)
	_eq(game.farm.story.stage, StoryState.STAGE_BANGING, "the beat moves the story to the banging")
	_ok(game.farm.story.chain_broken, "and snaps the shutter chain")
	_ok(game.farm.story.banging_done, "the pair is recorded as having come")
	_eq(game.burrowers.size(), 2, "two creatures reached the chamber")
	var inside: Array = _chamber_pair()
	_eq(inside.size(), 2, "both are inside the hunt chamber, behind the bulkhead")
	var scripted := true
	for creature in inside:
		if not is_zero_approx(creature.speed):
			scripted = false
	_ok(scripted, "they are held on the shutter errand, not running the hunt AI")
	_ok(not game.shutter_open and absf(game.shutter_body.position.y) < 0.10,
		"the outer shutter stays seated while they hit it")
	_ok(not game.hunt_bulkhead_open and absf(game.hunt_bulkhead_body.position.y) < 0.10,
		"and the bulkhead stays down, so they cannot reach the warm room")

	var bangs_before: int = game.story_bangs
	for _i in 150:
		await _frames(1)
		if game.story_bangs > bangs_before:
			break
	_eq(game.story_bangs, bangs_before + 1, "the pair strikes the shutter on its cadence")
	_ok(game.story_shudder > 0.0, "the shutter physically shudders on the hit")
	_ok(game.find_child("StoryShutterDust", true, false) != null, "and dust comes off the seam")
	_ok(_line_is_story(game.message_label.text), "the HUD carries one of the story lines", game.message_label.text)
	end_case()


func _test_pair_holds_the_chamber() -> void:
	begin_case("no_breach", "nothing in this beat can reach the warm room")
	# Stand right behind the bulkhead for a good while. If the scripted pair were
	# hunting instead of working the shutter, this is where they would arrive.
	game.player.global_position = Vector3(5.1, 0.9, -2.0)
	game.player.velocity = Vector3.ZERO
	await _frames(90)
	_eq(game.farm.story.stage, StoryState.STAGE_BANGING, "the beat is still running")
	_ok(not game.hunt_bulkhead_open and absf(game.hunt_bulkhead_body.position.y) < 0.10,
		"the bulkhead is still sealed")
	_eq(_chamber_pair().size(), 2, "both creatures are still on their side of it")
	_ok(game.player.global_position.x < 6.15, "the player never had to move")
	end_case()


func _test_crank_stops_the_banging() -> void:
	begin_case("crank_gate", "winding the bulkhead ends the banging without a free hit")
	game._on_bulkhead_cranked(true)
	await _frames(6)
	var bangs_before: int = game.story_bangs
	await _frames(90)
	_eq(game.story_bangs, bangs_before, "the pair stops working the shutter once the bulkhead is up")
	_ok(game.hunt_bulkhead_open, "the bulkhead is genuinely open")
	_eq(game.farm.story.stage, StoryState.STAGE_FIRST_WAVE, "cranking the bulkhead starts the first wave")
	_eq(game.burrowers.size(), 2, "both creatures are alive and waiting for it")
	end_case()


func _test_first_wave() -> void:
	begin_case("first_wave", "the pair engages one at a time and the blade clears the chamber")
	_eq(game.farm.story.stage, StoryState.STAGE_FIRST_WAVE, "cranking the bulkhead starts the first wave")
	await _frames(4)
	var moving := 0
	for creature in game.story_pair:
		if is_instance_valid(creature) and not is_zero_approx(creature.speed):
			moving += 1
	_eq(moving, 1, "only one creature is allowed to engage at a time")
	var first = game.story_pair[0]
	var second = game.story_pair[1]
	first.take_hit(2, "melee")
	await _frames(4)
	_ok(not burrowers_has(first), "the first creature dies to the blade")
	_ok(is_zero_approx(second.speed) == false, "the second is released once the first is down")
	second.take_hit(2, "melee")
	await _frames(4)
	_eq(game.farm.story.stage, StoryState.STAGE_CHAIN_SNAPPED, "killing both moves the story to the snapped chain")
	end_case()


func burrowers_has(creature) -> bool:
	return game.burrowers.has(creature)


func _test_chain_fit() -> void:
	begin_case("chain_fit", "a snapped chain refuses the crank until a crafted link is fitted")
	game.crank_cooldown = 0.0
	_ok(game.farm.story.chain_broken, "the chain is snapped after the first wave")
	game._crank()
	_ok(game.farm.story.chain_broken, "the crank refuses while the chain is snapped with no link")
	game.farm.parts = 2
	game.farm.chitin = 2
	var result: String = game.farm.craft_at_workbench("chain_link")
	_ok(game.farm.chain_links == 1, "the bench crafts one chain link (%s)" % result)
	game.crank_cooldown = 0.0
	game.player.global_position = Vector3(5.0, 0.0, -0.62)
	game.player.velocity = Vector3.ZERO
	_aim_player_at(game.shutter_lever.global_position)
	game._crank()
	for _i in 120:
		if not game.farm.story.chain_broken:
			break
		await _frames(1)
	_ok(not game.farm.story.chain_broken, "fitting the crafted link repairs the chain")
	_eq(game.farm.chain_links, 0, "the fitted link leaves the pack")
	end_case()


func _test_snare_and_handoff() -> void:
	begin_case("snare_handoff", "the fitted chain reopens the room, the snare proves the trap, a bolt hands the farm back")
	_eq(game.farm.story.stage, StoryState.STAGE_ROOM_REOPENED, "fitting the chain reopens the room")
	game.farm.snares = 1
	game.farm.snare_armed = false
	game._toggle_hunt_snare()
	_ok(game.farm.snare_armed, "the snare arms from the warm side")
	var creature = game.story_second_wave
	_ok(is_instance_valid(creature), "fitting the chain draws a second creature in")
	creature.global_position = game.HUNT_BAIT_SPOT
	game.try_trigger_hunt_snare(creature)
	_eq(game.farm.story.stage, StoryState.STAGE_TRAP_PROVEN, "a sprung snare proves the trap")
	game.farm.bolts = 1
	game.on_burrower_killed(creature, "standard", creature.global_position)
	_eq(game.farm.story.stage, StoryState.STAGE_HANDOFF, "a bolt kill after the snare hands the farm to stage 6")
	end_case()


func _test_new_buyer() -> void:
	begin_case("new_buyer", "THE RIVET is a buyer the farm's orders can name")
	_ok(FarmState.BUYERS.has("THE RIVET"), "THE RIVET is in the buyer list")
	end_case()


func _test_logbook() -> void:
	begin_case("logbook", "Mara's logbook line is set for the handoff")
	_ok(game.MARA_LOGBOOK_LINE.begins_with("MARA'S LOGBOOK"), "the logbook line is the Mara note")
	end_case()


func _test_rust_variant() -> void:
	begin_case("rust_variant", "the rust variant spawns with its own health and body scale")
	var creature = game._spawn_burrower(Vector3(2.0, 0.0, -10.0), false, game._rust_config())
	_eq(str(creature.variant), "rust", "the rust config sets the variant")
	_eq(int(creature.max_health), 4, "the rust variant has four health")
	_ok(is_equal_approx(float(creature.body_scale), 1.08), "the rust variant is scaled 1.08")
	end_case()


func _test_rivet_upgrade() -> void:
	begin_case("rivet_upgrade", "the rivet gun is a fifth upgrade axis that saves and loads")
	_ok(FarmState.AXES.has("rivets"), "rivets is an upgrade axis")
	game.farm.upgrades["rivets"] = 0
	game.farm.upgrades["rivets"] = 1
	var saved: Dictionary = game.farm.to_save()
	_eq(int(saved["upgrades"].get("rivets", -1)), 1, "the rivet tier is in the save")
	end_case()
