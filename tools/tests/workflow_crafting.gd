extends "res://tools/tests/test_base.gd"

## Workbench crafting and loadout choices
##
## Crafting as a procedure: a recipe stays locked until its
## prerequisite is earned, crafting at the workbench spends the real resources and
## produces the real item, and the bolt loadout can be chosen, cycled and worn.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/workflow_crafting.tscn


func _init() -> void:
	suite_name = "workflow_crafting"
	suite_level = "workflow"


func run_phases() -> void:
	await _test_workbench_loop()
	await _test_tactical_loadout()

func _test_workbench_loop() -> void:
	game.farm.parts = 3
	game.farm.chitin = 2
	game.farm.water = 1
	game.farm.hides = 1
	game.farm.kills = 0
	game.bolts = 0
	var gated_bolts: String = game.craft_workbench_recipe("basic_bolts")
	_ok(int(game.bolts) == 0, "ammunition stays uncraftable until the first kill", gated_bolts)
	game.farm.kills = 1
	game.bolts = 1
	game.farm.patches = 0
	var bolt_result: String = game.craft_workbench_recipe("basic_bolts")
	_ok(int(game.bolts) == 4, "workbench turns salvage into three usable bolts", bolt_result)
	_ok(int(game.farm.parts) == 2 and int(game.farm.chitin) == 1, "bolt recipe spends its listed parts and chitin")
	var antidote_result: String = game.craft_workbench_recipe("antidote")
	_ok(int(game.farm.antidotes) == 1, "workbench turns chitin and water into an antidote", antidote_result)
	var patch_result: String = game.craft_workbench_recipe("insulation_patch")
	_ok(int(game.farm.patches) == 1 and int(game.farm.parts) == 0 and int(game.farm.hides) == 0,
		"workbench creates an insulation patch as a real inventory item", patch_result)
	game._use_gap(0)
	_ok(bool(game.farm.gaps[0]["sealed"]) and int(game.farm.patches) == 0,
		"crafted insulation patch seals a specific leaking wall gap", game.message_label.text)
	_ok(game.gap_patch_visuals[0].visible and game.gap_patch_visuals[0].find_child("GeneratedInsulationPatchModel", true, false) != null,
		"installing a patch visibly covers the repaired wall gap")
	game.farm.parts = 3
	game.farm.chitin = 1
	game.farm.hides = 1
	var rack_result: String = game.craft_workbench_recipe("warm_storage_rack")
	_ok(game.farm.storage_rack_installed, "workbench turns salvage into a persistent warm storage upgrade", rack_result)
	_ok(game.storage_rack_visual.visible and game.storage_rack_visual.find_child("GeneratedWarmStorageRack", true, false) != null,
		"crafted storage upgrade visibly adds the shelf and heat lamp to the safe room")
	_ok(game.ration_crate_body.global_position.distance_to(game.STORAGE_RACK_SPOT) < 1.0,
		"ration interaction moves into the physical lower storage bay after the upgrade")
	# The regulator itself is a cave find. Preparing it here keeps this suite
	# independent of the cave run; the craft and the install below are still real.
	game.farm.thermal_regulators = 1
	game.farm.parts = 2
	var reclaimer_result: String = game.craft_workbench_recipe("furnace_heat_reclaimer")
	_ok(game.farm.heat_reclaimer_installed, "workbench turns the cave regulator into a persistent furnace upgrade", reclaimer_result)
	_ok(game.heat_reclaimer_visual.visible and game.heat_reclaimer_visual.find_child("GeneratedFurnaceHeatReclaimer", true, false) != null,
		"fitted cave upgrade visibly appears beside the real furnace")
	game._use_workbench()
	_ok(game.menu.visible and game.menu.current_screen == "workbench" and get_tree().paused,
		"physical workbench opens the crafting menu")
	_ok(game.menu.panel.get_child_count() > 0 and game.menu.panel.get_child(0) is ScrollContainer,
		"workbench keeps its growing recipe list inside a scrollable fabrication panel")
	game.menu.close_menu()


