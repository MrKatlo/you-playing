extends "res://tools/tests/test_base.gd"

## LEVEL 1 — Phase C2 // culture: cricket husbandry, the kitchen and the save shape.
##
## No scene, no frames. The farm's multiplication verb, the alive-only harvest and
## the meal/jerky chain are all model rules, so they are pinned here in about a
## second instead of eight seconds into the workflow suite.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/unit_c2_culture.tscn

const HOUR := 60.0


func _init() -> void:
	suite_name = "unit_c2_culture"
	suite_level = "unit"
	needs_scene = false
	timeout_seconds = 40.0


func run_phases() -> void:
	_test_net_gate()
	_test_population_schedule()
	_test_harvest_population()
	_test_seed_colony()
	_test_maggots_keep_mass()
	_test_dress_and_cook()
	_test_cure()
	_test_kitchen_queue()
	_test_eating()
	_test_net_recipe()
	_test_products_in_orders()
	_test_cave_papers()
	_test_cinder_loot()
	_test_tools()
	_test_save_v9()


func _state() -> FarmState:
	var fresh := FarmState.new()
	fresh.new_game()
	fresh.furnace_lit = true
	fresh.temperature = 27.0
	return fresh


func _ripe(survivor: FarmState, index: int) -> void:
	survivor.trays[index]["active"] = true
	survivor.trays[index]["dead"] = false
	survivor.trays[index]["progress"] = 1.0
	survivor.trays[index]["health"] = 1.0
	# C2.7 // a cricket tray is ripe by population, not by the maggot progress bar.
	if str(survivor.trays[index].get("species", "")) == "cricket":
		survivor.trays[index]["population"] = FarmState.CRICKET_HARVEST_POPULATION
		survivor.trays[index]["growth_minutes"] = FarmState.CRICKET_FIRST_MILESTONE_MINUTES


# --------------------------------------------------------------- husbandry

func _test_net_gate() -> void:
	begin_case("net_gate", "a cricket tray cannot be harvested bare-handed")
	var survivor: FarmState = _state()
	_ripe(survivor, 0)
	var refused: String = survivor.harvest_tray(0)
	_ok(refused.contains("net"), "the refusal names the missing net", refused)
	_eq(int(survivor.live_crickets), 0, "nothing is taken alive without a net")
	_eq(float(survivor.trays[0]["progress"]), 1.0, "the mature tray is left untouched")
	end_case()


func _test_population_schedule() -> void:
	begin_case("population_schedule", "the colony hits its milestones on the documented clock")
	var survivor: FarmState = _state()
	_eq(survivor.cricket_population_at(0.0), FarmState.CRICKET_START_POPULATION,
		"a new colony starts at six")
	_eq(survivor.cricket_population_at(FarmState.CRICKET_FIRST_MILESTONE_MINUTES),
		FarmState.CRICKET_HARVEST_POPULATION, "2.5 real minutes reaches the first scoop")
	_eq(survivor.cricket_population_at(FarmState.CRICKET_SECOND_MILESTONE_MINUTES),
		FarmState.CRICKET_SECOND_MILESTONE_POPULATION, "five real minutes reaches forty-three")
	_ok(survivor.cricket_population_at(100000.0) <= FarmState.CRICKET_CAPACITY,
		"the colony never passes its capacity")
	_ok(survivor.cricket_population_at(6000.0) > survivor.cricket_population_at(600.0),
		"late growth keeps climbing instead of stopping at the second milestone")

	# Growing by the clock: 150 warm minutes from six reaches 27 through the tick,
	# and a hungry colony stands still instead.
	survivor.feed = 6.0
	survivor.advance_minutes(FarmState.CRICKET_FIRST_MILESTONE_MINUTES)
	_eq(survivor.tray_population(0), FarmState.CRICKET_HARVEST_POPULATION,
		"a fed colony reaches the scoopable size in 2.5 real minutes")
	survivor.feed = 0.0
	var hungry_before: int = survivor.tray_population(0)
	survivor.advance_minutes(60.0)
	_eq(survivor.tray_population(0), hungry_before, "an unfed colony pauses where it is")

	# C2.7 // the room starts cold (15 C). The schedule is real time, not a
	# stretch of it, so a fresh fed colony still reaches its milestone on 150
	# minutes; only the freezing band pauses it.
	var cold: FarmState = _state()
	cold.temperature = 15.0
	cold.feed = 6.0
	cold.advance_minutes(FarmState.CRICKET_FIRST_MILESTONE_MINUTES)
	_eq(cold.tray_population(0), FarmState.CRICKET_HARVEST_POPULATION,
		"a cold-start room still reaches the scoop on schedule")
	_eq(cold.tray_minutes_to_harvest(0), 0.0, "and reports no wait once ripe")
	var frozen: FarmState = _state()
	frozen.temperature = 8.0
	frozen.furnace_lit = false
	frozen.fuel = 0.0
	frozen.feed = 6.0
	frozen.advance_minutes(20.0)
	_eq(frozen.tray_population(0), FarmState.CRICKET_START_POPULATION, "a freezing room pauses the colony")
	_eq(frozen.tray_minutes_to_harvest(0), -1.0, "and the readout says the room is too cold")
	end_case()


