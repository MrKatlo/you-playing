class_name Mimic
extends CharacterBody3D

const REVEAL_SOUND := preload("res://assets/audio/mimic_reveal.ogg")
const MIMIC_MODEL_SCENE := preload("res://assets/models/characters/the_mimic.glb")

enum Mode { DORMANT, STALK, INVESTIGATE, CHASE, LURED }

var active := false
var mode := Mode.DORMANT
var target := Vector3.ZERO
var home := Vector3(0, 0, -37)
var search_timer := 0.0
var stalk_timer := 0.0
var sound_trail_age := 999.0
var sound_strength := 0.0
var last_sound_position := Vector3.ZERO
var search_step_timer := 0.0
var echo_pulse_timer := 0.0
var echo_pulse_flash := 0.0
var stagger_timer := 0.0
var animation_clock := 0.0
var scan_hint_given := false
var collision_shape: CollisionShape3D
var body_pivot: Node3D
var resonator_throat: Node3D
var reveal_player: AudioStreamPlayer3D
var rig_nodes: Dictionary = {}
var stalk_points: Array[Vector3] = [Vector3(-3.8, 0, -35), Vector3(3.5, 0, -52), Vector3(-3.4, 0, -55), Vector3(0, 0, -69)]

func _ready() -> void:
	name = "TheMimic"
	global_position = home
	collision_shape = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.42
	shape.height = 2.28
	collision_shape.shape = shape
	collision_shape.position.y = 1.14
	add_child(collision_shape)

	body_pivot = Node3D.new()
	add_child(body_pivot)
	var visual := MIMIC_MODEL_SCENE.instantiate()
	visual.scale = Vector3(0.84, 0.84, 0.84)
	body_pivot.add_child(visual)
	resonator_throat = visual.find_child("ResonatorThroat", true, false) as Node3D
	_cache_rig_nodes(visual)
	_set_body_visible(false)
	collision_shape.disabled = true
	reveal_player = AudioStreamPlayer3D.new()
	reveal_player.stream = REVEAL_SOUND
	reveal_player.volume_db = -5.0
	reveal_player.max_distance = 28.0
	add_child(reveal_player)

func awaken() -> void:
	# The player does not see it until a later story beat.
	active = true
	mode = Mode.DORMANT
	search_timer = 4.0
	sound_trail_age = 999.0
	echo_pulse_timer = 3.5

func reveal_at(reveal_position: Vector3) -> void:
	if not active:
		return
	global_position = reveal_position
	velocity = Vector3.ZERO
	_set_body_visible(true)
	collision_shape.set_deferred("disabled", false)
	reveal_player.play()
	mode = Mode.STALK
	stalk_timer = 2.8
	target = reveal_position
	sound_trail_age = 999.0
	echo_pulse_timer = 2.3

func hear(noise_position: Vector3, radius: float) -> void:
	if not active or mode == Mode.DORMANT or mode == Mode.LURED:
		return
	# The Resonant has poor eyes. It receives a location only when a real sound
	# reaches it; it never gets the player's live position from a distance.
	if global_position.distance_to(noise_position) > radius:
		return
	last_sound_position = noise_position
	target = noise_position
	sound_trail_age = 0.0
	sound_strength = radius
	search_timer = 5.0
	if radius >= 9.0:
		mode = Mode.CHASE
	else:
		if mode != Mode.CHASE:
			mode = Mode.INVESTIGATE

func divert(noise_position: Vector3) -> void:
	if not active:
		return
	_set_body_visible(true)
	collision_shape.set_deferred("disabled", false)
	target = noise_position
	mode = Mode.LURED
	search_timer = 12.0
	sound_trail_age = 999.0

func take_rivet_hit(from_position: Vector3) -> void:
	# A rivet cannot kill the Resonant, but it can rock it back and make it come on.
	if not active:
		awaken()
	_set_body_visible(true)
	collision_shape.set_deferred("disabled", false)
	echo_pulse_flash = 1.0
	stagger_timer = 0.55
	velocity = (global_position - from_position).normalized() * 3.2
	mode = Mode.CHASE
	last_sound_position = from_position
	target = from_position
	sound_trail_age = 0.0
	search_timer = 6.5

func reset_after_capture() -> void:
	global_position = home
	velocity = Vector3.ZERO
	active = true
	mode = Mode.DORMANT
	search_timer = 5.0
	sound_trail_age = 999.0
	echo_pulse_timer = 3.5
	_set_body_visible(false)
	collision_shape.set_deferred("disabled", true)

