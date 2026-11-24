extends "res://tools/tests/test_base.gd"

const Trading := preload("res://scripts/rail_trading.gd")
const Workshop := preload("res://scripts/rail_workshop.gd")
const Safety := preload("res://scripts/rail_safety.gd")
const Hunter := preload("res://scripts/echo_hunter.gd")
var rail

func _init() -> void:
	suite_name = "workflow_rail"
	suite_level = "workflow"
	timeout_seconds = 90

func run_phases() -> void:
	rail = game.rail
	rail.controls_enabled = false
	rail.encounters_enabled = false
	game.opening_state = "complete"
	game.finish_opening_sequence_for_test()
	await _persistence()
	await _journey()
	_economy()
	_safety_and_threats()
	await _live_hazards()
	await _recovery()
	await _geometry()
	await _physical_switches()

func _persistence() -> void:
	begin_case("migration", "version 11 migration and validated version 12 round trips")
	var old: Dictionary = farm.to_save()
	old.version = 11
	old.parts = 17
	old.story.stage = StoryState.STAGE_HANDOFF
	var loaded := FarmState.new()
	_ok(loaded.from_save(old), "version 11 loads")
	_eq(loaded.parts, 17, "migration preserves existing parts")
	_ok(loaded.story.is_complete(), "migration preserves story handoff")
	_ok(not loaded.rail.data.unlocked and loaded.rail.data.repair_stage == 0, "migration starts rail undiscovered")
	var saved: Dictionary = loaded.to_save()
	saved.rail_cart_durability = 140
	saved.rail_shared_parts = 50
	saved.rail_terminal_parts_stock = -4
	saved.rail_last_safe_station = "inside rock"
	saved.rail_safety_switches = [true]
	loaded.from_save(saved)
	_eq(int(loaded.rail.data.cart_durability), 100, "durability is clamped")
	_eq(int(loaded.rail.data.shared_parts), 25, "storage is clamped")
	_eq(int(loaded.rail.data.terminal_parts_stock), 0, "terminal stock is clamped")
	_eq(str(loaded.rail.data.last_safe_station), "corridor", "unknown station falls back safely")
	_eq(loaded.rail.data.safety_switches.size(), 3, "partial switch array is normalized")
	loaded.rail_stage2_kit = true
	loaded.rail_stage3_kit = true
	loaded.rail.data.cart_durability = 61
	var copy := FarmState.new()
	copy.from_save(JSON.parse_string(JSON.stringify(loaded.to_save())))
	_ok(copy.rail_stage2_kit and copy.rail_stage3_kit, "both protected kits survive JSON serialization")
	_eq(int(copy.rail.data.cart_durability), 61, "durability survives JSON round trip")
	_eq(int(copy.to_save().version), FarmState.SAVE_VERSION, "save uses the current schema")
	_ok(not copy.to_save().has("rail_speed") and not copy.to_save().has("rail_distance"), "no live ride is serialized")
	var checkpoint_path := "user://rail_qa_%d.json" % Time.get_ticks_usec()
	_eq(int(rail.write_checkpoint(checkpoint_path, copy.to_save())), int(OK), "station snapshot writes successfully")
	copy.rail.data.cart_durability = 36
	_eq(int(rail.write_checkpoint(checkpoint_path, copy.to_save())), int(OK), "atomic snapshot replacement works on this platform")
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(checkpoint_path))
	_eq(int(disk.rail_cart_durability), 36, "replacement snapshot retains latest damage")
	_ok(not FileAccess.file_exists(checkpoint_path + ".tmp"), "successful checkpoint leaves no partial write")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(checkpoint_path))
	end_case()

