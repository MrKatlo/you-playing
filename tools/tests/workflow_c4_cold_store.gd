extends "res://tools/tests/test_base.gd"

## LEVEL 2 — Phase C4 // the cold store behind the outer shutter.
##
## The room is proved the way a player proves it: walk through the doorway, put
## your back against the far wall, then press the three things that answer. The
## suite uses the real `player_interact()` and the real prompt labels.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/workflow_c4_cold_store.tscn


func _init() -> void:
	suite_name = "workflow_c4_cold_store"
	suite_level = "workflow"
	timeout_seconds = 120.0


func run_phases() -> void:
	await _prepare_world()
	await _test_threshold()
	await _test_room_is_furnished()
	await _test_walls_hold()
	await _test_jars()
	await _test_crate()
	await _test_frame()


func _prepare_world() -> void:
	game.finish_opening_sequence_for_test()
	game.opening_state = ""
	game.player.is_hidden = false
	# This phase is the room, not the first night. The story's own suite can arm
	# it; here it must stay asleep or the banging pair walks into the cases.
	game.story_enabled = false
	game.shutter_open = false
	game.hunt_bulkhead_open = false
	game._move_shutter(0.0)
	game._move_hunt_bulkhead(0.0)
	game.farm.patches = 0
	game.farm.meals = 1
	game.farm.cold_store_jars_searched.clear()
	game.farm.cold_store_crate_opened = false
	game.farm.cold_frame_installed = false
	game.farm.cold_frame_meal = false
	await _frames(3)


func _stand_at(eye: Vector3, look: Vector3) -> void:
	game.player.global_position = Vector3(eye.x, 0.9, eye.z)
	game.player.velocity = Vector3.ZERO
	_aim_player_at(look)
	await _frames(3)


func _walk_forward(frames: int) -> void:
	Input.action_press("move_forward")
	await _frames(frames)
	Input.action_release("move_forward")
	await _frames(2)


func _store_node(name_value: String) -> Node:
	for child in game.get_children():
		if child is Node and child.name == name_value:
			return child
	return null


# ------------------------------------------------------------------ the room

func _test_threshold() -> void:
	begin_case("threshold", "the corridor's south wall opens into the cold store")
	await _stand_at(Vector3(16.0, 0.9, -2.6), Vector3(16.0, 0.9, -6.25))
	await _walk_forward(55)
	var inside: Vector3 = game.player.global_position
	_ok(inside.z < -4.25, "the player walks through the doorway instead of into a wall", "z = %.2f" % inside.z)
	_ok(inside.z > -8.4, "and stops inside the room rather than leaving the basement", "z = %.2f" % inside.z)
	_ok(absf(inside.x - 16.0) < 1.6, "while staying inside the doorway's line", "x = %.2f" % inside.x)
	# Walk straight back out: the door has to work in both directions.
	_aim_player_at(Vector3(16.0, 0.9, -1.0))
	await _walk_forward(45)
	var back: Vector3 = game.player.global_position
	_ok(back.z > -3.7, "and walks back out into the cave corridor", "z = %.2f" % back.z)
	end_case()


func _test_room_is_furnished() -> void:
	begin_case("furniture", "the four generated props are real nodes in the room")
	for name_value in ["ColdStoreJarShelf", "ColdStoreColdFrame", "ColdStoreDrainGrate", "ColdStoreSealedCrate"]:
		_ok(_store_node(name_value) != null, "%s is instanced" % name_value)
	var kinds: Dictionary = {}
	for item in game.interactables:
		if item is Node and is_instance_valid(item):
			kinds[str((item as Node).get_meta("kind", ""))] = int(kinds.get(str((item as Node).get_meta("kind", "")), 0)) + 1
	_eq(int(kinds.get("cold_jar", 0)), FarmState.COLD_STORE_JAR_COUNT, "three intact jars answer")
	_eq(int(kinds.get("cold_crate", 0)), 1, "the crate answers")
	_eq(int(kinds.get("cold_frame", 0)), 1, "the frame answers")
	_eq(int(kinds.get("cold_drain", 0)), 0, "the drain does not: it is a hole, not a station")
	end_case()


