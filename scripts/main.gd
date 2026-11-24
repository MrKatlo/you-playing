extends Node3D

const PlayerScript = preload("res://scripts/player.gd")
const MimicScript = preload("res://scripts/mimic.gd")
const HorrorAudioScript = preload("res://scripts/horror_audio.gd")
const ScavengerScript = preload("res://scripts/scavenger.gd")
const EchoScavengerScript = preload("res://scripts/echo_scavenger.gd")
const RpgProgressionScript = preload("res://scripts/rpg_progression.gd")
const GameMenuScript = preload("res://scripts/game_menu.gd")
const DOOR_OPEN_SFX := preload("res://assets/audio/door_open.ogg")
const MACHINE_START_SFX := preload("res://assets/audio/machine_start.ogg")
const ELEVATOR_SFX := preload("res://assets/audio/elevator.ogg")
const METAL_HIT_SFX := preload("res://assets/audio/metal_hit.ogg")
const FLOOR_TEXTURE := preload("res://assets/textures/station_floor_concrete.png")
const WALL_BAY_SCENE := preload("res://assets/models/station/station_wall_bay.glb")
const GRILL_GATE_SCENE := preload("res://assets/models/station/security_grill_gate.glb")
const CEILING_BAY_SCENE := preload("res://assets/models/station/ceiling_worklight_bay.glb")
const CONTROL_CONSOLE_SCENE := preload("res://assets/models/station/industrial_control_console.glb")
const PUMP_ASSEMBLY_SCENE := preload("res://assets/models/station/pump_assembly.glb")
const LOCKER_BANK_SCENE := preload("res://assets/models/station/locker_bank.glb")
const PIPE_RACK_SCENE := preload("res://assets/models/station/service_pipe_rack.glb")
const FREIGHT_SHUTTER_SCENE := preload("res://assets/models/station/freight_elevator_shutter.glb")
const SAVE_PATH := "user://last_signal_save.json"
const RIVETER_RANGE := 18.0
const RIVETER_DAMAGE := 1
const RIVETER_COOLDOWN := 0.85
const MAX_IMPACT_DECALS := 96
const MAX_ICHOR_POOLS := 28

var player: SignalRunner
var mimic: Mimic
var horror_audio: HorrorAudio
var sfx_player: AudioStreamPlayer
var game_menu: GameMenu
var world_environment: Environment
var rpg := RpgProgressionScript.new()
var master_volume_db := -5.0
var brightness := 1.0
var inventory := {"scrap": 0, "wire": 0, "fuse": 0, "cell": 0, "battery": 0, "lure": 0, "keycard": 0, "snack": 0, "arc_charge": 0, "rivet_gun": 0, "rivet_rounds": 0}
var stage := 0
var interactables: Array[Node3D] = []
var gates: Dictionary = {}
var objective_nodes: Dictionary = {}
var checkpoint := Vector3(0, 0.9, 2.5)
var scare_flags := {}
var caught_cooldown := false
var nix: TunnelRat
var echo_scavengers: Array[EchoScavenger] = []
var collected_pickups: Array[String] = []
var read_logs: Array[String] = []
var active_hide_spot: Node3D
var ending_choice := ""
var riveter_player: AudioStreamPlayer
var shot_stream: AudioStreamWAV
var dry_stream: AudioStreamWAV
var impact_stream: AudioStreamWAV
var impact_root: Node3D
var decal_material: StandardMaterial3D
var spark_material: StandardMaterial3D
var ichor_material: StandardMaterial3D
var impact_decals: Array[MeshInstance3D] = []
var ichor_pools: Array[Node3D] = []
var loot_counter := 0

var objective_label: Label
var tracker_label: Label
var inventory_label: Label
var prompt_label: Label
var message_label: Label
var vignette: ColorRect
var crosshair: Label
var objective_marker: Node3D
var rpg_label: Label

func _ready() -> void:
	_build_world_environment()
	_build_station()
	_build_ui()
	horror_audio = HorrorAudioScript.new()
	add_child(horror_audio)
	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -5.0
	add_child(sfx_player)
	_build_combat_feedback()
	player = PlayerScript.new()
	# The node must be in the tree before global_position is meaningful; setting it
	# first raised "!is_inside_tree()" and silently kept the player at the origin.
	add_child(player)
	player.global_position = checkpoint
	if nix != null:
		nix.player = player
	for scavenger in echo_scavengers:
		scavenger.player = player
		scavenger.game = self
	mimic = MimicScript.new()
	add_child(mimic)
	_build_objective_marker()
	game_menu = GameMenuScript.new()
	game_menu.game = self
	add_child(game_menu)
	game_menu.open_title()
	show_message("ASTER STATION // ECHO LOCK OFFLINE", 3.0)
	show_message("MARA VENN AUTHORIZATION REQUIRED. Find your maintenance keycard.", 4.0)

func _process(delta: float) -> void:
	_update_hud()
	_update_objective_tracker()
	_update_tension()
	_check_scares()
	if vignette.color.a > 0.0:
		vignette.color.a = maxf(0.0, vignette.color.a - delta * 0.82)

func _build_world_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.003, 0.006, 0.012)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.08, 0.11, 0.16)
	environment.ambient_light_energy = 0.28
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = true
	environment.glow_intensity = 0.7
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.04, 0.07, 0.10)
	environment.fog_density = 0.015
	world_environment = environment
	var world_env := WorldEnvironment.new()
	world_env.environment = environment
	add_child(world_env)

