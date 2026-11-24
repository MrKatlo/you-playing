extends "res://tools/tests/test_base.gd"

## C2 // culture, husbandry slice (M1).
##
## The farm stops being a progress bar that turns into a generic number: a mature
## cricket tray has to be netted alive, and a carried starter founds a new colony
## in the empty frame. Everything here goes through the real wall stations and the
## real `player_interact()`; nothing is applied straight to the model.
##
## The kitchen, orders and the cave drop arrive in later C2 modules and get their
## own cases in this suite.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/workflow_c2_culture.tscn


func _init() -> void:
	suite_name = "workflow_c2_culture"
	suite_level = "workflow"


func run_phases() -> void:
	await _prepare_world()
	await _test_empty_frame_is_a_target()
	await _test_net_needs_a_net()
	await _test_netting_a_mature_tray()
	await _test_seeding_a_frame()
	await _test_kitchen_station()
	await _test_kitchen_actions()
	await _test_cricket_hud()
	await _test_all_six_frames()
	await _test_kitchen_life()
	await _test_food_crate()
	await _test_pack_cooked_order()
	await _test_cave_slate_hud()
	await _test_pocket_walk()
	await _test_cave_trade_loop()
	await _test_cinder_burrower()
	await _test_tools()


func _prepare_world() -> void:
	# The tutorial owns interaction until it is done; the culture loop is what is
	# under test here.
	game.finish_opening_sequence_for_test()
	game.opening_state = ""
	game.player.is_hidden = false
	game.farm.net_crafted = false
	game.farm.live_crickets = 0
	game.farm.dressed_crickets = 0
	game.farm.parts = 6
	game.farm.hides = 2
	game.farm.upgrades["throughput"] = 0
	# Tray one is a live colony with a hinged lid; tray two is a bare frame.
	game.farm.trays[0]["species"] = "cricket"
	game.farm.trays[0]["active"] = true
	game.farm.trays[0]["dead"] = false
	game.farm.trays[0]["progress"] = 1.0
	game.farm.trays[0]["health"] = 1.0
	# C2.7 // a colony is ripe by population. Twenty-seven is the first scoopable
	# size, and 150 growth-minutes is where that size sits on the curve.
	game.farm.trays[0]["population"] = FarmState.CRICKET_HARVEST_POPULATION
	game.farm.trays[0]["growth_minutes"] = FarmState.CRICKET_FIRST_MILESTONE_MINUTES
	game.farm.trays[1]["active"] = false
	game.farm.trays[1]["dead"] = false
	game.farm.trays[1]["progress"] = 0.0
	game.farm.trays[1]["species"] = "maggot"
	game._refresh_trays()
	await _frames(3)


func _stand_at_tray(index: int, distance: float = 0.95) -> void:
	var spot: Vector3 = game.TRAY_SPOTS[index]
	game.player.global_position = Vector3(spot.x, 0.9, spot.z + distance)
	game.player.velocity = Vector3.ZERO
	_aim_player_at(Vector3(spot.x, 0.6, spot.z))
	await _frames(3)


## The prompt is written on the HUD's own frame; wait for it instead of guessing a
## frame count, then assert on what the player would actually see.
func _wait_prompt(expected: String, max_frames: int = 40) -> void:
	for _i in range(max_frames):
		if game.prompt_label.text == expected:
			return
		await _frames(1)


func _tray_of(index: int) -> Node3D:
	return game.tray_bodies[index] as Node3D


func _crickets_for_tray(index: int) -> Array:
	var found: Array = []
	for item in game.tray_crickets:
		if typeof(item) == TYPE_DICTIONARY and int((item as Dictionary).get("tray_index", -1)) == index:
			found.append(item)
	return found


# ------------------------------------------------------------------- cases

func _test_empty_frame_is_a_target() -> void:
	begin_case("empty_frame", "the bare frame can be interacted with")
	var frame := _tray_of(1)
	_ok(frame != null, "the second culture frame exists in the room")
	if frame == null:
		return
	_eq(str(frame.get_meta("kind", "")), "tray", "the empty frame is a culture station")
	_eq(int(frame.get_meta("index", -1)), 1, "the frame reports its own slot")
	_ok(str(frame.get_meta("label", "")).contains("SEED"),
		"the dormant frame asks for a starter, not a harvest",
		str(frame.get_meta("label", "")))
	_ok(frame.get_node_or_null("UnfinishedMark") != null, "the dormant frame keeps its stencil")
	await _stand_at_tray(1)
	_ok(game._nearest_interactable() == frame, "the player can select the empty frame")
	game.player_interact()
	await _frames(4)
	_ok(not bool(game.farm.trays[1]["active"]), "an empty-handed press does not found a colony")
	_ok(game.message_label.text.contains("6 live crickets"),
		"the refusal explains how many crickets a colony needs",
		game.message_label.text)


func _test_net_needs_a_net() -> void:
	begin_case("net_gate", "a mature tray cannot be taken bare-handed")
	var frame := _tray_of(0)
	await _stand_at_tray(0)
	_ok(game._nearest_interactable() == frame, "the live tray is the interaction point")
	game.player_interact()
	await _frames(6)
	_eq(int(game.farm.live_crickets), 0, "no crickets are taken without a net")
	_eq(float(game.farm.trays[0]["progress"]), 1.0, "the refused tray stays mature")
	_ok(game.message_label.text.contains("net"), "the refusal names the missing net",
		game.message_label.text)
	end_case()


func _test_netting_a_mature_tray() -> void:
	begin_case("netting", "the crafted net takes a live load")
	var made: String = str(game.craft_workbench_recipe("cricket_net"))
	_ok(bool(game.farm.net_crafted), "the net is woven at the real workbench", made)
	_eq(int(game.farm.parts), 4, "the net recipe spends its parts")
	_eq(int(game.farm.hides), 1, "the net recipe spends its hide")
	await _frames(24)
	_ok(game.player.net_view.visible,
		"the woven net stays on the player even with another slot drawn")
	_ok(game.player.net_view.position.distance_to(game.player.net_view_stowed) < 0.06,
		"and it rides the low hip carry, clear of the blade",
		str(game.player.net_view.position))
	game.player.select_slot(game.player.SLOT_NET)
	# The carry flag and slot gating are applied on the idle frame, so give the
	# player a process frame before reading the drawn pose.
	await _frames(24)
	await get_tree().process_frame
	await get_tree().process_frame
	_ok(game.player.net_view.visible
		and game.player.net_view.position.distance_to(game.player.net_view_rest) < 0.06,
		"slot four draws the same net model up into the hand grip",
		str(game.player.net_view.position))

	await _stand_at_tray(0)
	game.player_interact()
	_ok(game.player.net_sweep < 1.0, "the net swings when the tray is taken",
		"%.2f" % game.player.net_sweep)
	_eq(game.net_catches, 1, "the catch cue fires once per netted tray")
	_ok(game.net_swish_player.playing, "the gauze swish plays on the catch")
	# The lid holds open for about a second, so read it while it is up rather than
	# after the chirp settle, where a slow headless frame can already have it closing.
	await _frames(8)
	var lid: Node3D = game.tray_lids[0] as Node3D
	_ok(lid != null and absf(lid.rotation.x) > deg_to_rad(10.0),
		"the tray lid lifts for the harvest",
		"%.1f deg" % rad_to_deg(lid.rotation.x) if lid != null else "no lid")
	await _frames(20)
	_ok(game.chirp_player.stream != null, "the crickets chirp a beat later")
	await _frames(20)
	_ok(is_equal_approx(game.player.net_sweep, 1.0), "and settles back to the carry",
		"%.2f" % game.player.net_sweep)
	_eq(int(game.farm.live_crickets), FarmState.CRICKET_HARVEST_POPULATION - FarmState.CRICKET_BREEDING_RESERVE,
		"a mature tray nets everything above the breeding reserve")
	_eq(int(game.farm.tray_population(0)), FarmState.CRICKET_BREEDING_RESERVE,
		"the colony falls back to its six-cricket reserve")
	_ok(float(game.farm.trays[0]["progress"]) < 0.01, "netting restarts the culture")
	_ok(game.message_label.text.contains("LIVE") and game.message_label.text.contains("120"),
		"the HUD reports the colony, its capacity and its feed state", game.message_label.text)
	end_case()