func _test_tactical_loadout() -> void:
	# Standalone precondition: a bolt has to be able to reach the creature. The
	# chamber bulkhead is sealed at the start of a shift, so open it and let the
	# body move before anything is fired.
	game.hunt_bulkhead_open = true
	game._move_hunt_bulkhead(2.6)
	await _frames(70)
	game.farm.kills = 1
	game.player.set_riveter_equipped(true)
	game.farm.parts = 5
	game.farm.chitin = 4
	game.farm.hides = 3
	game.farm.water = 1
	game.farm.broadhead_bolts = 0
	game.farm.tether_bolts = 0
	game.farm.snares = 0
	game.farm.driver_durability = 1
	var broadhead_result: String = game.craft_workbench_recipe("broadhead_bolts")
	_ok(int(game.farm.broadhead_bolts) == 2, "workbench builds broadhead bolts for a fast kill", broadhead_result)
	var tether_result: String = game.craft_workbench_recipe("tether_bolt")
	_ok(int(game.farm.tether_bolts) == 1, "workbench builds a non-lethal tether bolt", tether_result)
	var snare_result: String = game.craft_workbench_recipe("snare_kit")
	_ok(int(game.farm.snares) == 1, "workbench builds a floor snare kit", snare_result)
	var repair_result: String = game.craft_workbench_recipe("driver_repair")
	_ok(int(game.farm.driver_durability) == FarmState.DRIVER_MAX_DURABILITY,
		"workbench rebuild restores bolt-driver durability", repair_result)
	game.farm.selected_bolt_type = "standard"
	var cycled: String = game.farm.cycle_bolt_type()
	_ok(cycled == "BROADHEAD" and game.farm.selected_bolt_type == "broadhead",
		"Q-cycle model selects broadhead load")
	cycled = game.farm.cycle_bolt_type()
	_ok(cycled == "TETHER" and game.farm.selected_bolt_type == "tether",
		"Q-cycle model selects tether load")

	# The machete is the no-bolts fallback, so it has to finish a two-health
	# creature by itself when the driver is empty.
	game.player.global_position = Vector3(7.5, 0.9, -2.6)
	game.player.velocity = Vector3.ZERO
	game.player.set_machete_equipped(true)
	game.player.select_slot(game.player.SLOT_MACHETE)
	await _frames(14)
	game._spawn_burrower(Vector3(7.5, 0.0, -1.05), false)
	var blade_target: Burrower = game.burrowers[game.burrowers.size() - 1] as Burrower
	blade_target.speed = 0.0
	await _aim_player_at(Vector3(7.5, 0.30, -1.05))
	game.shot_cooldown = 0.0
	game.player_melee()
	await _frames(22)
	_ok(not blade_target.dead and int(blade_target.health) == 1 and blade_target.stagger > 0.0,
		"one machete swing staggers the slime without killing it")
	await _wait_for_machete_ready(game.player)
	await _aim_player_at(blade_target.global_position + Vector3(0.0, 0.30, 0.0))
	game.shot_cooldown = 0.0
	game.player_melee()
	await _frames(24)
	_ok(blade_target.dead and not game.burrowers.has(blade_target), "two machete swings kill a hunt slime")
	await _wait_for_machete_ready(game.player)
	if game.burrowers.has(blade_target):
		game.burrowers.erase(blade_target)
	blade_target.queue_free()

	game.player.global_position = Vector3(7.5, 0.9, -3.25)
	game.player.velocity = Vector3.ZERO
	game.farm.selected_bolt_type = "broadhead"
	game._spawn_burrower(Vector3(7.5, 0.0, -1.05), false)
	var broadhead_target: Burrower = game.burrowers[game.burrowers.size() - 1] as Burrower
	broadhead_target.speed = 0.0
	await _aim_player_at(Vector3(7.5, 0.30, -1.05))
	var broadhead_before: int = int(game.farm.broadhead_bolts)
	var durability_before: int = int(game.farm.driver_durability)
	_ok(game.player.select_slot(game.player.SLOT_DRIVER), "machete recovery permits changing back to the bolt driver")
	await _frames(14)
	# The driver's bolt leaves the eye, and the camera pitch is recoil only, so a
	# slime sitting on the floor is under the shot. The honest in-play target is a
	# body crossing the sightline at eye height - which is exactly where a pouncer
	# is when a bolt meets it - so the prey is placed on the view ray at eye height
	# instead of on the floor.
	_place_burrower_on_view_ray(broadhead_target)
	broadhead_target.global_position.y = game.player.camera.global_position.y - 0.29  # sphere centre is 0.29 above the root
	await _frames(2)
	game.shot_cooldown = 0.0
	game.player_fire()
	await _frames(2)
	_ok(int(game.farm.broadhead_bolts) == broadhead_before - 1 and int(game.farm.driver_durability) == durability_before - 1,
		"broadhead fire spends its own ammo and wears the driver")
	_ok(broadhead_target.dead and not game.burrowers.has(broadhead_target),
		"a broadhead kills the two-health slime in one hit",
		"health=%d dead=%s active=%s message=%s" % [int(broadhead_target.health), str(broadhead_target.dead), str(game.burrowers.has(broadhead_target)), game.message_label.text])
	if game.burrowers.has(broadhead_target):
		game.burrowers.erase(broadhead_target)
		broadhead_target.queue_free()

	game._spawn_burrower(Vector3(7.5, 0.0, -1.05), false)
	var tether_target: Burrower = game.burrowers[game.burrowers.size() - 1] as Burrower
	tether_target.speed = 0.0
	game.farm.selected_bolt_type = "tether"
	game.player.select_slot(game.player.SLOT_DRIVER)
	await _aim_player_at(Vector3(7.5, 0.30, -1.05))
	_place_burrower_on_view_ray(tether_target)
	tether_target.global_position.y = game.player.camera.global_position.y - 0.29  # sphere centre is 0.29 above the root
	await _frames(2)
	game.shot_cooldown = 0.0
	game.player_fire()
	await _frames(1)
	_ok(int(tether_target.health) == 2 and float(tether_target.tether_left) > 4.0,
		"tether bolt pins prey without damaging its hide",
		"health=%d tether=%.2f message=%s" % [int(tether_target.health), float(tether_target.tether_left), game.message_label.text])
	if game.burrowers.has(tether_target):
		game.burrowers.erase(tether_target)
	tether_target.queue_free()
	game.farm.selected_bolt_type = "standard"