func freeze_for_capture() -> void:
	active = false
	velocity = Vector3.ZERO
	_set_body_visible(false)
	collision_shape.set_deferred("disabled", true)

func is_chasing() -> bool:
	return mode == Mode.CHASE

func is_dormant() -> bool:
	return mode == Mode.DORMANT

func _physics_process(delta: float) -> void:
	if not active:
		return
	var game := get_parent()
	var runner: SignalRunner = game.player
	if runner == null or not runner.can_move:
		return
	animation_clock += delta
	echo_pulse_flash = maxf(0.0, echo_pulse_flash - delta * 2.4)
	if stagger_timer > 0.0:
		stagger_timer -= delta
		velocity = velocity.move_toward(Vector3.ZERO, delta * 7.5)
		move_and_slide()
		_animate_body(delta)
		return
	if mode == Mode.DORMANT:
		search_timer -= delta
		_animate_body(delta)
		return

	sound_trail_age += delta
	_run_echo_scan(delta, runner, game)
	if mode == Mode.CHASE:
		# Chase the latest loud sound, not the player's invisible current location.
		if sound_trail_age <= 2.35:
			_move_to(last_sound_position, 4.7)
		else:
			_begin_search()
	elif mode == Mode.INVESTIGATE:
		search_timer -= delta
		if global_position.distance_to(target) > 0.85:
			_move_to(target, 2.65)
		else:
			velocity = Vector3.ZERO
			search_step_timer -= delta
			if search_step_timer <= 0.0 and search_timer > 0.8:
				# It prowls around the last heard place rather than instantly forgetting.
				target = last_sound_position + Vector3(randf_range(-1.15, 1.15), 0, randf_range(-1.15, 1.15))
				search_step_timer = randf_range(0.75, 1.3)
		if search_timer <= 0.0:
			_begin_stalk()
	elif mode == Mode.LURED:
		_move_to(target, 5.2)
		if global_position.distance_to(target) < 1.0:
			_set_body_visible(false)
			collision_shape.set_deferred("disabled", true)
			mode = Mode.DORMANT
			search_timer = 15.0
	elif mode == Mode.STALK:
		stalk_timer -= delta
		if stalk_timer <= 0.0:
			_begin_stalk()
		elif global_position.distance_to(target) <= 0.75:
			# A stalking Resonant settles at a listening perch; it does not pace
			# back and forth on a fixed patrol route.
			velocity = Vector3.ZERO
		else:
			_move_to(target, 1.35)

	var distance := global_position.distance_to(runner.global_position)
	if not runner.is_hidden and distance < 1.35 and mode in [Mode.CHASE, Mode.INVESTIGATE]:
		game.player_caught()
	_animate_body(delta)

func _begin_stalk() -> void:
	mode = Mode.STALK
	target = stalk_points[randi() % stalk_points.size()]
	for attempt in 4:
		var candidate: Vector3 = stalk_points[randi() % stalk_points.size()]
		if candidate.distance_to(global_position) > 3.2:
			target = candidate
			break
	stalk_timer = randf_range(6.0, 10.0)
	search_step_timer = 0.0

func _begin_search() -> void:
	mode = Mode.INVESTIGATE
	target = last_sound_position
	search_timer = 4.6
	search_step_timer = 0.7

func _run_echo_scan(delta: float, runner: SignalRunner, game: Node) -> void:
	if mode == Mode.LURED:
		return
	echo_pulse_timer -= delta
	if echo_pulse_timer > 0.0:
		return
	echo_pulse_timer = randf_range(5.0, 7.4)
	echo_pulse_flash = 1.0
	if global_position.distance_to(runner.global_position) <= 24.0 and game.horror_audio != null:
		game.horror_audio.play_echo_pulse()
	var runner_speed := Vector2(runner.velocity.x, runner.velocity.z).length()
	if global_position.distance_to(runner.global_position) <= 15.5 and runner_speed > 0.32:
		# A pulse finds movement only in the local tunnel. Staying still breaks it.
		hear(runner.global_position, 15.5)
		if not scan_hint_given:
			scan_hint_given = true
			game.show_message("The throat folds pulse through the tunnel. Stay still, or it will hear you.", 3.4)

func _move_to(destination: Vector3, speed: float) -> void:
	var flat_target := Vector3(destination.x, global_position.y, destination.z)
	var direction := global_position.direction_to(flat_target)
	velocity = Vector3(direction.x * speed, -0.1, direction.z * speed)
	if Vector2(direction.x, direction.z).length() > 0.05:
		look_at(Vector3(destination.x, global_position.y, destination.z), Vector3.UP, true)
	move_and_slide()