func _test_seeding_a_frame() -> void:
	begin_case("seeding", "a starter founds a second colony")
	var frame := _tray_of(1)
	var crickets_before: int = _crickets_for_tray(1).size()
	_eq(crickets_before, 0, "the empty frame has no crickets in it")

	await _stand_at_tray(1)
	game.player_interact()
	await _frames(10)
	var tray: Dictionary = game.farm.trays[1]
	_ok(bool(tray["active"]) and not bool(tray["dead"]), "the frame becomes a live colony")
	_eq(str(tray["species"]), "cricket", "the new colony is crickets")
	_eq(int(game.farm.tray_population(1)), FarmState.CRICKET_START_POPULATION,
		"the new colony starts at the six-cricket floor")
	_eq(int(game.farm.live_crickets), (FarmState.CRICKET_HARVEST_POPULATION - FarmState.CRICKET_BREEDING_RESERVE) - FarmState.CRICKETS_TO_SEED,
		"seeding spends six of the netted crickets")

	var colony: Array = _crickets_for_tray(1)
	_eq(colony.size(), 2, "a fresh colony shows only a couple of crickets")
	if colony.size() > 0:
		var root: Node3D = (colony[0] as Dictionary).get("root") as Node3D
		var start: Vector3 = root.global_position
		await _frames(20)
		_ok(root.visible, "the new colony is visible")
		_ok(root.global_position.distance_to(start) > 0.002,
			"the new colony moves on its own",
			"%.4f" % root.global_position.distance_to(start))

	_ok(str(frame.get_meta("label", "")).contains("TEND"),
		"the frame prompt switches from seeding to tending",
		str(frame.get_meta("label", "")))
	var mark := frame.get_node_or_null("UnfinishedMark") as Label3D
	_ok(mark == null or not mark.visible, "the dormant stencil is cleared once the frame is alive")

	# Feeding a growing colony still works through the same station.
	var feed_before: float = float(game.farm.feed)
	game.player_interact()
	await _frames(6)
	_ok(float(game.farm.feed) < feed_before, "a second press tops the growing colony up")
	end_case()


func _test_kitchen_station() -> void:
	begin_case("kitchen_station", "the kitchen is a real bench against the free wall")
	var bench: Node3D = game.kitchen_body
	_ok(bench != null and is_instance_valid(bench), "the kitchen bench exists")
	if bench == null:
		return
	_eq(str(bench.get_meta("kind", "")), "kitchen", "the bench is a kitchen station")
	_ok(bench.get_node_or_null("KitchenBenchModel") != null, "the generated bench model is attached")
	_ok(absf(bench.global_position.x - game.KITCHEN_SPOT.x) < 0.05,
		"the bench sits where the room was left free")
	_ok(bench.global_position.x - 0.435 > -5.90,
		"the bench back is against the west wall",
		"back %.3f" % (bench.global_position.x - 0.435))
	_ok(game.kitchen_meal_plate != null and game.kitchen_jerky_bundle != null,
		"the two products have a place on the board")
	_ok(not game.kitchen_meal_plate.visible and not game.kitchen_jerky_bundle.visible,
		"an empty kitchen shows no finished food")

	game.player.global_position = Vector3(-4.55, 0.9, game.KITCHEN_SPOT.z)
	game.player.velocity = Vector3.ZERO
	_aim_player_at(Vector3(game.KITCHEN_SPOT.x, 0.95, game.KITCHEN_SPOT.z))
	await _frames(3)
	_ok(game._nearest_interactable() == bench, "the bench is the interaction point at the wall")
	await _wait_prompt("COOK")
	_ok(game.prompt_label.text == "COOK", "the HUD offers COOK at the bench")

	game.player_interact()
	await _frames(2)
	_ok(game.menu.current_screen == "kitchen", "pressing the bench opens the kitchen panel")
	_ok(game.menu.visible, "the kitchen panel is on screen")
	var offered_dress := false
	for node in game.menu.find_children("*", "Button", true, false):
		if (node as Button).text.contains("DRESS"):
			offered_dress = true
	_ok(offered_dress, "the kitchen panel offers the dressing step")
	var offered_stepper := false
	var offered_queue := false
	var offered_collect := false
	for node in game.menu.find_children("*", "Button", true, false):
		var text := (node as Button).text
		if text.contains("BATCHES"):
			offered_stepper = true
		if text.contains("QUEUE"):
			offered_queue = true
		if text.contains("COLLECT"):
			offered_collect = true
	_ok(offered_stepper, "the kitchen panel offers a batch stepper")
	_ok(offered_queue, "the kitchen panel offers queue buttons")
	_ok(offered_collect, "the kitchen panel offers a collect button")
	game.menu.close_menu()
	await _frames(2)
	_ok(not game.menu.visible, "the kitchen panel closes back into the room")
	end_case()


