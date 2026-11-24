extends "res://tools/tests/test_base.gd"

## Building, doors and station interaction
##
## Real interaction with the physical world: the shift starts, the
## stations exist and answer the interact input, the cave threshold opens and
## closes under real collision, and the hunt chamber doorway is wide enough to
## walk through carrying the body the player actually has.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/workflow_interaction.tscn


func _init() -> void:
	suite_name = "workflow_interaction"
	suite_level = "workflow"


func run_phases() -> void:
	await _test_new_shift()
	await _test_stations()
	await _test_cave_access()
	await _test_player_input()
	await _test_hunt_doorway_clearance()
	await _test_burrower_and_shutter()

func _test_new_shift() -> void:
	game.farm.day = 7
	game.farm.feed = 0.0
	game.bolts = 0
	game.new_shift()
	# This suite is about the room and the wake tutorial. The C3 first night has
	# its own suite, so disarm it here rather than letting the banging pair spawn
	# three seconds into later cases.
	game.story_enabled = false
	await _frames(1)
	_ok(int(game.farm.day) == 1, "New Shift resets the day")
	_ok(is_equal_approx(float(game.farm.feed), 6.0), "New Shift restores starting feed")
	_ok(int(game.bolts) == 0, "New Shift starts with an empty bolt supply")
	_ok(_active_trays() == 1, "New Shift starts one live cricket tray")
	_ok(not game.farm.bedside_kit_opened and not game.player.flashlight_acquired and not game.player.machete_equipped and not game.player.riveter_equipped,
		"New Shift starts without the bedside kit's torch, machete, or bolt driver")
	_ok(is_equal_approx(float(game.farm.temperature), 15.0) and not game.farm.furnace_lit and is_equal_approx(float(game.farm.fuel), 3.0),
		"New Shift starts cold with enough fuel to tend the furnace")
	_ok(game.opening_state == "wake" and not game.player.can_move and not game.player.flashlight_on,
		"New Shift begins with a locked bed wake-up and flashlight off")
	game.finish_opening_sequence_for_test()
	await _frames(1)
	_ok(game.opening_state == "tend_fire" and game.player.can_move and game.player.head.position.y > 1.45,
		"wake-up releases into the first in-world furnace tutorial")
	var wake_start: Vector3 = game.player.global_position
	Input.action_press("move_forward")
	await _frames(10)
	Input.action_release("move_forward")
	var wake_walked: Vector3 = game.player.global_position - wake_start
	wake_walked.y = 0.0
	_ok(wake_walked.length() > 0.20, "wake-up position has a clear walkable route toward the furnace")


