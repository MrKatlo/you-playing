extends RefCounted

## Persistent rail facts only. FarmState owns this model; live distance/speed are
## deliberately absent so a reload can only restore a completed platform stop.
const DEFAULTS := {
	"unlocked": false, "repair_stage": 0, "completed_repairs": [],
	"first_ride_completed": false, "destination": "corridor",
	"station_restored": false, "safety_restored": false,
	"safety_switches": [false, false, false], "cart_durability": 0,
	"motor_upgraded": false, "shared_parts": 0, "emergency_parts": 0,
	"recovery_pending": false, "terminal_parts_stock": 10,
	"stage2_kit_purchased": false, "stage3_kit_purchased": false,
	"last_safe_station": "corridor", "loop_completion_count": 0,
	"starter_taken": false, "salvage_cycle": -1, "loop_half_complete": false,
	"warning_volume": 0.8, "subtitles": true, "reduced_shake": false,
}
var data: Dictionary = DEFAULTS.duplicate(true)

func to_save() -> Dictionary:
	var saved := {}
	for key in DEFAULTS:
		saved["rail_" + key] = data[key]
	return saved.duplicate(true)

func from_save(saved: Dictionary) -> void:
	data = DEFAULTS.duplicate(true)
	if int(saved.get("version", 0)) < 12:
		return
	for key in DEFAULTS:
		var value: Variant = saved.get("rail_" + key, DEFAULTS[key])
		match typeof(DEFAULTS[key]):
			TYPE_BOOL: data[key] = bool(value)
			TYPE_INT: data[key] = maxi(0, int(value))
			TYPE_FLOAT: data[key] = clampf(float(value), 0.0, 1.0)
			TYPE_STRING: data[key] = str(value)
			TYPE_ARRAY:
				if value is Array: data[key] = value.duplicate(true)
	data.cart_durability = clampi(int(data.cart_durability), 0, 100)
	data.shared_parts = clampi(int(data.shared_parts), 0, 25)
	data.terminal_parts_stock = clampi(int(data.terminal_parts_stock), 0, 10)
	data.emergency_parts = clampi(int(data.emergency_parts), 0, 3)
	data.salvage_cycle = maxi(-1, int(saved.get("rail_salvage_cycle", -1)))
	data.repair_stage = clampi(int(data.repair_stage), 0, 3)
	var switches: Array = [false, false, false]
	for i in mini(3, data.safety_switches.size()): switches[i] = bool(data.safety_switches[i])
	data.safety_switches = switches
	data.safety_restored = switches.all(func(v): return v) and bool(data.station_restored)
	data.motor_upgraded = data.safety_restored
	if data.safety_restored: data.repair_stage = 3
	elif data.station_restored: data.repair_stage = 2
	else: data.repair_stage = mini(int(data.repair_stage), 1)
	if not ["corridor", "pocket"].has(data.last_safe_station): data.last_safe_station = "corridor"
	data.destination = data.last_safe_station
	if data.recovery_pending or (data.repair_stage > 0 and data.cart_durability == 0):
		data.last_safe_station = "corridor"
		data.destination = "corridor"
		data.loop_half_complete = false

func discover(story_complete: bool) -> bool:
	if not story_complete: return false
	data.unlocked = true
	return true

func ensure_recovery_parts(carried: int) -> void:
	var stored: int = int(data.shared_parts) if data.station_restored else 0
	var needed := int(ceil(float(100 - int(data.cart_durability)) / 40.0))
	data.emergency_parts = maxi(int(data.emergency_parts), maxi(0, needed - maxi(0, carried) - stored))

func recover(carried: int) -> void:
	data.cart_durability = 0
	data.recovery_pending = true
	data.last_safe_station = "corridor"
	data.destination = "corridor"
	data.loop_half_complete = false
	ensure_recovery_parts(carried)

func complete_loop() -> void:
	data.loop_completion_count += 1
	data.terminal_parts_stock = 10
	data.emergency_parts = 3
	data.loop_half_complete = false

func confirm_station(station: String) -> void:
	data.last_safe_station = station
	data.destination = station
	if station == "pocket":
		data.first_ride_completed = true
	data.recovery_pending = false
