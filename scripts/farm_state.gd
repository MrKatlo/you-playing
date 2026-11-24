class_name FarmState
extends RefCounted

# Pure model for the basement farm. No scene access, no nodes: it can be driven
# headless in steps of in-game minutes, which is how it gets tested.
#
# Time contract: one in-game hour = one real minute, so 1 real second = 1 game
# minute. advance_minutes() is fed by the basement every frame.

const SAVE_VERSION := 13
const RailStateModel := preload("res://scripts/rail_state.gd")
const TRAY_SLOTS := 6
const START_TRAYS := 1
const MAGGOT_MATURATION_HOURS := 12.0
const CRICKET_MATURATION_HOURS := 30.0
const FEED_HOURS_PER_UNIT := 4.0
# C2 // culture. A mature cricket tray is taken alive with a net, split to found
# a new colony, then dressed, cooked or cured at the kitchen.
# C2.3 // colony population. Every tray carries a real count of live crickets:
# six when a starter is settled, a hard ceiling of 120, and growth measured on
# the game clock where one real second is one game minute. The two milestones
# (27 at 2.5 real minutes, 43 at five) are what the schedule is solved for; the
# tail after five minutes approaches the ceiling without ever overshooting it.
const CRICKET_START_POPULATION := 6
# The floor a scoop can never take a colony below, however many crickets it holds.
const CRICKET_BREEDING_RESERVE := CRICKET_START_POPULATION
const CRICKET_CAPACITY := 120
const CRICKET_HARVEST_POPULATION := 27
const CRICKET_FIRST_MILESTONE_MINUTES := 150.0
const CRICKET_SECOND_MILESTONE_MINUTES := 300.0
const CRICKET_SECOND_MILESTONE_POPULATION := 43
const CRICKET_LATE_GROWTH_RATE := 0.006
# The net is the container: a full net stops a scoop instead of spilling.
const NET_CAPACITY := 60
const CRICKETS_TO_SEED := 6
const CRICKETS_TO_DRESS := 6
# Dressing is where the waste lives: shells, legs and gut come off six crickets,
# so a full net load leaves two portions and not six. That keeps a 30 h cricket
# tray slightly ahead of a maggot tray's calories instead of drowning the farm in
# free food, and it makes seeding (6 live) a real alternative to dressing them.
const DRESSED_PER_BATCH := 2
const MEALS_PER_BATCH := 2
const JERKY_PER_BATCH := 2
const DRESS_HOURS := 0.1
const COOK_HOURS := 0.5
const CURE_HOURS := 1.0
const COOK_FUEL_COST := 1.0
# C2.10 // a queue, not a single pot: the board takes as many batches as the
# larder and the fire can pay for, then works through them one at a time.
const MAX_KITCHEN_JOBS := 12
const EAT_HUNGER_LIMIT := 12.0
const MEAL_HUNGER_HOURS := 36.0
const JERKY_HUNGER_HOURS := 22.0
const FUEL_HOURS := [6.0, 8.0, 9.0, 10.0]
const RATION_HUNGER_HOURS := 30.0
const VENOM_SECONDS := 90.0
const UPGRADE_COSTS := [6, 14, 26]
const AXES := ["throughput", "labour", "quality", "heat", "rivets"]
const AXIS_NAMES := {
	"throughput": "THROUGHPUT",
	"labour": "LABOUR",
	"quality": "QUALITY",
	"heat": "HEAT EFFICIENCY",
	"rivets": "RIVET GUN",
}
const BUYERS := ["VESNA", "OLD KOREN", "THE TANNER", "MIRA NEXT DOOR", "HOLLOW JAN", "THE WEIGHER", "THE RIVET"]
# The cave channel: tighter clock than the hatch, a cap on papers under the clamp,
# and payment that only exists after the buyer has been and gone.
const CAVE_PAPER_CAP := 6
# The gland lantern burns one unit of furnace fuel per ten in-game minutes, and
# ten in-game minutes are 600 in-game seconds of burn in the field below.
const LANTERN_FUEL_SECONDS := 600.0
const LANTERN_RANGE := 6.0
const CAVE_ORDER_DUE_HOURS := 14.0
const CAVE_ORDER_GRACE_HOURS := 2.0
const CAVE_PAYOUT_DELAY_HOURS := 1.0
const GOODS_NAMES := ["water", "coal", "medicine"]
const DRIVER_MAX_DURABILITY := 12
const BOLT_TYPE_ORDER := ["standard", "broadhead", "tether"]
const BOLT_TYPE_NAMES := {
	"standard": "SALVAGE",
	"broadhead": "BROADHEAD",
	"tether": "TETHER",
}
const WORKBENCH_RECIPE_ORDER := [
	"basic_bolts", "broadhead_bolts", "tether_bolt", "snare_kit", "cricket_net",
	"chain_link", "ember_snare", "gland_lantern",
	"driver_repair", "antidote", "insulation_patch", "warm_storage_rack",
	"furnace_heat_reclaimer",
]
const WORKBENCH_RECIPES := {
	"basic_bolts": {
		"label": "SALVAGE BOLTS ×3",
		"description": "Shape chitin splinters around scrap shafts. Used by the bolt driver.",
		"cost": {"parts": 1, "chitin": 1},
		"output": {"bolts": 3},
	},
	"broadhead_bolts": {
		"label": "BROADHEAD BOLTS ×2",
		"description": "Wider chitin wedges kill quickly, but turn a clean hide into scrap.",
		"cost": {"parts": 1, "chitin": 2},
		"output": {"broadhead_bolts": 2},
	},
	"tether_bolt": {
		"label": "TETHER BOLT",
		"description": "A hide cord cinches the slime in place without puncturing the hide.",
		"cost": {"parts": 1, "hides": 1},
		"output": {"tether_bolts": 1},
	},
	"snare_kit": {
		"label": "FLOOR SNARE",
		"description": "A bait-side wire loop that holds a drawn creature still long enough to choose the kill.",
		"cost": {"parts": 2, "hides": 1},
		"output": {"snares": 1},
	},
	"cricket_net": {
		"label": "CRICKET NET",
		"description": "Wire hoop and worn gauze. Take a mature tray alive, or move a starter into an empty frame.",
		"cost": {"parts": 2, "hides": 1},
		"output_text": "cricket net woven",
		"effect": "craft_net",
	},
	"driver_repair": {
		"label": "REBUILD BOLT DRIVER",
		"description": "Replace the worn pressure seal before the driver seizes in the hunt room.",
		"cost": {"parts": 1, "chitin": 1},
		"output_text": "driver restored to full pressure",
		"effect": "repair_driver",
	},
	"antidote": {
		"label": "ANTIDOTE",
		"description": "Filter venom from chitin through one jar of clean water.",
		"cost": {"chitin": 1, "water": 1},
		"output": {"antidotes": 1},
	},
	"chain_link": {
		"label": "CHAIN LINK",
		"description": "Re-cut a length of shutter chain and rivet a new link into it.",
		"cost": {"parts": 1, "chitin": 1},
		"output": {"chain_links": 1},
	},
	"ember_snare": {
		"label": "EMBER SNARE",
		"description": "Rewire a floor snare around ember chitin. The wire survives its first trigger and folds back into a plain snare.",
		"cost": {"ember_chitin": 1, "snares": 1},
		"output": {"ember_snares": 1},
	},
	"gland_lantern": {
		"label": "GLAND LANTERN",
		"description": "Hang a cinder heat gland in a chitin-and-scrap cage. Six metres of warm light, burning furnace fuel.",
		"cost": {"heat_glands": 1, "parts": 2, "chitin": 1},
		"output_text": "gland lantern built and hung from the belt",
		"effect": "craft_lantern",
	},
	"insulation_patch": {
		"label": "INSULATION PATCH",
		"description": "Sew a hide over a scrap frame. Install it at a leaking wall gap.",
		"cost": {"parts": 2, "hides": 1},
		"output": {"patches": 1},
	},
	"warm_storage_rack": {
		"label": "WARM STORAGE RACK",
		"description": "Rebuild a shelf with a furnace-line coil and heat lamp. It makes a real warm rest point beside the stores.",
		"cost": {"parts": 3, "chitin": 1, "hides": 1},
		"output_text": "storage shelf and heat lamp installed",
		"effect": "install_storage_rack",
	},
	"furnace_heat_reclaimer": {
		"label": "FIT C-4 HEAT RECLAIMER",
		"description": "Bolt the recovered C-4 regulator beside the furnace. It recovers waste heat, making fuel last longer and the room warm faster.",
		"cost": {"parts": 2, "thermal_regulators": 1},
		"output_text": "C-4 heat reclaimer installed beside the furnace",
		"effect": "install_heat_reclaimer",
	},
}

# C3 // the first night. The stage machine and the chain state are one object so
# the save writes them together and old saves can be recognised by its absence.
var story := StoryState.new()
var rail = RailStateModel.new()
var scrap_metal := 0
var wiring := 0
var batteries := 0
var rail_stage2_kit := false
var rail_stage3_kit := false

var clock := 6.0
var day := 1
var temperature := 26.0
var fuel := 8.0
var feed := 6.0
var mass := 0
var rations := 0
var bait := 0
var hides := 0
var chitin := 0
var parts := 4
var water := 2
var coal := 1
var medicine := 0
var antidotes := 0
var bolts := 0
var broadhead_bolts := 0
var tether_bolts := 0
var snares := 0
var patches := 0
# C2 state contract. The kitchen, cave orders and the gland lantern land in later
# modules; the fields exist from schema 8 so a save never needs re-migrating.
var live_crickets := 0
var dressed_crickets := 0
var meals := 0
var jerky := 0
var meal_grade := "B"
var jerky_grade := "B"
# Queued batches, in order. Each job holds its kind, time left and grade so a
# save mid-cook resumes exactly where it stopped.
var kitchen_jobs: Array = []
var ready_meals := 0
var ready_jerky := 0
var ready_grade := "B"
var net_crafted := false
var ember_chitin := 0
var heat_glands := 0
# The cinder carcass always carries ember chitin; the gland is a quarter chance.
# Exposed so the suite can pin both ends instead of rolling dice.
var gland_chance := 0.25
var ember_snares := 0
var lantern_crafted := false
var lantern_on := false
var lantern_fuel_seconds := 0.0
# Which trap is in the floor: "" when clear, "plain" or "ember" when armed.
var snare_kind := ""
var cave_papers: Array = []
var cave_drop: Dictionary = {}
var cave_payout: Dictionary = {}
var driver_durability := DRIVER_MAX_DURABILITY
var selected_bolt_type := "standard"
var snare_armed := false
var storage_rack_installed := false
var thermal_regulators := 0
var chain_links := 0