func _test_stations() -> void:
	var kinds: Dictionary = {}
	var furnace_body = null
	var stair_body = null
	for item in game.interactables:
		if item is Node and is_instance_valid(item):
			kinds[str((item as Node).get_meta("kind", ""))] = true
			if str((item as Node).get_meta("kind", "")) == "furnace":
				furnace_body = item
			if str((item as Node).get_meta("kind", "")) == "stair":
				stair_body = item
	var expected: Array[String] = [
		"furnace", "tray", "kit", "table", "bench", "workbench", "slate", "ledger", "stair",
		"bed", "eat", "shutter", "crank", "bait", "bulkhead", "gap",
		"snare", "cave_wheel", "cave_marker", "cave_cart", "thermal_regulator",
	]
	for kind in expected:
		_ok(bool(kinds.get(kind, false)), "station present: %s" % kind)
	_ok(furnace_body != null and furnace_body.get_node_or_null("MakeshiftFurnaceModel") != null, "Blender furnace model is attached to the real station")
	_ok(game.find_child("CultureTray_1", true, false) != null, "Blender culture tray model is present")
	_ok(game.get_node_or_null("FurnaceSmoke") != null, "furnace smoke effect is present")
	_ok(game.furnace_door != null and game.furnace_flame_core != null, "furnace has an animated door and visible fire core")
	_ok(game.tray_lids.size() == 6 and game.tray_lids[0] != null, "the working culture tray has a hinged top lid")
	_ok(game.tray_lids[1] == null, "the unfinished second tray has no lid yet")
	_ok(game.bedside_kit_body != null and game.bedside_kit_body.get_node_or_null("BedsideKitClosedModel") != null, "bedside kit has a closed authored model")
	# The footlocker must stand beside the cot, not in the walkway in front of it.
	var kit_offset: Vector3 = game.BEDSIDE_KIT_SPOT - game.BED_SPOT
	_ok(absf(kit_offset.x) > 0.9 and kit_offset.z > 0.5,
		"bedside kit stands beside the cot against the rear wall")
	# The two large props must not share floor space: kit 1.08 x 0.76, rack 1.71 x 0.59.
	var kit_rect := Rect2(game.BEDSIDE_KIT_SPOT.x - 0.54, game.BEDSIDE_KIT_SPOT.z - 0.38, 1.08, 0.76)
	var rack_rect := Rect2(game.STORAGE_RACK_SPOT.x - 0.86, game.STORAGE_RACK_SPOT.z - 0.30, 1.72, 0.60)
	_ok(not kit_rect.intersects(rack_rect), "bedside kit and warm storage rack keep separate footprints")
	game.farm.bedside_kit_opened = false
	game._use_bedside_kit()
	_ok(game.farm.bedside_kit_opened and game.player.flashlight_acquired and game.player.machete_equipped and game.player.riveter_equipped,
		"opening the bedside kit hands over the torch, machete, and bolt driver")
	_ok(int(game.farm.bolts) == 0, "the bolt driver arrives with no ammunition")
	_ok(game.bedside_kit_open_visual.visible, "the kit swaps to its open authored model")
	game._use_bedside_kit()
	_ok(not game.bedside_kit_open_visual.visible, "the kit lid can be posed shut again")
	game._use_bedside_kit()
	_ok(game.bedside_kit_open_visual.visible, "the kit lid can be posed open again")
	_ok(game.find_child("ButcherTableModel", true, false) != null, "butcher table has a detailed salvaged model")
	_ok(game.find_child("PackagingBenchModel", true, false) != null, "packaging bench has a detailed production model")
	_ok(game.find_child("SalvagedWorkbenchModel", true, false) != null, "workbench has a generated physical model")
	_ok(game.find_child("GeneratedWarmStorageRack", true, false) != null and not game.storage_rack_visual.visible,
		"safe room has a hidden generated storage-rack upgrade before it is crafted")
	_ok(game.find_child("GeneratedHuntSnare", true, false) != null and not game.hunt_snare_visual.visible,
		"hunt chamber has a hidden generated floor snare before it is armed")
	_ok(game.gap_patch_visuals.size() == 4 and not game.gap_patch_visuals[0].visible,
		"each leaking gap has a hidden physical repair visual at shift start")
	_ok(game.find_child("SalvagedCotModel", true, false) != null, "bed has a detailed cot model")
	_ok(game.find_child("HuntBulkheadModel", true, false) != null, "safe room has a rendered hunt bulkhead")
	_ok(game.hunt_bulkhead_body != null, "hunt bulkhead exposes a moving collision door")
	_ok(game.find_child("OuterHuntShutterModel", true, false) != null, "outer hunt entrance has a rendered rolling shutter")
	_ok(stair_body != null and str(stair_body.get_meta("label", "")).contains("LOCKED"),
		"upstairs stair door remains locked and separate from the cave route")
	_ok(game.find_child("FrozenMaintenancePortal_0", true, false) != null,
		"cave entrance uses a generated frozen-maintenance portal model")
	_ok(game.find_child("ColdJunctionCollapse", true, false) != null,
		"first cave pocket ends at a visible future-route collapse")
	_ok(game.find_child("FrozenMaintenanceCart", true, false) != null,
		"Cold Junction has a generated service-cart landmark instead of filler crates")
	_ok(game.find_child("GeneratedFurnaceHeatReclaimer", true, false) != null and not game.heat_reclaimer_visual.visible,
		"safe room has a hidden generated furnace retrofit before the cave find is fitted")
	_ok(game.tray_crickets.size() == 2,
		"the young colony shows a couple of live imported crickets, not four",
		str(game.tray_crickets.size()))
	_ok(game.house_gecko != null, "Riverborn gecko is present as a non-hostile pest hunter")