func _test_kitchen_actions() -> void:
	begin_case("kitchen_actions", "dress, cook and cure through the station")
	game.farm.live_crickets = 6
	game.farm.dressed_crickets = 0
	game.farm.meals = 0
	game.farm.jerky = 0
	game.farm.furnace_lit = true
	game.farm.fuel = 4.0
	game._refresh_kitchen_state()

	game.kitchen_action("dress")
	_eq(int(game.farm.dressed_crickets), FarmState.DRESSED_PER_BATCH, "six live crickets become two portions")
	_eq(int(game.farm.live_crickets), 0, "dressing spends the live load")
	_ok(game.message_label.text.contains("Dressed"), "the HUD reports the dressing", game.message_label.text)

	game.kitchen_action("cook")
	_eq(game.farm.kitchen_jobs.size(), 1, "the pot takes the batch onto its queue")
	_eq(int(game.farm.meals), 0, "nothing is ready the instant it is queued")
	_ok(game.get_node_or_null("KitchenSteam_0") != null, "the pot steams while it works")
	_ok(not game.kitchen_meal_plate.visible, "the board stays empty until the batch lands")

	var refused: String = str(game.kitchen_action("cook"))
	_ok(refused.contains("dressed"), "cooking with nothing dressed is refused", refused)
	_eq(game.farm.kitchen_jobs.size(), 1, "the refusal queues no second batch")

	game.farm.advance_minutes(FarmState.COOK_HOURS * 60.0)
	game._refresh_kitchen_state()
	_ok(game.kitchen_meal_plate.visible, "finished meals appear on the board")
	game.kitchen_action("collect")
	_eq(int(game.farm.meals), FarmState.MEALS_PER_BATCH, "collecting moves two meals to the store")
	_ok(not game.kitchen_jerky_bundle.visible, "cooking does not produce jerky")

	game.farm.dressed_crickets = FarmState.DRESSED_PER_BATCH
	game.kitchen_action("cure")
	_eq(game.farm.kitchen_jobs.size(), 1, "the rack takes the batch onto its queue")
	game.farm.advance_minutes(FarmState.CURE_HOURS * 60.0)
	game._refresh_kitchen_state()
	_ok(game.kitchen_jerky_bundle.visible, "cured strips appear on the rack")
	game.kitchen_action("collect")
	_eq(int(game.farm.jerky), FarmState.JERKY_PER_BATCH, "the rack turns two portions into two strips")
	_eq(int(game.farm.meals), FarmState.MEALS_PER_BATCH, "curing adds no meal")
	_ok(str(game.kitchen_body.get_meta("label", "")).contains("LIVE"),
		"the bench prompt reports the stores", str(game.kitchen_body.get_meta("label", "")))
	end_case()


func _test_all_six_frames() -> void:
	begin_case("six_frames", "all six culture slots are built objects")
	_eq(game.tray_bodies.size(), 6, "six frames are registered")
	var built := 0
	for index in game.tray_bodies.size():
		var body: Node3D = game.tray_bodies[index] as Node3D
		if body == null or not is_instance_valid(body):
			continue
		if str(body.get_meta("kind", "")) != "tray":
			continue
		if body.get_node_or_null("CultureTray_%d" % (index + 1)) == null:
			continue
		built += 1
	_eq(built, 6, "every slot has a body, a generated model and a station kind")
	_ok(game.tray_slabs[5] == null and game.tray_slabs[2] == null,
		"the empty frames carry no colony slab")
	var last_mark := game.tray_bodies[5].get_node_or_null("UnfinishedMark") as Label3D
	_ok(last_mark != null and last_mark.text == "06",
		"the last frame is stencilled with its own slot number")
	_ok(str(game.tray_bodies[5].get_meta("label", "")).contains("CULTURE TRAY 6"),
		"the last frame is a named station", str(game.tray_bodies[5].get_meta("label", "")))

	game.farm.live_crickets = FarmState.CRICKETS_TO_SEED
	game._use_tray(5)
	await _frames(3)
	_ok(bool(game.farm.trays[5]["active"]), "the sixth frame takes a netted starter")
	_eq(str(game.farm.trays[5]["species"]), "cricket", "the seeded frame raises crickets")
	var living := false
	for item in game.tray_crickets:
		if typeof(item) == TYPE_DICTIONARY and int((item as Dictionary).get("tray_index", -1)) == 5:
			living = true
	_ok(living, "the sixth colony has living crickets in it")
	_ok(last_mark != null and not last_mark.visible,
		"a seeded frame stops advertising itself as empty")
	end_case()


func _test_food_crate() -> void:
	begin_case("food_crate", "the crate eats rations, meals and jerky")
	game.player.global_position = Vector3(-2.6, 0.9, 2.5)
	game.player.velocity = Vector3.ZERO
	_aim_player_at(Vector3(-2.6, 0.60, 3.4))
	await _frames(3)
	var target: Node3D = game._nearest_interactable()
	_ok(target != null and str(target.get_meta("kind", "")) == "eat",
		"the crate is the food station")
	await _wait_prompt("EAT")
	game.player_interact()
	await _frames(2)
	_eq(game.menu.current_screen, "food", "pressing the crate opens the food panel")

	game.farm.hunger_hours = 6.0
	game.farm.meals = 1
	game.farm.jerky = 0
	var ate: String = str(game.food_action("meal"))
	_ok(ate.contains("meal"), "the meal is eaten through the crate", ate)
	_eq(int(game.farm.meals), 0, "eating the meal spends it")
	_ok(is_equal_approx(float(game.farm.hunger_hours), FarmState.MEAL_HUNGER_HOURS),
		"a hot meal fills the appetite", "%.1f h" % float(game.farm.hunger_hours))
	var refused: String = str(game.food_action("jerky"))
	_ok(refused.contains("jerky"), "an empty jerky store is refused by name", refused)
	game.menu.close_menu()
	await _frames(2)
	_ok(not game.menu.visible, "the food panel closes back into the room")
	end_case()


func _test_pack_cooked_order() -> void:
	begin_case("pack_cooked_order", "a cooked order wraps at the real bench")
	game.farm.orders = [{
		"id": "cave_meal_1",
		"buyer": "THE WEIGHER",
		"product": "meal",
		"qty": 2,
		"min_grade": "B",
		"due_hour": game.farm.abs_hour() + 14.0,
		"pay_parts": 12,
		"pay_water": 1,
		"pay_standing": 4,
		"delivered": false,
		"special": false,
		"source": "cave",
	}]
	game.farm.packed_box.clear()
	game.farm.meals = 2
	game.farm.meal_grade = "A"
	game._use_bench()
	await _frames(2)
	_ok(not game.farm.packed_box.is_empty(), "the bench wraps the ordered meals",
		game.message_label.text)
	_eq(int(game.farm.meals), 0, "the wrapped meals leave the store")
	_eq(str(game.farm.packed_box.get("grade", "")), "A", "the box carries the meal grade")
	_ok(str(game.farm.packed_box.get("product", "")) == "meal", "the box is a meal box")
	_ok(game.farm.order_text().contains("CAVE"), "the slate reads the paper as a cave one",
		game.farm.order_text())
	game.farm.packed_box.clear()
	game.farm.orders.clear()
	end_case()


