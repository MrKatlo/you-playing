class_name SignalRunner
extends CharacterBody3D

const WALK_SPEED := 3.4
const RUN_SPEED := 5.8
const GRAVITY := 18.0
const JUMP_VELOCITY := 5.1
const MOUSE_SENSITIVITY := 0.0022
const FOOTSTEP_SOUNDS := [
	preload("res://assets/audio/footstep_00.ogg"),
	preload("res://assets/audio/footstep_02.ogg"),
	preload("res://assets/audio/footstep_06.ogg"),
	preload("res://assets/audio/footstep_09.ogg")
]

# The survivor's body is a resource like heat and food. A bite or a pounce
# spends it; the HUD bar is the only readout, so the damage stays legible
# without turning the screen into a spreadsheet.
const MAX_HEALTH := 100.0
const HURT_INVULNERABLE := 0.9
# The step is the answer to the telegraphed pounce. It is short, it costs noise,
# and its invulnerability window is deliberately shorter than the movement, so a
# late step eats the hit and an early one leaves you standing in the recovery
# window with the blade already up.
const DODGE_SPEED := 9.4
const DODGE_TIME := 0.30
const DODGE_COOLDOWN := 0.95
const DODGE_INVULNERABLE := 0.22
var health := MAX_HEALTH
var invulnerable := 0.0
var downed := false
var flashlight_on := true
var flashlight_acquired := false
var flashlight_charge := 100.0
var riveter_equipped := false
var machete_equipped := false
var riveter_cooldown := 0.0
var footstep_distance := 0.0
var head_time := 0.0
var dodge_left := 0.0
var dodge_cooldown := 0.0
var dodge_direction := Vector3.ZERO
var dodge_lean := 0.0
# The cinder variant's shove, and nothing else, uses these.
var push_left := 0.0
var push_velocity := Vector3.ZERO
var can_move := true
var is_hidden := false
var flashlight_before_hiding := true
var cinematic_locked := false
var rail_riding := false
var cinematic_collision_mask := 1
var camera_recoil := Vector2.ZERO
var muzzle_light: OmniLight3D
var riveter_view: Node3D
var riveter_kick := 0.0
var machete_view: Node3D
var machete_swing := 0.0
var machete_attack_kind := ""
var machete_attack_elapsed := -1.0
var machete_attack_duration := 0.0
var machete_attack_hit_sent := false
var machete_recovery := 0.0
var machete_last_attack := ""
var machete_combo_index := 0
var machete_draw_amount := 0.0
var machete_draw_target := 0.0
var torch_view: Node3D
var lantern_view: Node3D
var net_view: Node3D
var net_carried := false
var link_carried := false
var link_install_active := false
var using_gamepad := false
var link_view: Node3D = null
var lantern_low := false
var lantern_phase := 0.0
var lantern_swing := 0.0
var lantern_flicker := 0.0
var lantern_view_rest := Vector3(-0.46, -0.80, -0.58)
var lantern_view_rotation := Vector3(deg_to_rad(12.0), deg_to_rad(-30.0), deg_to_rad(8.0))
var net_sweep := 1.0
# C2.7 // the net shares the right-hand carry with the blade and the bolt
# driver. On the left it crowded the torch and the belt lantern, which already
# own that corner of the screen.
var net_view_rest := Vector3(0.34, -0.42, -0.56)
var net_view_rotation := Vector3(deg_to_rad(-60.0), deg_to_rad(40.0), deg_to_rad(20.0))
var net_view_stowed := Vector3(0.50, -0.56, -0.60)
var net_view_stowed_rotation := Vector3(deg_to_rad(-44.0), deg_to_rad(62.0), deg_to_rad(40.0))
const GLAND_LANTERN_MODEL := preload("res://assets/models/basement/generated/props/gland_lantern.glb")
const CRICKET_NET_MODEL := preload("res://assets/models/basement/generated/props/cricket_net.glb")
var torch_lens: StandardMaterial3D
var riveter_bolt: MeshInstance3D
var riveter_lever: MeshInstance3D
var reload_anim := 0.0
var active_slot := 1
var riveter_view_rotation := Vector3(deg_to_rad(-7.0), deg_to_rad(8.0), deg_to_rad(2.0))
var torch_rotation_rest := Vector3(deg_to_rad(-4.0), deg_to_rad(14.0), deg_to_rad(-6.0))
var torch_rotation_present := Vector3(deg_to_rad(-2.0), deg_to_rad(3.0), deg_to_rad(-2.0))
const SLOT_EMPTY := 0
const SLOT_MACHETE := 1
const SLOT_TORCH := 2
const SLOT_DRIVER := 3
const SLOT_NET := 4
const SLOT_LINK := 5
const RIVETER_VIEW_REST := Vector3(0.25, -0.255, -0.60)
const MACHETE_VIEW_REST := Vector3(0.30, -0.34, -0.52)
const NET_SWEEP_SECONDS := 0.55
const TORCH_VIEW_REST := Vector3(-0.27, -0.23, -0.46)
const TORCH_VIEW_PRESENT := Vector3(-0.15, -0.17, -0.35)
const MACHETE_DRAW_SPEED := 7.5
const MACHETE_ATTACK_ORDER := ["horizontal", "diagonal", "thrust"]

var head: Node3D
var camera: Camera3D
var flashlight: SpotLight3D
# The gland lantern is a body-centred warm circle, not a cone: the pocket is
# worked by feel and the paper slot has to be visible from the side.
var lantern: OmniLight3D
var footstep_player: AudioStreamPlayer

func _ready() -> void:

	name = "Player"
	var body := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.34
	capsule.height = 1.7
	body.shape = capsule
	body.position.y = 0.85
	add_child(body)

	head = Node3D.new()
	head.position.y = 1.55
	add_child(head)

	camera = Camera3D.new()
	camera.current = true
	camera.fov = 74.0
	camera.near = 0.05
	head.add_child(camera)

	flashlight = SpotLight3D.new()
	flashlight.light_color = Color(0.72, 0.84, 1.0)
	flashlight.light_energy = 4.2
	flashlight.spot_range = 18.0
	flashlight.spot_angle = 25.0
	flashlight.shadow_enabled = true
	flashlight.position = Vector3(0.12, -0.12, -0.15)
	camera.add_child(flashlight)
	flashlight.visible = false
	lantern = OmniLight3D.new()
	lantern.light_color = Color(1.0, 0.63, 0.30)
	lantern.light_energy = 2.4
	lantern.omni_range = 6.0
	lantern.omni_attenuation = 1.3
	lantern.shadow_enabled = false
	lantern.position = Vector3(-0.24, 1.15, -0.18)
	add_child(lantern)
	lantern.visible = false

	muzzle_light = OmniLight3D.new()
	muzzle_light.light_color = Color(1.0, 0.82, 0.55)
	muzzle_light.light_energy = 0.0
	muzzle_light.omni_range = 6.0
	muzzle_light.shadow_enabled = false
	muzzle_light.position = Vector3(0.16, -0.10, -0.50)
	camera.add_child(muzzle_light)
	_build_riveter_view()
	_build_machete_view()
	_build_torch_view()
	_build_lantern_view()
	_build_net_view()
	_build_link_view()

	footstep_player = AudioStreamPlayer.new()
	footstep_player.volume_db = -8.0
	add_child(footstep_player)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func observe_input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.25):
		using_gamepad = true
	elif event is InputEventKey or event is InputEventMouseButton or (event is InputEventMouseMotion and event.relative.length() > 2.0):
		using_gamepad = false


