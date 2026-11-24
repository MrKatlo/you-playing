extends "res://tools/tests/test_base.gd"

## Melee weapon and tool slots
##
## The blade itself: equipping it puts it in the hand, every swing
## variant has its own pose and cannot be interrupted into another, a swing that
## reaches a creature damages it, and the tool slot rules hold while a swing is
## in flight.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/workflow_weapons.tscn


func _init() -> void:
	suite_name = "workflow_weapons"
	suite_level = "workflow"


func run_phases() -> void:
	await _test_tool_slots()
	await _test_phase_a1_machete_system()

func _test_tool_slots() -> void:
	# The torch lives in the left hand while the right hand carries exactly one
	# tool: the machete and the bolt driver are never in view together.
	var player = game.player
	player.global_position = Vector3(7.5, 0.9, -2.6)
	player.velocity = Vector3.ZERO
	player.set_flashlight_acquired(true)
	player.set_machete_equipped(true)
	player.set_riveter_equipped(true)

	_ok(player.select_slot(player.SLOT_MACHETE), "slot 1 selects the machete")
	await _frames(14)
	_ok(player.machete_view.visible and not player.riveter_view.visible,
		"the machete slot shows the blade and hides the driver")
	_ok(player.torch_view.visible, "the torch stays visible in the left hand with the blade out")

	_ok(player.select_slot(player.SLOT_DRIVER), "slot 3 selects the bolt driver")
	await _frames(14)
	_ok(player.riveter_view.visible and not player.machete_view.visible,
		"the driver slot shows the gun and hides the machete")
	_ok(player.torch_view.visible, "the torch stays visible in the left hand with the driver out")

	_ok(player.select_slot(player.SLOT_TORCH), "slot 2 selects the hand torch")
	await _frames(14)
	_ok(not player.machete_view.visible and not player.riveter_view.visible,
		"the torch slot lowers both right-hand tools")
	for _step in 40:
		player._update_hand_views(0.05)
	_ok(player.torch_view.position.distance_to(player.TORCH_VIEW_PRESENT) < 0.05,
		"the torch raises into a presented stance on slot 2", str(player.torch_view.position))

	# 1/2/3 are real bindings, routed through the player controller.
	_ok(InputMap.has_action("slot_1") and InputMap.has_action("slot_2") and InputMap.has_action("slot_3"),
		"1/2/3 exist as input actions")
	for pair in [[2, "slot_2"], [1, "slot_1"], [3, "slot_3"]]:
		var press := InputEventAction.new()
		press.action = pair[1]
		press.pressed = true
		player._unhandled_input(press)
		await _frames(2)
		_ok(player.active_slot == int(pair[0]), "pressing %s selects slot %d" % [pair[1], int(pair[0])])

	# Left click acts on the held tool, so the blade never spends a bolt.
	player.select_slot(player.SLOT_MACHETE)
	await _frames(14)
	game.bolts = 3
	game.shot_cooldown = 0.0
	game.player_fire()
	var swung: float = player.machete_swing
	_ok(int(game.bolts) == 3, "left click with the machete out spends no bolt")
	_ok(swung > 0.0, "left click with the machete out starts the swing")
	await _wait_for_machete_ready(player)

	# R is the panic draw: it brings the blade up even from the driver slot.
	_ok(player.select_slot(player.SLOT_DRIVER), "the driver can be selected after blade recovery")
	await _frames(14)
	game.shot_cooldown = 0.0
	game.player_melee()
	await _frames(2)
	_ok(player.active_slot == player.SLOT_MACHETE and player.machete_view.visible,
		"R quick-draws the machete out of the driver slot")
	await _wait_for_machete_ready(player)

	# Reload animation: one stroke slides the bolt back and returns it.
	_ok(player.select_slot(player.SLOT_DRIVER), "the driver returns after the panic draw recovers")
	await _frames(14)
	player.play_riveter_reload()
	_ok(player.reload_anim > 0.0, "reloading starts the bolt stroke")
	var stroke_peak := -10.0
	for _step in 24:
		await _frames(1)
		if player.riveter_bolt != null:
			stroke_peak = maxf(stroke_peak, player.riveter_bolt.position.z)
	_ok(stroke_peak > -0.34, "the reload stroke pulls the bolt back into the driver", str(stroke_peak))

	# A landed swing briefly drags real time down, then restores it.
	Engine.time_scale = 1.0
	game.shot_cooldown = 0.0
	game._hit_stop(0.06)
	await _frames(1)
	_ok(Engine.time_scale < 1.0, "a landed blade drops into hit-stop", str(Engine.time_scale))
	await get_tree().create_timer(0.4, true, false, true).timeout
	_ok(is_equal_approx(Engine.time_scale, 1.0), "hit-stop restores normal time")
	Engine.time_scale = 1.0
	player.select_slot(player.SLOT_MACHETE)