var heat_reclaimer_installed := false
# C4 cold store: which of the three intact jars have been searched, whether the
# sealed crate is opened, and whether the cold frame has its patch fitted.
var cold_store_jars_searched: Array[int] = []
var cold_store_crate_opened := false
var cold_frame_installed := false
# C4 // one cooked meal kept in the fitted frame. Cold is the only preservation
# rule the farm has, so it is expressed as doubling that meal's hunger hours
# instead of adding a resource or a second food type.
var cold_frame_meal := false
var standing := 10
var traffic := 0
var hunger_hours := RATION_HUNGER_HOURS
var starving := false
var venom_seconds := 0.0
var furnace_lit := true
var bedside_kit_opened := false
var trays: Array = []
var orders: Array = []
var delivered_box: Dictionary = {}
var packed_box: Dictionary = {}
# Every body the player is carrying. Each entry is {"quality": String, "variant": String}.
var carried_remains: Array = []
# Physical pickups have one saved owner: this list or the carried inventory.
var world_items: Array = []
var next_world_item_id := 1
var gaps: Array = []
var upgrades := {"throughput": 0, "labour": 0, "quality": 0, "heat": 0, "rivets": 0}
var kills := 0
var night_rolled := false
var minute_buffer := 0.0
var report: Array = []

func _init() -> void:
	new_game()

func new_game() -> void:
	rail = RailStateModel.new()
	scrap_metal = 0
	wiring = 0
	batteries = 0
	rail_stage2_kit = false
	rail_stage3_kit = false
	clock = 6.0
	day = 1
	temperature = 26.0
	fuel = 8.0
	feed = 6.0
	mass = 0
	rations = 1
	bait = 0
	hides = 0
	chitin = 0
	parts = 4
	water = 2
	coal = 1
	medicine = 0
	antidotes = 0
	# Ammunition is earned: the first kill teaches the bolt pattern, so a fresh
	# shift starts with an empty driver and a machete.
	bolts = 0
	broadhead_bolts = 0
	tether_bolts = 0
	snares = 0
	patches = 0
	live_crickets = 0
	dressed_crickets = 0
	meals = 0
	jerky = 0
	meal_grade = "B"
	jerky_grade = "B"
	kitchen_jobs.clear()
	ready_meals = 0
	ready_jerky = 0
	ready_grade = "B"
	net_crafted = false
	ember_chitin = 0
	heat_glands = 0
	ember_snares = 0
	lantern_crafted = false
	lantern_on = false
	lantern_fuel_seconds = 0.0
	snare_kind = ""
	cave_papers.clear()
	cave_drop.clear()
	cave_payout.clear()
	driver_durability = DRIVER_MAX_DURABILITY
	selected_bolt_type = "standard"
	snare_armed = false
	storage_rack_installed = false
	thermal_regulators = 0
	chain_links = 0
	heat_reclaimer_installed = false
	standing = 10
	traffic = 0
	story.reset()
	cold_store_jars_searched.clear()
	cold_store_crate_opened = false
	cold_frame_installed = false
	cold_frame_meal = false
	hunger_hours = RATION_HUNGER_HOURS
	starving = false
	venom_seconds = 0.0
	furnace_lit = true
	bedside_kit_opened = false
	kills = 0
	night_rolled = false
	minute_buffer = 0.0
	report.clear()
	orders.clear()
	delivered_box.clear()
	packed_box.clear()
	carried_remains.clear()
	world_items.clear()
	next_world_item_id = 1
	upgrades = {"throughput": 0, "labour": 0, "quality": 0, "heat": 0, "rivets": 0}
	trays.clear()
	for index in TRAY_SLOTS:
		trays.append({
			"species": "cricket" if index == 0 else "maggot",
			"active": index < START_TRAYS,
			"progress": 0.0,
			"population": CRICKET_START_POPULATION if index == 0 else 0,
			"growth_minutes": 0.0,
			"health": 1.0,
			"fed": 1.0,
			"dead": false,
		})
	# One established colony gives the first night a live responsibility.  It
	# starts at the six-cricket floor and has to be grown to its first scoop, so
	# the population, the derived progress and the clock all agree on day one.
	# The second physical frame in the room is intentionally dormant.
	trays[0]["population"] = CRICKET_START_POPULATION
	trays[0]["growth_minutes"] = 0.0
	trays[0]["progress"] = 0.0
	gaps.clear()
	for index in 4:
		gaps.append({"sealed": false, "label": gap_label(index)})
	# The clamp is never empty on a fresh shift: somebody left the first paper
	# before the player ever opened the shutter.
	roll_cave_papers()

# ---------------------------------------------------------------- time & ticks

func abs_hour() -> float:
	return float(day - 1) * 24.0 + clock

func clock_text() -> String:
	var hours := int(clock)
	var minutes := int((clock - float(hours)) * 60.0)
	return "%02d:%02d" % [hours, minutes]

func advance_minutes(minutes: float) -> void:
	minute_buffer += minutes
	while minute_buffer >= 1.0:
		minute_buffer -= 1.0
		_tick_minute()

func _tick_minute() -> void:
	clock += 1.0 / 60.0
	_burn_fuel()
	_update_temperature()
	_grow_trays()
	_update_hunger()
	_tick_kitchen()
	_expire_cave_orders()
	if clock >= 24.0:
		clock -= 24.0
		day += 1
		night_rolled = false
		_dawn()
	if clock >= 20.0 and not night_rolled:
		night_rolled = true
		report.append("NIGHTFALL // something is testing the gaps.")

func _burn_fuel() -> void:
	if not furnace_lit:
		return
	var hours := float(FUEL_HOURS[mini(int(upgrades["heat"]), FUEL_HOURS.size() - 1)])
	# The C-4 reclaimer is a real expedition return: it catches waste heat from
	# the firebox rather than creating fuel from nothing.  The longer burn time
	# matters on a night when a hunt or cave trip went badly.
	if heat_reclaimer_installed:
		hours *= 1.30
	fuel = maxf(0.0, fuel - (1.0 / 60.0) / hours)
	if fuel <= 0.0:
		furnace_lit = false
		report.append("THE FURNACE IS OUT // feed it fat, skin or bone.")

func _update_temperature() -> void:
	# An unlit, leaking basement cannot plateau at a merely chilly temperature.
	# It keeps drifting toward a genuinely dangerous cold state until the player
	# restores the fire or later seals and upgrades the room.
	var target := (28.5 if heat_reclaimer_installed else 27.0) if furnace_lit and fuel > 0.0 else 5.0
	var insulation := float(upgrades["heat"])
	var response := 0.006 + insulation * 0.004
	if target > temperature:
		response = 0.02
	temperature = lerpf(temperature, target, response)

func temperature_band() -> String:
	if temperature >= 26.0:
		return "WARM"
	if temperature >= 20.0:
		return "COOL"
	if temperature >= 14.0:
		return "COLD"
	return "FREEZING"

func growth_multiplier() -> float:
	if temperature >= 26.0:
		return 1.0
	if temperature >= 20.0:
		return 0.6
	if temperature >= 14.0:
		return 0.2
	return 0.0

func _grow_trays() -> void:
	var mult := growth_multiplier()
	var feed_need := 0.0
	for tray in trays:
		if not bool(tray["active"]) or bool(tray["dead"]):
			continue
		feed_need += (1.0 / 60.0) / FEED_HOURS_PER_UNIT
	if upgrades["labour"] >= 2:
		feed_need *= 0.5
	if feed >= feed_need:
		feed = maxf(0.0, feed - feed_need)
		for tray in trays:
			if bool(tray["active"]) and not bool(tray["dead"]):
				tray["fed"] = 1.0
	else:
		for tray in trays:
			if bool(tray["active"]) and not bool(tray["dead"]):
				tray["fed"] = 0.0
	for tray in trays:
		if not bool(tray["active"]) or bool(tray["dead"]):
			continue
		var health := float(tray["health"])
		var grows := mult > 0.0 and bool(tray["fed"]) and health > 0.15
		if str(tray.get("species", "")) == "cricket":
			# Crickets grow as a population: fed minutes convert straight into
			# insects on the schedule, and the tray's visual bar is derived from
			# that count so the room and the model never disagree.
			if grows:
				# C2.7 // one tick is one game minute and the colony's clock is real
				# time: the 2.5-minute milestone has to hold in a cold-start room, so
				# cold either pauses growth (freezing) or lets it run, rather than
				# stretching the schedule. Feed is the gate that matters.
				tray["growth_minutes"] = float(tray.get("growth_minutes", 0.0)) + 1.0
			tray["population"] = cricket_population_at(float(tray["growth_minutes"]))
			tray["progress"] = clampf(float(int(tray["population"]) - CRICKET_START_POPULATION) / float(CRICKET_HARVEST_POPULATION - CRICKET_START_POPULATION), 0.0, 1.0)
		else:
			var progress := float(tray["progress"])
			if grows:
				progress = minf(1.4, progress + (1.0 / 60.0) / MAGGOT_MATURATION_HOURS * mult)
			tray["progress"] = progress
		if not bool(tray["fed"]):
			health -= 0.05 / 60.0
		if temperature < 18.0:
			health -= 0.15 / 60.0
		if temperature < 14.0:
			health -= 0.35 / 60.0
		health = clampf(health, 0.0, 1.0)
		tray["health"] = health
		if health <= 0.0:
			tray["dead"] = true
			report.append("A COLONY DIED // %s tray needs a starter culture (3 parts)." % str(tray["species"]).to_upper())

func _update_hunger() -> void:
	hunger_hours = maxf(0.0, hunger_hours - 1.0 / 60.0)
	starving = hunger_hours <= 0.0

func tick_venom(delta_seconds: float) -> void:
	if venom_seconds > 0.0:
		venom_seconds = maxf(0.0, venom_seconds - delta_seconds)
		if venom_seconds <= 0.0:
			report.append("THE VENOM HAS PASSED // hands steady again.")

func apply_venom() -> void:
	venom_seconds = VENOM_SECONDS
	report.append("VENOM // hands slow. Brew or sleep it off.")

func hand_speed() -> float:
	if venom_seconds > 0.0:
		return 0.5
	if starving:
		return 0.8
	return 1.0

func move_speed_scale() -> float:
	if venom_seconds > 0.0:
		return 0.6
	if starving:
		return 0.8
	return 1.0

# ---------------------------------------------------------------- trays

