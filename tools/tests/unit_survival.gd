extends "res://tools/tests/test_base.gd"

## LEVEL 1 - survival, heat and hunger, straight against FarmState.
##
## No scene, no frames, no waiting: this is the model that every survival
## workflow ultimately drives, so a broken fuel burn or hunger tick fails here in
## under a second instead of four minutes into the end-to-end run.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/unit_survival.tscn

const TICK_HOUR := 60.0


func _init() -> void:
	suite_name = "unit_survival"
	suite_level = "unit"
	needs_scene = false
	timeout_seconds = 40.0


func run_phases() -> void:
	_test_new_game_shape()
	_test_furnace_burn_and_heat()
	_test_reclaimer_burn_bonus()
	_test_hunger_and_eating()
	_test_venom_and_antidote()
	_test_tray_growth_and_harvest()
	_test_butcher_yields()
	_test_upgrade_gate()
	_test_save_round_trip()


func _state() -> FarmState:
	var fresh := FarmState.new()
	fresh.new_game()
	return fresh


func _test_new_game_shape() -> void:
	begin_case("new_game", "a fresh farm starts in a known state")
	var survivor: FarmState = _state()
	_eq(int(survivor.day), 1, "a new farm starts on day one")
	_ok(is_equal_approx(float(survivor.clock), 6.0), "a new farm starts at six in the morning", str(survivor.clock))
	_ok(is_equal_approx(float(survivor.feed), 6.0), "a new farm starts with six feed", str(survivor.feed))
	_ok(is_equal_approx(float(survivor.fuel), 8.0), "a new farm starts with eight fuel", str(survivor.fuel))
	_ok(is_equal_approx(float(survivor.temperature), 26.0), "a new farm starts just inside the warm band", str(survivor.temperature))
	_eq(survivor.active_tray_count(), 1, "a new farm starts one live tray")
	_ok(survivor.furnace_lit, "the furnace starts lit for the first night")
	_ok(is_equal_approx(float(survivor.hunger_hours), FarmState.RATION_HUNGER_HOURS),
		"a new farm starts fed", str(survivor.hunger_hours))
	end_case()


func _test_furnace_burn_and_heat() -> void:
	begin_case("furnace", "fuel burns at the documented rate and warms the room")
	var survivor: FarmState = _state()
	survivor.furnace_lit = true
	var fuel_before: float = float(survivor.fuel)
	var heat_before: float = float(survivor.temperature)
	survivor.advance_minutes(TICK_HOUR)
	# FUEL_HOURS[0] is 6.0 h per unit, so one in-game hour costs 1/6 of a unit.
	var burned: float = fuel_before - float(survivor.fuel)
	_ok(absf(burned - 1.0 / 6.0) < 0.002,
		"one hour of fire spends 1/6 of a fuel unit", "burned %.4f" % burned)
	_ok(float(survivor.temperature) > heat_before,
		"a lit furnace raises the room temperature", "%0.2f -> %0.2f" % [heat_before, survivor.temperature])

	survivor.advance_minutes(TICK_HOUR * 40.0)
	_ok(float(survivor.temperature) <= 27.05,
		"the room plateaus at the furnace's target instead of climbing forever",
		str(survivor.temperature))
	_ok(survivor.temperature_band() != "FREEZING",
		"a burning furnace keeps the room out of the freezing band", survivor.temperature_band())
	end_case()


func _test_reclaimer_burn_bonus() -> void:
	begin_case("reclaimer", "the fitted cave regulator stretches the same fuel")
	var plain: FarmState = _state()
	var fitted: FarmState = _state()
	plain.furnace_lit = true
	fitted.furnace_lit = true
	fitted.heat_reclaimer_installed = true
	var start_fuel: float = float(plain.fuel)
	plain.advance_minutes(TICK_HOUR)
	fitted.advance_minutes(TICK_HOUR)
	var plain_burn: float = start_fuel - float(plain.fuel)
	var fitted_burn: float = start_fuel - float(fitted.fuel)
	_ok(fitted_burn < plain_burn * 0.85,
		"the heat reclaimer slows fuel burn by roughly 30%",
		"plain %.4f, fitted %.4f" % [plain_burn, fitted_burn])
	end_case()