func _cache_rig_nodes(visual: Node) -> void:
	for joint_name in ["Hips", "Spine", "HeadPivot", "ArmLUpper", "ArmLFore", "ArmRUpper", "ArmRFore", "LegLUpper", "LegLLower", "LegLAnkle", "LegRUpper", "LegRLower", "LegRAnkle"]:
		var joint := visual.find_child(joint_name, true, false) as Node3D
		if joint != null:
			rig_nodes[joint_name] = joint

func _joint(joint_name: String) -> Node3D:
	return rig_nodes.get(joint_name, null) as Node3D

func _animate_body(_delta: float) -> void:
	if body_pivot == null:
		return
	var speed_factor := 0.0
	var cadence := 1.45
	if mode == Mode.STALK:
		speed_factor = 0.34 if Vector2(velocity.x, velocity.z).length() > 0.15 else 0.0
		cadence = 2.1
	elif mode == Mode.INVESTIGATE:
		speed_factor = 0.56 if Vector2(velocity.x, velocity.z).length() > 0.15 else 0.0
		cadence = 3.1
	elif mode in [Mode.CHASE, Mode.LURED]:
		speed_factor = 1.0
		cadence = 7.2 if mode == Mode.CHASE else 5.7
	var gait := sin(animation_clock * cadence)
	var counter_gait := cos(animation_clock * cadence)
	var sway := sin(animation_clock * 1.25)
	body_pivot.position.y = absf(sin(animation_clock * cadence * 0.5)) * 0.055 * speed_factor
	body_pivot.rotation.z = sway * (0.024 + speed_factor * 0.035)

	var hips := _joint("Hips")
	var spine := _joint("Spine")
	var head := _joint("HeadPivot")
	if hips != null:
		hips.rotation = Vector3(gait * 0.045 * speed_factor, 0.0, counter_gait * 0.035 * speed_factor)
	if spine != null:
		spine.rotation = Vector3(-0.05 - speed_factor * 0.13 + sway * 0.025, sway * 0.06, 0.0)
	if head != null:
		var listening_turn := sin(animation_clock * 1.7) * 0.20 if mode == Mode.INVESTIGATE else sin(animation_clock * 0.72) * 0.07
		head.rotation = Vector3(-0.06, listening_turn, 0.0)

	_set_limb_pose("ArmLUpper", "ArmLFore", gait, speed_factor, -1.0)
	_set_limb_pose("ArmRUpper", "ArmRFore", gait, speed_factor, 1.0)
	_set_leg_pose("LegLUpper", "LegLLower", "LegLAnkle", gait, speed_factor, -1.0)
	_set_leg_pose("LegRUpper", "LegRLower", "LegRAnkle", gait, speed_factor, 1.0)

	if resonator_throat != null:
		var agitation := 0.028 + speed_factor * 0.075 + echo_pulse_flash * 0.22
		var pulse := sin(animation_clock * (3.2 + speed_factor * 4.5)) * agitation + echo_pulse_flash * 0.13
		resonator_throat.scale = Vector3(1.0 + pulse, 1.0 - pulse * 0.20, 1.0 + pulse * 0.6)

func _set_limb_pose(upper_name: String, fore_name: String, gait: float, speed_factor: float, side: float) -> void:
	var upper := _joint(upper_name)
	var fore := _joint(fore_name)
	var arm_swing := gait * (0.12 + speed_factor * 0.42) * side
	if upper != null:
		upper.rotation = Vector3(arm_swing, 0.0, side * (0.08 + speed_factor * 0.10))
	if fore != null:
		fore.rotation = Vector3(-0.18 - absf(gait) * speed_factor * 0.30, 0.0, side * 0.035)

func _set_leg_pose(upper_name: String, lower_name: String, ankle_name: String, gait: float, speed_factor: float, side: float) -> void:
	var upper := _joint(upper_name)
	var lower := _joint(lower_name)
	var ankle := _joint(ankle_name)
	var stride := gait * (0.05 + speed_factor * 0.34) * side
	if upper != null:
		upper.rotation = Vector3(stride, 0.0, side * 0.025)
	if lower != null:
		lower.rotation = Vector3(-0.20 - maxf(0.0, gait * side) * speed_factor * 0.38, 0.0, 0.0)
	if ankle != null:
		ankle.rotation = Vector3(0.12 + maxf(0.0, -gait * side) * speed_factor * 0.22, 0.0, 0.0)

func _set_body_visible(is_visible: bool) -> void:
	body_pivot.visible = is_visible
