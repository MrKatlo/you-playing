extends "res://tools/tests/test_base.gd"

## LEVEL 1 — Phase C4 // the cold store's rules, without the room.
##
## Three jars that pay once, a crate that pays once, and a cold frame that has to
## be sealed with a real insulation patch before it will keep a meal. All of that
## is model state, so it is pinned here in a fraction of a second.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/unit_c4_cold_store.tscn


func _init() -> void:
	suite_name = "unit_c4_cold_store"
	suite_level = "unit"
	needs_scene = false
	timeout_seconds = 40.0


func run_phases() -> void:
	_test_jar_search()
	_test_crate_loot()
	_test_frame_needs_a_patch()
	_test_frame_keeps_one_meal()
	_test_save_shape()
	_test_new_game_resets()


func _state() -> FarmState:
	var fresh := FarmState.new()
	fresh.new_game()
	fresh.furnace_lit = true
	fresh.temperature = 26.0
	return fresh


# ------------------------------------------------------------------- search

func _test_jar_search() -> void:
	begin_case("jars", "each intact jar is searchable once and pays parts, not food")
	var store := _state()
	var parts_before: int = store.parts
	_eq(store.cold_store_jars_searched.size(), 0, "a fresh store has searched nothing")
	_ok(store.search_cold_store_jar(0).begins_with("A jar of old stock"), "the first jar gives up its stock")
	_eq(store.parts, parts_before + 1, "and pays one part")
	_eq(store.cold_store_jars_searched, [0] as Array[int], "the jar is recorded as emptied")
	_ok(store.search_cold_store_jar(0).begins_with("That jar is empty"), "the same jar refuses a second search")
	_eq(store.parts, parts_before + 1, "and pays nothing more")
	for index in [1, 2]:
		_ok(store.search_cold_store_jar(index).begins_with("A jar of old stock"), "jar %d still has stock" % index)
	_eq(store.parts, parts_before + 3, "three intact jars pay three parts in total")
	_ok(store.search_cold_store_jar(3).begins_with("No jar there"), "there is no fourth jar")
	_ok(store.search_cold_store_jar(-1).begins_with("No jar there"), "and no jar behind the shelf")
	end_case()


func _test_crate_loot() -> void:
	begin_case("crate", "the sealed crate pays parts and one heat gland, once")
	var store := _state()
	var parts_before: int = store.parts
	var glands_before: int = store.heat_glands
	_ok(store.open_cold_store_crate().begins_with("The seal gives"), "the wire twist gives way")
	_eq(store.parts, parts_before + FarmState.COLD_STORE_CRATE_PARTS, "it holds two parts")
	_eq(store.heat_glands, glands_before + FarmState.COLD_STORE_CRATE_GLANDS, "and one heat gland")
	_ok(store.open_cold_store_crate().begins_with("The crate is already open"), "a second open finds nothing")
	_eq(store.parts, parts_before + FarmState.COLD_STORE_CRATE_PARTS, "the crate does not pay twice")
	end_case()


# -------------------------------------------------------------------- frame

func _test_frame_needs_a_patch() -> void:
	begin_case("frame_gate", "the cold frame is gated on a real insulation patch")
	var store := _state()
	store.patches = 0
	_ok(store.install_cold_frame().contains("needs an insulation patch"), "a bare frame refuses to be fitted")
	_ok(not store.cold_frame_installed, "and stays unfitted")
	_eq(store.patches, 0, "without spending a patch it does not have")
	store.patches = 1
	_ok(store.install_cold_frame().contains("pane is sealed"), "one patch seals the cracked pane")
	_ok(store.cold_frame_installed, "the frame is fitted")
	_eq(store.patches, 0, "and the patch is spent")
	_ok(store.install_cold_frame().contains("already fitted"), "a second fit is refused")
	_eq(store.patches, 0, "and costs nothing")
	end_case()


