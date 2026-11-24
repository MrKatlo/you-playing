extends "res://tools/tests/test_base.gd"

## LEVEL 1 - the workbench model: what a recipe costs, what it pays, and when it
## refuses. Straight against FarmState, no scene.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/unit_crafting.tscn


func _init() -> void:
	suite_name = "unit_crafting"
	suite_level = "unit"
	needs_scene = false
	timeout_seconds = 40.0


func run_phases() -> void:
	_test_catalog()
	_test_ammunition_gate()
	_test_exact_costs_and_yields()
	_test_shortfall_is_free()
	_test_antidote_singleton()
	_test_driver_repair()
	_test_installed_upgrades_are_one_shot()
	_test_insulation_patch_installs()


func _state() -> FarmState:
	var fresh := FarmState.new()
	fresh.new_game()
	return fresh


func _test_catalog() -> void:
	begin_case("catalog", "every pinned pattern is reachable by id")
	var survivor: FarmState = _state()
	var ids: Array = survivor.workbench_recipe_ids()
	_eq(ids.size(), FarmState.WORKBENCH_RECIPE_ORDER.size(), "the bench lists every pinned pattern")
	for recipe_id in FarmState.WORKBENCH_RECIPE_ORDER:
		_ok(ids.has(recipe_id), "the bench lists %s" % recipe_id)
		_ok(not survivor.workbench_recipe(recipe_id).is_empty(), "%s carries a real definition" % recipe_id)
	_ok(survivor.workbench_recipe("not_a_recipe").is_empty(), "an unknown id has no definition")
	end_case()


func _test_ammunition_gate() -> void:
	begin_case("ammo_gate", "ammunition needs a body to learn from")
	var survivor: FarmState = _state()
	survivor.parts = 3
	survivor.chitin = 3
	survivor.kills = 0
	var refused: String = survivor.craft_at_workbench("basic_bolts")
	_ok(refused.contains("No ammunition pattern"), "the bench refuses ammunition before the first kill", refused)
	_eq(int(survivor.bolts), 0, "the refused craft produces no bolts")
	_eq(int(survivor.parts), 3, "the refused craft spends no parts")
	_eq(int(survivor.chitin), 3, "the refused craft spends no chitin")

	survivor.kills = 1
	var made: String = survivor.craft_at_workbench("basic_bolts")
	_eq(int(survivor.bolts), 3, "the same craft yields three bolts once a kill is recorded")
	_ok(made.contains("SALVAGE"), "the craft reports what it made", made)
	end_case()


func _test_exact_costs_and_yields() -> void:
	begin_case("costs", "each recipe spends its listed cost and pays its listed output")
	var survivor: FarmState = _state()
	survivor.kills = 1
	survivor.parts = 6
	survivor.chitin = 4
	survivor.hides = 2

	survivor.craft_at_workbench("basic_bolts")
	_eq(int(survivor.parts), 5, "salvage bolts cost one part")
	_eq(int(survivor.chitin), 3, "salvage bolts cost one chitin")
	_eq(int(survivor.bolts), 3, "salvage bolts pay three bolts")

	survivor.craft_at_workbench("broadhead_bolts")
	_eq(int(survivor.parts), 4, "broadheads cost one part")
	_eq(int(survivor.chitin), 1, "broadheads cost two chitin")
	_eq(int(survivor.broadhead_bolts), 2, "broadheads pay two bolts")

	survivor.craft_at_workbench("tether_bolt")
	_eq(int(survivor.parts), 3, "a tether costs one part")
	_eq(int(survivor.hides), 1, "a tether costs one hide")
	_eq(int(survivor.tether_bolts), 1, "a tether pays one bolt")
	end_case()


