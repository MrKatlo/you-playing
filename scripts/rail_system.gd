extends Node3D

const World := preload("res://scripts/rail_world.gd")
const Cart := preload("res://scripts/rail_cart.gd")
const Station := preload("res://scripts/rail_station.gd")
const Encounters := preload("res://scripts/rail_encounters.gd")
const Trading := preload("res://scripts/rail_trading.gd")
const Workshop := preload("res://scripts/rail_workshop.gd")
const Safety := preload("res://scripts/rail_safety.gd")
const CHECKPOINT := "user://basement_rail_checkpoint.json"
const SFX := {
	"scrape": preload("res://assets/audio/door_open.ogg"),
	"creak": preload("res://assets/audio/furnace_door_creak.ogg"),
	"water": preload("res://assets/audio/slime_slam.wav"),
	"stinger": preload("res://assets/audio/metal_hit.ogg"),
	"startup": preload("res://assets/audio/machine_start.ogg"),
}
var game
var world
var cart
var encounters
var stations: Array = []
var riding := false
var controls_enabled := true
var encounters_enabled := true
var previous_slot := 0
var previous_light := false
var ride_distance := 0.0
var departure_station := "corridor"
var last_announced := ""
var confirmed_stop := ""
var safety_startup := 0.0
var warning_left := 0.0
var motor_tick := 0.0
var world_ticks := 0.0
var ride_label: Label
var warning_label: Label
var durability_bar: ProgressBar
var hud: PanelContainer
var warning_player: AudioStreamPlayer
var motor_player: AudioStreamPlayer3D
var interactables: Array[Node3D] = []
var cart_target: Node3D

func _ready() -> void:
	name = "UndergroundRail"
	process_mode = Node.PROCESS_MODE_PAUSABLE
	world = World.new()
	add_child(world)
	world.build()
	cart = Cart.new()
	cart.name = "MiningCart"
	add_child(cart)
	cart.curve = world.curve
	var home = Station.new()
	home.distance = 2.0
	var pocket = Station.new()
	pocket.id = "pocket"
	pocket.distance = 44.0
	pocket.exit_position = Vector3(70, .05, -4.65)
	stations = [home, pocket]
	encounters = Encounters.new()
	encounters.rail = self
	add_child(encounters)
	encounters.rng.randomize()
	warning_player = AudioStreamPlayer.new()
	add_child(warning_player)
	motor_player = AudioStreamPlayer3D.new()
	motor_player.stream = SFX.startup
	motor_player.max_distance = 16
	motor_player.volume_db = -17
	cart.add_child(motor_player)
	_build_stations()
	_build_wildlife()
	_build_hud()
	reset(false)

func _build_stations() -> void:
	cart_target = target("rail_cart", "MINING CART — INSPECT / BOARD", Vector3.ZERO)
	target("rail_starter", "STARTER COUPLING / REPAIR PARTS", Vector3(25, .6, -4.45), "parts_cabinet")
	target("rail_emergency", "EMERGENCY PARTS", Vector3(26.5, .6, -4.45), "parts_cabinet")
	target("rail_safety", "TUNNEL SAFETY PANEL", Vector3(32, .65, -4.45), "parts_cabinet")
	for i in 3:
		var handle := target("rail_switch", ["LIGHTS SWITCH", "WARNINGS SWITCH", "MOTOR SWITCH"][i], Vector3(30.7 + float(i)*.65, 1.7, -4.08))
		handle.set_meta("index", i)
		World.box(handle, Vector3.ZERO, Vector3(.1, .28, .08), World.material(Color(.8, .38, .08)))
		world.switches.append(handle)
		World.box(world, handle.position + Vector3(0, 0, .055), Vector3(.44, .48, .08), World.material(Color(.13, .17, .17), .8, .6))
		var indicator := World.box(world, handle.position + Vector3(.13, .13, -.08), Vector3(.07, .07, .04), World.material(Color(.65, .12, .05))) as MeshInstance3D
		world.switch_indicators.append(indicator)
		world.add_sign(["LIGHTS", "WARNINGS", "MOTOR"][i], handle.position + Vector3(0, .34, -.12), PI, 15)
	target("rail_terminal", "INDUSTRIAL EXCHANGE", Vector3(66, .65, -4.4), "trading_terminal")
	target("rail_workshop", "POCKET WORKSHOP", Vector3(73.5, .65, -4.4), "workshop")
	target("rail_salvage", "WASHED-UP SALVAGE — SEARCH", Vector3(68, .35, -4.3))
	var salvage: Node3D = interactables.back()
	for i in 5:
		var scrap := World.box(salvage, Vector3(float(i)*.10-.2, -.10, 0), Vector3(.25, .15, .30), World.material(Color(.28, .18, .1)))
		scrap.rotation.y = i * .55
	for x in [29.5, 75.0]: target("rail_storage", "SHARED PARTS STORAGE", Vector3(x, .65, -4.45), "parts_cabinet")
	world.add_sign("RAIL  >\nC-4 PLATFORM", Vector3(22, 2.7, -3.78), 0, 25)
	world.add_sign("< EXCHANGE   WORKSHOP >", Vector3(70, 2.3, -4.15), PI, 24)