func _journey() -> void:
	begin_case("journey", "repair, board, manually stop, miss a station and return")
	var cart_target := _first_interactable("rail_cart")
	rail.interact(cart_target)
	_ok(not farm.rail.data.unlocked, "cart remains locked before story handoff")
	farm.story.stage = StoryState.STAGE_HANDOFF
	rail.interact(cart_target)
	_ok(farm.rail.data.unlocked, "inspection after handoff unlocks rail")
	farm.parts = 0
	rail.interact(_first_interactable("rail_starter"))
	rail.interact(cart_target)
	_ok(farm.rail.data.repair_stage == 1 and farm.rail.data.cart_durability == 100, "nearby starter cabinet repairs the cart without trading")
	_eq(farm.parts, 3, "starter pack leaves three portable repairs")
	player.global_position = rail.stations[0].exit_position
	_ok(rail.board(), "boarding works at the corridor platform")
	_ok(player.rail_riding and not player.can_move, "riding locks on-foot movement")
	var light_press := InputEventAction.new()
	light_press.action = "flashlight"
	light_press.pressed = true
	player._unhandled_input(light_press)
	_ok(rail.cart.headlight_on and rail.cart.lamp.visible, "F toggles the cart headlight")
	# Drive with the real input path for several physics frames.
	rail.controls_enabled = true
	Input.action_press("move_forward")
	await _frames(25)
	Input.action_release("move_forward")
	rail.controls_enabled = false
	_ok(rail.cart.speed > .5, "held W accelerates the actual cart")
	for i in 260: rail.advance(1.0/60.0, true, false)
	_ok(rail.station_here() == null and not rail.can_save(), "mid-tunnel manual saving is disabled")
	var pause := InputEventAction.new()
	pause.action = "pause"
	pause.pressed = true
	Input.parse_input_event(pause)
	await _frames(2)
	_ok(get_tree().paused and game.menu.visible, "Escape opens pause while riding")
	var paused_distance: float = rail.cart.distance
	await _frames(4)
	_ok(is_equal_approx(paused_distance, rail.cart.distance), "pause freezes cart movement")
	Input.parse_input_event(pause)
	await _frames(2)
	_ok(not get_tree().paused and not game.menu.visible, "Escape resumes the same ride")
	game.menu.close_menu()
	_ok(not rail.exit_cart() and rail.riding, "mid-tunnel exit is refused")
	var speed_before: float = rail.cart.speed
	rail.advance(.1, false, false)
	_ok(rail.cart.speed > 0 and rail.cart.speed < speed_before, "release W coasts without automatic braking")
	_stop_at(44)
	_ok(rail.station_here() != null and rail.station_here().id == "pocket", "manual braking stops inside the pocket platform")
	_ok(rail.cart.speed == 0 and rail.can_save(), "full station stop enables saving")
	var stopped: float = rail.cart.distance
	for i in 60: rail.advance(1.0/60.0, false, false)
	_ok(is_equal_approx(stopped, rail.cart.distance), "cart remains stationary until acceleration resumes")
	_ok(rail.exit_cart() and player.can_move, "E disembarks into the pocket platform")
	_ok(farm.rail.data.first_ride_completed and rail.world.gate.position.y > 4, "first arrival opens the pocket access gate")
	_eq(str(farm.rail.data.last_safe_station), "pocket", "confirmed station is the reload fallback")
	# With no brake input the home platform passes without stopping.
	_ok(rail.board(), "cart can be boarded again at the destination")
	for i in 2400:
		rail.advance(1.0/60.0, true, false)
		if farm.rail.data.loop_completion_count > 0 and rail.cart.distance > 8 and rail.cart.distance < 20: break
	_ok(farm.rail.data.loop_completion_count == 1, "complete two-leg loop is counted exactly once")
	_ok(rail.cart.speed > 0 and rail.station_here() == null, "missing home stop forces another loop")
	_stop_at(44)
	rail.exit_cart()
	rail.board()
	_stop_at(2)
	_ok(rail.station_here() != null and rail.station_here().id == "corridor" and rail.cart.speed == 0, "return leg can be manually stopped at the corridor")
	_ok(rail.exit_cart(), "home platform permits normal disembarking")
	rail.board()
	_stop_at(44)
	rail.exit_cart()
	end_case()

func _stop_at(destination: float) -> void:
	for i in 3000:
		var remaining := fposmod(destination - float(rail.cart.distance), rail.world.curve.get_baked_length())
		var braking_distance: float = rail.cart.speed * rail.cart.speed / (2.0 * rail.cart.performance(farm.rail.data.motor_upgraded).brake)
		var brake: bool = remaining < braking_distance + .6 or (remaining > rail.world.curve.get_baked_length() - 1)
		rail.advance(1.0/60.0, not brake, brake)
		if brake and rail.cart.speed == 0: return
	_ok(false, "cart reaches commanded manual stop within one loop")