func _test_cave_slate_hud() -> void:
	begin_case("cave_slate", "cave papers show on the objective block")
	game.farm.orders = [
		{
			"id": "cave_hud_1", "buyer": "THE WEIGHER", "product": "jerky", "qty": 2,
			"min_grade": "B", "due_hour": game.farm.abs_hour() + 14.0, "pay_parts": 11,
			"pay_water": 1, "pay_standing": 4, "delivered": false, "special": false,
			"source": "cave",
		},
		{
			"id": "cave_hud_2", "buyer": "THE WEIGHER", "product": "meal", "qty": 3,
			"min_grade": "B", "due_hour": game.farm.abs_hour() + 14.0, "pay_parts": 12,
			"pay_water": 1, "pay_standing": 4, "delivered": false, "special": false,
			"source": "cave",
		},
	]
	await _frames(8)
	_ok(game.slate_panel != null and game.slate_panel.visible,
		"the slate strip appears while a cave paper is owed")
	_ok(game.slate_label.text.contains("JERKY") and game.slate_label.text.contains("2"),
		"it names what the drop wants", game.slate_label.text)
	_ok(game.slate_label.text.contains("DUE"), "it carries the due hour", game.slate_label.text)
	_ok(game.slate_label.text.contains("+1"), "a second paper is counted, not printed",
		game.slate_label.text)
	_eq(game.order_label.text, "PACK CAVE", "the objective points at the packing bench")

	game.farm.orders.clear()
	await _frames(8)
	_ok(not game.slate_panel.visible, "the strip goes away once the papers are settled")
	_eq(game.order_label.text, "", "and the objective block empties again")
	end_case()


func _test_cave_trade_loop() -> void:
	begin_case("cave_trade_loop", "the paper becomes a box, the box becomes payment, and a missed paper tears")
	# Known state: one paper under the clamp, nothing carried, nothing owed.
	game.farm.cave_papers.clear()
	game.farm.cave_drop.clear()
	game.farm.cave_payout.clear()
	game.farm.packed_box.clear()
	game.farm.orders.clear()
	game.farm.roll_cave_papers()
	_eq(game.farm.cave_paper_count(), 1, "the clamp holds exactly one paper")
	game.player.global_position = game.TRADE_DROP_SPOT + Vector3(-1.30, 0.9, 0.0)
	game.player.velocity = Vector3.ZERO
	_aim_player_at(game.TRADE_DROP_SPOT + Vector3(0.0, 0.70, 0.0))
	await _frames(4)
	_eq(game.prompt_label.text, "TRADE DROP — READ PAPER",
		"the prompt reads the clamp's state from a step away")
	game.player_interact()
	await _frames(3)
	_eq(game.farm.cave_orders().size(), 1, "reading the clamp puts the paper on the slate")
	var cave_order: Dictionary = game.farm.cave_orders()[0]
	var paper_buyer := str(cave_order["buyer"])
	# Pin the goods so the loop is about the channel, not about the day's roll.
	cave_order["product"] = "meal"
	cave_order["qty"] = 2
	cave_order["min_grade"] = "B"
	game.farm.meals = 4
	game.farm.meal_grade = "B"
	game._use_bench()
	await _frames(3)
	_ok(game.farm.cave_box_packed(), "the bench wraps the batch into a cave box", game.message_label.text)
	await _frames(2)
	_eq(game.prompt_label.text, "TRADE DROP — LEAVE BOX",
		"a cave box turns the prompt into the deposit it belongs to")
	_ok(game.message_label.text.contains("drop"),
		"the bench says which hatch the box belongs to", game.message_label.text)
	_ok(str(game.farm.leave_box()).contains("drop in the pocket"),
		"the delivery hatch turns a cave box away")
	_ok(game.farm.delivered_box.is_empty(), "the cave box never enters the hatch queue")

	# Back at the clamp with the box: deposit, wait, collect.
	await _frames(2)
	game.player_interact()
	await _frames(3)
	_ok(game.message_label.text.contains("clamp") and game.message_label.text.contains(paper_buyer),
		"the box is deposited against the paper's buyer", game.message_label.text)
	_ok(not game.farm.cave_payout.is_empty(), "a payment is now owed")
	_ok(not game.farm.cave_payout_ready(), "the payment is not waiting the moment the box goes in")
	await _wait_prompt("TRADE DROP — PAYMENT LATER")
	_eq(game.prompt_label.text, "TRADE DROP — PAYMENT LATER",
		"the prompt says the money is not ready yet")
	game.farm.advance_minutes(61.0)
	await _wait_prompt("TRADE DROP — COLLECT PAYMENT")
	_eq(game.prompt_label.text, "TRADE DROP — COLLECT PAYMENT",
		"once the hour has passed the prompt changes to the collection")
	var parts_before: int = game.farm.parts
	game.player_interact()
	await _frames(3)
	_ok(game.message_label.text.contains("COLLECTED"),
		"the payment is collected on the later visit", game.message_label.text)
	_ok(int(game.farm.parts) > parts_before,
		"the parts land in the account", "%d -> %d" % [parts_before, int(game.farm.parts)])
	_ok(game.farm.cave_drop.is_empty() and game.farm.cave_payout.is_empty(),
		"the clamp is empty once it has been paid out")
	await _frames(2)
	_eq(game.prompt_label.text, "TRADE DROP — EMPTY", "and the prompt says so")

	# A paper nobody filled past due + 2 h comes back torn and costs standing.
	game.farm.cave_papers.clear()
	game.farm.orders.clear()
	game.farm.roll_cave_papers()
	game.farm.take_cave_paper()
	var owed: Dictionary = game.farm.cave_orders()[0]
	owed["product"] = "meal"
	owed["qty"] = 2
	owed["due_hour"] = game.farm.abs_hour() - 2.5
	var standing_before: int = game.farm.standing
	game.farm.advance_minutes(2.0)
	game._refresh_drop_papers()
	_ok(game.farm.cave_orders().is_empty(), "the missed paper leaves the slate")
	_ok(int(game.farm.standing) == maxi(0, standing_before - 2),
		"the miss costs two standing", "%d -> %d" % [standing_before, int(game.farm.standing)])
	_ok(game.drop_paper_torn != null and game.drop_paper_torn.visible,
		"the next visit finds the paper torn under the clamp")
	await _frames(2)
	_eq(game.prompt_label.text, "TRADE DROP — TORN PAPER",
		"the prompt separates a torn paper from a fresh one")
	game.player_interact()
	await _frames(3)
	_ok(game.message_label.text.contains("torn"),
		"reading the torn paper closes the loop", game.message_label.text)
	end_case()


func _clear_pocket_creatures() -> void:
	for creature in game.burrowers.duplicate():
		if is_instance_valid(creature):
			creature.queue_free()
	game.burrowers.clear()


func _last_burrower():
	for index in range(game.burrowers.size() - 1, -1, -1):
		if is_instance_valid(game.burrowers[index]):
			return game.burrowers[index]
	return null