func _test_hunger_and_eating() -> void:
	begin_case("hunger", "hunger falls with the clock and a ration answers it")
	var survivor: FarmState = _state()
	survivor.advance_minutes(TICK_HOUR)
	_ok(absf(float(survivor.hunger_hours) - 29.0) < 0.05,
		"one in-game hour costs one hunger hour", str(survivor.hunger_hours))

	var rations_before: int = int(survivor.rations)
	var full: String = survivor.eat()
	_ok(full.contains("Not hungry"), "a fed survivor is refused a ration", full)
	_eq(survivor.rations, rations_before, "the refused ration is not spent")

	survivor.hunger_hours = 4.0
	survivor.rations = 1
	var eaten: String = survivor.eat()
	_ok(eaten.contains("Ate one ration"), "a hungry survivor eats", eaten)
	_eq(survivor.rations, 0, "eating spends exactly one ration")
	_ok(is_equal_approx(float(survivor.hunger_hours), FarmState.RATION_HUNGER_HOURS),
		"eating restores the full hunger budget", str(survivor.hunger_hours))
	_ok(not survivor.starving, "eating clears starvation")

	var empty: String = survivor.eat()
	_ok(empty.contains("No rations"), "an empty shelf refuses to feed anyone", empty)
	end_case()


func _test_venom_and_antidote() -> void:
	begin_case("venom", "venom bites down on the body until an antidote is drunk")
	var survivor: FarmState = _state()
	survivor.apply_venom()
	_ok(is_equal_approx(float(survivor.venom_seconds), FarmState.VENOM_SECONDS),
		"a bite applies the full venom timer", str(survivor.venom_seconds))
	_ok(float(survivor.hand_speed()) < 1.0 and float(survivor.move_speed_scale()) < 1.0,
		"venom slows the hands and the legs",
		"hand %.2f move %.2f" % [survivor.hand_speed(), survivor.move_speed_scale()])
	survivor.tick_venom(10.0)
	_ok(absf(float(survivor.venom_seconds) - (FarmState.VENOM_SECONDS - 10.0)) < 0.01,
		"venom ticks down with real time", str(survivor.venom_seconds))

	survivor.chitin = 1
	survivor.water = 1
	var brewed: String = survivor.brew()
	_ok(int(survivor.antidotes) == 1, "chitin and water brew an antidote", brewed)
	_eq(survivor.chitin, 0, "brewing spends the chitin")
	_eq(survivor.water, 0, "brewing spends the water")
	var drunk: String = survivor.drink()
	_ok(is_zero_approx(float(survivor.venom_seconds)), "drinking the antidote clears venom", drunk)
	_eq(survivor.antidotes, 0, "drinking spends the antidote")
	end_case()


func _test_tray_growth_and_harvest() -> void:
	begin_case("trays", "trays grow, crickets net live, maggots still harvest as mass")
	var survivor: FarmState = _state()
	survivor.furnace_lit = true
	survivor.temperature = 27.0
	var progress_before: float = float(survivor.trays[0]["progress"])
	survivor.advance_minutes(TICK_HOUR)
	_ok(float(survivor.trays[0]["progress"]) > progress_before,
		"a live tray makes progress in a warm room",
		"%.3f -> %.3f" % [progress_before, survivor.trays[0]["progress"]])

	# A cricket tray is taken alive, and only with a net: the old generic "mass"
	# harvest moved to the maggot trays when the culture loop began.
	# Ripeness is a population, not a progress bar: 27 is the first scoopable size.
	survivor.trays[0]["population"] = FarmState.CRICKET_HARVEST_POPULATION
	survivor.trays[0]["growth_minutes"] = FarmState.CRICKET_FIRST_MILESTONE_MINUTES
	var refused: String = survivor.harvest_tray(0)
	_ok(refused.contains("net"), "a cricket tray cannot be harvested without a net", refused)
	_eq(int(survivor.live_crickets), 0, "a refused harvest takes nothing alive")
	_eq(int(survivor.tray_population(0)), FarmState.CRICKET_HARVEST_POPULATION,
		"a refused harvest leaves the colony ripe")

	survivor.net_crafted = true
	var live_before: int = int(survivor.live_crickets)
	var harvested: String = survivor.harvest_tray(0)
	_eq(int(survivor.live_crickets),
		live_before + FarmState.CRICKET_HARVEST_POPULATION - FarmState.CRICKET_BREEDING_RESERVE,
		"a mature cricket tray nets everything above the reserve")
	_eq(int(survivor.tray_population(0)), FarmState.CRICKET_BREEDING_RESERVE,
		"the breeding reserve stays behind")

	survivor.trays[1]["active"] = true
	survivor.trays[1]["species"] = "maggot"
	survivor.trays[1]["progress"] = 1.0
	var mass_before: int = int(survivor.mass)
	var maggot_harvest: String = survivor.harvest_tray(1)
	_eq(int(survivor.mass), mass_before + 1, "a mature maggot tray still harvests into insect mass")
	_ok(maggot_harvest.contains("mass"), "the maggot harvest still reports insect mass", maggot_harvest)
	_eq(int(survivor.live_crickets),
		live_before + FarmState.CRICKET_HARVEST_POPULATION - FarmState.CRICKET_BREEDING_RESERVE,
		"maggots do not add live crickets")
	end_case()