func _economy() -> void:
	begin_case("economy", "terminal, protected kits, workshop and shared cabinets")
	farm.parts = 0
	Trading.salvage(farm)
	_ok(farm.parts >= 6 and farm.scrap_metal >= 10 and farm.batteries >= 2, "accessible pocket salvage can fund progression and return repairs")
	var scrap: int = farm.scrap_metal
	Trading.salvage(farm)
	_eq(farm.scrap_metal, scrap, "same salvage load cannot be claimed twice")
	Trading.trade(farm, "stage2")
	_ok(farm.rail_stage2_kit, "terminal works before workshop restoration")
	var after_purchase: int = farm.scrap_metal
	Trading.trade(farm, "stage2")
	_eq(farm.scrap_metal, after_purchase, "progression kit cannot be bought twice")
	Workshop.restore(farm)
	_ok(farm.rail.data.station_restored and not farm.rail_stage2_kit, "installing Stage 2 consumes the protected kit")
	farm.rail.data.cart_durability = 1
	var before: int = farm.parts
	rail.menu_action("repair")
	_ok(farm.rail.data.cart_durability == 100 and farm.parts == before - 1, "one workshop part repairs full durability")
	Workshop.transfer(farm, true)
	_eq(int(farm.rail.data.shared_parts), 1, "parts deposit into shared storage")
	Workshop.transfer(farm, false)
	_eq(int(farm.rail.data.shared_parts), 0, "withdrawal returns parts to carried inventory")
	farm.rail.data.shared_parts = 25
	before = farm.parts
	Workshop.transfer(farm, true)
	_eq(farm.parts, before, "full shared storage does not consume a part")
	farm.rail.data.shared_parts = 0
	Trading.trade(farm, "part")
	_eq(int(farm.rail.data.terminal_parts_stock), 9, "ordinary trade decrements terminal stock")
	Trading.trade(farm, "stage3")
	_ok(farm.rail_stage3_kit, "Stage 3 kit can be purchased with accessible resources")
	var stock := int(farm.rail.data.terminal_parts_stock)
	rail.reset(false)
	_eq(int(farm.rail.data.terminal_parts_stock), stock, "reset/load does not restock the terminal")
	end_case()

func _safety_and_threats() -> void:
	begin_case("safety", "independent switches, upgrade multipliers and fair encounter sensing")
	Safety.install(farm)
	_ok(not farm.rail_stage3_kit and farm.rail.data.completed_repairs.has("safety_kit"), "safety installation consumes its protected kit")
	_ok(Safety.activate(farm, 1), "warning switch activates independently")
	_ok(not farm.rail.data.safety_restored, "one switch cannot complete Stage 3")
	var copy := FarmState.new()
	copy.from_save(JSON.parse_string(JSON.stringify(farm.to_save())))
	_ok(copy.rail.data.safety_switches[1] and not copy.rail.data.safety_switches[0], "individual switch state persists")
	_ok(Safety.activate(farm, 0) and Safety.activate(farm, 2), "remaining switches complete independently")
	_ok(farm.rail.data.safety_restored and farm.rail.data.motor_upgraded, "third switch permanently unlocks upgraded motor")
	_ok(not Safety.activate(farm, 2), "switch cannot be rewarded twice")
	var base: Dictionary = rail.cart.performance(false)
	var upgrade: Dictionary = rail.cart.performance(true)
	_ok(is_equal_approx(upgrade.accel / base.accel, 1.25), "motor acceleration improves 25 percent")
	_ok(is_equal_approx(upgrade.max_speed / base.max_speed, 1.10), "motor top speed improves 10 percent")
	_ok(is_equal_approx(upgrade.brake / base.brake, 1.15), "motor braking improves 15 percent")
	_ok(upgrade.drag < base.drag, "upgraded motor coasts further")
	_ok(Hunter.hears_motor(9, true, true) and not Hunter.hears_motor(9, true, false), "upgrade carries the agreed acceleration-noise penalty")
	_ok(not Hunter.hears_motor(1, false, true), "quiet coasting does not alert a blind hunter")
	var listening_before := Hunter.hears_motor(5, false, false)
	rail.cart.toggle_headlight()
	_eq(Hunter.hears_motor(5, false, false), listening_before, "headlight does not affect detection")
	rail.encounters.begin_ride()
	_ok(rail.encounters.opportunities.size() >= 3 and rail.encounters.opportunities.size() <= 5, "new pass schedules three to five encounter opportunities")
	rail.encounters.scares = 2
	rail.encounters.new_pass()
	_eq(rail.encounters.scares, 2, "extra loop does not reset the scripted-scare cap")
	_ok(rail.world.flood != null, "flood remains present after safety restoration")
	rail.world.refresh(farm.rail.data)
	_ok(rail.world.station_lights[1].light_energy > 2, "restoring workshop restores station illumination")
	_ok(rail.world.hazard_lights[0].light_energy > 0, "warning switch powers physical hazard beacons")
	end_case()

