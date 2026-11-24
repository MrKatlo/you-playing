extends "res://tools/tests/test_base.gd"

## LEVEL 3 - the preserved full gameplay run, now an orchestrator instead of a
## 1400-line script.
##
## Every step below is a real module from tools/tests/ driving the real
## production scene. Because the modules are the same files the player-facing
## suites run on their own, this run cannot drift away from them: fixing a module
## fixes the end-to-end run too, and adding a module step here is one line.
##
## The order is the original one, and it is order-dependent on purpose: it is a
## single continuous shift (one scene, one player, one farm) rather than a set of
## isolated procedures. The modular suites are the ones that must stand alone.
##
## Run:
##   Godot --headless --path . res://tools/tests/e2e_gameplay.tscn
##   (tools/test_basement_farm.tscn still works and forwards here)

const MODULE_SCRIPTS := {
	"interaction": "res://tools/tests/workflow_interaction.gd",
	"creatures": "res://tools/tests/workflow_creatures.gd",
	"survival": "res://tools/tests/workflow_survival.gd",
	"crafting": "res://tools/tests/workflow_crafting.gd",
	"weapons": "res://tools/tests/workflow_weapons.gd",
	"ui": "res://tools/tests/workflow_ui.gd",
}

var modules := {}


func _init() -> void:
	suite_name = "e2e_gameplay"
	suite_level = "e2e"
	timeout_seconds = 600.0


func run_phases() -> void:
	# The three launch checks the old single-file runner made before anything else:
	# the run is only meaningful if the real scene, the real player and the real
	# menu came up.
	_ok(game.farm != null, "farm state is created")
	_ok(game.player != null, "first-person player is created")
	_ok(game.menu != null, "title menu is created and can be closed")

	for key in MODULE_SCRIPTS:
		var suite = load(MODULE_SCRIPTS[key]).new()
		suite.auto_run = false
		add_child(suite)
		suite.game = game
		suite.player = player
		suite.farm = farm
		modules[key] = suite

	await _case("interaction", "_test_new_shift", "a shift starts from the bed")
	await _case("interaction", "_test_stations", "the stations exist and answer interact")
	await _case("interaction", "_test_cave_access", "the cave threshold opens and closes")
	await _case("creatures", "_test_cricket_and_gecko_motion", "tray animals live and move")
	await _case("interaction", "_test_player_input", "real input moves and interacts")
	await _case("interaction", "_test_hunt_doorway_clearance", "the hunt doorway is walkable")
	await _case("survival", "_test_farming_loop", "harvest and butcher yield materials")
	await _case("crafting", "_test_workbench_loop", "a recipe spends and produces")
	await _case("crafting", "_test_tactical_loadout", "the bolt loadout can be chosen")
	await _case("weapons", "_test_tool_slots", "tool slots hold their rules")
	await _case("weapons", "_test_phase_a1_machete_system", "the machete cuts and kills")
	await _case("creatures", "_test_phase_a2_creature_combat", "the creature senses, telegraphs and pounces")
	await _case("creatures", "_test_phase_a3_step_dodge", "a step dodges the pounce")
	await _case("creatures", "_test_phase_a4_landing_guard", "the landing guard answers a blade")
	await _case("creatures", "_test_hunt_pressure", "the creature stalks and chases")
	await _case("creatures", "_test_slime_facing_and_revive", "the creature survives a death")
	await _case("survival", "_test_order_loop", "an order packs and pays")
	await _case("survival", "_test_survival_and_save_shape", "survival state saves and loads")
	await _case("interaction", "_test_burrower_and_shutter", "the shutter contains the creature")
	await _case("ui", "_test_hud_and_menu", "the HUD reports the state")
	await _case("ui", "_test_pause_menu", "the pause menu freezes the world")


## Run one module phase and roll its counters and failure records into this run,
## so the end-to-end result line still means what it always meant.
func _case(module_key: String, method: String, label: String) -> void:
	var suite = modules[module_key]
	var checks_before: int = suite.checks
	var fails_before: int = suite.fails
	begin_case("%s.%s" % [module_key, method.trim_prefix("_test_")], label)
	await suite.callv(method, [])
	end_case()
	checks += suite.checks - checks_before
	fails += suite.fails - fails_before
	for index in range(_failures.size(), suite._failures.size()):
		_failures.append(suite._failures[index])