func _test_harvest_population() -> void:
	begin_case("harvest_population", "the net takes the colony above its breeding reserve, capped by the load")
	var survivor: FarmState = _state()
	survivor.net_crafted = true
	# Tier upgrades no longer multiply a fixed yield; the colony's own size does.
	survivor.upgrades["throughput"] = 3
	_ripe(survivor, 0)
	var caught: String = survivor.harvest_tray(0)
	_eq(int(survivor.live_crickets), FarmState.CRICKET_HARVEST_POPULATION - FarmState.CRICKET_BREEDING_RESERVE,
		"only the crickets above the reserve are netted")
	_eq(int(survivor.tray_population(0)), FarmState.CRICKET_BREEDING_RESERVE,
		"the colony falls back to its breeding reserve")
	_ok(not survivor.tray_harvestable(0), "a netted tray needs to grow back")
	_ok(float(survivor.trays[0]["health"]) < 1.0, "netting still costs the colony health")

	survivor.upgrades["throughput"] = 0
	_ripe(survivor, 0)
	survivor.live_crickets = FarmState.NET_CAPACITY - 2
	survivor.harvest_tray(0)
	_eq(int(survivor.live_crickets), FarmState.NET_CAPACITY, "the net stops at its capacity")
	_ok(float(survivor.tray_population(0)) > FarmState.CRICKET_BREEDING_RESERVE,
		"crickets the net could not carry stay in the tray")
	end_case()


func _test_seed_colony() -> void:
	begin_case("seed", "a carried starter founds a new colony")
	var survivor: FarmState = _state()
	survivor.live_crickets = FarmState.CRICKETS_TO_SEED - 1
	var short: String = survivor.seed_tray(1)
	_ok(short.contains("needs"), "a short starter is refused by name", short)
	_ok(not bool(survivor.trays[1]["active"]), "a refused seed leaves the frame empty")

	survivor.live_crickets = FarmState.CRICKETS_TO_SEED
	var seeded: String = survivor.seed_tray(1)
	_ok(bool(survivor.trays[1]["active"]), "the frame becomes a live colony", seeded)
	_eq(str(survivor.trays[1]["species"]), "cricket", "the new colony is crickets")
	_eq(int(survivor.tray_population(1)), FarmState.CRICKET_START_POPULATION,
		"the new colony starts at the six-cricket floor")
	_ok(is_equal_approx(float(survivor.trays[1]["health"]), 1.0), "the new colony starts healthy")
	_eq(int(survivor.live_crickets), 0, "seeding spends exactly the starter")

	survivor.live_crickets = FarmState.CRICKETS_TO_SEED * 2
	var again: String = survivor.seed_tray(1)
	_ok(again.contains("already"), "an established colony is not re-seeded", again)
	_eq(int(survivor.live_crickets), FarmState.CRICKETS_TO_SEED * 2, "the refusal costs nothing")

	# A dead colony is revived from carried crickets instead of the parts starter.
	survivor.trays[1]["dead"] = true
	var revived: String = survivor.seed_tray(1)
	_ok(not bool(survivor.trays[1]["dead"]) and bool(survivor.trays[1]["active"]),
		"a dead colony can be restarted from a carried starter", revived)
	end_case()


func _test_maggots_keep_mass() -> void:
	begin_case("maggots", "maggot trays still harvest as bulk mass")
	var survivor: FarmState = _state()
	survivor.trays[1]["active"] = true
	survivor.trays[1]["species"] = "maggot"
	survivor.trays[1]["progress"] = 1.0
	var mass_before: int = int(survivor.mass)
	var harvest: String = survivor.harvest_tray(1)
	_eq(int(survivor.mass), mass_before + 1, "a mature maggot tray adds one mass")
	_eq(int(survivor.live_crickets), 0, "maggots never add live crickets")
	end_case()


