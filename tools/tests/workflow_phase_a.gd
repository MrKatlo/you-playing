extends "res://tools/tests/test_base.gd"

func _init() -> void:
	suite_name = "workflow_phase_a"
	suite_level = "workflow"


func run_phases() -> void:
	await _test_saved_pickups()
	await _test_fitting()
	await _test_controller()
	await _test_multiple_carcasses()


func _snapshot() -> Dictionary:
	return JSON.parse_string(JSON.stringify(game.farm.to_save())) as Dictionary


func _test_saved_pickups() -> void:
	begin_case("saved_pickups", "a link has one owner through repeated reloads")
	game.opening_state = ""
	game.farm.chain_links = 2
	game.player.set_link_carried(true)
	game.player.select_slot(game.player.SLOT_LINK)
	game.player.global_position = Vector3(0, 0.1, 0)
	game.player.rotation = Vector3.ZERO
	game.player.velocity = Vector3.ZERO
	await _frames(3)
	game._drop_held_chain_link()
	_eq(game.farm.chain_links, 1, "placing a real pickup spends one carried link")
	_eq(game.farm.world_items.size(), 1, "one physical item is recorded")
	_eq(game.world_pickup_views.size(), 1, "one matching model exists")
	var saved: Dictionary = _snapshot()
	_ok(game.restore_snapshot(saved), "JSON save restores through the production loading path")
	_ok(game.restore_snapshot(saved), "reloading the same snapshot is safe")
	_eq(game.world_pickup_views.size(), 1, "reload reconstructs one model, not two")
	var drop: Node3D = game.world_pickup_views.values()[0]
	game._pick_up_chain_link(drop)
	game._pick_up_chain_link(drop)
	_eq(game.farm.chain_links, 2, "a repeated pickup cannot duplicate the link")
	_eq(game.farm.world_items.size(), 0, "retrieval removes the saved world record")
	_ok(game.restore_snapshot(saved), "older snapshot replaces the current owners")
	_eq(game.farm.chain_links + game.farm.world_items.size(), 2, "load preserves the total number of links")
	var legacy: Dictionary = saved.duplicate(true)
	legacy["version"] = 12
	legacy.erase("world_items")
	legacy.erase("next_world_item_id")
	_ok(game.restore_snapshot(legacy), "version 12 saves still load")
	_eq(game.world_pickup_views.size(), 0, "old saves clear stale physical views")
	_eq(game.farm.chain_links, 1, "old saves retain their carried stock")
	game.farm.carry_remains("A")
	game.new_shift(false)
	_eq(game.farm.world_items.size(), 0, "new shifts clear physical items")
	_eq(game.farm.carried_remains.size(), 0, "new shifts clear carried remains")
	end_case()


func _stand_at_shutter() -> void:
	game.player.global_position = Vector3(5.0, 0.0, -0.62)
	game.player.velocity = Vector3.ZERO
	_aim_player_at(game.shutter_lever.global_position)
	await _frames(2)


func _test_fitting() -> void:
	begin_case("fitting", "fitting consumes exactly once after its animation succeeds")
	game.opening_state = ""
	game.farm.story.stage = StoryState.STAGE_CHAIN_SNAPPED
	game.farm.story.chain_broken = true
	game.farm.chain_links = 0
	game.farm.parts = 1
	game.farm.chitin = 1
	game.craft_workbench_recipe("chain_link")
	_eq(game.farm.chain_links, 1, "the existing recipe creates one link")
	_eq(game.farm.parts, 0, "the recipe consumes one mechanical part")
	_eq(game.farm.chitin, 0, "the recipe consumes one chitin")
	game.crank_cooldown = 0.0
	await _stand_at_shutter()
	game.player_interact()
	_ok(game.chain_install_elapsed >= 0.0, "using the broken lever starts the fitting action")
	_eq(game.farm.chain_links, 1, "starting the animation does not spend the item")
	await _frames(15)
	_ok(game.chain_install_prop != null and game.chain_install_prop.visible, "the replacement visibly travels to the socket")
	game.player.global_position = Vector3.ZERO
	await _frames(3)
	_eq(game.farm.chain_links, 1, "walking away returns the link without loss")
	_ok(game.farm.story.chain_broken, "cancelled repairs leave the chain broken")
	await _stand_at_shutter()
	game.player_interact()
	await _frames(10)
	var saved: Dictionary = _snapshot()
	game.restore_snapshot(saved)
	_ok(game.chain_install_elapsed < 0.0, "loading cancels the old animation")
	_eq(game.farm.chain_links, 1, "loading during a fit keeps the unconsumed link")
	game.opening_state = ""
	await _stand_at_shutter()
	game.player_interact()
	game.player_interact()
	for _i in 130:
		if not game.farm.story.chain_broken:
			break
		await _frames(1)
	_ok(not game.farm.story.chain_broken, "completed fitting repairs the chain")
	_eq(game.farm.chain_links, 0, "one successful fitting consumes one link")
	_eq(game.farm.story.stage, StoryState.STAGE_ROOM_REOPENED, "the original story moves forward one stage")
	_ok(game.shutter_lever._chain_whole.visible and not game.shutter_lever._chain_tell.visible, "the installed chain replaces its broken state")
	_ok(not game.farm.fit_shutter_chain(), "the repair cannot consume a second link")
	game.restore_snapshot(_snapshot())
	_ok(game.shutter_lever._chain_whole.visible, "the repaired appearance survives loading")
	end_case()