func _input(event: InputEvent) -> void:
	observe_input(event)


func _update_controller_look(delta: float) -> void:
	if not InputMap.has_action("look_left") or cinematic_locked or rail_riding or not can_move or get_tree().paused:
		return
	var stick := Input.get_vector("look_left", "look_right", "look_up", "look_down")
	if stick.length() < 0.01:
		return
	using_gamepad = true
	rotate_y(-stick.x * absf(stick.x) * delta * 2.5)
	head.rotation.x = clampf(head.rotation.x - stick.y * absf(stick.y) * delta * 2.0, deg_to_rad(-78.0), deg_to_rad(78.0))


func cycle_owned_tool() -> void:
	for offset in 5:
		var candidate: int = ((active_slot + offset) % 5) + 1
		if owns_slot(candidate) and select_slot(candidate):
			return


func _unhandled_input(event: InputEvent) -> void:
	if rail_riding:
		_get_game().rail.handle_input(event)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not cinematic_locked:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-78.0), deg_to_rad(78.0))
	if event.is_action_pressed("pause"):
		_get_game().toggle_pause_menu()
	if cinematic_locked or link_install_active:
		return
	if InputMap.has_action("cycle_tool") and event.is_action_pressed("cycle_tool") and can_move:
		cycle_owned_tool()
	if InputMap.has_action("drop_item") and event.is_action_pressed("drop_item") and active_slot == SLOT_LINK and can_move:
		_get_game()._drop_held_chain_link()
	if event.is_action_pressed("flashlight"):
		if not flashlight_acquired:
			_get_game().show_message("TORCH IS IN THE BEDSIDE KIT.", 1.6)
		elif flashlight_charge > 0.0:
			var lit := toggle_torch()
			_get_game().show_message("TORCH %s" % ("ON" if lit else "OFF"), 1.2)
	if InputMap.has_action("lantern") and event.is_action_pressed("lantern"):
		if _get_game().has_method("player_lantern_click"):
			_get_game().player_lantern_click()
	if InputMap.has_action("holster") and event.is_action_pressed("holster") and can_move:
		if _get_game().has_method("player_holster"):
			_get_game().player_holster()
	# Number keys pick the tool in the right hand. The torch is always the left
	# hand, so its slot simply lowers both right-hand tools and raises the beam.
	for slot_index in [SLOT_MACHETE, SLOT_TORCH, SLOT_DRIVER, SLOT_NET, SLOT_LINK]:
		var slot_action := "slot_%d" % slot_index
		if InputMap.has_action(slot_action) and event.is_action_pressed(slot_action):
			if _get_game().has_method("player_select_slot"):
				_get_game().player_select_slot(slot_index)
	if event.is_action_pressed("interact"):
		_get_game().player_interact()
	if event.is_action_pressed("craft") and can_move:
		_get_game().player_craft()
	if event.is_action_pressed("pulse") and can_move:
		_get_game().player_pulse()
	if can_move and InputMap.has_action("fire") and event.is_action_pressed("fire"):
		_get_game().player_fire()
	if can_move and InputMap.has_action("dodge") and event.is_action_pressed("dodge"):
		try_dodge()


## A committed sidestep in the held direction, or straight back with no input.
## Returns true when a step actually started, so tools and tests can tell the
## difference between "dodged" and "still on cooldown".
func try_dodge() -> bool:
	if downed or not can_move or dodge_left > 0.0 or dodge_cooldown > 0.0 or health <= 0.0:
		return false
	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := transform.basis * Vector3(move_input.x, 0.0, move_input.y)
	direction.y = 0.0
	if direction.length() < 0.15:
		# No stick input: the step goes straight back, away from the camera aim.
		direction = transform.basis.z
	dodge_direction = direction.normalized()
	dodge_left = DODGE_TIME
	dodge_cooldown = DODGE_COOLDOWN
	invulnerable = maxf(invulnerable, DODGE_INVULNERABLE)
	# The lean reads the direction of the step without moving the camera's aim.
	dodge_lean = clampf(-dodge_direction.dot(transform.basis.x), -1.0, 1.0) * 0.055
	_dodge_footstep()
	_get_game().make_noise(global_position, 9.0, "dodge")
	return true


func _dodge_footstep() -> void:
	if footstep_player == null or FOOTSTEP_SOUNDS.is_empty():
		return
	footstep_player.stream = FOOTSTEP_SOUNDS[randi() % FOOTSTEP_SOUNDS.size()]
	footstep_player.pitch_scale = randf_range(1.06, 1.16)
	footstep_player.volume_db = -5.0
	footstep_player.play()