# ----------------------------------------------------------------- kitchen

func _test_dress_and_cook() -> void:
	begin_case("cook", "dress, then cook over a lit furnace")
	var survivor: FarmState = _state()
	survivor.live_crickets = 5
	var short: String = survivor.dress_crickets()
	_ok(short.contains("takes"), "dressing is refused under six crickets", short)
	_eq(int(survivor.dressed_crickets), 0, "a refused dress adds nothing")

	survivor.live_crickets = FarmState.CRICKETS_TO_DRESS
	var hour_before: float = survivor.abs_hour()
	var dressed: String = survivor.dress_crickets()
	_eq(int(survivor.dressed_crickets), FarmState.DRESSED_PER_BATCH, "six crickets dress into two portions")
	_eq(int(survivor.live_crickets), 0, "dressing spends the live load")
	_ok(absf(survivor.abs_hour() - hour_before - FarmState.DRESS_HOURS) < 0.02,
		"dressing takes its in-game time", dressed)

	survivor.dressed_crickets = 0
	var no_pot: String = survivor.cook_meal()
	_ok(no_pot.contains("dressed"), "cooking is refused with nothing dressed", no_pot)
	_eq(int(survivor.meals), 0, "a refused cook adds no meal")

	survivor.dressed_crickets = FarmState.DRESSED_PER_BATCH
	survivor.furnace_lit = false
	var cold: String = survivor.cook_meal()
	_ok(cold.contains("fire"), "cooking needs a lit furnace", cold)
	_eq(int(survivor.meals), 0, "no meal cooks on a cold fire")

	survivor.furnace_lit = true
	survivor.fuel = 0.4
	var dry: String = survivor.cook_meal()
	_ok(dry.contains("fuel"), "cooking needs one fuel under the pot", dry)
	_eq(int(survivor.meals), 0, "no meal cooks with an empty firebox")

	survivor.fuel = 3.0
	survivor.dressed_crickets = FarmState.DRESSED_PER_BATCH
	var cook_hour: float = survivor.abs_hour()
	var cooked: String = survivor.cook_meal()
	_eq(survivor.kitchen_jobs.size(), 1, "the pot takes the batch onto its queue")
	_eq(int(survivor.dressed_crickets), 0, "the portions are paid up front")
	_eq(int(survivor.meals), 0, "nothing is ready the instant it is queued")
	# The one fuel under the pot, plus the fire that keeps burning while it cooks.
	_ok(float(survivor.fuel) <= 2.0 and float(survivor.fuel) > 1.9,
		"cooking spends one fuel on top of the fire's own burn",
		"%.3f" % float(survivor.fuel))
	survivor.advance_minutes(FarmState.COOK_HOURS * 60.0)
	_eq(int(survivor.ready_meals), FarmState.MEALS_PER_BATCH, "the pot yields two ready meals")
	_ok(absf(survivor.abs_hour() - cook_hour - FarmState.COOK_HOURS) < 0.02,
		"cooking takes half an hour")
	_ok(survivor.kitchen_ready_total() > 0, "a finished batch waits on the board")
	_ok(not str(survivor.ready_grade).is_empty(), "the batch is graded by colony quality")
	var collected: String = survivor.collect_kitchen()
	_eq(int(survivor.meals), FarmState.MEALS_PER_BATCH, "collecting moves the meals to the store")
	_eq(int(survivor.ready_meals), 0, "the board is clear after collection")
	end_case()


func _test_kitchen_queue() -> void:
	begin_case("kitchen_queue", "batches queue behind each other and report what can start")
	var survivor: FarmState = _state()
	survivor.dressed_crickets = FarmState.DRESSED_PER_BATCH * 3
	survivor.fuel = 5.0
	_eq(int(survivor.kitchen_max("cook")), 3, "three batches are affordable")
	survivor.queue_kitchen("cook", 3)
	_eq(survivor.kitchen_jobs.size(), 3, "the queue holds the whole order")
	_eq(int(survivor.dressed_crickets), 0, "all three batches are paid at queue time")
	var queued_hours := 0.0
	for job in survivor.kitchen_jobs:
		queued_hours += float(job["hours_left"])
	_ok(is_equal_approx(queued_hours, FarmState.COOK_HOURS * 3.0),
		"the board quotes the whole queue")
	survivor.advance_minutes(FarmState.COOK_HOURS * 60.0)
	_eq(int(survivor.kitchen_ready_total()), FarmState.MEALS_PER_BATCH,
		"only the front batch finishes in the first window")
	_eq(survivor.kitchen_jobs.size(), 2, "the rest of the order is still queued")
	var refused: String = survivor.queue_kitchen("cook", 1)
	_ok(refused.contains("nothing") or refused.contains("dressed"),
		"an unaffordable batch is refused by name", refused)
	end_case()


