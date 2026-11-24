extends RefCounted

static func restore(farm) -> String:
	if farm.rail.data.station_restored: return "WORKSHOP ONLINE — one part repairs the cart fully."
	if not farm.rail_stage2_kit: return "NEED WORKSHOP KIT — buy one at the terminal."
	farm.rail_stage2_kit = false
	farm.rail.data.station_restored = true
	farm.rail.data.repair_stage = 2
	farm.rail.data.completed_repairs.append("workshop")
	return "WORKSHOP RESTORED — shared storage and full repairs online."

static func repair(farm, full: bool = false) -> String:
	if farm.rail.data.repair_stage == 0: return "Install the starter coupling first."
	if farm.rail.data.cart_durability >= 100: return "CART ALREADY SOUND — 100 / 100"
	if farm.parts < 1: return "NEED 1 MECHANICAL PART — check storage or the emergency cabinet."
	farm.parts -= 1
	var gain := 100 if full and farm.rail.data.station_restored else 40
	farm.rail.data.cart_durability = mini(100, int(farm.rail.data.cart_durability) + gain)
	farm.rail.data.recovery_pending = false
	return "CART REPAIRED — %d / 100" % int(farm.rail.data.cart_durability)

static func transfer(farm, deposit: bool) -> String:
	if not farm.rail.data.station_restored: return "RESTORE THE WORKSHOP to connect shared storage."
	if deposit:
		if farm.parts == 0 or farm.rail.data.shared_parts == 25: return "No carried parts or storage full."
		farm.parts -= 1
		farm.rail.data.shared_parts += 1
	else:
		if farm.rail.data.shared_parts == 0: return "Shared cabinet empty."
		farm.parts += 1
		farm.rail.data.shared_parts -= 1
	return "SHARED STORAGE %d / 25 · CARRIED %d" % [int(farm.rail.data.shared_parts), farm.parts]