func _test_cave_access() -> void:
	_ok(game.cave_return_wheel != null and game.cave_marker != null and game.cave_cart != null and game.cave_regulator_pickup != null,
		"cave has a physical return wheel, route marker, cart, and recoverable regulator")
	# The same exterior shutter used for the hunt must be a real passage, not a
	# cosmetic gateway. Ray checks exercise its moving collision from both sides.
	game.shutter_open = false
	game._move_shutter(0.0)
	await _frames(60)
	var query := PhysicsRayQueryParameters3D.create(Vector3(10.8, 1.0, -2.0), Vector3(9.15, 1.0, -2.0))
	var closed_hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
	_ok(not closed_hit.is_empty(), "closed exterior shutter physically blocks the cave threshold")
	game._use_cave_return_wheel()
	await _frames(60)
	var open_hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(query)
	_ok(game.shutter_open and open_hit.is_empty(), "cave-side wheel opens a walkable return path through the real shutter")
	# Move the actual CharacterBody through the opening in both directions. This
	# catches a false-positive layout where a ray clears the door but a player is
	# still blocked by the floor, frame, or a misplaced portal model.
	game.player.global_position = Vector3(8.45, 0.9, -2.0)
	game.player.velocity = Vector3.ZERO
	await _aim_player_at(Vector3(13.20, 0.9, -2.0))
	Input.action_press("move_forward")
	await _frames(44)
	Input.action_release("move_forward")
	_ok(game.player.global_position.x > 10.55, "real first-person player can walk from hunt chamber into the cave")
	await _aim_player_at(Vector3(8.35, 0.9, -2.0))
	Input.action_press("move_forward")
	await _frames(44)
	Input.action_release("move_forward")
	_ok(game.player.global_position.x < 9.65, "real first-person player can walk back from cave to hunt chamber")
	game._read_cave_marker()
	_ok(game.message_label.text.contains("FURNACE RETURN ROUTE"), "cave marker explains the return rule without a HUD arrow")
	game.player.global_position = game.CAVE_REGULATOR_SPOT + Vector3(0.0, -0.10, -0.84)
	game.player.velocity = Vector3.ZERO
	_ok(game._nearest_interactable() == game.cave_regulator_pickup,
		"thermal regulator is the natural nearest interaction at the front of the service cart")
	game._recover_thermal_regulator()
	_ok(game.farm.thermal_regulators == 1 and not game.cave_regulator_pickup.visible,
		"Cold Junction service cart yields a recoverable heat component")
	game._inspect_cave_cart()
	_ok(game.message_label.text.contains("in your pack"), "service cart explains the component's home-bound purpose")
	game.crank_cooldown = 0.0
	game._crank()
	await _frames(60)
	_ok(not game.shutter_open, "safe-side crank can still reseal the hunt chamber after cave access")


func _test_player_input() -> void:
	game.player.global_position = Vector3(0.0, 0.9, 2.0)
	game.player.rotation.y = 0.0
	game.player.velocity = Vector3.ZERO
	# Standalone precondition: the wake-up has to be released into the first
	# furnace lesson, exactly as the new-shift step leaves it, or the furnace
	# ignores the interact input.
	if game.opening_state == "wake":
		game.finish_opening_sequence_for_test()
		await _frames(2)
	var start: Vector3 = game.player.global_position
	Input.action_press("move_forward")
	await _frames(12)
	Input.action_release("move_forward")
	var moved: Vector3 = game.player.global_position - start
	moved.y = 0.0
	_ok(moved.length() > 0.15, "move_forward input moves the real player")

	game.player.global_position = Vector3(-5.0, 0.9, -2.4)
	game.player.velocity = Vector3.ZERO
	# Two units, not one: igniting the very last unit snuffs the fire on the next
	# simulation tick, which is a real behaviour but not what this step is about.
	game.farm.fuel = 2.0
	game.farm.furnace_lit = false
	var interact := InputEventAction.new()
	interact.action = "interact"
	interact.pressed = true
	game.player._unhandled_input(interact)
	await _frames(4)
	_ok(bool(game.furnace_door_open), "first interaction opens the nearby furnace door")
	_ok(not bool(game.farm.furnace_lit), "opening the furnace does not ignite it by itself")
	game.player._unhandled_input(interact)
	await _frames(3)
	_ok(bool(game.farm.furnace_lit) and absf(float(game.farm.fuel) - 1.0) < 0.25,
		"second interaction feeds fuel and lights the furnace",
		"lit=%s fuel=%.2f" % [str(game.farm.furnace_lit), float(game.farm.fuel)])
	_ok(game.find_child("FurnaceFuelChunk", true, false) != null, "feeding the open furnace visibly throws a fuel chunk into it")
	_ok(game.opening_state == "kit", "the first fire hands the lesson over to the bedside kit")
	# Closing the furnace door must not be locked behind the kit lesson.
	game.player._unhandled_input(interact)
	await _frames(6)
	_ok(not game.furnace_door_open, "the furnace door can be closed before taking the kit")
	game.opening_state = "complete"

	game._use_tray(0)
	await _frames(4)
	var lid: Node3D = game.tray_lids[0] as Node3D
	_ok(lid != null and absf(lid.rotation.x) > deg_to_rad(10.0), "using a culture tray visibly lifts its top lid")

	game.set_hunt_bulkhead_for_test(true)
	await _frames(10)
	_ok(game.hunt_bulkhead_open and game.hunt_bulkhead_body.position.y > 0.10, "bulkhead control visibly opens the full hunt-room door")
	await _frames(50)
	game.set_hunt_bulkhead_for_test(false)
	await _frames(50)
	_ok(not game.hunt_bulkhead_open and absf(game.hunt_bulkhead_body.position.y) < 0.10, "bulkhead control seals the hunt room again")

	game.player.set_riveter_equipped(false)
	game.player.select_slot(game.player.SLOT_DRIVER)
	game.bolts = 2
	game.shot_cooldown = 0.0
	_ok(not game.player.riveter_equipped, "an unclaimed driver slot falls back to another tool")
	game.player.active_slot = game.player.SLOT_DRIVER
	game.player_fire()
	_ok(int(game.bolts) == 2, "the bolt driver cannot fire before the kit hands it over")
	game.player.set_riveter_equipped(true)
	game.player.select_slot(game.player.SLOT_DRIVER)
	# The blocked attempt above started a short dry-fire cooldown.
	game.shot_cooldown = 0.0
	game.bolts = 1
	var fire := InputEventAction.new()
	fire.action = "fire"
	fire.pressed = true
	game.player._unhandled_input(fire)
	_ok(int(game.bolts) == 0, "fire input spends a bolt through the player controller")