func _test_cure() -> void:
	begin_case("cure", "curing is slower, free of fuel and never needs the fire")
	var survivor: FarmState = _state()
	survivor.furnace_lit = false
	survivor.fuel = 0.0
	survivor.dressed_crickets = FarmState.DRESSED_PER_BATCH
	var hour_before: float = survivor.abs_hour()
	var cured: String = survivor.cure_jerky()
	_eq(survivor.kitchen_jobs.size(), 1, "the rack takes the batch onto its queue")
	survivor.advance_minutes(FarmState.CURE_HOURS * 60.0)
	_eq(int(survivor.ready_jerky), FarmState.JERKY_PER_BATCH, "the rack yields two jerky")
	_eq(int(survivor.meals), 0, "curing never produces meal")
	_ok(absf(survivor.abs_hour() - hour_before - FarmState.CURE_HOURS) < 0.02,
		"curing takes a full hour")
	survivor.collect_kitchen()
	_eq(int(survivor.jerky), FarmState.JERKY_PER_BATCH, "collecting moves the jerky to the store")
	_ok(float(survivor.fuel) < 0.05, "curing spends no fuel")
	end_case()


# ------------------------------------------------------------------- food

func _test_eating() -> void:
	begin_case("eating", "meal feeds best, jerky travels, rations stay the baseline")
	var survivor: FarmState = _state()
	survivor.hunger_hours = 4.0
	survivor.meals = 1
	survivor.eat("meal")
	_ok(is_equal_approx(float(survivor.hunger_hours), FarmState.MEAL_HUNGER_HOURS),
		"a hot meal restores the most hunger")
	_eq(int(survivor.meals), 0, "eating a meal spends one portion")

	survivor.hunger_hours = 4.0
	survivor.jerky = 1
	survivor.eat("jerky")
	_ok(is_equal_approx(float(survivor.hunger_hours), FarmState.JERKY_HUNGER_HOURS),
		"jerky restores less than a meal")
	_eq(int(survivor.jerky), 0, "eating jerky spends one strip")

	survivor.hunger_hours = 4.0
	survivor.rations = 1
	survivor.eat()
	_ok(is_equal_approx(float(survivor.hunger_hours), FarmState.RATION_HUNGER_HOURS),
		"a ration keeps its old value")

	survivor.hunger_hours = 4.0
	var empty: String = survivor.eat("jerky")
	_ok(empty.contains("jerky"), "eating an empty store is refused by name", empty)
	_eq(float(survivor.hunger_hours), 4.0, "a refused meal changes no hunger")

	survivor.hunger_hours = 20.0
	survivor.meals = 1
	var full: String = survivor.eat("meal")
	_ok(full.contains("Not hungry"), "a full survivor is not forced to eat", full)
	end_case()


# ----------------------------------------------------------------- recipe

func _cave_order(product: String, qty: int, min_grade: String) -> Dictionary:
	return {
		"id": "cave_%s" % product,
		"buyer": "THE WEIGHER",
		"product": product,
		"qty": qty,
		"min_grade": min_grade,
		"due_hour": 40.0,
		"pay_parts": 9,
		"pay_water": 1,
		"pay_standing": 4,
		"delivered": false,
		"special": false,
		"source": "cave",
	}