func _live_hazards() -> void:
	begin_case("hazards", "real encounters respect coasting, warning time and stopped repairs")
	farm.rail.data.last_safe_station = "corridor"
	farm.rail.data.motor_upgraded = false
	farm.rail.data.safety_switches = [false, false, false]
	rail.encounters_enabled = true
	for loud in [false, true]:
		farm.rail.data.cart_durability = 100
		rail.reset(true)
		rail.encounters.rng.seed = 418
		rail.board()
		rail.encounters.collapse_active = false
		rail.cart.speed = 6
		for i in 500:
			rail.advance(1.0/60.0, loud, false)
			if rail.cart.distance > 23: break
		_eq(int(farm.rail.data.cart_durability), 75 if loud else 100, "accelerating near a warned Hunter costs exactly 25" if loud else "a whole quiet coast passes the Hunter without damage")
		if loud:
			_ok(rail.encounters.opportunities[0].warning_time >= 2.0, "actual Hunter strike allows at least two seconds after its warning")
		var unchanged := int(farm.rail.data.cart_durability)
		for i in 30: rail.encounters.tick(1.0/60.0, 23)
		_eq(int(farm.rail.data.cart_durability), unchanged, "finished encounter cannot hit repeatedly")
	for careful in [false, true]:
		farm.rail.data.cart_durability = 100
		rail.reset(true)
		rail.board()
		rail.encounters.clear()
		rail.encounters.collapse_active = true
		rail.cart.speed = 6
		for i in 1500:
			var brake: bool = careful and rail.encounters.collapse_warned and rail.cart.speed > 1.5
			rail.advance(1.0/60.0, not brake, brake)
			if rail.cart.distance > 15: break
		_eq(int(farm.rail.data.cart_durability), 100 if careful else 82, "braking and crawling avoids the active collapse" if careful else "ignoring a warned collapse damages the cart")
		_ok(rail.encounters.collapse_warning_time >= 1.4, "collapse grants a viable braking warning")
	while rail.cart.speed > 0: rail.advance(1.0/60.0, false, true)
	farm.rail.data.cart_durability = 55
	farm.parts = 2
	var repair := InputEventAction.new()
	repair.action = "melee"
	repair.pressed = true
	player._unhandled_input(repair)
	_ok(farm.rail.data.cart_durability == 95 and farm.parts == 1, "R repairs a fully stopped cart inside the tunnel by 40")
	_ok(not rail.exit_cart(), "repairing in the tunnel still does not allow exit")
	rail.cart.speed = 1
	player._unhandled_input(repair)
	_eq(farm.parts, 1, "repair input cannot spend parts while moving")
	rail.cart.speed = 1
	rail.cart.step(.1, true, false, false, false)
	var dry_speed: float = rail.cart.speed
	rail.cart.speed = 1
	rail.cart.step(.1, true, false, false, true)
	_ok(rail.cart.speed < dry_speed, "persistent water reduces actual acceleration")
	rail.encounters_enabled = false
	end_case()

func _recovery() -> void:
	begin_case("recovery", "breakdown preserves cargo and supplies repair capacity")
	var interrupted: Dictionary = farm.to_save()
	farm.from_save(JSON.parse_string(JSON.stringify(interrupted)))
	rail.reset(true)
	_ok(not rail.riding and rail.cart.speed == 0 and rail.station_here().id == "corridor", "loading an actual interrupted tunnel ride restores the last confirmed platform")
	_eq(int(farm.rail.data.cart_durability), 95, "interrupted ride keeps its repaired durability")
	farm.rail_stage2_kit = true
	farm.rail_stage3_kit = true
	farm.parts = 0
	farm.rail.data.shared_parts = 0
	farm.rail.data.emergency_parts = 0
	var clock_before: float = farm.abs_hour()
	rail.damage_cart(100, "TEST BREAKDOWN")
	_ok(farm.rail.data.cart_durability == 0 and farm.rail.data.last_safe_station == "corridor", "breakdown returns the broken cart to corridor")
	_ok(player.global_position.distance_to(rail.stations[0].exit_position) < .2, "player recovers on the safe platform")
	_ok(farm.rail_stage2_kit and farm.rail_stage3_kit, "capture retains protected kit inventory")
	_ok(farm.abs_hour() > clock_before, "recovery advances the shift clock")
	_eq(int(farm.rail.data.emergency_parts), 3, "empty pack receives enough emergency repair capacity")
	rail.interact(_first_interactable("rail_emergency"))
	for i in 3: Workshop.repair(farm)
	_eq(int(farm.rail.data.cart_durability), 100, "emergency repairs restore a broken cart fully")
	var snapshot: Dictionary = farm.to_save()
	farm.from_save(JSON.parse_string(JSON.stringify(snapshot)))
	rail.reset(true)
	_ok(not rail.riding and rail.cart.speed == 0 and rail.station_here().id == "corridor", "interrupted ride loads stopped at a stable station")
	end_case()