func _build_station() -> void:
	var floor_mat := _floor_material()
	var wall_mat := _material(Color(0.18, 0.22, 0.25), 0.78, 0.05)
	var rust_mat := _material(Color(0.24, 0.12, 0.08), 0.9, 0.0)
	var entry := Vector3(0, 0, 0)
	_build_room(entry, Vector2(14, 12), floor_mat, wall_mat, true, false)
	_build_corridor(Vector3(0, 0, -9), 6.0, floor_mat, wall_mat)
	_build_room(Vector3(0, 0, -18), Vector2(14, 12), floor_mat, wall_mat, true, true)
	_build_corridor(Vector3(0, 0, -27), 6.0, floor_mat, wall_mat)
	_build_room(Vector3(0, 0, -36), Vector2(14, 12), floor_mat, wall_mat, true, true)
	_build_corridor(Vector3(0, 0, -45), 6.0, floor_mat, wall_mat)
	_build_room(Vector3(0, 0, -54), Vector2(14, 12), floor_mat, wall_mat, true, true)
	_build_corridor(Vector3(0, 0, -63), 6.0, floor_mat, wall_mat)
	_build_room(Vector3(0, 0, -72), Vector2(14, 12), floor_mat, wall_mat, false, true)

	_add_light(Vector3(-3.5, 3.0, 2.0), Color(0.62, 0.77, 1.0), 5.0, 12.0)
	_add_light(Vector3(3.0, 3.0, -17.0), Color(0.64, 0.79, 1.0), 4.0, 11.0)
	_add_light(Vector3(-3.5, 2.8, -35.0), Color(0.95, 0.11, 0.05), 3.0, 10.0)
	_add_light(Vector3(3.0, 2.8, -53.0), Color(0.70, 0.12, 0.05), 3.0, 9.0)
	_add_light(Vector3(0, 3.4, -72.0), Color(0.78, 0.84, 1.0), 6.0, 14.0)

	_add_console(Vector3(-3.4, 0.0, -2.5), "SOREN'S VOICE LOG", "log", "Mara—if you are hearing this, the Echo Lock opened again. Your acoustic authorization can restart the ridge beacon. Do not answer anything that sounds like me.")
	_add_pickup(Vector3(3.2, 0.42, -3.5), "keycard", "MAINTENANCE KEYCARD", "keycard")
	_add_pickup(Vector3(-4.6, 0.42, -3.5), "rivet_gun", "MAINTENANCE RIVETER", "rivet_gun")
	_add_pickup(Vector3(-0.8, 0.42, 3.4), "rivet_rounds", "RIVET ROUND CASE", "entry_rounds", 8)
	_add_pickup(Vector3(-3.2, 0.42, 2.0), "scrap", "METAL SCRAP", "entry_scrap")
	_add_pickup(Vector3(0.0, 0.42, -3.0), "snack", "SEALED PROTEIN SNACK")
	_add_console(Vector3(0, 0.0, -7.2), "OPERATIONS BLAST DOOR", "blast_door", "A maintenance keycard is required to enter operations.")
	_make_gate("ops_gate", Vector3(0, 1.5, -9.0), Vector3(4.2, 3.2, 0.45), rust_mat)

	_add_pickup(Vector3(-2.4, 0.42, -18.7), "wire", "INSULATED WIRE", "ops_wire")
	_add_pickup(Vector3(3.8, 0.42, -20.5), "fuse", "CERAMIC FUSE", "ops_fuse")
	_add_console(Vector3(-4.4, 0.0, -21.2), "ECHO LOCK ARCHIVE", "log", "PROJECT ECHO // Venn's voiceprint was used to calibrate a living cave surveyor. It began repeating staff recordings after each acoustic test.")
	_add_console(Vector3(0, 0.0, -15.0), "EMERGENCY GENERATOR", "generator", "A bypass will wake the Echo Lock network—and the things that learned to use its speakers.")
	_add_console(Vector3(3.8, 0.0, -22.0), "FREIGHT ELEVATOR", "elevator", "The lift is dark. Restore generator power first.")
	_make_gate("pump_gate", Vector3(0, 1.5, -27.0), Vector3(4.2, 3.2, 0.45), rust_mat, FREIGHT_SHUTTER_SCENE)

	_add_pickup(Vector3(3.2, 0.42, -34.0), "cell", "POWER CELL", "cell")
	_add_console(Vector3(4.5, 0.0, -39.5), "INCIDENT RECORD", "log", "R-9 is nearly blind. It localizes movement with throat pulses and follows vibration through the pipework. Do not run when it scans.")
	_add_console(Vector3(-2.8, 0.0, -37.5), "PUMP CONTROL", "pump", "Drain the flooded test shaft. The Resonant escaped through these tunnels five years ago.")
	_make_gate("medical_gate", Vector3(0, 1.5, -45.0), Vector3(4.2, 3.2, 0.45), rust_mat)

	_add_pickup(Vector3(-3.0, 0.42, -52.0), "scrap", "METAL SCRAP", "medical_scrap")
	_add_pickup(Vector3(3.2, 0.42, -55.0), "wire", "INSULATED WIRE", "medical_wire")
	_add_pickup(Vector3(0.0, 0.42, -57.0), "battery", "BEACON BATTERY", "battery")
	_add_pickup(Vector3(4.6, 0.42, -59.6), "rivet_rounds", "RIVET ROUND CASE", "medical_rounds", 6)
	_add_pickup(Vector3(4.7, 0.42, -48.8), "arc_charge", "ARC STUN CHARGE", "arc_charge_a")
	_add_pickup(Vector3(-5.0, 0.42, -59.0), "arc_charge", "ARC STUN CHARGE", "arc_charge_b")
	_add_console(Vector3(-4.6, 0.0, -57.6), "SOREN // UNSENT", "log", "Mara, we taught it our voices. When the breach started, it used yours to open the inner gate. I should never have asked you to sign the shutdown.")
	_add_console(Vector3(0, 0.0, -50.0), "MAINTENANCE SPEAKER", "speaker", "The Resonant tracks vibration, not sight. A tuned lure can pull it into the deep shaft.")
	_add_ally(Vector3(4.0, 0.0, -51.0))
	_make_gate("beacon_gate", Vector3(0, 1.5, -63.0), Vector3(4.2, 3.2, 0.45), rust_mat)

	_add_console(Vector3(0, 0.0, -72.5), "RIDGE BEACON / ECHO LOCK", "beacon", "Mara's authorization and a charged battery will restart the rescue channel and re-engage containment.")
	# Partitions and machinery turn the square rooms into routes with cover and blind corners.
	_add_static_box(Vector3(-0.7, 1.0, -18.0), Vector3(0.55, 2.0, 5.6), wall_mat)
	_add_static_box(Vector3(1.4, 1.0, -35.2), Vector3(0.55, 2.0, 4.8), rust_mat)
	_add_static_box(Vector3(-1.6, 1.0, -53.5), Vector3(0.55, 2.0, 5.0), wall_mat)
	_add_machine(Vector3(-4.3, 0.8, -17), Vector3(1.5, 1.6, 1.0), wall_mat)
	_add_machine(Vector3(4.5, 0.8, -36), Vector3(1.8, 1.6, 1.2), rust_mat)
	_add_machine(Vector3(-4.2, 0.8, -53), Vector3(1.4, 1.6, 1.0), wall_mat)
	_add_prop(LOCKER_BANK_SCENE, Vector3(-5.85, 0, 1.5), Vector3(0.85, 0.85, 0.85))
	_add_prop(LOCKER_BANK_SCENE, Vector3(5.85, 0, -14.5), Vector3(0.85, 0.85, 0.85))
	_add_prop(LOCKER_BANK_SCENE, Vector3(5.85, 0, -56.4), Vector3(0.85, 0.85, 0.85))
	_add_prop(PIPE_RACK_SCENE, Vector3(-6.65, 0.55, -21.5), Vector3(1.0, 1.0, 1.0), PI * 0.5)
	_add_prop(PIPE_RACK_SCENE, Vector3(6.65, 0.55, -39.5), Vector3(1.0, 1.0, 1.0), -PI * 0.5)
	_add_prop(PIPE_RACK_SCENE, Vector3(-6.65, 0.55, -58.5), Vector3(1.0, 1.0, 1.0), PI * 0.5)
	_add_hide_spot(Vector3(-5.85, 0, -2.0))
	_add_hide_spot(Vector3(5.75, 0, -33.5))
	_add_hide_spot(Vector3(-5.75, 0, -50.0))
	_add_hide_spot(Vector3(5.75, 0, -71.0))
	_add_echo_scavenger([Vector3(4.7, 0, -52.0), Vector3(4.7, 0, -57.8), Vector3(2.1, 0, -57.8)])
	_add_echo_scavenger([Vector3(-4.8, 0, -58.4), Vector3(-3.9, 0, -52.3), Vector3(-0.7, 0, -54.0)])

func _build_room(center: Vector3, size: Vector2, floor_mat: Material, wall_mat: Material, north_open: bool, south_open: bool) -> void:
	_add_static_box(center + Vector3(0, -0.12, 0), Vector3(size.x, 0.24, size.y), floor_mat)
	var half_x := size.x * 0.5
	var half_z := size.y * 0.5
	_add_station_wall(center + Vector3(-half_x, 1.6, 0), size.y, false, wall_mat)
	_add_station_wall(center + Vector3(half_x, 1.6, 0), size.y, false, wall_mat)
	_add_wall_with_gap(center + Vector3(0, 1.6, -half_z), size.x, wall_mat, north_open)
	_add_wall_with_gap(center + Vector3(0, 1.6, half_z), size.x, wall_mat, south_open)
	_add_ceiling_modules(center + Vector3(0, 3.24, 0), size.x, size.y)

func _build_corridor(center: Vector3, length_value: float, floor_mat: Material, wall_mat: Material) -> void:
	_add_static_box(center + Vector3(0, -0.12, 0), Vector3(4.5, 0.24, length_value), floor_mat)
	_add_station_wall(center + Vector3(-2.25, 1.6, 0), length_value, false, wall_mat)
	_add_station_wall(center + Vector3(2.25, 1.6, 0), length_value, false, wall_mat)
	_add_ceiling_modules(center + Vector3(0, 3.24, 0), 4.5, length_value)

func _add_wall_with_gap(position: Vector3, width: float, material: Material, open: bool) -> void:
	if not open:
		_add_station_wall(position, width, true, material)
		return
	var side_width := (width - 4.4) * 0.5
	_add_station_wall(position + Vector3(-(2.2 + side_width * 0.5), 0, 0), side_width, true, material)
	_add_station_wall(position + Vector3(2.2 + side_width * 0.5, 0, 0), side_width, true, material)
	_add_static_box(position + Vector3(0, 2.85, 0), Vector3(4.4, 0.5, 0.35), material)