func _test_products_in_orders() -> void:
	begin_case("products_in_orders", "cooked goods wrap into orders with their own grade")
	var survivor := _state()
	survivor.meals = 3
	survivor.meal_grade = "A"
	survivor.orders = [_cave_order("meal", 2, "B")]
	var packed: String = str(survivor.pack_for_order())
	_ok(not survivor.packed_box.is_empty(), "a cave paper takes cooked meals", packed)
	_eq(int(survivor.meals), 1, "wrapping removes the meals it packs")
	_eq(str(survivor.packed_box.get("product", "")), "meal", "the box records the product")
	_eq(str(survivor.packed_box.get("grade", "")), "A", "the box carries the meal's own grade")
	_ok(survivor.order_text().contains("CAVE"), "the slate marks a cave paper", survivor.order_text())
	_ok(survivor.product_name("meal").contains("MEAL"), "meals have their own name at the hatch")

	var depleted := _state()
	depleted.jerky = 2
	depleted.jerky_grade = "B"
	depleted.orders = [_cave_order("jerky", 3, "B")]
	var short: String = str(depleted.pack_for_order())
	_ok(short.contains("jerky") or short.contains("JERKY"), "a short jerky order is refused by name", short)
	_eq(int(depleted.jerky), 2, "a refused wrap spends nothing")
	depleted.orders = [_cave_order("jerky", 2, "B")]
	var wrapped: String = str(depleted.pack_for_order())
	_ok(not depleted.packed_box.is_empty(), "two strips fill a two-strip order", wrapped)
	_eq(int(depleted.jerky), 0, "the wrapped strips leave the store")
	_eq(str(depleted.packed_box.get("grade", "")), "B", "jerky carries its cure grade")

	# Dawn replaces hatch papers but must not tear a paper carried out of the cave.
	var dawn := _state()
	var cave: Dictionary = _cave_order("jerky", 1, "B")
	var hatch := {
		"id": "hatch_1", "buyer": "OLD KOREN", "product": "ration", "qty": 3,
		"min_grade": "B", "due_hour": 30.0, "pay_parts": 6, "pay_water": 0,
		"pay_standing": 3, "delivered": false, "special": false,
	}
	dawn.orders = [cave, hatch]
	dawn._dawn()
	var kept_cave := false
	var kept_hatch := false
	for order in dawn.orders:
		if str(order.get("source", "")) == "cave":
			kept_cave = true
		if str(order.get("id", "")) == "hatch_1":
			kept_hatch = true
	_ok(kept_cave, "dawn keeps a paper carried out of the cave")
	_ok(not dawn.cave_slate_text().is_empty(), "the HUD slate text survives dawn too")
	_eq(dawn.cave_orders().size(), 1, "only the cave paper is listed for the HUD")
	var done := _state()
	var finished: Dictionary = _cave_order("meal", 2, "B")
	finished["delivered"] = true
	done.orders = [finished]
	_eq(done.cave_slate_text(), "", "a settled paper leaves the HUD slate empty")
	_ok(not kept_hatch, "dawn replaces the hatch paper it rolled yesterday")