func _test_butcher_yields() -> void:
	begin_case("butcher", "butchering pays feed, fuel, chitin and hide")
	var survivor: FarmState = _state()
	var feed_before: float = float(survivor.feed)
	var fuel_before: float = float(survivor.fuel)
	var chitin_before: int = int(survivor.chitin)
	var hides_before: int = int(survivor.hides)
	survivor.butcher("A")
	_ok(is_equal_approx(float(survivor.feed), feed_before + 4.0), "butchering creates tray feed")
	_ok(is_equal_approx(float(survivor.fuel), fuel_before + 4.0), "butchering creates furnace fuel")
	_eq(int(survivor.chitin), chitin_before + 2, "butchering creates two chitin")
	_eq(int(survivor.hides), hides_before + 1, "butchering creates one hide")
	end_case()


func _test_upgrade_gate() -> void:
	begin_case("upgrades", "an upgrade needs parts before it changes the room")
	var survivor: FarmState = _state()
	survivor.parts = 0
	_ok(not survivor.can_upgrade("throughput"), "an upgrade is refused with no parts")
	var refused: String = survivor.buy_upgrade("throughput")
	_ok(refused.contains("needs"), "the refusal names the missing parts", refused)
	_eq(int(survivor.upgrades["throughput"]), 0, "a refused upgrade changes nothing")

	survivor.parts = int(FarmState.UPGRADE_COSTS[0])
	_ok(survivor.can_upgrade("throughput"), "the first tier is affordable with its listed cost")
	survivor.buy_upgrade("throughput")
	_eq(int(survivor.parts), 0, "buying the upgrade spends exactly its cost")
	_eq(int(survivor.upgrades["throughput"]), 1, "the upgrade tier advances")
	_eq(survivor.active_tray_count(), FarmState.TRAY_SLOTS,
		"the first throughput tier brings every tray slot online")
	end_case()


func _test_save_round_trip() -> void:
	begin_case("save", "the survival model survives a save round trip")
	var survivor: FarmState = _state()
	survivor.day = 9
	survivor.fuel = 1.5
	survivor.temperature = 23.25
	survivor.hunger_hours = 11.5
	survivor.venom_seconds = 42.0
	survivor.mass = 4
	var snapshot: Dictionary = survivor.to_save()
	var restored: FarmState = FarmState.new()
	var loaded: bool = restored.from_save(snapshot)
	_ok(loaded, "the save shape is accepted")
	_eq(int(restored.day), 9, "the save restores the day")
	_ok(is_equal_approx(float(restored.fuel), 1.5), "the save restores fuel", str(restored.fuel))
	_ok(is_equal_approx(float(restored.temperature), 23.25), "the save restores temperature", str(restored.temperature))
	_ok(is_equal_approx(float(restored.hunger_hours), 11.5), "the save restores hunger", str(restored.hunger_hours))
	_ok(is_equal_approx(float(restored.venom_seconds), 42.0), "the save restores an active venom timer", str(restored.venom_seconds))
	_eq(int(restored.mass), 4, "the save restores stored mass")
	_eq(int(snapshot.get("version", 0)), FarmState.SAVE_VERSION, "the save declares the current schema version")
	end_case()