func _physics_process(delta: float) -> void:
	_update_controller_look(delta)
	invulnerable = maxf(0.0, invulnerable - delta)
	dodge_cooldown = maxf(0.0, dodge_cooldown - delta)
	dodge_lean = move_toward(dodge_lean, 0.0, delta * 0.34)
	riveter_cooldown = maxf(0.0, riveter_cooldown - delta)
	camera_recoil = camera_recoil.lerp(Vector2.ZERO, minf(1.0, delta * 9.5))
	camera.rotation.x = camera_recoil.x
	camera.rotation.z = camera_recoil.y + dodge_lean
	riveter_kick = move_toward(riveter_kick, 0.0, delta * 0.42)
	reload_anim = maxf(0.0, reload_anim - delta * 1.9)
	_update_hand_views(delta)
	if muzzle_light != null and muzzle_light.light_energy > 0.0:
		muzzle_light.light_energy = maxf(0.0, muzzle_light.light_energy - delta * 52.0)
	if not can_move:
		return
	if push_left > 0.0:
		# A landed strike on the cinder variant is felt as the creature throwing
		# the hunter back, not as a wound. Steering is out of the player's hands
		# until the shove is spent, so the hit costs ground that must be retaken.
		push_left = maxf(0.0, push_left - delta)
		if push_left <= 0.0:
			# The shove is a measured distance, not a slide: it stops dead when spent
			# instead of bleeding another half metre off its own momentum.
			push_velocity = Vector3.ZERO
			velocity = Vector3.ZERO
			move_and_slide()
			return
		velocity.x = push_velocity.x
		velocity.z = push_velocity.z
		if not is_on_floor():
			velocity.y -= GRAVITY * delta
		else:
			velocity.y = -0.2
		move_and_slide()
		return
	var move_input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(move_input.x, 0.0, move_input.y)).normalized()
	var running := Input.is_action_pressed("sprint") and move_input.length() > 0.1
	var speed := RUN_SPEED if running else WALK_SPEED
	if dodge_left > 0.0:
		# The step overrides steering for its whole duration: you commit to a
		# direction and the body carries it. Speed bleeds off so the last frames
		# settle instead of stopping dead.
		dodge_left = maxf(0.0, dodge_left - delta)
		var step_speed := DODGE_SPEED * (0.28 + 0.72 * (dodge_left / DODGE_TIME))
		velocity.x = dodge_direction.x * step_speed
		velocity.z = dodge_direction.z * step_speed
		running = true
	elif direction:
		velocity.x = direction.x * speed * move_input.length()
		velocity.z = direction.z * speed * move_input.length()
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * 8.0 * delta)
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		if Input.is_action_just_pressed("jump"):
			velocity.y = JUMP_VELOCITY
			_get_game().make_noise(global_position, 7.0, "vault")
		else:
			velocity.y = -0.2
	move_and_slide()

	if flashlight_on:
		flashlight_charge = maxf(0.0, flashlight_charge - delta * 0.32)
		if flashlight_charge <= 0.0:
			flashlight_on = false
			flashlight.visible = false
			_update_torch_lens()
			_get_game().show_message("FLASHLIGHT BATTERY DEPLETED", 2.5)

	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	if horizontal_speed > 0.2 and is_on_floor():
		footstep_distance += horizontal_speed * delta
		head_time += delta * (10.0 if running else 7.0)
		head.position.y = 1.55 + sin(head_time) * 0.025
		if footstep_distance > (1.2 if running else 1.75):
			footstep_distance = 0.0
			_play_footstep(running)
			_get_game().make_noise(global_position, 12.0 if running else 5.0, "footstep")
	else:
		head.position.y = lerpf(head.position.y, 1.55, delta * 8.0)

func _update_hand_views(delta: float) -> void:
	_update_machete_view(delta)
	if riveter_view != null:
		# The driver only appears once the blade has cleared the right hand.  This
		# avoids the old one-frame overlap where both tools occupied the camera.
		riveter_view.visible = riveter_equipped and active_slot == SLOT_DRIVER and machete_draw_amount <= 0.025
		# The reload stroke: the sleeve runs back, the side lever cocks, and the
		# whole tool dips so the cycle reads in first person.
		var stroke: float = sin((1.0 - clampf(reload_anim, 0.0, 1.0)) * PI) if reload_anim > 0.0 else 0.0
		riveter_view.position = RIVETER_VIEW_REST + Vector3(0, sin(head_time * 0.5) * 0.004, riveter_kick + 0.045 * stroke)
		riveter_view.rotation = riveter_view_rotation + Vector3(-0.24 * stroke, 0.10 * stroke, 0.16 * stroke)
		if riveter_bolt != null:
			riveter_bolt.position = Vector3(0.0, 0.01, -0.36 + 0.105 * stroke)
		if riveter_lever != null:
			riveter_lever.rotation = Vector3(-1.25 * stroke, 0.0, 0.0)
	if torch_view != null:
		var presenting := active_slot == SLOT_TORCH
		var weight := minf(1.0, delta * 9.0)
		torch_view.position = torch_view.position.lerp(TORCH_VIEW_PRESENT if presenting else TORCH_VIEW_REST, weight)
		torch_view.rotation = torch_view.rotation.lerp(torch_rotation_present if presenting else torch_rotation_rest, weight)
	if net_view != null:
		# A woven net stays on the player at all times. Slot four draws it up into
		# the netting grip; any other slot parks it low by the hip, clear of the
		# blade and the driver, which share the same right-hand corner.
		var carrying: bool = net_carried
		var drawn: bool = carrying and active_slot == SLOT_NET
		net_view.visible = carrying
		if link_view != null:
			link_view.visible = link_carried and active_slot == SLOT_LINK and not link_install_active
		if drawn and net_sweep < 1.0:
			_update_net_sweep(delta)
		elif carrying:
			var settle: float = minf(1.0, delta * 10.0)
			var target_position: Vector3 = net_view_rest if drawn else net_view_stowed
			var target_rotation: Vector3 = net_view_rotation if drawn else net_view_stowed_rotation
			net_view.position = net_view.position.lerp(target_position, settle)
			net_view.rotation = net_view.rotation.lerp(target_rotation, settle)
			if drawn:
				var sway: float = sin(lantern_phase * 0.92) * 0.016 * lantern_swing
				net_view.position += Vector3(sway, absf(sway) * 0.7, 0.0)
				net_view.rotation += Vector3(0.0, 0.0, sway * 2.5)
	_update_lantern_view(delta)