func _geometry() -> void:
	begin_case("geometry", "track, stations and old access remain physically usable")
	await _frames(3)
	var blocked := 0
	for index in 145:
		var a: Vector3 = rail.world.curve.sample_baked(float(index)) + Vector3(0, 1.2, 0)
		var b: Vector3 = rail.world.curve.sample_baked(float(index) + .5) + Vector3(0, 1.2, 0)
		var query := PhysicsRayQueryParameters3D.create(a, b)
		query.exclude = [player.get_rid()]
		if not game.get_world_3d().direct_space_state.intersect_ray(query).is_empty(): blocked += 1
	_eq(blocked, 0, "entire cart centerline is clear of world collision")
	var cold_query := PhysicsRayQueryParameters3D.create(Vector3(16, 1, -3), Vector3(16, 1, -5))
	cold_query.exclude = [player.get_rid()]
	_ok(game.get_world_3d().direct_space_state.intersect_ray(cold_query).is_empty(), "cold-store doorway remains unobstructed")
	var entrance_query := PhysicsRayQueryParameters3D.create(Vector3(22, 1, -3), Vector3(22, 1, -4.6))
	entrance_query.exclude = [player.get_rid()]
	_ok(game.get_world_3d().direct_space_state.intersect_ray(entrance_query).is_empty(), "new rail access doorway is physically open")
	player.global_position = Vector3(22, .05, -2.4)
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.head.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	Input.action_press("move_forward")
	await _frames(49)
	Input.action_release("move_forward")
	_ok(player.global_position.z < -4.8, "real player walks through the cave-to-rail doorway")
	player.rotation.y = -PI * .5
	Input.action_press("move_forward")
	await _frames(105)
	Input.action_release("move_forward")
	_ok(player.global_position.x > 27 and player.global_position.y > -.2, "real player follows the platform past cabinets to the cart", "position=%s" % player.global_position)
	for x in [66.0, 74.0]:
		var edge_query := PhysicsRayQueryParameters3D.create(Vector3(x, 1.6, -4.7), Vector3(x, 1.6, -3))
		edge_query.exclude = [player.get_rid()]
		_ok(not game.get_world_3d().direct_space_state.intersect_ray(edge_query).is_empty(), "pocket platform rear wall prevents a fall into the map gap")
	_ok(game.find_child("PocketCableSpool", true, false) != null, "existing pocket spool is preserved")
	game.menu.open_rail("rail_terminal")
	_ok(game.menu.visible and _tree_text_contains(game.menu, "EXCHANGE"), "terminal opens a usable industrial exchange screen")
	game.menu.close_menu()
	end_case()

func _physical_switches() -> void:
	begin_case("physical_switches", "all relay handles can be selected and used above their cabinet")
	game.opening_state = "complete"
	farm.rail.data.safety_switches = [false, false, false]
	farm.rail.data.safety_restored = false
	farm.rail.data.motor_upgraded = false
	farm.rail.data.repair_stage = 2
	for i in 3:
		var handle: Node3D = rail.world.switches[i]
		player.global_position = Vector3(handle.position.x, .05, -5.15)
		player.head.rotation = Vector3.ZERO
		player.camera.rotation = Vector3.ZERO
		await _aim_player_at(handle.global_position)
		_ok(game._nearest_interactable() == handle, "reticle selects relay %d instead of the cabinet" % (i+1))
		rail.safety_startup = 0
		var use := InputEventAction.new()
		use.action = "interact"
		use.pressed = true
		player._unhandled_input(use)
		_ok(farm.rail.data.safety_switches[i], "normal E input activates relay %d" % (i+1))
		player.camera.rotation = Vector3.ZERO
	await _frames(3)
	_ok(farm.rail.data.safety_restored, "three physical activations finish the upgrade")
	end_case()
