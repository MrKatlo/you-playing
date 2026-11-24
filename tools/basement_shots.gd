extends Node

## Windowed visual test for the real Basement Farm scene.
##
## Run with:
##   Godot --path . res://tools/basement_shots.tscn
##
## It creates PNGs in res://tools/shots/basement/, then exits on its own. The
## runner only stages temporary in-memory game state; it never calls save_game.

const BASEMENT_SCENE: PackedScene = preload("res://scenes/basement.tscn")
const OUT := "res://tools/shots/basement/"

var game


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	game = BASEMENT_SCENE.instantiate()
	add_child(game)
	await _frames(8)
	await _shot("01_title")
	game.menu._on_instructions()
	await _frames(4)
	await _shot("01a_survival_guide")
	game.menu._back()
	await _frames(3)

	game.new_shift()
	game.menu.close_menu()
	await _frames(18)
	await _shot("01b_wake")
	game.finish_opening_sequence_for_test()
	await _frames(4)
	await _shot("02_entry")

	# Asset close-ups: these make the post-apocalypse material read reviewable
	# without requiring somebody to manually drive the editor camera.
	await _stage(Vector3(-3.2, 0.9, -2.5), Vector3(-4.95, 1.0, -4.0))
	await _shot("03_furnace_close")
	game._set_furnace_door(true)
	await _frames(14)
	await _shot("03a_furnace_open_fire")
	game.farm.furnace_lit = false
	game.farm.fuel = 2.0
	game._use_furnace()
	await _frames(4)
	await _shot("03b_furnace_fuel_throw")
	game._set_furnace_door(false)
	await _frames(14)

	await _stage(Vector3(-3.3, 1.0, -2.5), Vector3(-4.68, 2.48, -4.0))
	await _shot("04_furnace_smoke")

	await _stage(Vector3(-0.1, 0.9, -2.55), Vector3(-0.6, 0.62, -4.25))
	await _shot("05_culture_tray_close")
	game._open_tray_lid(0)
	await _frames(8)
	await _shot("05a_culture_tray_open")
	var preview_cricket: Node3D = game.find_child("Cricket_1_1", true, false) as Node3D
	if preview_cricket != null:
		# Isolate one supplied Riverborn cricket for visual QA without changing the
		# actual saved game or leaving it displaced for later captures.
		var cricket_colony: Array = game.tray_crickets.duplicate()
		var cricket_home := preview_cricket.position
		var cricket_rotation := preview_cricket.rotation
		var cricket_scale := preview_cricket.scale
		game.tray_crickets.clear()
		preview_cricket.position = Vector3(0.0, 0.10, -1.20)
		preview_cricket.rotation = Vector3.ZERO
		preview_cricket.scale = Vector3.ONE * 2.4
		await _stage(Vector3(0.0, 0.72, 0.65), Vector3(0.0, 0.15, -1.20))
		await _shot("05b_cricket_preview")
		preview_cricket.position = cricket_home
		preview_cricket.rotation = cricket_rotation
		preview_cricket.scale = cricket_scale
		game.tray_crickets = cricket_colony

	var preview_gecko: Node3D = game.house_gecko
	if preview_gecko != null:
		var gecko_home := preview_gecko.position
		var gecko_rotation := preview_gecko.rotation
		var gecko_wait: float = float(game.gecko_wait)
		preview_gecko.position = Vector3(0.0, 0.07, -1.20)
		preview_gecko.rotation = Vector3.ZERO
		game.gecko_wait = 20.0
		await _stage(Vector3(0.0, 0.62, 0.70), Vector3(0.0, 0.14, -1.20))
		await _shot("05c_gecko_preview")
		preview_gecko.position = gecko_home
		preview_gecko.rotation = gecko_rotation
		game.gecko_wait = gecko_wait

	await _stage(Vector3(-1.5, 0.9, 1.6), Vector3(-4.9, 0.8, -3.8))
	await _shot("03_furnace_and_trays")

	await _stage(Vector3(0.0, 0.9, 1.2), Vector3(-3.4, 0.6, -0.2))
	await _shot("04_butcher_table")

	await _stage(Vector3(2.6, 0.9, 1.2), Vector3(3.6, 0.6, -0.2))
	await _shot("05_packaging_bench")

	await _stage(Vector3(3.95, 0.9, 1.40), Vector3(3.95, 0.72, 2.65))
	await _shot("05d_salvage_workbench")
	game._use_workbench()
	await _frames(4)
	await _shot("05e_workbench_menu")
	game.menu.close_menu()
	await _frames(3)
	game.farm.parts = 2
	game.farm.hides = 1
	game.craft_workbench_recipe("insulation_patch")
	game._use_gap(0)
	await _frames(10)
	await _stage(Vector3(4.55, 0.9, 4.0), Vector3(5.82, 1.0, 3.2))
	await _shot("05f_installed_insulation_patch")
	game.farm.parts = 3
	game.farm.chitin = 1
	game.farm.hides = 1
	game.craft_workbench_recipe("warm_storage_rack")
	await _frames(14)
	game.message_label.text = ""
	await _stage(Vector3(4.45, 0.95, -2.05), Vector3(4.70, 1.15, -4.44))
	await _shot("05g_warm_storage_rack")

	# Hunt loop visual proof: a closed inner door, baited outer entrance, then a
	# sealed room opened only when the player is ready to kill the contained prey.
	await _stage(Vector3(3.15, 0.9, 0.25), Vector3(6.0, 1.1, -2.0))
	await _shot("06_hunt_bulkhead_closed")
	game._on_bulkhead_cranked(true)
	await _frames(52)
	game.message_label.text = ""
	await _stage(Vector3(4.45, 0.9, -2.0), Vector3(8.20, 1.00, -2.0))
	await _shot("06b_bulkhead_open_lane")
	game._on_bulkhead_cranked(false)
	await _frames(52)
	game.farm.snares = 1
	game._arm_hunt_snare()
	await _frames(4)
	await _stage(Vector3(7.05, 0.9, -3.05), Vector3(8.25, 0.08, -2.0))
	await _shot("06a_floor_snare_armed")
	await _stage(Vector3(3.15, 0.9, 0.25), Vector3(6.0, 1.1, -2.0))

	game.farm.fuel = 2.0
	game._bait_hook()
	game._crank()
	await _frames(160)
	game.crank_cooldown = 0.0
	game._crank()
	await _frames(70)
	var hunt_slime = game.burrowers[0] if not game.burrowers.is_empty() else null
	if hunt_slime != null:
		# Lock the live prey on the bait mark for an unambiguous visual inspection
		# after proving that the lure and outer shutter spawned it.
		hunt_slime.global_position = Vector3(8.25, 0.0, -2.0)
		hunt_slime.speed = 0.0
	game._on_bulkhead_cranked(true)
	await _frames(65)
	await _stage(Vector3(7.05, 0.9, -3.05), Vector3(8.25, 0.45, -2.0))
	await _shot("07_contained_hunt_slime")

	if hunt_slime != null:
		hunt_slime.take_hit(1, "melee")
		hunt_slime.take_hit(1, "melee")
	await _frames(6)
	await _stage(Vector3(7.05, 0.9, -3.05), Vector3(8.25, 0.10, -2.0))
	await _shot("08_slime_guts_and_loot")
	game.farm.venom_seconds = 0.0
	game.message_label.text = ""
	await _frames(2)

	# Expedition access proof: the player physically crosses the same exterior
	# hunt shutter into the new frozen maintenance tunnel, then reaches the first
	# Cold Junction and its in-world return marker. No scene swap or demo shell.
	game._use_cave_return_wheel()
	await _frames(70)
	game.message_label.text = ""
	await _frames(2)
	await _stage(Vector3(8.45, 0.9, -2.0), Vector3(13.60, 1.20, -2.0))
	await _shot("08a_open_cave_threshold")
	await _stage(Vector3(12.20, 0.9, -2.0), Vector3(12.55, 1.00, -3.18))
	await _shot("08b_cave_return_marker")
	await _stage(Vector3(18.15, 0.9, -1.58), Vector3(18.25, 0.78, 1.72))
	await _shot("08c_cold_junction")
	await _stage(Vector3(18.72, 1.05, -1.25), game.CAVE_REGULATOR_SPOT + Vector3(0.0, 0.28, 0.0))
	await _shot("08e_c4_thermal_regulator")
	# C4 // the cold store: the door from the corridor, the room itself, and the
	# cold frame with its cracked pane.
	await _stage(Vector3(16.0, 0.9, -1.55), Vector3(16.0, 1.15, -5.0))
	await _shot("08g_cold_store_door")
	await _stage(Vector3(16.75, 0.9, -4.45), Vector3(14.55, 0.95, -7.15))
	await _shot("08h_cold_store_room")
	await _stage(Vector3(16.0, 0.9, -6.45), Vector3(16.0, 0.55, -7.6))
	await _shot("08i_cold_frame")
	game._recover_thermal_regulator()
	game.farm.parts = 2
	game.craft_workbench_recipe("furnace_heat_reclaimer")
	await _frames(16)
	game.message_label.text = ""
	await _stage(Vector3(-3.05, 1.10, -2.40), game.FURNACE_SPOT + Vector3(0.78, 0.65, -0.12))
	await _shot("08f_fitted_heat_reclaimer")
	await _stage(Vector3(19.35, 0.9, -2.0), Vector3(23.74, 1.20, -2.0))
	await _shot("08d_cave_collapse")
	game.crank_cooldown = 0.0
	game._crank()
	await _frames(60)

	# Temporarily stage the cot in clear floor space for an unobstructed visual
	# proof of the actual model; the runner never saves this in-memory move.
	var cot_model: Node3D = game.find_child("SalvagedCotModel", true, false) as Node3D
	var cot_body: StaticBody3D = cot_model.get_parent() as StaticBody3D if cot_model != null else null
	var cot_home := cot_body.global_position if cot_body != null else Vector3.ZERO
	if cot_body != null:
		cot_body.global_position = Vector3(-0.8, 0.28, 0.0)
	await _stage(Vector3(-0.8, 1.25, -2.45), Vector3(-0.8, 0.54, 0.0))
	await _shot("09_salvaged_cot")
	if cot_body != null:
		cot_body.global_position = cot_home

	# Cot corner review: the cot now sits flush to the rear wall with the bed-
	# side kit standing on the side wall, so both clearances and the walking
	# route can be judged before and after the kit hands over the tools.
	await _stage(Vector3(-2.55, 0.95, 2.55), Vector3(-4.30, 0.55, 4.35))
	game.message_label.text = ""
	await _shot("10a_cot_and_kit_closed")
	game._use_bedside_kit()
	await _frames(8)
	# Taking the kit raises the machete into view, so lower it for this capture.
	game.player.machete_view.visible = false
	game.message_label.text = ""
	await _shot("10b_cot_and_kit_open")

	# First-person tool proof: the rebuilt machete in the right hand and the
	# salvaged hand torch in the left, then the same view mid-cleave.
	game.player.set_flashlight_acquired(true)
	game.player.set_flashlight_enabled(true)
	game.player.set_machete_equipped(true)
	game.player.set_riveter_equipped(false)
	game.player.select_slot(game.player.SLOT_MACHETE)
	await _stage(Vector3(0.0, 0.9, 1.2), Vector3(0.5, 0.6, -3.0))
	await _frames(16)
	game.message_label.text = ""
	await _shot("10c_machete_and_torch")
	game.player.begin_machete_attack("horizontal")
	await _frames(8)
	game.message_label.text = ""
	await _shot("10d_machete_swing")
	await _frames(40)
	game.player.begin_machete_attack("diagonal")
	await _frames(10)
	game.message_label.text = ""
	await _shot("10h_machete_diagonal")
	await _frames(40)
	game.player.begin_machete_attack("thrust")
	await _frames(10)
	game.message_label.text = ""
	await _shot("10i_machete_thrust")
	await _frames(40)

	# A2 proof: the pounce telegraph, the airborne leap, and what a wound costs on
	# the survival HUD. The slime is placed rather than lured so the three frames
	# are comparable and the pose is unambiguous.
	game._spawn_burrower(Vector3(0.55, 0.0, -2.25), false)
	var a2_slime = game.burrowers[game.burrowers.size() - 1]
	a2_slime.speed = 0.0
	a2_slime.provoked = true
	a2_slime.attack_cooldown = 0.0
	await _stage(Vector3(0.0, 0.9, 1.2), Vector3(0.55, 0.35, -2.25))
	a2_slime.state = a2_slime.STATE_CROUCH
	a2_slime.state_time = 0.0
	a2_slime.animation_lock = 0.6
	await _frames(9)
	game.message_label.text = ""
	await _shot("10j_leap_telegraph")
	# Launch from further out: the pounce keeps a fixed airtime, so a longer jump
	# is faster and would otherwise reach the lens before the shutter opens.
	a2_slime.global_position = Vector3(0.55, 0.0, -4.25)
	a2_slime._launch_leap()
	await _frames(4)
	game.message_label.text = ""
	await _shot("10k_leap_airborne")
	await _frames(50)
	a2_slime.queue_free()
	game.burrowers.erase(a2_slime)
	game.player.health = 34.0
	game.player.invulnerable = 0.0
	game._damage_player(12.0, game.player.global_position + Vector3(1.0, 0.0, 0.0), 0.0)
	await _frames(3)
	game.message_label.text = ""
	await _shot("10l_wounded_hud")
	game.player.heal_to_full()
	game.hurt_flash = 0.0
	await _frames(30)

	# A3 proof: the step itself. The frame is taken mid-move, where the camera
	# lean and the committed direction are both readable.
	game.player.dodge_cooldown = 0.0
	game.player.invulnerable = 0.0
	game.player.rotation.y = deg_to_rad(-24.0)
	game.player.velocity = Vector3.ZERO
	game.player.try_dodge()
	await _frames(5)
	game.message_label.text = ""
	await _shot("10m_step_dodge")
	await _frames(24)
	game.player.heal_to_full()
	game.player.dodge_cooldown = 0.0
	game.player.rotation.y = 0.0

	# A4 proof: a pounce that missed lands guarded. The pale ring is pushed out
	# away from the body instead of closing in, so the two warnings cannot be
	# confused at a glance.
	game._spawn_burrower(Vector3(0.35, 0.0, -2.1), false)
	var a4_slime = game.burrowers[game.burrowers.size() - 1]
	a4_slime.speed = 0.0
	a4_slime.provoked = true
	a4_slime.player = game.player
	# The guard only exists inside 2 m of the hunter, so the camera has to be that
	# close to the animal for the frame to show the real state.
	await _stage(Vector3(0.15, 0.78, -0.35), Vector3(0.35, 0.30, -2.1))
	a4_slime.state = a4_slime.STATE_LEAP
	a4_slime.leap_hit_done = false
	a4_slime._land_leap()
	a4_slime.state_time = 0.14
	game.player.invulnerable = 0.0
	await _frames(2)
	game.message_label.text = ""
	await _shot("10n_landing_guard")
	a4_slime.queue_free()
	game.burrowers.erase(a4_slime)
	game.player.heal_to_full()
	await _frames(20)

	game.player.set_riveter_equipped(true)

	# Slot proof: the torch slot lowers the right hand and raises the left-hand
	# torch, then the driver slot brings the bolt driver up mid-reload stroke.
	game.player.select_slot(game.player.SLOT_TORCH)
	await _frames(24)
	game.message_label.text = ""
	await _shot("10e_torch_slot")
	game.player.select_slot(game.player.SLOT_DRIVER)
	await _frames(16)
	game.message_label.text = ""
	await _shot("10f_driver_slot")
	game.player.play_riveter_reload()
	await _frames(12)
	game.message_label.text = ""
	await _shot("10g_driver_slot_reload")
	game.player.select_slot(game.player.SLOT_MACHETE)

	await _stage(Vector3(0.0, 0.9, -1.45), Vector3(0.0, 1.55, -4.84))
	await _shot("11_broken_wall_bays")

	# C2 // the pocket, the clamp's paper, the gland lantern and the variant. These
	# are staged in memory only; the runner never saves the shift.
	game.farm.net_crafted = true
	game.farm.heat_glands = 1
	game.farm.parts = maxi(int(game.farm.parts), 2)
	game.farm.chitin = maxi(int(game.farm.chitin), 1)
	game.farm.fuel = 8.0
	game.craft_workbench_recipe("gland_lantern")
	game.farm.cave_papers.clear()
	game.farm.roll_cave_papers()
	await _frames(6)
	game.message_label.text = ""
	await _stage(Vector3(26.5, 0.9, -2.0), Vector3(40.0, 1.40, -2.0))
	await _shot("13a_pocket_corridor")
	await _stage(Vector3(45.0, 0.9, 1.6), Vector3(58.0, 1.30, 3.0))
	await _shot("13b_pocket_gallery")
	await _stage(Vector3(68.2, 0.9, 2.0), game.TRADE_DROP_SPOT + Vector3(0.0, 1.05, 0.0))
	await _frames(20)
	game.message_label.text = ""
	await _shot("13c_clamp_paper")
	# Lamp lit: six metres of warm light on the same chamber, with the readout up.
	game.player_lantern_click()
	await _frames(24)
	game.message_label.text = ""
	await _shot("13d_lantern_lit")
	await _stage(Vector3(71.6, 0.9, 1.2), Vector3(70.5, 1.20, 5.90))
	await _shot("13e_breach")
	var shot_cinder = game._spawn_burrower(game.POCKET_CHAMBER_CENTER + Vector3(-0.4, 0.02, 0.6), false, game._cinder_config())
	await _frames(4)
	# Hold the pose: the review frame is about the body's colour and silhouette, not
	# about how fast it closes on the camera.
	if shot_cinder != null:
		shot_cinder.set_physics_process(false)
		shot_cinder.velocity = Vector3.ZERO
		shot_cinder.rotation.y = 0.0
	await _frames(4)
	await _stage(shot_cinder.global_position + Vector3(-2.7, 0.9, 1.5), shot_cinder.global_position + Vector3(0.0, 0.34, 0.0))
	await _frames(8)
	game.message_label.text = ""
	await _shot("13f_cinder_burrower")
	if is_instance_valid(shot_cinder):
		shot_cinder.queue_free()
	game.burrowers.clear()
	# First-person proof of the generated lantern hanging at the belt.
	await _stage(Vector3(72.0, 0.9, 2.2), Vector3(74.8, 0.95, 2.6))
	await _frames(16)
	game.message_label.text = ""
	await _shot("13g_hand_lantern")
	game.player_lantern_click()
	# The woven net in the right hand: draw its own slot first, because another
	# slot parks the carried net in the stowed hip pose.
	game.player.select_slot(4)
	await _stage(Vector3(72.0, 0.9, 2.2), Vector3(74.8, 0.95, 2.6))
	await _frames(12)
	game.message_label.text = ""
	await _shot("13h_net_in_hand")
	# Mid-sweep: the pose the net takes while a tray is actually taken.
	game.player.play_net_sweep()
	await _frames(20)
	game.message_label.text = ""
	await _shot("13i_net_sweep")
	game.player.net_sweep = 1.0

	game.toggle_pause_menu()
	await _frames(4)
	await _shot("12_pause_menu")

	print("BASEMENT SCREENSHOTS: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()


func _stage(position_value: Vector3, target: Vector3) -> void:
	game.player.global_position = position_value
	game.player.velocity = Vector3.ZERO
	await _aim_at(target)
	await _frames(12)


func _aim_at(target: Vector3) -> void:
	for _pass in 3:
		var camera: Camera3D = game.player.camera
		var direction: Vector3 = target - camera.global_position
		if direction.length() < 0.01:
			return
		direction = direction.normalized()
		game.player.rotation.y = atan2(-direction.x, -direction.z)
		await _frames(1)
		direction = (target - game.player.camera.global_position).normalized()
		game.player.head.rotation.x = clampf(asin(clampf(direction.y, -1.0, 1.0)), deg_to_rad(-60.0), deg_to_rad(60.0))
		await _frames(1)


func _frames(count: int) -> void:
	for _frame in count:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = get_viewport().get_texture().get_image()
	var path := OUT + name + ".png"
	var result := image.save_png(ProjectSettings.globalize_path(path))
	print("  %s  (%s)" % [path, "ok" if result == OK else "error %d" % result])