func _test_shortfall_is_free() -> void:
	begin_case("shortfall", "a craft that cannot be paid for changes nothing")
	var survivor: FarmState = _state()
	survivor.kills = 1
	survivor.parts = 3
	survivor.chitin = 0
	_ok(not survivor.can_craft_at_workbench("broadhead_bolts"),
		"the bench reports the missing chitin")
	var refused: String = survivor.craft_at_workbench("broadhead_bolts")
	_ok(refused.contains("Need"), "the refusal names the missing resource", refused)
	_eq(int(survivor.parts), 3, "a refused craft spends no parts")
	_eq(int(survivor.broadhead_bolts), 0, "a refused craft produces nothing")
	end_case()


func _test_antidote_singleton() -> void:
	begin_case("antidote", "only one antidote can be held at a time")
	var survivor: FarmState = _state()
	survivor.chitin = 2
	survivor.water = 2
	survivor.craft_at_workbench("antidote")
	_eq(int(survivor.antidotes), 1, "chitin and water make one antidote")
	_eq(int(survivor.water), 1, "the first antidote spends one water")
	_ok(not survivor.can_craft_at_workbench("antidote"), "a held antidote blocks the pattern")
	var refused: String = survivor.craft_at_workbench("antidote")
	_ok(refused.contains("already have"), "the refusal explains the limit", refused)
	_eq(int(survivor.water), 1, "the refused antidote spends no water")
	end_case()


func _test_driver_repair() -> void:
	begin_case("repair", "the driver is only repairable when it is actually worn")
	var survivor: FarmState = _state()
	survivor.parts = 3
	survivor.chitin = 3
	_ok(not survivor.can_craft_at_workbench("driver_repair"),
		"a full-pressure driver offers no repair pattern")
	var refused: String = survivor.craft_at_workbench("driver_repair")
	_ok(refused.contains("full pressure"), "the refusal explains why", refused)
	_eq(int(survivor.parts), 3, "the refused repair spends no parts")

	survivor.wear_driver(5)
	_ok(survivor.can_craft_at_workbench("driver_repair"), "a worn driver can be rebuilt")
	survivor.craft_at_workbench("driver_repair")
	_eq(int(survivor.driver_durability), FarmState.DRIVER_MAX_DURABILITY,
		"the rebuild restores full pressure")
	_eq(int(survivor.parts), 2, "the rebuild spends its part")
	end_case()


func _test_installed_upgrades_are_one_shot() -> void:
	begin_case("installs", "installed upgrades cannot be bought twice")
	var survivor: FarmState = _state()
	survivor.parts = 6
	survivor.chitin = 2
	survivor.hides = 2
	survivor.thermal_regulators = 1

	survivor.craft_at_workbench("warm_storage_rack")
	_ok(survivor.storage_rack_installed, "the warm storage rack installs")
	_ok(not survivor.can_craft_at_workbench("warm_storage_rack"),
		"an installed rack leaves no pattern behind")

	survivor.craft_at_workbench("furnace_heat_reclaimer")
	_ok(survivor.heat_reclaimer_installed, "the C-4 reclaimer installs")
	_eq(int(survivor.thermal_regulators), 0, "installing the reclaimer spends the regulator")
	_ok(not survivor.can_craft_at_workbench("furnace_heat_reclaimer"),
		"an installed reclaimer leaves no pattern behind")
	end_case()


func _test_insulation_patch_installs() -> void:
	begin_case("patch", "a patch is crafted, held, and then spent at a real gap")
	var survivor: FarmState = _state()
	survivor.parts = 2
	survivor.hides = 1
	survivor.craft_at_workbench("insulation_patch")
	_eq(int(survivor.patches), 1, "two parts and a hide make one patch")
	_eq(int(survivor.parts), 0, "the patch spends both parts")

	var open_before: int = survivor.open_gap_count()
	var sealed: String = survivor.patch_gap(0)
	_eq(int(survivor.patches), 0, "installing the patch spends it")
	_ok(survivor.open_gap_count() == open_before - 1,
		"installing the patch closes one gap", "%d -> %d (%s)" % [open_before, survivor.open_gap_count(), sealed])
	var refused: String = survivor.patch_gap(0)
	_ok(refused.contains("already sealed"), "a sealed gap refuses a second patch", refused)
	end_case()