func _update_machete_view(delta: float) -> void:
	if machete_view == null:
		return
	_advance_machete_attack(delta)
	var movement_amount: float = clampf(Vector2(velocity.x, velocity.z).length() / RUN_SPEED, 0.0, 1.0)
	var time_value: float = float(Time.get_ticks_msec()) * 0.001
	var idle_position := MACHETE_VIEW_REST + Vector3(
		sin(time_value * 4.2) * (0.003 + 0.010 * movement_amount),
		cos(time_value * 7.3) * 0.003 + absf(sin(time_value * 7.3)) * 0.008 * movement_amount,
		cos(time_value * 4.2) * 0.004 * movement_amount)
	var idle_rotation := Vector3(
		deg_to_rad(-16.0 + sin(time_value * 4.2) * 1.0 * movement_amount),
		deg_to_rad(20.0 + cos(time_value * 4.2) * 1.8 * movement_amount),
		deg_to_rad(10.0 + sin(time_value * 7.3) * 1.5 * movement_amount))
	var position_value: Vector3 = idle_position
	var rotation_value: Vector3 = idle_rotation
	if not machete_attack_kind.is_empty() and machete_attack_duration > 0.0:
		var progress: float = clampf(machete_attack_elapsed / machete_attack_duration, 0.0, 1.0)
		match machete_attack_kind:
			"horizontal":
				# Keep the broad cut just beyond the near plane. The older prototype
				# rolled the entire mesh into the camera, which filled the view with an
				# unreadable black triangle instead of a forceful horizontal slash.
				var horizontal_prep := Vector3(0.45, -0.18, -0.72)
				var horizontal_prep_rotation := Vector3(deg_to_rad(-38.0), deg_to_rad(32.0), deg_to_rad(30.0))
				var horizontal_cut := Vector3(-0.05, -0.32, -0.74)
				var horizontal_cut_rotation := Vector3(deg_to_rad(-4.0), deg_to_rad(-20.0), deg_to_rad(-30.0))
				if progress < 0.22:
					var lift: float = _smooth_attack(progress / 0.22)
					position_value = idle_position.lerp(horizontal_prep, lift)
					rotation_value = idle_rotation.lerp(horizontal_prep_rotation, lift)
				elif progress < 0.57:
					var cut: float = _smooth_attack((progress - 0.22) / 0.35)
					position_value = horizontal_prep.lerp(horizontal_cut, cut)
					rotation_value = horizontal_prep_rotation.lerp(horizontal_cut_rotation, cut)
				else:
					var settle: float = _smooth_attack((progress - 0.57) / 0.43)
					position_value = horizontal_cut.lerp(idle_position, settle)
					rotation_value = horizontal_cut_rotation.lerp(idle_rotation, settle)
			"diagonal":
				var diagonal_prep := Vector3(0.42, -0.14, -0.72)
				var diagonal_prep_rotation := Vector3(deg_to_rad(-52.0), deg_to_rad(27.0), deg_to_rad(24.0))
				var diagonal_cut := Vector3(0.04, -0.42, -0.76)
				var diagonal_cut_rotation := Vector3(deg_to_rad(8.0), deg_to_rad(-24.0), deg_to_rad(-20.0))
				if progress < 0.26:
					var lift: float = _smooth_attack(progress / 0.26)
					position_value = idle_position.lerp(diagonal_prep, lift)
					rotation_value = idle_rotation.lerp(diagonal_prep_rotation, lift)
				elif progress < 0.62:
					var cut: float = _smooth_attack((progress - 0.26) / 0.36)
					position_value = diagonal_prep.lerp(diagonal_cut, cut)
					rotation_value = diagonal_prep_rotation.lerp(diagonal_cut_rotation, cut)
				else:
					var settle: float = _smooth_attack((progress - 0.62) / 0.38)
					position_value = diagonal_cut.lerp(idle_position, settle)
					rotation_value = diagonal_cut_rotation.lerp(idle_rotation, settle)
			"thrust":
				var thrust_prep := Vector3(0.28, -0.36, -0.62)
				var thrust_prep_rotation := Vector3(deg_to_rad(-18.0), deg_to_rad(8.0), deg_to_rad(4.0))
				var thrust_cut := Vector3(0.04, -0.28, -1.06)
				var thrust_cut_rotation := Vector3(deg_to_rad(-6.0), deg_to_rad(-4.0), deg_to_rad(-2.0))
				if progress < 0.23:
					var draw_back: float = _smooth_attack(progress / 0.23)
					position_value = idle_position.lerp(thrust_prep, draw_back)
					rotation_value = idle_rotation.lerp(thrust_prep_rotation, draw_back)
				elif progress < 0.48:
					var stab: float = _smooth_attack((progress - 0.23) / 0.25)
					position_value = thrust_prep.lerp(thrust_cut, stab)
					rotation_value = thrust_prep_rotation.lerp(thrust_cut_rotation, stab)
				else:
					var settle: float = _smooth_attack((progress - 0.48) / 0.52)
					position_value = thrust_cut.lerp(idle_position, settle)
					rotation_value = thrust_cut_rotation.lerp(idle_rotation, settle)
	machete_draw_target = 1.0 if machete_equipped and active_slot == SLOT_MACHETE else 0.0
	machete_draw_amount = move_toward(machete_draw_amount, machete_draw_target, delta * MACHETE_DRAW_SPEED)
	var holster: float = 1.0 - machete_draw_amount
	position_value += Vector3(0.20 * holster, -0.28 * holster, 0.28 * holster)
	rotation_value += Vector3(0.78 * holster, 0.30 * holster, -0.28 * holster)
	machete_view.position = position_value
	machete_view.rotation = rotation_value
	machete_view.visible = machete_equipped and (machete_draw_amount > 0.025 or machete_draw_target > 0.0)


func _advance_machete_attack(delta: float) -> void:
	machete_recovery = maxf(0.0, machete_recovery - delta)
	if machete_attack_kind.is_empty():
		machete_swing = 0.0
		return
	machete_attack_elapsed += delta
	var progress: float = clampf(machete_attack_elapsed / machete_attack_duration, 0.0, 1.0)
	machete_swing = 1.0 - progress
	if not machete_attack_hit_sent and progress >= _machete_hit_fraction(machete_attack_kind):
		machete_attack_hit_sent = true
		var game := _get_game()
		if game != null and game.has_method("player_machete_strike"):
			game.player_machete_strike(machete_attack_kind)
	if progress >= 1.0:
		machete_attack_kind = ""
		machete_attack_elapsed = -1.0
		machete_attack_duration = 0.0
		machete_swing = 0.0
		machete_recovery = 0.08


func _smooth_attack(value: float) -> float:
	var clamped: float = clampf(value, 0.0, 1.0)
	return clamped * clamped * (3.0 - 2.0 * clamped)


func _machete_hit_fraction(attack_kind: String) -> float:
	match attack_kind:
		"horizontal": return 0.40
		"diagonal": return 0.47
		"thrust": return 0.42
	return 0.45


func restore_at(checkpoint: Vector3) -> void:
	global_position = checkpoint
	velocity = Vector3.ZERO
	dodge_left = 0.0
	dodge_cooldown = 0.0
	dodge_lean = 0.0
	flashlight_charge = maxf(flashlight_charge, 35.0)
	is_hidden = false
	flashlight.visible = flashlight_on and flashlight_acquired
	_update_torch_lens()
	can_move = true


func set_flashlight_enabled(enabled: bool) -> void:
	flashlight_on = enabled and flashlight_charge > 0.0 and flashlight_acquired
	if flashlight != null:
		flashlight.visible = flashlight_on
	_update_torch_lens()


func set_flashlight_acquired(value: bool) -> void:
	flashlight_acquired = value
	if not flashlight_acquired:
		set_flashlight_enabled(false)
	elif flashlight != null:
		flashlight.visible = flashlight_on and flashlight_charge > 0.0
	_refresh_hand_visibility()
	_update_torch_lens()


func _update_torch_lens() -> void:
	if torch_lens == null:
		return
	var lit := flashlight_on and flashlight != null and flashlight.visible
	torch_lens.emission_energy_multiplier = 3.4 if lit else 0.0


func set_cinematic_locked(locked: bool) -> void:
	if locked == cinematic_locked:
		return
	cinematic_locked = locked
	velocity = Vector3.ZERO
	if locked:
		cinematic_collision_mask = collision_mask
		collision_mask = 0
		can_move = false
	else:
		collision_mask = cinematic_collision_mask
		can_move = true

func apply_shot_recoil(pitch: float, roll: float) -> void:
	camera_recoil += Vector2(pitch, roll)
	riveter_kick = 0.075
	reload_anim = 1.0
	if muzzle_light != null:
		muzzle_light.light_energy = 3.6


