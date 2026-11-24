extends RefCounted

# Mechanical components and mechanical parts use the existing farm.parts stock.
# Kits are inventory fields on FarmState, never ephemeral world pickups.
const OFFERS := {
	"part": {"label": "MECHANICAL PART", "cost": {"scrap_metal": 3, "wiring": 1}},
	"stage2": {"label": "WORKSHOP KIT", "cost": {"scrap_metal": 5, "wiring": 2, "parts": 1}},
	"stage3": {"label": "SAFETY KIT", "cost": {"scrap_metal": 5, "batteries": 2, "parts": 2}},
}
const RESOURCE_NAMES := {"scrap_metal": "scrap", "wiring": "wire", "parts": "mechanical part", "batteries": "battery"}

static func cost_text(id: String) -> String:
	var items: PackedStringArray = []
	for key in OFFERS[id].cost:
		items.append("%d %s" % [OFFERS[id].cost[key], RESOURCE_NAMES[key]])
	return " + ".join(items)

static func trade(farm, id: String) -> String:
	var state: Dictionary = farm.rail.data
	if not state.first_ride_completed: return "TERMINAL LOCKED — arrive by rail to register your cart."
	if not OFFERS.has(id): return "Unknown exchange."
	if id == "part" and state.terminal_parts_stock <= 0: return "PARTS SOLD OUT — complete a full rail loop."
	if id != "part" and state[id + "_kit_purchased"]: return "That protected kit has already been issued."
	if id == "stage3" and not state.station_restored: return "Restore the workshop before ordering the safety kit."
	for key in OFFERS[id].cost:
		if int(farm.get(key)) < int(OFFERS[id].cost[key]): return "NEED " + cost_text(id)
	for key in OFFERS[id].cost: farm.set(key, int(farm.get(key)) - int(OFFERS[id].cost[key]))
	if id == "part":
		farm.parts += 1
		state.terminal_parts_stock -= 1
	else:
		state[id + "_kit_purchased"] = true
		farm.set("rail_" + id + "_kit", true)
	return str(OFFERS[id].label) + " DISPENSED"

static func salvage(farm) -> String:
	var state: Dictionary = farm.rail.data
	if int(state.salvage_cycle) == int(state.loop_completion_count):
		return "SALVAGE CLEARED — another load washes in after a full loop."
	state.salvage_cycle = state.loop_completion_count
	# Enough accessible material for both kits, plus three return-trip repairs.
	farm.scrap_metal += 13
	farm.wiring += 3
	farm.batteries += 2
	farm.parts += 6
	return "RECOVERED: 13 scrap · 3 wire · 2 batteries · 6 mechanical parts"