func target(kind: String, label: String, point: Vector3, model: String = "") -> Node3D:
	var node := Node3D.new()
	node.position = point
	node.set_meta("kind", kind)
	node.set_meta("label", label)
	node.set_meta("requires_look", true)
	node.set_meta("aim_3d", true)
	node.set_meta("aim_dot", .985 if kind == "rail_switch" else .94)
	add_child(node)
	if not model.is_empty():
		var path := "res://assets/models/basement/generated/props/salvaged_workbench.glb" if model == "workshop" else "res://assets/models/basement/generated/rail/%s.glb" % model
		var visual: Node3D = load(path).instantiate()
		if model == "workshop": visual.scale = Vector3(.65, .85, .62)
		if model == "parts_cabinet":
			# Shallow wall cabinets leave a capsule-width route around the bend.
			node.position.z = -4.14
			visual.scale.z = .5
		visual.position.y = -point.y
		visual.rotation.y = 0
		node.add_child(visual)
		World.box(node, Vector3(0, .02, -.04 if model == "parts_cabinet" else 0), Vector3(.95, 1.3, .5 if model == "parts_cabinet" else .65), World.material(Color(.15, .18, .19)), true).visible = false
	game.interactables.append(node)
	interactables.append(node)
	return node

func _build_wildlife() -> void:
	# Existing small creatures occupy the track margin, out of the running lane.
	# Their original patrol/listening animation is reused. Cart combat remains
	# the warned Echo Hunter encounter, so these cannot cause an untelegraphed bite.
	var scavenger := EchoScavenger.new()
	scavenger.player = game.player
	add_child(scavenger)
	scavenger.configure([Vector3(58, 0, -20.7), Vector3(62, 0, -20.7)])
	scavenger.set_active(true)
	var rat := TunnelRat.new()
	rat.player = game.player
	add_child(rat)
	rat.position = Vector3(71.8, 0, -4.3)

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 3
	add_child(layer)
	hud = PanelContainer.new()
	hud.position = Vector2(360, 566)
	hud.size = Vector2(560, 126)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.025, .035, .038, .94)
	style.border_color = Color(.78, .47, .15)
	style.set_border_width_all(2)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	hud.add_theme_stylebox_override("panel", style)
	layer.add_child(hud)
	var stack := VBoxContainer.new()
	hud.add_child(stack)
	ride_label = Label.new()
	ride_label.add_theme_font_size_override("font_size", 15)
	stack.add_child(ride_label)
	durability_bar = ProgressBar.new()
	durability_bar.custom_minimum_size = Vector2(0, 12)
	durability_bar.show_percentage = false
	stack.add_child(durability_bar)
	warning_label = Label.new()
	warning_label.position = Vector2(265, 145)
	warning_label.size = Vector2(750, 80)
	warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	warning_label.add_theme_color_override("font_color", Color(1, .78, .40))
	warning_label.add_theme_color_override("font_outline_color", Color.BLACK)
	warning_label.add_theme_constant_override("outline_size", 8)
	layer.add_child(warning_label)