func apply_melee_impact() -> void:
	camera_recoil += Vector2(0.062, 0.014)


## A shove with no wound behind it: the cinder variant's weight throwing the hunter
## back a measured distance. It replaces steering for its short duration and then
## hands control straight back.
func apply_push(from_position: Vector3, distance: float) -> void:
	if downed or not can_move:
		return
	var away: Vector3 = global_position - from_position
	away.y = 0.0
	if away.length() < 0.01:
		away = -global_transform.basis.z
	away = away.normalized()
	const PUSH_TIME := 0.26
	push_left = PUSH_TIME
	push_velocity = away * (distance / PUSH_TIME)
	velocity = push_velocity


func take_damage(amount: float, from_position: Vector3 = Vector3.ZERO, knockback: float = 0.0) -> bool:
	if downed or invulnerable > 0.0 or health <= 0.0:
		return false
	health = maxf(0.0, health - amount)
	invulnerable = HURT_INVULNERABLE
	# The head snaps away from the hit instead of the camera being yanked in a
	# fixed direction, so the player reads where the creature came from.
	var away := Vector2(randf_range(-1.0, 1.0), -1.0)
	camera_recoil += away.normalized() * randf_range(0.075, 0.115)
	if knockback > 0.0 and from_position != Vector3.ZERO:
		var push := global_position - from_position
		push.y = 0.0
		if push.length() > 0.01:
			velocity = push.normalized() * knockback
	return true


func heal_to_full() -> void:
	health = MAX_HEALTH
	invulnerable = HURT_INVULNERABLE


func set_downed(value: bool) -> void:
	downed = value
	velocity = Vector3.ZERO
	dodge_left = 0.0
	dodge_cooldown = 0.0
	dodge_lean = 0.0
	set_cinematic_locked(value)
	if value:
		head.rotation.x = deg_to_rad(-52.0)
	else:
		head.rotation.x = 0.0


func play_riveter_reload() -> void:
	if riveter_equipped:
		reload_anim = 1.0


func _build_lantern_view() -> void:
	# The lantern hangs from the belt on the left, so the torch can stay in the
	# left hand and the blade in the right without the two models fighting.
	lantern_view = GLAND_LANTERN_MODEL.instantiate() as Node3D
	lantern_view.name = "HandLanternView"
	lantern_view.scale = Vector3(0.48, 0.48, 0.48)
	lantern_view.position = Vector3(-0.46, -0.80, -0.58)
	lantern_view.rotation = Vector3(deg_to_rad(12.0), deg_to_rad(-30.0), deg_to_rad(8.0))
	camera.add_child(lantern_view)
	lantern_view.visible = false


func _build_net_view() -> void:
	# The woven net is carried in the right hand with the blade and the driver,
	# hoop forward and shaft down past the wrist. It is on the player from the
	# moment it is woven; slot four draws it up from the stowed hip carry.
	net_view = CRICKET_NET_MODEL.instantiate() as Node3D
	net_view.name = "HandNetView"
	net_view.scale = Vector3(0.38, 0.38, 0.38)
	net_view.position = net_view_rest
	net_view.rotation = net_view_rotation
	camera.add_child(net_view)
	# The stock materials are tuned to be read across a room; a metre from the belt
	# lamp they blow out. The carried copy darkens every surface it shares, leaving
	# the bench prop with its original paint.
	# The stock thread is opaque and tuned to be read across a room; at arm's length
	# it becomes a pale bucket. The carried copy shows the gauze as see-through mesh
	# and leaves the shaft and hoop as they are.
	for node in net_view.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance: MeshInstance3D = node as MeshInstance3D
		if mesh_instance == null or mesh_instance.mesh == null:
			continue
		for index in mesh_instance.mesh.get_surface_count():
			var surface: StandardMaterial3D = mesh_instance.get_active_material(index) as StandardMaterial3D
			if surface == null:
				continue
			if not str(surface.resource_name).to_lower().contains("gauze"):
				continue
			var carried: StandardMaterial3D = surface.duplicate() as StandardMaterial3D
			carried.albedo_color = Color(0.72, 0.68, 0.56, 0.30)
			carried.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			carried.cull_mode = BaseMaterial3D.CULL_DISABLED
			carried.roughness = 0.96
			carried.emission_enabled = false
			mesh_instance.set_surface_override_material(index, carried)
	net_view.visible = false


func play_net_sweep() -> void:
	# Called when a tray is actually netted: raise the hoop, sweep it across the
	# sight line and bring it back to the carry.
	if net_view == null or not net_carried:
		return
	net_sweep = 0.0


func _update_net_sweep(delta: float) -> void:
	net_sweep = minf(1.0, net_sweep + delta / NET_SWEEP_SECONDS)
	var raised_position := Vector3(0.34, -0.28, -0.56)
	var raised_rotation := Vector3(deg_to_rad(-92.0), deg_to_rad(4.0), deg_to_rad(-6.0))
	var swept_position := Vector3(0.02, -0.36, -0.58)
	var swept_rotation := Vector3(deg_to_rad(-84.0), deg_to_rad(-24.0), deg_to_rad(16.0))
	if net_sweep < 0.30:
		var raise_amount: float = smoothstep(0.0, 0.30, net_sweep)
		net_view.position = net_view_rest.lerp(raised_position, raise_amount)
		net_view.rotation = net_view_rotation.lerp(raised_rotation, raise_amount)
	elif net_sweep < 0.62:
		var sweep_amount: float = smoothstep(0.30, 0.62, net_sweep)
		net_view.position = raised_position.lerp(swept_position, sweep_amount)
		net_view.rotation = raised_rotation.lerp(swept_rotation, sweep_amount)
	else:
		var settle_amount: float = smoothstep(0.62, 1.0, net_sweep)
		net_view.position = swept_position.lerp(net_view_rest, settle_amount)
		net_view.rotation = swept_rotation.lerp(net_view_rotation, settle_amount)


func set_net_carried(value: bool) -> void:
	net_carried = value
	if not value and active_slot == SLOT_NET:
		active_slot = SLOT_EMPTY
	if net_view != null:
		net_view.visible = value


func set_link_carried(value: bool) -> void:
	link_carried = value
	if not value and active_slot == SLOT_LINK:
		active_slot = SLOT_EMPTY
	if link_view != null:
		link_view.visible = value and active_slot == SLOT_LINK and not link_install_active


func _build_link_view() -> void:
	link_view = Node3D.new()
	link_view.name = "HandChainLinkView"
	link_view.position = Vector3(0.27, -0.27, -0.44)
	link_view.rotation = Vector3(-0.22, 0.15, -0.42)
	camera.add_child(link_view)
	link_view.add_child(preload("res://assets/models/basement/generated/props/replacement_chain_link.glb").instantiate())
	link_view.visible = false