func _test_cave_papers() -> void:
	begin_case("cave_papers", "papers wait under the clamp, become orders, and are paid on a later trip")
	var survivor := _state()
	_eq(survivor.cave_paper_count(), 1, "a fresh shift already has one paper under the clamp")
	var paper: Dictionary = survivor.top_cave_paper()
	_ok(not paper.is_empty(), "the paper has a body", str(paper))
	_ok(paper.has("taken") and not bool(paper.get("taken", true)), "the paper starts under the clamp untaken")
	_ok(absf(float(paper.get("due_hour", 0.0)) - (survivor.abs_hour() + FarmState.CAVE_ORDER_DUE_HOURS)) < 0.01,
		"a cave paper is due 14 h out", "%.2f vs now %.2f" % [float(paper.get("due_hour", 0.0)), survivor.abs_hour()])
	var product := str(paper.get("product", ""))
	_ok(product == "meal" or product == "jerky" or product == "ration" or product == "bait" or product == "hide",
		"the paper asks for real goods", product)
	if product == "meal" or product == "jerky":
		var qty := int(paper.get("qty", 0))
		var expected := qty * (3 if product == "meal" else 4)
		_ok(int(paper.get("pay_parts", 0)) >= expected + 4 and int(paper.get("pay_parts", 0)) <= expected + 10,
			"the cave price is about 1.8x the hatch formula", "%d parts for %d %s" % [int(paper.get("pay_parts", 0)), qty, product])
	survivor.roll_cave_papers()
	_eq(survivor.cave_paper_count(), 1, "the roll only adds one paper per in-game day")

	# Packing before reading: the bench refuses and the goods stay put.
	survivor.meals = 3
	var paper_id := str(paper.get("id", ""))
	var refused: String = str(survivor.pack_for_order(paper_id))
	_ok(refused.contains("still under the clamp"), "packing for an unread paper is refused", refused)
	_eq(int(survivor.meals), 3, "the refused wrap spends nothing")

	# Reading it turns the paper into a slate entry with the cave source.
	var read: String = str(survivor.take_cave_paper())
	_ok(read.contains("PAPER"), "reading the clamp gives the paper's terms", read)
	_eq(survivor.cave_paper_count(), 0, "the paper leaves the clamp when it is taken")
	_eq(survivor.cave_orders().size(), 1, "the paper becomes a cave order on the slate")
	_ok(not survivor.cave_slate_text().is_empty(), "the HUD has a cave line to show", survivor.cave_slate_text())
	# Pin the carried paper's goods so the packing half of the case is about the
	# bench rather than about which paper the day happened to roll.
	for carried in survivor.orders:
		if survivor.order_is_cave(carried):
			carried["product"] = "meal"
			carried["qty"] = 2
			carried["min_grade"] = "B"

	# Packing takes the cave order before any hatch paper, and it is not hatch-bound.
	var hatch := {
		"id": "hatch_1", "buyer": "OLD KOREN", "product": "ration", "qty": 3,
		"min_grade": "B", "due_hour": 30.0, "pay_parts": 6, "pay_water": 0,
		"pay_standing": 3, "delivered": false, "special": false,
	}
	survivor.orders.insert(0, hatch)
	survivor.meals = 6
	survivor.meal_grade = "B"
	var packed: String = str(survivor.pack_for_order())
	_ok(not survivor.packed_box.is_empty(), "the bench wraps something", packed)
	_ok(bool(survivor.cave_box_packed()), "the cave paper wins the bench while its clock runs", str(survivor.packed_box))
	_ok(packed.contains("drop"), "the message says the box leaves through the drop", packed)
	var hatch_refused: String = str(survivor.leave_box())
	_ok(hatch_refused.contains("drop in the pocket"), "the hatch refuses a cave box", hatch_refused)
	_ok(survivor.delivered_box.is_empty(), "no cave box is left in the hatch")

	# Deposit, then wait out the buyer's absence.
	var before_parts: int = survivor.parts
	var deposited: String = str(survivor.drop_cave_box())
	_ok(deposited.contains("clamp"), "the clamp takes the box", deposited)
	_ok(survivor.packed_box.is_empty(), "the box leaves the player's hands")
	_ok(not survivor.cave_payout.is_empty(), "a payment is now owed")
	_ok(not bool(survivor.cave_payout_ready()), "payment is not instant")
	var early: String = str(survivor.collect_cave_payout())
	_ok(early.contains("shut"), "collecting before the hour is refused", early)
	_eq(int(survivor.parts), before_parts, "an early collect credits nothing")
	survivor.advance_minutes(FarmState.CAVE_PAYOUT_DELAY_HOURS * 60.0 + 3.0)
	_ok(bool(survivor.cave_payout_ready()), "an hour later the clamp can be emptied")
	var payout_parts := int(survivor.cave_payout.get("parts", 0))
	var payout_water := int(survivor.cave_payout.get("water", 0))
	var collected: String = str(survivor.collect_cave_payout())
	_ok(collected.contains("COLLECTED"), "the payment is collected", collected)
	_eq(int(survivor.parts), before_parts + payout_parts, "the parts land in the account")
	_eq(int(survivor.water), 2 + payout_water, "the water lands with them")
	_ok(survivor.cave_payout.is_empty() and survivor.cave_drop.is_empty(), "the clamp is cleared after collection")

	# Expiry: past due + 2 h the paper tears itself, costs standing, and waits.
	var expired := _state()
	expired.take_cave_paper()
	var owed: Dictionary = expired.cave_orders()[0]
	owed["due_hour"] = expired.abs_hour() + 0.2
	expired.orders[0]["due_hour"] = owed["due_hour"]
	var standing_before: int = expired.standing
	expired.advance_minutes(150.0)
	_eq(expired.cave_orders().size(), 0, "an unfilled cave paper leaves the slate")
	_eq(int(expired.standing), maxi(0, standing_before - 2), "expiry costs two standing")
	_eq(expired.cave_paper_count(), 1, "a torn paper is waiting under the clamp")
	_ok(bool(expired.cave_has_torn_paper()), "the paper is marked torn")
	var torn_text: String = str(expired.take_cave_paper())
	_ok(torn_text.contains("torn"), "reading the torn paper tells the player it is over", torn_text)
	_eq(expired.cave_paper_count(), 0, "the torn paper is cleared by reading it")
	end_case()