func reset(restore_player: bool) -> void:
	if riding: _release_player()
	riding = false
	cart.speed = 0
	cart.accelerating = false
	cart.headlight_on = false
	cart.lamp.visible = false
	motor_player.stop()
	confirmed_stop = ""
	last_announced = ""
	ride_distance = 0
	encounters.clear()
	var data: Dictionary = game.farm.rail.data
	if data.recovery_pending: game.farm.rail.ensure_recovery_parts(game.farm.parts)
	var station = stations[1] if data.last_safe_station == "pocket" else stations[0]
	cart.distance = station.distance
	cart.place()
	if restore_player and data.unlocked:
		game.player.global_position = station.exit_position
		game.player.velocity = Vector3.ZERO
	world.refresh(data)
	_update_visuals()

func station_here():
	for station in stations:
		if station.contains(cart.distance, world.curve.get_baked_length()): return station
	return null

func can_save() -> bool:
	return not riding or (cart.speed == 0.0 and station_here() != null)

func board() -> bool:
	var data: Dictionary = game.farm.rail.data
	if riding or data.repair_stage == 0 or data.cart_durability <= 0 or cart.speed != 0.0: return false
	if game.player.global_position.distance_to(cart.position) > 3.0: return false
	previous_slot = game.player.active_slot
	previous_light = game.player.flashlight_on
	game.player.put_away_right_hand()
	game.player.set_flashlight_enabled(false)
	game.player.rail_riding = true
	game.player.set_cinematic_locked(true)
	riding = true
	departure_station = str(data.last_safe_station)
	confirmed_stop = departure_station
	encounters.begin_ride()
	checkpoint()
	warn("W accelerate · release W to coast · S brake · F headlight · E exit at a stopped platform", "startup")
	return true

func exit_cart() -> bool:
	var station = station_here()
	if not riding or station == null or cart.speed != 0.0:
		warn("STOP INSIDE A MARKED PLATFORM to get out. Mid-tunnel repairs: R while stopped.")
		return false
	_confirm_station(station)
	_release_player()
	riding = false
	game.player.global_position = station.exit_position
	encounters.clear()
	return true

func _release_player() -> void:
	game.player.rail_riding = false
	game.player.set_cinematic_locked(false)
	game.player.select_slot(previous_slot)
	game.player.set_flashlight_enabled(previous_light)
	game.player.head.rotation = Vector3.ZERO
	game.player.camera.rotation = Vector3.ZERO
	game.player.velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if game == null: return
	world_ticks += delta
	warning_left = maxf(0, warning_left - delta)
	safety_startup = maxf(0, safety_startup - delta)
	if warning_left == 0: warning_label.text = ""
	if riding:
		var throttle := controls_enabled and Input.is_action_pressed("move_forward")
		var brake := controls_enabled and (Input.is_action_pressed("move_back") or Input.is_action_pressed("jump"))
		advance(delta, throttle, brake)
	_update_visuals()

func advance(delta: float, throttle: bool, brake: bool) -> void:
	if not riding: return
	var before: float = cart.distance
	var data: Dictionary = game.farm.rail.data
	var travelled: float = cart.step(delta, throttle, brake, data.motor_upgraded, cart.distance > 23 and cart.distance < 33)
	ride_distance += travelled
	# Full-loop restocking uses passage across the home marker after the pocket
	# marker, independent of stops. Both flags survive an interrupted journey.
	if before < 44 and cart.distance >= 44: data.loop_half_complete = true
	var wrapped: bool = cart.distance < before
	if (before < 2 and cart.distance >= 2) or (wrapped and cart.distance >= 2):
		if data.loop_half_complete:
			game.farm.rail.complete_loop()
			checkpoint()
	if wrapped: encounters.new_pass()
	if encounters_enabled: encounters.tick(delta, cart.distance)
	if not riding: return
	var station = station_here()
	if station != null and cart.speed == 0:
		if confirmed_stop != station.id: _confirm_station(station)
	elif cart.speed > 0:
		confirmed_stop = ""
	for stop in stations:
		var remaining := fposmod(stop.distance - cart.distance, world.curve.get_baked_length())
		if remaining < 12 and remaining > 4 and last_announced != stop.id:
			last_announced = stop.id
			warn("PLATFORM AHEAD — brake with S. Missing it means another loop.", "stinger")
	game.player.global_position = cart.global_position + Vector3(0, .12, 0)
	game.player.rotation.y = cart.rotation.y
	game.player.head.rotation.x = -.08
	if not data.reduced_shake:
		game.player.camera.rotation.z = sin(world_ticks * 23) * .003 * cart.speed / 6.0
	else: game.player.camera.rotation.z = 0
	motor_tick -= delta
	if cart.speed > .2 and motor_tick <= 0:
		motor_tick = 1.6
		motor_player.volume_db = -19 if throttle else -31
		motor_player.pitch_scale = .65 + cart.speed * .055
		motor_player.play()
	elif cart.speed == 0: motor_player.stop()