func _test_cinder_burrower() -> void:
	begin_case("cinder_burrower", "the breach sends a heavier variant that shoves, splits and pays ember loot")
	_clear_pocket_creatures()
	game.cinder_cooldown = 0.0
	game.player.can_move = false
	game.player.invulnerable = 999.0
	game.player.global_position = game.POCKET_CHAMBER_CENTER + Vector3(1.2, 0.9, -1.0)
	game.player.velocity = Vector3.ZERO
	await _frames(3)

	# Stirred by work at the clamp, not by a random spawn timer.
	_ok(game._stir_cinder("drop"), "using the drop stirs the breach")
	var cinder = _last_burrower()
	_ok(cinder != null, "a creature answers")
	if cinder == null:
		end_case()
		return
	_eq(str(cinder.variant), "cinder", "the answer is the cinder variant")
	_eq(int(cinder.health), 3, "it carries three health, not two")
	_ok(is_equal_approx(float(cinder.speed), 4.8), "and a 4.8 m/s gait", str(cinder.speed))
	_ok(float(cinder.body_scale) > 1.10, "it is slightly larger than a base body", str(cinder.body_scale))
	_ok(float(cinder.knockback_on_hit) > 0.0, "it is configured to shove the hunter on a hit")
	_ok(bool(cinder.splits_on_death), "and to split when it dies")
	_ok(str(cinder.visual.name).contains("Cinder"),
		"the body is the generated cinder model, not a tinted slime", str(cinder.visual.name))
	_ok(str(cinder.visual.scene_file_path).contains("cinder_burrower"),
		"loaded from its own GLB", str(cinder.visual.scene_file_path))

	# Two may be out at once; a third waits for one of them to go.
	game.cinder_cooldown = 0.0
	_ok(game._stir_cinder("drop"), "the breach can send a second")
	game.cinder_cooldown = 0.0
	_ok(not game._stir_cinder("drop"), "never a third while two are standing")
	_eq(game._cinder_alive(), 2, "exactly two cinders are alive")

	# A landed strike is a shove, not a wound: the hunter loses the ground.
	game.player.global_position = cinder.global_position + Vector3(-1.7, 0.9, 0.0)
	game.player.can_move = true
	game.player.velocity = Vector3.ZERO
	await _frames(2)
	var shove_from: Vector3 = game.player.global_position
	var health_before: int = int(cinder.health)
	cinder.take_hit(1, "melee", (cinder.global_position - game.player.global_position).normalized(), 0.0)
	await _frames(24)
	var shoved: float = shove_from.distance_to(game.player.global_position)
	_eq(int(cinder.health), health_before - 1, "the blade still wounds it")
	_ok(shoved > 0.85 and shoved < 1.55, "the hunter is thrown back about 1.2 m", str(shoved))
	game.player.can_move = false

	# Death: quality A whatever the tool, exactly two ordinary bodies, no third split.
	var before_split: int = game.burrowers.size()
	cinder.take_hit(5, "broadhead", Vector3.FORWARD, 0.0)
	await _frames(3)
	_eq(game.burrowers.size(), before_split + 1, "one death puts two smaller bodies into the room")
	var clones: Array = []
	for creature in game.burrowers:
		if is_instance_valid(creature) and str(creature.get("variant")) == "slime":
			clones.append(creature)
	_eq(clones.size(), 2, "both halves are ordinary burrowers")
	if clones.size() == 2:
		_eq(int(clones[0].health), 2, "a half starts at the base two health")
		_ok(not bool(clones[1].splits_on_death), "and neither half can split again")
		var apart: float = clones[0].global_position.distance_to(clones[1].global_position)
		_ok(apart > 1.2 and apart < 1.6, "they come apart about ±0.7 m", str(apart))
	var cinder_carcass: Node3D = null
	for node in game.interactables:
		if is_instance_valid(node) and str(node.get_meta("kind", "")) == "carcass" and str(node.get_meta("variant", "")) == "cinder":
			cinder_carcass = node as Node3D
	_ok(cinder_carcass != null, "the cinder leaves its own remains")
	if cinder_carcass != null:
		_eq(str(cinder_carcass.get_meta("quality", "")), "A", "a cinder carcass is always A grade")
		game._pick_up_carcass(cinder_carcass)
		_eq(str(game.farm.carried_remains.back().get("variant", "")), "cinder", "the carry remembers which body it came from")
		game.farm.gland_chance = 1.0
		var ember_before: int = game.farm.ember_chitin
		var glands_before: int = game.farm.heat_glands
		game._use_table()
		_eq(game.farm.ember_chitin, ember_before + 1, "butchering yields one ember chitin")
		_eq(game.farm.heat_glands, glands_before + 1, "and the gland when the roll lands")
		_eq(game.farm.carried_remains.size(), 0, "the carry is cleared at the table")
		game.farm.gland_chance = 0.25

	# The leash: past its pocket it gives up the hunt and runs home.
	_clear_pocket_creatures()
	game.cinder_cooldown = 0.0
	await _frames(2)
	_ok(game._stir_cinder("breach"), "the breach stirs again after a minute's rest")
	var leashed = _last_burrower()
	leashed.global_position = game.BREACH_SPOT + Vector3(-25.0, 0.05, 0.0)
	var home_before: float = leashed.global_position.distance_to(game.BREACH_SPOT)
	await _frames(22)
	var home_after: float = leashed.global_position.distance_to(game.BREACH_SPOT)
	_ok(home_after < home_before - 0.8,
		"a cinder outside its leash walks back toward the breach", "%.2f -> %.2f" % [home_before, home_after])
	_ok(not bool(leashed.engaged), "and drops the hunt to do it")

	game.player.invulnerable = 0.0
	game.player.can_move = true
	_clear_pocket_creatures()
	end_case()