func _test_net_recipe() -> void:
	begin_case("net_recipe", "the net is a real workbench pattern, made once")
	var survivor: FarmState = _state()
	var recipe: Dictionary = survivor.workbench_recipe("cricket_net")
	_ok(not recipe.is_empty(), "the workbench lists a cricket net")
	_ok(survivor.workbench_recipe_ids().has("cricket_net"), "the net appears in the recipe order")
	_eq(int(recipe.get("cost", {}).get("parts", 0)), 2, "the net costs two parts")
	_eq(int(recipe.get("cost", {}).get("hides", 0)), 1, "the net costs one hide")

	survivor.parts = 1
	survivor.hides = 1
	var refused: String = survivor.craft_at_workbench("cricket_net")
	_ok(not bool(survivor.net_crafted) and refused.contains("Need"), "a short bench cannot weave a net", refused)

	survivor.parts = 4
	survivor.hides = 1
	var made: String = survivor.craft_at_workbench("cricket_net")
	_ok(bool(survivor.net_crafted), "the bench weaves the net", made)
	_eq(int(survivor.parts), 2, "the net spends its parts")
	_eq(int(survivor.hides), 0, "the net spends its hide")

	var twice: String = survivor.craft_at_workbench("cricket_net")
	_ok(twice.contains("already"), "a second net is refused; one lasts forever", twice)
	end_case()


# -------------------------------------------------------------------- save

func _test_cinder_loot() -> void:
	begin_case("cinder_loot", "a cinder carcass always carries ember chitin and sometimes a gland")
	var survivor := _state()
	survivor.gland_chance = 0.0
	var ember_before: int = survivor.ember_chitin
	var glands_before: int = survivor.heat_glands
	var note: String = survivor.butcher("A", "cinder")
	_eq(survivor.ember_chitin, ember_before + 1, "ember chitin is always in a cinder hide")
	_eq(survivor.heat_glands, glands_before, "no gland when the quarter roll misses")
	_ok(note.contains("ember"), "the table note names the new material", note)
	survivor.gland_chance = 1.0
	survivor.butcher("A", "cinder")
	_eq(survivor.heat_glands, glands_before + 1, "a gland when the roll lands")
	var chitin_before: int = survivor.chitin
	survivor.butcher("A")
	_eq(survivor.chitin, chitin_before + 2, "a plain body still gives only base chitin")
	_eq(survivor.ember_chitin, ember_before + 2, "and never ember chitin")
	survivor.gland_chance = 0.25


func _test_tools() -> void:
	begin_case("tools", "the gland lantern burns fuel and the ember snare survives one trigger")
	var survivor := _state()
	survivor.heat_glands = 0
	var refused: String = survivor.craft_at_workbench("gland_lantern")
	_ok(refused.contains("Need"), "the lantern needs a heat gland", refused)
	_ok(not survivor.lantern_crafted, "a failed craft builds nothing")
	survivor.heat_glands = 1
	survivor.parts = 5
	survivor.chitin = 2
	var built: String = survivor.craft_at_workbench("gland_lantern")
	_ok(survivor.lantern_crafted, "the workbench builds the lantern", built)
	_eq(survivor.parts, 3, "for two parts")
	_eq(survivor.heat_glands, 0, "one heat gland")
	_eq(survivor.chitin, 1, "and one chitin")
	_ok(survivor.craft_at_workbench("gland_lantern").contains("already"), "a second lantern is refused")
	_ok(not survivor.lantern_on, "the lantern starts shuttered")
	survivor.fuel = 5.0
	var lit: String = survivor.toggle_lantern()
	_ok(lit.contains("LANTERN"), "the toggle lights it", lit)
	_ok(survivor.lantern_on, "and the light is on")
	_ok(absf(survivor.fuel - 4.0) < 0.001, "lighting spends the first fuel unit", str(survivor.fuel))
	survivor.tick_lantern(4.0)
	_ok(absf(survivor.fuel - 4.0) < 0.001, "the first ten minutes are already paid for")
	survivor.tick_lantern(6.0)
	_ok(survivor.lantern_on and absf(survivor.fuel - 3.0) < 0.001, "ten in-game minutes draw the next unit", str(survivor.fuel))
	survivor.fuel = 0.0
	survivor.tick_lantern(10.0)
	_ok(not survivor.lantern_on, "an empty fuel store puts the lantern out")
	var dry: String = survivor.toggle_lantern()
	_ok(not survivor.lantern_on and dry.contains("dry"), "and it will not relight dry", dry)

	# Ember snare: built from one plain snare and one ember chitin, and it comes
	# back as a plain snare after its single trigger.
	survivor.ember_chitin = 1
	survivor.snares = 1
	var made: String = survivor.craft_at_workbench("ember_snare")
	_eq(survivor.ember_snares, 1, "ember chitin is spent into an ember snare")
	_ok(made.to_lower().contains("snare"), "and the bench names it", made)
	_eq(survivor.snares, 0, "the plain snare is consumed")
	var armed: String = survivor.arm_snare()
	_ok(armed.to_lower().contains("ember"), "the ember snare is the one that goes in", armed)
	_eq(survivor.ember_snares, 0, "arming takes it from the pack")
	_ok(survivor.disarm_snare().to_lower().contains("disarmed") and survivor.ember_snares == 1,
		"disarming returns the ember snare itself")
	survivor.arm_snare()
	survivor.trigger_snare()
	_ok(not survivor.snare_armed, "the trigger consumes the set trap")
	_eq(survivor.snares, 1, "and the ember wire comes back as a plain snare")
	_eq(survivor.ember_snares, 0, "the ember quality is spent")
	survivor.arm_snare()
	_eq(survivor.snare_kind, "plain", "the recovered snare arms normally")
	survivor.disarm_snare()
	_eq(survivor.snares, 1, "and folds back whole")