func _update_lantern_view(delta: float) -> void:
	if lantern_view == null:
		return
	# The lamp hangs from the belt, so it swings with the stride and settles flat
	# when the player stops.
	var speed: float = Vector2(velocity.x, velocity.z).length()
	var walk_target: float = 1.0 if speed > 0.5 else 0.15
	lantern_swing = move_toward(lantern_swing, walk_target, delta * 2.4)
	lantern_phase += delta * (7.4 if speed > WALK_SPEED * 1.05 else 5.6) * (0.4 + 0.6 * lantern_swing)
	var sway: float = sin(lantern_phase) * 0.030 * lantern_swing
	var lift: float = absf(sin(lantern_phase)) * 0.022 * lantern_swing
	lantern_view.position = lantern_view_rest + Vector3(sway, lift, -absf(sway) * 0.35)
	lantern_view.rotation = lantern_view_rotation + Vector3(sway * 1.1, 0.0, -sway * 1.9)
	if lantern == null or not lantern.visible:
		lantern_flicker = 0.0
		return
	if not lantern_low:
		lantern.light_energy = move_toward(lantern.light_energy, 2.4, delta * 3.0)
		return
	# Low fuel: the flame gutter takes bites out of the light, with the odd catch.
	lantern_flicker += delta
	var stutter: float = sin(lantern_flicker * 21.0) * sin(lantern_flicker * 7.7 + 1.3)
	var catch: float = 1.0 if fmod(lantern_flicker, 2.9) > 2.62 else 0.0
	lantern.light_energy = 2.4 * clampf(0.46 + stutter * 0.30 + catch * 0.55, 0.22, 1.05)
	lantern_view.position += Vector3(0.0, sin(lantern_flicker * 37.0) * 0.0016, 0.0)


func set_lantern_low(value: bool) -> void:
	lantern_low = value


func set_lantern_carried(value: bool) -> void:
	if lantern_view != null:
		lantern_view.visible = value


func set_lantern_on(value: bool) -> void:
	if lantern == null:
		return
	lantern.visible = value


func toggle_torch() -> bool:
	if not flashlight_acquired or flashlight_charge <= 0.0:
		return flashlight_on
	flashlight_on = not flashlight_on
	flashlight.visible = flashlight_on
	_update_torch_lens()
	return flashlight_on


func owns_slot(slot: int) -> bool:
	match slot:
		SLOT_MACHETE:
			return machete_equipped
		SLOT_TORCH:
			return flashlight_acquired
		SLOT_DRIVER:
			return riveter_equipped
		SLOT_NET:
			return net_carried
		SLOT_LINK:
			return link_carried
	return false


func active_tool_label() -> String:
	match active_slot:
		SLOT_EMPTY:
			return "EMPTY HANDS"
		SLOT_MACHETE:
			return "MACHETE"
		SLOT_TORCH:
			return "HAND TORCH"
		SLOT_DRIVER:
			return "BOLT DRIVER"
		SLOT_NET:
			return "CRICKET NET"
		SLOT_LINK:
			return "CHAIN LINK"
	return "EMPTY HANDS"


func select_slot(slot: int) -> bool:
	if slot == SLOT_EMPTY:
		return put_away_right_hand()
	if not owns_slot(slot):
		return false
	if is_machete_busy() and slot != SLOT_MACHETE:
		return false
	active_slot = slot
	_refresh_hand_visibility()
	return true


func put_away_right_hand() -> bool:
	if is_machete_busy():
		return false
	active_slot = SLOT_EMPTY
	_refresh_hand_visibility()
	return true


func _ensure_valid_slot() -> void:
	if active_slot == SLOT_EMPTY:
		return
	if owns_slot(active_slot):
		return
	for candidate in [SLOT_MACHETE, SLOT_DRIVER, SLOT_TORCH, SLOT_NET, SLOT_LINK]:
		if owns_slot(candidate):
			active_slot = candidate
			return
	active_slot = SLOT_EMPTY


func _refresh_hand_visibility() -> void:
	# The right hand carries exactly one thing. The blade is allowed to finish a
	# short holster animation, then the driver is raised; they never overlap.
	_ensure_valid_slot()
	machete_draw_target = 1.0 if machete_equipped and active_slot == SLOT_MACHETE else 0.0
	if machete_view != null:
		if machete_equipped and machete_draw_target > 0.0:
			machete_view.visible = true
		elif not machete_equipped:
			machete_view.visible = false
	if riveter_view != null:
		riveter_view.visible = riveter_equipped and active_slot == SLOT_DRIVER and machete_draw_amount <= 0.025
	if torch_view != null:
		torch_view.visible = flashlight_acquired


func set_riveter_equipped(value: bool) -> void:
	riveter_equipped = value
	_refresh_hand_visibility()


func set_machete_equipped(value: bool) -> void:
	machete_equipped = value
	if not machete_equipped:
		machete_attack_kind = ""
		machete_attack_elapsed = -1.0
		machete_attack_duration = 0.0
		machete_recovery = 0.0
		machete_swing = 0.0
		machete_draw_amount = 0.0
		if active_slot == SLOT_MACHETE:
			active_slot = SLOT_EMPTY
	_refresh_hand_visibility()


func is_machete_attacking() -> bool:
	return not machete_attack_kind.is_empty()


func is_machete_busy() -> bool:
	return is_machete_attacking() or machete_recovery > 0.0



func begin_machete_attack(requested_attack: String = "") -> String:
	if not machete_equipped or active_slot != SLOT_MACHETE or is_machete_busy():
		return ""
	var attack_kind := requested_attack
	if not MACHETE_ATTACK_ORDER.has(attack_kind):
		attack_kind = str(MACHETE_ATTACK_ORDER[machete_combo_index % MACHETE_ATTACK_ORDER.size()])
		if attack_kind == machete_last_attack:
			machete_combo_index += 1
			attack_kind = str(MACHETE_ATTACK_ORDER[machete_combo_index % MACHETE_ATTACK_ORDER.size()])
	var attack_index: int = MACHETE_ATTACK_ORDER.find(attack_kind)
	machete_combo_index = (attack_index + 1) % MACHETE_ATTACK_ORDER.size()
	machete_last_attack = attack_kind
	machete_attack_kind = attack_kind
	machete_attack_elapsed = 0.0
	machete_attack_duration = _machete_duration_for(attack_kind)
	machete_attack_hit_sent = false
	machete_swing = 1.0
	return attack_kind


func _machete_duration_for(attack_kind: String) -> float:
	match attack_kind:
		"horizontal": return 0.50
		"diagonal": return 0.56
		"thrust": return 0.48
	return 0.50


func play_machete_swing() -> void:
	begin_machete_attack()