func _add_static_box(position: Vector3, box_size: Vector3, material: Material, create_visual: bool = true) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position
	if create_visual:
		var mesh_instance := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = box_size
		mesh_instance.mesh = mesh
		mesh_instance.material_override = material
		body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box_size
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body

func _add_station_wall(position: Vector3, length_value: float, runs_along_x: bool, collision_material: Material) -> void:
	var collision_size := Vector3(length_value, 3.2, 0.35) if runs_along_x else Vector3(0.35, 3.2, length_value)
	_add_static_box(position, collision_size, collision_material, false)
	var module_count := ceili(length_value / 2.0)
	var segment_length := length_value / module_count
	for index in module_count:
		var module := WALL_BAY_SCENE.instantiate()
		if runs_along_x:
			module.position = position + Vector3(-length_value * 0.5 + segment_length * (index + 0.5), -1.6, 0)
			module.scale.x = segment_length / 2.0
		else:
			module.position = position + Vector3(0, -1.6, -length_value * 0.5 + segment_length * (index + 0.5))
			module.rotation.y = PI * 0.5
			module.scale.x = segment_length / 2.0
		add_child(module)

func _add_ceiling_modules(center: Vector3, width: float, length_value: float) -> void:
	var count_x := ceili(width / 2.0)
	var count_z := ceili(length_value / 2.0)
	var segment_x := width / count_x
	var segment_z := length_value / count_z
	for x_index in count_x:
		for z_index in count_z:
			var module := CEILING_BAY_SCENE.instantiate()
			module.position = center + Vector3(-width * 0.5 + segment_x * (x_index + 0.5), 0, -length_value * 0.5 + segment_z * (z_index + 0.5))
			module.scale = Vector3(segment_x / 2.0, 1.0, segment_z / 2.0)
			add_child(module)

func _add_machine(position: Vector3, size_value: Vector3, material: Material) -> void:
	_add_static_box(position, size_value, material, false)
	var machine := PUMP_ASSEMBLY_SCENE.instantiate()
	machine.position = position - Vector3(0, size_value.y * 0.5, 0)
	machine.scale = Vector3(size_value.x / 2.25, size_value.y / 1.85, size_value.z / 1.05)
	add_child(machine)
	_add_light(position + Vector3(0, 1.0, -0.55), Color(0.95, 0.18, 0.04), 0.8, 2.0)

func _add_prop(scene: PackedScene, position_value: Vector3, scale_value: Vector3 = Vector3.ONE, rotation_y: float = 0.0) -> void:
	var prop := scene.instantiate()
	prop.position = position_value
	prop.scale = scale_value
	prop.rotation.y = rotation_y
	add_child(prop)

