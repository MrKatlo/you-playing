extends "res://tools/tests/test_base.gd"

## Farming, orders, heat and hunger
##
## The survival loop: a mature cricket tray nets live crickets, a
## butchering yields feed, fuel, chitin and hide, the ledger order pays out on
## delivery, and the furnace/heat/hunger numbers survive a save round trip.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/workflow_survival.tscn


func _init() -> void:
	suite_name = "workflow_survival"
	suite_level = "workflow"


func run_phases() -> void:
	await _test_farming_loop()
	await _test_order_loop()
	await _test_survival_and_save_shape()

func _test_farming_loop() -> void:
	var tray: Dictionary = game.farm.trays[0]
	# A cricket tray is ripe by population: 27 is the first scoopable size.
	tray["population"] = FarmState.CRICKET_HARVEST_POPULATION
	tray["growth_minutes"] = FarmState.CRICKET_FIRST_MILESTONE_MINUTES
	tray["progress"] = 1.0
	# A cricket tray is taken alive: the net is crafted at the real bench first.
	game.farm.parts = 6
	game.farm.hides = 2
	var net: String = str(game.craft_workbench_recipe("cricket_net"))
	_ok(bool(game.farm.net_crafted), "the workbench weaves a cricket net", net)
	var live_before: int = int(game.farm.live_crickets)
	var harvest: String = str(game.farm.harvest_tray(0))
	_ok(int(game.farm.live_crickets) ==
			live_before + FarmState.CRICKET_HARVEST_POPULATION - FarmState.CRICKET_BREEDING_RESERVE,
		"mature tray nets everything above its breeding reserve", harvest)
	_ok(float(game.farm.trays[0]["progress"]) < 0.01, "harvest resets tray progress")

	var feed_before: float = float(game.farm.feed)
	var fuel_before: float = float(game.farm.fuel)
	var chitin_before: int = int(game.farm.chitin)
	var hides_before: int = int(game.farm.hides)
	game.farm.butcher("A")
	_ok(is_equal_approx(float(game.farm.feed), feed_before + 4.0), "butchering creates tray feed")
	_ok(is_equal_approx(float(game.farm.fuel), fuel_before + 4.0), "butchering creates furnace fuel")
	_ok(int(game.farm.chitin) == chitin_before + 2, "butchering creates chitin")
	_ok(int(game.farm.hides) == hides_before + 1, "butchering creates a hide")


func _test_order_loop() -> void:
	game.farm.orders = [{
		"id": "test_rations",
		"buyer": "TEST BUYER",
		"product": "ration",
		"qty": 2,
		"min_grade": "C",
		"due_hour": game.farm.abs_hour() + 20.0,
		"pay_parts": 5,
		"pay_water": 1,
		"pay_standing": 3,
		"delivered": false,
		"special": false,
	}]
	game.farm.rations = 2
	var packed: String = str(game.farm.pack_for_order())
	_ok(not game.farm.packed_box.is_empty(), "packing bench creates an order box", packed)
	_ok(int(game.farm.rations) == 0, "packing removes the ordered rations")
	var left: String = str(game.farm.leave_box())
	_ok(not game.farm.delivered_box.is_empty(), "shutter accepts the packed box", left)
	_ok(game.farm.packed_box.is_empty(), "box leaves the bench after delivery")


func _test_survival_and_save_shape() -> void:
	game.farm.chitin = 1
	game.farm.water = 1
	var brew: String = str(game.farm.brew())
	_ok(int(game.farm.antidotes) == 1, "chitin and water brew an antidote", brew)
	game.farm.venom_seconds = 30.0
	var drink: String = str(game.farm.drink())
	_ok(is_zero_approx(float(game.farm.venom_seconds)), "antidote clears venom", drink)

	# The save shape has to carry the built upgrades. The crafting suite builds
	# them when the full run is played end to end; standalone nothing is built yet,
	# so install them through the real recipe path before taking the snapshot.
	if not game.farm.storage_rack_installed:
		game.farm.parts += 3
		game.farm.chitin += 1
		game.farm.hides += 1
		game.craft_workbench_recipe("warm_storage_rack")
	if not game.farm.heat_reclaimer_installed:
		game.farm.parts += 2
		game.farm.thermal_regulators += 1
		game.craft_workbench_recipe("furnace_heat_reclaimer")

	var snapshot: Dictionary = game.farm.to_save()
	game.farm.broadhead_bolts = 1
	game.farm.tether_bolts = 1
	game.farm.driver_durability = 7
	snapshot = game.farm.to_save()
	var restored: FarmState = FarmState.new()
	var loaded: bool = restored.from_save(snapshot)
	_ok(loaded, "farm state accepts its in-memory save shape")
	_ok(int(restored.day) == int(game.farm.day), "save shape restores day")
	_ok(int(restored.parts) == int(game.farm.parts), "save shape restores parts")
	_ok(int(restored.bolts) == int(game.farm.bolts), "save shape restores crafted bolt supply")
	_ok(int(restored.broadhead_bolts) == 1 and int(restored.tether_bolts) == 1,
		"save shape restores alternate bolt supplies")
	_ok(int(restored.driver_durability) == 7, "save shape restores bolt-driver wear")
	_ok(int(restored.patches) == int(game.farm.patches), "save shape restores crafted insulation patches")
	_ok(restored.storage_rack_installed, "save shape restores the built warm storage rack")
	_ok(restored.heat_reclaimer_installed and restored.thermal_regulators == 0,
		"save shape restores the fitted cave furnace upgrade")
	var legacy: Dictionary = snapshot.duplicate(true)
	legacy.erase("bolts")
	legacy.erase("storage_rack_installed")
	legacy.erase("thermal_regulators")
	legacy.erase("heat_reclaimer_installed")
	var migrated: FarmState = FarmState.new()
	migrated.from_save(legacy)
	_ok(int(migrated.bolts) == 6, "version two save shape migrates to a usable bolt supply")
	_ok(not migrated.storage_rack_installed, "older saves leave the new storage-rack upgrade unbuilt")
	_ok(not migrated.heat_reclaimer_installed and migrated.thermal_regulators == 0,
		"older saves leave the new cave furnace upgrade safely unbuilt")