func _build_riveter_view() -> void:
	# A compact industrial riveter in the lower-right of the view. It uses the
	# same utilitarian forms as the pickup, so Mara carries a tool rather than a
	# generic military gun.
	riveter_view = Node3D.new()
	riveter_view.name = "MaintenanceRiveterView"
	riveter_view.position = RIVETER_VIEW_REST
	# The driver is compact but long, so it is held a little further out and
	# scaled down; otherwise its breech fills the lower-right corner of the view
	# and hides the reload stroke that sells the tool's weight.
	riveter_view.scale = Vector3(0.86, 0.86, 0.86)
	riveter_view.rotation = riveter_view_rotation
	camera.add_child(riveter_view)
	var steel := _weapon_material(Color(0.11, 0.15, 0.18), 0.32, 0.86)
	var housing := _weapon_material(Color(0.16, 0.21, 0.24), 0.48, 0.58)
	var copper := _weapon_material(Color(0.44, 0.13, 0.045), 0.30, 0.75)
	var status := _weapon_material(Color(0.10, 0.95, 0.66), 0.22, 0.25)
	status.emission_enabled = true
	status.emission = Color(0.025, 0.48, 0.24)
	status.emission_energy_multiplier = 1.4
	_weapon_part(_weapon_box(Vector3(0.19, 0.15, 0.43)), Vector3(0, 0.0, -0.02), housing)
	riveter_bolt = _weapon_part(_weapon_cylinder(0.052, 0.43), Vector3(0.0, 0.01, -0.36), steel, Vector3(PI * 0.5, 0, 0))
	riveter_lever = _weapon_part(_weapon_box(Vector3(0.030, 0.032, 0.150)), Vector3(0.116, -0.052, 0.015), copper)
	_weapon_part(_weapon_box(Vector3(0.12, 0.30, 0.13)), Vector3(0, -0.18, 0.08), steel, Vector3(-0.25, 0, 0))
	_weapon_part(_weapon_box(Vector3(0.11, 0.035, 0.16)), Vector3(0, 0.10, 0.06), status)
	# The rear cap sits back at the receiver instead of hugging the eye, so the
	# reload stroke stays readable in the lower-right corner of the view.
	_weapon_part(_weapon_cylinder(0.060, 0.16), Vector3(0, 0.0, 0.10), copper, Vector3(0, PI * 0.5, 0))
	_refresh_hand_visibility()


func _build_machete_view() -> void:
	# An old working machete rather than a clean sci-fi blade: its hand-ground
	# profile keeps a few small edge nicks, the steel is darkened and scarred,
	# and the full tang disappears into a worn timber-and-cord grip.
	machete_view = Node3D.new()
	machete_view.name = "BedsideMacheteView"
	machete_view.position = MACHETE_VIEW_REST
	machete_view.rotation = Vector3(deg_to_rad(-16.0), deg_to_rad(20.0), deg_to_rad(10.0))
	camera.add_child(machete_view)
	# The low metallic values matter: a mirror-finish blade picks up the room's
	# ambient light and reads as brand new, so the steel is dulled into a broad
	# matte sheen and the only bright surface is the worn edge bevel.
	# This room is lit hot enough that a "dark grey" albedo renders near white,
	# so the worn steel is specified much darker than it reads on screen.
	var steel := _weapon_material(Color(0.055, 0.062, 0.058), 0.86, 0.30)
	var bevel := _weapon_material(Color(0.150, 0.160, 0.145), 0.55, 0.55)
	var pitting := _weapon_material(Color(0.100, 0.032, 0.011), 0.97, 0.05)
	var scratch := _weapon_material(Color(0.105, 0.112, 0.100), 0.66, 0.40)
	var grime := _weapon_material(Color(0.018, 0.019, 0.017), 0.98, 0.03)
	var timber := _weapon_material(Color(0.052, 0.030, 0.015), 0.95, 0.0)
	var cord := _weapon_material(Color(0.030, 0.028, 0.024), 0.98, 0.0)
	var brass := _weapon_material(Color(0.110, 0.078, 0.022), 0.74, 0.45)
	_machete_part(_machete_blade_mesh(), Vector3(0.0, 0.055, 0.0), steel)
	# Bright cutting edge along the belly, pitted oxide along the spine, plus
	# shallow repair-scratches on both exposed faces.
	_machete_part(_weapon_box(Vector3(0.013, 0.330, 0.016)), Vector3(0.050, 0.225, 0.0), bevel)
	# Oxide along the spine is broken into uneven patches; one unbroken strip
	# reads as a painted racing stripe instead of rust.
	for spine_patch in [
		[Vector3(-0.021, 0.150, 0.0), 0.062],
		[Vector3(-0.020, 0.262, 0.0), 0.086],
		[Vector3(-0.019, 0.368, 0.0), 0.044],
	]:
		_machete_part(_weapon_box(Vector3(0.009, float(spine_patch[1]), 0.013)), spine_patch[0], pitting)
	var scars := [
		[Vector3(0.012, 0.135, 0.008), -24.0, 0.030],
		[Vector3(-0.006, 0.243, 0.008), -12.0, 0.042],
		[Vector3(0.018, 0.347, 0.008), -30.0, 0.024],
		[Vector3(-0.011, 0.404, 0.008), -16.0, 0.034],
		[Vector3(0.005, 0.185, -0.008), 9.0, 0.038],
		[Vector3(0.014, 0.298, -0.008), 21.0, 0.028],
		[Vector3(-0.004, 0.372, -0.008), -7.0, 0.022],
	]
	for scar in scars:
		_machete_part(_weapon_box(Vector3(float(scar[2]), 0.004, 0.003)), scar[0], scratch, Vector3(0.0, 0.0, deg_to_rad(float(scar[1]))))
	# Small rust blooms cluster where moisture sits: the spine seam and the
	# ricasso above the guard, not evenly across the face.
	var rust_marks := [
		[Vector3(-0.014, 0.165, -0.008), 11.0, Vector2(0.018, 0.030)],
		[Vector3(0.021, 0.305, -0.008), 11.0, Vector2(0.016, 0.026)],
		[Vector3(0.010, 0.072, 0.008), -6.0, Vector2(0.022, 0.020)],
		[Vector3(-0.018, 0.355, 0.008), 16.0, Vector2(0.014, 0.024)],
	]
	for rust_mark in rust_marks:
		var mark_size: Vector2 = rust_mark[2]
		_machete_part(_weapon_box(Vector3(mark_size.x, mark_size.y, 0.003)), rust_mark[0], pitting, Vector3(0.0, 0.0, deg_to_rad(float(rust_mark[1]))))
	# Grime and a repaired chip near the tip, where the blade has been used the
	# hardest. Two of the profile's notches line up with this darkening.
	_machete_part(_weapon_box(Vector3(0.030, 0.058, 0.0035)), Vector3(0.016, 0.432, 0.007), grime, Vector3(0.0, 0.0, deg_to_rad(-22.0)))
	_machete_part(_weapon_box(Vector3(0.026, 0.046, 0.0035)), Vector3(-0.008, 0.318, 0.007), grime, Vector3(0.0, 0.0, deg_to_rad(14.0)))
	_machete_part(_weapon_box(Vector3(0.010, 0.012, 0.007)), Vector3(0.055, 0.162, 0.0), grime)
	_machete_part(_weapon_box(Vector3(0.120, 0.020, 0.032)), Vector3(0.004, 0.050, 0.0), brass)
	_machete_part(_weapon_box(Vector3(0.052, 0.225, 0.048)), Vector3(0.0, -0.078, 0.0), timber)
	for wrap_y in [-0.020, -0.078, -0.136]:
		_machete_part(_weapon_cylinder(0.030, 0.018), Vector3(0.0, wrap_y, 0.0), cord)
	_machete_part(_weapon_cylinder(0.033, 0.024), Vector3(0.0, -0.190, 0.0), brass)
	_machete_part(_weapon_cylinder(0.009, 0.058), Vector3(0.0, -0.202, 0.0), brass, Vector3(0.0, 0.0, PI * 0.5))
	machete_view.visible = machete_equipped