func _confirm_station(station) -> void:
	confirmed_stop = station.id
	game.farm.rail.confirm_station(station.id)
	world.refresh(game.farm.rail.data)
	checkpoint()
	warn("%s PLATFORM — E to exit · R repair · W depart" % str(station.id).to_upper())

func handle_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"): game.toggle_pause_menu()
	elif event.is_action_pressed("interact"): exit_cart()
	elif event.is_action_pressed("flashlight"):
		cart.toggle_headlight()
	elif event.is_action_pressed("melee"):
		if cart.speed == 0:
			warn(Workshop.repair(game.farm))
			checkpoint()
		else: warn("STOP THE CART before repairing it.")

func interact(node: Node3D) -> void:
	var data: Dictionary = game.farm.rail.data
	var kind := str(node.get_meta("kind", ""))
	if not data.unlocked:
		if kind != "rail_cart" or not game.farm.rail.discover(game.farm.story.is_complete()):
			var next_task: String = game.farm.story.guidance()
			warn("NEXT: %s" % next_task if not next_task.is_empty() else "Finish the first-night repairs, then inspect the mining cart.")
			return
		warn("MOTOR COUPLING MISSING — the starter cabinet is beside the platform.")
		checkpoint()
		return
	match kind:
		"rail_cart":
			if data.repair_stage == 0:
				if not data.starter_taken: warn("TAKE THE STARTER COUPLING from the platform cabinet.")
				else:
					data.repair_stage = 1
					data.completed_repairs.append("cart")
					data.cart_durability = 100
					warn("CART REPAIRED — E to board. Brake manually at the pocket platform.", "startup")
			elif data.cart_durability <= 0:
				warn(Workshop.repair(game.farm))
			else: board()
		"rail_starter":
			if not data.starter_taken:
				data.starter_taken = true
				game.farm.parts += 3
				warn("STARTER COUPLING + 3 MECHANICAL PARTS — fit the coupling at the cart.")
			else: warn("STARTER CABINET EMPTY — coupling already collected.")
		"rail_emergency":
			if data.recovery_pending: game.farm.rail.ensure_recovery_parts(game.farm.parts)
			game.farm.parts += int(data.emergency_parts)
			warn("RECOVERED %d EMERGENCY PARTS" % int(data.emergency_parts))
			data.emergency_parts = 0
		"rail_terminal", "rail_workshop", "rail_storage", "rail_safety":
			game.menu.open_rail(kind)
		"rail_switch":
			if safety_startup > 0: warn("RELAYS STARTING — wait for the clunk.")
			elif Safety.activate(game.farm, int(node.get_meta("index"))):
				safety_startup = 1.4
				warn("RELAY %d ONLINE%s" % [int(node.get_meta("index")) + 1, " — MOTOR UPGRADED" if data.safety_restored else ""], "startup")
				var switch_index := int(node.get_meta("index"))
				world.refresh(data)
				world.switches[switch_index].rotation.z = .35
				for light in world.lights: light.light_energy = .12
				var tween := create_tween()
				tween.tween_property(world.switches[switch_index], "rotation:z", -.6, .55)
				for light in world.lights:
					tween.tween_property(light, "light_energy", 1.15 if data.safety_switches[0] else .4, .035)
			else: warn("FIT THE SAFETY KIT FIRST, or choose a switch still marked OFF.")
		"rail_salvage": warn(Trading.salvage(game.farm), "stinger")
	checkpoint()

func menu_action(action: String) -> String:
	var result := ""
	match action:
		"part", "stage2", "stage3": result = Trading.trade(game.farm, action)
		"workshop": result = Workshop.restore(game.farm)
		"repair":
			if not game.farm.rail.data.station_restored: return "RESTORE THE WORKSHOP before using its repair tools."
			var station = station_here()
			if cart.speed != 0 or station == null or station.id != "pocket": return "PARK THE CART at the pocket workshop first."
			result = Workshop.repair(game.farm, true)
		"deposit": result = Workshop.transfer(game.farm, true)
		"withdraw": result = Workshop.transfer(game.farm, false)
		"safety": result = Safety.install(game.farm)
	world.refresh(game.farm.rail.data)
	warn(result, "stinger")
	checkpoint()
	return result