func _joy(button_index: int, pressed: bool) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	event.pressed = pressed
	Input.parse_input_event(event)


func _test_controller() -> void:
	begin_case("controller", "Xbox events operate movement, look, tools, the crank and menus")
	game.new_shift(false)
	game.opening_state = ""
	game.player.global_position = Vector3(0, 0.0, 0)
	game.player.rotation = Vector3.ZERO
	var start: Vector3 = game.player.global_position
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_LEFT_Y
	motion.axis_value = -1.0
	Input.parse_input_event(motion)
	await _frames(20)
	motion.axis_value = 0.0
	Input.parse_input_event(motion)
	_ok(game.player.global_position.distance_to(start) > 0.35, "left stick moves the real player")
	var yaw: float = game.player.rotation.y
	motion.axis = JOY_AXIS_RIGHT_X
	motion.axis_value = 0.8
	Input.parse_input_event(motion)
	await _frames(15)
	motion.axis_value = 0.0
	Input.parse_input_event(motion)
	_ok(absf(game.player.rotation.y - yaw) > 0.1, "right stick turns the real camera")
	game.farm.chain_links = 1
	game.player.set_link_carried(true)
	game.player.set_machete_equipped(true)
	game.player.select_slot(game.player.SLOT_MACHETE)
	_joy(JOY_BUTTON_Y, true)
	_joy(JOY_BUTTON_Y, false)
	await _frames(4)
	_eq(game.player.active_slot, game.player.SLOT_LINK, "Y cycles to an owned chain link")
	game.player.global_position = Vector3(5, 0, -3.30)
	game.player.velocity = Vector3.ZERO
	_aim_player_at(game.bulkhead_crank.global_position)
	await _frames(3)
	_joy(JOY_BUTTON_X, true)
	await _frames(20)
	_ok(game.bulkhead_crank.progress > 0.0 and not game.hunt_bulkhead_open, "X winds the crank without opening early")
	_eq(str(game.prompt_key_label.text), "X", "the prompt follows controller use")
	_joy(JOY_BUTTON_X, false)
	await _frames(25)
	_ok(game.bulkhead_crank.progress == 0.0, "letting go returns the wheel")
	_joy(JOY_BUTTON_X, true)
	for _i in 160:
		if game.hunt_bulkhead_open:
			break
		await _frames(1)
	_joy(JOY_BUTTON_X, false)
	_ok(game.hunt_bulkhead_open, "a full controller hold opens the bulkhead")
	game.menu.open_pause()
	await _frames(3)
	_ok(get_viewport().gui_get_focus_owner() is Button, "the menu gives controller navigation an initial focus")
	_joy(JOY_BUTTON_B, true)
	_joy(JOY_BUTTON_B, false)
	await _frames(3)
	_ok(not game.menu.visible and not get_tree().paused, "B closes the pause menu")
	game.player.using_gamepad = false
	end_case()


func _test_multiple_carcasses() -> void:
	begin_case("fair_loot", "five real kills produce five paid carcasses, including corridor kills")
	game.new_shift(false)
	game.opening_state = ""
	var before: Array = [game.farm.feed, game.farm.fuel, game.farm.chitin, game.farm.hides]
	for i in 5:
		var point := Vector3(7.0, 0.0, -2.0) if i < 3 else Vector3(14.0, 0.0, -2.0)
		var creature = game._spawn_burrower(point)
		creature.take_hit(100, "melee")
	for body in game.interactables.duplicate():
		if is_instance_valid(body) and str(body.get_meta("kind", "")) == "carcass":
			game._pick_up_carcass(body)
			game._pick_up_carcass(body)
	_eq(game.farm.carried_remains.size(), 5, "five bodies are carried, with duplicate pickup refused")
	game.restore_snapshot(_snapshot())
	_eq(game.farm.carried_remains.size(), 5, "all five bodies survive the production restore path")
	game._use_table()
	_ok(is_equal_approx(game.farm.feed - float(before[0]), 20.0), "five bodies pay 20 feed")
	_ok(is_equal_approx(game.farm.fuel - float(before[1]), 20.0), "five bodies pay 20 fuel")
	_eq(game.farm.chitin - int(before[2]), 10, "five bodies pay 10 chitin")
	_eq(game.farm.hides - int(before[3]), 5, "five bodies pay 5 hides")
	_eq(game.farm.carried_remains.size(), 0, "butchering empties the carried haul")
	game._use_table()
	_eq(game.farm.chitin - int(before[2]), 10, "using the empty table cannot pay again")
	end_case()