## The growth schedule, in game minutes of *fed* colony life. Solved so a colony
## that starts at six reaches 27 at the 2.5-minute milestone and 43 at five
## minutes, then eases towards the 120 ceiling instead of jumping.
static func cricket_population_at(minutes: float) -> int:
	if minutes <= 0.0:
		return CRICKET_START_POPULATION
	var population := float(CRICKET_START_POPULATION)
	if minutes < CRICKET_FIRST_MILESTONE_MINUTES:
		var early_rate := float(CRICKET_HARVEST_POPULATION - CRICKET_START_POPULATION) / CRICKET_FIRST_MILESTONE_MINUTES
		population += early_rate * minutes
	elif minutes < CRICKET_SECOND_MILESTONE_MINUTES:
		var mid_rate := float(CRICKET_SECOND_MILESTONE_POPULATION - CRICKET_HARVEST_POPULATION) / (CRICKET_SECOND_MILESTONE_MINUTES - CRICKET_FIRST_MILESTONE_MINUTES)
		population = float(CRICKET_HARVEST_POPULATION) + mid_rate * (minutes - CRICKET_FIRST_MILESTONE_MINUTES)
	else:
		var late := minutes - CRICKET_SECOND_MILESTONE_MINUTES
		population = float(CRICKET_SECOND_MILESTONE_POPULATION) + float(CRICKET_CAPACITY - CRICKET_SECOND_MILESTONE_POPULATION) * (1.0 - exp(-CRICKET_LATE_GROWTH_RATE * late))
	return clampi(int(floor(population)), CRICKET_START_POPULATION, CRICKET_CAPACITY)


## The inverse, used when a scoop leaves more than the reserve behind: the colony
## keeps the growth it had earned and resumes from there.
static func _cricket_minutes_for_population(population: int) -> float:
	var target := clampi(population, CRICKET_START_POPULATION, CRICKET_CAPACITY)
	if target < CRICKET_HARVEST_POPULATION:
		var early_rate := float(CRICKET_HARVEST_POPULATION - CRICKET_START_POPULATION) / CRICKET_FIRST_MILESTONE_MINUTES
		return float(target - CRICKET_START_POPULATION) / early_rate
	if target < CRICKET_SECOND_MILESTONE_POPULATION:
		var mid_rate := float(CRICKET_SECOND_MILESTONE_POPULATION - CRICKET_HARVEST_POPULATION) / (CRICKET_SECOND_MILESTONE_MINUTES - CRICKET_FIRST_MILESTONE_MINUTES)
		return CRICKET_FIRST_MILESTONE_MINUTES + float(target - CRICKET_HARVEST_POPULATION) / mid_rate
	if target >= CRICKET_CAPACITY:
		return CRICKET_SECOND_MILESTONE_MINUTES + 3000.0
	var remaining := float(CRICKET_CAPACITY - target)
	var span := float(CRICKET_CAPACITY - CRICKET_SECOND_MILESTONE_POPULATION)
	return CRICKET_SECOND_MILESTONE_MINUTES + log(span / remaining) / CRICKET_LATE_GROWTH_RATE


## Harvest readiness is a population, not a bar: 27 is the first scoopable colony.
func tray_population(index: int) -> int:
	if index < 0 or index >= trays.size():
		return 0
	return int(trays[index].get("population", CRICKET_START_POPULATION))


func tray_harvestable(index: int) -> bool:
	if index < 0 or index >= trays.size():
		return false
	var tray: Dictionary = trays[index]
	if not bool(tray["active"]) or bool(tray["dead"]):
		return false
	if str(tray.get("species", "")) == "cricket":
		return tray_population(index) >= CRICKET_HARVEST_POPULATION
	return float(tray["progress"]) >= 1.0


## Minutes of real play until this colony can be netted, at today's temperature.
## Zero means it is scoopable now. This is what the tray text and the HUD quote.
func tray_minutes_to_harvest(index: int) -> float:
	if index < 0 or index >= trays.size():
		return 0.0
	var tray: Dictionary = trays[index]
	if not bool(tray["active"]) or bool(tray["dead"]) or str(tray.get("species", "")) != "cricket":
		return 0.0
	if tray_harvestable(index):
		return 0.0
	var remaining: float = maxf(0.0, CRICKET_FIRST_MILESTONE_MINUTES - float(tray.get("growth_minutes", 0.0)))
	if growth_multiplier() <= 0.0:
		return -1.0
	return remaining


## One line the tray prompt can show: population, capacity, feed and readiness.
func tray_status(index: int) -> String:
	if index < 0 or index >= trays.size():
		return ""
	var tray: Dictionary = trays[index]
	if not bool(tray["active"]):
		return "EMPTY FRAME — 6 live crickets found a colony"
	if bool(tray["dead"]):
		return "COLONY DEAD — 3 parts for a starter culture"
	if str(tray.get("species", "")) != "cricket":
		return "MAGGOT TRAY — %d%% grown" % int(float(tray["progress"]) * 100.0)
	var line := "%d / %d LIVE" % [tray_population(index), CRICKET_CAPACITY]
	line += " — FED" if bool(tray["fed"]) else " — HUNGRY, GROWTH PAUSED"
	if tray_harvestable(index):
		line += " — READY TO NET"
	else:
		var minutes := tray_minutes_to_harvest(index)
		if minutes < 0.0:
			line += " — TOO COLD TO GROW"
		else:
			line += " — %dS TO %d" % [int(minutes), CRICKET_HARVEST_POPULATION]
	return line


# C4 cold store. Three intact jars, each searchable once; the crate pays once.
# Parts and heat glands are the only rewards, so the room adds no currency.
const COLD_STORE_JAR_COUNT := 3
const COLD_STORE_CRATE_PARTS := 2
const COLD_STORE_CRATE_GLANDS := 1

func search_cold_store_jar(index: int) -> String:
	if index < 0 or index >= COLD_STORE_JAR_COUNT:
		return "No jar there."
	if cold_store_jars_searched.has(index):
		return "That jar is empty now."
	cold_store_jars_searched.append(index)
	parts += 1
	return "A jar of old stock. Parts, from the bottom of it."

func open_cold_store_crate() -> String:
	if cold_store_crate_opened:
		return "The crate is already open."
	cold_store_crate_opened = true
	parts += COLD_STORE_CRATE_PARTS
	heat_glands += COLD_STORE_CRATE_GLANDS
	return "The seal gives. Two parts and a heat gland, wrapped in cloth."

func install_cold_frame() -> String:
	if cold_frame_installed:
		return "The cold frame is already fitted."
	if patches <= 0:
		return "The cold frame needs an insulation patch to seal its pane."
	patches -= 1
	cold_frame_installed = true
	return "The pane is sealed. The frame will keep one cooked meal cold, and cold keeps it twice as long."


## One verb for the frame: fit it, put a meal in it, or eat what it kept.
func cold_frame_action() -> String:
	if not cold_frame_installed:
		return install_cold_frame()
	if cold_frame_meal:
		if hunger_hours > EAT_HUNGER_LIMIT:
			return "Not hungry yet. The frame will hold it."
		cold_frame_meal = false
		hunger_hours = MEAL_HUNGER_HOURS * 2.0
		starving = false
		return "Ate the meal kept in the cold frame. Cold food, but twice the value."
	if meals <= 0:
		return "Nothing cooked to keep. Bring a meal down from the kitchen."
	meals -= 1
	cold_frame_meal = true
	return "MEAL IN THE COLD FRAME // it will keep until you need it."

func active_tray_count() -> int:
	var count := 0
	for tray in trays:
		if bool(tray["active"]):
			count += 1
	return count

func feed_tray(index: int) -> String:
	if index < 0 or index >= trays.size():
		return "No tray there."
	var tray: Dictionary = trays[index]
	if not bool(tray["active"]):
		return "That shelf is empty. Build it up first."
	if bool(tray["dead"]):
		if parts >= 3:
			parts -= 3
			tray["dead"] = false
			tray["health"] = 0.5
			tray["progress"] = 0.0
			tray["population"] = CRICKET_START_POPULATION
			tray["growth_minutes"] = 0.0
			return "Starter culture added. The colony begins again."
		return "The colony is dead. A starter costs 3 parts."
	if feed < 1.0:
		return "No feed. Butcher something."
	feed = maxf(0.0, feed - 1.0)
	tray["fed"] = 1.0
	tray["health"] = minf(1.0, float(tray["health"]) + 0.08)
	return "Tray topped up. One feed unit used."

func harvest_tray(index: int) -> String:
	if index < 0 or index >= trays.size():
		return "No tray there."
	var tray: Dictionary = trays[index]
	if not bool(tray["active"]):
		return "That shelf is empty."
	if bool(tray["dead"]):
		return "Nothing left alive in that tray."
	var tier := 1
	if int(upgrades["throughput"]) >= 2:
		tier = 2
	if int(upgrades["throughput"]) >= 3:
		tier = 3
	# Crickets are taken alive; only the maggot trays still harvest as bulk mass.
	if str(tray["species"]) == "cricket":
		if not net_crafted:
			return "A net first — they have to be taken alive. Weave one at the workbench."
		var population := tray_population(index)
		if population < CRICKET_HARVEST_POPULATION:
			return "Not ready yet — %d of %d crickets. A tray can be netted at %d." % [population, CRICKET_CAPACITY, CRICKET_HARVEST_POPULATION]
		# C2.5 // the breeding reserve stays behind. A scoop can never take the
		# colony below six, and a full net stops the scoop instead of spilling.
		var room: int = maxi(0, NET_CAPACITY - live_crickets)
		if room <= 0:
			return "The net is full at %d live crickets. Dress or seed some first." % NET_CAPACITY
		var caught: int = mini(population - CRICKET_BREEDING_RESERVE, room)
		if caught <= 0:
			return "The colony is at its %d-cricket breeding reserve. Leave it to grow." % CRICKET_BREEDING_RESERVE
		live_crickets += caught
		tray["population"] = population - caught
		tray["growth_minutes"] = _cricket_minutes_for_population(int(tray["population"]))
		tray["progress"] = clampf(float(int(tray["population"]) - CRICKET_START_POPULATION) / float(CRICKET_HARVEST_POPULATION - CRICKET_START_POPULATION), 0.0, 1.0)
		tray["health"] = maxf(0.55, float(tray["health"]) - 0.15)
		return "Netted %d live crickets. %d carried, %d left to breed." % [caught, live_crickets, int(tray["population"])]
	if float(tray["progress"]) < 1.0:
		return "Not ready yet — %d%% grown." % int(float(tray["progress"]) * 100.0)
	mass += tier
	tray["progress"] = 0.0
	tray["health"] = maxf(0.55, float(tray["health"]) - 0.15)
	return "Harvested %d batch(es) of raw insect mass." % tier


## Founds a new colony from carried crickets. This is the farm's multiplication
## verb: a netted tray can either seed empty frames or feed the kitchen.
func seed_tray(index: int) -> String:
	if index < 0 or index >= trays.size():
		return "No tray there."
	var tray: Dictionary = trays[index]
	if bool(tray["active"]) and not bool(tray["dead"]):
		return "That colony is already established."
	if live_crickets < CRICKETS_TO_SEED:
		return "A new colony needs %d live crickets. You are carrying %d." % [CRICKETS_TO_SEED, live_crickets]
	live_crickets -= CRICKETS_TO_SEED
	tray["species"] = "cricket"
	tray["active"] = true
	tray["dead"] = false
	tray["population"] = CRICKET_START_POPULATION
	tray["growth_minutes"] = 0.0
	tray["progress"] = 0.0
	tray["health"] = 1.0
	tray["fed"] = 1.0
	return "Colony seeded. %d live crickets settled into the fresh frame." % CRICKETS_TO_SEED