func _test_save_v9() -> void:
	begin_case("save", "the current schema stores the culture and loads a schema 7 shift safely")
	var survivor: FarmState = _state()
	survivor.net_crafted = true
	survivor.live_crickets = 7
	survivor.dressed_crickets = 3
	survivor.meals = 2
	survivor.jerky = 5
	survivor.meal_grade = "A"
	survivor.ember_chitin = 1
	survivor.heat_glands = 2
	survivor.cave_papers = [{
		"id": "c9_p0", "buyer": "THE WEIGHER", "product": "meal", "qty": 2,
		"min_grade": "B", "due_hour": 40.0, "pay_parts": 12, "pay_water": 1,
		"pay_standing": 4, "torn": false, "taken": false, "found_day": 9,
	}]
	survivor.cave_drop = {"product": "meal", "qty": 2, "grade": "B", "buyer": "THE WEIGHER"}
	survivor.cave_payout = {"parts": 12, "water": 1, "standing": 4, "ready_hour": 30.0}
	survivor.lantern_crafted = true
	survivor.lantern_on = true
	survivor.lantern_fuel_seconds = 420.0
	survivor.ember_snares = 2
	var saved: Dictionary = survivor.to_save()
	_eq(int(saved.get("version", 0)), FarmState.SAVE_VERSION, "the save declares the current schema")

	var restored := FarmState.new()
	_ok(restored.from_save(saved), "a schema 8 save loads")
	_eq(int(restored.live_crickets), 7, "live crickets survive the save")
	_eq(int(restored.dressed_crickets), 3, "dressed crickets survive the save")
	_eq(int(restored.meals), 2, "meals survive the save")
	_eq(int(restored.jerky), 5, "jerky survives the save")
	_eq(str(restored.meal_grade), "A", "the meal grade survives the save")
	_ok(bool(restored.net_crafted), "the net survives the save")
	_eq(int(restored.heat_glands), 2, "a heat gland survives the save")
	_eq(restored.cave_papers.size(), 1, "a paper under the clamp survives the save")
	_eq(str(restored.cave_drop.get("buyer", "")), "THE WEIGHER", "a box in the clamp survives the save")
	_eq(int(restored.cave_payout.get("parts", 0)), 12, "an owed payment survives the save")
	_ok(not bool(restored.cave_payout_ready()), "a reloaded payment waits for its hour, not the wall clock")
	_ok(bool(restored.lantern_crafted) and bool(restored.lantern_on), "the lit lantern survives the save")
	_eq(int(restored.lantern_fuel_seconds), 420, "with the burn left in its account")
	_eq(int(restored.ember_snares), 2, "and ember snares survive the save")

	# A version 7 save has none of the C2 keys. It must still load as before.
	var old_save: Dictionary = saved.duplicate(true)
	old_save["version"] = 7
	for key in ["live_crickets", "dressed_crickets", "meals", "jerky", "meal_grade",
			"jerky_grade", "net_crafted", "ember_chitin", "heat_glands", "ember_snares",
			"lantern_crafted", "lantern_on", "lantern_fuel_seconds", "cave_papers",
			"cave_drop", "cave_payout", "story"]:
		old_save.erase(key)
	var migrated := FarmState.new()
	_ok(migrated.from_save(old_save), "a schema 7 save still loads")
	_eq(int(migrated.live_crickets), 0, "an old save starts with no live crickets")
	_ok(not bool(migrated.net_crafted), "an old save starts without a net")
	_eq(int(migrated.trays.size()), FarmState.TRAY_SLOTS, "the old trays are preserved")
	_eq(int(migrated.parts), int(saved.get("parts", -1)), "the old inventory is preserved")
	end_case()