func _add_light(position: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = true
	add_child(light)

func _material(color: Color, roughness_value: float, metallic_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	material.metallic = metallic_value
	return material

func _floor_material() -> StandardMaterial3D:
	var material := _material(Color(0.46, 0.53, 0.58), 0.84, 0.08)
	material.albedo_texture = FLOOR_TEXTURE
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.uv1_scale = Vector3(0.28, 0.28, 1.0)
	return material

func _add_pickup(position: Vector3, item: String, label_text: String, objective_id: String = "", amount: int = 1) -> void:
	var pickup := Node3D.new()
	pickup.position = position
	pickup.set_meta("kind", "pickup")
	pickup.set_meta("item", item)
	pickup.set_meta("label", label_text)
	pickup.set_meta("persistent_id", objective_id if not objective_id.is_empty() else item)
	pickup.set_meta("amount", amount)
	_build_pickup_visual(pickup, item)
	_add_pickup_light(pickup)
	add_child(pickup)
	interactables.append(pickup)
	if not objective_id.is_empty():
		objective_nodes[objective_id] = pickup

func _build_pickup_visual(pickup: Node3D, item: String) -> void:
	# Objective objects are intentionally distinct silhouettes, not generic glowing boxes.
	var casing := _material(Color(0.14, 0.18, 0.22), 0.42, 0.64)
	var amber := _material(Color(0.96, 0.48, 0.06), 0.28, 0.34)
	amber.emission_enabled = true
	amber.emission = Color(0.70, 0.16, 0.015)
	amber.emission_energy_multiplier = 1.7
	var ceramic := _material(Color(0.72, 0.74, 0.70), 0.5, 0.12)
	var copper := _material(Color(0.56, 0.20, 0.07), 0.32, 0.82)
	var label_mat := _material(Color(0.12, 0.78, 0.64), 0.32, 0.42)
	label_mat.emission_enabled = true
	label_mat.emission = Color(0.025, 0.33, 0.22)
	label_mat.emission_energy_multiplier = 1.35
	match item:
		"keycard":
			_add_pickup_part(pickup, _box_mesh(Vector3(0.62, 0.055, 0.36)), Vector3(0, 0.06, 0), casing)
			_add_pickup_part(pickup, _box_mesh(Vector3(0.39, 0.012, 0.08)), Vector3(0, 0.10, -0.08), label_mat)
			_add_pickup_part(pickup, _cylinder_mesh(0.035, 0.018), Vector3(-0.24, 0.10, 0.10), amber, Vector3.ONE, Vector3(PI * 0.5, 0, 0))
		"wire":
			var coil := TorusMesh.new()
			coil.inner_radius = 0.16
			coil.outer_radius = 0.245
			coil.rings = 10
			coil.ring_segments = 16
			_add_pickup_part(pickup, coil, Vector3(0, 0.08, 0), copper)
			_add_pickup_part(pickup, _cylinder_mesh(0.025, 0.42), Vector3(0.22, 0.10, 0), copper, Vector3.ONE, Vector3(0, 0, PI * 0.45))
		"fuse":
			_add_pickup_part(pickup, _cylinder_mesh(0.11, 0.42), Vector3.ZERO, ceramic, Vector3.ONE, Vector3(0, 0, PI * 0.5))
			_add_pickup_part(pickup, _cylinder_mesh(0.125, 0.08), Vector3(-0.25, 0, 0), casing, Vector3.ONE, Vector3(0, 0, PI * 0.5))
			_add_pickup_part(pickup, _cylinder_mesh(0.125, 0.08), Vector3(0.25, 0, 0), casing, Vector3.ONE, Vector3(0, 0, PI * 0.5))
		"cell":
			_add_pickup_part(pickup, _cylinder_mesh(0.16, 0.64), Vector3(0, 0.05, 0), casing, Vector3.ONE, Vector3(0, 0, PI * 0.5))
			_add_pickup_part(pickup, _cylinder_mesh(0.112, 0.50), Vector3(0, 0.05, 0), label_mat, Vector3.ONE, Vector3(0, 0, PI * 0.5))
			_add_pickup_part(pickup, _box_mesh(Vector3(0.09, 0.13, 0.23)), Vector3(0.35, 0.05, 0), amber)
		"battery":
			_add_pickup_part(pickup, _box_mesh(Vector3(0.48, 0.30, 0.26)), Vector3(0, 0.06, 0), casing)
			_add_pickup_part(pickup, _box_mesh(Vector3(0.34, 0.17, 0.016)), Vector3(0, 0.22, -0.02), label_mat)
			for x in [-0.13, 0.13]:
				_add_pickup_part(pickup, _cylinder_mesh(0.042, 0.045), Vector3(x, 0.24, 0.08), copper)
		"arc_charge":
			_add_pickup_part(pickup, _cylinder_mesh(0.13, 0.42), Vector3(0, 0.06, 0), casing, Vector3.ONE, Vector3(0, 0, PI * 0.5))
			_add_pickup_part(pickup, _cylinder_mesh(0.078, 0.31), Vector3(0, 0.06, 0), label_mat, Vector3.ONE, Vector3(0, 0, PI * 0.5))
			_add_pickup_part(pickup, _box_mesh(Vector3(0.05, 0.10, 0.19)), Vector3(0.24, 0.06, 0), amber)
		"rivet_gun":
			# Industrial tool silhouette: a compact riveter, not a modern military weapon.
			_add_pickup_part(pickup, _box_mesh(Vector3(0.34, 0.19, 0.66)), Vector3(0, 0.13, 0), casing, Vector3.ONE, Vector3(0.0, 0.16, 0.0))
			_add_pickup_part(pickup, _cylinder_mesh(0.07, 0.53), Vector3(0, 0.14, -0.47), copper, Vector3.ONE, Vector3(PI * 0.5, 0, 0))
			_add_pickup_part(pickup, _box_mesh(Vector3(0.14, 0.35, 0.16)), Vector3(0, -0.08, 0.17), casing, Vector3.ONE, Vector3(-0.28, 0, 0))
			_add_pickup_part(pickup, _box_mesh(Vector3(0.17, 0.07, 0.16)), Vector3(0, 0.25, 0.10), label_mat)
		"rivet_rounds":
			for x in [-0.11, 0.0, 0.11]:
				_add_pickup_part(pickup, _cylinder_mesh(0.042, 0.32), Vector3(x, 0.10, 0), copper, Vector3.ONE, Vector3(0, 0, PI * 0.5))
				_add_pickup_part(pickup, _cylinder_mesh(0.052, 0.055), Vector3(x - 0.18, 0.10, 0), casing, Vector3.ONE, Vector3(0, 0, PI * 0.5))
		"snack":
			_add_pickup_part(pickup, _box_mesh(Vector3(0.38, 0.18, 0.60)), Vector3(0, 0.05, 0), _material(Color(0.22, 0.12, 0.24), 0.38, 0.15))
			_add_pickup_part(pickup, _box_mesh(Vector3(0.28, 0.014, 0.34)), Vector3(0, 0.15, -0.04), label_mat)
		_:
			# Scrap is a bundle of bent plates rather than a single placeholder cube.
			_add_pickup_part(pickup, _box_mesh(Vector3(0.60, 0.07, 0.18)), Vector3(-0.04, 0.08, 0.03), casing, Vector3.ONE, Vector3(0.18, 0.35, -0.22))
			_add_pickup_part(pickup, _box_mesh(Vector3(0.42, 0.06, 0.27)), Vector3(0.09, 0.16, -0.06), copper, Vector3.ONE, Vector3(-0.14, -0.30, 0.16))

func _box_mesh(size_value: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size_value
	return mesh

func _cylinder_mesh(radius_value: float, height_value: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius_value
	mesh.bottom_radius = radius_value
	mesh.height = height_value
	mesh.radial_segments = 12
	return mesh

func _add_pickup_part(parent: Node3D, mesh: Mesh, offset: Vector3, material: Material, scale_value: Vector3 = Vector3.ONE, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = offset
	part.scale = scale_value
	part.rotation = rotation_value
	part.material_override = material
	parent.add_child(part)

func _add_pickup_light(pickup: Node3D) -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.48, 0.08)
	light.light_energy = 0.8
	light.omni_range = 2.5
	pickup.add_child(light)

func _add_ally(position_value: Vector3) -> void:
	nix = ScavengerScript.new()
	nix.position = position_value
	nix.set_meta("kind", "ally")
	nix.set_meta("label", "NIX, THE TUNNEL RAT")
	add_child(nix)
	interactables.append(nix)

func _add_echo_scavenger(points: Array[Vector3]) -> void:
	var scavenger := EchoScavengerScript.new()
	add_child(scavenger)
	scavenger.configure(points)
	echo_scavengers.append(scavenger)

func _add_hide_spot(position_value: Vector3) -> void:
	var hide_spot := Node3D.new()
	hide_spot.position = position_value
	hide_spot.set_meta("kind", "hide")
	hide_spot.set_meta("label", "ACOUSTIC LOCKER")
	var locker := LOCKER_BANK_SCENE.instantiate()
	locker.scale = Vector3(0.86, 0.86, 0.86)
	hide_spot.add_child(locker)
	add_child(hide_spot)
	interactables.append(hide_spot)

func _add_console(position: Vector3, title: String, kind: String, note: String) -> void:
	var console := Node3D.new()
	console.position = position
	console.set_meta("kind", kind)
	console.set_meta("label", title)
	console.set_meta("note", note)
	if kind == "log":
		console.set_meta("log_id", title)
	var visual := CONTROL_CONSOLE_SCENE.instantiate()
	console.add_child(visual)
	var collision_body := StaticBody3D.new()
	collision_body.position = Vector3(0, 0.52, 0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.16, 0.72, 1.05)
	collision.shape = shape
	collision_body.add_child(collision)
	console.add_child(collision_body)
	add_child(console)
	interactables.append(console)
	if kind != "log":
		objective_nodes[kind] = console

func _make_gate(gate_name: String, position: Vector3, size_value: Vector3, material: Material, visual_scene: PackedScene = GRILL_GATE_SCENE) -> void:
	var gate := Node3D.new()
	gate.name = gate_name
	gate.position = Vector3(position.x, 0, position.z)
	add_child(gate)
	var collision_body := StaticBody3D.new()
	collision_body.position = Vector3(0, position.y, 0)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size_value
	collision.shape = shape
	collision_body.add_child(collision)
	gate.add_child(collision_body)
	var visual := visual_scene.instantiate()
	visual.position = Vector3.ZERO
	gate.add_child(visual)
	gates[gate_name] = gate

func player_interact() -> void:
	if player.is_hidden:
		_leave_hiding()
		return
	var nearby := _nearest_interactable()
	if nearby == null:
		show_message("Nothing close enough to use.", 1.2)
		return
	var kind: String = nearby.get_meta("kind")
	if kind == "pickup":
		var item: String = nearby.get_meta("item")
		var amount := int(nearby.get_meta("amount", 1))
		inventory[item] += amount
		var persistent_id: String = nearby.get_meta("persistent_id")
		if not collected_pickups.has(persistent_id):
			collected_pickups.append(persistent_id)
		_play_sfx(METAL_HIT_SFX, -10.0, randf_range(0.94, 1.06))
		make_noise(player.global_position, 3.5)
		_award_experience(10)
		if item == "rivet_gun":
			player.set_riveter_equipped(true)
			show_message("EQUIPPED: MAINTENANCE RIVETER // LEFT CLICK TO FIRE. SHOTS ARE LOUD.", 3.4)
		else:
			var suffix := " x%d" % amount if amount > 1 else ""
			show_message("COLLECTED: %s%s" % [nearby.get_meta("label"), suffix], 2.0)
		interactables.erase(nearby)
		nearby.queue_free()
		return
	if kind == "log":
		var log_id := str(nearby.get_meta("log_id", nearby.get_meta("label")))
		if not read_logs.has(log_id):
			read_logs.append(log_id)
			_award_experience(18)
		show_message(nearby.get_meta("note"), 4.0)
		return
	if kind == "hide":
		_enter_hiding(nearby)
		return
	if kind == "ally":
		game_menu.open_nix_dialog()
		return
	if kind == "blast_door":
		if stage == 0 and inventory.keycard > 0:
			stage = 1
			_open_gate("ops_gate")
			_award_experience(25)
			make_noise(nearby.global_position, 6.0)
			show_message("OPERATIONS UNLOCKED. Find generator parts—and learn why Soren called you back.", 4.0)
		else:
			show_message("The blast door needs the maintenance keycard from the entry bay.", 2.6)
		return
	if kind == "generator":
		if stage == 1 and inventory.fuse > 0 and inventory.wire > 0 and inventory.scrap > 0:
			inventory.fuse -= 1
			inventory.wire -= 1
			inventory.scrap -= 1
			stage = 2
			mimic.awaken()
			_award_experience(45)
			_play_sfx(MACHINE_START_SFX, -3.0)
			make_noise(nearby.global_position, 18.0)
			horror_audio.play_stinger()
			show_message("ECHO LOCK POWER RESTORED. SOMETHING ANSWERS THROUGH THE SPEAKERS.", 4.0)
		else:
			show_message("Generator needs: 1 scrap, 1 insulated wire, 1 ceramic fuse.", 2.8)
		return
	if kind == "elevator":
		if stage == 2:
			stage = 3
			_open_gate("pump_gate")
			_award_experience(35)
			_play_sfx(ELEVATOR_SFX, -2.0)
			make_noise(nearby.global_position, 14.0)
			show_message("FREIGHT ELEVATOR DESCENDING. THE TEST SHAFT IS OPEN.", 3.0)
		else:
			show_message("The elevator control has no power.", 2.0)
		return
	if kind == "pump":
		if stage == 3 and inventory.cell > 0:
			inventory.cell -= 1
			stage = 4
			checkpoint = Vector3(0, 0.9, -36.0)
			_open_gate("medical_gate")
			_activate_echo_scavengers()
			_award_experience(50)
			_play_sfx(MACHINE_START_SFX, -4.0, 0.82)
			make_noise(nearby.global_position, 13.0)
			show_message("PUMPS ONLINE. LOWER WING UNSEALED. ECHO SCAVENGERS NEST BELOW—VAULT OR STUN THEM.", 4.0)
		else:
			show_message("Pump control needs a power cell.", 2.0)
		return
	if kind == "speaker":
		if stage == 4 and inventory.lure > 0:
			inventory.lure -= 1
			stage = 5
			checkpoint = Vector3(0, 0.9, -54.0)
			_open_gate("beacon_gate")
			mimic.divert(Vector3(0, 0, -45.0))
			_award_experience(45)
			_play_sfx(METAL_HIT_SFX, -6.0, 0.78)
			show_message("TUNED LURE TRANSMITTING. IT TURNS TOWARD THE SHAFT—MOVE.", 3.2)
		else:
			show_message("A crafted noise lure can overload this speaker.", 2.5)
		return
	if kind == "beacon":
		if stage == 5 and inventory.battery > 0:
			game_menu.open_beacon_choice()
		else:
			show_message("Beacon needs a charged battery and a clear transmission route.", 2.5)

func player_craft() -> void:
	if stage < 4:
		show_message("No useful field recipe is available yet.", 1.8)
		return
	if inventory.scrap > 0 and inventory.wire > 0 and inventory.lure == 0:
		inventory.scrap -= 1
		inventory.wire -= 1
		inventory.lure = 1
		_play_sfx(METAL_HIT_SFX, -8.0, 1.25)
		make_noise(player.global_position, 8.0)
		show_message("CRAFTED: TUNED NOISE LURE // Use it at the maintenance speaker.", 3.0)
	else:
		show_message("Need 1 scrap and 1 wire to craft a noise lure.", 2.0)

func player_fire() -> void:
	if not player.riveter_equipped:
		show_message("No maintenance riveter equipped.", 1.8)
		return
	if player.riveter_cooldown > 0.0:
		return
	if inventory.rivet_rounds <= 0:
		player.riveter_cooldown = 0.45
		riveter_player.stream = dry_stream
		riveter_player.pitch_scale = 1.0
		riveter_player.play()
		show_message("RIVETER EMPTY // Loot rivet round cases in the station.", 2.2)
		return
	inventory.rivet_rounds -= 1
	player.riveter_cooldown = RIVETER_COOLDOWN
	riveter_player.stream = shot_stream
	riveter_player.pitch_scale = randf_range(0.96, 1.04)
	riveter_player.play()
	player.apply_shot_recoil(randf_range(0.035, 0.055), randf_range(-0.018, 0.018))
	var hit := _riveter_trace(0.0)
	# The scavengers are knee-high and fast; a single hairline ray makes them a
	# coin flip to hit. A little vertical tolerance keeps the tool fair.
	if not _hit_is_creature(hit):
		for vertical_offset in [0.10, -0.12]:
			var alternate := _riveter_trace(vertical_offset)
			if _hit_is_creature(alternate):
				hit = alternate
				break
	if not hit.is_empty():
		var collider = hit.get("collider")
		var point: Vector3 = hit.get("position", Vector3.ZERO)
		var normal: Vector3 = hit.get("normal", Vector3.UP)
		var on_creature := false
		if collider is EchoScavenger:
			(collider as EchoScavenger).take_rivet_hit(RIVETER_DAMAGE, player.global_position)
			on_creature = true
		elif collider is Mimic:
			(collider as Mimic).take_rivet_hit(player.global_position)
			on_creature = true
			show_message("THE RIVET BITES. IT ROCKS BACK, THROAT RINGS FLARING—THEN COMES ON.", 2.6)
		_spawn_impact(point, normal, on_creature)
		_pulse_hit_marker(on_creature)
	else:
		_pulse_hit_marker(false)
	# Sound is the real weapon: the crack travels the pipework to the Resonant.
	make_noise(player.global_position, 17.0, "rivet")

func _riveter_trace(vertical_offset: float = 0.0) -> Dictionary:
	# A real projectile: crosshair ray against world collision, so walls, doors
	# and lockers stop the rivet instead of the shot passing through them.
	var camera := player.camera
	var origin: Vector3 = camera.global_position + camera.global_transform.basis.y * vertical_offset
	var forward: Vector3 = -camera.global_transform.basis.z
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * RIVETER_RANGE)
	query.exclude = [player.get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = false
	return space.intersect_ray(query)

func _hit_is_creature(hit: Dictionary) -> bool:
	if hit.is_empty():
		return false
	var collider = hit.get("collider")
	return collider is EchoScavenger or collider is Mimic

func _build_combat_feedback() -> void:
	shot_stream = _build_shot_stream()
	dry_stream = _build_click_stream(0.08, 2200.0)
	impact_stream = _build_click_stream(0.15, 1450.0)
	riveter_player = AudioStreamPlayer.new()
	riveter_player.stream = shot_stream
	riveter_player.volume_db = -2.5
	add_child(riveter_player)
	impact_root = Node3D.new()
	impact_root.name = "RivetImpacts"
	add_child(impact_root)
	decal_material = StandardMaterial3D.new()
	decal_material.albedo_texture = _build_hole_texture()
	decal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	decal_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	decal_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	decal_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	spark_material = _emissive_material(Color(1.0, 0.72, 0.34), Color(1.0, 0.5, 0.14), 4.0)
	ichor_material = _emissive_material(Color(0.5, 0.08, 0.07), Color(0.78, 0.06, 0.03), 2.2)

func _build_shot_stream() -> AudioStreamWAV:
	# Synthesised riveter crack: noise transient, low chamber thump, metal ring
	# and a room tail. Generated at startup so the shot needs no sample assets.
	var rate := 22050
	var frames := int(rate * 0.46)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 441733
	for frame in frames:
		var time := float(frame) / rate
		var transient := rng.randf_range(-1.0, 1.0) * exp(-time * 34.0)
		var thump := sin(TAU * 74.0 * time) * exp(-time * 11.0) * 0.62
		var ring := sin(TAU * 1210.0 * time) * exp(-time * 26.0) * 0.20
		var body := sin(TAU * 320.0 * time) * exp(-time * 17.0) * 0.24
		var tail := rng.randf_range(-1.0, 1.0) * exp(-time * 6.5) * 0.16
		var sample := clampf(transient + thump + ring + body + tail, -1.0, 1.0)
		data.encode_s16(frame * 2, int(sample * 30500.0))
	return _wav_from(data, rate)

func _build_click_stream(duration: float, tone: float) -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * duration)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(tone) * 7919
	for frame in frames:
		var time := float(frame) / rate
		var click := rng.randf_range(-1.0, 1.0) * exp(-time * 42.0) * 0.55
		var ring := sin(TAU * tone * time) * exp(-time * 30.0) * 0.22
		var sample := clampf(click + ring, -1.0, 1.0)
		data.encode_s16(frame * 2, int(sample * 30000.0))
	return _wav_from(data, rate)

func _wav_from(data: PackedByteArray, rate: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.stereo = false
	stream.data = data
	return stream

func _build_hole_texture() -> ImageTexture:
	# Soft dark puncture with a light chipped rim, drawn once and reused by
	# every impact decal so repeated shots do not allocate new textures.
	var size := 32
	var image := Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	for y in size:
		for x in size:
			var radius := Vector2(x + 0.5, y + 0.5).distance_to(center) / (size * 0.5)
			var core := clampf(1.0 - radius / 0.45, 0.0, 1.0)
			var rim := clampf(1.0 - absf(radius - 0.66) / 0.30, 0.0, 1.0)
			var alpha := clampf(core * 0.95 + rim * 0.32, 0.0, 1.0)
			var shade := 0.035 + rim * 0.06
			image.set_pixel(x, y, Color(shade, shade, shade + 0.012, alpha))
	return ImageTexture.create_from_image(image)

func _emissive_material(albedo: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	return material

func _spawn_impact(point: Vector3, normal: Vector3, on_creature: bool) -> void:
	var decal := MeshInstance3D.new()
	var quad := QuadMesh.new()
	var size := randf_range(0.10, 0.14) if on_creature else randf_range(0.15, 0.23)
	quad.size = Vector2(size, size)
	decal.mesh = quad
	decal.material_override = decal_material
	impact_root.add_child(decal)
	decal.position = point + normal * 0.012
	var up := Vector3.UP if absf(normal.dot(Vector3.UP)) < 0.97 else Vector3.FORWARD
	decal.look_at(point - normal, up)
	decal.rotate_object_local(Vector3(0, 0, 1), randf() * TAU)
	impact_decals.append(decal)
	while impact_decals.size() > MAX_IMPACT_DECALS:
		var oldest: MeshInstance3D = impact_decals.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	_spawn_sparks(point, normal, on_creature)
	_play_impact(point, on_creature)

func _spawn_sparks(point: Vector3, normal: Vector3, on_creature: bool) -> void:
	var sparks := CPUParticles3D.new()
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = 16 if on_creature else 11
	sparks.lifetime = 0.42
	sparks.direction = normal
	sparks.spread = 45.0
	sparks.initial_velocity_min = 2.4
	sparks.initial_velocity_max = 5.8
	sparks.gravity = Vector3(0, -11.0, 0)
	sparks.scale_amount_min = 0.5
	sparks.scale_amount_max = 1.15
	var spark_mesh := BoxMesh.new()
	spark_mesh.size = Vector3(0.022, 0.022, 0.055)
	sparks.mesh = spark_mesh
	sparks.material_override = ichor_material if on_creature else spark_material
	sparks.position = point
	add_child(sparks)
	sparks.emitting = true
	get_tree().create_timer(1.2).timeout.connect(sparks.queue_free)

func _play_impact(point: Vector3, on_creature: bool) -> void:
	var impact := AudioStreamPlayer3D.new()
	impact.stream = impact_stream
	impact.unit_size = 5.0
	impact.max_distance = 24.0
	impact.volume_db = -13.0 if on_creature else -9.5
	impact.pitch_scale = randf_range(0.9, 1.15)
	impact.position = point
	add_child(impact)
	impact.play()
	impact.finished.connect(impact.queue_free)

func _pulse_hit_marker(on_creature: bool) -> void:
	if crosshair == null:
		return
	crosshair.text = "×" if on_creature else "·"
	crosshair.add_theme_color_override("font_color", Color(1.0, 0.55, 0.18, 1.0) if on_creature else Color(0.75, 0.82, 0.86, 0.9))
	var marker := crosshair.text
	await get_tree().create_timer(0.13).timeout
	if is_instance_valid(crosshair) and crosshair.text == marker:
		crosshair.text = "+"
		crosshair.add_theme_color_override("font_color", Color(0.8, 0.9, 0.95, 0.75))

func scavenger_killed(at_position: Vector3) -> void:
	_spawn_ichor_pool(at_position)
	loot_counter += 1
	_add_pickup(at_position + Vector3(0, 0.06, 0), "rivet_rounds", "DROPPED RIVET ROUNDS", "loot_%d" % loot_counter, 2)
	_award_experience(18)
	show_message("THE SCAVENGER GOES STILL. IT DROPPED RIVET ROUNDS.", 2.2)

func _spawn_ichor_pool(at_position: Vector3) -> void:
	# The scavengers bleed a dark, faintly reactive ichor. It stays on the floor
	# long enough to make every kill leave a readable consequence in the room.
	if impact_root == null:
		return
	var pool := Node3D.new()
	pool.position = at_position + Vector3(0, 0.014, 0)
	impact_root.add_child(pool)
	var pool_mesh := CylinderMesh.new()
	var radius := randf_range(0.22, 0.38)
	pool_mesh.top_radius = radius
	pool_mesh.bottom_radius = radius * 0.93
	pool_mesh.height = 0.022
	pool_mesh.radial_segments = 18
	var pool_surface := MeshInstance3D.new()
	pool_surface.mesh = pool_mesh
	pool_surface.material_override = _ichor_pool_material()
	pool.add_child(pool_surface)
	for index in 6:
		var fleck := MeshInstance3D.new()
		var fleck_mesh := SphereMesh.new()
		fleck_mesh.radius = 0.045
		fleck_mesh.height = 0.035
		fleck.mesh = fleck_mesh
		fleck.scale = Vector3(randf_range(0.45, 1.2), 0.30, randf_range(0.35, 0.9))
		var direction := Vector2.from_angle(randf() * TAU)
		fleck.position = Vector3(direction.x, 0.014, direction.y) * randf_range(radius * 0.85, radius * 2.15)
		fleck.material_override = _ichor_pool_material()
		pool.add_child(fleck)
	ichor_pools.append(pool)
	while ichor_pools.size() > MAX_ICHOR_POOLS:
		var oldest: Node3D = ichor_pools.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()

func _ichor_pool_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.18, 0.018, 0.024)
	material.roughness = 0.32
	material.metallic = 0.05
	material.emission_enabled = true
	material.emission = Color(0.20, 0.006, 0.012)
	material.emission_energy_multiplier = 0.42
	return material

func make_noise(noise_position: Vector3, radius: float, source: String = "world") -> void:
	var adjusted_radius := radius
	if rpg.has_skill("quiet_step") and source in ["footstep", "vault"]:
		adjusted_radius *= 0.68
	if mimic != null:
		mimic.hear(noise_position, adjusted_radius)

func _award_experience(amount: int) -> void:
	var levels_gained := rpg.gain_experience(amount)
	if levels_gained > 0:
		get_tree().create_timer(1.1).timeout.connect(_announce_level_up)

func _announce_level_up() -> void:
	show_message("LEVEL UP // MARA VENN — LEVEL %d\n%d SKILL POINT AVAILABLE IN PAUSE > CHARACTER" % [rpg.level, rpg.skill_points], 4.0)

func unlock_skill(skill_id: String) -> bool:
	if not rpg.unlock(skill_id):
		return false
	var skill_data: Dictionary = rpg.SKILLS.get(skill_id, {})
	show_message("UNLOCKED // %s" % str(skill_data.get("name", skill_id)), 2.8)
	return true

func _enter_hiding(hide_spot: Node3D) -> void:
	active_hide_spot = hide_spot
	player.enter_hide()
	show_message("HIDDEN // HOLD STILL. [E] LEAVE LOCKER", 30.0)

func _leave_hiding() -> void:
	player.leave_hide()
	active_hide_spot = null
	show_message("LEFT LOCKER", 1.2)

func player_pulse() -> void:
	if inventory.arc_charge <= 0:
		show_message("No arc charge. Nix may find one if you feed it.", 2.2)
		return
	var forward := -player.camera.global_transform.basis.z
	var stunned_any := false
	var stun_duration := 11.5 if rpg.has_skill("charged_pulse") else 7.5
	for scavenger in echo_scavengers:
		if scavenger.can_receive_pulse(player.global_position + Vector3.UP * 0.65, forward):
			scavenger.stun(stun_duration)
			stunned_any = true
	if not stunned_any:
		show_message("No Echo Scavenger in pulse range.", 1.8)
		return
	inventory.arc_charge -= 1
	_play_sfx(METAL_HIT_SFX, -3.0, 1.45)
	make_noise(player.global_position, 9.0)
	show_message("ARC PULSE DISCHARGED. THE SCAVENGER IS STUNNED—MOVE.", 2.4)

func scavenger_hit(scavenger: EchoScavenger) -> void:
	if not player.can_move:
		return
	var drain := 14.0 if rpg.has_skill("insulated_pack") else 28.0
	player.flashlight_charge = maxf(0.0, player.flashlight_charge - drain)
	make_noise(scavenger.global_position, 7.0)
	scavenger.scurry_away()
	show_message("A scavenger tears into your cable pack. FLASHLIGHT -%d%%." % int(drain), 2.4)

func _activate_echo_scavengers() -> void:
	for scavenger in echo_scavengers:
		scavenger.set_active(true)

func resolve_nix_choice(choice: String) -> String:
	if nix == null:
		return "The vent is empty."
	if choice == "ask":
		if not bool(nix.get_meta("resonant_hint", false)):
			nix.set_meta("resonant_hint", true)
			_award_experience(12)
			return "Nix taps the floor twice, freezes, then presses itself flat. It knows the tall one hears movement before it arrives."
		return "Nix tilts its head toward the old shaft. It is warning you to stop moving when the air begins to pulse."
	if choice == "feed":
		if inventory.snack <= 0:
			return "Nix sniffs your empty hands and retreats into the vent."
		if nix.trade():
			inventory.snack -= 1
			player.flashlight_charge = 100.0
			inventory.arc_charge += 1
			rpg.gain_companion_trust()
			_award_experience(28)
			return "Nix accepts the snack, vanishes into a vent, and returns with a flashlight pack and an arc charge. Trust increased."
		return "Nix has already repaid the kindness. It chirps under the maintenance speaker."
	return "Nix watches without moving."

func resolve_beacon_choice(choice: String) -> void:
	if stage != 5 or inventory.battery <= 0:
		return
	ending_choice = choice
	inventory.battery -= 1
	stage = 6
	player.can_move = false
	horror_audio.set_tension(0.0)
	_play_sfx(ELEVATOR_SFX, -1.0, 1.18)
	_award_experience(90)
	game_menu.close_menu()
	if choice == "expose":
		show_message("BEACON ONLINE. PROJECT ECHO ARCHIVES BROADCAST.\nTHE WORLD WILL HEAR WHAT ASTER DID.", 8.0)
	else:
		show_message("BEACON ONLINE. ECHO LOCK RE-ENGAGING.\nMARA VENN'S LAST SIGNAL IS OUT.", 8.0)

func player_caught() -> void:
	if caught_cooldown or stage >= 6:
		return
	caught_cooldown = true
	player.can_move = false
	mimic.freeze_for_capture()
	horror_audio.play_stinger()
	vignette.color = Color(0.72, 0.0, 0.0, 0.92)
	show_message("THE RESONANT FOUND YOU", 1.2)
	get_tree().create_timer(1.35).timeout.connect(_finish_capture)

func _finish_capture() -> void:
	player.restore_at(checkpoint)
	mimic.reset_after_capture()
	vignette.color = Color(0.0, 0.0, 0.0, 0.0)
	caught_cooldown = false
	show_message("You woke at the last safe point. It is listening again.", 2.5)

func _nearest_interactable() -> Node3D:
	var nearest: Node3D = null
	var nearest_distance := 2.3
	for candidate in interactables:
		if not is_instance_valid(candidate):
			continue
		var distance := player.global_position.distance_to(candidate.global_position)
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest

func _open_gate(gate_name: String, instantly: bool = false) -> void:
	if gates.has(gate_name) and is_instance_valid(gates[gate_name]):
		var gate: Node3D = gates[gate_name]
		_play_sfx(DOOR_OPEN_SFX, -4.0, randf_range(0.92, 1.04))
		if instantly:
			gate.queue_free()
			return
		var tween := gate.create_tween()
		tween.tween_property(gate, "position:y", 3.6, 0.78).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		tween.tween_callback(gate.queue_free)

func _play_sfx(sound: AudioStream, volume_db: float = -6.0, pitch: float = 1.0) -> void:
	if sfx_player == null:
		return
	sfx_player.stream = sound
	sfx_player.volume_db = volume_db
	sfx_player.pitch_scale = pitch
	sfx_player.play()

func toggle_pause_menu() -> void:
	if game_menu == null:
		return
	if game_menu.visible and game_menu.current_screen == "pause":
		game_menu.close_menu()
	elif game_menu.visible and game_menu.current_screen != "title":
		game_menu.open_pause()
	elif not game_menu.visible:
		game_menu.open_pause()

func new_game() -> void:
	game_menu.close_menu()
	player.can_move = true
	show_message("INCOMING // SOREN: ‘Mara, Echo Lock is open. Do not trust my voice.’", 4.2)
	get_tree().create_timer(4.35).timeout.connect(_show_return_objective)

func _show_return_objective() -> void:
	if stage == 0 and player.can_move:
		show_message("Recover your maintenance keycard. The tracker will point to it.", 3.5)

func save_game() -> void:
	var data := {
		"stage": stage,
		"inventory": inventory,
		"player_position": [player.global_position.x, player.global_position.y, player.global_position.z],
		"checkpoint": [checkpoint.x, checkpoint.y, checkpoint.z],
		"collected_pickups": collected_pickups,
		"read_logs": read_logs,
		"nix_traded": nix != null and nix.traded,
		"nix_hint_learned": nix != null and bool(nix.get_meta("resonant_hint", false)),
		"ending_choice": ending_choice,
		"rpg": rpg.to_save_data(),
		"master_volume_db": master_volume_db,
		"brightness": brightness
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	show_message("GAME SAVED", 1.6)

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	stage = int(parsed.get("stage", 0))
	ending_choice = str(parsed.get("ending_choice", ""))
	var saved_inventory: Dictionary = parsed.get("inventory", {})
	for key in inventory:
		inventory[key] = int(saved_inventory.get(key, 0))
	collected_pickups.clear()
	for persistent_id in parsed.get("collected_pickups", []):
		collected_pickups.append(str(persistent_id))
	read_logs.clear()
	for log_id in parsed.get("read_logs", []):
		read_logs.append(str(log_id))
	checkpoint = _array_to_vector(parsed.get("checkpoint", [0, 0.9, 2.5]), Vector3(0, 0.9, 2.5))
	var saved_position := _array_to_vector(parsed.get("player_position", [0, 0.9, 2.5]), checkpoint)
	player.restore_at(saved_position)
	if inventory.rivet_gun > 0:
		player.set_riveter_equipped(true)
	if nix != null:
		nix.traded = bool(parsed.get("nix_traded", false))
		nix.set_meta("resonant_hint", bool(parsed.get("nix_hint_learned", false)))
	if parsed.has("rpg"):
		rpg.load_save_data(parsed.get("rpg", {}))
	else:
		# Existing prototype saves should not strand a late-game player at level 1.
		rpg = RpgProgressionScript.new()
		rpg.gain_experience(stage * 70 + collected_pickups.size() * 10 + read_logs.size() * 18)
	set_master_volume(float(parsed.get("master_volume_db", master_volume_db)))
	set_brightness(float(parsed.get("brightness", brightness)))
	_remove_collected_pickups()
	if stage >= 1:
		_open_gate("ops_gate", true)
	if stage >= 3:
		_open_gate("pump_gate", true)
	if stage >= 4:
		_open_gate("medical_gate", true)
		_activate_echo_scavengers()
	if stage >= 5:
		_open_gate("beacon_gate", true)
	if stage >= 2:
		mimic.awaken()
	show_message("LAST SIGNAL RESTORED", 2.5)
	return true

func set_master_volume(value: float) -> void:
	master_volume_db = value
	var bus_index := AudioServer.get_bus_index("Master")
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, master_volume_db)

func set_brightness(value: float) -> void:
	brightness = value
	if world_environment != null:
		world_environment.ambient_light_energy = 0.28 * brightness

func _remove_collected_pickups() -> void:
	for candidate in interactables.duplicate():
		if not is_instance_valid(candidate) or candidate.get_meta("kind") != "pickup":
			continue
		var persistent_id: String = candidate.get_meta("persistent_id")
		if collected_pickups.has(persistent_id):
			interactables.erase(candidate)
			candidate.queue_free()

func _array_to_vector(values: Array, fallback: Vector3) -> Vector3:
	if values.size() != 3:
		return fallback
	return Vector3(float(values[0]), float(values[1]), float(values[2]))

func _update_hud() -> void:
	if player == null:
		return
	objective_label.text = "OBJECTIVE  //  " + _objective_text()
	var riveter_state := "STOWED"
	if player.riveter_equipped:
		if inventory.rivet_rounds <= 0:
			riveter_state = "EMPTY"
		elif player.riveter_cooldown > 0.0:
			riveter_state = "CYCLING"
		else:
			riveter_state = "READY"
	inventory_label.text = "SCRAP %d  WIRE %d  FUSE %d  CELL %d  BATTERY %d  LURE %d\nRIVETS %d  CARD %d  SNACK %d  ARC %d  •  FLASHLIGHT %d%%  •  RIVETER %s" % [inventory.scrap, inventory.wire, inventory.fuse, inventory.cell, inventory.battery, inventory.lure, inventory.rivet_rounds, inventory.keycard, inventory.snack, inventory.arc_charge, int(player.flashlight_charge), riveter_state]
	rpg_label.text = "MARA VENN  •  LV %d\nXP %d / %d  •  SKILL %d\nNIX TRUST %d / 3" % [rpg.level, rpg.experience, rpg.experience_to_next(), rpg.skill_points, rpg.companion_trust]
	if player.is_hidden:
		prompt_label.text = "[E] LEAVE ACOUSTIC LOCKER"
	else:
		var nearby := _nearest_interactable()
		prompt_label.text = "[E] " + str(nearby.get_meta("label")) if nearby != null else ""

func _build_objective_marker() -> void:
	objective_marker = Node3D.new()
	objective_marker.name = "TaskLocator"
	var ring := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.16
	mesh.bottom_radius = 0.28
	mesh.height = 0.10
	ring.mesh = mesh
	var material := _material(Color(0.12, 0.95, 0.82), 0.25, 0.15)
	material.emission_enabled = true
	material.emission = Color(0.04, 0.55, 0.45)
	material.emission_energy_multiplier = 1.8
	ring.material_override = material
	objective_marker.add_child(ring)
	var light := OmniLight3D.new()
	light.light_color = Color(0.15, 0.9, 0.75)
	light.light_energy = 1.25
	light.omni_range = 4.0
	objective_marker.add_child(light)
	add_child(objective_marker)

func _update_objective_tracker() -> void:
	if player == null or objective_marker == null:
		return
	var target := _objective_target()
	if target == null:
		objective_marker.visible = false
		tracker_label.text = ""
		return
	objective_marker.visible = true
	objective_marker.global_position = target.global_position + Vector3(0, 2.35 + sin(Time.get_ticks_msec() * 0.004) * 0.16, 0)
	objective_marker.rotation.y += 0.025
	var offset := target.global_position - player.global_position
	var flat_offset := Vector3(offset.x, 0, offset.z)
	var distance := int(flat_offset.length())
	var direction := flat_offset.normalized()
	var forward := -player.global_transform.basis.z
	var right := player.global_transform.basis.x
	var direction_glyph := "↑"
	if forward.dot(direction) < -0.45:
		direction_glyph = "↓"
	elif right.dot(direction) > 0.45:
		direction_glyph = "→"
	elif right.dot(direction) < -0.45:
		direction_glyph = "←"
	tracker_label.text = "TRACKER  //  %s  %s  •  %dm" % [direction_glyph, str(target.get_meta("label")), distance]

func _objective_target() -> Node3D:
	match stage:
		0:
			return _objective_node("keycard")
		1:
			if inventory.scrap <= 0:
				return _objective_node("entry_scrap")
			if inventory.wire <= 0:
				return _objective_node("ops_wire")
			if inventory.fuse <= 0:
				return _objective_node("ops_fuse")
			return _objective_node("generator")
		2:
			return _objective_node("elevator")
		3:
			if inventory.cell <= 0:
				return _objective_node("cell")
			return _objective_node("pump")
		4:
			if inventory.lure > 0:
				return _objective_node("speaker")
			if inventory.scrap <= 0:
				return _objective_node("medical_scrap")
			if inventory.wire <= 0:
				return _objective_node("medical_wire")
			return _objective_node("speaker")
		5:
			if inventory.battery <= 0:
				return _objective_node("battery")
			return _objective_node("beacon")
	return null

func _objective_node(objective_id: String) -> Node3D:
	if objective_nodes.has(objective_id) and is_instance_valid(objective_nodes[objective_id]):
		return objective_nodes[objective_id]
	return null

func _objective_text() -> String:
	match stage:
		0: return "Recover Mara's maintenance keycard"
		1: return "Find generator parts for Echo Lock"
		2: return "Activate the freight elevator"
		3: return "Install the cell and drain the test shaft"
		4: return "Craft a tuned noise lure  [C]"
		5: return "Reach the ridge beacon and re-engage Echo Lock"
		_: return "Rescue signal and containment active"

func _update_tension() -> void:
	if mimic == null or not mimic.active:
		horror_audio.set_tension(0.12)
		return
	var distance := player.global_position.distance_to(mimic.global_position)
	var value := clampf(1.0 - (distance - 2.0) / 22.0, 0.18, 1.0)
	if mimic.is_chasing():
		value = 1.0
	horror_audio.set_tension(value)

func _check_scares() -> void:
	var z := player.global_position.z
	if stage >= 3 and z < -30.0 and not scare_flags.has("pump"):
		scare_flags["pump"] = true
		mimic.reveal_at(Vector3(-3.6, 0, -37.0))
		_trigger_scare("Soren's voice whispers from the pump tunnel: ‘Mara… don't turn around.’")
	if stage >= 3 and z < -30.0 and mimic.is_dormant() and mimic.search_timer <= 0.0:
		mimic.reveal_at(Vector3(3.2, 0, -39.0))
		_trigger_scare("The thing beside the pump folds its throat open and pulses the air.")
	if stage >= 4 and z < -50.0 and not scare_flags.has("medical"):
		scare_flags["medical"] = true
		_trigger_scare("A red emergency light bursts to life beyond the medical bay.")
	if stage >= 5 and z < -66.0 and not scare_flags.has("beacon"):
		scare_flags["beacon"] = true
		_trigger_scare("The Resonant screams through every speaker at once.")

func _trigger_scare(text_value: String) -> void:
	horror_audio.play_stinger()
	vignette.color = Color(0.7, 0.01, 0.0, 0.58)
	show_message(text_value, 4.0)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.color = Color(0.7, 0.0, 0.0, 0.0)
	layer.add_child(vignette)

	objective_label = _ui_label(Vector2(28, 24), Vector2(720, 36), 19, Color(0.72, 0.88, 0.94))
	tracker_label = _ui_label(Vector2(28, 50), Vector2(720, 30), 15, Color(0.20, 0.92, 0.76))
	rpg_label = _ui_label(Vector2(916, 20), Vector2(336, 72), 14, Color(0.74, 0.87, 0.91))
	rpg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	inventory_label = _ui_label(Vector2(28, 626), Vector2(650, 70), 15, Color(0.76, 0.82, 0.86))
	prompt_label = _ui_label(Vector2(380, 610), Vector2(520, 36), 18, Color(1.0, 0.78, 0.32))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label = _ui_label(Vector2(250, 80), Vector2(780, 90), 21, Color(0.94, 0.94, 0.96))
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	crosshair = _ui_label(Vector2(628, 344), Vector2(24, 30), 24, Color(0.8, 0.9, 0.95, 0.75))
	crosshair.text = "+"
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var hint := _ui_label(Vector2(936, 634), Vector2(320, 66), 14, Color(0.55, 0.64, 0.7))
	hint.text = "WASD MOVE  •  SHIFT RUN  •  SPACE VAULT\nE USE  •  C CRAFT  •  Q PULSE  •  F LIGHT\nLMB FIRE RIVETER"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _ui_label(position_value: Vector2, size_value: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position_value
	label.size = size_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	get_child(get_child_count() - 1).add_child(label)
	return label

func show_message(text_value: String, duration: float) -> void:
	if message_label == null:
		return
	message_label.text = text_value
	var shown_text := text_value
	await get_tree().create_timer(duration).timeout
	if message_label != null and message_label.text == shown_text:
		message_label.text = ""