# ------------------------------------------------------------------- kitchen

func dressed_hours() -> float:
	return DRESS_HOURS


func dress_crickets() -> String:
	if live_crickets < CRICKETS_TO_DRESS:
		return "Dressing takes %d live crickets. You are carrying %d." % [CRICKETS_TO_DRESS, live_crickets]
	live_crickets -= CRICKETS_TO_DRESS
	dressed_crickets += DRESSED_PER_BATCH
	advance_minutes(DRESS_HOURS * 60.0)
	return "Dressed %d crickets into %d portions." % [CRICKETS_TO_DRESS, DRESSED_PER_BATCH]


## How many whole batches the board can start right now, for the quantity
## stepper and for the refusal message when the answer is zero.
func kitchen_max(kind: String) -> int:
	var room: int = maxi(0, MAX_KITCHEN_JOBS - kitchen_jobs.size())
	var portions: int = int(dressed_crickets / DRESSED_PER_BATCH)
	if kind == "cook":
		if not furnace_lit:
			return 0
		portions = mini(portions, int(fuel / COOK_FUEL_COST))
	return mini(room, portions)


func kitchen_queue_hours(kind: String) -> float:
	return COOK_HOURS if kind == "cook" else CURE_HOURS


## The one path every kitchen button takes: pay the ingredients and the fuel up
## front so two clicks can never spend the same six crickets, then let the queue
## finish the work on the clock.
func queue_kitchen(kind: String, quantity: int) -> String:
	if kind != "cook" and kind != "cure":
		return "The board has no such job."
	if quantity <= 0:
		return "Choose how many batches first."
	if kitchen_jobs.size() >= MAX_KITCHEN_JOBS:
		return "The board is full — %d batches already waiting." % MAX_KITCHEN_JOBS
	var affordable := kitchen_max(kind)
	if affordable <= 0:
		if dressed_crickets < DRESSED_PER_BATCH:
			return "The pot needs %d dressed crickets." % DRESSED_PER_BATCH
		if kind == "cook" and not furnace_lit:
			return "The fire is out. A meal has to cook over a lit furnace."
		if kind == "cook" and fuel < COOK_FUEL_COST:
			return "Cooking needs one fuel under the pot."
		return "The board is full — %d batches already waiting." % MAX_KITCHEN_JOBS
	var count: int = mini(quantity, affordable)
	var grade := _batch_grade()
	var hours := kitchen_queue_hours(kind)
	for _i in count:
		dressed_crickets -= DRESSED_PER_BATCH
		if kind == "cook":
			fuel = maxf(0.0, fuel - COOK_FUEL_COST)
		kitchen_jobs.append({
			"kind": kind,
			# Hours, because the tick spends 1/60 h per game minute; the total is
			# kept in minutes for the progress readout.
			"hours_left": hours,
			"total_minutes": hours * 60.0,
			"grade": grade,
		})
	var verb := "Cooking" if kind == "cook" else "Curing"
	return "%s %d batch(es) — %d dressed left, %d waiting." % [verb, count, dressed_crickets, kitchen_jobs.size()]


func cook_meal() -> String:
	return queue_kitchen("cook", 1)


func cure_jerky() -> String:
	return queue_kitchen("cure", 1)


func _tick_kitchen() -> void:
	if kitchen_jobs.is_empty():
		return
	var job: Dictionary = kitchen_jobs[0]
	job["hours_left"] = float(job["hours_left"]) - 1.0 / 60.0
	# Subtracting 1/60 thirty times lands on a float epsilon, not a clean zero.
	if float(job["hours_left"]) > 0.0001:
		return
	kitchen_jobs.pop_front()
	ready_grade = str(job.get("grade", "B"))
	if str(job["kind"]) == "cook":
		ready_meals += MEALS_PER_BATCH
		report.append("THE POT // %d cricket meals ready at the board." % ready_meals)
	else:
		ready_jerky += JERKY_PER_BATCH
		report.append("THE RACK // %d strips of jerky ready at the board." % ready_jerky)


func kitchen_ready_total() -> int:
	return ready_meals + ready_jerky


## Finished batches wait on the board until they are picked up, so the queue can
## run while the player is elsewhere in the basement.
func collect_kitchen() -> String:
	if kitchen_ready_total() <= 0:
		return "Nothing is waiting on the board."
	var picked_meals := ready_meals
	var picked_jerky := ready_jerky
	if picked_meals > 0:
		meals += picked_meals
		meal_grade = ready_grade
	if picked_jerky > 0:
		jerky += picked_jerky
		jerky_grade = ready_grade
	ready_meals = 0
	ready_jerky = 0
	return "Collected %d meal(s) and %d jerky (grade %s)." % [picked_meals, picked_jerky, ready_grade]


func _batch_grade() -> String:
	# Quality upgrades and colony health still decide the grade, exactly as they
	# decided the old order grade.
	if trays.is_empty():
		return "C"
	return tray_grade(0)

func tray_grade(index: int) -> String:
	var health := float(trays[index]["health"])
	var floor_tier := int(upgrades["quality"])
	if floor_tier >= 3:
		return "A"
	if floor_tier >= 2:
		return "B"
	if health >= 0.9:
		return "A"
	if health >= 0.6:
		return "B"
	return "C"

# ---------------------------------------------------------------- packing

func pack(product: String, qty: int = 1) -> String:
	if qty <= 0:
		return "Nothing to pack."
	if product == "ration":
		if mass < qty:
			return "Need %d raw mass." % qty
		mass -= qty
		rations += qty
		_heat_recovery()
		return "Packed %d ration block(s)." % qty
	if product == "bait":
		if mass < qty:
			return "Need %d raw mass." % qty
		if chitin < qty:
			return "Bait needs %d chitin." % qty
		mass -= qty
		chitin -= qty
		bait += qty
		_heat_recovery()
		return "Packed %d bait tin(s)." % qty
	return "Unknown product."

func _heat_recovery() -> void:
	if upgrades["heat"] >= 3:
		fuel += 0.25

func eat(kind: String = "ration") -> String:
	# What is in the pack is answered before appetite, so an empty shelf never
	# reports "not hungry" and the refusal always names the missing food.
	match kind:
		"meal":
			if meals <= 0:
				return "No cricket meal left."
		"jerky":
			if jerky <= 0:
				return "No jerky in the pack."
		_:
			if rations <= 0:
				return "No rations. You would be eating the orders."
	if hunger_hours > EAT_HUNGER_LIMIT:
		return "Not hungry yet."
	match kind:
		"meal":
			meals -= 1
			hunger_hours = MEAL_HUNGER_HOURS
			starving = false
			return "Ate a hot cricket meal. That is one portion not sold."
		"jerky":
			jerky -= 1
			hunger_hours = JERKY_HUNGER_HOURS
			starving = false
			return "Chewed a strip of cricket jerky. It travels well."
	rations -= 1
	hunger_hours = RATION_HUNGER_HOURS
	starving = false
	return "Ate one ration block. That is one block not sold."

# ---------------------------------------------------------------- orders

func order_text() -> String:
	for order in orders:
		if bool(order.get("delivered", false)):
			continue
		return "%s%s: %d x %s (min %s) due %s" % [
			"CAVE " if order_is_cave(order) else "",
			str(order["buyer"]), int(order["qty"]), product_name(str(order["product"])),
			str(order["min_grade"]), _due_text(order),
		]
	return "No orders on the slate."

func product_name(product: String) -> String:
	match product:
		"ration": return "RATIONS"
		"bait": return "BAIT TINS"
		"hide": return "HIDES"
		"meal": return "CRICKET MEALS"
		"jerky": return "CRICKET JERKY"
	return product.to_upper()


## Where an order came from decides who answers it and when it dies: hatch papers
## are replaced at dawn, cave papers live on their own clock.
func order_source(order: Dictionary) -> String:
	return str(order.get("source", "hatch"))

func order_is_cave(order: Dictionary) -> bool:
	return order_source(order) == "cave"


## Papers carried out of the cave, still owed. The HUD needs exactly this list,
## so it lives here rather than being rebuilt by the scene every frame.
func cave_orders() -> Array:
	var papers: Array = []
	for order in orders:
		if order_is_cave(order) and not bool(order.get("delivered", false)):
			papers.append(order)
	return papers


## One compact line for the objective block: the first paper in full, and a count
## of the others so a stack of six does not become a wall of text.
func cave_slate_text() -> String:
	var papers := cave_orders()
	if papers.is_empty():
		return ""
	var first: Dictionary = papers[0]
	var text := "%d %s  DUE %s" % [int(first["qty"]), short_product_name(str(first["product"])), _due_text(first)]
	if papers.size() > 1:
		text += "  +%d" % (papers.size() - 1)
	return text


# ---------------------------------------------------------------- cave papers

## One paper per in-game day lands under the clamp while there is room for it.
## Nothing about the paper is announced: the player finds it by walking out.
func roll_cave_papers() -> void:
	if cave_papers_lying().size() >= CAVE_PAPER_CAP:
		return
	# One paper per day, however often the roll is asked for: a paper already
	# stamped with today's date means the buyer has been and gone.
	for existing in cave_papers:
		if int(existing.get("found_day", -1)) == day:
			return
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 104729 + int(abs_hour() * 7.0)
	var product := "meal"
	var roll := rng.randf()
	if roll > 0.90:
		product = ["ration", "bait", "hide"][rng.randi_range(0, 2)]
	elif roll > 0.60:
		product = "jerky"
	var qty := rng.randi_range(2, 4)
	var price := qty * 3 + rng.randi_range(4, 9)
	if product == "jerky":
		price = qty * 4 + rng.randi_range(5, 10)
	elif product != "meal":
		qty = rng.randi_range(3, 6) if product == "ration" else rng.randi_range(2, 4)
		price = rng.randi_range(3, 8) + qty
	if product == "hide":
		qty = rng.randi_range(1, 2)
		price = rng.randi_range(3, 8) + qty
	cave_papers.append({
		"id": "c%d_p%d" % [day, cave_papers.size()],
		"buyer": BUYERS[rng.randi_range(0, BUYERS.size() - 1)],
		"product": product,
		"qty": qty,
		"min_grade": "B" if standing < 50 else "A",
		"due_hour": abs_hour() + CAVE_ORDER_DUE_HOURS,
		"pay_parts": price,
		"pay_water": rng.randi_range(0, 2),
		"pay_standing": rng.randi_range(3, 6),
		"torn": false,
		"taken": false,
		"found_day": day,
	})