func _machete_blade_mesh() -> ArrayMesh:
	# Extruded machete profile: broad belly, clipped point, near-straight spine,
	# and a couple of repaired nicks in the cutting edge.
	var profile := PackedVector2Array([
		Vector2(-0.034, 0.000), Vector2(0.028, 0.000), Vector2(0.044, 0.062),
		Vector2(0.054, 0.138), Vector2(0.045, 0.153), Vector2(0.058, 0.171),
		Vector2(0.058, 0.250), Vector2(0.046, 0.266), Vector2(0.056, 0.282), Vector2(0.056, 0.330),
		Vector2(0.048, 0.400), Vector2(0.034, 0.452), Vector2(0.018, 0.480),
		Vector2(-0.006, 0.470), Vector2(-0.022, 0.410), Vector2(-0.030, 0.320),
		Vector2(-0.033, 0.210), Vector2(-0.034, 0.100),
	])
	var half := 0.0065
	var centre := Vector2.ZERO
	for point in profile:
		centre += point
	centre /= float(profile.size())
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for index in profile.size():
		var a: Vector2 = profile[index]
		var b: Vector2 = profile[(index + 1) % profile.size()]
		_tri(surface, Vector3(centre.x, centre.y, half), Vector3(a.x, a.y, half), Vector3(b.x, b.y, half))
		_tri(surface, Vector3(centre.x, centre.y, -half), Vector3(b.x, b.y, -half), Vector3(a.x, a.y, -half))
		_tri(surface, Vector3(a.x, a.y, half), Vector3(a.x, a.y, -half), Vector3(b.x, b.y, -half))
		_tri(surface, Vector3(a.x, a.y, half), Vector3(b.x, b.y, -half), Vector3(b.x, b.y, half))
	surface.generate_normals()
	return surface.commit()


func _tri(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	surface.add_vertex(a)
	surface.add_vertex(b)
	surface.add_vertex(c)


func _build_torch_view() -> void:
	# The salvaged hand torch is a real object in the left hand: an aluminium
	# tube, a caged lens, rubber grips, and a thumb switch. Its lens only glows
	# while the beam is actually on.
	torch_view = Node3D.new()
	torch_view.name = "HandTorchView"
	torch_view.position = TORCH_VIEW_REST
	torch_view.rotation = Vector3(deg_to_rad(-4.0), deg_to_rad(14.0), deg_to_rad(-6.0))
	camera.add_child(torch_view)
	var shell := _weapon_material(Color(0.20, 0.21, 0.22), 0.44, 0.74)
	var rubber := _weapon_material(Color(0.10, 0.10, 0.10), 0.96, 0.02)
	var brass := _weapon_material(Color(0.52, 0.38, 0.14), 0.40, 0.80)
	torch_lens = _weapon_material(Color(0.86, 0.90, 0.82), 0.16, 0.10)
	torch_lens.emission_enabled = true
	torch_lens.emission = Color(0.92, 0.95, 0.86)
	torch_lens.emission_energy_multiplier = 0.0
	var lay := Vector3(-PI * 0.5, 0.0, 0.0)
	_weapon_part(_weapon_cylinder(0.024, 0.185), Vector3(0.0, 0.0, 0.0), shell, lay, torch_view)
	_weapon_part(_weapon_cylinder(0.034, 0.055), Vector3(0.0, 0.0, -0.112), shell, lay, torch_view)
	_weapon_part(_weapon_cylinder(0.031, 0.012), Vector3(0.0, 0.0, -0.142), brass, lay, torch_view)
	_weapon_part(_weapon_cylinder(0.027, 0.010), Vector3(0.0, 0.0, -0.150), torch_lens, lay, torch_view)
	for grip_z in [0.030, 0.062, 0.094]:
		_weapon_part(_weapon_cylinder(0.027, 0.016), Vector3(0.0, 0.0, grip_z), rubber, lay, torch_view)
	_weapon_part(_weapon_box(Vector3(0.014, 0.026, 0.046)), Vector3(0.026, 0.004, -0.012), rubber, Vector3.ZERO, torch_view)
	torch_view.visible = flashlight_acquired


func _machete_part(mesh: Mesh, offset: Vector3, material: Material, rotation_value: Vector3 = Vector3.ZERO) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = offset
	part.rotation = rotation_value
	part.material_override = material
	machete_view.add_child(part)

func _weapon_box(size_value: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size_value
	return mesh

func _weapon_cylinder(radius_value: float, height_value: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius_value
	mesh.bottom_radius = radius_value
	mesh.height = height_value
	mesh.radial_segments = 12
	return mesh

func _weapon_part(mesh: Mesh, offset: Vector3, material: Material, rotation_value: Vector3 = Vector3.ZERO, parent: Node3D = null) -> MeshInstance3D:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.position = offset
	part.rotation = rotation_value
	part.material_override = material
	var host: Node3D = parent
	if host == null:
		host = riveter_view
	host.add_child(part)
	return part

func _weapon_material(color: Color, roughness_value: float, metallic_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	material.metallic = metallic_value
	return material

func enter_hide() -> void:
	if is_hidden:
		return
	is_hidden = true
	can_move = false
	velocity = Vector3.ZERO
	flashlight_before_hiding = flashlight_on
	flashlight.visible = false

func leave_hide() -> void:
	if not is_hidden:
		return
	is_hidden = false
	can_move = true
	flashlight.visible = flashlight_on and flashlight_acquired and flashlight_charge > 0.0

func _play_footstep(running: bool) -> void:
	footstep_player.stream = FOOTSTEP_SOUNDS[randi() % FOOTSTEP_SOUNDS.size()]
	footstep_player.pitch_scale = randf_range(1.05, 1.15) if running else randf_range(0.92, 1.02)
	footstep_player.volume_db = -8.0
	footstep_player.play()

func _get_game() -> Node:
	return get_parent()