func damage_cart(amount: int, message: String) -> void:
	game.farm.rail.data.cart_durability = maxi(0, int(game.farm.rail.data.cart_durability) - amount)
	warn(message, "stinger")
	if not game.farm.rail.data.reduced_shake: game.player.camera_recoil += Vector2(.035, .02)
	if game.farm.rail.data.cart_durability == 0: recover()
	checkpoint()

func recover() -> void:
	game.farm.rail.recover(game.farm.parts)
	game.farm.advance_minutes(3.0)
	reset(true)
	warn("CART BROKEN — recovered at C-4. Inventory kept. Take emergency parts, repair, and try again.", "creak")
	checkpoint()

func warn(message: String, sound: String = "") -> void:
	if game.farm.rail.data.subtitles:
		warning_label.text = message
		warning_left = 5.5
	if SFX.has(sound):
		warning_player.stream = SFX[sound]
		warning_player.volume_db = linear_to_db(maxf(.001, float(game.farm.rail.data.warning_volume))) - 6
		warning_player.play()
	# Actions always remain readable even with sound captions disabled.
	if sound.is_empty(): game.show_message(message, 3.0)

func _update_visuals() -> void:
	cart_target.position = cart.position + Vector3(0, .4, 0)
	var near: bool = game.player.global_position.distance_to(cart.position) < 6
	hud.visible = (riding or near) and not game.menu.visible
	if game.hotbar_name_label != null: game.hotbar_name_label.get_parent().visible = not hud.visible
	if game.inventory_label != null: game.inventory_label.get_parent().visible = not riding
	if not hud.visible: return
	var data: Dictionary = game.farm.rail.data
	var next := "POCKET" if cart.distance < 44 else "C-4 CORRIDOR"
	ride_label.text = "%s  →  %s   |   %.1f m/s   |   %d / 100\nW DRIVE   S BRAKE   F LAMP   R REPAIR   E EXIT" % ["MOTOR" if cart.accelerating else "COAST", next, cart.speed, int(data.cart_durability)] if riding else "MINING CART   |   %d / 100\n%s" % [int(data.cart_durability), "E INSPECT / BOARD  ·  STARTER PARTS BESIDE PLATFORM"]
	durability_bar.value = int(data.cart_durability)

func checkpoint(force: bool = false) -> void:
	# Automated tools instantiate the farm below their runner, so they never
	# write player saves. Only a production Basement scene owns checkpoints.
	if game.get_parent() != get_tree().root or (not force and not game.farm.rail.data.unlocked): return
	var result := write_checkpoint(CHECKPOINT, game.farm.to_save())
	if result != OK: push_warning("Could not replace the rail station checkpoint: %d" % result)

static func write_checkpoint(path: String, snapshot: Dictionary) -> Error:
	# Write then rename: an interrupted write must not truncate the last station.
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(snapshot))
	file.close()
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))

func objective() -> Dictionary:
	var state: Dictionary = game.farm.rail.data
	if not state.unlocked: return {"text": "INSPECT CART", "point": cart.position}
	if state.repair_stage == 0:
		return {"text": "FIT COUPLING" if state.starter_taken else "TAKE COUPLING", "point": cart.position if state.starter_taken else Vector3(25, .6, -4.45)}
	if not state.first_ride_completed: return {"text": "RIDE TO\nEXCHANGE", "point": cart.position}
	if not state.station_restored:
		return {"text": "RESTORE\nWORKSHOP" if game.farm.rail_stage2_kit else "TRADE FOR\nWORKSHOP KIT", "point": Vector3(73.5 if game.farm.rail_stage2_kit else 66, 1, -4.4)}
	if not state.safety_restored:
		var kit_ready: bool = game.farm.rail_stage3_kit or state.completed_repairs.has("safety_kit")
		return {"text": "RESTORE\nTUNNEL SAFETY" if kit_ready else "TRADE FOR\nSAFETY KIT", "point": Vector3(32 if kit_ready else 66, 1, -4.4)}
	return {"text": "RAIL ONLINE", "point": cart.position}