func _test_phase_a1_machete_system() -> void:
	# A1 is intentionally tested against the live player and a live Burrower rather
	# than a mock. It covers hand state, all three animation poses, cooldown, and
	# the hit reaction on a moving enemy.
	var player = game.player
	Engine.time_scale = 1.0
	player.global_position = Vector3(7.5, 0.9, -2.6)
	player.velocity = Vector3.ZERO
	player.set_flashlight_acquired(true)
	player.set_machete_equipped(true)
	player.set_riveter_equipped(true)
	await _wait_for_machete_ready(player)

	_ok(player.select_slot(player.SLOT_MACHETE), "A1 equips the single recovered machete")
	await _frames(16)
	_ok(player.active_slot == player.SLOT_MACHETE and player.machete_view.visible and not player.riveter_view.visible,
		"A1 draws the machete without duplicating the right-hand tool")
	_ok(InputMap.has_action("holster"), "A1 exposes a dedicated holster input")
	var holster_press := InputEventAction.new()
	holster_press.action = "holster"
	holster_press.pressed = true
	player._unhandled_input(holster_press)
	_ok(player.active_slot == player.SLOT_EMPTY, "A1 H input puts the machete away")
	await _frames(16)
	_ok(player.active_slot == player.SLOT_EMPTY and not player.machete_view.visible and not player.riveter_view.visible,
		"A1 holsters the right hand cleanly")
	_ok(player.select_slot(player.SLOT_MACHETE), "A1 retrieves the holstered machete")
	await _frames(16)
	_ok(player.machete_view.visible and player.active_slot == player.SLOT_MACHETE,
		"A1 redraws the same machete after holstering")

	var attack_samples := [
		{"kind": "horizontal", "sample_frames": 8},
		{"kind": "diagonal", "sample_frames": 10},
		{"kind": "thrust", "sample_frames": 10},
	]
	var attack_poses: Array[Vector3] = []
	var attack_rotations: Array[Vector3] = []
	for sample in attack_samples:
		var kind: String = str(sample["kind"])
		var started: String = player.begin_machete_attack(kind)
		_ok(started == kind, "A1 starts the %s machete attack" % kind)
		if kind == "horizontal":
			_ok(player.begin_machete_attack("diagonal").is_empty(), "A1 blocks a second attack during recovery")
		await _frames(int(sample["sample_frames"]))
		attack_poses.append(player.machete_view.position)
		attack_rotations.append(player.machete_view.rotation)
		_ok(player.is_machete_attacking() and player.machete_view.position.distance_to(player.MACHETE_VIEW_REST) > 0.12,
			"A1 gives the %s attack a readable first-person pose" % kind,
			"position=%s distance=%.3f" % [str(player.machete_view.position), player.machete_view.position.distance_to(player.MACHETE_VIEW_REST)])
		var recovered: bool = await _wait_for_machete_ready(player)
		_ok(recovered, "A1 %s attack returns to an idle-ready state" % kind)
	_ok(attack_poses.size() == 3 and attack_rotations.size() == 3 and
		(attack_poses[0].distance_to(attack_poses[1]) > 0.08 or attack_rotations[0].distance_to(attack_rotations[1]) > deg_to_rad(15.0)) and
		(attack_poses[1].distance_to(attack_poses[2]) > 0.08 or attack_rotations[1].distance_to(attack_rotations[2]) > deg_to_rad(15.0)),
		"A1 attack variants use visibly different weapon paths")

	var automatic_first: String = player.begin_machete_attack()
	var automatic_first_ready: bool = await _wait_for_machete_ready(player)
	var automatic_second: String = player.begin_machete_attack()
	var automatic_second_ready: bool = await _wait_for_machete_ready(player)
	_ok(automatic_first_ready and automatic_second_ready and not automatic_first.is_empty() and automatic_first != automatic_second,
		"A1 successive normal swings do not repeat the same animation")

	# A slow live slime is close enough to hit, but moving during the swing. This
	# proves that the actual impact frame re-evaluates range and direction.
	game._spawn_burrower(Vector3(7.5, 0.0, -1.00), false)
	var moving_target: Burrower = game.burrowers[game.burrowers.size() - 1] as Burrower
	moving_target.speed = 0.24
	await _aim_player_at(moving_target.global_position + Vector3(0.0, 0.30, 0.0))
	var health_before: int = int(moving_target.health)
	var strike_kind: String = player.begin_machete_attack("thrust")
	await _frames(22)
	var feedback = game.find_child("MacheteHitFeedback", true, false)
	_ok(strike_kind == "thrust" and int(moving_target.health) == health_before - 1,
		"A1 thrust hit detection damages a moving slime")
	_ok(moving_target.stagger > 0.0 and moving_target.hit_recoil > 0.0 and moving_target.knockback_velocity.length() > 0.10,
		"A1 hit gives the slime a controlled recoil and knockback")
	# A blade into a gel body now has its own wound recording rather than the
	# pitched-down metal clank that used to stand in for it.
	_ok(feedback != null and game.sfx_player != null and game.sfx_player.stream != null and game.sfx_player.stream.resource_path.ends_with("flesh_impact.wav"),
		"A1 hit spawns subtle gel feedback and plays the wound sound")
	await _wait_for_machete_ready(player)
	Engine.time_scale = 1.0
	if game.burrowers.has(moving_target):
		game.burrowers.erase(moving_target)
	if is_instance_valid(moving_target):
		moving_target.queue_free()
	player.select_slot(player.SLOT_MACHETE)