func _test_tools() -> void:
	begin_case("tools", "the workbench makes a lantern that burns fuel and an ember snare that comes back")
	game.farm.heat_glands = 1
	game.farm.ember_chitin = 1
	game.farm.parts = maxi(int(game.farm.parts), 4)
	game.farm.chitin = maxi(int(game.farm.chitin), 2)
	game.farm.fuel = 6.0
	var built: String = game.craft_workbench_recipe("gland_lantern")
	_ok(game.farm.lantern_crafted, "the real workbench builds the gland lantern", built)
	_ok(not game.player.lantern.visible, "the lamp is dark until it is lit")
	await _frames(2)
	_ok(game.player.lantern_view != null and game.player.lantern_view.visible,
		"the generated lantern hangs from the belt once it is built")
	if not game.farm.net_crafted:
		game.farm.parts = maxi(int(game.farm.parts), 2)
		game.farm.hides = maxi(int(game.farm.hides), 1)
		game.craft_workbench_recipe("cricket_net")
	# The carry flag is applied from the idle frame, so wait for one rather than
	# racing the physics tick that `_frames` resumes on.
	await _frames(2)
	await get_tree().process_frame
	_ok(game.farm.net_crafted and game.cricket_net_prop != null and game.cricket_net_prop.visible,
		"the generated net leans by the workbench once it is woven")
	game.player.select_slot(game.player.SLOT_NET)
	await _frames(2)
	_ok(game.player.net_view != null and game.player.net_view.visible,
		"and the same net model is in the player's hand", str(game.player.net_view))
	game.player_lantern_click()
	await _frames(2)
	_ok(game.farm.lantern_on and game.player.lantern.visible,
		"the tool lights the warm circle", game.message_label.text)
	await _frames(2)
	_ok(game.pocket_label.text.contains("LANTERN  ON"),
		"the pocket readout shows the lantern burning", game.pocket_label.text)
	_ok(is_equal_approx(game.player.lantern.omni_range, FarmState.LANTERN_RANGE),
		"six metres of light", str(game.player.lantern.omni_range))
	_ok(game.player.lantern.light_color.r > game.player.lantern.light_color.b,
		"and it is warm, not white", str(game.player.lantern.light_color))
	var fuel_before: float = game.farm.fuel
	game.farm.tick_lantern(10.0)
	_ok(game.farm.fuel < fuel_before, "ten in-game minutes burn a fuel unit",
		"%.2f -> %.2f" % [fuel_before, game.farm.fuel])
	game.player_lantern_click()
	await _frames(2)
	_ok(not game.farm.lantern_on and not game.player.lantern.visible, "the same key shuts it")
	game.farm.toggle_lantern()
	game.farm.fuel = 0.0
	game.farm.tick_lantern(12.0)
	await _frames(2)
	_ok(not game.farm.lantern_on and not game.player.lantern.visible,
		"an empty fuel store puts the light out")

	# The last of a unit: the flame gutters instead of burning steady.
	game.farm.fuel = 1.1
	game.player_lantern_click()
	game.farm.lantern_fuel_seconds = 90.0
	await _frames(3)
	_ok(game.farm.lantern_on and game.player.lantern_low,
		"the last two minutes leave the lamp flagged low",
		"%.1f min" % game.farm.lantern_minutes_left())
	var gutter_a: float = game.player.lantern.light_energy
	await _frames(4)
	_ok(not is_equal_approx(gutter_a, game.player.lantern.light_energy),
		"the low flame stutters the light", "%.2f -> %.2f" % [gutter_a, game.player.lantern.light_energy])

	# The ember snare through the real trap and the real creature.
	game.farm.snares = 1
	var made: String = game.farm.craft_at_workbench("ember_snare")
	_eq(game.farm.ember_snares, 1, "ember chitin becomes an ember snare")
	_ok(made.to_lower().contains("snare"), "and the bench says so", made)
	_clear_pocket_creatures()
	var creature = game._spawn_burrower(game.HUNT_BAIT_SPOT + Vector3(0.2, 0.0, 0.0))
	_ok(creature != null, "a body to spring the trap")
	_ok(game.farm.arm_snare().to_lower().contains("ember"), "the ember snare arms first")
	_ok(game.try_trigger_hunt_snare(creature), "the drawn creature triggers it")
	_eq(game.farm.snares, 1, "the wire comes back as a plain snare")
	_eq(game.farm.ember_snares, 0, "the ember quality is spent")
	if is_instance_valid(creature):
		creature.queue_free()
	game.burrowers.clear()
	game.farm.fuel = 6.0
	end_case()


func _first_wisp() -> Node3D:
	for child in game.get_children():
		if str(child.name).begins_with("KitchenWisp_"):
			return child as Node3D
	return null


func _test_kitchen_life() -> void:
	begin_case("kitchen_life", "the lamp breathes and the pot steams while the line is hot")
	_ok(game.kitchen_light != null and game.kitchen_glow != null,
		"the bench carries its own lamp and a shade glow")
	if game.kitchen_light == null:
		return
	# The flicker is random per frame, so compare the spread of a sample rather than
	# two ends of one sequence: two samples can land on nearly the same value.
	var lowest: float = game.kitchen_light.light_energy
	var highest: float = lowest
	for _i in 12:
		game._update_kitchen_life(0.11)
		await _frames(1)
		lowest = minf(lowest, game.kitchen_light.light_energy)
		highest = maxf(highest, game.kitchen_light.light_energy)
	_ok(highest - lowest > 0.002, "the lamp light moves instead of holding one value",
		"%.4f .. %.4f" % [lowest, highest])
	_ok(highest > 0.30 and highest < 0.75, "the flicker stays inside a readable range", "%.3f" % highest)
	var glow := game.kitchen_glow.material_override as StandardMaterial3D
	_ok(glow != null and glow.emission_enabled and glow.emission_energy_multiplier > 0.5,
		"the shade glow brightens with the flame")

	# A cold line means a cold pot: no steam, so the station's state reads at a glance.
	game.farm.furnace_lit = false
	game.farm.fuel = 0.0
	game.kitchen_steam_clock = 0.0
	game.kitchen_steam_live = 0
	var cold_serial: int = game.kitchen_wisp_serial
	for _i in 4:
		game._update_kitchen_life(0.5)
	_eq(game.kitchen_wisp_serial, cold_serial, "a cold pot puts out no steam")

	game.farm.furnace_lit = true
	game.farm.fuel = 4.0
	game.kitchen_steam_clock = 0.0
	var hot_serial: int = game.kitchen_wisp_serial
	game._update_kitchen_life(1.4)
	_ok(game.kitchen_wisp_serial > hot_serial, "a hot pot keeps a low steam going on its own")
	var wisp := _first_wisp()
	_ok(wisp != null, "the steam is real geometry in the room")
	if wisp != null:
		# The wisp is already climbing when it is sampled, so the column is what has
		# to sit over the pot mouth; the rise itself is the point.
		var pot: Vector3 = game._kitchen_local(-0.480, 1.182, 0.030)
		var column: float = Vector2(wisp.position.x - pot.x, wisp.position.z - pot.z).length()
		_ok(column < 0.10 and wisp.position.y >= pot.y - 0.01,
			"the steam rises off the pot mouth, not the bench",
			"%.3f m off, %.3f m up" % [column, wisp.position.y - pot.y])

	# Cooking thickens it rather than switching it on: same window, more wisps.
	game.kitchen_steam_live = 0
	game.kitchen_steam_clock = 0.0
	game.kitchen_cook_heat = 0.0
	var plain_serial: int = game.kitchen_wisp_serial
	game._update_kitchen_life(0.7)
	var plain_count: int = game.kitchen_wisp_serial - plain_serial
	game.kitchen_steam_live = 0
	game.kitchen_steam_clock = 0.0
	game.kitchen_cook_heat = 1.6
	var heated_serial: int = game.kitchen_wisp_serial
	game._update_kitchen_life(0.7)
	var heated_count: int = game.kitchen_wisp_serial - heated_serial
	_ok(heated_count > plain_count, "a fresh cook makes the steam come faster",
		"%d vs %d wisps" % [heated_count, plain_count])
	game.kitchen_cook_heat = 0.0
	end_case()