func _test_walls_hold() -> void:
	begin_case("walls", "the store is a room, not a hole in the collision")
	await _stand_at(Vector3(16.0, 0.9, -6.0), Vector3(16.0, 0.9, -9.0))
	await _walk_forward(45)
	var south: Vector3 = game.player.global_position
	_ok(south.z > -8.55, "the far wall stops the player", "z = %.2f" % south.z)
	await _stand_at(Vector3(16.0, 0.9, -6.0), Vector3(11.0, 0.9, -6.0))
	await _walk_forward(35)
	var west: Vector3 = game.player.global_position
	_ok(west.x > 13.4, "the west wall holds", "x = %.2f" % west.x)
	await _stand_at(Vector3(16.0, 0.9, -6.0), Vector3(21.0, 0.9, -6.0))
	await _walk_forward(35)
	var east: Vector3 = game.player.global_position
	_ok(east.x < 18.6, "and so does the east wall", "x = %.2f" % east.x)
	end_case()


# ------------------------------------------------------------- the responses

func _test_jars() -> void:
	begin_case("jars", "each intact jar is a separate, single-use target")
	var parts_before: int = int(game.farm.parts)
	await _stand_at(Vector3(15.05, 0.9, -5.6), Vector3(14.16, 1.05, -5.6))
	_eq(game._short_interaction_label(game._nearest_interactable()), "SEARCH JAR", "the jar prompt names the action")
	game.player_interact()
	_eq(int(game.farm.parts), parts_before + 1, "searching the jar pays one part")
	_ok(game.message_label.text.begins_with("A jar of old stock"), "and the message says what was found")
	game.player_interact()
	_ok(game.message_label.text.begins_with("That jar is empty"), "the same jar refuses a second search")
	_eq(int(game.farm.parts), parts_before + 1, "and pays nothing more")
	# The middle jar is its own target, so three searches are three rewards.
	await _stand_at(Vector3(15.05, 0.9, -6.3), Vector3(14.16, 1.05, -6.3))
	game.player_interact()
	_eq(int(game.farm.parts), parts_before + 2, "the next jar pays separately")
	end_case()


func _test_crate() -> void:
	begin_case("crate", "the sealed crate opens once for parts and a gland")
	var parts_before: int = int(game.farm.parts)
	var glands_before: int = int(game.farm.heat_glands)
	await _stand_at(Vector3(17.30, 0.9, -7.25), Vector3(18.0, 0.45, -7.8))
	_eq(game._short_interaction_label(game._nearest_interactable()), "OPEN CRATE", "the crate prompt names the action")
	game.player_interact()
	_eq(int(game.farm.parts), parts_before + FarmState.COLD_STORE_CRATE_PARTS, "the crate holds two parts")
	_eq(int(game.farm.heat_glands), glands_before + FarmState.COLD_STORE_CRATE_GLANDS, "and one heat gland")
	game.player_interact()
	_ok(game.message_label.text.begins_with("The crate is already open"), "a second open finds an empty crate")
	_eq(int(game.farm.parts), parts_before + FarmState.COLD_STORE_CRATE_PARTS, "and no second payout")
	end_case()


func _test_frame() -> void:
	begin_case("frame", "the frame is fitted, filled and eaten through one prompt")
	await _stand_at(Vector3(16.0, 0.9, -6.75), Vector3(16.0, 0.35, -7.6))
	_eq(game._short_interaction_label(game._nearest_interactable()), "FIT PATCH", "a bare frame asks for a patch")
	game.farm.patches = 0
	game.player_interact()
	_ok(game.message_label.text.contains("needs an insulation patch"), "without a patch the frame refuses")
	_ok(not game.farm.cold_frame_installed, "and stays bare")
	game.farm.patches = 1
	game.player_interact()
	_ok(game.farm.cold_frame_installed, "spending a patch fits the frame")
	_eq(int(game.farm.patches), 0, "the patch is consumed")
	_eq(game._short_interaction_label(game._nearest_interactable()), "STORE MEAL", "a fitted empty frame offers storage")
	game.farm.meals = 1
	game.player_interact()
	_ok(game.farm.cold_frame_meal, "a cooked meal goes into the frame")
	_eq(int(game.farm.meals), 0, "and leaves the pack")
	_eq(game._short_interaction_label(game._nearest_interactable()), "EAT FROM FRAME", "a filled frame offers the meal")
	game.farm.hunger_hours = 3.0
	game.player_interact()
	_eq(game.farm.hunger_hours, FarmState.MEAL_HUNGER_HOURS * 2.0, "eating it is worth double hunger hours")
	_ok(not game.farm.cold_frame_meal, "and empties the frame")
	end_case()