func _test_hunt_doorway_clearance() -> void:
	# The controls are visual interaction points, not collision obstacles. The
	# safe-to-hunt lane must remain wide enough for the real player capsule to
	# pass the inner bulkhead after it opens.
	var controls := ["crank", "bait", "bulkhead", "snare"]
	for kind in controls:
		var control = _first_interactable(kind)
		_ok(control is StaticBody3D and int((control as StaticBody3D).collision_layer) == 0,
			"hunt control is non-blocking: %s" % kind)
	game.player.global_position = Vector3(4.45, 0.9, -2.0)
	game.player.velocity = Vector3.ZERO
	if not game.hunt_bulkhead_open:
		game.set_hunt_bulkhead_for_test(true)
	await _frames(54)
	await _aim_player_at(Vector3(7.45, 0.9, -2.0))
	Input.action_press("move_forward")
	await _frames(52)
	Input.action_release("move_forward")
	_ok(game.player.global_position.x > 6.45,
		"real player crosses the opened hunt bulkhead without snagging on chute or controls")
	await _aim_player_at(Vector3(4.20, 0.9, -2.0))
	Input.action_press("move_forward")
	await _frames(52)
	Input.action_release("move_forward")
	_ok(game.player.global_position.x < 5.55, "real player can return through the cleared hunt doorway")
	if game.hunt_bulkhead_open:
		game.set_hunt_bulkhead_for_test(false)
	await _frames(48)


func _test_burrower_and_shutter() -> void:
	game.player.global_position = Vector3(4.5, 0.9, -0.2)
	game.player.velocity = Vector3.ZERO
	game.farm.snare_armed = false
	game.hunt_snare_sprung = false
	game._refresh_hunt_snare_visual()
	game.farm.snares = 1
	game._arm_hunt_snare()
	await _wait_lever(game.snare_lever)
	_ok(game.farm.snare_armed and game.hunt_snare_visual.visible,
		"safe-side snare control arms the generated hunt trap")
	game.farm.fuel = 2.0
	game._bait_hook()
	_ok(float(game.lure_left) > 0.0, "bait hook starts a lure window")
	game._crank()
	await _frames(3)
	_ok(bool(game.shutter_open), "crank opens the outer hunt shutter")
	_ok(game.burrowers.size() == 1, "baited outer shutter draws in one hunt slime")

	var creature = game.burrowers[0]
	_ok(creature is Burrower and bool(creature.lure_active), "spawned prey is a lure-driven hunt slime")
	_ok(int(creature.health) == 2, "hunt slime starts with two health")
	# C2.12 // the bait draws a red animal. The painted body replaces the green
	# authored material instead of multiplying into mud.
	_ok(bool(creature.body_paint), "the shutter lure is a painted variant")
	var painted_red := false
	for node in creature.visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var material := mesh_instance.get_surface_override_material(0) as StandardMaterial3D
		if material != null and material.albedo_color.r > material.albedo_color.g * 2.0:
			painted_red = true
			break
	_ok(painted_red, "the lure's body material is red, not green")
	creature.global_position = game.HUNT_BAIT_SPOT
	await _frames(2)
	_ok(not game.farm.snare_armed and game.hunt_snare_sprung and float(creature.tether_left) > 5.0,
		"bait-side floor snare catches the drawn slime and pins it")
	game.crank_cooldown = 0.0
	await _wait_lever(game.shutter_lever)
	game._crank()
	await _frames(3)
	_ok(not bool(game.shutter_open), "outer shutter closes to contain the slime in the hunt room")
	creature.take_hit(1, "melee")
	_ok(int(creature.health) == 1, "first melee hit damages the hunt slime")
	creature.take_hit(1, "melee")
	await _frames(2)
	_ok(game.burrowers.is_empty(), "second melee hit kills the hunt slime")
	_ok(_has_interactable("carcass"), "slime death leaves a lootable remains pickup")
	_ok(game.find_child("SlimeGuts", true, false) != null, "slime death spreads guts across the floor")