func _test_cricket_hud() -> void:
	begin_case("cricket_hud", "the carried culture is visible on the HUD")
	game.farm.net_crafted = true
	game.farm.live_crickets = 7
	game.farm.dressed_crickets = 2
	# The HUD is written by the frame loop, so let a few frames go by before reading
	# the label, the same way a player's screen would settle.
	await _frames(8)
	_ok(game.cricket_panel != null and game.cricket_panel.visible,
		"the culture readout appears once the farm is working")
	_ok(game.cricket_label.text.contains("07") and game.cricket_label.text.contains("IN NET"),
		"the HUD shows the live cricket count against the net's capacity", game.cricket_label.text)
	_ok(game.cricket_label.text.contains("02"),
		"the HUD shows the dressed portions too", game.cricket_label.text)

	game.farm.net_crafted = false
	game.farm.live_crickets = 0
	game.farm.dressed_crickets = 0
	await _frames(8)
	_ok(not game.cricket_panel.visible, "a bare-handed shift keeps the clean screen")
	end_case()


func _test_pocket_walk() -> void:
	begin_case("pocket_walk", "the deposit pocket is a real walk out of the old cave")
	# M4 opened the old collapse into the deposit pocket. The squeeze has to be
	# walkable, the route past it has to have floor, and the spaces have to
	# connect without a teleport or a fall out of the level.
	var floor_query := PhysicsRayQueryParameters3D.create(Vector3(30.0, 1.60, -1.80), Vector3(30.0, -1.00, -1.80))
	var floor_hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(floor_query)
	_ok(not floor_hit.is_empty() and absf(float(floor_hit["position"].y)) < 0.10,
		"the corridor past the collapse has its own floor at the old cave's level",
		"hit %s" % str(floor_hit))

	# Drive the real CharacterBody through the dug-through shoulders.
	game.player.global_position = Vector3(22.10, 0.9, -1.80)
	game.player.velocity = Vector3.ZERO
	_aim_player_at(Vector3(31.00, 0.9, -1.80))
	await _frames(2)
	Input.action_press("move_forward")
	await _frames(80)
	Input.action_release("move_forward")
	_ok(game.player.global_position.x > 25.40,
		"the first-person player walks through the dug collapse into the pocket",
		"x %.2f" % game.player.global_position.x)

	# The bend: the corridor's east end is wall, and the route turns north.
	var end_query := PhysicsRayQueryParameters3D.create(Vector3(39.40, 1.0, -2.00), Vector3(41.00, 1.0, -2.00))
	_ok(not game.get_world_3d().direct_space_state.intersect_ray(end_query).is_empty(),
		"the corridor ends in wall instead of open space")
	game.player.global_position = Vector3(38.70, 0.9, -1.60)
	game.player.velocity = Vector3.ZERO
	_aim_player_at(Vector3(38.70, 0.9, 3.40))
	await _frames(2)
	Input.action_press("move_forward")
	await _frames(60)
	Input.action_release("move_forward")
	_ok(game.player.global_position.z > 0.50,
		"the route turns north from the corridor into the gallery",
		"z %.2f" % game.player.global_position.z)

	# Gallery and chamber are one unbroken floor: ray across both joints.
	var gallery_query := PhysicsRayQueryParameters3D.create(Vector3(65.00, 1.0, 2.50), Vector3(67.00, 1.0, 2.50))
	var gallery_hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(gallery_query)
	_ok(gallery_hit.is_empty(), "the gallery opens into the chamber without a wall")
	# The chamber mouth is a real doorway, not a lip over open space: walk back
	# out of it and the floor has to hold the player at the same height.
	game.player.global_position = Vector3(67.60, 0.9, 2.50)
	game.player.velocity = Vector3.ZERO
	_aim_player_at(Vector3(60.00, 0.9, 2.50))
	await _frames(2)
	Input.action_press("move_forward")
	await _frames(70)
	Input.action_release("move_forward")
	_ok(game.player.global_position.x < 65.60 and absf(game.player.global_position.y) < 0.20,
		"the walk out of the chamber stays on floor at corridor height",
		"x %.2f  y %.2f" % [game.player.global_position.x, game.player.global_position.y])
	var drop_walk: Vector3 = game.TRADE_DROP_SPOT - Vector3(10.0, 0.0, -2.0)
	_ok(Vector2(drop_walk.x, drop_walk.z).length() > 60.0,
		"the drop is a real walk away, not next door to the shutter",
		"%.1f m" % Vector2(drop_walk.x, drop_walk.z).length())

	# The place was used by someone: prints, a satchel, a count on the wall.
	var print_count := 0
	for child in game.get_children():
		if str(child.name).begins_with("PocketBootprint_"):
			print_count += 1
	_eq(print_count, 26, "a bootprint trail crosses the pocket")
	_ok(game.get_node_or_null("PocketSatchel") != null and game.get_node_or_null("PocketChalkTally_0") != null,
		"the drop has a dropped satchel and a chalk count beside it")

	# Presentation pass: the chamber has three silhouettes and a painted way home,
	# because the walk back is unlit, long and has no map.
	_ok(game.get_node_or_null("PocketOreHopper") != null
		and game.get_node_or_null("PocketCableSpool") != null
		and game.get_node_or_null("PocketPalletStack") != null,
		"the chamber holds three distinct landmark silhouettes")
	var hopper_ray := PhysicsRayQueryParameters3D.create(Vector3(69.10, 1.20, -1.60), Vector3(69.10, 1.20, 1.20))
	_ok(not game.get_world_3d().direct_space_state.intersect_ray(hopper_ray).is_empty(),
		"the ore hopper is solid geometry, not a decal")
	_ok(game.get_node_or_null("PocketBeacon") != null, "the chamber mouth is marked by a hung hand lamp")
	var dash_count := 0
	for child in game.get_children():
		if str(child.name).begins_with("PocketPaintDash_"):
			dash_count += 1
	_ok(dash_count >= 30, "a worn paint line runs from the drop back to the old cave",
		"%d dashes" % dash_count)
	var sign_text := ""
	var sign_names := ""
	for child in game.get_children():
		if child is Label3D and str(child.name).begins_with("PocketSignText"):
			sign_text += str((child as Label3D).text) + " "
			sign_names += str(child.name) + ","
	_ok(sign_text.contains("OUT") and sign_text.contains("FURNACE"),
		"both stencils point the way home",
		sign_text.replace("\n", " / ") + " [" + sign_names + "]")

	# The drop itself answers, even empty. Its papers are M5.
	_ok(game.trade_drop_body != null and game.trade_drop_body in game.interactables,
		"the trade drop is a real interactable")
	game.player.global_position = game.TRADE_DROP_SPOT + Vector3(-1.30, 0.9, 0.0)
	game.player.velocity = Vector3.ZERO
	_aim_player_at(game.TRADE_DROP_SPOT + Vector3(0.0, 0.70, 0.0))
	await _frames(4)
	_eq(str(game._nearest_interactable()), str(game.trade_drop_body), "the drop is the nearest thing at arm's length")
	await _wait_prompt("TRADE DROP — READ PAPER")
	_eq(game.prompt_label.text, "TRADE DROP — READ PAPER",
		"the drop's prompt says a paper is waiting before anything is touched")
	_eq(game.farm.cave_paper_count(), 1, "looking at the clamp does not take the paper")
	_ok(game.drop_paper != null and game.drop_paper.visible,
		"a paper waits visibly under the clamp", str(game.drop_paper))
	game.player_interact()
	await _frames(3)
	_ok(game.message_label.text.contains("PAPER"),
		"reading the clamp gives the paper's terms",
		game.message_label.text)
	_eq(game.farm.cave_orders().size(), 1, "the paper becomes a cave order on the slate")
	_ok(not game.drop_paper.visible, "the clamp is bare once the paper has been taken")
	_ok(game.farm.packed_box.is_empty(), "taking a paper packs nothing by itself")
	var paper_material := game.drop_paper.material_override as StandardMaterial3D
	_ok(paper_material != null and paper_material.albedo_texture != null,
		"the clamp's paper carries the generated order note")
	_ok(game.pocket_panel.visible, "the pocket readout appears in the chamber")
	_ok(game.pocket_label.text.contains("CLAMP"), "and it names the clamp's state", game.pocket_label.text)
	_ok(game.pocket_label.text.contains("LANTERN"), "beside the lantern's", game.pocket_label.text)
	await _frames(2)
	_eq(game.prompt_label.text, "TRADE DROP — EMPTY",
		"with the paper read the prompt goes back to empty")

	# The breach is a glimpse: a message and warm light, no fight and no gate.
	_ok(game.breach_body != null and game.breach_body in game.interactables,
		"the nest breach is a real interactable")
	game.player.global_position = game.BREACH_SPOT + Vector3(0.0, 0.9, -1.30)
	game.player.velocity = Vector3.ZERO
	_aim_player_at(game.BREACH_SPOT + Vector3(0.0, 1.10, 0.0))
	await _frames(4)
	_eq(str(game._nearest_interactable()), str(game.breach_body), "the breach is the nearest thing in front of it")
	await _wait_prompt("LOOK INSIDE")
	_eq(game.prompt_label.text, "LOOK INSIDE", "the breach asks to be looked into")
	var base_energy: float = game.breach_light.light_energy if game.breach_light != null else 0.0
	game.player_interact()
	await _frames(10)
	_ok(game.message_label.text.contains("breathing"),
		"looking in gives a glimpse of what is behind the wall", game.message_label.text)
	_ok(game.breach_light != null and game.breach_light.light_energy > base_energy,
		"the breach light flares when the player looks in",
		"%.2f -> %.2f" % [base_energy, game.breach_light.light_energy if game.breach_light != null else 0.0])

	# The pocket has its own soundscape: positional, synthesised at load, and
	# placed so the room you are in decides what you hear.
	var pocket_sound: PocketAudio = game.pocket_audio
	_ok(pocket_sound != null and is_instance_valid(pocket_sound),
		"the pocket owns a soundscape node", "%s" % str(pocket_sound))
	if pocket_sound != null:
		_ok(pocket_sound.draft_stream != null and pocket_sound.draft_stream.data.size() > 16000,
			"the corridor draft is a real synthesised loop",
			"%d samples" % (pocket_sound.draft_stream.data.size() / 2 if pocket_sound.draft_stream != null else 0))
		_ok(pocket_sound.draft_stream != null and pocket_sound.draft_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,
			"the draft loops without a restart seam")
		_ok(pocket_sound.note_stream != null and pocket_sound.note_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD,
			"the drop's tone is its own looping bed, not a reused drip")
		_ok(pocket_sound.drip_stream != null and pocket_sound.drip_stream.loop_mode != AudioStreamWAV.LOOP_FORWARD,
			"the drip is a one-shot so the gaps between them stay uneven")
		var draft_pos := Vector3.ZERO
		if pocket_sound.draft_player != null:
			draft_pos = pocket_sound.draft_player.global_position
		_ok(pocket_sound.draft_player != null and draft_pos.x > 24.0 and draft_pos.x < 40.0 and absf(draft_pos.z + 1.7) < 1.0,
			"the draft is positional and sits inside the approach corridor", str(draft_pos))
		_ok(pocket_sound.draft_player != null and pocket_sound.draft_player.max_distance < 39.0,
			"the corridor draft does not reach the chamber",
			"reach %.1f m vs %.1f m to the chamber" % [pocket_sound.draft_player.max_distance if pocket_sound.draft_player != null else 0.0, draft_pos.distance_to(game.POCKET_CHAMBER_CENTER)])
		var note_pos := Vector3.ZERO
		if pocket_sound.note_player != null:
			note_pos = pocket_sound.note_player.global_position
		_ok(pocket_sound.note_player != null and note_pos.distance_to(game.TRADE_DROP_SPOT) < 3.0,
			"the drop has a distinct tone positioned on the clamp", str(note_pos))
		_ok(pocket_sound.drip_players.size() >= 4,
			"several drip sources are spread through the pocket",
			"%d sources" % pocket_sound.drip_players.size())
		var drips_in_pocket := 0
		for drip_player in pocket_sound.drip_players:
			var drip_pos: Vector3 = drip_player.global_position
			if drip_pos.x > 40.0 and drip_pos.x < 76.0 and drip_pos.z > 0.0 and drip_pos.z < 6.0 and drip_pos.y > 2.0:
				drips_in_pocket += 1
		_ok(drips_in_pocket == pocket_sound.drip_players.size(),
			"every drip hangs from the pocket's ceiling, not in the old cave",
			"%d of %d in the pocket" % [drips_in_pocket, pocket_sound.drip_players.size()])
		var drips_before := pocket_sound.drip_serial
		pocket_sound.play_drip()
		_ok(pocket_sound.drip_serial == drips_before + 1,
			"a drip can be struck on demand for the room's clock",
			"%d -> %d" % [drips_before, pocket_sound.drip_serial])
		var loud_db: float = pocket_sound.draft_player.volume_db if pocket_sound.draft_player != null else 0.0
		game.menu.open_pause()
		await _frames(4)
		_ok(pocket_sound.draft_player != null and pocket_sound.draft_player.volume_db < loud_db - 15.0,
			"opening the menu ducks the pocket as well as the basement",
			"%.1f -> %.1f dB" % [loud_db, pocket_sound.draft_player.volume_db if pocket_sound.draft_player != null else 0.0])
		game.menu.close_menu()
		await _frames(8)
		_ok(pocket_sound.draft_player != null and absf(pocket_sound.draft_player.volume_db - loud_db) < 0.5,
			"closing the menu brings the pocket back",
			"%.1f dB, paused %s, muted %s" % [pocket_sound.draft_player.volume_db if pocket_sound.draft_player != null else 0.0, str(get_tree().paused), str(pocket_sound.muted)])
	end_case()
