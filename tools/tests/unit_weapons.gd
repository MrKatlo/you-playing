extends "res://tools/tests/test_base.gd"

## LEVEL 1 - ammunition, the bolt driver's wear, and the snare, straight against
## FarmState. This is the state authority the weapon workflow reads, so a broken
## ammo count fails here in a second rather than in a four-minute run.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/unit_weapons.tscn


func _init() -> void:
	suite_name = "unit_weapons"
	suite_level = "unit"
	needs_scene = false
	timeout_seconds = 40.0


func run_phases() -> void:
	_test_ammo_counts()
	_test_loadout_cycle()
	_test_consumption_spends_the_selected_pool()
	_test_empty_pool_refuses()
	_test_driver_wear()
	_test_snare_state()


func _state() -> FarmState:
	var fresh := FarmState.new()
	fresh.new_game()
	return fresh


func _test_ammo_counts() -> void:
	begin_case("counts", "each ammunition type reports its own count")
	var survivor: FarmState = _state()
	survivor.bolts = 7
	survivor.broadhead_bolts = 2
	survivor.tether_bolts = 1
	_eq(int(survivor.ammo_count("standard")), 7, "standard ammo reports the salvage pool")
	_eq(int(survivor.ammo_count("broadhead")), 2, "broadhead ammo reports its own pool")
	_eq(int(survivor.ammo_count("tether")), 1, "tether ammo reports its own pool")
	_eq(int(survivor.ammo_count("unknown")), 0, "an unknown ammunition type reports empty")
	survivor.selected_bolt_type = "broadhead"
	_eq(int(survivor.ammo_count()), 2, "the default count is the selected pool")
	_eq(str(survivor.selected_ammo_label()), "BROADHEAD", "the selected pool has a readable label")
	end_case()


func _test_loadout_cycle() -> void:
	begin_case("cycle", "the loadout cycles in one predictable order")
	var survivor: FarmState = _state()
	survivor.selected_bolt_type = "standard"
	_eq(str(survivor.cycle_bolt_type()), "BROADHEAD", "standard cycles to broadhead")
	_eq(str(survivor.cycle_bolt_type()), "TETHER", "broadhead cycles to tether")
	_eq(str(survivor.cycle_bolt_type()), "SALVAGE", "tether wraps back to salvage")
	_eq(str(survivor.selected_bolt_type), "standard", "the cycle lands back where it started")
	end_case()


func _test_consumption_spends_the_selected_pool() -> void:
	begin_case("consume", "firing spends the selected pool and nothing else")
	var survivor: FarmState = _state()
	survivor.bolts = 3
	survivor.broadhead_bolts = 2
	survivor.selected_bolt_type = "broadhead"
	var spent: bool = survivor.consume_selected_ammo()
	_ok(spent, "a loaded broadhead can be spent")
	_eq(int(survivor.broadhead_bolts), 1, "the broadhead pool loses one")
	_eq(int(survivor.bolts), 3, "the salvage pool is untouched")
	end_case()


func _test_empty_pool_refuses() -> void:
	begin_case("empty", "an empty pool cannot be fired")
	var survivor: FarmState = _state()
	survivor.bolts = 0
	survivor.broadhead_bolts = 4
	survivor.selected_bolt_type = "standard"
	var spent: bool = survivor.consume_selected_ammo()
	_ok(not spent, "an empty selected pool refuses to fire")
	_eq(int(survivor.bolts), 0, "the empty pool stays empty")
	_eq(int(survivor.broadhead_bolts), 4, "an unspent broadhead is not stolen by a dry click")
	end_case()


func _test_driver_wear() -> void:
	begin_case("wear", "the driver wears down and cannot pass zero")
	var survivor: FarmState = _state()
	_eq(int(survivor.driver_durability), FarmState.DRIVER_MAX_DURABILITY,
		"the driver starts at full pressure")
	survivor.wear_driver(3)
	_eq(int(survivor.driver_durability), FarmState.DRIVER_MAX_DURABILITY - 3,
		"a shot's wear is exact")
	survivor.wear_driver(FarmState.DRIVER_MAX_DURABILITY + 5)
	_eq(int(survivor.driver_durability), 0, "driving past the limit clamps at zero")
	survivor.wear_driver(-4)
	_eq(int(survivor.driver_durability), 0, "a negative wear cannot repair the driver")
	end_case()


func _test_snare_state() -> void:
	begin_case("snare", "the floor snare is armed once and springs once")
	var survivor: FarmState = _state()
	survivor.snares = 0
	var refused: String = survivor.arm_snare()
	_ok(refused.contains("Need a floor snare"), "an unbuilt snare cannot be armed", refused)
	_ok(not survivor.snare_armed, "a refused arming leaves the floor clear")

	survivor.snares = 1
	var armed: String = survivor.arm_snare()
	_ok(survivor.snare_armed, "a built snare arms", armed)
	_eq(int(survivor.snares), 0, "arming the snare spends it")
	var again: String = survivor.arm_snare()
	_ok(again.contains("already armed"), "a second snare cannot be set on the same mark", again)

	survivor.trigger_snare()
	_ok(not survivor.snare_armed, "springing the snare clears the armed state")

	# The physical lever can also fold a set trap back into the pack.
	survivor.snares = 1
	survivor.arm_snare()
	_ok(survivor.snare_armed, "the trap can be set again after a spring")
	survivor.disarm_snare()
	_ok(not survivor.snare_armed, "disarming clears the armed state")
	_eq(int(survivor.snares), 1, "disarming returns the trap to the pack")
	var clear_again: String = survivor.disarm_snare()
	_ok(clear_again.contains("already clear"), "disarming an empty mark changes nothing", clear_again)
	_eq(int(survivor.snares), 1, "a refused disarm cannot duplicate the trap")
	end_case()
