extends RefCounted

static func install(farm) -> String:
	if farm.rail.data.completed_repairs.has("safety_kit"): return "Throw each of the three switches."
	if not farm.rail.data.station_restored or not farm.rail_stage3_kit: return "NEED SAFETY KIT from the pocket terminal."
	farm.rail_stage3_kit = false
	farm.rail.data.completed_repairs.append("safety_kit")
	return "KIT FITTED — throw all three switches: LIGHTS, WARNINGS, MOTOR."

static func activate(farm, index: int) -> bool:
	if index < 0 or index > 2 or not farm.rail.data.completed_repairs.has("safety_kit"): return false
	if farm.rail.data.safety_switches[index]: return false
	farm.rail.data.safety_switches[index] = true
	if farm.rail.data.safety_switches.all(func(v): return v):
		farm.rail.data.safety_restored = true
		farm.rail.data.motor_upgraded = true
		farm.rail.data.repair_stage = 3
		farm.rail.data.completed_repairs.append("safety")
	return true
