extends "res://tools/tests/test_base.gd"

## HUD, menu and pause behaviour
##
## What the player can read and stop: the HUD reports the state the
## simulation is in, the title menu starts a shift, and the pause menu freezes the
## world without losing the run.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/workflow_ui.tscn


func _init() -> void:
	suite_name = "workflow_ui"
	suite_level = "workflow"


func run_phases() -> void:
	await _test_hud_and_menu()
	await _test_pause_menu()

func _test_hud_and_menu() -> void:
	# This suite inspects steady-state HUD priorities, so the opening lesson must
	# not still be steering the objective card toward the furnace or the kit.
	game.opening_state = "complete"
	game._update_hud()
	_ok(game.heat_bar != null and game.fuel_bar != null and game.prompt_panel != null and game.message_panel != null,
		"HUD uses compact survival bars and dedicated action/notification cards")
	_ok(not game.inventory_label.text.contains("FEED") and game.inventory_label.text.contains("BOLTS"),
		"HUD no longer prints the full farm inventory during play")
	_ok(game.warmth_glyph != null and game.fuel_glyph != null and game.compass_glyph != null and game.objective_arrow != null,
		"HUD uses native survival glyphs and a directional objective arrow")
	game.farm.heat_reclaimer_installed = false
	game.farm.thermal_regulators = 1
	game._update_hud()
	_ok(game.objective_panel.visible and game.order_label.text.contains("THERMAL REGULATOR"),
		"HUD promotes a recovered cave component without becoming an inventory dump")
	game.farm.thermal_regulators = 0
	game.farm.heat_reclaimer_installed = true
	game.farm.temperature = 5.0
	game._update_hud()
	_ok(game.cold_overlay != null and game.cold_overlay.color.a > 0.15 and game.state_label.text == "COLD",
		"critical cold creates a pale freezing screen warning")
	game.farm.temperature = 15.0
	game.menu._on_instructions()
	_ok(game.menu.visible and game.menu.current_screen == "instructions" and get_tree().paused,
		"survival guide opens as a pause-safe menu screen")
	_ok(_tree_text_contains(game.menu, "CONTAIN") and _tree_text_contains(game.menu, "RETURN"),
		"survival guide presents hunt and cave instructions as icon-led action cards")
	game.menu._back()
	_ok(not game.menu.visible and not get_tree().paused, "leaving the guide returns cleanly to first-person play")


func _test_pause_menu() -> void:
	var pause := InputEventAction.new()
	pause.action = "pause"
	pause.pressed = true
	game.player._unhandled_input(pause)
	_ok(game.menu.visible and get_tree().paused, "pause action opens the pause menu")
	game.menu.close_menu()
	_ok(not game.menu.visible and not get_tree().paused, "resume unpauses the simulation")