func _test_frame_keeps_one_meal() -> void:
	begin_case("frame_meal", "an unfitted frame does nothing; a fitted one keeps exactly one meal")
	var store := _state()
	store.patches = 1
	store.meals = 0
	_ok(store.cold_frame_action().contains("pane is sealed"), "the frame verb fits the frame first")
	_ok(store.cold_frame_action().contains("Nothing cooked to keep"), "with no meal in the pack there is nothing to keep")
	store.meals = 1
	_ok(store.cold_frame_action().contains("MEAL IN THE COLD FRAME"), "a cooked meal goes into the frame")
	_ok(store.cold_frame_meal, "the frame reports a stored meal")
	_eq(store.meals, 0, "and the meal leaves the pack")
	_ok(store.cold_frame_action().contains("Not hungry yet"), "a full survivor cannot eat it yet")
	_ok(store.cold_frame_meal, "so the meal stays in the frame")
	store.hunger_hours = 4.0
	_ok(store.cold_frame_action().contains("twice the value"), "a hungry survivor eats the cold meal")
	_ok(not store.cold_frame_meal, "the frame is empty again")
	_eq(store.hunger_hours, FarmState.MEAL_HUNGER_HOURS * 2.0, "the kept meal is worth double hunger hours")
	_ok(not store.starving, "and clears starvation")
	_ok(store.cold_frame_action().contains("Nothing cooked to keep"), "eating the meal does not refill it")
	end_case()


# --------------------------------------------------------------------- save

func _test_save_shape() -> void:
	begin_case("save", "the store's four pieces of state survive a round trip and old saves migrate")
	var store := _state()
	store.patches = 1
	store.meals = 1
	store.search_cold_store_jar(0)
	store.open_cold_store_crate()
	store.install_cold_frame()
	store.cold_frame_action()
	var data: Dictionary = store.to_save()
	_eq(int(data.get("version", 0)), FarmState.SAVE_VERSION, "the save uses the current schema")
	_eq((data.get("cold_store_jars_searched", []) as Array).size(), 1, "searched jars are written")
	_ok(bool(data.get("cold_store_crate_opened", false)), "the opened crate is written")
	_ok(bool(data.get("cold_frame_installed", false)), "the fitted frame is written")
	_ok(bool(data.get("cold_frame_meal", false)), "the kept meal is written")

	var loaded := FarmState.new()
	_ok(loaded.from_save(data), "the save loads")
	_eq(loaded.cold_store_jars_searched, [0] as Array[int], "the searched jar comes back")
	_ok(loaded.cold_store_crate_opened, "the open crate comes back")
	_ok(loaded.cold_frame_installed and loaded.cold_frame_meal, "the fitted frame and its meal come back")
	_ok(loaded.open_cold_store_crate().begins_with("The crate is already open"), "and the crate will not pay again after a load")

	# Schema 10 and older have no cold store at all: the room simply arrives
	# untouched, which is the safe direction for an old shift.
	var old: Dictionary = data.duplicate(true)
	old["version"] = 10
	old.erase("cold_store_jars_searched")
	old.erase("cold_store_crate_opened")
	old.erase("cold_frame_installed")
	old.erase("cold_frame_meal")
	var migrated := FarmState.new()
	migrated.from_save(old)
	_eq(migrated.cold_store_jars_searched.size(), 0, "an old save has searched no jars")
	_ok(not migrated.cold_store_crate_opened and not migrated.cold_frame_installed, "its crate is sealed and its frame is bare")
	_ok(not migrated.cold_frame_meal, "and it keeps no meal")
	end_case()


func _test_new_game_resets() -> void:
	begin_case("new_game", "a new shift starts with the store untouched")
	var store := _state()
	store.patches = 1
	store.meals = 1
	store.search_cold_store_jar(0)
	store.open_cold_store_crate()
	store.install_cold_frame()
	store.cold_frame_action()
	store.new_game()
	_eq(store.cold_store_jars_searched.size(), 0, "searched jars are cleared")
	_ok(not store.cold_store_crate_opened, "the crate is sealed again")
	_ok(not store.cold_frame_installed, "the frame is bare again")
	_ok(not store.cold_frame_meal, "and holds no meal")
	end_case()