## Papers still under the clamp, newest last. Torn ones stay on the ground until
## somebody picks them up and reads how it ended.
func cave_papers_lying() -> Array:
	var lying: Array = []
	for paper in cave_papers:
		if not bool(paper.get("taken", false)):
			lying.append(paper)
	return lying

func top_cave_paper() -> Dictionary:
	var lying := cave_papers_lying()
	if lying.is_empty():
		return {}
	return lying[lying.size() - 1]

func cave_paper_count() -> int:
	return cave_papers_lying().size()

func cave_has_torn_paper() -> bool:
	for paper in cave_papers_lying():
		if bool(paper.get("torn", false)):
			return true
	return false


## Reading the clamp. A torn paper is removed and costs nothing more; a live one
## becomes a slate entry the packing bench can fill. The paper is not carried as
## a separate object — the entry in `orders` is what the player carries.
func take_cave_paper() -> String:
	var paper := top_cave_paper()
	if paper.is_empty():
		return "The clamp is empty. Nobody has left a paper since the last shift."
	cave_papers.erase(paper)
	if bool(paper.get("torn", false)):
		return "The paper is torn through. Whatever it wanted, nobody is coming back for it."
	orders.append({
		"id": str(paper["id"]),
		"buyer": str(paper["buyer"]),
		"product": str(paper["product"]),
		"qty": int(paper["qty"]),
		"min_grade": str(paper["min_grade"]),
		"due_hour": float(paper["due_hour"]),
		"pay_parts": int(paper["pay_parts"]),
		"pay_water": int(paper["pay_water"]),
		"pay_standing": int(paper["pay_standing"]),
		"delivered": false,
		"special": false,
		"source": "cave",
	})
	var water_text := ""
	if int(paper["pay_water"]) > 0:
		water_text = " + %d water" % int(paper["pay_water"])
	return "PAPER // %d %s for %s. Due %s. %d parts%s, if it is good enough." % [
		int(paper["qty"]), short_product_name(str(paper["product"])), str(paper["buyer"]),
		_due_text({"due_hour": float(paper["due_hour"])}), int(paper["pay_parts"]), water_text,
	]


## An unfilled cave order tears itself at due + 2 h: the order leaves the slate,
## standing drops, and the paper is back under the clamp to be read.
func _expire_cave_orders() -> void:
	var now := abs_hour()
	var kept: Array = []
	for order in orders:
		if order_is_cave(order) and not bool(order.get("delivered", false)) and now > float(order["due_hour"]) + CAVE_ORDER_GRACE_HOURS:
			standing = maxi(0, standing - 2)
			report.append("CAVE PAPER EXPIRED // %s wanted %d %s. -2 standing." % [
				str(order["buyer"]), int(order["qty"]), short_product_name(str(order["product"])),
			])
			if cave_papers_lying().size() < CAVE_PAPER_CAP:
				var torn: Dictionary = order.duplicate(true)
				torn["taken"] = false
				torn["torn"] = true
				torn.erase("delivered")
				cave_papers.append(torn)
			continue
		kept.append(order)
	orders = kept


## The bench wraps for the cave before the hatch: a cave paper's clock is 14 h
## rather than 20, and its box leaves through the drop instead of the shutter.
func next_cave_order() -> Dictionary:
	var papers := cave_orders()
	if papers.is_empty():
		return {}
	return papers[0]

func cave_box_packed() -> bool:
	return not packed_box.is_empty() and str(packed_box.get("source", "hatch")) == "cave"

func cave_payout_ready() -> bool:
	if cave_payout.is_empty():
		return false
	return abs_hour() >= float(cave_payout.get("ready_hour", 0.0))


## The deposit. Settlement is decided here — grade and deadline — but the money
## is left in the clamp and only collectable on a later visit.
func drop_cave_box() -> String:
	if not cave_payout.is_empty() and not cave_payout_ready():
		return "A box is already in the clamp. Whoever empties it has not come yet."
	if packed_box.is_empty():
		return "The clamp is open and empty. Nothing to leave."
	if not cave_box_packed():
		return "That box is bound for the hatch, not the clamp."
	var box: Dictionary = packed_box.duplicate(true)
	packed_box.clear()
	var order: Dictionary = {}
	for candidate in orders:
		if str(candidate["id"]) == str(box.get("order_id", "")):
			order = candidate
			break
	if order.is_empty():
		cave_drop = box
		cave_drop["ready_hour"] = abs_hour() + CAVE_PAYOUT_DELAY_HOURS
		cave_payout = {"parts": 2, "water": 0, "standing": 0, "ready_hour": abs_hour() + CAVE_PAYOUT_DELAY_HOURS}
		return "The box goes in without a word. A surplus is still a surplus: 2 parts in the clamp next visit."
	var under_grade := grade_rank(str(box.get("grade", "C"))) < grade_rank(str(order["min_grade"])) and str(order["product"]) != "hide"
	var payout_parts := int(order["pay_parts"])
	var payout_water := int(order["pay_water"])
	var payout_standing := int(order["pay_standing"])
	if under_grade:
		payout_parts = int(order["pay_parts"]) / 2
		payout_water = 0
		payout_standing = -2
		standing = maxi(0, standing - 2)
		order["delivered"] = true
		report.append("UNDER GRADE AT THE DROP // %s paid half. -2 standing." % str(order["buyer"]))
	else:
		order["delivered"] = true
	cave_drop = box.duplicate(true)
	cave_drop["ready_hour"] = abs_hour() + CAVE_PAYOUT_DELAY_HOURS
	cave_drop["buyer"] = str(order["buyer"])
	cave_payout = {
		"parts": payout_parts,
		"water": payout_water,
		"standing": payout_standing,
		"ready_hour": abs_hour() + CAVE_PAYOUT_DELAY_HOURS,
	}
	var money := "%d parts" % payout_parts
	if payout_water > 0:
		money += " and %d water" % payout_water
	return "The box goes into the clamp. %s left %s, next time somebody walks out this way." % [str(order["buyer"]), money]


## Payment waits at least an hour, so the drop is not a shop counter: the player
## has to come back for it.
func collect_cave_payout() -> String:
	if cave_payout.is_empty():
		return "There is nothing in the clamp."
	if not cave_payout_ready():
		return "The clamp is shut. Nobody has been out here since the box went in."
	var payout := cave_payout
	var buyer := str(cave_drop.get("buyer", "THE BUYER"))
	parts += int(payout.get("parts", 0))
	water += int(payout.get("water", 0))
	standing = clampi(standing + int(payout.get("standing", 0)), 0, 100)
	cave_drop.clear()
	cave_payout.clear()
	var text := "COLLECTED // %d parts" % int(payout.get("parts", 0))
	if int(payout.get("water", 0)) > 0:
		text += " and %d water" % int(payout.get("water", 0))
	if int(payout.get("standing", 0)) > 0:
		text += ", standing +%d" % int(payout.get("standing", 0))
	return text + ". %s does not wait twice." % buyer


func short_product_name(product: String) -> String:
	match product:
		"ration": return "RATIONS"
		"bait": return "BAIT"
		"hide": return "HIDES"
		"meal": return "MEALS"
		"jerky": return "JERKY"
	return product.to_upper()

func _due_text(order: Dictionary) -> String:
	var due := float(order["due_hour"])
	var day_index := int(floor(due / 24.0)) + 1
	var hour := fmod(due, 24.0)
	return "DAY %d %02d:00" % [day_index, int(hour)]

func next_order() -> Dictionary:
	for order in orders:
		if not bool(order.get("delivered", false)):
			return order
	return {}

func pack_for_order(order_id := "") -> String:
	var order: Dictionary = {}
	if not order_id.is_empty():
		# Naming a paper that is still under the clamp is the refusal the spec
		# asks for: the order does not exist until it has been read and carried.
		for paper in cave_papers_lying():
			if str(paper["id"]) == order_id:
				return "That paper is still under the clamp. Read it at the drop before packing for it."
		for candidate in orders:
			if str(candidate["id"]) == order_id:
				order = candidate
				break
		if order.is_empty():
			return "That order is no longer on the slate."
	else:
		# The cave paper wins the bench when both channels are open: its clock is
		# six hours tighter and the box has much further to go.
		order = next_cave_order()
		if order.is_empty():
			order = next_order()
	if order.is_empty():
		return "No order to pack for."
	if bool(order.get("delivered", false)):
		return "That order is already filled."
	if not packed_box.is_empty():
		return "A box is already packed. Deliver it before packing another."
	var product := str(order["product"])
	var qty := int(order["qty"])
	var destination := "the drop in the pocket" if order_is_cave(order) else "the shutter"
	if product == "hide":
		if hides < qty:
			return "Need %d hide(s) on the rack." % qty
		hides -= qty
		packed_box = {
			"product": "hide",
			"qty": qty,
			"grade": "A",
			"order_id": str(order["id"]),
			"hour_left": abs_hour(),
			"due": float(order["due_hour"]),
			"source": order_source(order),
		}
		return "Box packed for %s. It goes to %s." % [str(order["buyer"]), destination]
	if product == "ration":
		if rations < qty:
			return "Need %d packed rations (you have %d)." % [qty, rations]
		rations -= qty
	elif product == "bait":
		if bait < qty:
			return "Need %d bait tins (you have %d)." % [qty, bait]
		bait -= qty
	elif product == "meal":
		if meals < qty:
			return "Need %d cricket meals (you have %d)." % [qty, meals]
		meals -= qty
	elif product == "jerky":
		if jerky < qty:
			return "Need %d cricket jerky (you have %d)." % [qty, jerky]
		jerky -= qty
	packed_box = {
		"product": product,
		"qty": qty,
		"grade": _box_grade(product),
		"order_id": str(order["id"]),
		"hour_left": abs_hour(),
		"due": float(order["due_hour"]),
		"source": order_source(order),
	}
	return "Box packed for %s. It goes to %s." % [str(order["buyer"]), destination]

## Grades are letters, so text comparison is wrong ("A" < "B"). Rank them.
func grade_rank(grade: String) -> int:
	match grade:
		"A": return 3
		"B": return 2
		"C": return 1
	return 0

func _box_grade(product: String) -> String:
	# Cooked and cured goods carry the grade they were made at; everything else is
	# still graded by the tray that produced it.
	if product == "meal":
		return meal_grade
	if product == "jerky":
		return jerky_grade
	return tray_grade(0)

func leave_box() -> String:
	if packed_box.is_empty():
		return "Nothing packed. Use the bench first."
	if cave_box_packed():
		return "That box is bound for the drop in the pocket. The hatch has no claim on it."
	delivered_box = packed_box.duplicate(true)
	packed_box.clear()
	return "Box left in the shutter. Payment comes at dawn."

func _dawn() -> void:
	_deliver_settlement()
	# Dawn replaces the hatch slate. A paper carried out of the cave is not the
	# hatch's to clear: it runs to its own due hour and expires there.
	var carried_cave: Array = []
	for order in orders:
		if order_is_cave(order) and not bool(order.get("delivered", false)):
			carried_cave.append(order)
	orders = carried_cave
	var rng := RandomNumberGenerator.new()
	rng.seed = day * 7919 + int(abs_hour())
	var count := 1
	if standing >= 25 and rng.randf() < 0.6:
		count = 2
	# A fresh paper is under the clamp before the hatch slate is read.
	roll_cave_papers()
	for index in count:
		var product := "ration"
		var roll := rng.randf()
		if roll > 0.78:
			product = "hide"
		elif roll > 0.58 and standing >= 20:
			product = "bait"
		var min_grade := "B" if standing < 50 else "A"
		var qty := 3
		if product == "ration":
			qty = rng.randi_range(3, 6)
		elif product == "bait":
			qty = rng.randi_range(2, 4)
		else:
			qty = rng.randi_range(1, 2)
		orders.append({
			"id": "d%d_o%d" % [day, index],
			"buyer": BUYERS[rng.randi_range(0, BUYERS.size() - 1)],
			"product": product,
			"qty": qty,
			"min_grade": min_grade,
			"due_hour": abs_hour() + 20.0,
			"pay_parts": rng.randi_range(3, 8) + qty,
			"pay_water": rng.randi_range(0, 2),
			"pay_standing": rng.randi_range(3, 6),
			"delivered": false,
			"special": false,
		})
	report.append("DAWN // %d order(s) on the slate. Read the slate by the stairs." % orders.size())

func _deliver_settlement() -> void:
	if delivered_box.is_empty():
		return
	var box := delivered_box
	delivered_box = {}
	if abs_hour() > float(box.get("due", 0.0)) + 2.0:
		var chance := 0.05
		if standing < 25:
			chance = 0.4
		elif standing < 50:
			chance = 0.2
		var rng := RandomNumberGenerator.new()
		rng.seed = int(abs_hour() * 31.0) + int(box.get("qty", 1))
		if rng.randf() < chance:
			standing = maxi(0, standing - 3)
			report.append("THE BOX IS GONE // taken from the shutter. No payment, -3 standing.")
			return
	var order := {}
	for candidate in orders:
		if str(candidate["id"]) == str(box.get("order_id", "")):
			order = candidate
			break
	if order.is_empty():
		parts += 2
		report.append("SURPLUS SOLD // 2 parts left in the shutter.")
		return
	var paid := parts
	if grade_rank(str(box.get("grade", "C"))) < grade_rank(str(order["min_grade"])) and str(order["product"]) != "hide":
		parts += int(order["pay_parts"]) / 2
		standing = maxi(0, standing - 2)
		report.append("UNDER GRADE // %s paid half. -2 standing." % str(order["buyer"]))
	else:
		parts += int(order["pay_parts"])
		water += int(order["pay_water"])
		standing = clampi(standing + int(order["pay_standing"]), 0, 100)
		order["delivered"] = true
		report.append("PAID // %s left %d parts%s." % [
			str(order["buyer"]), int(order["pay_parts"]),
			" and %d water" % int(order["pay_water"]) if int(order["pay_water"]) > 0 else "",
		])
	if str(box.get("product", "")) == "bait":
		traffic += int(box.get("qty", 1))

# ---------------------------------------------------------------- upgrades & survival

func upgrade_cost(axis: String) -> int:
	var tier := int(upgrades.get(axis, 0))
	if tier >= UPGRADE_COSTS.size():
		return 9999
	return int(UPGRADE_COSTS[tier])

func can_upgrade(axis: String) -> bool:
	return upgrades.has(axis) and int(upgrades[axis]) < UPGRADE_COSTS.size() and parts >= upgrade_cost(axis)

func buy_upgrade(axis: String) -> String:
	if not AXES.has(axis):
		return "Unknown upgrade."
	if int(upgrades[axis]) >= UPGRADE_COSTS.size():
		return "%s is already at maximum." % str(AXIS_NAMES[axis])
	var cost := upgrade_cost(axis)
	if parts < cost:
		return "%s needs %d parts." % [str(AXIS_NAMES[axis]), cost]
	parts -= cost
	upgrades[axis] = int(upgrades[axis]) + 1
	if axis == "throughput" and int(upgrades["throughput"]) == 1:
		for index in range(START_TRAYS, TRAY_SLOTS):
			trays[index]["active"] = true
	return "%s upgraded to tier %d." % [str(AXIS_NAMES[axis]), int(upgrades[axis])]

func patch_gap(index: int) -> String:
	if index < 0 or index >= gaps.size():
		return "Nothing to patch."
	if bool(gaps[index]["sealed"]):
		return "That gap is already sealed."
	if patches <= 0:
		return "Need an insulation patch. Make one at the workbench (2 parts + 1 hide)."
	patches -= 1
	gaps[index]["sealed"] = true
	return "Insulation patch installed. Cold air stops moving."

func gap_label(index: int) -> String:
	match index:
		0: return "NORTH-EAST GAP"
		1: return "WEST WALL GAP"
		2: return "NORTH GAP"
		3: return "STAR WELL GAP"
	return "GAP"

func open_gap_count() -> int:
	var count := 0
	for gap in gaps:
		if not bool(gap["sealed"]):
			count += 1
	return count

# -------------------------------------------------------------- workbench

func workbench_recipe_ids() -> Array:
	return WORKBENCH_RECIPE_ORDER.duplicate()

func workbench_recipe(recipe_id: String) -> Dictionary:
	var recipe: Dictionary = WORKBENCH_RECIPES.get(recipe_id, {})
	return recipe.duplicate(true)

func workbench_recipe_label(recipe_id: String) -> String:
	var recipe: Dictionary = workbench_recipe(recipe_id)
	return str(recipe.get("label", "UNKNOWN RECIPE"))

func workbench_recipe_description(recipe_id: String) -> String:
	var recipe: Dictionary = workbench_recipe(recipe_id)
	return str(recipe.get("description", "No notes for this recipe."))

func workbench_recipe_cost_text(recipe_id: String) -> String:
	var recipe: Dictionary = workbench_recipe(recipe_id)
	var costs: Dictionary = recipe.get("cost", {})
	return _resource_bundle_text(costs)

func workbench_recipe_output_text(recipe_id: String) -> String:
	var recipe: Dictionary = workbench_recipe(recipe_id)
	var output_text: String = str(recipe.get("output_text", ""))
	if not output_text.is_empty():
		return output_text
	var output: Dictionary = recipe.get("output", {})
	return _resource_bundle_text(output)

func can_craft_at_workbench(recipe_id: String) -> bool:
	var recipe: Dictionary = workbench_recipe(recipe_id)
	if recipe.is_empty():
		return false
	if recipe_id == "antidote" and antidotes > 0:
		return false
	if str(recipe.get("effect", "")) == "repair_driver" and driver_durability >= DRIVER_MAX_DURABILITY:
		return false
	if str(recipe.get("effect", "")) == "install_storage_rack" and storage_rack_installed:
		return false
	if str(recipe.get("effect", "")) == "install_heat_reclaimer" and heat_reclaimer_installed:
		return false
	var costs: Dictionary = recipe.get("cost", {})
	for resource_key in costs.keys():
		var resource: String = str(resource_key)
		var required: int = int(costs.get(resource_key, 0))
		if _resource_amount(resource) < required:
			return false
	return true

func craft_at_workbench(recipe_id: String) -> String:
	var recipe: Dictionary = workbench_recipe(recipe_id)
	if recipe.is_empty():
		return "That pattern is not pinned to this bench."
	# Ammunition needs a body to learn from. Until the first kill, the bench has
	# no bolt pattern at all, no matter what salvage is on the shelf.
	if recipe_id in ["basic_bolts", "broadhead_bolts", "tether_bolt"] and kills < 1:
		return "No ammunition pattern yet. Kill something and study the body first."
	if recipe_id == "antidote" and antidotes > 0:
		return "You already have an antidote. Drink it before brewing another."
	var effect: String = str(recipe.get("effect", ""))
	if effect == "craft_net" and net_crafted:
		return "You already have a net. It is holding together."
	if effect == "craft_lantern" and lantern_crafted:
		return "You already carry a lantern. Its cage is sound."
	if effect == "repair_driver" and driver_durability >= DRIVER_MAX_DURABILITY:
		return "The bolt driver is already holding full pressure."
	if effect == "install_storage_rack" and storage_rack_installed:
		return "The warm storage rack is already running beside the rations."
	if effect == "install_heat_reclaimer" and heat_reclaimer_installed:
		return "The C-4 heat reclaimer is already holding pressure beside the furnace."
	var costs: Dictionary = recipe.get("cost", {})
	for resource_key in costs.keys():
		var resource: String = str(resource_key)
		var required: int = int(costs.get(resource_key, 0))
		if _resource_amount(resource) < required:
			return "Need %s." % _resource_bundle_text(costs)
	for resource_key in costs.keys():
		var spent_resource: String = str(resource_key)
		_add_resource(spent_resource, -int(costs.get(resource_key, 0)))
	var output: Dictionary = recipe.get("output", {})
	for resource_key in output.keys():
		var made_resource: String = str(resource_key)
		_add_resource(made_resource, int(output.get(resource_key, 0)))
	if effect == "repair_driver":
		driver_durability = DRIVER_MAX_DURABILITY
		return "BOLT DRIVER REBUILT // pressure %d/%d." % [driver_durability, DRIVER_MAX_DURABILITY]
	if effect == "install_storage_rack":
		storage_rack_installed = true
		return "WARM STORAGE RACK INSTALLED // the heat lamp gives the stores a safe warm circle."
	if effect == "install_heat_reclaimer":
		heat_reclaimer_installed = true
		return "C-4 HEAT RECLAIMER INSTALLED // furnace fuel now holds longer and the room warms faster."
	if effect == "craft_net":
		net_crafted = true
		return "CRICKET NET // a mature tray can now be taken alive, and a colony founded."
	if effect == "craft_lantern":
		lantern_crafted = true
		return "GLAND LANTERN // six metres of warm light, fed from the fuel store."
	return "%s crafted: %s." % [workbench_recipe_label(recipe_id), _resource_bundle_text(output)]

func ammo_count(ammo_type: String = selected_bolt_type) -> int:
	match ammo_type:
		"standard": return bolts
		"broadhead": return broadhead_bolts
		"tether": return tether_bolts
	return 0

func selected_ammo_label() -> String:
	return str(BOLT_TYPE_NAMES.get(selected_bolt_type, "SALVAGE"))

func cycle_bolt_type() -> String:
	var current_index: int = BOLT_TYPE_ORDER.find(selected_bolt_type)
	if current_index < 0:
		current_index = 0
	selected_bolt_type = str(BOLT_TYPE_ORDER[(current_index + 1) % BOLT_TYPE_ORDER.size()])
	return selected_ammo_label()

func consume_selected_ammo() -> bool:
	if ammo_count() <= 0:
		return false
	match selected_bolt_type:
		"standard": bolts -= 1
		"broadhead": broadhead_bolts -= 1
		"tether": tether_bolts -= 1
		_: return false
	return true

func wear_driver(amount: int = 1) -> void:
	driver_durability = maxi(0, driver_durability - maxi(0, amount))

func arm_snare() -> String:
	if snare_armed:
		return "The floor snare is already armed at the bait mark."
	# The ember trap goes in first when there is one: it is the better snare.
	if ember_snares > 0:
		ember_snares -= 1
		snare_kind = "ember"
		snare_armed = true
		return "Ember snare armed. The chitin wire survives its first trigger."
	if snares <= 0:
		return "Need a floor snare. Build one at the salvage workbench."
	snares -= 1
	snare_kind = "plain"
	snare_armed = true
	return "Floor snare armed. Keep the bulkhead sealed until something takes the bait."

func disarm_snare() -> String:
	# A sprung snare is gone; a set one can be folded back into the pack.
	if not snare_armed:
		return "The floor snare is already clear."
	if snare_kind == "ember":
		ember_snares += 1
	else:
		snares += 1
	snare_armed = false
	snare_kind = ""
	return "Floor snare disarmed and folded back into the pack."

func trigger_snare() -> void:
	snare_armed = false
	if snare_kind == "ember":
		# One trigger is what the ember chitin buys: the wire holds, then comes
		# back as an ordinary snare instead of being spent.
		snares += 1
		report.append("EMBER SNARE // the wire held and came back folded. One plain snare recovered.")
	snare_kind = ""

## The lantern is lit by the same economy as the fire: one unit of fuel for ten
## in-game minutes of warm light. It never lights without fuel in the store.
func toggle_lantern() -> String:
	if not lantern_crafted:
		return "No lantern. A heat gland and a workbench make one."
	if lantern_on:
		lantern_on = false
		return "Lantern shuttered. The pocket goes back to its failing strips."
	if fuel < 1.0:
		return "The lantern is dry. No fuel in the store to burn."
	fuel -= 1.0
	lantern_fuel_seconds = LANTERN_FUEL_SECONDS
	lantern_on = true
	return "LANTERN LIT // warm light for ten in-game minutes."


func tick_lantern(minutes: float) -> void:
	# `minutes` are in-game minutes, the same unit advance_minutes() counts in
	# (the scene feeds it one real second per in-game minute).
	if not lantern_on:
		return
	lantern_fuel_seconds = maxf(0.0, lantern_fuel_seconds - minutes * 60.0)
	if lantern_fuel_seconds > 0.0:
		return
	if fuel < 1.0:
		lantern_on = false
		lantern_fuel_seconds = 0.0
		report.append("THE LANTERN GUTTERS // the fuel store is empty.")
		return
	fuel -= 1.0
	lantern_fuel_seconds += LANTERN_FUEL_SECONDS


func lantern_minutes_left() -> float:
	return lantern_fuel_seconds / 60.0


func _resource_amount(resource: String) -> int:
	if resource == "ember_chitin":
		return ember_chitin
	if resource == "heat_glands":
		return heat_glands
	if resource == "ember_snares":
		return ember_snares
	match resource:
		"parts": return parts
		"chitin": return chitin
		"water": return water
		"hides": return hides
		"bolts": return bolts
		"broadhead_bolts": return broadhead_bolts
		"tether_bolts": return tether_bolts
		"snares": return snares
		"antidotes": return antidotes
		"patches": return patches
		"thermal_regulators": return thermal_regulators
		"chain_links": return chain_links
	return 0

func _add_resource(resource: String, amount: int) -> void:
	match resource:
		"parts": parts = maxi(0, parts + amount)
		"chitin": chitin = maxi(0, chitin + amount)
		"water": water = maxi(0, water + amount)
		"hides": hides = maxi(0, hides + amount)
		"bolts": bolts = maxi(0, bolts + amount)
		"broadhead_bolts": broadhead_bolts = maxi(0, broadhead_bolts + amount)
		"tether_bolts": tether_bolts = maxi(0, tether_bolts + amount)
		"snares": snares = maxi(0, snares + amount)
		"ember_snares": ember_snares = maxi(0, ember_snares + amount)
		"ember_chitin": ember_chitin = maxi(0, ember_chitin + amount)
		"heat_glands": heat_glands = maxi(0, heat_glands + amount)
		"antidotes": antidotes = maxi(0, antidotes + amount)
		"patches": patches = maxi(0, patches + amount)
		"thermal_regulators": thermal_regulators = maxi(0, thermal_regulators + amount)
		"chain_links": chain_links = maxi(0, chain_links + amount)

func _resource_bundle_text(bundle: Dictionary) -> String:
	var result := ""
	for resource in ["parts", "chitin", "water", "hides", "bolts", "broadhead_bolts", "tether_bolts", "snares", "ember_snares", "ember_chitin", "heat_glands", "antidotes", "patches", "thermal_regulators", "chain_links"]:
		if not bundle.has(resource):
			continue
		var count: int = int(bundle.get(resource, 0))
		if count <= 0:
			continue
		if not result.is_empty():
			result += " + "
		result += "%d %s" % [count, _resource_name(resource, count)]
	return result if not result.is_empty() else "nothing"

func _resource_name(resource: String, count: int) -> String:
	match resource:
		"parts": return "part" if count == 1 else "parts"
		"chitin": return "chitin"
		"water": return "water"
		"hides": return "hide" if count == 1 else "hides"
		"bolts": return "bolt" if count == 1 else "bolts"
		"broadhead_bolts": return "broadhead bolt" if count == 1 else "broadhead bolts"
		"tether_bolts": return "tether bolt" if count == 1 else "tether bolts"
		"snares": return "floor snare" if count == 1 else "floor snares"
		"ember_snares": return "ember snare"
		"ember_chitin": return "ember chitin"
		"heat_glands": return "heat gland" if count == 1 else "heat glands"
		"antidotes": return "antidote" if count == 1 else "antidotes"
		"patches": return "insulation patch" if count == 1 else "insulation patches"
		"thermal_regulators": return "thermal regulator" if count == 1 else "thermal regulators"
		"chain_links": return "chain link" if count == 1 else "chain links"
	return resource

func brew() -> String:
	# Kept as a thin compatibility wrapper for the old keyboard action and saves.
	# All actual resource changes now flow through the workbench recipe registry.
	return craft_at_workbench("antidote")

func drink() -> String:
	if venom_seconds <= 0.0:
		return "Nothing to cure."
	if antidotes <= 0:
		return "No antidote. Craft one at the workbench (1 chitin + 1 water)."
	antidotes -= 1
	venom_seconds = 0.0
	return "The antidote burns going down. Hands steady."

func sleep() -> String:
	var target := 6.0
	var hours := 0.0
	if clock < target:
		hours = target - clock
	else:
		hours = (24.0 - clock) + target
	var before_parts := parts
	advance_minutes(hours * 60.0)
	var summary := "SLEPT %d HOURS // %d parts, %d water, standing %d" % [int(hours), parts - before_parts, water, standing]
	report.append(summary)
	return summary

func night_breach_count(rng_seed: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed + day * 131
	var chance := 0.25 + float(open_gap_count()) * 0.10 + float(traffic) * 0.02
	var count := 0
	if rng.randf() < chance:
		count += 1
	if rng.randf() < chance * 0.4:
		count += 1
	return count

func seconds_until_dark() -> float:
	var hours := 20.0 - clock
	if hours < 0.0:
		hours += 24.0
	return hours * 60.0

# -------------------------------------------------------- physical mission items

func drop_chain_link(point: Vector3) -> Dictionary:
	if chain_links <= 0 or not point.is_finite():
		return {}
	var item := {"id": next_world_item_id, "item": "chain_link",
		"position": [point.x, point.y, point.z]}
	next_world_item_id += 1
	chain_links -= 1
	world_items.append(item)
	return item.duplicate(true)


func pick_up_world_item(item_id: int) -> bool:
	for index in world_items.size():
		var item: Dictionary = world_items[index]
		if int(item.get("id", -1)) == item_id and str(item.get("item", "")) == "chain_link":
			world_items.remove_at(index)
			chain_links += 1
			return true
	return false


func fit_shutter_chain() -> bool:
	# Validate before spending. Animation cancellation never changes this state.
	if chain_links <= 0 or not story.chain_broken or story.stage != StoryState.STAGE_CHAIN_SNAPPED:
		return false
	story.links += 1
	if not story.fit_link():
		story.links -= 1
		return false
	chain_links -= 1
	story.advance_to(StoryState.STAGE_ROOM_REOPENED)
	return true


func _restore_world_items(data: Dictionary) -> void:
	world_items.clear()
	next_world_item_id = maxi(1, int(data.get("next_world_item_id", 1)))
	var seen: Dictionary = {}
	var entries: Variant = data.get("world_items", [])
	if not entries is Array:
		return
	for entry in entries:
		if not entry is Dictionary or str(entry.get("item", "")) != "chain_link":
			continue
		var item_id := int(entry.get("id", 0))
		var coords: Variant = entry.get("position", [])
		if item_id <= 0 or seen.has(item_id) or not coords is Array or coords.size() != 3:
			continue
		var valid := true
		for value in coords:
			if (not value is float and not value is int) or not is_finite(float(value)):
				valid = false
		if not valid:
			continue
		world_items.append({"id": item_id, "item": "chain_link", "position": coords.duplicate()})
		seen[item_id] = true
		next_world_item_id = maxi(next_world_item_id, item_id + 1)


# ---------------------------------------------------------------- carcasses

func carry_remains(quality: String, variant: String = "") -> void:
	carried_remains.append({"quality": quality, "variant": variant})

## Butchers every carried body exactly once and reports what was actually gained.
func butcher_carried() -> String:
	if carried_remains.is_empty():
		return "Nothing to butcher. Kill something and carry it here."
	var before := [feed, fuel, chitin, hides, ember_chitin, heat_glands]
	var count := carried_remains.size()
	for body in carried_remains.duplicate():
		butcher(str(body["quality"]), str(body["variant"]))
	carried_remains.clear()
	var note := "Butchered %d: +%d feed, +%d fuel, +%d chitin, +%d hide(s)" % [
		count,
		int(round(feed - float(before[0]))),
		int(round(fuel - float(before[1]))),
		chitin - int(before[2]),
		hides - int(before[3]),
	]
	if ember_chitin > int(before[4]):
		note += ", +%d ember chitin" % (ember_chitin - int(before[4]))
	if heat_glands > int(before[5]):
		note += ", +%d heat gland" % (heat_glands - int(before[5]))
	return note + "."

func butcher(quality: String, variant: String = "") -> String:
	kills += 1
	feed += 4.0
	fuel += 4.0
	chitin += 2
	hides += 1
	var note := "Butchered: +4 feed, +4 fuel, +2 chitin, +1 hide (%s)." % quality
	if quality == "A":
		note += " The skin is clean."
	elif quality == "C":
		note += " The skin is ruined by bolt holes."
	if variant == "cinder":
		# The pocket's body carries what the base slime never does: a heat gland
		# worth a lantern, and ember chitin worth a snare that survives itself.
		ember_chitin += 1
		note += " +1 ember chitin"
		if randf() < gland_chance:
			heat_glands += 1
			note += ", +1 heat gland"
	return note

# ---------------------------------------------------------------- save / load

func to_save() -> Dictionary:
	var saved := {
		"scrap_metal": scrap_metal, "wiring": wiring, "batteries": batteries,
		"rail_stage2_kit": rail_stage2_kit, "rail_stage3_kit": rail_stage3_kit,
		"version": SAVE_VERSION,
		"clock": clock,
		"day": day,
		"temperature": temperature,
		"fuel": fuel,
		"feed": feed,
		"mass": mass,
		"rations": rations,
		"bait": bait,
		"hides": hides,
		"chitin": chitin,
		"parts": parts,
		"water": water,
		"coal": coal,
		"medicine": medicine,
		"antidotes": antidotes,
		"bolts": bolts,
		"broadhead_bolts": broadhead_bolts,
		"tether_bolts": tether_bolts,
		"snares": snares,
		"patches": patches,
		"live_crickets": live_crickets,
		"dressed_crickets": dressed_crickets,
		"meals": meals,
		"jerky": jerky,
		"meal_grade": meal_grade,
		"jerky_grade": jerky_grade,
		"kitchen_jobs": kitchen_jobs.duplicate(true),
		"ready_meals": ready_meals,
		"ready_jerky": ready_jerky,
		"ready_grade": ready_grade,
		"net_crafted": net_crafted,
		"ember_chitin": ember_chitin,
		"heat_glands": heat_glands,
		"ember_snares": ember_snares,
		"lantern_crafted": lantern_crafted,
		"lantern_on": lantern_on,
		"lantern_fuel_seconds": lantern_fuel_seconds,
		"cave_papers": cave_papers.duplicate(true),
		"cave_drop": cave_drop.duplicate(true),
		"cave_payout": cave_payout.duplicate(true),
		"driver_durability": driver_durability,
		"selected_bolt_type": selected_bolt_type,
		"snare_armed": snare_armed,
		"storage_rack_installed": storage_rack_installed,
		"thermal_regulators": thermal_regulators,
		"chain_links": chain_links,
		"heat_reclaimer_installed": heat_reclaimer_installed,
		"cold_store_jars_searched": cold_store_jars_searched.duplicate(),
		"cold_store_crate_opened": cold_store_crate_opened,
		"cold_frame_installed": cold_frame_installed,
		"cold_frame_meal": cold_frame_meal,
		"standing": standing,
		"traffic": traffic,
		"hunger_hours": hunger_hours,
		"venom_seconds": venom_seconds,
		"furnace_lit": furnace_lit,
		"bedside_kit_opened": bedside_kit_opened,
		"trays": trays.duplicate(true),
		"orders": orders.duplicate(true),
		"delivered_box": delivered_box.duplicate(true),
		"packed_box": packed_box.duplicate(true),
		"carried_remains": carried_remains.duplicate(true),
		"world_items": world_items.duplicate(true),
		"next_world_item_id": next_world_item_id,
		"gaps": gaps.duplicate(true),
		"upgrades": upgrades.duplicate(true),
		"kills": kills,
		"story": story.to_save(),
	}
	saved.merge(rail.to_save())
	return saved

func from_save(data: Dictionary) -> bool:
	if data.is_empty():
		return false
	rail.from_save(data)
	scrap_metal = maxi(0, int(data.get("scrap_metal", 0)))
	wiring = maxi(0, int(data.get("wiring", 0)))
	batteries = maxi(0, int(data.get("batteries", 0)))
	rail_stage2_kit = bool(data.get("rail_stage2_kit", false))
	rail_stage3_kit = bool(data.get("rail_stage3_kit", false))
	clock = float(data.get("clock", 6.0))
	day = int(data.get("day", 1))
	temperature = float(data.get("temperature", 26.0))
	fuel = float(data.get("fuel", 8.0))
	feed = float(data.get("feed", 6.0))
	mass = int(data.get("mass", 0))
	rations = int(data.get("rations", 0))
	bait = int(data.get("bait", 0))
	hides = int(data.get("hides", 0))
	chitin = int(data.get("chitin", 0))
	parts = int(data.get("parts", 0))
	water = int(data.get("water", 0))
	coal = int(data.get("coal", 0))
	medicine = int(data.get("medicine", 0))
	antidotes = int(data.get("antidotes", 0))
	# Version 2 kept bolts on the scene node and therefore did not save them.
	# Old shifts migrate to the same six-bolt starting kit rather than loading an
	# unplayable empty weapon; v3 and later preserve the crafted count exactly.
	bolts = maxi(0, int(data.get("bolts", 6)))
	broadhead_bolts = maxi(0, int(data.get("broadhead_bolts", 0)))
	tether_bolts = maxi(0, int(data.get("tether_bolts", 0)))
	snares = maxi(0, int(data.get("snares", 0)))
	patches = maxi(0, int(data.get("patches", 0)))
	# Schema 8 (C2) added the culture store; schema 9 adds colony populations.
	# Older shifts load with an empty culture store and no net, so nothing about
	# their existing trays or orders changes under them.
	live_crickets = maxi(0, int(data.get("live_crickets", 0)))
	dressed_crickets = maxi(0, int(data.get("dressed_crickets", 0)))
	meals = maxi(0, int(data.get("meals", 0)))
	jerky = maxi(0, int(data.get("jerky", 0)))
	meal_grade = str(data.get("meal_grade", "B"))
	jerky_grade = str(data.get("jerky_grade", "B"))
	kitchen_jobs = data.get("kitchen_jobs", [])
	ready_meals = maxi(0, int(data.get("ready_meals", 0)))
	ready_jerky = maxi(0, int(data.get("ready_jerky", 0)))
	ready_grade = str(data.get("ready_grade", "B"))
	net_crafted = bool(data.get("net_crafted", false))
	ember_chitin = maxi(0, int(data.get("ember_chitin", 0)))
	heat_glands = maxi(0, int(data.get("heat_glands", 0)))
	ember_snares = maxi(0, int(data.get("ember_snares", 0)))
	lantern_crafted = bool(data.get("lantern_crafted", false))
	lantern_on = bool(data.get("lantern_on", false))
	lantern_fuel_seconds = maxf(0.0, float(data.get("lantern_fuel_seconds", 0.0)))
	cave_papers = data.get("cave_papers", [])
	cave_drop = data.get("cave_drop", {})
	cave_payout = data.get("cave_payout", {})
	driver_durability = clampi(int(data.get("driver_durability", DRIVER_MAX_DURABILITY)), 0, DRIVER_MAX_DURABILITY)
	selected_bolt_type = str(data.get("selected_bolt_type", "standard"))
	if not BOLT_TYPE_ORDER.has(selected_bolt_type):
		selected_bolt_type = "standard"
	snare_armed = bool(data.get("snare_armed", false))
	storage_rack_installed = bool(data.get("storage_rack_installed", false))
	thermal_regulators = maxi(0, int(data.get("thermal_regulators", 0)))
	chain_links = maxi(0, int(data.get("chain_links", 0)))
	_restore_world_items(data)
	heat_reclaimer_installed = bool(data.get("heat_reclaimer_installed", false))
	# Schema 11 (C4) adds the cold store. Older saves have no searched jars, an
	# unopened crate and no cold frame, so the cellar loads exactly as unvisited.
	cold_store_jars_searched = []
	for jar_value in data.get("cold_store_jars_searched", []):
		cold_store_jars_searched.append(int(jar_value))
	cold_store_crate_opened = bool(data.get("cold_store_crate_opened", false))
	cold_frame_installed = bool(data.get("cold_frame_installed", false))
	cold_frame_meal = bool(data.get("cold_frame_meal", false))
	standing = int(data.get("standing", 10))
	traffic = int(data.get("traffic", 0))
	hunger_hours = float(data.get("hunger_hours", RATION_HUNGER_HOURS))
	venom_seconds = float(data.get("venom_seconds", 0.0))
	furnace_lit = bool(data.get("furnace_lit", true))
	# Older saves predate the bedside kit.  Leaving it closed is safe: an old
	# shift still loads, then naturally receives the first-night tool prompt.
	bedside_kit_opened = bool(data.get("bedside_kit_opened", false))
	trays = data.get("trays", [])
	# Existing Basement Farm saves used a cockroach tray.  Preserve all its
	# progress and health while migrating the colony to the supplied cricket rig.
	for tray_value in trays:
		if typeof(tray_value) != TYPE_DICTIONARY:
			continue
		var tray: Dictionary = tray_value as Dictionary
		if str(tray.get("species", "")) == "roach":
			tray["species"] = "cricket"
		# Schema 9 // colonies carry a population. Older cards only had a growth
		# bar, so the count is derived from that bar and growth resumes from it.
		if not tray.has("population"):
			tray["population"] = CRICKET_START_POPULATION if str(tray.get("species", "")) != "cricket" else int(round(lerpf(float(CRICKET_START_POPULATION), float(CRICKET_HARVEST_POPULATION), clampf(float(tray.get("progress", 0.0)), 0.0, 1.0))))
		if not tray.has("growth_minutes"):
			tray["growth_minutes"] = _cricket_minutes_for_population(int(tray["population"]))
	orders = data.get("orders", [])
	delivered_box = data.get("delivered_box", {})
	packed_box = data.get("packed_box", {})
	carried_remains = data.get("carried_remains", [])
	gaps = data.get("gaps", [])
	var saved_upgrades: Dictionary = data.get("upgrades", {})
	for axis in AXES:
		upgrades[axis] = int(saved_upgrades.get(axis, 0))
	kills = int(data.get("kills", 0))
	# Schema 10 (C3) adds the first-night story. A save without it predates the
	# opening: it loads finished, with an intact shutter chain, so no existing
	# farm is pushed back through the tutorial or loses a working lever.
	story.from_save(data.get("story", {}))
	starving = hunger_hours <= 0.0
	night_rolled = clock >= 20.0
	report.clear()
	return true
