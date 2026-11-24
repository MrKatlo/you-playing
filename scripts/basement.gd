extends Node3D

# The basement farm. Builds the room, owns the FarmState model, and wires the
# stations (furnace, trays, table, bench, slate, delivery hatch, and hunt
# chamber) to it.

const PlayerScript := preload("res://scripts/player.gd")
const BurrowerScript := preload("res://scripts/burrower.gd")
const MenuScript := preload("res://scripts/basement_menu.gd")
const AudioScript := preload("res://scripts/basement_audio.gd")
const SurvivalGlyph := preload("res://scripts/survival_glyph.gd")
const RailSystem := preload("res://scripts/rail_system.gd")
const CEILING_BAY := preload("res://assets/models/station/ceiling_worklight_bay.glb")
const LOCKER_BANK := preload("res://assets/models/station/locker_bank.glb")
const PIPE_RACK := preload("res://assets/models/station/service_pipe_rack.glb")
const CONSOLE := preload("res://assets/models/station/industrial_control_console.glb")
const FURNACE_MODEL := preload("res://assets/models/basement/makeshift_furnace.glb")
const CULTURE_TRAY_MODEL := preload("res://assets/models/basement/grimy_culture_tray.glb")
const PARCEL_MODEL := preload("res://assets/models/basement/generated/props/order_parcel.glb")
const RUGGED_WALL_A := preload("res://assets/models/basement/rugged_basement_wall_a.glb")
const RUGGED_WALL_B := preload("res://assets/models/basement/rugged_basement_wall_b.glb")
const RUGGED_WALL_C := preload("res://assets/models/basement/rugged_basement_wall_c.glb")
const BUTCHER_TABLE_MODEL := preload("res://assets/models/basement/butcher_table.glb")
const PACKAGING_BENCH_MODEL := preload("res://assets/models/basement/packaging_bench.glb")
const SALVAGED_WORKBENCH_MODEL := preload("res://assets/models/basement/generated/props/salvaged_workbench.glb")
const KITCHEN_BENCH_MODEL := preload("res://assets/models/basement/generated/props/kitchen_bench.glb")
const CAVE_TRADE_DROP_MODEL := preload("res://assets/models/basement/generated/props/cave_trade_drop.glb")
const ORDER_NOTE_TEXTURE := preload("res://assets/models/basement/generated/props/order_note.png")
const CRICKET_NET_MODEL := preload("res://assets/models/basement/generated/props/cricket_net.glb")
const COLD_STORE_JAR_SHELF_MODEL := preload("res://assets/models/basement/generated/props/cold_store_jar_shelf.glb")
const COLD_STORE_COLD_FRAME_MODEL := preload("res://assets/models/basement/generated/props/cold_store_cold_frame.glb")
const COLD_STORE_DRAIN_GRATE_MODEL := preload("res://assets/models/basement/generated/props/cold_store_drain_grate.glb")
const COLD_STORE_SEALED_CRATE_MODEL := preload("res://assets/models/basement/generated/props/cold_store_sealed_crate.glb")
const NEST_BREACH_MODEL := preload("res://assets/models/basement/generated/props/nest_breach.glb")
const WALL_INSULATION_PATCH_MODEL := preload("res://assets/models/basement/generated/props/wall_insulation_patch.glb")
const HUNT_SNARE_MODEL := preload("res://assets/models/basement/generated/props/hunt_snare.glb")
const MECH_LEVER := preload("res://scripts/mechanical_lever.gd")
const WARM_STORAGE_RACK_MODEL := preload("res://assets/models/basement/generated/props/warm_storage_rack.glb")
const FROZEN_MAINTENANCE_PORTAL_MODEL := preload("res://assets/models/basement/generated/props/frozen_maintenance_portal.glb")
const FROZEN_MAINTENANCE_CART_MODEL := preload("res://assets/models/basement/generated/props/frozen_maintenance_cart.glb")
const FURNACE_HEAT_RECLAIMER_MODEL := preload("res://assets/models/basement/generated/props/furnace_heat_reclaimer.glb")
const BEDSIDE_KIT_CLOSED_MODEL := preload("res://assets/models/basement/generated/props/bedside_survival_kit_closed.glb")
const BEDSIDE_KIT_OPEN_MODEL := preload("res://assets/models/basement/generated/props/bedside_survival_kit_open.glb")
const SALVAGED_COT_MODEL := preload("res://assets/models/basement/salvaged_cot.glb")
const SHUTTER_PANEL_MODEL := preload("res://assets/models/basement/salvaged_rolling_shutter.glb")
const SHUTTER_FRAME_MODEL := preload("res://assets/models/basement/shutter_frame.glb")
const CRICKET_MODEL := preload("res://assets/models/basement/riverborn_animals/cricket.glb")
const GECKO_MODEL := preload("res://assets/models/basement/riverborn_animals/gecko.glb")
const FLOOR_TEXTURE := preload("res://assets/textures/station_floor_concrete.png")
const WALL_TEXTURE := preload("res://assets/textures/basement_wall_grit.png")
const SMOKE_TEXTURE := preload("res://assets/textures/basement_smoke.png")
const HUD_SURFACE := preload("res://assets/ui/hud/survival_hud_surface.png")
const HIT_SFX := preload("res://assets/audio/metal_hit.ogg")
const SWING_SFX := preload("res://assets/audio/machete_swing.wav")
const FLESH_SFX := preload("res://assets/audio/flesh_impact.wav")
const HURT_SFX := preload("res://assets/audio/player_hurt.wav")
const COIL_SFX := preload("res://assets/audio/slime_coil.wav")
const SLAM_SFX := preload("res://assets/audio/slime_slam.wav")
const FURNACE_DOOR_CREAK_SFX := preload("res://assets/audio/furnace_door_creak.ogg")
const FURNACE_DOOR_CLOSE_SFX := preload("res://assets/audio/furnace_door_close.ogg")
const NET_SWISH_SFX := preload("res://assets/audio/net_swish.wav")
const CRICKET_CHIRP_SFX := preload("res://assets/audio/cricket_chirp.wav")
const SAVE_PATH := "user://basement_farm_save.json"

const TRAY_SPOTS := [
	Vector3(-3.0, 0.55, -4.25), Vector3(-1.8, 0.55, -4.25), Vector3(-0.6, 0.55, -4.25),
	Vector3(0.6, 0.55, -4.25), Vector3(1.8, 0.55, -4.25), Vector3(3.0, 0.55, -4.25),
]
const STARTER_TRAY_COUNT := 2
const FURNACE_SPOT := Vector3(-5.0, 0.0, -4.0)
const WORKBENCH_SPOT := Vector3(3.95, 0.0, 2.65)
const PACK_BENCH_SPOT := Vector3(3.6, 0.45, -0.2)
# C2 // culture kitchen: the free stretch of west wall between the butcher table
# and the cot, front facing into the room.
const KITCHEN_SPOT := Vector3(-5.37, 0.0, 1.55)
const STORAGE_RACK_SPOT := Vector3(4.70, 0.0, -4.44)
const STORAGE_RACK_ROTATION := 0.0
const HUNT_CHAMBER_CENTER := Vector3(8.0, 0.0, -2.0)
const HUNT_BAIT_SPOT := Vector3(8.25, 0.0, -2.0)
const HUNT_SNARE_SPOT := Vector3(8.25, 0.012, -2.0)
const HUNT_BULKHEAD_SPOT := Vector3(6.0, 0.0, -2.0)
const OUTER_HUNT_SHUTTER_SPOT := Vector3(10.0, 0.0, -2.0)
const OUTER_HUNT_SPAWN := Vector3(11.7, 0.0, -2.0)
const CAVE_ENTRY_SPOT := Vector3(11.25, 0.0, -2.0)
const CAVE_JUNCTION_SPOT := Vector3(17.75, 0.0, -2.0)
const CAVE_RETURN_WHEEL_SPOT := Vector3(10.72, 1.02, -3.12)
const CAVE_MARKER_SPOT := Vector3(12.55, 0.92, -3.18)
const CAVE_REGULATOR_SPOT := Vector3(18.72, 1.08, 0.92)
const CAVE_COLLAPSE_SPOT := Vector3(24.05, 0.0, -2.0)
# C2 // the deposit pocket: corridor off the old collapse, gallery, deposit chamber
# and the nest nook behind the breach. Roughly 200 m2 of walkable floor.
const POCKET_CORRIDOR_CENTER := Vector3(32.0, 0.0, -2.0)
# C4 cold store centre: x 13.5..18.5, z -8.5..-4.0, north of the cave corridor.
const COLD_STORE_CENTER := Vector3(16.0, 0.0, -6.25)
const COLD_STORE_CRATE_SPOT := Vector3(18.0, 0.36, -7.8)
const COLD_STORE_FRAME_SPOT := Vector3(16.0, 0.30, -7.6)
var cold_crate: StaticBody3D
var cold_frame_body: StaticBody3D
const POCKET_GALLERY_CENTER := Vector3(52.0, 0.0, 2.5)
const POCKET_CHAMBER_CENTER := Vector3(71.0, 0.0, 2.5)
const TRADE_DROP_SPOT := Vector3(74.85, 0.0, 2.60)
const BREACH_SPOT := Vector3(70.50, 0.0, 5.90)
const POCKET_NEST_CENTER := Vector3(70.50, 0.0, 7.50)
const START_SPOT := Vector3(0.0, 0.9, 2.0)
const BED_SPOT := Vector3(-4.95, 0.28, 3.65)
const BEDSIDE_KIT_SPOT := Vector3(-3.80, 0.28, 4.42)
const WAKE_BED_SPOT := Vector3(-4.95, 0.62, 3.65)
const WAKE_STAND_SPOT := Vector3(-3.72, 0.90, 3.28)
# Mounted controls are physical equipment: they need the player to stand at them
# and face them, not merely to be the nearest object in a 2.4 m bubble.
const LEVER_REACH := 1.9
const LOOK_TO_USE_DOT := 0.72
# All three levers are bolted to the warm-side east wall at the same height; the
# wall's inner face is x = 5.825, so 5.80 seats a 45 mm backing plate on it.
const LEVER_WALL_SPOT := Vector3(5.80, 1.10, 0.0)
const GECKO_ROUTE := [
	Vector3(-4.25, 0.06, -2.80), Vector3(-3.20, 0.06, -3.28),
	Vector3(-2.35, 0.06, -2.72), Vector3(-3.05, 0.06, -2.10),
]
const GAP_POINTS := [
	Vector3(5.9, 1.0, 3.2), Vector3(-5.9, 1.0, -1.0), Vector3(2.5, 1.0, -4.9), Vector3(-2.5, 1.0, 4.9),
]

var farm: FarmState
var rail
var player: SignalRunner
var menu
var sfx_player: AudioStreamPlayer
var audio: BasementAudio
var pocket_audio: PocketAudio
var drop_paper: MeshInstance3D
var drop_paper_second: MeshInstance3D
var drop_paper_torn: Node3D
var drop_paper_signature := ""
var order_box_bench: Node3D
var order_box_hatch: Node3D
var vignette: ColorRect
var cold_overlay: ColorRect
var hurt_overlay: ColorRect
var down_overlay: ColorRect
var health_bar: ColorRect
var hurt_flash := 0.0
var player_downed := false
var down_serial := 0
var wake_overlay: Control
var wake_veil: ColorRect
var wake_top_lid: ColorRect
var wake_bottom_lid: ColorRect
var clock_label: Label
var status_label: Label
var inventory_label: Label
var cricket_panel: Panel
var cricket_label: Label
var carry_panel: Panel
var carry_label: Label
var order_label: Label
var prompt_label: Label
var message_label: Label
var state_label: Label
var crosshair: Label
var heat_bar: ProgressBar
var fuel_bar: ProgressBar
var prompt_panel: Panel
var prompt_key_label: Label
var message_panel: Panel
var objective_panel: Panel
var slate_panel: Panel
var slate_label: Label
# The pocket readout: the lantern's burn and what the clamp is holding, both
# things a player would otherwise walk 75 m to check.
var cricket_net_prop: Node3D
var pocket_panel: Panel
var pocket_label: Label
var danger_panel: Panel
var warmth_glyph: SurvivalGlyph
var fuel_glyph: SurvivalGlyph
var ammo_glyph: SurvivalGlyph
var objective_glyph: SurvivalGlyph
var objective_arrow: SurvivalGlyph
var danger_glyph: SurvivalGlyph
var compass_glyph: SurvivalGlyph
var message_glyph: SurvivalGlyph
var prompt_glyph: SurvivalGlyph
var hotbar_slots: Array[Panel] = []
var hotbar_glyphs: Array[SurvivalGlyph] = []
var hotbar_keys: Array[Label] = []
var hotbar_name_label: Label
var swing_player: AudioStreamPlayer
var net_swish_player: AudioStreamPlayer
var chirp_player: AudioStreamPlayer
var net_catches := 0
var interactables: Array = []
var burrowers: Array = []
var kitchen_body: Node3D
var trade_drop_body: Node3D
var breach_body: Node3D
var breach_light: OmniLight3D
var kitchen_meal_plate: Node3D
var kitchen_jerky_bundle: Node3D
var kitchen_light: OmniLight3D
var kitchen_glow: MeshInstance3D
var kitchen_flicker_time := 0.0
var kitchen_steam_clock := 0.0
var kitchen_cook_heat := 0.0
var kitchen_steam_live := 0
var kitchen_wisp_serial := 0
var tray_slabs: Array = []
var tray_lids: Array = []
var tray_bodies: Array = []
var tray_crickets: Array = []
var slime_guts: Array = []
var gap_patch_visuals: Array[Node3D] = []
var cricket_time := 0.0
var house_gecko: Node3D
var house_gecko_animation: AnimationPlayer
var house_gecko_legs: Array = []
var gecko_time := 0.0
var gecko_route_index := 0
var gecko_wait := 1.2
var shutter_body: Node3D
var hunt_bulkhead_body: Node3D
var shutter_lever: MECH_LEVER
var bulkhead_crank: BulkheadCrank
var snare_lever: MECH_LEVER
var cave_return_wheel: StaticBody3D
var cave_marker: StaticBody3D
var cave_cart: StaticBody3D
var cave_regulator_pickup: Node3D
var hunt_snare_visual: Node3D
var storage_rack_visual: Node3D
var storage_rack_lamp: OmniLight3D
var heat_reclaimer_visual: Node3D
var heat_reclaimer_light: OmniLight3D
var ration_crate_body: StaticBody3D
var bedside_kit_body: StaticBody3D
var bedside_kit_closed_visual: Node3D
var bedside_kit_open_visual: Node3D
var bedside_kit_lid_open := false
var hunt_bulkhead_open := false
var hunt_snare_sprung := false
# C3 // first night. The scripted opening is only armed by a real new shift, so
# the existing suites that build a shift with new_shift(false) are untouched.
var story_enabled := false
var story_wait := -1.0
var story_bang_clock := 0.0
var story_pair: Array = []
## The second-wave creature drawn in after the chain is fitted.
var story_second_wave = null
## Mara's logbook, read aloud once when the farm is handed back.
const MARA_LOGBOOK_LINE := "MARA'S LOGBOOK // The bulkhead holds, but the chain is the weak link. Keep a spare."
var story_bangs := 0
var story_line_index := 0
var story_shudder := 0.0
const STORY_BANG_DELAY := 3.0
const STORY_BANG_CADENCE := 1.6
const STORY_SHUDDER_SECONDS := 0.12
const STORY_BANG_LINES := [
	"SOMETHING IS HITTING THE OUTER SHUTTER.",
	"THE SHUTTER HOLDS — SOMETHING IS ON THE FAR SIDE.",
	"SCRAPING ALONG THE SHUTTER SEAM. IT KNOWS THE ROOM IS WARM.",
	"THE BULKHEAD IS THE ONLY THING BETWEEN YOU AND IT.",
]
var furnace_light: OmniLight3D
var furnace_smoke: GPUParticles3D
var furnace_smoke_puffs: Array = []
var furnace_smoke_time := 0.0
var furnace_door: Node3D
var furnace_flame_core: Node3D
var furnace_door_open := false
var bolts: int:
	get:
		return farm.bolts if farm != null else 0
	set(value):
		if farm != null:
			farm.bolts = maxi(0, value)
var shutter_open := false
var lure_left := 0.0
var breach_day := 0
var crank_cooldown := 0.0
var shot_cooldown := 0.0
# The pocket's threat (M6): two cinder burrowers may be out at once, and the
# breach will not give up another for a minute after one is stirred.
const CINDER_MAX_ALIVE := 2
const CINDER_SPAWN_COOLDOWN := 60.0
const CINDER_LEASH_RADIUS := 22.0
const CINDER_LINGER_TIME := 2.0
var cinder_cooldown := 0.0
var cinder_serial := 0
var cinder_split_serial := 0
var breach_linger := 0.0
var hit_stop_serial := 0
var warmth := 1.0
var master_volume_db := -5.0
var opening_state := ""
var opening_tween: Tween
const PhysicalPickup := preload("res://scripts/farm_pickup.gd")
const ControllerInput := preload("res://scripts/basement_input.gd")
const LINK_FIT_SECONDS := 0.9
var world_pickup_views: Dictionary = {}
var chain_install_elapsed := -1.0
var chain_install_start := Transform3D.IDENTITY
var chain_install_health := 0.0
var chain_install_prop: Node3D
var interaction_progress: ProgressBar

func _ready() -> void:
	ControllerInput.configure()
	farm = FarmState.new()
	_build_environment()
	_build_room()
	_build_stations()
	_build_hud()
	sfx_player = AudioStreamPlayer.new()
	sfx_player.volume_db = -5.0
	add_child(sfx_player)
	swing_player = AudioStreamPlayer.new()
	swing_player.volume_db = -4.0
	add_child(swing_player)
	net_swish_player = AudioStreamPlayer.new()
	net_swish_player.volume_db = -2.0
	add_child(net_swish_player)
	chirp_player = AudioStreamPlayer.new()
	chirp_player.volume_db = -8.0
	add_child(chirp_player)
	audio = AudioScript.new()
	add_child(audio)
	player = PlayerScript.new()
	add_child(player)
	player.global_position = START_SPOT
	menu = MenuScript.new()
	menu.game = self
	add_child(menu)
	rail = RailSystem.new()
	rail.game = self
	add_child(rail)
	menu.open_title()
	set_master_volume(master_volume_db)
	show_message("THE BASEMENT // heat is the whole economy.", 3.0)

func _process(delta: float) -> void:
	if farm == null:
		return
	if not get_tree().paused:
		farm.advance_minutes(delta)
		farm.tick_lantern(delta)
		if player != null:
			player.set_lantern_on(farm.lantern_on)
			player.set_lantern_carried(farm.lantern_crafted)
			player.set_lantern_low(farm.lantern_on and farm.lantern_minutes_left() <= 2.0)
			player.set_net_carried(farm.net_crafted)
			player.set_link_carried(farm.chain_links > 0)
		_refresh_net_prop()
		farm.tick_venom(delta)
		lure_left = maxf(0.0, lure_left - delta)
		_update_pocket_threat(delta)
		crank_cooldown = maxf(0.0, crank_cooldown - delta)
		shot_cooldown = maxf(0.0, shot_cooldown - delta)
		hurt_flash = maxf(0.0, hurt_flash - delta * 1.45)
		_update_warmth(delta)
		_update_audio()
		_update_furnace_fx(delta)
		_update_kitchen_life(delta)
		_update_crickets(delta)
		_update_house_gecko(delta)
		_update_bulkhead_crank()
		_update_story(delta)
		_update_chain_install(delta)
		shutter_lever.set_chain_snapped(farm.story.chain_broken)
		_check_night()
	_update_hud()

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if rail != null and rail.riding:
		return
	if event.is_action_pressed("melee") and chain_install_elapsed < 0.0:
		player_melee()

func _update_warmth(delta: float) -> void:
	if player == null:
		return
	# The reclaimer does not make the whole basement safe by itself, but it makes
	# the furnace corner a more reliable staging point after a cave run.
	var furnace_radius := 3.75 if farm.heat_reclaimer_installed else 3.2
	var near_fire := player.global_position.distance_to(FURNACE_SPOT) < furnace_radius
	var near_storage_lamp := farm.storage_rack_installed and farm.furnace_lit and farm.fuel > 0.0 and player.global_position.distance_to(STORAGE_RACK_SPOT) < 2.25
	if near_fire or near_storage_lamp or farm.temperature >= 24.0:
		warmth = minf(1.0, warmth + delta * 0.18)
	else:
		warmth = maxf(0.0, warmth - delta * 0.02)

func _update_audio() -> void:
	if audio == null:
		return
	# Furnace: a steady roar once it is lit and has fuel to burn.
	var furnace := 0.0
	if farm.furnace_lit and farm.fuel > 0.0:
		furnace = clampf(0.62 + farm.temperature / 60.0, 0.62, 1.0)
	# Trays: density follows live colonies, and health decides how thin it sounds.
	var live := 0
	var health_sum := 0.0
	for tray in farm.trays:
		if not bool(tray["active"]) or bool(tray["dead"]):
			continue
		live += 1
		health_sum += float(tray["health"])
	var density := clampf(float(live) / float(FarmState.START_TRAYS), 0.0, 1.0)
	var thin := 1.0
	if live > 0:
		thin = clampf(1.0 - health_sum / float(live), 0.0, 1.0)
	audio.set_beds(furnace, density, thin)
	audio.set_muted(menu != null and menu.visible)
	if pocket_audio != null:
		pocket_audio.set_muted(menu != null and menu.visible)
	_refresh_drop_papers()
	_refresh_order_boxes()


## Shows the order box on the packing bench while it is packed, and at the
## delivery hatch while it waits to be collected. Both follow FarmState, which
## stays the only source of truth.
func _refresh_order_boxes() -> void:
	if order_box_bench == null or order_box_hatch == null or farm == null:
		return
	order_box_bench.visible = not farm.packed_box.is_empty()
	order_box_hatch.visible = not farm.delivered_box.is_empty()


func _build_order_box(parent: Node3D, name_text: String) -> Node3D:
	var box := PARCEL_MODEL.instantiate() as Node3D
	box.name = name_text
	box.position = Vector3(0.0, 0.10, 0.0)
	box.visible = false
	parent.add_child(box)
	return box


func _update_furnace_fx(delta: float) -> void:
	if farm == null:
		return
	var burning: bool = farm.furnace_lit and farm.fuel > 0.0
	if furnace_light != null:
		furnace_light.visible = burning
		furnace_light.light_energy = 3.6 if burning else 0.0
	if storage_rack_lamp != null:
		storage_rack_lamp.visible = farm.storage_rack_installed and burning
		storage_rack_lamp.light_energy = 1.15 if farm.storage_rack_installed and burning else 0.0
	if heat_reclaimer_light != null:
		heat_reclaimer_light.visible = farm.heat_reclaimer_installed and burning
		heat_reclaimer_light.light_energy = 0.72 if farm.heat_reclaimer_installed and burning else 0.0
	if furnace_smoke != null:
		furnace_smoke.emitting = burning
	if furnace_flame_core != null:
		furnace_flame_core.visible = burning
		var flame_scale: float = 0.92 + sin(furnace_smoke_time * 8.0) * 0.10 if burning else 0.0
		furnace_flame_core.scale = Vector3(1.0, flame_scale, 1.0)
	furnace_smoke_time += delta if burning else 0.0
	for index in furnace_smoke_puffs.size():
		var puff := furnace_smoke_puffs[index] as MeshInstance3D
		if puff == null:
			continue
		puff.visible = burning
		if not burning:
			continue
		var phase: float = fmod(furnace_smoke_time * 0.22 + float(index) * 0.29, 1.0)
		puff.position = FURNACE_SPOT + Vector3(
			0.30 + sin(furnace_smoke_time * 0.8 + float(index) * 1.7) * 0.16,
			2.72 + phase * 0.36,
			cos(furnace_smoke_time * 0.65 + float(index) * 1.2) * 0.12,
		)
		var puff_scale: float = 0.52 + phase * 0.72
		puff.scale = Vector3.ONE * puff_scale


func _update_crickets(delta: float) -> void:
	if farm == null:
		return
	cricket_time += delta
	for item in tray_crickets:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var cricket: Dictionary = item as Dictionary
		var root: Node3D = cricket.get("root") as Node3D
		if root == null or not is_instance_valid(root):
			continue
		var tray_index: int = int(cricket.get("tray_index", -1))
		if tray_index < 0 or tray_index >= farm.trays.size():
			root.visible = false
			continue
		var tray: Dictionary = farm.trays[tray_index]
		var alive: bool = bool(tray["active"]) and not bool(tray["dead"])
		root.visible = alive
		if not alive:
			continue
		var phase: float = float(cricket.get("phase", 0.0))
		var home: Vector2 = cricket.get("home", Vector2.ZERO) as Vector2
		var speed: float = 0.58 + fmod(phase, 0.22)
		var stride: float = cricket_time * speed + phase
		var drift_x: float = sin(stride) * 0.105 + sin(stride * 0.53 + phase) * 0.032
		var drift_z: float = cos(stride * 1.24 + phase) * 0.068
		var movement_x: float = cos(stride) * speed * 0.105 + cos(stride * 0.53 + phase) * speed * 0.017
		var movement_z: float = -sin(stride * 1.24 + phase) * speed * 0.084
		var hop_cycle: float = fmod(stride * 0.82, 1.0)
		var hopping: bool = hop_cycle < 0.28
		var hop_height: float = sin(PI * hop_cycle / 0.28) * 0.030 if hopping else 0.0
		var target_position: Vector3 = Vector3(
			TRAY_SPOTS[tray_index].x + home.x + drift_x,
			0.515 + hop_height,
			TRAY_SPOTS[tray_index].z + home.y + drift_z,
		)
		root.position = target_position
		var desired_yaw: float = atan2(-movement_x, -movement_z)
		root.rotation.y = lerp_angle(root.rotation.y, desired_yaw, minf(1.0, delta * 8.0))
		root.rotation.z = 0.0
		var growth: float = clampf(float(tray["progress"]), 0.0, 1.0)
		root.scale = Vector3.ONE * (0.92 + growth * 0.18)
		var animation: AnimationPlayer = cricket.get("animation") as AnimationPlayer
		_play_riverborn_animation(animation, "hop" if hopping else "idle", 1.0 if hopping else 0.82)


func _play_riverborn_animation(animation: AnimationPlayer, clip: String, speed: float = 1.0) -> void:
	if animation == null or not animation.has_animation(clip):
		return
	if animation.current_animation != clip:
		animation.play(clip, 0.08)
	animation.speed_scale = speed


func _update_house_gecko(delta: float) -> void:
	if house_gecko == null or not is_instance_valid(house_gecko) or GECKO_ROUTE.is_empty():
		return
	gecko_time += delta
	var target: Vector3 = GECKO_ROUTE[gecko_route_index]
	var offset: Vector3 = target - house_gecko.position
	offset.y = 0.0
	if offset.length() < 0.055:
		gecko_wait -= delta
		_play_riverborn_animation(house_gecko_animation, "rest", 0.75)
		_animate_house_gecko_legs(0.0)
		if gecko_wait <= 0.0:
			gecko_route_index = (gecko_route_index + 1) % GECKO_ROUTE.size()
			gecko_wait = 1.4 + fmod(gecko_time * 0.37, 1.7)
		return
	var direction: Vector3 = offset.normalized()
	house_gecko.position += direction * minf(offset.length(), delta * 0.19)
	house_gecko.position.y = target.y + sin(gecko_time * 5.0) * 0.006
	var desired_yaw: float = atan2(-direction.x, -direction.z)
	house_gecko.rotation.y = lerp_angle(house_gecko.rotation.y, desired_yaw, minf(1.0, delta * 7.0))
	_play_riverborn_animation(house_gecko_animation, "slither", 0.72)
	_animate_house_gecko_legs(gecko_time * 9.0)


func _animate_house_gecko_legs(stride: float) -> void:
	for item in house_gecko_legs:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var leg: Dictionary = item as Dictionary
		var pivot: Node3D = leg.get("pivot") as Node3D
		if pivot == null or not is_instance_valid(pivot):
			continue
		var side: float = float(leg.get("side", 1.0))
		var phase: float = float(leg.get("phase", 0.0))
		var swing: float = sin(stride + phase) * deg_to_rad(13.0) if stride > 0.0 else 0.0
		pivot.rotation.x = -side * (deg_to_rad(57.0) + swing)

func _check_night() -> void:
	if farm.clock < 20.0 or breach_day == int(farm.day):
		return
	breach_day = int(farm.day)
	var count: int = farm.night_breach_count(int(farm.day) * 17)
	for _i in count:
		var index := _random_open_gap()
		if index >= 0:
			_spawn_burrower(GAP_POINTS[index] + Vector3(-0.6, 0, 0.0))
	if count > 0:
		show_message("SOMETHING IS INSIDE // it came through a gap. Seal them with 2 parts.", 3.2)
		farm.report.append("BREACH // %d creature(s) inside." % count)

func _random_open_gap() -> int:
	var open: Array = []
	for index in range(farm.gaps.size()):
		if not bool(farm.gaps[index]["sealed"]):
			open.append(index)
	if open.is_empty():
		return -1
	return int(open[randi() % open.size()])

# ---------------------------------------------------------------- world

func _build_environment() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.006, 0.005, 0.004)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.20, 0.14, 0.10)
	environment.ambient_light_energy = 0.35
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.fog_enabled = true
	environment.fog_light_color = Color(0.10, 0.07, 0.05)
	environment.fog_density = 0.02
	var world_env := WorldEnvironment.new()
	world_env.environment = environment
	add_child(world_env)

func _build_room() -> void:
	var floor_mat := _floor_material()
	var wall_mat := _material(Color(0.26, 0.21, 0.17), 0.9, 0.02)
	wall_mat.albedo_texture = WALL_TEXTURE
	wall_mat.uv1_scale = Vector3(1.35, 1.35, 1.0)
	_static_box(Vector3(0, -0.12, 0), Vector3(12, 0.24, 10), floor_mat)
	_static_box(Vector3(0, 3.2, 0), Vector3(12, 0.2, 10), wall_mat)
	_static_box(Vector3(0, 1.6, -5), Vector3(12, 3.2, 0.35), wall_mat)
	_static_box(Vector3(0, 1.6, 5), Vector3(12, 3.2, 0.35), wall_mat)
	_static_box(Vector3(-6, 1.6, 0), Vector3(0.35, 3.2, 10), wall_mat)
	# East wall is split for the inner bulkhead. Beyond it is a dedicated hunt
	# chamber, so the farm itself remains a defendable warm room.
	_static_box(Vector3(6, 1.6, -3.95), Vector3(0.35, 3.2, 2.1), wall_mat)
	_static_box(Vector3(6, 1.6, 1.95), Vector3(0.35, 3.2, 6.1), wall_mat)
	_static_box(Vector3(6, 2.95, -2.0), Vector3(0.35, 0.5, 1.8), wall_mat)
	_build_hunt_chamber(floor_mat, wall_mat)
	_build_cave_access()
	_add_rugged_wall_bays()
	for x in [-3.0, 0.0, 3.0]:
		for z in [-2.5, 2.5]:
			var bay := CEILING_BAY.instantiate()
			bay.position = Vector3(x, 3.05, z)
			bay.scale = Vector3(1.5, 1.0, 1.25)
			add_child(bay)
	# The cot corner is intentionally low and clear.  The old upright locker was
	# visually cutting through the mattress, so the survivor's tools now live in
	# a wall-hugging footlocker built for this room rather than a station prop.
	_add_prop(PIPE_RACK, Vector3(5.75, 0.4, 2.6), Vector3(0.9, 0.9, 0.9), -PI * 0.5)
	# Lights: warm work light, furnace glow, tray glow, cold shutter spill.
	_add_light(Vector3(0, 2.8, 0), Color(1.0, 0.82, 0.58), 3.2, 14.0)
	furnace_light = _light_node(FURNACE_SPOT + Vector3(0.55, 1.15, 0.42), Color(1.0, 0.31, 0.08), 3.6, 7.0)
	add_child(furnace_light)
	_add_light(Vector3(0, 1.1, -4.0), Color(0.45, 0.85, 0.35), 0.9, 4.5)
	_add_light(Vector3(5.4, 2.1, -2.0), Color(0.45, 0.62, 1.0), 1.1, 6.0)


func _build_hunt_chamber(floor_mat: Material, wall_mat: Material) -> void:
	# The actual trap is a room, not a tiny cage: creature enters through the
	# outer shutter, the hunter seals it, then chooses whether to risk opening
	# the inner bulkhead. It deliberately uses colder lights and rougher walls
	# than the warm farm side.
	_static_box(HUNT_CHAMBER_CENTER + Vector3(0.0, -0.12, 0.0), Vector3(4.0, 0.24, 4.0), floor_mat)
	_static_box(HUNT_CHAMBER_CENTER + Vector3(0.0, 3.2, 0.0), Vector3(4.0, 0.20, 4.0), wall_mat)
	_static_box(Vector3(8.0, 1.6, -4.0), Vector3(4.0, 3.2, 0.35), wall_mat)
	_static_box(Vector3(8.0, 1.6, 0.0), Vector3(4.0, 3.2, 0.35), wall_mat)
	# The far east wall is likewise split around the exterior hunt shutter.
	_static_box(Vector3(10.0, 1.6, -3.55), Vector3(0.35, 3.2, 0.9), wall_mat)
	_static_box(Vector3(10.0, 1.6, -0.45), Vector3(0.35, 3.2, 0.9), wall_mat)
	_static_box(Vector3(10.0, 2.95, -2.0), Vector3(0.35, 0.50, 1.8), wall_mat)
	# A rusted pressure slab is visual evidence of prior hunts, not a magical
	# damage machine. The actual containment comes from the two real doors.
	var slab := _box_visual(Vector3(2.20, 0.035, 1.80), Color(0.14, 0.12, 0.10), false)
	slab.position = HUNT_CHAMBER_CENTER + Vector3(0.0, 0.024, 0.0)
	add_child(slab)
	for offset in [-0.72, -0.24, 0.24, 0.72]:
		var stripe := _box_visual(Vector3(0.12, 0.012, 1.55), Color(0.56, 0.18, 0.025), true, 0.35)
		stripe.position = HUNT_CHAMBER_CENTER + Vector3(offset, 0.046, 0.0)
		add_child(stripe)
	_add_light(HUNT_CHAMBER_CENTER + Vector3(0.0, 2.55, 0.0), Color(0.56, 0.13, 0.07), 1.15, 5.5)
	_add_light(HUNT_CHAMBER_CENTER + Vector3(1.40, 1.25, 0.0), Color(0.24, 0.42, 0.58), 0.65, 3.4)


func _build_cave_access() -> void:
	# This is deliberately part of the production Basement Farm scene, not a
	# second game or a teleport. The hunt chamber's outer shutter remains the
	# physical threshold: when it lifts, the player can walk directly into the
	# frozen maintenance route below the house and walk back the same way.
	var cave_floor := _floor_material()
	cave_floor.albedo_color = Color(0.30, 0.34, 0.35)
	cave_floor.uv1_scale = Vector3(0.20, 0.20, 1.0)
	var cave_wall := _material(Color(0.16, 0.20, 0.21), 0.96, 0.12)
	cave_wall.albedo_texture = WALL_TEXTURE
	cave_wall.uv1_scale = Vector3(1.05, 1.05, 1.0)

	# A narrow service tunnel continues the hunt room's exact floor level. The
	# collision is intentionally plain and dependable; its visible surface is
	# dressed with generated portal bays, worn wall panels, ice, debris, and
	# lighting below rather than presented as a bare grey box.
	_static_box(Vector3(17.0, -0.12, -2.0), Vector3(14.0, 0.24, 4.0), cave_floor)
	_static_box(Vector3(17.0, 3.2, -2.0), Vector3(14.0, 0.20, 4.0), cave_wall)
	# The south wall breaks once, at the cold store: a real doorway with jambs
	# and a lintel, so the room is reached by walking rather than by a teleport.
	_static_box(Vector3(12.6, 1.6, -4.0), Vector3(5.2, 3.2, 0.35), cave_wall)
	# Rail access opens at x22, beyond the cold-store doorway at x16.
	_static_box(Vector3(18.9, 1.6, -4.0), Vector3(4.2, 3.2, 0.35), cave_wall)
	_static_box(Vector3(23.5, 1.6, -4.0), Vector3(1.0, 3.2, 0.35), cave_wall)
	_static_box(Vector3(22.0, 2.9, -4.0), Vector3(2.0, 0.6, 0.35), cave_wall)
	_static_box(Vector3(16.0, 2.78, -4.0), Vector3(1.6, 0.84, 0.35), cave_wall)
	# The north wall breaks only at the junction alcove. That offset space gives
	# the player a first landmark and a readable place to turn around, instead of
	# an endless straight corridor.
	_static_box(Vector3(13.05, 1.6, 0.0), Vector3(6.10, 3.2, 0.35), cave_wall)
	_static_box(Vector3(22.10, 1.6, 0.0), Vector3(3.80, 3.2, 0.35), cave_wall)
	# The old collapse is dug through, not removed: two shoulders of rubble wall and
	# a lintel keep the squeeze legible while the route to the deposit pocket opens.
	_static_box(Vector3(24.0, 1.6, -3.225), Vector3(0.35, 3.2, 1.55), cave_wall)
	_static_box(Vector3(24.0, 1.6, -0.575), Vector3(0.35, 3.2, 1.15), cave_wall)
	_static_box(Vector3(24.0, 2.60, -1.80), Vector3(0.35, 1.20, 1.30), cave_wall)

	# The Cold Junction is the first hand-authored cave pocket. It is compact on
	# purpose: this slice proves home -> hunt chamber -> cave -> return without
	# pretending an unfinished tunnel is a full expedition biome.
	_static_box(Vector3(18.25, -0.12, 1.5), Vector3(4.0, 0.24, 3.0), cave_floor)
	_static_box(Vector3(18.25, 3.2, 1.5), Vector3(4.0, 0.20, 3.0), cave_wall)
	_static_box(Vector3(16.25, 1.6, 1.5), Vector3(0.35, 3.2, 3.0), cave_wall)
	_static_box(Vector3(20.25, 1.6, 1.5), Vector3(0.35, 3.2, 3.0), cave_wall)
	_static_box(Vector3(18.25, 1.6, 3.0), Vector3(4.0, 3.2, 0.35), cave_wall)

	# These are authored GLB support bays built through the Basement-owned model
	# pipeline. The repeated weak lamps form a physical breadcrumb trail back to
	# the furnace glow, while their uneven pipes and frost stop the new route
	# looking like a sterile corridor bolted onto the old room.
	for index in 5:
		var portal: Node3D = FROZEN_MAINTENANCE_PORTAL_MODEL.instantiate() as Node3D
		if portal == null:
			continue
		portal.name = "FrozenMaintenancePortal_%d" % index
		portal.position = Vector3(11.35 + float(index) * 2.95, 0.0, -2.0)
		portal.rotation.y = PI * 0.5
		add_child(portal)
		# The generated model contains the caged lamp; this small real light is
		# its readable spill on the floor. It makes the way back visible without
		# making the tunnel feel like a well-lit basement extension.
		_add_light(Vector3(11.00 + float(index) * 2.95, 2.0, -3.25), Color(0.92, 0.40, 0.12), 0.46, 3.0)

	var cave_bays: Array[PackedScene] = [RUGGED_WALL_C, RUGGED_WALL_B, RUGGED_WALL_A, RUGGED_WALL_C]
	for index in cave_bays.size():
		_add_prop(cave_bays[index], Vector3(11.8 + float(index) * 2.85, 0.0, -3.74))
	# The alcove face uses the same repaired-wall language as home, but the
	# opposite rotation and colder exposure make it feel like infrastructure
	# beneath the house rather than a duplicated basement wall.
	_add_prop(RUGGED_WALL_B, Vector3(21.75, 0.0, -0.25), Vector3.ONE, PI)
	_add_prop(RUGGED_WALL_A, Vector3(18.20, 0.0, 2.74), Vector3.ONE, PI)

	_add_cave_frost_cluster(Vector3(12.3, 0.10, -3.66), Vector3(0.78, 0.18, 0.10), 1)
	_add_cave_frost_cluster(Vector3(15.55, 0.08, -0.30), Vector3(0.62, 0.13, 0.08), 2)
	_add_cave_frost_cluster(Vector3(18.5, 0.08, 2.68), Vector3(0.94, 0.16, 0.10), 3)
	_add_cave_frost_cluster(Vector3(22.65, 0.09, -3.66), Vector3(0.72, 0.15, 0.11), 4)
	_build_cave_collapse()
	_build_cave_return_wheel()
	_build_cave_marker()
	_build_cave_cart()

	_add_light(Vector3(11.8, 2.10, -2.0), Color(0.34, 0.47, 0.59), 0.92, 4.6)
	_add_light(CAVE_JUNCTION_SPOT + Vector3(0.0, 2.20, 0.0), Color(0.28, 0.42, 0.55), 1.08, 5.6)
	_add_light(Vector3(18.20, 1.50, 1.45), Color(0.65, 0.29, 0.08), 0.72, 3.6)
	_add_light(Vector3(23.15, 1.55, -2.0), Color(0.45, 0.30, 0.16), 0.54, 2.8)
	_build_cave_pocket()
	_build_cold_store()


func _build_cave_pocket() -> void:
	# The deposit pocket is one route in three connected spaces: a 16 m approach
	# corridor with a bend, a 28 m gallery with failing strips, and a dark chamber
	# where the drop waits. The length is the point: the trip out is a walk with
	# nothing to do on it, so arriving somewhere reads as an arrival.
	var pocket_floor := _floor_material()
	pocket_floor.albedo_color = Color(0.29, 0.32, 0.33)
	pocket_floor.uv1_scale = Vector3(0.22, 0.22, 1.0)
	var pocket_wall := _material(Color(0.15, 0.19, 0.20), 0.96, 0.12)
	pocket_wall.albedo_texture = WALL_TEXTURE
	pocket_wall.uv1_scale = Vector3(1.10, 1.10, 1.0)

	# Approach corridor (x 24..40). Its south wall stops short, so the route bends
	# north into the gallery instead of running straight forever.
	_static_box(POCKET_CORRIDOR_CENTER + Vector3(0.0, -0.12, 0.0), Vector3(16.0, 0.24, 4.0), pocket_floor)
	_static_box(POCKET_CORRIDOR_CENTER + Vector3(0.0, 3.2, 0.0), Vector3(16.0, 0.20, 4.0), pocket_wall)
	_static_box(POCKET_CORRIDOR_CENTER + Vector3(0.0, 1.6, -2.0), Vector3(16.0, 3.2, 0.35), pocket_wall)
	_static_box(Vector3(31.0, 1.6, 0.0), Vector3(14.0, 3.2, 0.35), pocket_wall)
	# The corridor's east end is wall, not a hole into unloaded space. The only
	# way on is the three-metre slot north into the gallery.
	_static_box(Vector3(40.0, 1.6, -2.0), Vector3(0.35, 3.2, 4.0), pocket_wall)

	# Gallery (x 38..66, z 0..5).
	_static_box(POCKET_GALLERY_CENTER + Vector3(0.0, -0.12, 0.0), Vector3(28.0, 0.24, 5.0), pocket_floor)
	_static_box(POCKET_GALLERY_CENTER + Vector3(0.0, 3.2, 0.0), Vector3(28.0, 0.20, 5.0), pocket_wall)
	_static_box(POCKET_GALLERY_CENTER + Vector3(0.0, 1.6, 2.5), Vector3(28.0, 3.2, 0.35), pocket_wall)
	_static_box(Vector3(53.0, 1.6, 0.0), Vector3(26.0, 3.2, 0.35), pocket_wall)
	_static_box(Vector3(38.0, 1.6, 2.5), Vector3(0.35, 3.2, 5.0), pocket_wall)

	# Deposit chamber (x 66..76, z -1..6), with the breach cut into its north wall.
	_static_box(POCKET_CHAMBER_CENTER + Vector3(0.0, -0.12, 0.0), Vector3(10.0, 0.24, 7.0), pocket_floor)
	_static_box(POCKET_CHAMBER_CENTER + Vector3(0.0, 3.2, 0.0), Vector3(10.0, 0.20, 7.0), pocket_wall)
	_static_box(Vector3(67.5, 1.6, -1.0), Vector3(3.0, 3.2, 0.35), pocket_wall)
	_static_box(Vector3(73.5, 1.6, -1.0), Vector3(5.0, 3.2, 0.35), pocket_wall)
	_static_box(Vector3(70.0, 2.95, -1.0), Vector3(2.0, 0.50, 0.35), pocket_wall)
	_static_box(Vector3(67.5, 1.6, 6.0), Vector3(3.0, 3.2, 0.35), pocket_wall)
	_static_box(Vector3(74.0, 1.6, 6.0), Vector3(4.0, 3.2, 0.35), pocket_wall)
	_static_box(Vector3(70.5, 2.90, 6.0), Vector3(3.0, 0.60, 0.35), pocket_wall)
	_static_box(Vector3(76.0, 1.6, 2.5), Vector3(0.35, 3.2, 7.0), pocket_wall)
	# Two stubs of the chamber's west wall frame the mouth from the gallery, so the
	# opening reads as a doorway rather than the room simply stopping.
	_static_box(Vector3(66.0, 1.6, -0.5), Vector3(0.35, 3.2, 1.0), pocket_wall)
	_static_box(Vector3(66.0, 1.6, 5.5), Vector3(0.35, 3.2, 1.0), pocket_wall)

	# Nest nook (3 x 3 m) behind the breach: enough to look into, never a room yet.
	_static_box(POCKET_NEST_CENTER + Vector3(0.0, -0.12, 0.0), Vector3(3.0, 0.24, 3.0), pocket_floor)
	_static_box(POCKET_NEST_CENTER + Vector3(0.0, 3.2, 0.0), Vector3(3.0, 0.20, 3.0), pocket_wall)
	_static_box(Vector3(69.0, 1.6, 7.5), Vector3(0.35, 3.2, 3.0), pocket_wall)
	_static_box(Vector3(72.0, 1.6, 7.5), Vector3(0.35, 3.2, 3.0), pocket_wall)
	_static_box(Vector3(70.5, 1.6, 9.0), Vector3(3.0, 3.2, 0.35), pocket_wall)

	# Same repaired-wall language as the old cave, sparser: the pocket is further
	# from anywhere maintained.
	for index in 4:
		_add_prop(RUGGED_WALL_A if index % 2 == 0 else RUGGED_WALL_C,
			Vector3(41.5 + float(index) * 6.4, 0.0, 4.74), Vector3.ONE, PI)
	_add_prop(RUGGED_WALL_B, Vector3(44.6, 0.0, -0.28))
	_add_prop(RUGGED_WALL_C, Vector3(57.8, 0.0, -0.28))
	_add_prop(RUGGED_WALL_A, Vector3(64.9, 0.0, 4.74), Vector3.ONE, PI)
	_add_prop(RUGGED_WALL_B, Vector3(73.9, 0.0, -0.90), Vector3.ONE, PI)

	_add_cave_frost_cluster(Vector3(30.4, 0.09, -3.62), Vector3(0.86, 0.16, 0.10), 11)
	_add_cave_frost_cluster(Vector3(45.2, 0.08, 4.62), Vector3(1.05, 0.18, 0.12), 12)
	_add_cave_frost_cluster(Vector3(67.4, 0.09, -0.66), Vector3(0.74, 0.14, 0.10), 13)
	_add_cave_frost_cluster(Vector3(74.9, 0.10, 0.30), Vector3(0.92, 0.17, 0.11), 14)

	# Bootprints converging on the drop. Somebody else walks this route.
	var print_material := _material(Color(0.09, 0.11, 0.12), 0.86, 0.04)
	for index in 26:
		var along := float(index) / 25.0
		var path := Vector3(
			lerpf(41.8, TRADE_DROP_SPOT.x - 2.4, along),
			0.014,
			lerpf(2.35, TRADE_DROP_SPOT.z + 0.05, along) + sin(along * 6.0) * 0.16
		)
		var bootprint := _box_visual(Vector3(0.24, 0.012, 0.10), Color(0.09, 0.11, 0.12))
		bootprint.name = "PocketBootprint_%d" % index
		bootprint.material_override = print_material
		bootprint.position = path
		bootprint.rotation.y = deg_to_rad(6.0 if index % 2 == 0 else -4.0)
		add_child(bootprint)

	# Dropped satchel and pencil stub beside the drop: people stood here.
	var satchel := _box_visual(Vector3(0.34, 0.22, 0.18), Color(0.24, 0.20, 0.15))
	satchel.name = "PocketSatchel"
	satchel.position = TRADE_DROP_SPOT + Vector3(-0.85, 0.11, 0.55)
	satchel.rotation.y = deg_to_rad(24.0)
	add_child(satchel)
	var pencil := _box_visual(Vector3(0.17, 0.014, 0.014), Color(0.42, 0.33, 0.16))
	pencil.name = "PocketPencilStub"
	pencil.position = TRADE_DROP_SPOT + Vector3(-0.55, 0.012, 0.30)
	pencil.rotation.y = deg_to_rad(-38.0)
	add_child(pencil)

	# Chalk tally on the chamber wall: whoever uses the drop counts something.
	for index in 7:
		var tally := _box_visual(Vector3(0.012, 0.15, 0.012), Color(0.62, 0.60, 0.52))
		tally.name = "PocketChalkTally_%d" % index
		tally.position = Vector3(73.55 + float(index % 2) * 0.05, 1.62 + float(index) * 0.02, 5.78)
		tally.rotation.z = deg_to_rad(-12.0 + float(index) * 2.0)
		add_child(tally)
	for index in 2:
		var slash := _box_visual(Vector3(0.20, 0.012, 0.012), Color(0.62, 0.60, 0.52))
		slash.name = "PocketChalkSlash_%d" % index
		slash.position = Vector3(73.58, 1.52 + float(index) * 0.16, 5.78)
		slash.rotation.z = deg_to_rad(28.0)
		add_child(slash)

	# Light is the route's clock: one strip in the corridor, a warm lamp at the
	# bend, three strips in the gallery fading east, and nothing overhead in the
	# chamber. The dark is what makes the drop's own lamp the destination.
	_add_light(Vector3(29.6, 2.86, -2.10), Color(0.34, 0.44, 0.52), 0.30, 3.2)
	_add_light(Vector3(38.90, 1.40, 0.35), Color(0.72, 0.42, 0.16), 0.44, 3.6)
	_add_light(Vector3(44.00, 2.92, 2.40), Color(0.42, 0.56, 0.64), 0.40, 4.4)
	_add_light(Vector3(55.00, 2.92, 2.60), Color(0.42, 0.56, 0.64), 0.20, 3.4)
	_add_light(Vector3(64.50, 2.92, 2.40), Color(0.42, 0.56, 0.64), 0.11, 3.0)

	# A dead strip in the middle of the gallery: the gap is legible as a failure,
	# not as a shorter room, and it gives the walk a beat.
	var dead_strip := _box_visual(Vector3(0.86, 0.06, 0.16), Color(0.10, 0.11, 0.12))
	dead_strip.name = "PocketDeadStrip"
	dead_strip.position = Vector3(49.60, 2.94, 2.30)
	dead_strip.rotation.z = deg_to_rad(4.0)
	add_child(dead_strip)

	_build_pocket_landmarks()
	_build_trade_drop()
	_build_breach()
	_build_pocket_audio()


func _build_pocket_landmarks() -> void:
	# Three shapes the eye can hold from the drop, because the walk back is unlit
	# and there is no map. Each landmark owns a light or a silhouette edge, so it
	# reads at fog distance rather than only up close.
	_build_pocket_hopper()
	_build_pocket_spool()
	_build_pocket_pallets()
	_build_pocket_beacon()
	_build_pocket_wayfinding()


func _build_pocket_hopper() -> void:
	# A dead ore hopper, the pocket's biggest silhouette and the "this is the
	# deposit" marker. It stands just inside the mouth, so it is the first thing
	# seen coming in and the last thing passed going out.
	var hopper := StaticBody3D.new()
	hopper.name = "PocketOreHopper"
	hopper.position = Vector3(69.10, 0.0, 0.10)
	hopper.rotation.y = deg_to_rad(-6.0)
	add_child(hopper)
	var rust := _material(Color(0.29, 0.20, 0.14), 0.92, 0.30)
	var rust_dark := _material(Color(0.17, 0.13, 0.10), 0.94, 0.24)
	var cone := MeshInstance3D.new()
	var cone_mesh := CylinderMesh.new()
	cone_mesh.top_radius = 0.92
	cone_mesh.bottom_radius = 0.26
	cone_mesh.height = 1.05
	cone_mesh.radial_segments = 10
	cone.mesh = cone_mesh
	cone.position = Vector3(0.0, 1.62, 0.0)
	cone.material_override = rust
	hopper.add_child(cone)
	var chute := _box_visual(Vector3(0.34, 0.42, 0.34), Color(0.20, 0.16, 0.12))
	chute.position = Vector3(0.0, 1.12, 0.0)
	hopper.add_child(chute)
	for index in 4:
		var angle := float(index) * PI * 0.5 + 0.12
		var leg := _box_visual(Vector3(0.09, 1.16, 0.09), Color(0.20, 0.16, 0.12))
		leg.position = Vector3(cos(angle) * 0.62, 0.58, sin(angle) * 0.62)
		leg.rotation = Vector3(sin(angle) * 0.10, 0.0, -cos(angle) * 0.10)
		hopper.add_child(leg)
	for index in 5:
		var spill := MeshInstance3D.new()
		var mesh := SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 6
		mesh.rings = 3
		spill.mesh = mesh
		spill.position = Vector3(-0.30 + float(index % 3) * 0.26, 0.06 + float(index / 3) * 0.05, -0.34 + float(index % 2) * 0.30)
		spill.scale = Vector3(0.30, 0.16, 0.26)
		spill.rotation = Vector3(0.2 * float(index), 0.5 * float(index), 0.1)
		spill.material_override = rust_dark
		hopper.add_child(spill)
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.92
	shape.height = 2.10
	collision.shape = shape
	collision.position = Vector3(0.0, 1.05, 0.0)
	hopper.add_child(collision)


func _build_pocket_spool() -> void:
	# A cable spool on its side with its conduit trailing away: the chamber's round
	# silhouette, set opposite the drop so the room has two ends to hold onto.
	var spool := StaticBody3D.new()
	spool.name = "PocketCableSpool"
	spool.position = Vector3(74.05, 0.0, 4.55)
	spool.rotation.y = deg_to_rad(18.0)
	add_child(spool)
	var wood := _material(Color(0.32, 0.24, 0.16), 0.90, 0.05)
	var cable := _material(Color(0.09, 0.09, 0.10), 0.72, 0.18)
	for side in [-1.0, 1.0]:
		var cheek := MeshInstance3D.new()
		var cheek_mesh := CylinderMesh.new()
		cheek_mesh.top_radius = 0.62
		cheek_mesh.bottom_radius = 0.62
		cheek_mesh.height = 0.08
		cheek_mesh.radial_segments = 12
		cheek.mesh = cheek_mesh
		cheek.position = Vector3(0.0, 0.62, side * 0.26)
		cheek.rotation.x = PI * 0.5
		cheek.material_override = wood
		spool.add_child(cheek)
	var drum := MeshInstance3D.new()
	var drum_mesh := CylinderMesh.new()
	drum_mesh.top_radius = 0.40
	drum_mesh.bottom_radius = 0.40
	drum_mesh.height = 0.44
	drum_mesh.radial_segments = 12
	drum.mesh = drum_mesh
	drum.position = Vector3(0.0, 0.62, 0.0)
	drum.rotation.x = PI * 0.5
	drum.material_override = cable
	spool.add_child(drum)
	for index in 7:
		var coil := _box_visual(Vector3(0.42, 0.05, 0.05), Color(0.12, 0.12, 0.13))
		coil.position = Vector3(-0.55 - float(index) * 0.36, 0.06, 0.55 + sin(float(index) * 0.9) * 0.22)
		coil.rotation.y = 0.22 * float(index)
		spool.add_child(coil)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.30, 1.24, 0.66)
	collision.shape = shape
	collision.position = Vector3(0.0, 0.62, 0.0)
	spool.add_child(collision)


func _build_pocket_pallets() -> void:
	# A leaning stack of split pallets under the breach, so the warm glow there has
	# a shape beneath it instead of floating on the wall.
	var stack := StaticBody3D.new()
	stack.name = "PocketPalletStack"
	stack.position = Vector3(72.70, 0.0, 4.95)
	stack.rotation.y = deg_to_rad(-9.0)
	add_child(stack)
	var plank := _material(Color(0.30, 0.25, 0.17), 0.93, 0.04)
	for index in 6:
		var board := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.86, 0.055, 0.42)
		board.mesh = mesh
		board.position = Vector3(0.0, 0.03 + float(index) * 0.075, 0.0)
		board.rotation = Vector3(0.0, 0.16 * float(index % 3), 0.05 * float(index % 2))
		board.material_override = plank
		stack.add_child(board)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.95, 0.52, 0.55)
	collision.shape = shape
	collision.position = Vector3(0.0, 0.26, 0.0)
	stack.add_child(collision)


func _build_pocket_beacon() -> void:
	# One warm hand lamp on a bent post at the mouth. It is the only light the
	# chamber owns, so the way out is a warm vertical shape in the dark rather
	# than a guess at where the fog thins.
	var post := Node3D.new()
	post.name = "PocketBeacon"
	post.position = Vector3(66.95, 0.0, 4.35)
	add_child(post)
	var metal := Color(0.18, 0.17, 0.15)
	var pole := _box_visual(Vector3(0.07, 1.55, 0.07), metal)
	pole.position = Vector3(0.0, 0.78, 0.0)
	post.add_child(pole)
	var arm := _box_visual(Vector3(0.34, 0.06, 0.06), metal)
	arm.position = Vector3(0.15, 1.52, 0.0)
	post.add_child(arm)
	var cage := MeshInstance3D.new()
	var cage_mesh := SphereMesh.new()
	cage_mesh.radius = 0.13
	cage_mesh.height = 0.24
	cage_mesh.radial_segments = 6
	cage_mesh.rings = 3
	cage.mesh = cage_mesh
	cage.name = "PocketBeaconGlobe"
	cage.position = Vector3(0.32, 1.38, 0.0)
	var glass := _material(Color(0.86, 0.58, 0.24), 0.40, 0.10)
	glass.emission_enabled = true
	glass.emission = Color(0.86, 0.42, 0.12)
	glass.emission_energy_multiplier = 1.7
	cage.material_override = glass
	post.add_child(cage)
	_add_light(Vector3(67.27, 1.38, 4.35), Color(0.92, 0.52, 0.20), 0.58, 4.6)


func _build_pocket_wayfinding() -> void:
	# The walk back is the part of the errand nobody can read from a map, so the
	# route is painted once by maintenance: worn dashes leave the drop, pass the
	# hopper, cross the gallery and turn down the corridor at the bend. They are
	# faded on purpose — old floor marking, not a quest arrow.
	var paint := _material(Color(0.52, 0.36, 0.16), 0.88, 0.02)
	var route: Array[Vector3] = [
		Vector3(74.10, 0.0, 2.30),
		Vector3(70.20, 0.0, 2.20),
		Vector3(67.60, 0.0, 2.30),
		Vector3(66.20, 0.0, 2.30),
		Vector3(62.00, 0.0, 1.45),
		Vector3(48.00, 0.0, 1.45),
		Vector3(40.40, 0.0, 1.30),
		Vector3(38.70, 0.0, 0.30),
		Vector3(38.40, 0.0, -1.60),
		Vector3(30.00, 0.0, -1.80),
		Vector3(25.20, 0.0, -1.80),
	]
	var dash_index := 0
	for index in route.size() - 1:
		var from: Vector3 = route[index]
		var to: Vector3 = route[index + 1]
		var direction := (to - from).normalized()
		var steps := maxi(int(from.distance_to(to) / 1.30), 1)
		for step in steps:
			var point: Vector3 = from.lerp(to, (float(step) + 0.5) / float(steps))
			var dash := _box_visual(Vector3(0.34, 0.010, 0.14), Color(0.52, 0.36, 0.16))
			dash.name = "PocketPaintDash_%d" % dash_index
			dash.material_override = paint
			dash.position = Vector3(point.x, 0.020, point.z)
			dash.rotation.y = atan2(-direction.z, direction.x)
			add_child(dash)
			dash_index += 1

	# Two stencils, both readable from the wrong side of the room: the mouth sign
	# answers "which way is out", the bend sign answers "which way is home".
	_pocket_sign("Mouth", "C-4\nOUT  <", Vector3(66.14, 2.42, 2.50), -PI * 0.5, 0.78, true)
	_pocket_sign("Bend", "FURNACE  <", Vector3(38.22, 2.36, 1.00), PI * 0.5, 0.92)


func _pocket_sign(id: String, text_value: String, position_value: Vector3, rotation_y: float, width: float, hang: bool = false) -> void:
	var plate := _box_visual(Vector3(width, 0.42, 0.03), Color(0.13, 0.15, 0.15))
	plate.name = "PocketSignPlate_" + id
	plate.position = position_value
	plate.rotation.y = rotation_y
	add_child(plate)
	if hang:
		# The mouth has no wall to bolt to, so the sign hangs off two rods from the
		# ceiling rather than floating in the opening.
		for offset in [-0.28, 0.28]:
			var rod := _box_visual(Vector3(0.025, 0.68, 0.025), Color(0.18, 0.17, 0.15))
			rod.position = position_value + Vector3(cos(rotation_y) * offset, 0.55, -sin(rotation_y) * offset)
			add_child(rod)
	var label := Label3D.new()
	label.name = "PocketSignText_" + id
	label.text = text_value
	label.position = position_value + Vector3(sin(rotation_y), 0.0, cos(rotation_y)) * 0.026
	label.rotation.y = rotation_y
	label.font_size = 36
	label.outline_size = 5
	label.pixel_size = 0.0045
	label.modulate = Color(0.90, 0.58, 0.22)
	add_child(label)

func _build_pocket_audio() -> void:
	# Place the three sounds the pocket owns. The draft sits in the corridor, the
	# drop's tone sits on the clamp, and the drips are spread across the gallery
	# and chamber ceiling so each one names the room it fell in.
	pocket_audio = PocketAudio.new()
	pocket_audio.name = "PocketAudio"
	add_child(pocket_audio)
	pocket_audio.place(
		Vector3(32.0, 1.30, -1.70),
		TRADE_DROP_SPOT + Vector3(0.0, 1.15, 0.0),
		[
			Vector3(43.5, 2.88, 1.20),
			Vector3(57.2, 2.88, 3.90),
			Vector3(69.4, 2.88, 0.90),
			Vector3(73.2, 2.88, 4.40),
		]
	)


func _build_trade_drop() -> void:
	trade_drop_body = StaticBody3D.new()
	trade_drop_body.name = "CaveTradeDrop"
	trade_drop_body.position = TRADE_DROP_SPOT
	trade_drop_body.rotation.y = PI * 0.5
	trade_drop_body.set_meta("kind", "drop")
	trade_drop_body.set_meta("label", "TRADE DROP")
	add_child(trade_drop_body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.15, 0.90, 0.90)
	collision.shape = shape
	collision.position = Vector3(0.0, 0.46, 0.0)
	trade_drop_body.add_child(collision)
	var visual: Node3D = CAVE_TRADE_DROP_MODEL.instantiate() as Node3D
	if visual != null:
		visual.name = "CaveTradeDropModel"
		trade_drop_body.add_child(visual)
	interactables.append(trade_drop_body)
	_add_light(TRADE_DROP_SPOT + Vector3(-1.45, 1.75, 0.0), Color(0.72, 0.44, 0.20), 0.26, 3.2)
	_build_drop_papers()


func _build_drop_papers() -> void:
	# The paper itself is the only reason to walk out here, so it is a real object
	# on the clamp rather than a line in a menu. Count and torn state are shown,
	# not written out.
	drop_paper = _box_visual(Vector3(0.26, 0.010, 0.34), Color(0.80, 0.78, 0.70))
	drop_paper.name = "PocketDropPaper"
	drop_paper.position = TRADE_DROP_SPOT + Vector3(-0.22, 0.955, 0.02)
	drop_paper.rotation = Vector3(0.0, PI * 0.5 + 0.18, 0.0)
	add_child(drop_paper)
	drop_paper_second = _box_visual(Vector3(0.24, 0.008, 0.32), Color(0.74, 0.72, 0.63))
	drop_paper_second.name = "PocketDropPaperSecond"
	drop_paper_second.position = TRADE_DROP_SPOT + Vector3(-0.25, 0.966, -0.03)
	drop_paper_second.rotation = Vector3(0.0, PI * 0.5 - 0.11, 0.0)
	add_child(drop_paper_second)
	# A torn paper is two halves pulled apart, so the state is legible at a glance
	# from the gallery mouth.
	drop_paper_torn = Node3D.new()
	drop_paper_torn.name = "PocketDropPaperTorn"
	drop_paper_torn.position = TRADE_DROP_SPOT + Vector3(-0.22, 0.958, 0.02)
	add_child(drop_paper_torn)
	var left := _box_visual(Vector3(0.16, 0.010, 0.34), Color(0.72, 0.68, 0.58))
	left.position = Vector3(-0.10, 0.0, 0.05)
	left.rotation = Vector3(0.0, 0.22, 0.0)
	drop_paper_torn.add_child(left)
	var right := _box_visual(Vector3(0.10, 0.010, 0.34), Color(0.68, 0.64, 0.54))
	right.position = Vector3(0.12, 0.002, -0.06)
	right.rotation = Vector3(0.0, -0.34, 0.0)
	drop_paper_torn.add_child(right)
	# The paper is the generated order note, not a blank card: the terms are on it
	# even when the player is still too far away to read them.
	for paper in [drop_paper, drop_paper_second, left, right]:
		_apply_note_texture(paper)
	drop_paper.visible = false
	drop_paper_second.visible = false
	drop_paper_torn.visible = false


func _apply_note_texture(paper: Node3D) -> void:
	if paper == null:
		return
	var mesh_instance := paper as MeshInstance3D
	if mesh_instance == null:
		return
	var material := mesh_instance.material_override as StandardMaterial3D
	if material == null:
		return
	material.albedo_texture = ORDER_NOTE_TEXTURE
	material.roughness = 0.92
	material.metallic = 0.0


## Cheap signature check: the drop's paper state only changes when a paper is
## taken, rolled, or expires, so the meshes are not touched every frame.
func _refresh_drop_papers() -> void:
	if drop_paper == null or farm == null:
		return
	var count: int = farm.cave_paper_count()
	var torn: bool = farm.cave_has_torn_paper()
	var signature := "%d|%s" % [count, str(torn)]
	if signature == drop_paper_signature:
		return
	drop_paper_signature = signature
	drop_paper.visible = count > 0 and not torn
	drop_paper_second.visible = count > 1 and not torn
	drop_paper_torn.visible = count > 0 and torn


func _build_breach() -> void:
	breach_body = StaticBody3D.new()
	breach_body.name = "NestBreach"
	breach_body.position = BREACH_SPOT
	breach_body.set_meta("kind", "breach")
	breach_body.set_meta("label", "BREACH — LOOK INSIDE")
	add_child(breach_body)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.60, 2.10, 0.70)
	collision.shape = shape
	collision.position = Vector3(0.0, 1.05, 0.10)
	breach_body.add_child(collision)
	var visual: Node3D = NEST_BREACH_MODEL.instantiate() as Node3D
	if visual != null:
		visual.name = "NestBreachModel"
		breach_body.add_child(visual)
	interactables.append(breach_body)
	breach_light = _light_node(BREACH_SPOT + Vector3(0.0, 1.05, -0.55), Color(0.92, 0.34, 0.08), 0.78, 4.6)
	add_child(breach_light)


func _add_cave_frost_cluster(position_value: Vector3, scale_value: Vector3, seed: int) -> void:
	# Frost is deliberately chunky and mineral rather than a flat cyan decal.
	# A few low, asymmetrical deposits make temperature readable at walking pace.
	var frost := MeshInstance3D.new()
	frost.name = "CaveFrost_%d" % seed
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 7
	mesh.rings = 4
	frost.mesh = mesh
	frost.position = position_value
	frost.scale = scale_value
	frost.rotation = Vector3(0.12 * float(seed), 0.34 * float(seed), -0.08 * float(seed))
	var material := _material(Color(0.24, 0.43, 0.48), 0.72, 0.02)
	material.emission_enabled = true
	material.emission = Color(0.006, 0.018, 0.024)
	material.emission_energy_multiplier = 0.24
	frost.material_override = material
	add_child(frost)


func _build_cave_collapse() -> void:
	# The first tunnel ends at a genuine collapse, not an arbitrary invisible
	# border. It frames the next cave milestone as a route to excavate later and
	# makes the current return path obvious under pressure.
	var collapse := Node3D.new()
	collapse.name = "ColdJunctionCollapse"
	collapse.position = CAVE_COLLAPSE_SPOT
	add_child(collapse)
	var rubble_material := _material(Color(0.21, 0.25, 0.25), 0.94, 0.04)
	var frost_material := _material(Color(0.40, 0.60, 0.64), 0.42, 0.06)
	for index in 9:
		var rock := MeshInstance3D.new()
		rock.name = "CollapseRubble_%d" % index
		var mesh := SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 7
		mesh.rings = 4
		rock.mesh = mesh
		# Keep the rubble on the player side of the collision wall so the pile
		# visibly explains the blocked route instead of clipping through it.
		var x_offset := -0.34 + float(index % 3) * 0.075
		var y_offset := 0.18 + float(index / 3) * 0.27
		var z_offset := -1.18 + float(index % 4) * 0.68
		rock.position = Vector3(x_offset, y_offset, z_offset)
		rock.scale = Vector3(0.58 + float(index % 2) * 0.16, 0.44 + float(index % 3) * 0.13, 0.48 + float(index % 4) * 0.07)
		rock.rotation = Vector3(0.21 * float(index), 0.44 * float(index), -0.16 * float(index))
		rock.material_override = frost_material if index in [1, 5, 8] else rubble_material
		collapse.add_child(rock)
	var warning := Label3D.new()
	warning.name = "CollapseStencil"
	warning.text = "ROUTE C-4  //  DUG THROUGH"
	warning.position = Vector3(-0.23, 2.38, 0.0)
	warning.rotation.y = -PI * 0.5
	warning.font_size = 42
	warning.outline_size = 6
	warning.pixel_size = 0.006
	warning.modulate = Color(0.78, 0.43, 0.17)
	collapse.add_child(warning)


func _build_cave_return_wheel() -> void:
	# A real exterior-side release means the player cannot accidentally trap
	# themself in the cave if the hunt shutter gets seated behind them.
	cave_return_wheel = StaticBody3D.new()
	cave_return_wheel.name = "CaveReturnWheel"
	cave_return_wheel.position = CAVE_RETURN_WHEEL_SPOT
	cave_return_wheel.set_meta("kind", "cave_wheel")
	cave_return_wheel.set_meta("label", "CAVE-SIDE WHEEL // OPEN SHUTTER")
	add_child(cave_return_wheel)
	interactables.append(cave_return_wheel)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.62, 0.72, 0.18)
	collision.shape = shape
	collision.position = Vector3(0.0, 0.0, -0.04)
	cave_return_wheel.add_child(collision)
	var plate := _box_visual(Vector3(0.55, 0.68, 0.10), Color(0.20, 0.25, 0.26), false)
	plate.position = Vector3(0.0, 0.0, -0.05)
	cave_return_wheel.add_child(plate)
	var wheel := MeshInstance3D.new()
	wheel.name = "CaveWheelVisual"
	var wheel_mesh := TorusMesh.new()
	wheel_mesh.inner_radius = 0.12
	wheel_mesh.outer_radius = 0.27
	wheel_mesh.rings = 8
	wheel_mesh.ring_segments = 6
	wheel.mesh = wheel_mesh
	wheel.position = Vector3(0.0, 0.0, 0.10)
	wheel.rotation.x = PI * 0.5
	wheel.material_override = _material(Color(0.45, 0.22, 0.12), 0.82, 0.55)
	cave_return_wheel.add_child(wheel)
	for index in 4:
		var spoke := _box_visual(Vector3(0.045, 0.40, 0.045), Color(0.32, 0.37, 0.37), false)
		spoke.position = Vector3(0.0, 0.0, 0.105)
		spoke.rotation.z = float(index) * PI * 0.5
		cave_return_wheel.add_child(spoke)
	var label := Label3D.new()
	label.text = "RETURN\nWHEEL"
	label.position = Vector3(0.0, 0.46, 0.12)
	label.font_size = 30
	label.outline_size = 4
	label.pixel_size = 0.004
	label.modulate = Color(0.88, 0.55, 0.20)
	cave_return_wheel.add_child(label)


func _build_cave_marker() -> void:
	# The first sign keeps the new route legible without replacing exploration
	# with objective arrows. It explains the reliable return rule in-world.
	cave_marker = _static_box(CAVE_MARKER_SPOT, Vector3(0.84, 0.64, 0.10), _material(Color(0.19, 0.24, 0.25), 0.72, 0.62))
	cave_marker.name = "CaveRouteMarker"
	cave_marker.set_meta("kind", "cave_marker")
	cave_marker.set_meta("label", "B-01 RETURN MARKER")
	interactables.append(cave_marker)
	var label := Label3D.new()
	label.text = "B-01\nFURNACE  <"
	label.position = Vector3(0.0, 0.0, 0.065)
	label.font_size = 34
	label.outline_size = 4
	label.pixel_size = 0.004
	label.modulate = Color(0.78, 0.66, 0.42)
	cave_marker.add_child(label)


# C4 cold store: a root cellar north of the corridor, reached through the
# junction alcove. Its footprint is moved north of the corridor's north wall
# (z -4.0 to -8.5) because the spec's z -4.0..0.0 overlaps the wall.
func _build_cold_store() -> void:
	var store_floor := _floor_material()
	store_floor.albedo_color = Color(0.22, 0.25, 0.26)
	store_floor.uv1_scale = Vector3(0.18, 0.18, 1.0)
	var store_wall := _material(Color(0.13, 0.17, 0.18), 0.96, 0.12)
	store_wall.albedo_texture = WALL_TEXTURE
	store_wall.uv1_scale = Vector3(0.90, 0.90, 1.0)

	# Room shell: x 13.5..18.5, z -8.5..-4.0. The south wall is the corridor's
	# north wall, so only the other three sides are built here. The doorway is
	# the existing junction-alcove gap (x 16.1..20.2) in that wall.
	_static_box(COLD_STORE_CENTER + Vector3(0.0, -0.12, 0.0), Vector3(5.0, 0.24, 4.5), store_floor)
	_static_box(COLD_STORE_CENTER + Vector3(0.0, 3.2, 0.0), Vector3(5.0, 0.20, 4.5), store_wall)
	_static_box(Vector3(13.25, 1.6, -6.25), Vector3(0.35, 3.2, 4.5), store_wall)
	_static_box(Vector3(18.75, 1.6, -6.25), Vector3(0.35, 3.2, 4.5), store_wall)
	_static_box(Vector3(16.0, 1.6, -8.75), Vector3(5.5, 3.2, 0.35), store_wall)

	# Props, placed against the walls, each built through the Basement pipeline.
	var jar_shelf := COLD_STORE_JAR_SHELF_MODEL.instantiate() as Node3D
	if jar_shelf != null:
		jar_shelf.name = "ColdStoreJarShelf"
		jar_shelf.position = Vector3(13.85, 0.0, -6.25)
		jar_shelf.rotation.y = PI * 0.5
		add_child(jar_shelf)
	var cold_frame := COLD_STORE_COLD_FRAME_MODEL.instantiate() as Node3D
	if cold_frame != null:
		cold_frame.name = "ColdStoreColdFrame"
		cold_frame.position = Vector3(16.0, 0.0, -7.6)
		add_child(cold_frame)
	var drain_grate := COLD_STORE_DRAIN_GRATE_MODEL.instantiate() as Node3D
	if drain_grate != null:
		drain_grate.name = "ColdStoreDrainGrate"
		drain_grate.position = Vector3(16.0, 0.0, -5.2)
		add_child(drain_grate)
	var sealed_crate := COLD_STORE_SEALED_CRATE_MODEL.instantiate() as Node3D
	if sealed_crate != null:
		sealed_crate.name = "ColdStoreSealedCrate"
		sealed_crate.position = Vector3(18.0, 0.0, -7.8)
		sealed_crate.rotation.y = -PI * 0.5
		add_child(sealed_crate)

	# Doorway dressing: jambs, a worn threshold plate and the door's own weak
	# bulb, so the opening reads from the corridor before you are inside.
	for side in [-1.0, 1.0]:
		var jamb := _box_visual(Vector3(0.16, 2.38, 0.42), Color(0.12, 0.15, 0.16))
		jamb.name = "ColdStoreDoorJamb_%s" % ("W" if side < 0.0 else "E")
		jamb.position = Vector3(16.0 + side * 0.88, 1.19, -4.0)
		add_child(jamb)
	var threshold := _box_visual(Vector3(1.72, 0.020, 0.46), Color(0.20, 0.22, 0.22))
	threshold.name = "ColdStoreThreshold"
	threshold.position = Vector3(16.0, 0.012, -4.02)
	add_child(threshold)
	_add_prop(RUGGED_WALL_C, Vector3(16.0, 0.0, -8.52), Vector3.ONE, PI)
	_add_prop(RUGGED_WALL_A, Vector3(13.46, 0.0, -6.25), Vector3.ONE, PI * 0.5)
	_add_cave_frost_cluster(Vector3(14.2, 0.08, -7.9), Vector3(0.80, 0.15, 0.10), 21)
	_add_cave_frost_cluster(Vector3(18.1, 0.09, -4.55), Vector3(0.62, 0.12, 0.09), 22)
	_add_light(Vector3(16.0, 2.35, -4.85), Color(0.55, 0.70, 0.74), 0.55, 3.4)
	_add_light(COLD_STORE_CENTER + Vector3(0.0, 2.4, 0.0), Color(0.42, 0.55, 0.60), 0.62, 4.2)

	# Interactables. The three intact jars sit on the shelf; the breakable jars are
	# scenery. Each is a body with a kind, so it uses the same prompt and dispatch
	# as the cave cart.
	for jar_index in FarmState.COLD_STORE_JAR_COUNT:
		# The bodies sit just proud of the shelf front, so the prompt targets the
		# jar the player is looking at rather than the shelf behind it.
		var jar := _static_box(Vector3(14.16, 1.05, -5.6 - 0.7 * float(jar_index)), Vector3(0.30, 0.40, 0.30), store_wall)
		jar.name = "ColdStoreJar_%d" % jar_index
		jar.set_meta("kind", "cold_jar")
		jar.set_meta("index", jar_index)
		jar.set_meta("label", "JAR")
		interactables.append(jar)
	cold_crate = _static_box(COLD_STORE_CRATE_SPOT, Vector3(0.66, 0.72, 0.48), store_wall)
	cold_crate.name = "ColdStoreCrateBody"
	cold_crate.set_meta("kind", "cold_crate")
	cold_crate.set_meta("label", "SEALED CRATE")
	interactables.append(cold_crate)
	cold_frame_body = _static_box(COLD_STORE_FRAME_SPOT, Vector3(1.10, 0.60, 0.70), store_wall)
	cold_frame_body.name = "ColdStoreFrameBody"
	cold_frame_body.set_meta("kind", "cold_frame")
	cold_frame_body.set_meta("label", "COLD FRAME")
	interactables.append(cold_frame_body)


func _drop_held_chain_link() -> void:
	if player == null or farm.chain_links <= 0 or chain_install_elapsed >= 0.0:
		return
	var forward: Vector3 = -player.global_transform.basis.z
	var origin: Vector3 = player.global_position + Vector3.UP * 0.5
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * 0.65, 1, [player.get_rid()])
	var wall: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	var point: Vector3 = origin + forward * 0.65 if wall.is_empty() else (wall["position"] as Vector3) - forward * 0.15
	query = PhysicsRayQueryParameters3D.create(point + Vector3.UP * 0.3, point - Vector3.UP * 4.0, 1, [player.get_rid()])
	var floor_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if floor_hit.is_empty() or (floor_hit["normal"] as Vector3).y < 0.65:
		show_message("NO SAFE SURFACE FOR THE LINK", 1.6)
		return
	var item: Dictionary = farm.drop_chain_link((floor_hit["position"] as Vector3) + Vector3.UP * 0.022)
	if item.is_empty():
		return
	_spawn_saved_pickup(item)
	player.set_link_carried(farm.chain_links > 0)
	show_message("CHAIN LINK PLACED", 1.6)


func _spawn_saved_pickup(record: Dictionary) -> void:
	var id := int(record["id"])
	if world_pickup_views.has(id):
		return
	var pickup := PhysicalPickup.new()
	pickup.configure(record)
	add_child(pickup)
	interactables.append(pickup)
	world_pickup_views[id] = pickup


func _restore_world_pickups() -> void:
	for node in world_pickup_views.values():
		if is_instance_valid(node):
			interactables.erase(node)
			remove_child(node)
			node.queue_free()
	world_pickup_views.clear()
	for record in farm.world_items:
		_spawn_saved_pickup(record)


func _pick_up_chain_link(target: Node3D) -> void:
	var id := int(target.get_meta("world_item_id", -1))
	if not farm.pick_up_world_item(id):
		return
	world_pickup_views.erase(id)
	interactables.erase(target)
	target.queue_free()
	player.set_link_carried(true)
	show_message("CHAIN LINK RECOVERED", 1.6)


func _use_cold_jar(index: int) -> void:
	show_message(farm.search_cold_store_jar(index), 2.6)


func _use_cold_crate() -> void:
	show_message(farm.open_cold_store_crate(), 3.0)


func _use_cold_frame() -> void:
	show_message(farm.cold_frame_action(), 3.0)


## The frame is one verb whose prompt changes as it is fitted and filled.
func _cold_frame_prompt() -> String:
	if not farm.cold_frame_installed:
		return "FIT PATCH"
	if farm.cold_frame_meal:
		return "EAT FROM FRAME"
	return "STORE MEAL"


func _build_cave_cart() -> void:
	# The cart lives in the Cold Junction alcove rather than blocking the return
	# corridor. It supplies a strong physical landmark and an environmental clue
	# about who maintained this route before the house became a refuge.
	cave_cart = _static_box(Vector3(18.25, 0.60, 1.72), Vector3(1.55, 1.20, 1.24), _material(Color(0.12, 0.16, 0.17), 0.88, 0.20))
	cave_cart.name = "FrozenMaintenanceCartBody"
	cave_cart.set_meta("kind", "cave_cart")
	cave_cart.set_meta("label", "FROZEN SERVICE CART")
	interactables.append(cave_cart)
	var model := _attach_model_to_body(cave_cart, FROZEN_MAINTENANCE_CART_MODEL, Vector3(0.0, -0.60, 0.0))
	if model != null:
		model.name = "FrozenMaintenanceCart"
	var label := Label3D.new()
	label.text = "C-4\nSERVICE CART"
	label.position = Vector3(0.0, 0.84, -0.66)
	# The cart is approached from the south side of the alcove, so turn the
	# stencil outward instead of showing its mirrored back to the player.
	label.rotation.y = PI
	label.font_size = 28
	label.outline_size = 4
	label.pixel_size = 0.004
	label.modulate = Color(0.70, 0.54, 0.29)
	cave_cart.add_child(label)
	_add_light(Vector3(18.38, 1.45, 1.38), Color(0.72, 0.34, 0.10), 0.40, 2.5)
	_build_cave_regulator_pickup()


func _build_cave_regulator_pickup() -> void:
	# This is deliberately its own small, non-blocking interaction point instead
	# of making the whole cart a generic loot crate. It is visible on the cart
	# before recovery, then becomes a real model beside the furnace after fitting.
	cave_regulator_pickup = Node3D.new()
	cave_regulator_pickup.name = "C4ThermalRegulatorPickup"
	cave_regulator_pickup.position = CAVE_REGULATOR_SPOT
	cave_regulator_pickup.set_meta("kind", "thermal_regulator")
	cave_regulator_pickup.set_meta("label", "THERMAL REGULATOR — SALVAGE")
	add_child(cave_regulator_pickup)
	interactables.append(cave_regulator_pickup)
	var regulator: Node3D = FURNACE_HEAT_RECLAIMER_MODEL.instantiate() as Node3D
	if regulator != null:
		regulator.name = "RecoveredThermalRegulator"
		regulator.scale = Vector3.ONE * 0.54
		# The service face points down the approach lane: the player can read the
		# gauge and recovery pipes before the prompt tells them what it is.
		regulator.rotation.y = 0.0
		cave_regulator_pickup.add_child(regulator)
	var glint := _light_node(Vector3(0.10, 0.42, -0.12), Color(0.90, 0.48, 0.16), 0.32, 1.8)
	cave_regulator_pickup.add_child(glint)
	_refresh_cave_regulator_pickup()


func _refresh_cave_regulator_pickup() -> void:
	if farm == null:
		return
	var available := farm.thermal_regulators <= 0 and not farm.heat_reclaimer_installed
	if cave_regulator_pickup != null:
		cave_regulator_pickup.visible = available
	if cave_cart != null:
		cave_cart.set_meta("label", "C-4 SERVICE CART — RECOVERED" if not available else "C-4 SERVICE CART")


func _add_rugged_wall_bays() -> void:
	# The collision shell stays simple, but the dressed face alternates intact
	# repairs, ripped-out panels and wet masonry. Sparse side bays leave breathing
	# room for the underlying damp wall instead of turning the basement into pipes.
	var back_bays: Array[PackedScene] = [RUGGED_WALL_A, RUGGED_WALL_B, RUGGED_WALL_C, RUGGED_WALL_B, RUGGED_WALL_A]
	for index in back_bays.size():
		_add_prop(back_bays[index], Vector3(-4.0 + float(index) * 2.0, 0.0, -4.74))
	var left_bays: Array[PackedScene] = [RUGGED_WALL_C, RUGGED_WALL_B, RUGGED_WALL_A]
	for index in left_bays.size():
		_add_prop(left_bays[index], Vector3(-5.74, 0.0, -2.8 + float(index) * 2.8), Vector3.ONE, PI * 0.5)
	var right_bays: Array[PackedScene] = [RUGGED_WALL_B, RUGGED_WALL_C]
	for index in right_bays.size():
		_add_prop(right_bays[index], Vector3(5.74, 0.0, 0.8 + float(index) * 2.6), Vector3.ONE, -PI * 0.5)

func _build_stations() -> void:
	# Furnace.
	var furnace := _static_box(FURNACE_SPOT + Vector3(0, 0.9, 0), Vector3(1.4, 1.8, 1.0), _material(Color(0.13, 0.11, 0.10), 0.6, 0.5))
	var furnace_visual: Node3D = _attach_model_to_body(furnace, FURNACE_MODEL, Vector3(0.0, -0.90, 0.0))
	if furnace_visual != null:
		furnace_visual.name = "MakeshiftFurnaceModel"
		furnace_door = furnace_visual.find_child("FurnaceDoorPivot", true, false) as Node3D
		furnace_flame_core = furnace_visual.find_child("FurnaceFlameCore", true, false) as Node3D
	furnace.set_meta("kind", "furnace")
	furnace.set_meta("label", "FURNACE — OPEN / FEED")
	interactables.append(furnace)
	_add_furnace_smoke()
	_build_furnace_heat_reclaimer()

	# Butcher table.
	var table := _static_box(Vector3(-3.4, 0.45, -0.2), Vector3(1.8, 0.9, 1.1), _material(Color(0.30, 0.22, 0.14), 0.85, 0.0))
	var table_visual: Node3D = _attach_model_to_body(table, BUTCHER_TABLE_MODEL, Vector3(0.0, -0.45, 0.0))
	if table_visual != null:
		table_visual.name = "ButcherTableModel"
	table.set_meta("kind", "table")
	table.set_meta("label", "BUTCHER TABLE — PROCESS CARRIED KILL")
	interactables.append(table)

	# Packaging bench.
	var bench := _static_box(Vector3(3.6, 0.45, -0.2), Vector3(1.8, 0.9, 1.1), _material(Color(0.26, 0.24, 0.20), 0.7, 0.2))
	var bench_visual: Node3D = _attach_model_to_body(bench, PACKAGING_BENCH_MODEL, Vector3(0.0, -0.45, 0.0))
	if bench_visual != null:
		bench_visual.name = "PackagingBenchModel"
	bench.set_meta("kind", "bench")
	bench.set_meta("label", "PACKAGING BENCH — PACK ORDER")
	interactables.append(bench)
	order_box_bench = _build_order_box(bench, "PackedOrderBox")
	order_box_bench.position = Vector3(0.0, 0.52, 0.0)

	# The craft station is a real procedural prop, generated alongside the slime
	# asset. It is separate from packing so each table has one honest purpose:
	# butcher a kill, shape survival gear, then pack goods for an order.
	var workbench := _static_box(WORKBENCH_SPOT + Vector3(0.0, 0.66, 0.0), Vector3(1.85, 1.32, 0.98), _material(Color(0.18, 0.15, 0.12), 0.88, 0.12))
	var workbench_visual: Node3D = _attach_model_to_body(workbench, SALVAGED_WORKBENCH_MODEL, Vector3(0.0, -0.66, 0.0))
	if workbench_visual != null:
		workbench_visual.name = "SalvagedWorkbenchModel"
	workbench.set_meta("kind", "workbench")
	workbench.set_meta("label", "SALVAGE WORKBENCH — CRAFT GEAR")
	interactables.append(workbench)
	_add_light(WORKBENCH_SPOT + Vector3(0.46, 1.18, -0.03), Color(1.0, 0.54, 0.18), 0.58, 2.5)

	# C2 // the culture kitchen: where crickets become meal and jerky.
	_build_kitchen_bench()

	# Order slate and upgrade ledger.
	_add_prop(CONSOLE, Vector3(-1.0, 0, 4.5))
	var slate := Node3D.new()
	slate.position = Vector3(-1.0, 0.9, 4.4)
	slate.set_meta("kind", "slate")
	slate.set_meta("label", "ORDER SLATE")
	add_child(slate)
	interactables.append(slate)

	_add_prop(CONSOLE, Vector3(2.4, 0, 4.5), Vector3(0.9, 0.9, 0.9))
	var ledger := Node3D.new()
	ledger.position = Vector3(2.4, 0.9, 4.4)
	ledger.set_meta("kind", "ledger")
	ledger.set_meta("label", "UPGRADE LEDGER")
	add_child(ledger)
	interactables.append(ledger)

	# Stair door (locked) and bed.
	var stair := _static_box(Vector3(0.7, 1.5, 4.93), Vector3(1.6, 3.0, 0.18), _material(Color(0.24, 0.14, 0.09), 0.9, 0.1))
	stair.set_meta("kind", "stair")
	stair.set_meta("label", "STAIR DOOR [LOCKED]")
	interactables.append(stair)

	# The cot is now flush to the rear wall, leaving a clean, walkable front edge.
	# Its kit moves forward on the left wall instead of clipping through the bed.
	var bed := _static_box(BED_SPOT, Vector3(1.3, 0.56, 2.0), _material(Color(0.20, 0.17, 0.16), 0.95, 0.0))
	var bed_visual: Node3D = _attach_model_to_body(bed, SALVAGED_COT_MODEL, Vector3(0.0, -0.28, 0.0))
	if bed_visual != null:
		bed_visual.name = "SalvagedCotModel"
	bed.set_meta("kind", "bed")
	bed.set_meta("label", "BED — SLEEP TO NEXT MORNING")
	interactables.append(bed)
	_build_bedside_kit()

	# Rations crate (eat).
	var crate := _static_box(Vector3(-2.6, 0.3, 3.4), Vector3(0.9, 0.6, 0.7), _material(Color(0.22, 0.18, 0.12), 0.9, 0.0))
	crate.set_meta("kind", "eat")
	crate.set_meta("label", "FOOD CRATE — EAT")
	interactables.append(crate)
	ration_crate_body = crate
	_build_warm_storage_rack()

	# Hunt system: inner bulkhead -> bait room -> exterior shutter. The former
	# small crush cage is gone; the doors and the room are now the trap.
	hunt_bulkhead_body = _build_rolling_gate(HUNT_BULKHEAD_SPOT, "HuntBulkheadModel")
	shutter_body = _build_rolling_gate(OUTER_HUNT_SHUTTER_SPOT, "OuterHuntShutterModel")

	# Delivery remains a safe-side hatch, independent from the hunt entrance.
	var delivery_hatch := _static_box(Vector3(5.78, 1.00, 1.15), Vector3(0.24, 0.92, 1.10), _material(Color(0.18, 0.16, 0.13), 0.72, 0.42))
	delivery_hatch.set_meta("kind", "shutter")
	delivery_hatch.set_meta("label", "DELIVERY HATCH — LEAVE BOX")
	interactables.append(delivery_hatch)
	order_box_hatch = _build_order_box(delivery_hatch, "DeliveredOrderBox")
	order_box_hatch.position = Vector3(-0.30, -0.10, 0.0)

	# These controls live on the warm side, but they must never turn the actual
	# bulkhead into an obstacle course. Keep a clear 1.5m lane from the farm to
	# the hunt room and make wall-mounted controls non-blocking; interaction is
	# distance-based, so their collision bodies serve no gameplay purpose.
	# Physical levers, not invisible click boxes. Each is bolted to the warm-side
	# wall, faces the room, and is the only thing that operates its mechanism. The
	# east wall's inner face is at x = 5.825 and the plate is 45 mm thick, so a
	# lever origin of 5.80 leaves its back 2.5 mm off the wall: mounted, not floating.
	shutter_lever = _build_mech_lever(LEVER_WALL_SPOT + Vector3(0.0, 0.0, -0.62), "OUTER SHUTTER",
		Color(0.42, 0.60, 0.78), "crank")
	interactables.append(shutter_lever)
	var bait_chute := _static_box(Vector3(5.64, 1.62, -1.38), Vector3(0.16, 0.26, 0.34), _material(Color(0.20, 0.12, 0.06), 0.78, 0.25))
	_make_interactable_non_blocking(bait_chute)
	bait_chute.set_meta("kind", "bait")
	bait_chute.set_meta("label", "BAIT CHUTE (1 FUEL)")
	interactables.append(bait_chute)
	var chute_glow := _box_visual(Vector3(0.025, 0.10, 0.16), Color(0.85, 0.32, 0.06), true, 1.1)
	chute_glow.position = Vector3(5.53, 1.62, -1.38)
	add_child(chute_glow)
	# Both hunt-side controls sit on the solid wall south of the bulkhead opening
	# (which spans z -2.9 to -1.1), clear of the door frame.
	# C3 // the inner bulkhead is a geared crank now: the door is heavy enough
	# that it is wound up with both hands, not thrown with one.
	bulkhead_crank = _build_bulkhead_crank(LEVER_WALL_SPOT + Vector3(0.0, 0.0, -3.30))
	interactables.append(bulkhead_crank)
	snare_lever = _build_mech_lever(LEVER_WALL_SPOT + Vector3(0.0, 0.0, -4.00), "FLOOR SNARE",
		Color(0.74, 0.20, 0.14), "snare")
	interactables.append(snare_lever)
	_build_hunt_snare()

	for index in GAP_POINTS.size():
		var gap := Node3D.new()
		gap.position = GAP_POINTS[index]
		gap.set_meta("kind", "gap")
		gap.set_meta("index", index)
		gap.set_meta("label", "GAP — INSTALL INSULATION PATCH")
		add_child(gap)
		interactables.append(gap)
		_build_gap_patch_visual(index)

	_build_trays()
	_build_net_prop()
	_refresh_net_prop()
	_build_house_gecko()

func _build_gap_patch_visual(index: int) -> void:
	# A crafted patch is a persistent physical object, not just a closed flag. The
	# scene owns the visual while FarmState owns whether that repair has been made.
	var root := Node3D.new()
	root.name = "WallInsulationPatch_%d" % (index + 1)
	root.position = _gap_patch_position(index)
	root.rotation.y = _gap_patch_rotation(index)
	var patch: Node3D = WALL_INSULATION_PATCH_MODEL.instantiate() as Node3D
	if patch != null:
		patch.name = "GeneratedInsulationPatchModel"
		root.add_child(patch)
	add_child(root)
	gap_patch_visuals.append(root)
	root.visible = index < farm.gaps.size() and bool(farm.gaps[index]["sealed"])

func _gap_patch_position(index: int) -> Vector3:
	var position_value: Vector3 = GAP_POINTS[index] + Vector3(0.0, -0.55, 0.0)
	match index:
		0: position_value.x -= 0.08 # right wall, pushed toward the warm room
		1: position_value.x += 0.08 # left wall
		2: position_value.z += 0.08 # north wall
		3: position_value.z -= 0.08 # stair-well wall
	return position_value

func _gap_patch_rotation(index: int) -> float:
	match index:
		0: return PI * 0.5
		1: return -PI * 0.5
		3: return PI
	return 0.0

func _refresh_gap_patch_visuals(animate_index: int = -1) -> void:
	if farm == null:
		return
	for index in range(mini(gap_patch_visuals.size(), farm.gaps.size())):
		var patch: Node3D = gap_patch_visuals[index]
		if patch == null:
			continue
		var sealed := bool(farm.gaps[index]["sealed"])
		patch.visible = sealed
		if sealed and index == animate_index:
			patch.scale = Vector3.ONE * 0.18
			var tween := create_tween()
			tween.tween_property(patch, "scale", Vector3.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		elif sealed:
			patch.scale = Vector3.ONE

func _build_hunt_snare() -> void:
	hunt_snare_visual = HUNT_SNARE_MODEL.instantiate() as Node3D
	if hunt_snare_visual == null:
		return
	hunt_snare_visual.name = "GeneratedHuntSnare"
	hunt_snare_visual.position = HUNT_SNARE_SPOT
	add_child(hunt_snare_visual)
	_refresh_hunt_snare_visual()

## The bench is rotated a quarter turn against the west wall, so a point authored
## in the prop's local space lands in the room as (-z, y, x). Every light, steam
## wisp and product plate goes through here instead of hand-guessed offsets.
func _kitchen_local(x: float, y: float, z: float) -> Vector3:
	return KITCHEN_SPOT + Vector3(-z, y, x)


func _update_kitchen_life(delta: float) -> void:
	# Two slow sine layers, not noise: a low oil flame breathes at roughly the
	# tempo a player reads as "alive" without strobing under the lamp.
	kitchen_flicker_time += delta
	var breath: float = 0.92 + sin(kitchen_flicker_time * 9.7) * 0.055 + sin(kitchen_flicker_time * 23.3) * 0.032
	if kitchen_light != null:
		kitchen_light.light_energy = 0.52 * breath
		kitchen_light.light_color = Color(1.0, 0.56 + breath * 0.05, 0.23)
	if kitchen_glow != null:
		var glow_material := kitchen_glow.material_override as StandardMaterial3D
		if glow_material != null:
			glow_material.emission_energy_multiplier = 2.3 * breath

	# The pot is fed from the furnace line, so a dead fire means a cold pot with no
	# steam at all: the station's state is readable from across the room.
	kitchen_cook_heat = maxf(0.0, kitchen_cook_heat - delta * 0.20)
	var burning: bool = farm != null and farm.furnace_lit and farm.fuel > 0.0
	if not burning or kitchen_steam_live >= 8:
		return
	kitchen_steam_clock += delta * (1.0 + kitchen_cook_heat * 2.6)
	while kitchen_steam_clock > 0.62:
		kitchen_steam_clock -= 0.62
		_spawn_kitchen_wisp(kitchen_cook_heat)


func _spawn_kitchen_wisp(heat: float) -> void:
	# A wisp is a tiny dim box that rises, swells and fades. Cheap, deterministic
	# and it never leaves a particle system running for the whole shift.
	var wisp := _box_visual(Vector3(0.048, 0.048, 0.048), Color(0.70, 0.68, 0.62))
	wisp.name = "KitchenWisp_%d" % kitchen_wisp_serial
	kitchen_wisp_serial += 1
	wisp.position = _kitchen_local(-0.480, 1.182, 0.030) + Vector3(randf_range(-0.028, 0.028), 0.0, randf_range(-0.028, 0.028))
	wisp.transparency = 0.58
	add_child(wisp)
	kitchen_steam_live += 1
	var drift := create_tween()
	drift.set_parallel(true)
	drift.tween_property(wisp, "position:y", wisp.position.y + 0.44 + heat * 0.22, 2.2 + heat * 0.5)
	drift.tween_property(wisp, "position:x", wisp.position.x + randf_range(-0.055, 0.055), 2.4)
	drift.tween_property(wisp, "scale", Vector3.ONE * (1.7 + heat * 0.8), 2.4)
	drift.tween_property(wisp, "transparency", 0.96, 2.4)
	drift.chain().tween_callback(_free_kitchen_wisp.bind(wisp))


func _free_kitchen_wisp(wisp: Node) -> void:
	kitchen_steam_live = maxi(0, kitchen_steam_live - 1)
	if is_instance_valid(wisp):
		wisp.queue_free()


func _kitchen_steam_burst() -> void:
	# A cook throws a real puff and heats the pot, so the ambient steam thickens for
	# the next few seconds instead of stopping the moment the button is released.
	kitchen_cook_heat = 1.6
	for index in 3:
		var puff := _box_visual(Vector3(0.09, 0.09, 0.09), Color(0.66, 0.64, 0.58))
		puff.name = "KitchenSteam_%d" % index
		puff.position = _kitchen_local(-0.480, 1.186, 0.030) + Vector3(0.0, 0.0, float(index) * 0.05)
		puff.transparency = 0.35
		add_child(puff)
		var drift := create_tween()
		drift.set_parallel(true)
		drift.tween_property(puff, "position:y", puff.position.y + 0.42 + float(index) * 0.05, 1.1 + float(index) * 0.15)
		drift.tween_property(puff, "scale", Vector3.ONE * 2.3, 1.2)
		drift.tween_property(puff, "transparency", 0.95, 1.2)
		drift.chain().tween_callback(puff.queue_free)


func _build_kitchen_bench() -> void:
	# The station explains the chain before any text does: a dressing board, a pot
	# fed by the furnace line, a knife block, and a wire rack for curing. It sits on
	# the free west wall, clear of the butcher table and the cot.
	var body := _static_box(KITCHEN_SPOT + Vector3(0.0, 0.475, 0.0), Vector3(0.87, 0.95, 1.68),
		_material(Color(0.17, 0.13, 0.10), 0.9, 0.05))
	body.name = "KitchenBenchBody"
	var visual: Node3D = _attach_model_to_body(body, KITCHEN_BENCH_MODEL,
		Vector3(0.0, -0.475, 0.0), Vector3.ONE, -PI * 0.5)
	if visual != null:
		visual.name = "KitchenBenchModel"
	body.set_meta("kind", "kitchen")
	body.set_meta("label", "KITCHEN — DRESS / COOK / CURE")
	interactables.append(body)
	kitchen_body = body

	# The bench's own hooded lamp, lit and alive. It hangs off the prop's lamp arm,
	# and a tiny emissive chip under the shade is what the player actually sees
	# brighten: the omni light alone would look lit by nothing.
	kitchen_light = _light_node(_kitchen_local(0.615, 1.395, 0.108), Color(1.0, 0.60, 0.26), 0.52, 3.0)
	add_child(kitchen_light)
	kitchen_glow = _box_visual(Vector3(0.074, 0.014, 0.062), Color(1.0, 0.72, 0.34), true, 2.3)
	kitchen_glow.name = "KitchenLampGlow"
	kitchen_glow.position = _kitchen_local(0.615, 1.360, 0.108)
	add_child(kitchen_glow)

	# Physical evidence of the two products, on the board where they belong.
	kitchen_meal_plate = _box_visual(Vector3(0.26, 0.03, 0.26), Color(0.52, 0.48, 0.36))
	kitchen_meal_plate.name = "KitchenMealPlate"
	kitchen_meal_plate.position = _kitchen_local(0.400, 0.960, -0.180)
	add_child(kitchen_meal_plate)
	kitchen_jerky_bundle = _box_visual(Vector3(0.22, 0.10, 0.15), Color(0.30, 0.22, 0.13))
	kitchen_jerky_bundle.name = "KitchenJerkyBundle"
	kitchen_jerky_bundle.position = _kitchen_local(-0.120, 0.985, -0.240)
	add_child(kitchen_jerky_bundle)
	_refresh_kitchen_state()


func _build_warm_storage_rack() -> void:
	# This starts hidden because the workshop recipe builds the upgrade. The
	# actual shelf, supplies and heat lamp appear in the room once made; the
	# FarmState flag simply persists that physical base change.
	var root := Node3D.new()
	root.name = "WarmStorageRack"
	root.position = STORAGE_RACK_SPOT
	root.rotation.y = STORAGE_RACK_ROTATION
	var rack: Node3D = WARM_STORAGE_RACK_MODEL.instantiate() as Node3D
	if rack != null:
		rack.name = "GeneratedWarmStorageRack"
		root.add_child(rack)
	storage_rack_lamp = _light_node(Vector3(0.39, 1.73, -0.34), Color(1.0, 0.54, 0.18), 1.15, 4.0)
	root.add_child(storage_rack_lamp)
	add_child(root)
	storage_rack_visual = root
	_refresh_storage_rack_visual()


func _build_furnace_heat_reclaimer() -> void:
	# The cave reward has a permanent place in the warm room.  It has no physics
	# body because it mounts beside an existing furnace and must not introduce a
	# fresh snag point along the player's normal work route.
	var root := Node3D.new()
	root.name = "FurnaceHeatReclaimer"
	root.position = FURNACE_SPOT + Vector3(0.94, 0.02, -0.18)
	root.rotation.y = -PI * 0.5
	var reclaimer: Node3D = FURNACE_HEAT_RECLAIMER_MODEL.instantiate() as Node3D
	if reclaimer != null:
		reclaimer.name = "GeneratedFurnaceHeatReclaimer"
		root.add_child(reclaimer)
	heat_reclaimer_light = _light_node(Vector3(0.0, 0.52, -0.33), Color(1.0, 0.42, 0.12), 0.72, 2.8)
	root.add_child(heat_reclaimer_light)
	add_child(root)
	heat_reclaimer_visual = root
	_refresh_heat_reclaimer_visual()


func _refresh_heat_reclaimer_visual(animate: bool = false) -> void:
	if heat_reclaimer_visual == null or farm == null:
		return
	var installed := farm.heat_reclaimer_installed
	heat_reclaimer_visual.visible = installed
	if heat_reclaimer_light != null:
		var burning := farm.furnace_lit and farm.fuel > 0.0
		heat_reclaimer_light.visible = installed and burning
		heat_reclaimer_light.light_energy = 0.72 if installed and burning else 0.0
	if not installed:
		heat_reclaimer_visual.scale = Vector3.ONE
		return
	if animate:
		heat_reclaimer_visual.scale = Vector3.ONE * 0.16
		var tween := create_tween()
		tween.tween_property(heat_reclaimer_visual, "scale", Vector3.ONE, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		heat_reclaimer_visual.scale = Vector3.ONE

func _refresh_storage_rack_visual(animate: bool = false) -> void:
	if storage_rack_visual == null or farm == null:
		return
	var installed := farm.storage_rack_installed
	storage_rack_visual.visible = installed
	# Before the upgrade, the rations sit in a freestanding crate. Once the shelf
	# is built the same interactable moves into the lower bay, while its generic
	# runtime box is hidden behind the authored crate in the generated model.
	if ration_crate_body != null:
		var crate_local := Vector3(-0.39, 0.50, -0.025)
		var rack_layout := Basis(Vector3.UP, STORAGE_RACK_ROTATION)
		ration_crate_body.position = STORAGE_RACK_SPOT + rack_layout * crate_local if installed else Vector3(-2.6, 0.3, 3.4)
		for child in ration_crate_body.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).visible = not installed
	if storage_rack_lamp != null:
		storage_rack_lamp.visible = installed and farm.furnace_lit and farm.fuel > 0.0
		storage_rack_lamp.light_energy = 1.15 if installed else 0.0
	if not installed:
		storage_rack_visual.scale = Vector3.ONE
		return
	if animate:
		storage_rack_visual.scale = Vector3.ONE * 0.16
		var tween := create_tween()
		tween.tween_property(storage_rack_visual, "scale", Vector3.ONE, 0.36).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		storage_rack_visual.scale = Vector3.ONE

func _refresh_hunt_snare_visual(triggered: bool = false) -> void:
	if hunt_snare_visual == null or farm == null:
		return
	var visible := farm.snare_armed or hunt_snare_sprung
	hunt_snare_visual.visible = visible
	if not visible:
		hunt_snare_visual.scale = Vector3.ONE
		return
	if triggered:
		hunt_snare_visual.scale = Vector3.ONE
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(hunt_snare_visual, "scale", Vector3(1.18, 0.42, 1.18), 0.18).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
		tween.tween_property(hunt_snare_visual, "rotation:y", deg_to_rad(24.0), 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		hunt_snare_visual.scale = Vector3.ONE
		hunt_snare_visual.rotation.y = 0.0

func _arm_hunt_snare() -> void:
	# Kept for direct callers (tests, scripted moments): arm only, never disarm.
	if farm.snare_armed:
		return
	_toggle_hunt_snare()


func _toggle_hunt_snare() -> void:
	var arming := not farm.snare_armed
	# The trap still has to be built and carried here first. Refuse before the
	# lever moves, so the handle never shows a state the trap is not in.
	if arming and farm.snares <= 0:
		show_message(farm.arm_snare(), 2.6)
		return
	if snare_lever != null and not snare_lever.pull(arming):
		return
	var result: String = farm.arm_snare() if arming else farm.disarm_snare()
	if arming:
		hunt_snare_sprung = false
	elif audio != null:
		audio.play_chain()
	_refresh_hunt_snare_visual()
	show_message(result, 2.6)

func _build_bulkhead_crank(position_value: Vector3) -> BulkheadCrank:
	# The crank replaces the bulkhead's lever. It is the same bolted, stencilled
	# wall family, but the wheel is a control you hold rather than throw.
	var crank := BulkheadCrank.new()
	crank.name = "BulkheadCrank"
	crank.position = position_value
	# Local -Z (the wheel) must point into the room, i.e. toward -X.
	crank.rotation.y = PI * 0.5
	crank.configure(Color(0.80, 0.56, 0.16), "INNER BULKHEAD — CRANK")
	crank.set_meta("kind", "bulkhead")
	crank.set_meta("requires_look", true)
	crank.set_meta("reach", LEVER_REACH)
	crank.set_meta("label", "INNER BULKHEAD CRANK // HOLD TO RAISE OR SEAT")
	crank.turned.connect(_on_bulkhead_cranked)
	add_child(crank)
	return crank


func _build_mech_lever(position_value: Vector3, plate_text: String, tag: Color, kind: String) -> MECH_LEVER:
	# Worn, bolted and facing the warm room. Reused for the outer shutter and the
	# snare, so both behave and sound the same way.
	var lever := MECH_LEVER.new()
	match kind:
		"crank": lever.name = "ShutterLever"
		"snare": lever.name = "SnareLever"
	lever.position = position_value
	# Local -Z (the mechanism) must point into the room, i.e. toward -X.
	lever.rotation.y = PI * 0.5
	lever.configure(tag, plate_text)
	lever.set_meta("kind", kind)
	lever.set_meta("requires_look", true)
	lever.set_meta("reach", LEVER_REACH)
	match kind:
		"bulkhead": lever.set_meta("label", "INNER BULKHEAD LEVER // PULL TO OPEN OR SEAL")
		"crank": lever.set_meta("label", "OUTER SHUTTER LEVER // PULL TO LIFT OR SEAT")
		"snare": lever.set_meta("label", "FLOOR SNARE LEVER // PULL TO ARM OR CLEAR")
	add_child(lever)
	return lever


func _sync_levers_instant() -> void:
	# Boot, new shift and load: the player never pulled these, so they must not click.
	if bulkhead_crank != null:
		bulkhead_crank.set_engaged(hunt_bulkhead_open, true)
	if shutter_lever != null:
		shutter_lever.set_engaged(shutter_open, true)
		shutter_lever.set_chain_snapped(farm.story.chain_broken)
	if snare_lever != null and farm != null:
		snare_lever.set_engaged(farm.snare_armed, true)


func try_trigger_hunt_snare(creature: Burrower) -> bool:
	if farm == null or creature == null or not farm.snare_armed:
		return false
	var offset: Vector3 = creature.global_position - HUNT_BAIT_SPOT
	offset.y = 0.0
	if offset.length() > 0.62:
		return false
	farm.trigger_snare()
	hunt_snare_sprung = true
	if farm.story.stage == StoryState.STAGE_ROOM_REOPENED:
		farm.story.advance_to(StoryState.STAGE_TRAP_PROVEN)
	_refresh_hunt_snare_visual(true)
	# The trap sprang on its own: reset the handle to its clear position.
	if snare_lever != null:
		snare_lever.set_engaged(false, false)
	creature.apply_tether(6.5)
	if audio != null:
		audio.play_chain()
	show_message("SNARE TAKES HOLD // the slime is pinned for a few seconds.", 2.8)
	return true


func _build_bedside_kit() -> void:
	# This is a real blocking footlocker standing beside the head of the cot
	# against the rear wall. It replaces the old free-standing locker that cut
	# into the bed silhouette, and it no longer sits in the walkway.
	bedside_kit_body = _static_box(BEDSIDE_KIT_SPOT, Vector3(1.08, 0.56, 0.76), _material(Color(0.12, 0.10, 0.08), 0.92, 0.10))
	bedside_kit_body.name = "BedsideSurvivalKit"
	bedside_kit_closed_visual = _attach_model_to_body(bedside_kit_body, BEDSIDE_KIT_CLOSED_MODEL, Vector3(0.0, -0.28, 0.0))
	if bedside_kit_closed_visual != null:
		bedside_kit_closed_visual.name = "BedsideKitClosedModel"
	bedside_kit_open_visual = _attach_model_to_body(bedside_kit_body, BEDSIDE_KIT_OPEN_MODEL, Vector3(0.0, -0.28, 0.0))
	if bedside_kit_open_visual != null:
		bedside_kit_open_visual.name = "BedsideKitOpenModel"
	bedside_kit_body.set_meta("kind", "kit")
	bedside_kit_body.set_meta("label", "BEDSIDE KIT — TAKE TOOLS")
	interactables.append(bedside_kit_body)
	_refresh_bedside_kit()


func _refresh_bedside_kit() -> void:
	if farm == null:
		return
	var opened := farm.bedside_kit_opened and bedside_kit_lid_open
	if bedside_kit_closed_visual != null:
		bedside_kit_closed_visual.visible = not opened
	if bedside_kit_open_visual != null:
		bedside_kit_open_visual.visible = opened


func _use_bedside_kit() -> void:
	if farm.bedside_kit_opened:
		# Once the tools are out, the lid is a physical thing the player can pose.
		bedside_kit_lid_open = not bedside_kit_lid_open
		_refresh_bedside_kit()
		show_message("KIT %s // [1] blade [2] torch [3] driver // [F] light // [Q] load." % ("OPEN" if bedside_kit_lid_open else "CLOSED"), 2.0)
		return
	farm.bedside_kit_opened = true
	bedside_kit_lid_open = true
	player.set_flashlight_acquired(true)
	player.set_machete_equipped(true)
	player.set_riveter_equipped(true)
	player.select_slot(player.SLOT_MACHETE)
	_refresh_bedside_kit()
	if opening_state == "kit":
		opening_state = "complete"
	show_message("KIT OPEN // torch in the left hand, blade or driver in the right. No bolts yet.", 3.6)


func _build_trays() -> void:
	# First shift begins with one working colony; the rest of the shelf is built
	# but empty, and a netted starter is what turns a frame into a colony.
	tray_slabs.resize(FarmState.TRAY_SLOTS)
	tray_lids.resize(FarmState.TRAY_SLOTS)
	tray_bodies.resize(FarmState.TRAY_SLOTS)
	# All six frames are physically real from the first shift: the room has six
	# slots, and a slot you can see and press is a slot the farm can grow into.
	for index in FarmState.TRAY_SLOTS:
		var spot: Vector3 = TRAY_SPOTS[index]
		var tray_body := _static_box(Vector3(spot.x, 0.46, spot.z), Vector3(0.96, 0.92, 0.74), _material(Color(0.14, 0.16, 0.10), 0.92, 0.18))
		tray_body.name = "CultureTrayBody_%d" % (index + 1)
		tray_bodies[index] = tray_body
		var tray_model: Node3D = _attach_model_to_body(tray_body, CULTURE_TRAY_MODEL, Vector3(0.0, -0.46, 0.0))
		if tray_model != null:
			tray_model.name = "CultureTray_%d" % (index + 1)
		var lid: Node3D = null
		if tray_model != null:
			lid = tray_model.find_child("CultureLidPivot", true, false) as Node3D
		# Tray two has its frame and floor but no lid or colony yet.  Keeping the
		# body solid makes the incomplete construction feel like a real object.
		if index == 1 and lid != null:
			lid.visible = false
		tray_lids[index] = lid if index == 0 else null
		if index == 0:
			_build_cricket_colony(index)
			var slab := MeshInstance3D.new()
			var slab_mesh := BoxMesh.new()
			slab_mesh.size = Vector3(0.76, 0.15, 0.45)
			slab.mesh = slab_mesh
			var slab_mat := StandardMaterial3D.new()
			slab_mat.albedo_color = Color(0.20, 0.25, 0.09)
			slab_mat.emission_enabled = true
			slab_mat.emission = Color(0.12, 0.20, 0.035)
			slab_mat.emission_energy_multiplier = 0.8
			slab.material_override = slab_mat
			slab.position = Vector3(spot.x, 0.51, spot.z)
			add_child(slab)
			tray_slabs[index] = slab
			tray_body.set_meta("kind", "tray")
			tray_body.set_meta("index", index)
			tray_body.set_meta("label", "CULTURE TRAY 1 — OPEN / TEND")
			interactables.append(tray_body)
		else:
			var unfinished_mark := Label3D.new()
			unfinished_mark.name = "UnfinishedMark"
			unfinished_mark.text = "%02d" % (index + 1)
			unfinished_mark.font_size = 34
			unfinished_mark.outline_size = 6
			unfinished_mark.modulate = Color(0.72, 0.38, 0.12, 0.78)
			unfinished_mark.position = Vector3(0.0, 0.46, -0.39)
			unfinished_mark.rotation_degrees = Vector3(-18.0, 0.0, 0.0)
			tray_body.add_child(unfinished_mark)
			# The empty frame is a real target: a netted starter can found a colony
			# here instead of the shelf staying decorative.
			tray_body.set_meta("kind", "tray")
			tray_body.set_meta("index", index)
			tray_body.set_meta("label", "CULTURE TRAY %d — SEED A COLONY" % (index + 1))
			interactables.append(tray_body)
	_refresh_trays()
	_refresh_net_prop()


func _build_cricket_colony(tray_index: int) -> void:
	if farm == null or tray_index < 0 or tray_index >= farm.trays.size():
		return
	var tray: Dictionary = farm.trays[tray_index]
	if str(tray.get("species", "")) != "cricket":
		return
	# C2.13 // density, not simulation. The rig is cheap but not free, so the room
	# shows between two and eight crickets as the colony grows; the number above
	# them is the truth the model and the kitchen read.
	_sync_cricket_density(tray_index)


## Adds cricket rigs until the tray shows as many bodies as its population earns.
func _sync_cricket_density(tray_index: int) -> void:
	if farm == null or tray_index < 0 or tray_index >= farm.trays.size():
		return
	var population: int = farm.tray_population(tray_index)
	var wanted: int = clampi(2 + population / 20, 2, 8)
	var existing: int = 0
	for item in tray_crickets:
		if typeof(item) == TYPE_DICTIONARY and int((item as Dictionary).get("tray_index", -1)) == tray_index:
			existing += 1
	for cricket_index in range(existing, wanted):
		_tray_cricket_item(tray_index, cricket_index)


func _tray_cricket_item(tray_index: int, cricket_index: int) -> void:
	var root := Node3D.new()
	root.name = "Cricket_%d_%d" % [tray_index + 1, cricket_index + 1]
	root.position = Vector3(TRAY_SPOTS[tray_index].x, 0.515, TRAY_SPOTS[tray_index].z)
	add_child(root)
	var visual: Node3D = CRICKET_MODEL.instantiate() as Node3D
	if visual == null:
		root.queue_free()
		return
	visual.name = "CricketVisual"
	# This is Riverborn's native Godot-facing orientation, so unlike the old
	# downloaded cockroach it needs no corrective flip.
	visual.scale = Vector3.ONE * 1.75
	root.add_child(visual)
	var animation: AnimationPlayer = visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_play_riverborn_animation(animation, "idle", 0.82)
	# A loose scatter of homes across the tray floor rather than a fixed rank.
	var angle := float(cricket_index) * 2.399 + float(tray_index) * 0.41
	var radius := 0.10 + 0.046 * float(cricket_index % 4)
	tray_crickets.append({
		"root": root,
		"tray_index": tray_index,
		"home": Vector2(cos(angle), sin(angle)) * radius,
		"phase": float(cricket_index) * 1.71 + float(tray_index) * 0.41,
		"animation": animation,
	})


func _build_house_gecko() -> void:
	# The Riverborn gecko source uses its small slithering rig. Here it is a
	# harmless house gecko: a living sign that the warm farm has its own ecology,
	# not a second enemy and not a required task.
	house_gecko = Node3D.new()
	house_gecko.name = "HouseGecko"
	house_gecko.position = GECKO_ROUTE[0]
	add_child(house_gecko)
	var visual: Node3D = GECKO_MODEL.instantiate() as Node3D
	if visual == null:
		return
	visual.name = "GeckoVisual"
	visual.scale = Vector3.ONE * 0.36
	house_gecko.add_child(visual)
	var gecko_skin := StandardMaterial3D.new()
	gecko_skin.albedo_color = Color(0.24, 0.20, 0.12)
	gecko_skin.roughness = 0.82
	gecko_skin.vertex_color_use_as_albedo = true
	_apply_gecko_skin(visual, gecko_skin)
	_add_house_gecko_body(visual)
	house_gecko_legs = _add_house_gecko_legs(visual)
	house_gecko_animation = visual.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_play_riverborn_animation(house_gecko_animation, "rest", 0.75)


func _apply_gecko_skin(node: Node, skin: Material) -> void:
	if node is MeshInstance3D:
		var mesh_instance := node as MeshInstance3D
		if mesh_instance.mesh != null:
			for surface in mesh_instance.mesh.get_surface_count():
				mesh_instance.set_surface_override_material(surface, skin)
	for child in node.get_children():
		_apply_gecko_skin(child, skin)


func _add_house_gecko_body(visual: Node3D) -> void:
	# The moving Riverborn rig supplies the life; this low, mottled body gives it
	# a gecko silhouette instead of leaving the reused snake mesh as a thin line.
	var body_material := _material(Color(0.29, 0.23, 0.12), 0.86, 0.0)
	var belly_material := _material(Color(0.48, 0.34, 0.17), 0.92, 0.0)
	var eye_material := _material(Color(0.82, 0.48, 0.07), 0.40, 0.0)
	eye_material.emission_enabled = true
	eye_material.emission = Color(0.26, 0.08, 0.008)
	eye_material.emission_energy_multiplier = 0.35
	var body := MeshInstance3D.new()
	body.name = "GeckoBody"
	var body_mesh := SphereMesh.new()
	body_mesh.radius = 0.5
	body_mesh.height = 1.0
	body_mesh.radial_segments = 12
	body_mesh.rings = 6
	body.mesh = body_mesh
	body.scale = Vector3(0.98, 0.16, 0.28)
	body.position = Vector3(-0.03, 0.025, 0.0)
	body.material_override = body_material
	visual.add_child(body)
	var belly := MeshInstance3D.new()
	var belly_mesh := SphereMesh.new()
	belly_mesh.radius = 0.5
	belly_mesh.height = 1.0
	belly.mesh = belly_mesh
	belly.scale = Vector3(0.58, 0.055, 0.18)
	belly.position = Vector3(-0.03, -0.075, 0.0)
	belly.material_override = belly_material
	visual.add_child(belly)
	var head := MeshInstance3D.new()
	head.name = "GeckoHead"
	var head_mesh := SphereMesh.new()
	head_mesh.radius = 0.5
	head_mesh.height = 1.0
	head.mesh = head_mesh
	head.scale = Vector3(0.29, 0.18, 0.25)
	head.position = Vector3(0.53, 0.042, 0.0)
	head.material_override = body_material
	visual.add_child(head)
	for side in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		eye.name = "GeckoEye_%d" % int(side)
		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = 0.5
		eye_mesh.height = 1.0
		eye.mesh = eye_mesh
		eye.scale = Vector3(0.045, 0.050, 0.034)
		eye.position = Vector3(0.65, 0.085, side * 0.105)
		eye.material_override = eye_material
		visual.add_child(eye)


func _add_house_gecko_legs(visual: Node3D) -> Array:
	# Riverborn's gecko behaviour deliberately reuses a small snake rig.  These
	# four low limbs turn that supplied, animated body into a readable lizard
	# silhouette for the basement without touching the source project.
	var legs: Array = []
	var leg_material := _material(Color(0.10, 0.075, 0.040), 0.92, 0.0)
	for fore_aft in [-0.31, 0.25]:
		for side in [-1.0, 1.0]:
			var pivot := Node3D.new()
			pivot.name = "GeckoLeg_%d_%d" % [int(fore_aft * 10.0), int(side)]
			pivot.position = Vector3(fore_aft, -0.018, side * 0.030)
			pivot.rotation.x = -side * deg_to_rad(57.0)
			visual.add_child(pivot)
			var limb := MeshInstance3D.new()
			var limb_mesh := CylinderMesh.new()
			limb_mesh.top_radius = 0.026
			limb_mesh.bottom_radius = 0.018
			limb_mesh.height = 0.44
			limb.mesh = limb_mesh
			limb.material_override = leg_material
			limb.position = Vector3(0.0, -0.20, 0.0)
			pivot.add_child(limb)
			var toe := MeshInstance3D.new()
			var toe_mesh := SphereMesh.new()
			toe_mesh.radius = 0.5
			toe_mesh.height = 1.0
			toe.mesh = toe_mesh
			toe.scale = Vector3(0.07, 0.025, 0.12)
			toe.position = Vector3(0.0, -0.39, 0.0)
			toe.material_override = leg_material
			pivot.add_child(toe)
			legs.append({"pivot": pivot, "side": side, "phase": fore_aft * 9.0})
	return legs

func _refresh_trays() -> void:
	_refresh_tray_marks()
	for index in farm.trays.size() if farm != null else 0:
		if str(farm.trays[index].get("species", "")) == "cricket" and bool(farm.trays[index]["active"]) and not bool(farm.trays[index]["dead"]):
			_sync_cricket_density(index)
	for index in tray_slabs.size():
		var slab: MeshInstance3D = tray_slabs[index] as MeshInstance3D
		if slab == null or farm == null or index >= farm.trays.size():
			continue
		var tray: Dictionary = farm.trays[index]
		var active := bool(tray["active"]) and not bool(tray["dead"])
		slab.visible = bool(tray["active"])
		var growth: float = clampf(float(tray["progress"]), 0.0, 1.0)
		slab.scale.y = 0.40 + growth * 1.45
		slab.position.y = 0.43 + slab.scale.y * 0.075
		var mat := slab.material_override as StandardMaterial3D
		if mat != null:
			if bool(tray["dead"]):
				mat.emission = Color(0.055, 0.028, 0.012)
				mat.albedo_color = Color(0.11, 0.07, 0.035)
			elif active:
				mat.emission = Color(0.12, 0.20, 0.035)
				mat.albedo_color = Color(0.20, 0.25, 0.09)

# ---------------------------------------------------------------- HUD

func _build_hud() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 1
	add_child(layer)
	vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vignette.color = Color(0.75, 0.35, 0.0, 0.0)
	layer.add_child(vignette)
	cold_overlay = ColorRect.new()
	cold_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	cold_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cold_overlay.color = Color(0.78, 0.90, 1.0, 0.0)
	layer.add_child(cold_overlay)
	hurt_overlay = ColorRect.new()
	hurt_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hurt_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hurt_overlay.color = Color(0.42, 0.015, 0.010, 0.0)
	layer.add_child(hurt_overlay)
	down_overlay = ColorRect.new()
	down_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	down_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	down_overlay.color = Color(0.02, 0.01, 0.01, 0.0)
	layer.add_child(down_overlay)
	var wake_layer := CanvasLayer.new()
	wake_layer.layer = 3
	add_child(wake_layer)
	_build_wake_overlay(wake_layer)

	# Original icon-first survival HUD: vital rings and tool glyphs do the first
	# pass of communication. Short numbers remain only where precision matters.
	var compass := _hud_panel(layer, Vector2(542, 18), Vector2(196, 48), Color(0.010, 0.016, 0.018, 0.55), Color(0.32, 0.54, 0.56, 0.42))
	compass_glyph = _hud_glyph(compass, Vector2(74, 4), Vector2(40, 40), "compass", Color(0.67, 0.88, 0.89), Color(1.0, 0.62, 0.25))
	var compass_rule := _ui_label(compass, Vector2(16, 17), Vector2(54, 14), 10, Color(0.40, 0.64, 0.66, 0.76))
	compass_rule.text = "◂  ◂"
	var compass_rule_right := _ui_label(compass, Vector2(126, 17), Vector2(54, 14), 10, Color(0.40, 0.64, 0.66, 0.76))
	compass_rule_right.text = "▸  ▸"

	var survival := _hud_panel(layer, Vector2(24, 24), Vector2(208, 118), Color(0.018, 0.025, 0.027, 0.92), Color(0.82, 0.39, 0.14, 0.72))
	warmth_glyph = _hud_glyph(survival, Vector2(12, 39), Vector2(54, 54), "warmth", Color(1.0, 0.45, 0.16), Color(1.0, 0.75, 0.28))
	fuel_glyph = _hud_glyph(survival, Vector2(78, 42), Vector2(48, 48), "fuel", Color(0.98, 0.70, 0.24), Color(0.46, 0.84, 0.84))
	clock_label = _ui_label(survival, Vector2(14, 10), Vector2(178, 20), 13, Color(0.96, 0.78, 0.45))
	status_label = _ui_label(survival, Vector2(138, 45), Vector2(56, 24), 16, Color(0.78, 0.92, 0.92))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	heat_bar = _hud_bar(survival, Vector2(18, 97), Vector2(48, 6), Color(1.0, 0.36, 0.10))
	fuel_bar = _hud_bar(survival, Vector2(78, 97), Vector2(48, 6), Color(0.96, 0.70, 0.20))
	# Health is drawn as a plain rect rather than a ProgressBar: the theme's
	# minimum height inflates a 6 px bar into a slab that overflows the card.
	var health_track := ColorRect.new()
	health_track.position = Vector2(18, 32)
	health_track.size = Vector2(172, 3)
	health_track.color = Color(0.030, 0.020, 0.018, 0.95)
	health_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	survival.add_child(health_track)
	health_bar = ColorRect.new()
	health_bar.position = Vector2(18, 32)
	health_bar.size = Vector2(172, 3)
	health_bar.color = Color(0.62, 0.17, 0.13)
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	survival.add_child(health_bar)
	var vital_ticks := _ui_label(survival, Vector2(140, 76), Vector2(52, 18), 10, Color(0.48, 0.64, 0.66, 0.78))
	vital_ticks.text = "◒  ◓"
	vital_ticks.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# Objective is a direction and a symbol first, with only a compact name.
	objective_panel = _hud_panel(layer, Vector2(1004, 24), Vector2(252, 82), Color(0.018, 0.025, 0.027, 0.92), Color(0.42, 0.78, 0.67, 0.70))
	objective_glyph = _hud_glyph(objective_panel, Vector2(12, 15), Vector2(50, 50), "objective", Color(0.46, 0.90, 0.72), Color(1.0, 0.67, 0.26))
	objective_arrow = _hud_glyph(objective_panel, Vector2(202, 22), Vector2(30, 30), "arrow", Color(1.0, 0.64, 0.22), Color(0.46, 0.90, 0.72))
	order_label = _ui_label(objective_panel, Vector2(72, 16), Vector2(122, 48), 12, Color(0.81, 0.96, 0.82))
	order_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	order_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# C2 // cave papers ride under the objective block: what the drop asked for, how
	# many, and when it is due, so the wrap can be planned without walking back.
	slate_panel = _hud_panel(layer, Vector2(1004, 112), Vector2(252, 30), Color(0.018, 0.025, 0.027, 0.92), Color(0.62, 0.46, 0.78, 0.70))
	slate_panel.visible = false
	_hud_glyph(slate_panel, Vector2(5, 4), Vector2(22, 22), "cave", Color(0.80, 0.70, 0.96), Color(1.0, 0.67, 0.26))
	slate_label = _ui_label(slate_panel, Vector2(30, 6), Vector2(214, 18), 11, Color(0.88, 0.83, 0.97))
	slate_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# C2 // pocket readout: the gland lantern's remaining burn and the clamp's state,
	# so the walk back does not have to be repeated to remember either.
	pocket_panel = _hud_panel(layer, Vector2(1004, 148), Vector2(252, 52), Color(0.018, 0.025, 0.027, 0.92), Color(0.82, 0.52, 0.22, 0.66))
	pocket_panel.visible = false
	_hud_glyph(pocket_panel, Vector2(6, 14), Vector2(24, 24), "cave", Color(1.0, 0.74, 0.36), Color(0.86, 0.44, 0.14))
	pocket_label = _ui_label(pocket_panel, Vector2(36, 5), Vector2(208, 42), 11, Color(0.96, 0.86, 0.68))
	pocket_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	pocket_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Bottom-right is a visual weapon card: symbol, count, and a quiet condition
	# ring in place of a row of developer inventory labels.
	# C2 // culture readout: the live load the farm is carrying, so the net count is
	# not a number the player only sees in a message.
	cricket_panel = _hud_panel(layer, Vector2(1010, 500), Vector2(246, 40), Color(0.018, 0.025, 0.027, 0.92), Color(0.40, 0.62, 0.30, 0.62))
	cricket_panel.visible = false
	_hud_glyph(cricket_panel, Vector2(9, 8), Vector2(24, 24), "cricket", Color(0.74, 0.88, 0.46), Color(1.0, 0.67, 0.26))
	cricket_label = _ui_label(cricket_panel, Vector2(40, 10), Vector2(198, 22), 12, Color(0.86, 0.94, 0.72))
	cricket_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Carried inventory: icons for what the player holds on the body and in the
	# pack. Kitchen stock stays off this panel; it is not in the player's hands.
	carry_panel = _hud_panel(layer, Vector2(1010, 452), Vector2(246, 40), Color(0.018, 0.025, 0.027, 0.92), Color(0.62, 0.46, 0.28, 0.62))
	carry_panel.visible = false
	_hud_glyph(carry_panel, Vector2(9, 8), Vector2(24, 24), "cricket", Color(0.90, 0.72, 0.46), Color(0.46, 0.84, 0.84))
	carry_label = _ui_label(carry_panel, Vector2(40, 10), Vector2(198, 22), 12, Color(0.96, 0.88, 0.72))
	carry_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	var loadout := _hud_panel(layer, Vector2(1010, 548), Vector2(246, 144), Color(0.018, 0.025, 0.027, 0.92), Color(0.38, 0.58, 0.62, 0.64))
	ammo_glyph = _hud_glyph(loadout, Vector2(14, 44), Vector2(70, 70), "driver", Color(0.77, 0.92, 0.92), Color(1.0, 0.60, 0.22))
	inventory_label = _ui_label(loadout, Vector2(92, 43), Vector2(135, 76), 26, Color(0.95, 0.96, 0.90))
	inventory_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var loadout_caption := _ui_label(loadout, Vector2(16, 13), Vector2(210, 18), 10, Color(0.53, 0.70, 0.72))
	loadout_caption.text = "BOLT DRIVER"
	var loadout_rule := _ui_label(loadout, Vector2(92, 112), Vector2(132, 16), 10, Color(1.0, 0.65, 0.28))
	loadout_rule.text = "◇  ◇  ◇"
	loadout_rule.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# Danger only becomes visible when it needs attention; a warning mark beats a
	# permanent red text banner on an otherwise calm screen.
	danger_panel = _hud_panel(layer, Vector2(1160, 120), Vector2(96, 70), Color(0.14, 0.027, 0.020, 0.94), Color(1.0, 0.27, 0.17, 0.82))
	danger_panel.visible = false
	danger_glyph = _hud_glyph(danger_panel, Vector2(10, 14), Vector2(40, 40), "warning", Color(1.0, 0.31, 0.18), Color(1.0, 0.70, 0.28))
	state_label = _ui_label(danger_panel, Vector2(54, 18), Vector2(34, 38), 10, Color(1.0, 0.78, 0.58))
	state_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	message_panel = _hud_panel(layer, Vector2(370, 78), Vector2(540, 48), Color(0.008, 0.012, 0.014, 0.94), Color(0.80, 0.42, 0.16, 0.66))
	message_panel.visible = false
	message_glyph = _hud_glyph(message_panel, Vector2(12, 8), Vector2(32, 32), "furnace", Color(1.0, 0.55, 0.20), Color(0.50, 0.86, 0.86))
	message_label = _ui_label(message_panel, Vector2(55, 8), Vector2(468, 32), 13, Color(0.94, 0.93, 0.87))
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	prompt_panel = _hud_panel(layer, Vector2(408, 506), Vector2(464, 60), Color(0.008, 0.012, 0.014, 0.95), Color(0.84, 0.45, 0.16, 0.82))
	prompt_panel.visible = false
	prompt_glyph = _hud_glyph(prompt_panel, Vector2(10, 9), Vector2(42, 42), "use", Color(1.0, 0.65, 0.28), Color(0.48, 0.88, 0.88))
	var keycap := _hud_panel(prompt_panel, Vector2(60, 12), Vector2(36, 36), Color(0.10, 0.06, 0.025, 1.0), Color(1.0, 0.64, 0.26, 0.92))
	prompt_key_label = _ui_label(keycap, Vector2(0, 4), Vector2(36, 28), 16, Color(1.0, 0.85, 0.55))
	prompt_key_label.text = "E"
	prompt_key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label = _ui_label(prompt_panel, Vector2(110, 13), Vector2(332, 32), 16, Color(0.97, 0.88, 0.68))
	prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	interaction_progress = ProgressBar.new()
	interaction_progress.position = Vector2(106, 48)
	interaction_progress.size = Vector2(330, 4)
	interaction_progress.max_value = 1.0
	interaction_progress.show_percentage = false
	interaction_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_panel.add_child(interaction_progress)

	crosshair = _ui_label(layer, Vector2(620, 336), Vector2(40, 40), 20, Color(0.92, 0.88, 0.75, 0.82))
	crosshair.text = "×"
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Minecraft-style tool bar: four slots with real tool icons, switched with
	# 1/2/3/4. The net is slot four once it is woven, so a carried colony starter
	# has a home instead of hanging in the view whenever the torch is lowered.
	var hotbar := _hud_panel(layer, Vector2(394, 586), Vector2(492, 118), Color(0.010, 0.014, 0.016, 0.72), Color(0.30, 0.47, 0.50, 0.52))
	hotbar_name_label = _ui_label(hotbar, Vector2(0, 7), Vector2(396, 16), 11, Color(1.0, 0.73, 0.38))
	hotbar_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tool_order := ["machete", "torch", "driver", "cricket", "chain"]
	for index in 5:
		var slot_panel := _hud_panel(hotbar, Vector2(14 + index * 96, 28), Vector2(80, 78), Color(0.018, 0.025, 0.027, 0.92), Color(0.28, 0.42, 0.44, 0.55))
		var slot_key := _ui_label(slot_panel, Vector2(7, 3), Vector2(20, 14), 10, Color(0.62, 0.80, 0.82, 0.85))
		slot_key.text = str(index + 1)
		var slot_icon := _hud_glyph(slot_panel, Vector2(18, 20), Vector2(44, 44), tool_order[index], Color(0.84, 0.92, 0.90), Color(1.0, 0.62, 0.25))
		hotbar_slots.append(slot_panel)
		hotbar_glyphs.append(slot_icon)
		hotbar_keys.append(slot_key)


func _build_wake_overlay(layer: CanvasLayer) -> void:
	# The opening uses movable eyelids rather than a generic fade: the player
	# begins low in the cot, sees only a slit of the cold room, then sits up.
	wake_overlay = Control.new()
	wake_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wake_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wake_overlay.visible = false
	layer.add_child(wake_overlay)
	wake_veil = ColorRect.new()
	wake_veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	wake_veil.color = Color(0.0, 0.0, 0.0, 0.0)
	wake_veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wake_overlay.add_child(wake_veil)
	wake_top_lid = ColorRect.new()
	wake_top_lid.set_anchors_preset(Control.PRESET_TOP_WIDE)
	wake_top_lid.offset_left = 0.0
	wake_top_lid.offset_top = 0.0
	wake_top_lid.offset_right = 0.0
	wake_top_lid.offset_bottom = 0.0
	wake_top_lid.color = Color(0.0, 0.0, 0.0, 1.0)
	wake_top_lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wake_overlay.add_child(wake_top_lid)
	wake_bottom_lid = ColorRect.new()
	wake_bottom_lid.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	wake_bottom_lid.offset_left = 0.0
	wake_bottom_lid.offset_top = 0.0
	wake_bottom_lid.offset_right = 0.0
	wake_bottom_lid.offset_bottom = 0.0
	wake_bottom_lid.color = Color(0.0, 0.0, 0.0, 1.0)
	wake_bottom_lid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wake_overlay.add_child(wake_bottom_lid)


func _set_wake_lids(closedness: float, veil_alpha: float) -> void:
	if wake_overlay == null:
		return
	var amount := clampf(closedness, 0.0, 1.0)
	wake_overlay.visible = amount > 0.0 or veil_alpha > 0.0
	if wake_veil != null:
		wake_veil.color = Color(0.0, 0.0, 0.0, clampf(veil_alpha, 0.0, 1.0))
	if wake_top_lid != null:
		wake_top_lid.offset_bottom = 340.0 * amount
	if wake_bottom_lid != null:
		wake_bottom_lid.offset_top = -340.0 * amount

func _ui_label(parent: Node, position_value: Vector2, size_value: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.position = position_value
	label.size = size_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
	return label


func _hud_glyph(parent: Node, position_value: Vector2, size_value: Vector2, glyph_name: String, tint_value: Color, accent_value: Color) -> SurvivalGlyph:
	var icon := SurvivalGlyph.new()
	icon.position = position_value
	icon.size = size_value
	icon.glyph = glyph_name
	icon.tint = tint_value
	icon.accent = accent_value
	parent.add_child(icon)
	return icon


func _hud_panel(parent: Node, position_value: Vector2, size_value: Vector2, fill: Color, border: Color) -> Panel:
	var panel := Panel.new()
	panel.position = position_value
	panel.size = size_value
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.52)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 2)
	panel.add_theme_stylebox_override("panel", style)
	# This original generated surface is intentionally faint: it gives the HUD a
	# tangible worn-material edge without sacrificing contrast or legibility.
	var surface := TextureRect.new()
	surface.texture = HUD_SURFACE
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	surface.stretch_mode = TextureRect.STRETCH_SCALE
	surface.modulate = Color(0.78, 0.92, 0.94, 0.105)
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(surface)
	parent.add_child(panel)
	return panel


func _hud_bar(parent: Node, position_value: Vector2, size_value: Vector2, fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = position_value
	bar.size = size_value
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.show_percentage = false
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var background := StyleBoxFlat.new()
	background.bg_color = Color(0.015, 0.018, 0.020, 0.92)
	background.corner_radius_top_left = 3
	background.corner_radius_top_right = 3
	background.corner_radius_bottom_left = 3
	background.corner_radius_bottom_right = 3
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.corner_radius_top_left = 3
	fill.corner_radius_top_right = 3
	fill.corner_radius_bottom_left = 3
	fill.corner_radius_bottom_right = 3
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	parent.add_child(bar)
	return bar

func _update_hotbar() -> void:
	if hotbar_slots.is_empty() or player == null:
		return
	for index in hotbar_slots.size():
		var slot_id := index + 1
		var owned: bool = player.owns_slot(slot_id)
		var selected: bool = owned and player.active_slot == slot_id
		var style := hotbar_slots[index].get_theme_stylebox("panel") as StyleBoxFlat
		if style != null:
			style.bg_color = Color(0.055, 0.072, 0.062, 0.96) if selected else Color(0.016, 0.022, 0.024, 0.90)
			if selected:
				style.border_color = Color(1.0, 0.66, 0.26, 0.98)
			elif owned:
				style.border_color = Color(0.34, 0.50, 0.52, 0.70)
			else:
				style.border_color = Color(0.15, 0.19, 0.20, 0.45)
			style.set_border_width_all(2 if selected else 1)
		hotbar_glyphs[index].active = owned
		hotbar_keys[index].modulate = Color(1.0, 0.80, 0.44) if selected else Color(0.52, 0.66, 0.68, 0.78)
	if hotbar_name_label != null:
		hotbar_name_label.text = player.active_tool_label() if player.owns_slot(player.active_slot) else "NO TOOL"


func _update_hud() -> void:
	if farm == null or clock_label == null:
		return
	clock_label.text = "D%02d   %s" % [int(farm.day), farm.clock_text()]
	status_label.text = "%02d°" % int(farm.temperature)
	if heat_bar != null:
		heat_bar.value = clampf(warmth * 100.0, 0.0, 100.0)
	if fuel_bar != null:
		fuel_bar.value = clampf((farm.fuel / 8.0) * 100.0, 0.0, 100.0)
	if health_bar != null and player != null:
		var health_ratio: float = clampf(player.health / player.MAX_HEALTH, 0.0, 1.0)
		health_bar.size.x = 172.0 * health_ratio
		health_bar.color = Color(0.62 + (1.0 - health_ratio) * 0.30, 0.17, 0.13)
	if hurt_overlay != null:
		# Venom keeps its slow amber vignette; a real wound is a short red flash.
		hurt_overlay.color = Color(0.42, 0.015, 0.010, clampf(hurt_flash, 0.0, 1.0) * 0.42)
	if down_overlay != null and not player_downed:
		down_overlay.color.a = maxf(0.0, down_overlay.color.a - get_process_delta_time() * 1.6)
	if warmth_glyph != null:
		warmth_glyph.value = warmth
		warmth_glyph.tint = Color(1.0, 0.29 + warmth * 0.27, 0.12 + warmth * 0.10)
	if fuel_glyph != null:
		fuel_glyph.value = clampf(farm.fuel / 8.0, 0.0, 1.0)
	if ammo_glyph != null:
		ammo_glyph.value = float(farm.driver_durability) / float(FarmState.DRIVER_MAX_DURABILITY)
		ammo_glyph.active = farm.driver_durability > 0
	inventory_label.text = "%02d\nBOLTS" % farm.ammo_count()
	if cricket_panel != null and cricket_label != null:
		# Visible once the player has a net or anything to carry, so a fresh shift
		# keeps its clean screen.
		cricket_panel.visible = bool(farm.net_crafted) or int(farm.live_crickets) > 0 or int(farm.dressed_crickets) > 0
		cricket_label.text = "%02d/%d IN NET   %02d DRESSED" % [int(farm.live_crickets), FarmState.NET_CAPACITY, int(farm.dressed_crickets)]
	if carry_panel != null and carry_label != null:
		# Remains, hides and ammunition are the things the player physically holds.
		var carrying := farm.carried_remains.size()
		var held_hides := int(farm.hides)
		carry_panel.visible = carrying > 0 or held_hides > 0
		carry_label.text = "%02d REMAINS   %02d HIDES   %02d BOLTS" % [carrying, held_hides, farm.ammo_count()]
	var cave_slate: String = farm.cave_slate_text()
	if slate_panel != null and slate_label != null:
		slate_panel.visible = not cave_slate.is_empty()
		slate_label.text = cave_slate
	if pocket_panel != null and pocket_label != null:
		# Visible where it is useful: in the pocket, or whenever something is
		# waiting there for the walk back.
		var pocket_active := farm.lantern_on or farm.cave_box_packed() or not farm.cave_payout.is_empty()
		if player != null and player.global_position.x > 21.0:
			pocket_active = true
		pocket_panel.visible = pocket_active and not (rail != null and rail.riding)
		pocket_label.text = "%s\n%s" % [_lantern_readout(), _clamp_readout()]
	_update_hotbar()
	if compass_glyph != null and player != null:
		compass_glyph.direction = -player.rotation.y
	var has_opening_fire_task := opening_state == "tend_fire"
	var has_opening_kit_task := opening_state == "kit"
	var has_order := not farm.orders.is_empty() or not farm.delivered_box.is_empty()
	var has_reclaimer_task := farm.thermal_regulators > 0 and not farm.heat_reclaimer_installed
	if objective_panel != null:
		objective_panel.visible = has_opening_fire_task or has_opening_kit_task or has_order or has_reclaimer_task
	if has_opening_fire_task:
		order_label.text = "TEND FIRE"
		if objective_glyph != null:
			objective_glyph.glyph = "furnace"
		if objective_arrow != null:
			objective_arrow.direction = _relative_hud_angle(FURNACE_SPOT)
	elif has_opening_kit_task:
		order_label.text = "TAKE KIT"
		if objective_glyph != null:
			objective_glyph.glyph = "gear"
		if objective_arrow != null:
			objective_arrow.direction = _relative_hud_angle(BEDSIDE_KIT_SPOT)
	elif has_reclaimer_task:
		order_label.text = "THERMAL REGULATOR"
		if objective_glyph != null:
			objective_glyph.glyph = "furnace"
		if objective_arrow != null:
			objective_arrow.direction = _relative_hud_angle(WORKBENCH_SPOT)
	elif not farm.delivered_box.is_empty():
		order_label.text = "DELIVER"
		if objective_glyph != null:
			objective_glyph.glyph = "objective"
		if objective_arrow != null:
			objective_arrow.direction = _relative_hud_angle(Vector3(5.78, 1.0, 1.15))
	elif not cave_slate.is_empty():
		# The cave channel points at the packing bench, not the hatch: this box
		# leaves through the drop, so the walk is part of the task.
		order_label.text = "PACK CAVE"
		if objective_glyph != null:
			objective_glyph.glyph = "cave"
		if objective_arrow != null:
			objective_arrow.direction = _relative_hud_angle(PACK_BENCH_SPOT)
	elif has_order:
		order_label.text = "PACK ORDER"
		if objective_glyph != null:
			objective_glyph.glyph = "objective"
		if objective_arrow != null:
			objective_arrow.direction = _relative_hud_angle(Vector3(5.78, 1.0, 1.15))
	else:
		order_label.text = ""
	if rail != null and farm.story.is_complete() and player.global_position.x > 20 and player.global_position.z < -3.5:
		var rail_objective: Dictionary = rail.objective()
		objective_panel.visible = true
		order_label.text = rail_objective.text
		objective_glyph.glyph = "gear"
		objective_arrow.direction = _relative_hud_angle(rail_objective.point)
	var danger_state := ""
	var danger_color := Color(1.0, 0.56, 0.24)
	if player != null and player.health / player.MAX_HEALTH <= 0.35:
		danger_state = "HURT"
		danger_color = Color(1.0, 0.30, 0.22)
	elif farm.venom_seconds > 0.0:
		danger_state = "VENOM"
		danger_color = Color(1.0, 0.34, 0.22)
	elif farm.starving:
		danger_state = "HUNGRY"
		danger_color = Color(1.0, 0.70, 0.28)
	elif farm.temperature <= 7.0:
		danger_state = "COLD"
		danger_color = Color(0.64, 0.86, 1.0)
	if not farm.delivered_box.is_empty():
		danger_state = "BOX" if danger_state.is_empty() else danger_state
	state_label.text = danger_state
	state_label.modulate = danger_color
	state_label.visible = not danger_state.is_empty()
	if danger_panel != null:
		danger_panel.visible = not danger_state.is_empty()
	if danger_glyph != null:
		danger_glyph.tint = danger_color
		danger_glyph.active = not danger_state.is_empty()
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.006)
	if farm.venom_seconds > 0.0:
		vignette.color = Color(0.75, 0.35, 0.0, 0.16 + 0.10 * pulse)
	else:
		vignette.color = Color(0.75, 0.35, 0.0, 0.0)
	if cold_overlay != null:
		var cold_level := clampf((7.0 - farm.temperature) / 2.0, 0.0, 1.0)
		cold_overlay.color = Color(0.78, 0.90, 1.0, cold_level * (0.18 + 0.10 * pulse))
	if message_panel != null:
		message_panel.visible = not message_label.text.is_empty()
	if message_glyph != null:
		message_glyph.glyph = _message_glyph_name(message_label.text)
	if player != null and player.is_hidden:
		prompt_label.text = ""
		if prompt_panel != null:
			prompt_panel.visible = false
	else:
		var target := _nearest_interactable()
		if opening_state == "tend_fire" and target != null and str(target.get_meta("kind", "")) != "furnace":
			target = null
		elif opening_state == "kit" and target != null and str(target.get_meta("kind", "")) != "kit":
			target = null
		prompt_label.text = _short_interaction_label(target)
		prompt_key_label.text = "X" if player.using_gamepad else "E"
		interaction_progress.visible = chain_install_elapsed >= 0.0 or target == bulkhead_crank
		interaction_progress.value = chain_install_elapsed / LINK_FIT_SECONDS if chain_install_elapsed >= 0.0 else bulkhead_crank.progress
		if prompt_glyph != null:
			prompt_glyph.glyph = _interactable_glyph_name(target)
		if prompt_panel != null:
			prompt_panel.visible = target != null
	_refresh_trays()


func _short_interaction_label(target: Node3D) -> String:
	if chain_install_elapsed >= 0.0:
		return "FITTING CHAIN LINK"
	if target == null:
		return ""
	if str(target.get_meta("kind", "")).begins_with("rail_"):
		return str(target.get_meta("label", "RAIL"))
	match str(target.get_meta("kind", "")):
		"furnace": return "TEND FIRE"
		"kit": return "TAKE KIT"
		"tray": return "TEND CULTURE"
		"kitchen": return "COOK"
		"drop": return _drop_prompt_text()
		"breach": return "LOOK INSIDE"
		"table": return "BUTCHER"
		"bench": return "PACK ORDER"
		"workbench": return "BUILD GEAR"
		"slate": return "ORDERS"
		"ledger": return "UPGRADES"
		"stair": return "LOCKED"
		"bed": return "SLEEP"
		"shutter": return "DELIVER"
		"crank": return "FIT CHAIN LINK" if farm.story.chain_broken and farm.chain_links > 0 else ("CHAIN LINK NEEDED" if farm.story.chain_broken else "PULL LEVER")
		"chain_drop": return "TAKE CHAIN LINK"
		"snare": return "PULL LEVER"
		"bulkhead": return "HOLD %s — CRANK" % ("X" if player.using_gamepad else "E")
		"cave_wheel": return "TURN WHEEL"
		"cave_marker": return "READ MARKER"
		"cave_cart": return "SEARCH CART"
		"cold_jar": return "SEARCH JAR"
		"cold_crate": return "OPEN CRATE"
		"cold_frame": return _cold_frame_prompt()
		"thermal_regulator": return "SALVAGE"
		"bait": return "LOAD BAIT"
		"gap": return "PATCH GAP"
		"carcass": return "TAKE REMAINS"
		"eat": return "EAT"
	return "USE"


func _interactable_glyph_name(target: Node3D) -> String:
	if target == null:
		return "use"
	match str(target.get_meta("kind", "")):
		"furnace": return "furnace"
		"kit": return "gear"
		"tray": return "warmth"
		"kitchen": return "cooking"
		"drop", "breach": return "cave"
		"table", "workbench": return "gear"
		"bench", "shutter": return "objective"
		"crank", "cave_wheel", "ledger": return "gear"
		"cave_marker": return "compass"
		"cave_cart", "thermal_regulator", "carcass": return "objective"
		"bait", "snare": return "hook"
		"bulkhead", "stair": return "exit"
		"bed", "eat": return "warmth"
		"gap": return "warning"
	return "use"


func _message_glyph_name(message: String) -> String:
	var upper := message.to_upper()
	if upper.contains("CAVE") or upper.contains("C-4") or upper.contains("SHUTTER"):
		return "cave"
	if upper.contains("HUNT") or upper.contains("SLIME") or upper.contains("SNARE"):
		return "warning"
	if upper.contains("FURNACE") or upper.contains("FUEL") or upper.contains("HEAT"):
		return "furnace"
	if upper.contains("BOLT") or upper.contains("DRIVER"):
		return "bolt"
	if upper.contains("SAVE") or upper.contains("SHIFT"):
		return "save"
	return "objective"


func _relative_hud_angle(world_target: Vector3) -> float:
	if player == null:
		return 0.0
	var direction := world_target - player.global_position
	direction.y = 0.0
	if direction.length_squared() < 0.001:
		return 0.0
	direction = direction.normalized()
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := player.global_transform.basis.x
	right.y = 0.0
	right = right.normalized()
	return atan2(right.dot(direction), forward.dot(direction))

# ---------------------------------------------------------------- interaction

func _nearest_interactable() -> Node3D:
	if player == null:
		return null
	if rail != null and rail.riding:
		return null
	var nearest: Node3D = null
	var nearest_distance := 2.4
	for candidate in interactables:
		if not is_instance_valid(candidate):
			continue
		var distance := player.global_position.distance_to(candidate.global_position)
		if distance >= float(candidate.get_meta("reach", 2.4)):
			continue
		# A mounted lever is only usable when the player is actually facing it.
		# Without this, the nearest object in a 2.4 m bubble wins and a player can
		# operate a door by looking at an unrelated patch of wall.
		if bool(candidate.get_meta("requires_look", false)) and not _player_is_looking_at(candidate):
			continue
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance
	return nearest


func _player_is_looking_at(target: Node3D) -> bool:
	if player == null or player.camera == null or target == null:
		return false
	# Horizontal facing only: a wall plate hangs below eye height, and the camera
	# pitch is recoil-driven, so a pitch test would make a chest-high lever
	# unusable unless the player stared at the floor.
	var eye: Vector3 = player.camera.global_position
	var to_target: Vector3 = target.global_position - eye
	if bool(target.get_meta("aim_3d", false)):
		return to_target.normalized().dot(-player.camera.global_transform.basis.z) >= float(target.get_meta("aim_dot", .94))
	var flat_target := Vector3(to_target.x, 0.0, to_target.z)
	if flat_target.length_squared() < 0.0001:
		return true
	var forward: Vector3 = -player.camera.global_transform.basis.z
	var flat_forward := Vector3(forward.x, 0.0, forward.z)
	if flat_forward.length_squared() < 0.0001:
		return false
	return flat_forward.normalized().dot(flat_target.normalized()) >= LOOK_TO_USE_DOT

func player_interact() -> void:
	if chain_install_elapsed >= 0.0:
		return
	if rail != null and rail.riding:
		rail.exit_cart()
		return
	var target := _nearest_interactable()
	if target == null:
		if player != null and player.active_slot == player.SLOT_LINK:
			_drop_held_chain_link()
			return
		show_message("Nothing within reach.", 1.2)
		return
	# A lever in transit must not fire its mechanism again: the handle would be
	# asked to stop somewhere it is not.
	var lever := target as MECH_LEVER
	if lever != null and lever.is_moving():
		return
	var crank := target as BulkheadCrank
	if crank != null and crank.is_moving():
		return
	if opening_state == "tend_fire" and str(target.get_meta("kind", "")) != "furnace":
		show_message("THE FIRE FIRST // the room is losing heat.", 1.8)
		return
	# The furnace stays usable during the kit lesson so the player can always
	# close the door they just opened.
	if opening_state == "kit" and str(target.get_meta("kind", "")) != "kit" and str(target.get_meta("kind", "")) != "furnace":
		show_message("TAKE THE BEDSIDE KIT // light and blade first.", 1.8)
		return
	if str(target.get_meta("kind", "")).begins_with("rail_"):
		rail.interact(target)
		return
	match str(target.get_meta("kind")):
		"furnace": _use_furnace()
		"kit": _use_bedside_kit()
		"tray": _use_tray(int(target.get_meta("index")))
		"table": _use_table()
		"bench": _use_bench()
		"workbench": _use_workbench()
		"kitchen": _use_kitchen()
		"drop": _use_drop()
		"chain_drop": _pick_up_chain_link(target)
		"breach": _use_breach()
		"slate": show_message(farm.order_text(), 4.0)
		"ledger": menu.open_upgrades()
		"stair": show_message("Barred from the other side. The stairs go up, but not yet.", 2.4)
		"bed": _sleep()
		"shutter": show_message(farm.leave_box(), 2.6)
		"crank": _crank()
		"cave_wheel": _use_cave_return_wheel()
		"cave_marker": _read_cave_marker()
		"cave_cart": _inspect_cave_cart()
		"cold_jar": _use_cold_jar(int(target.get_meta("index")))
		"cold_crate": _use_cold_crate()
		"cold_frame": _use_cold_frame()
		"thermal_regulator": _recover_thermal_regulator()
		"bait": _bait_hook()
		"bulkhead": _crank_bulkhead_hint()
		"snare": _toggle_hunt_snare()
		"gap": _use_gap(int(target.get_meta("index")))
		"carcass": _pick_up_carcass(target)
		"eat": _use_food()
		_: show_message("Nothing happens.", 1.2)

func _use_furnace() -> void:
	# The furnace is deliberately a small physical ritual rather than a switch:
	# open its heavy door, add a rendered unit of fuel, then close it again.
	if not furnace_door_open:
		_set_furnace_door(true)
		show_message("FURNACE OPEN // [E] throw in 1 fuel.", 2.0)
		return
	if not farm.furnace_lit:
		if farm.fuel < 1.0:
			show_message("The firebox is empty. Butcher something for fuel.", 2.2)
			return
		var completed_opening_fire := opening_state == "tend_fire"
		farm.fuel -= 1.0
		_throw_fuel_into_furnace()
		farm.furnace_lit = true
		if completed_opening_fire:
			opening_state = "kit"
			show_message("FIRE CATCHES // the room will slowly recover. Open the BEDSIDE KIT for tools.", 3.2)
		else:
			show_message("Fuel hisses into the coals. The furnace catches.", 2.4)
		return
	_set_furnace_door(false)
	show_message("Furnace door sealed. Heat holds in the room.", 1.8)


func _set_furnace_door(open: bool, play_sound: bool = true) -> void:
	furnace_door_open = open
	if play_sound:
		# A dry hinge creak on the way out, a heavier iron clank on the way in.
		if open:
			_play_sfx(FURNACE_DOOR_CREAK_SFX, -9.0, randf_range(0.94, 1.03))
		else:
			_play_sfx(FURNACE_DOOR_CLOSE_SFX, -8.0, randf_range(0.92, 1.02))
	if furnace_door == null:
		return
	var tween := create_tween()
	var target_rotation := deg_to_rad(-82.0) if open else 0.0
	tween.tween_property(furnace_door, "rotation:y", target_rotation, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _throw_fuel_into_furnace() -> void:
	# Keep the fuel physical enough to read in first person: a rough fat/coal
	# chunk crosses the open mouth and disappears into the fire before the glow
	# rises. The simulation remains deterministic; this is purely its feedback.
	var chunk := MeshInstance3D.new()
	chunk.name = "FurnaceFuelChunk"
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.18, 0.14, 0.22)
	chunk.mesh = mesh
	chunk.material_override = _material(Color(0.11, 0.075, 0.035), 0.98, 0.0)
	chunk.position = FURNACE_SPOT + Vector3(0.0, 1.02, 1.10)
	chunk.rotation = Vector3(0.22, 0.35, -0.16)
	add_child(chunk)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(chunk, "position", FURNACE_SPOT + Vector3(0.0, 1.02, 0.47), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(chunk, "scale", Vector3.ONE * 0.28, 0.22)
	tween.chain().tween_callback(chunk.queue_free)

func _use_tray(index: int) -> void:
	if index < 0 or index >= farm.trays.size():
		return
	_open_tray_lid(index)
	var tray: Dictionary = farm.trays[index]
	var was_active: bool = bool(tray["active"]) and not bool(tray["dead"])
	var result := ""
	if was_active and farm.tray_harvestable(index):
		if player == null or player.active_slot != player.SLOT_NET:
			# C2.7 // the net has to be the tool in hand. A woven net sitting in
			# the hotbar is not enough to scoop with.
			result = "The net has to be in hand — press 4. The colony can wait."
		else:
			var caught_before: int = int(farm.live_crickets)
			result = farm.harvest_tray(index)
			if int(farm.live_crickets) > caught_before:
				player.play_net_sweep()
				_play_net_catch()
	elif was_active:
		result = farm.feed_tray(index)
	elif farm.live_crickets >= FarmState.CRICKETS_TO_SEED:
		# A carried starter founds the colony; the parts starter is the fallback.
		result = farm.seed_tray(index)
	elif bool(tray["dead"]):
		result = farm.feed_tray(index)
	else:
		result = farm.seed_tray(index)
	show_message(result, 2.4)
	if bool(tray["active"]) and not bool(tray["dead"]) and not result.begins_with("The net has to be in hand"):
		# C2.13 // the tray itself answers the culture questions: population,
		# capacity, feed state and the countdown to the next scoopable size.
		show_message(farm.tray_status(index), 3.4)
	if not was_active and bool(tray["active"]) and not bool(tray["dead"]):
		_ensure_tray_colony(index)
	_refresh_trays()


func _play_net_catch() -> void:
	# The hoop goes through the air first; the crickets land a beat later, once
	# the net has actually closed over them.
	net_catches += 1
	if net_swish_player != null:
		net_swish_player.stream = NET_SWISH_SFX
		net_swish_player.pitch_scale = randf_range(0.93, 1.07)
		net_swish_player.play()
	if chirp_player != null:
		var delay := create_tween()
		delay.tween_interval(0.16)
		delay.tween_callback(_play_cricket_chirp)


func _play_cricket_chirp() -> void:
	if chirp_player == null:
		return
	chirp_player.stream = CRICKET_CHIRP_SFX
	chirp_player.pitch_scale = randf_range(0.88, 1.16)
	chirp_player.play()


func _ensure_tray_colony(index: int) -> void:
	# A seeded frame gets living crickets the moment it becomes real, using the
	# same imported rig and wander loop as the first tray.
	if farm == null or index < 0 or index >= farm.trays.size():
		return
	if str(farm.trays[index].get("species", "")) != "cricket":
		return
	for item in tray_crickets:
		if typeof(item) == TYPE_DICTIONARY and int((item as Dictionary).get("tray_index", -1)) == index:
			return
	_build_cricket_colony(index)


func _refresh_tray_marks() -> void:
	# The frame's "02" stencil and its prompt have to agree with the colony that is
	# actually in it.
	if farm == null:
		return
	for index in tray_bodies.size():
		var body: Node3D = tray_bodies[index] as Node3D
		if body == null or index >= farm.trays.size():
			continue
		var tray: Dictionary = farm.trays[index]
		var mark := body.get_node_or_null("UnfinishedMark") as Label3D
		if mark != null:
			mark.visible = not bool(tray["active"])
		if str(body.get_meta("kind", "")) != "tray":
			continue
		var label := "CULTURE TRAY %d — SEED A COLONY" % (index + 1)
		if bool(tray["dead"]):
			label = "CULTURE TRAY %d — COLONY DEAD" % (index + 1)
		elif bool(tray["active"]):
			var ready := farm.tray_harvestable(index)
			var holding_net := player != null and player.active_slot == player.SLOT_NET
			var action := "HARVEST" if ready and holding_net else ("NET NEEDED (4)" if ready else "TEND")
			# C2.13 // the population sits on the station itself, so the colony's
			# size and capacity are readable before the player commits a press.
			if str(tray.get("species", "")) == "cricket":
				label = "CULTURE TRAY %d — %d/%d LIVE · %s" % [index + 1, farm.tray_population(index), FarmState.CRICKET_CAPACITY, action]
			else:
				label = "CULTURE TRAY %d — %s" % [index + 1, action]
		body.set_meta("label", label)


func _open_tray_lid(index: int) -> void:
	if index < 0 or index >= tray_lids.size():
		return
	var lid: Node3D = tray_lids[index] as Node3D
	if lid == null:
		return
	var tween := create_tween()
	tween.tween_property(lid, "rotation:x", deg_to_rad(-68.0), 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_interval(1.15)
	tween.tween_property(lid, "rotation:x", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

func _build_net_prop() -> void:
	# The net is a real object in the room, not just a recipe flag: it leans where
	# the workbench and the trays meet, so the framing reads as the kit it is.
	var prop := CRICKET_NET_MODEL.instantiate() as Node3D
	prop.name = "CricketNetProp"
	prop.position = WORKBENCH_SPOT + Vector3(0.62, 0.0, -0.30)
	prop.rotation = Vector3(deg_to_rad(-9.0), deg_to_rad(34.0), deg_to_rad(4.0))
	prop.visible = false
	add_child(prop)
	cricket_net_prop = prop


func _refresh_net_prop() -> void:
	if cricket_net_prop != null:
		cricket_net_prop.visible = bool(farm != null and farm.net_crafted)


func _use_table() -> void:
	show_message(farm.butcher_carried(), 3.0)

## The clamp's prompt is a status line, not a verb: the player should be able to
## read what the next press will do from a step away, without pressing it. Pure
## reads only — nothing here may move a paper, a box or a payment.
## The lantern line of the pocket readout. Burn is shown in whole in-game minutes
## because that is the unit the fuel is actually spent in.
func _lantern_readout() -> String:
	if not farm.lantern_crafted:
		return "LANTERN  NOT BUILT"
	if farm.lantern_on:
		return "LANTERN  ON · %dm LEFT" % int(ceil(farm.lantern_minutes_left()))
	if float(farm.fuel) < 1.0:
		return "LANTERN  OFF · DRY"
	return "LANTERN  OFF · READY"


## The clamp line, in the same priority order as the prompt, so the HUD and the
## key press cannot disagree about what is waiting.
func _clamp_readout() -> String:
	if farm.cave_payout_ready():
		return "CLAMP  PAYMENT READY"
	if not farm.cave_payout.is_empty():
		var minutes := int(ceil(maxf(0.0, float(farm.cave_payout.get("ready_hour", 0.0)) - farm.abs_hour()) * 60.0))
		return "CLAMP  PAID IN %dm" % minutes
	if farm.cave_box_packed():
		return "CLAMP  BOX TO LEAVE"
	if farm.cave_has_torn_paper():
		return "CLAMP  TORN PAPER"
	var papers: int = farm.cave_paper_count()
	if papers > 0:
		return "CLAMP  %d PAPER%s" % [papers, "" if papers == 1 else "S"]
	if not farm.packed_box.is_empty():
		return "CLAMP  WRONG BOX"
	return "CLAMP  EMPTY"


func _drop_prompt_text() -> String:
	if farm == null:
		return "TRADE DROP"
	if farm.cave_payout_ready():
		return "TRADE DROP — COLLECT PAYMENT"
	if not farm.cave_payout.is_empty():
		return "TRADE DROP — PAYMENT LATER"
	if farm.cave_box_packed():
		return "TRADE DROP — LEAVE BOX"
	if farm.cave_has_torn_paper():
		return "TRADE DROP — TORN PAPER"
	if not farm.cave_papers_lying().is_empty():
		return "TRADE DROP — READ PAPER"
	if not farm.packed_box.is_empty():
		return "TRADE DROP — NOT THIS BOX"
	return "TRADE DROP — EMPTY"


func _use_drop() -> void:
	# The clamp is the whole cave channel in one key: payment first (because it is
	# the reason the walk was worth it), then a box to leave, then a paper to read.
	var text := ""
	if farm.cave_payout_ready():
		text = farm.collect_cave_payout()
	elif not farm.cave_payout.is_empty():
		text = "The clamp is shut. Whoever empties it has not walked out this way yet."
	elif farm.cave_box_packed():
		text = farm.drop_cave_box()
	elif not farm.cave_papers_lying().is_empty():
		text = farm.take_cave_paper()
	elif not farm.packed_box.is_empty():
		text = farm.drop_cave_box()
	else:
		text = "The clamp is empty. Nobody has left a paper here since the last shift."
	# Work at the clamp is not quiet work: the breach answers company.
	if _stir_cinder("drop"):
		text += " The breach answers."
	show_message(text, 3.2)
	_refresh_drop_papers()


func _use_breach() -> void:
	# Looking in is a glimpse, not a fight: one cue, no gate, and the wall stays open.
	var text := "Warm air. Something shifting in the dark, breathing slow. You back away."
	if _stir_cinder("breach"):
		text = "Warm air. The dark heaves once, and something heavy comes out of the breach."
	show_message(text, 3.4)
	if breach_light != null:
		var flare := create_tween()
		flare.tween_property(breach_light, "light_energy", 1.45, 0.25)
		flare.tween_property(breach_light, "light_energy", 0.78, 1.4)


func _use_food() -> void:
	if menu == null:
		show_message(farm.eat(), 2.2)
		return
	menu.open_food()


## The crate's three buttons all land here, so a test can eat exactly what a
## click eats.
func food_action(kind: String) -> String:
	var result: String = farm.eat(kind)
	show_message(result, 2.4)
	return result


func _use_bench() -> void:
	if not farm.delivered_box.is_empty():
		show_message("A box is already waiting in the shutter.", 2.0)
		return
	show_message(farm.pack_for_order(), 2.8)

func _use_workbench() -> void:
	if menu == null:
		show_message("The workbench is dark. No patterns visible.", 1.8)
		return
	menu.open_workbench()


func _use_kitchen() -> void:
	if menu == null:
		show_message("The board is bare. No tools, no heat.", 1.8)
		return
	menu.open_kitchen()


## Every kitchen button goes through here, so a test drives the same path a
## click does.
func kitchen_action(action_name: String) -> String:
	var result := "Nothing to do at the board."
	match action_name:
		"dress":
			result = farm.dress_crickets()
		"cook":
			result = farm.cook_meal()
			if result.begins_with("Cooking"):
				_kitchen_steam_burst()
		"cure":
			result = farm.cure_jerky()
		"collect":
			result = farm.collect_kitchen()
	show_message(result, 2.8)
	_refresh_kitchen_state()
	return result


## The quantity stepper's commit: queue N batches of one kind through the same
## farm call a single-batch button uses, so there is exactly one cooking path.
func kitchen_queue(kind: String, quantity: int) -> String:
	var result: String = farm.queue_kitchen(kind, quantity)
	if kind == "cook" and result.begins_with("Cooking"):
		_kitchen_steam_burst()
	show_message(result, 2.8)
	_refresh_kitchen_state()
	return result


func _refresh_kitchen_state() -> void:
	if farm == null:
		return
	if kitchen_meal_plate != null:
		kitchen_meal_plate.visible = int(farm.meals) + int(farm.ready_meals) > 0
	if kitchen_jerky_bundle != null:
		kitchen_jerky_bundle.visible = int(farm.jerky) + int(farm.ready_jerky) > 0
	if kitchen_body != null:
		kitchen_body.set_meta("label", "KITCHEN — %d LIVE / %d DRESSED / %d READY / %d QUEUED" % [
			int(farm.live_crickets), int(farm.dressed_crickets), int(farm.kitchen_ready_total()), farm.kitchen_jobs.size()])

func craft_workbench_recipe(recipe_id: String) -> String:
	var had_storage_rack := farm.storage_rack_installed
	var had_heat_reclaimer := farm.heat_reclaimer_installed
	var result: String = farm.craft_at_workbench(recipe_id)
	if not had_storage_rack and farm.storage_rack_installed:
		_refresh_storage_rack_visual(true)
	if not had_heat_reclaimer and farm.heat_reclaimer_installed:
		_refresh_heat_reclaimer_visual(true)
		_refresh_cave_regulator_pickup()
	_refresh_net_prop()
	show_message(result, 2.6)
	return result

func _use_gap(index: int) -> void:
	var was_sealed := index >= 0 and index < farm.gaps.size() and bool(farm.gaps[index]["sealed"])
	var result: String = farm.patch_gap(index)
	var is_sealed := index >= 0 and index < farm.gaps.size() and bool(farm.gaps[index]["sealed"])
	_refresh_gap_patch_visuals(index if is_sealed and not was_sealed else -1)
	show_message(result, 2.6)

func _sleep() -> void:
	var summary: String = farm.sleep()
	breach_day = int(farm.day) if farm.clock >= 20.0 else breach_day
	show_message(summary, 3.2)
	if not farm.report.is_empty():
		show_message(str(farm.report[farm.report.size() - 1]), 3.2)

func _begin_chain_install() -> void:
	if chain_install_elapsed >= 0.0:
		return
	if farm.story.stage != StoryState.STAGE_CHAIN_SNAPPED:
		show_message("CLEAR THE CHAMBER BEFORE REPAIRING THE CHAIN", 2.3)
		return
	if farm.chain_links <= 0:
		show_message("CHAIN LINK NEEDED · 1 PART + 1 CHITIN AT THE WORKBENCH", 2.8)
		return
	if player.is_machete_busy() or player.global_position.distance_to(shutter_lever.global_position) > LEVER_REACH:
		return
	shutter_lever.set_chain_snapped(true)
	player.set_link_carried(true)
	player.select_slot(player.SLOT_LINK)
	chain_install_prop = player.link_view.duplicate() as Node3D
	chain_install_prop.name = "InstallingChainLink"
	add_child(chain_install_prop)
	chain_install_prop.global_transform = player.link_view.global_transform
	chain_install_prop.visible = true
	chain_install_start = chain_install_prop.global_transform
	chain_install_health = player.health
	chain_install_elapsed = 0.0
	player.link_install_active = true
	player.link_view.visible = false
	show_message("FITTING CHAIN LINK", 1.0)


func _cancel_chain_install() -> void:
	chain_install_elapsed = -1.0
	if is_instance_valid(chain_install_prop):
		chain_install_prop.queue_free()
	chain_install_prop = null
	if player != null:
		player.link_install_active = false
		player.set_link_carried(farm.chain_links > 0)


func _update_chain_install(delta: float) -> void:
	if chain_install_elapsed < 0.0:
		return
	if player_downed or player.health < chain_install_health or farm.chain_links <= 0 or not farm.story.chain_broken or player.global_position.distance_to(shutter_lever.global_position) > LEVER_REACH:
		_cancel_chain_install()
		return
	chain_install_elapsed += delta
	var fraction := clampf(chain_install_elapsed / LINK_FIT_SECONDS, 0.0, 1.0)
	var reach := smoothstep(0.0, 0.72, fraction)
	var fitted: Transform3D = shutter_lever.chain_socket.global_transform
	chain_install_prop.global_transform = chain_install_start.interpolate_with(fitted, reach)
	chain_install_prop.global_position.y += sin(reach * PI) * 0.065
	if fraction < 1.0:
		return
	var installed: bool = farm.fit_shutter_chain()
	_cancel_chain_install()
	if not installed:
		return
	shutter_lever.play_chain_fit()
	_play_sfx(HIT_SFX, -9.0, 1.18)
	story_second_wave = _spawn_burrower(OUTER_HUNT_SPAWN, true, _hunt_lure_config())
	crank_cooldown = 0.0
	_crank()
	show_message("CHAIN FITTED · SHUTTER CONTROL RESTORED", 2.6)


func _crank() -> void:
	if crank_cooldown > 0.0:
		return
	if farm.story.chain_broken:
		_begin_chain_install()
		return
	# The lever is the control. If it refuses the throw (already there, or still
	# travelling) the shutter must not move either, or the two would desync.
	if shutter_lever != null and not shutter_lever.pull(not shutter_open):
		return
	crank_cooldown = 1.6 * (2.0 if farm.venom_seconds > 0.0 else 1.0)
	if audio != null:
		audio.play_chain()
	if shutter_open:
		shutter_open = false
		_move_shutter(0.0)
		if _is_slime_in_hunt_chamber():
			show_message("Outer shutter sealed. The hunt chamber is contained.", 2.4)
		else:
			show_message("Outer shutter seated. Nothing made it into the hunt room.", 2.2)
	else:
		shutter_open = true
		_move_shutter(2.6)
		if lure_left > 0.0 and burrowers.is_empty():
			_spawn_burrower(OUTER_HUNT_SPAWN, true, _hunt_lure_config())
			show_message("Outer shutter open. Wait safely: the bait is drawing something into the hunt room.", 3.2)
		else:
			show_message("Outer shutter open. Cold air and the maintenance tunnel beyond.", 2.1)

func _move_shutter(height: float) -> void:
	if shutter_body == null:
		return
	var tween := create_tween()
	tween.tween_property(shutter_body, "position:y", height, 0.85).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func _use_cave_return_wheel() -> void:
	# The outside control only ever opens the shutter. Closing it from the cave
	# would be an easy way to strand a player, so containment remains a deliberate
	# decision at the safe-side crank.
	if shutter_open:
		show_message("The shutter is already lifted. Follow the orange lamps home.", 2.0)
		return
	shutter_open = true
	_move_shutter(2.6)
	# The wheel and the warm-side lever are linked on the same shaft: the inside
	# handle must follow the cave-side control instead of lying about the shutter.
	if shutter_lever != null:
		shutter_lever.set_engaged(true, false)
	if audio != null:
		audio.play_chain()
	show_message("Cave-side wheel releases the shutter. The warm basement is open again.", 2.7)


func _read_cave_marker() -> void:
	show_message("B-01 // FURNACE RETURN ROUTE. If the hunt shutter closes, use the wheel on the cave side. The orange lamps lead back.", 4.0)


func _inspect_cave_cart() -> void:
	if farm.thermal_regulators > 0 and not farm.heat_reclaimer_installed:
		show_message("C-4 SERVICE CART // the thermal regulator is in your pack. Fit it at the workbench with 2 parts.", 3.8)
		return
	if farm.heat_reclaimer_installed:
		show_message("C-4 SERVICE CART // dead battery, frozen canisters, cut cable. Its heat regulator is keeping B-01 warm again.", 4.0)
		return
	show_message("C-4 SERVICE CART // dead battery, frozen canisters, cut cable. A working thermal regulator is still bolted to the deck.", 4.0)


func _recover_thermal_regulator() -> void:
	if farm.heat_reclaimer_installed:
		show_message("The C-4 thermal regulator is already fitted beside the furnace.", 2.2)
		return
	if farm.thermal_regulators > 0:
		show_message("Thermal regulator secured. Bring it to the salvage workbench with 2 parts.", 2.4)
		return
	farm.thermal_regulators = 1
	_refresh_cave_regulator_pickup()
	if audio != null:
		audio.play_chain()
	show_message("THERMAL REGULATOR RECOVERED // return to the salvage workbench. Fit it with 2 parts to reclaim furnace heat.", 4.2)

func _bait_hook() -> void:
	if lure_left > 0.0:
		show_message("The bait chute is already loaded.", 1.6)
		return
	if farm.fuel < 1.0:
		show_message("No fat to spare. Render some at the butcher table.", 2.2)
		return
	farm.fuel -= 1.0
	lure_left = 45.0
	show_message("Fat drops through the chute. Open the outer shutter and wait in the safe room.", 2.8)


## A completed crank turn is the only thing that moves the bulkhead. The wheel
## already flipped its own state; this seats or raises the gate to match.
func _on_bulkhead_cranked(down: bool) -> void:
	if bulkhead_crank != null and bulkhead_crank.is_engaged() != down:
		bulkhead_crank.set_engaged(down, true)
	hunt_bulkhead_open = down
	_move_hunt_bulkhead(2.6 if down else 0.0)
	if down and story_enabled and farm.story.stage == StoryState.STAGE_BANGING:
		if farm.story.advance_to(StoryState.STAGE_FIRST_WAVE):
			show_message("The bulkhead is up. They are in the chamber with you.", 2.8)
			return
	if not down:
		show_message("Hunt bulkhead sealed. The warm room is safe again.", 2.2)
		return
	if shutter_open:
		show_message("Hunt bulkhead open — outer shutter is still open. Do not let the cold into the farm.", 2.8)
	else:
		show_message("Hunt bulkhead open. Step into the chamber only when you are ready to kill.", 2.8)


## Holding E at the crank winds it; letting go early springs it back. The press
## itself is only a hint, so a single tap can never open the door.
func _update_bulkhead_crank() -> void:
	if bulkhead_crank == null:
		return
	var can_wind := opening_state != "tend_fire" and opening_state != "kit"
	if menu != null and menu.visible:
		can_wind = false
	can_wind = can_wind and player != null and not player.is_hidden
	can_wind = can_wind and _nearest_interactable() == bulkhead_crank
	if can_wind and Input.is_action_pressed("interact"):
		bulkhead_crank.begin_hold()
	else:
		bulkhead_crank.end_hold()


# ---------------------------------------------------------------- first night

## Tooling hook for the C3 suite: arm the opening without playing the whole wake
## tutorial, and optionally skip the three-second beat.
func begin_first_night_for_test(immediate: bool = true) -> void:
	story_enabled = true
	story_wait = 0.0 if immediate else STORY_BANG_DELAY


func _update_story(delta: float) -> void:
	if farm == null or not story_enabled:
		return
	if farm.story.is_complete():
		return
	if farm.story.stage == StoryState.STAGE_DORMANT:
		if opening_state != "complete":
			return
		if story_wait < 0.0:
			story_wait = STORY_BANG_DELAY
		story_wait -= delta
		if story_wait <= 0.0:
			_begin_banging()
		return
	if farm.story.stage == StoryState.STAGE_FIRST_WAVE:
		_update_first_wave()
		return
	if farm.story.stage != StoryState.STAGE_BANGING:
		return
	if story_shudder > 0.0:
		story_shudder = maxf(0.0, story_shudder - delta)
		if shutter_body != null:
			# The gate is mounted at its own z; the shudder is an offset from that,
			# never a move to the world origin.
			shutter_body.position.z = OUTER_HUNT_SHUTTER_SPOT.z - (0.035 if story_shudder > 0.0 else 0.0)
	# The beat ends the moment the bulkhead is wound up: the pair stops hitting
	# the shutter and waits inside the chamber, because the fight is the next
	# stage and nothing here should land a free hit.
	if hunt_bulkhead_open:
		_update_first_wave()
		return
	story_bang_clock -= delta
	if story_bang_clock <= 0.0:
		story_bang_clock = STORY_BANG_CADENCE
		_story_shutter_strike()


## The scripted pair is here to work the shutter, not to hunt. They arrive at
## the far side of the chamber, are held still by speed 0, and face the door;
## their strikes are driven by the cadence above so the beat is readable and
## never depends on pathfinding luck.
func _begin_banging() -> void:
	if farm.story.stage != StoryState.STAGE_DORMANT:
		return
	if not farm.story.advance_to(StoryState.STAGE_BANGING):
		return
	farm.story.banging_done = true
	story_wait = -1.0
	story_bang_clock = 0.9
	story_pair.clear()
	for offset in [-0.55, 0.55]:
		var creature = _spawn_burrower(Vector3(9.45, 0.0, -2.0 + offset))
		creature.speed = 0.0
		creature.rotation.y = -PI * 0.5
		story_pair.append(creature)
	_play_sfx(HIT_SFX, -4.0, 0.62)
	show_message(str(STORY_BANG_LINES[0]), 2.6)
	story_line_index = 1


## The first wave is ordinary burrowers, but only one is allowed to engage at a
## time. The second stays put until the first is dead, so a player with only a
## blade is never in a two-on-one.
func _update_first_wave() -> void:
	if farm.story.stage != StoryState.STAGE_FIRST_WAVE:
		return
	var alive: Array = []
	for creature in story_pair:
		if is_instance_valid(creature) and burrowers.has(creature):
			alive.append(creature)
	if alive.is_empty():
		story_pair.clear()
		farm.story.advance_to(StoryState.STAGE_CHAIN_SNAPPED)
		show_message("Both are dead. Something is lying in the chamber. Gather the chitin.", 3.0)
		return
	for i in alive.size():
		var creature = alive[i]
		creature.speed = 4.2 if i == 0 else 0.0
		creature.set_hunt_lure(HUNT_BAIT_SPOT if i == 0 else creature.global_position)


func _story_shutter_strike() -> void:
	story_bangs += 1
	story_shudder = STORY_SHUDDER_SECONDS
	_play_sfx(HIT_SFX, -6.0, 0.78)
	_story_dust()
	show_message(str(STORY_BANG_LINES[story_line_index % STORY_BANG_LINES.size()]), 1.9)
	story_line_index += 1


## A short-lived puff at the shutter seam, so the hit is visible and not only
## audible. It frees itself once the particles are spent.
func _story_dust() -> void:
	if shutter_body == null:
		return
	var dust := CPUParticles3D.new()
	dust.name = "StoryShutterDust"
	dust.one_shot = true
	dust.emitting = true
	dust.amount = 14
	dust.lifetime = 0.45
	dust.explosiveness = 0.95
	dust.direction = Vector3(-1.0, 0.35, 0.0)
	dust.spread = 30.0
	dust.initial_velocity_min = 0.6
	dust.initial_velocity_max = 1.7
	dust.gravity = Vector3(0.0, -2.4, 0.0)
	dust.scale_amount_min = 0.02
	dust.scale_amount_max = 0.05
	var mote := BoxMesh.new()
	mote.size = Vector3(0.03, 0.03, 0.03)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.55, 0.52, 0.45, 0.55)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mote.material = material
	dust.mesh = mote
	dust.position = shutter_body.position + Vector3(-0.16, 0.85, 0.0)
	add_child(dust)
	dust.finished.connect(dust.queue_free)


func _crank_bulkhead_hint() -> void:
	if hunt_bulkhead_open:
		show_message("HOLD [%s] TO WIND THE BULKHEAD DOWN." % ("X" if player.using_gamepad else "E"), 1.8)
	else:
		show_message("HOLD [E] TO WIND THE BULKHEAD UP. Let go and it springs back.", 2.2)


## Tooling hook: put the bulkhead in a state without making a person hold the
## wheel for a second and a half. The real control is exercised in
## workflow_c1_controls; suites about the room use this to stage it.
func set_hunt_bulkhead_for_test(open: bool) -> void:
	hunt_bulkhead_open = open
	_move_hunt_bulkhead(2.6 if open else 0.0)
	if bulkhead_crank != null:
		bulkhead_crank.set_engaged(open, true)


func _move_hunt_bulkhead(height: float) -> void:
	if hunt_bulkhead_body == null:
		return
	var tween := create_tween()
	tween.tween_property(hunt_bulkhead_body, "position:y", height, 0.72).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)


func is_player_in_hunt_chamber() -> bool:
	if player == null:
		return false
	return player.global_position.x > 6.15 and player.global_position.x < 9.85 and player.global_position.z > -3.85 and player.global_position.z < -0.15


func _is_slime_in_hunt_chamber() -> bool:
	for creature in burrowers:
		if not is_instance_valid(creature):
			continue
		if creature.global_position.x > 6.15 and creature.global_position.x < 9.85 and creature.global_position.z > -3.85 and creature.global_position.z < -0.15:
			return true
	return false

func _pick_up_carcass(node: Node3D) -> void:
	if not is_instance_valid(node) or not interactables.has(node):
		return
	farm.carry_remains(str(node.get_meta("quality", "C")), str(node.get_meta("variant", "")))
	interactables.erase(node)
	node.queue_free()
	show_message("Remains +1 · carrying %d. Take them to the table." % farm.carried_remains.size(), 2.0)

# ---------------------------------------------------------------- player actions

func player_craft() -> void:
	if farm.venom_seconds > 0.0 and farm.antidotes > 0:
		show_message(farm.drink(), 2.2)
		return
	if farm.venom_seconds > 0.0:
		show_message("No antidote. Craft one at the salvage workbench.", 2.2)
		return
	show_message("Craft gear at the salvage workbench. [C] only drinks an antidote.", 2.2)

func player_pulse() -> void:
	if not player.riveter_equipped:
		show_message("BOLT DRIVER IS IN THE BEDSIDE KIT.", 1.6)
		return
	var next_type: String = farm.cycle_bolt_type()
	player.play_riveter_reload()
	show_message("BOLT LOAD: %s // %d remaining. [Q] cycle." % [next_type, farm.ammo_count()], 1.8)

func player_fire() -> void:
	if chain_install_elapsed >= 0.0:
		return
	# Left click acts on whatever is actually in the hand: the blade swings, the
	# torch clicks on, and only the bolt driver spends ammunition.
	if player.active_slot == player.SLOT_MACHETE:
		player_melee()
		return
	if player.active_slot == player.SLOT_TORCH:
		player_torch_click()
		return
	if player.active_slot != player.SLOT_DRIVER:
		show_message("HANDS CLEAR // choose a tool first.", 1.0)
		return
	if not player.riveter_equipped:
		shot_cooldown = 0.4
		if audio != null:
			audio.play_dry()
		show_message("BOLT DRIVER IS IN THE BEDSIDE KIT.", 1.8)
		return
	if shot_cooldown > 0.0:
		return
	if farm.driver_durability <= 0:
		shot_cooldown = 0.5
		if audio != null:
			audio.play_dry()
		show_message("Bolt driver seized. Rebuild it at the salvage workbench.", 2.0)
		return
	var bolt_type: String = farm.selected_bolt_type
	if farm.ammo_count(bolt_type) <= 0:
		shot_cooldown = 0.5
		if audio != null:
			audio.play_dry()
		if farm.bolts + farm.broadhead_bolts + farm.tether_bolts <= 0:
			show_message("NO BOLTS // the blade makes the first kill, then shape ammunition at the bench.", 2.4)
		else:
			show_message("No %s bolts. [Q] cycle load or craft more." % farm.selected_ammo_label().to_lower(), 1.8)
		return
	if not farm.consume_selected_ammo():
		return
	farm.wear_driver()
	shot_cooldown = 0.92 if bolt_type == "broadhead" else 0.78
	player.apply_shot_recoil(randf_range(0.03, 0.05), randf_range(-0.01, 0.01))
	if audio != null:
		audio.play_bolt()
	var origin: Vector3 = player.camera.global_position
	var forward: Vector3 = -player.camera.global_transform.basis.z
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + forward * 16.0)
	query.exclude = [player.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		show_message("The %s bolt goes into the dark. Driver %d/%d." % [farm.selected_ammo_label().to_lower(), farm.driver_durability, FarmState.DRIVER_MAX_DURABILITY], 1.8)
		return
	var collider = hit.get("collider")
	if collider is Burrower:
		var prey := collider as Burrower
		match bolt_type:
			"broadhead":
				prey.take_hit(2, "broadhead")
				show_message("Broadhead bites deep. Fast kill, ruined hide. Driver %d/%d." % [farm.driver_durability, FarmState.DRIVER_MAX_DURABILITY], 2.0)
			"tether":
				prey.apply_tether(5.0)
				show_message("Tether cinches tight. Finish it cleanly with the hook. Driver %d/%d." % [farm.driver_durability, FarmState.DRIVER_MAX_DURABILITY], 2.2)
			_:
				prey.take_hit(1, "standard")
				show_message("Salvage bolt hits. It staggers, but the hide is marked. Driver %d/%d." % [farm.driver_durability, FarmState.DRIVER_MAX_DURABILITY], 2.0)
	else:
		show_message("Bolt bites the wall. Loud, and nothing else. Driver %d/%d." % [farm.driver_durability, FarmState.DRIVER_MAX_DURABILITY], 1.8)

func player_select_slot(slot: int) -> void:
	if player == null:
		return
	if player.is_machete_busy() and slot != player.SLOT_MACHETE:
		show_message("BLADE IS STILL RECOVERING.", 0.9)
		return
	if not player.select_slot(slot):
		show_message("THAT TOOL IS STILL IN THE BEDSIDE KIT.", 1.4)
		return
	show_message("%s IN HAND" % player.active_tool_label(), 0.9)


func player_holster() -> void:
	if player == null:
		return
	if not player.put_away_right_hand():
		show_message("BLADE IS STILL RECOVERING.", 0.9)
		return
	show_message("HANDS CLEAR", 0.8)


## The gland lantern's own control. It is the pocket's light, not a replacement
## for the torch, so both can be carried and only one has a fuel account.
func player_lantern_click() -> void:
	var result: String = farm.toggle_lantern()
	player.set_lantern_on(farm.lantern_on)
	show_message(result, 2.6)


func player_torch_click() -> void:
	if not player.flashlight_acquired:
		show_message("TORCH IS IN THE BEDSIDE KIT.", 1.6)
		return
	if player.flashlight_charge <= 0.0:
		show_message("TORCH BATTERY DEPLETED", 1.8)
		return
	show_message("TORCH %s" % ("ON" if player.toggle_torch() else "OFF"), 1.0)


func player_melee() -> void:
	if chain_install_elapsed >= 0.0:
		return
	if rail != null and rail.riding: return
	if not player.machete_equipped:
		show_message("MACHETE IS IN THE BEDSIDE KIT.", 1.8)
		return
	# R is the panic draw: it brings the blade up even when the driver is out.
	if player.active_slot != player.SLOT_MACHETE:
		player.select_slot(player.SLOT_MACHETE)
	if player.is_machete_busy():
		return
	var attack_kind: String = player.begin_machete_attack()
	if attack_kind.is_empty():
		return
	# The strike is resolved by the view animation at its contact frame, not when
	# the key is pressed. A moving slime can therefore dodge or walk into range.
	shot_cooldown = maxf(shot_cooldown, player.machete_attack_duration)
	if swing_player != null:
		swing_player.stream = SWING_SFX
		match attack_kind:
			"thrust": swing_player.pitch_scale = randf_range(0.82, 0.90)
			"diagonal": swing_player.pitch_scale = randf_range(1.00, 1.08)
			_: swing_player.pitch_scale = randf_range(0.92, 1.00)
		swing_player.play()


func player_machete_strike(attack_kind: String) -> void:
	if player == null or not player.machete_equipped or player.active_slot != player.SLOT_MACHETE:
		return
	var reach := 2.02
	var arc_dot := 0.18
	var knockback := 3.25
	match attack_kind:
		"horizontal":
			reach = 2.06
			arc_dot = -0.06
			knockback = 3.00
		"diagonal":
			reach = 2.18
			arc_dot = 0.08
			knockback = 3.42
		"thrust":
			reach = 2.48
			arc_dot = 0.62
			knockback = 3.78
	var forward: Vector3 = -player.camera.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.001:
		return
	forward = forward.normalized()
	var target: Burrower = null
	var target_distance := INF
	for creature in burrowers.duplicate():
		if not is_instance_valid(creature):
			continue
		var offset: Vector3 = creature.global_position - player.global_position
		offset.y = 0.0
		var distance: float = offset.length()
		if distance <= 0.08 or distance > reach:
			continue
		if forward.dot(offset.normalized()) < arc_dot:
			continue
		if distance < target_distance:
			target = creature as Burrower
			target_distance = distance
	if target == null:
		show_message("The machete cuts air.", 0.9)
		return
	var impact_direction: Vector3 = target.global_position - player.global_position
	impact_direction.y = 0.0
	if impact_direction.length_squared() < 0.001:
		impact_direction = forward
	else:
		impact_direction = impact_direction.normalized()
	target.take_hit(1, "melee", impact_direction, knockback)
	_spawn_machete_hit_feedback(target.global_position + Vector3(0.0, 0.32, 0.0), impact_direction)
	# A blade into gel sounds like a wound, not struck metal: the metal_hit clip is
	# kept only for hard surfaces elsewhere in the basement.
	_play_sfx(FLESH_SFX, -6.0, randf_range(0.94, 1.10))
	player.apply_melee_impact()
	_hit_stop(0.07)
	show_message("MACHETE HIT // it recoils.", 1.2)


func _spawn_machete_hit_feedback(position_value: Vector3, impact_direction: Vector3) -> void:
	# Short-lived gel flecks make a non-lethal hit legible without filling the
	# combat room with expensive particles. The death remains are still handled
	# separately by the harvest loop.
	var burst := Node3D.new()
	burst.name = "MacheteHitFeedback"
	burst.position = position_value
	add_child(burst)
	var gel := _material(Color(0.45, 0.66, 0.12), 0.42, 0.04)
	gel.emission_enabled = true
	gel.emission = Color(0.10, 0.24, 0.02)
	gel.emission_energy_multiplier = 0.8
	for index in 4:
		var fleck := MeshInstance3D.new()
		var fleck_mesh := SphereMesh.new()
		fleck_mesh.radius = 0.5
		fleck_mesh.height = 1.0
		fleck_mesh.radial_segments = 6
		fleck_mesh.rings = 3
		fleck.mesh = fleck_mesh
		fleck.material_override = gel
		var side: float = -0.10 + float(index) * 0.065
		fleck.position = impact_direction * (0.08 + float(index) * 0.035) + Vector3(side, 0.01 + float(index) * 0.025, 0.0)
		fleck.scale = Vector3(0.038 + float(index) * 0.006, 0.060, 0.038 + float(index) * 0.006)
		burst.add_child(fleck)
	var fade := create_tween()
	fade.tween_property(burst, "scale", Vector3.ONE * 0.18, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade.tween_callback(burst.queue_free)


func _hit_stop(seconds: float) -> void:
	# A short real-time freeze sells the weight of a blade that actually bites.
	# The timer ignores game time, so a slow frame can never trap the shift.
	hit_stop_serial += 1
	var serial := hit_stop_serial
	Engine.time_scale = 0.16
	await get_tree().create_timer(seconds, true, false, true).timeout
	if serial == hit_stop_serial:
		Engine.time_scale = 1.0

func player_bitten(creature) -> void:
	farm.apply_venom()
	var from: Vector3 = creature.global_position if is_instance_valid(creature) else Vector3.ZERO
	_damage_player(14.0, from, 4.2)
	show_message("Teeth. Venom in the arm.", 2.2)


func player_leap_hit(creature) -> void:
	var from: Vector3 = creature.global_position if is_instance_valid(creature) else Vector3.ZERO
	_damage_player(22.0, from, 5.6)
	show_message("IT CAME OFF THE FLOOR", 1.6)


func _damage_player(amount: float, from_position: Vector3, knockback: float) -> void:
	if player == null or player_downed:
		return
	if not player.take_damage(amount, from_position, knockback):
		# Still inside the brief recovery window; the body was already hit.
		return
	hurt_flash = 1.0
	_play_sfx(HURT_SFX, -6.5, randf_range(0.93, 1.05))
	if player.health <= 0.0:
		_player_down()


func _player_down() -> void:
	if player == null or player_downed:
		return
	player_downed = true
	down_serial += 1
	var serial := down_serial
	player.set_downed(true)
	show_message("YOU GO DOWN // the shift is writing your name in the ledger.", 3.2)
	if down_overlay != null:
		var fade := create_tween()
		fade.tween_property(down_overlay, "color:a", 0.88, 0.7)
	await get_tree().create_timer(2.6).timeout
	if serial != down_serial or not is_instance_valid(self):
		return
	_revive_player()


func _revive_player() -> void:
	player_downed = false
	down_serial += 1
	player.set_downed(false)
	player.heal_to_full()
	player.restore_at(START_SPOT)
	# The fight is lost with the body; the creature is not. Anything still alive
	# stays alive exactly where it is standing - no despawn, no second spawn - but
	# the hunt it was running dies with the hunter it killed, so waking up does not
	# put it back on the camera mid-lunge. It has to sense the hunter again.
	var survivors: Array = []
	for creature in burrowers:
		if not is_instance_valid(creature):
			continue
		if creature.has_method("reset_after_player_death"):
			creature.reset_after_player_death()
		survivors.append(creature)
	burrowers = survivors
	# The haul is what a bad fight actually costs: the body heals, the shift's
	# work does not come back with it.
	farm.carried_remains.clear()
	hurt_flash = 0.0
	if down_overlay != null:
		var fade := create_tween()
		fade.tween_property(down_overlay, "color:a", 0.0, 0.9)
	show_message("YOU COME TO BY THE COT // the haul is gone.", 3.2)


func creature_leap_telegraph(_creature) -> void:
	# The crouch needs to be audible as well as visible: a wet rising creak under a
	# pressure tone lands the cue while the body is still on the floor.
	_play_sfx(COIL_SFX, -8.0, randf_range(0.96, 1.04))


func creature_leap_started(_creature) -> void:
	# Air moving over a thrown mass: the swing clip is filtered noise, which is
	# exactly the right texture once it is slowed and dropped in pitch.
	_play_sfx(SWING_SFX, -11.0, 0.78)


func creature_leap_landed(_creature, hit_player: bool) -> void:
	# The slam carries the landing's weight on concrete; a connecting pounce also
	# plays the wound cue from _damage_player, so keep the body slap quieter there.
	# A missed pounce is still coiled: the rising creak repeats first, under the
	# slam, so the guarded tail is audible with the eyes somewhere else.
	if not hit_player:
		_play_sfx(COIL_SFX, -11.5, 1.26)
	_play_sfx(SLAM_SFX, -9.0 if hit_player else -6.5, randf_range(0.95, 1.06))


func creature_reflex_bite(creature) -> void:
	# The landing guard paying out: no blade damage, one bite, and a line that
	# names the rule instead of leaving the hunter to guess why the swing missed.
	var from: Vector3 = creature.global_position if is_instance_valid(creature) else Vector3.ZERO
	var bite := 12.0
	if is_instance_valid(creature):
		bite = float(creature.get("reflex_bite"))
	_play_sfx(FLESH_SFX, -5.0, 1.16)
	# The blade is already past the body when the bite lands, so the stroke is simply
	# spent, not refunded. Interrupting the swing was measured and rejected: resetting
	# the attack let a greedy hunter re-swing sooner and kill faster than a patient
	# one, which is the opposite of what the guard is for.
	_damage_player(bite, from, 3.2)
	show_message("Guarded. It keeps a bite in reserve - let the coil settle.", 2.0)

func make_noise(_noise_position: Vector3, _radius: float, _source: String = "world") -> void:
	pass

func on_burrower_killed(creature, method: String, position_value: Vector3) -> void:
	var quality := "C"
	if method == "melee":
		quality = "A"
	elif method == "standard" or method == "ranged":
		quality = "B"
	elif method == "broadhead":
		quality = "C"
	var variant := ""
	var splits := false
	if is_instance_valid(creature):
		variant = str(creature.get("variant"))
		splits = bool(creature.get("splits_on_death"))
	if variant == "cinder":
		# The pocket's body is worth carrying home regardless of how it died.
		quality = "A"
	if burrowers.has(creature):
		burrowers.erase(creature)
	if farm.story.stage == StoryState.STAGE_TRAP_PROVEN and method in ["standard", "ranged", "broadhead"]:
		farm.story.advance_to(StoryState.STAGE_HANDOFF)
		show_message("The trap has done its work. The farm is yours: net, kitchen, orders.", 3.4)
		show_message(MARA_LOGBOOK_LINE, 5.0)
	_spawn_slime_guts(position_value, variant)
	_spawn_carcass(position_value, quality, variant)
	if splits:
		_split_cinder(position_value)
	else:
		show_message("The slime bursts across the concrete. Gather what is left.", 2.4)


## A variant that splits doubles itself exactly once: two ordinary bodies at ±0.7 m,
## both at full health, neither able to split again. Killing it can be worse than
## walking around it, which is the point.
func _split_cinder(position_value: Vector3) -> void:
	cinder_split_serial += 1
	var axis := Vector3.RIGHT.rotated(Vector3.UP, float(cinder_split_serial) * TAU * 0.37)
	var base := Vector3(position_value.x, 0.02, position_value.z)
	# A wet tear first, then the two halves finding their feet.
	_play_sfx(HIT_SFX, -5.0, 0.55)
	_play_sfx(FLESH_SFX, -3.5, 0.82)
	for side in [-1.0, 1.0]:
		var clone = _spawn_burrower(base + axis * 0.7 * side)
		if clone == null:
			continue
		clone.provoked = true
		clone.leash_center = BREACH_SPOT
		clone.leash_radius = CINDER_LEASH_RADIUS
	show_message("It tears down the middle — two smaller ones crawl out of it.", 2.6)
	farm.report.append("THE BREACH // the cinder split.")


## The pocket's threat. Nothing here is a second AI: the same burrower with a
## heavier configuration, stirred by using the drop, looking into the breach, or
## simply standing in front of it.
## C2.12 // what the bait draws through the outer shutter is its own red animal,
## not the green home-base slime and not the dark-orange breach variant. Same rig
## and same brain: only the painted body changes.
func _hunt_lure_config() -> Dictionary:
	return {
		"variant": "slime",
		"max_health": 2,
		"speed": 4.2,
		"body_paint": true,
		"body_colour": Color(0.66, 0.10, 0.08),
		"body_scale": 1.0,
	}


## A tougher, slower variant of the basement slime: same body and brain, more
## health and a heavier knockback, drawn from the rust-coloured culture trays.
func _rust_config() -> Dictionary:
	return {
		"variant": "rust",
		"max_health": 4,
		"speed": 3.6,
		"knockback_on_hit": 0.6,
		"body_paint": true,
		"body_colour": Color(0.52, 0.30, 0.12),
		"body_scale": 1.08,
	}


func _cinder_config() -> Dictionary:
	return {
		"variant": "cinder",
		"max_health": 3,
		"speed": 4.8,
		"knockback_on_hit": 1.2,
		"splits_on_death": true,
		"loot_table": {"ember_chitin": 1, "heat_gland_chance": 0.25},
		"body_colour": Color(0.62, 0.24, 0.05),
		"body_scale": 1.15,
		"leash_center": BREACH_SPOT,
		"leash_radius": CINDER_LEASH_RADIUS,
	}


func _cinder_alive() -> int:
	var count := 0
	for creature in burrowers:
		if not is_instance_valid(creature):
			continue
		if str(creature.get("variant")) == "cinder":
			count += 1
	return count


func _stir_cinder(source: String) -> bool:
	if cinder_cooldown > 0.0 or _cinder_alive() >= CINDER_MAX_ALIVE:
		return false
	cinder_cooldown = CINDER_SPAWN_COOLDOWN
	var creature = _spawn_burrower(BREACH_SPOT + Vector3(-0.8, 0.05, -1.6), false, _cinder_config())
	if creature == null:
		return false
	cinder_serial += 1
	# Gel splitting under pressure, then the weight of the body landing.
	_play_sfx(FLESH_SFX, -4.5, 0.60)
	_play_sfx(SLAM_SFX, -8.0, 0.70)
	if source != "drop" and source != "breach":
		farm.report.append("THE BREACH // a cinder burrower came through.")
	return true


func _update_pocket_threat(delta: float) -> void:
	cinder_cooldown = maxf(0.0, cinder_cooldown - delta)
	if player == null:
		return
	var watch := BREACH_SPOT + Vector3(0.0, 0.0, -0.9)
	if player.global_position.distance_to(watch) > 3.0 or _cinder_alive() >= CINDER_MAX_ALIVE:
		breach_linger = 0.0
		return
	breach_linger += delta
	if breach_linger < CINDER_LINGER_TIME:
		return
	breach_linger = 0.0
	if _stir_cinder("linger"):
		show_message("The breach opens. Something heavy unfolds into the chamber.", 3.0)


func variant_knockback_player(creature, distance: float) -> void:
	if player == null or not is_instance_valid(creature):
		return
	player.apply_push(creature.global_position, distance)


func _spawn_slime_guts(position_value: Vector3, variant: String = "") -> void:
	# A kill leaves readable physical evidence rather than making the prey simply
	# vanish: heavy green gel, orange organs, and thin streaks on the floor.
	var remains := Node3D.new()
	remains.name = "SlimeGuts"
	remains.position = Vector3(position_value.x, 0.018, position_value.z)
	var get_colour := Color(0.19, 0.36, 0.075) if variant != "cinder" else Color(0.42, 0.19, 0.045)
	var gel_mat := _material(get_colour, 0.42, 0.08)
	gel_mat.emission_enabled = true
	gel_mat.emission = Color(0.045, 0.12, 0.012) if variant != "cinder" else Color(0.30, 0.09, 0.008)
	gel_mat.emission_energy_multiplier = 0.9
	var organ_mat := _material(Color(0.50, 0.095, 0.025), 0.58, 0.12)
	organ_mat.emission_enabled = true
	organ_mat.emission = Color(0.24, 0.025, 0.004)
	organ_mat.emission_energy_multiplier = 0.75
	for index in 9:
		var splat := MeshInstance3D.new()
		splat.name = "GelSplat_%d" % index
		var mesh := SphereMesh.new()
		mesh.radius = 0.5
		mesh.height = 1.0
		mesh.radial_segments = 16
		mesh.rings = 8
		splat.mesh = mesh
		var angle: float = float(index) * TAU / 9.0 + 0.23
		var distance: float = 0.10 + float(index % 4) * 0.115
		splat.position = Vector3(cos(angle) * distance, 0.005 + float(index % 3) * 0.006, sin(angle) * distance)
		var width: float = 0.18 + float(index % 3) * 0.09
		splat.scale = Vector3(width, 0.018 + float(index % 2) * 0.010, width * (0.62 + float(index % 2) * 0.18))
		splat.rotation.y = angle + 0.4
		splat.material_override = organ_mat if index in [2, 6] else gel_mat
		remains.add_child(splat)
	var core := MeshInstance3D.new()
	core.name = "SplitCore"
	var core_mesh := SphereMesh.new()
	core_mesh.radius = 0.5
	core_mesh.height = 1.0
	core.mesh = core_mesh
	core.scale = Vector3(0.24, 0.075, 0.18)
	core.position = Vector3(-0.06, 0.045, 0.04)
	core.material_override = organ_mat
	remains.add_child(core)
	add_child(remains)
	slime_guts.append(remains)

func _spawn_carcass(position_value: Vector3, quality: String, variant: String = "") -> void:
	var carcass := Node3D.new()
	carcass.position = Vector3(position_value.x, 0.05, position_value.z)
	carcass.set_meta("kind", "carcass")
	carcass.set_meta("quality", quality)
	if variant != "":
		carcass.set_meta("variant", variant)
	var name_of_body := "CINDER REMAINS" if variant == "cinder" else "SLIME REMAINS"
	carcass.set_meta("label", "%s [%s GRADE]" % [name_of_body, quality])
	var lump := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	lump.mesh = mesh
	lump.scale = Vector3(0.55, 0.30, 0.8)
	lump.position = Vector3(0, 0.22, 0)
	var remains_mat := _material(Color(0.25, 0.42, 0.09) if variant != "cinder" else Color(0.48, 0.20, 0.05), 0.48, 0.03)
	remains_mat.emission_enabled = true
	remains_mat.emission = Color(0.055, 0.13, 0.014) if variant != "cinder" else Color(0.24, 0.06, 0.006)
	remains_mat.emission_energy_multiplier = 0.75
	lump.material_override = remains_mat
	carcass.add_child(lump)
	add_child(carcass)
	interactables.append(carcass)

func _spawn_burrower(position_value: Vector3, drawn_to_hunt: bool = false, variant_config: Dictionary = {}):
	var creature = BurrowerScript.new()
	creature.game = self
	creature.player = player
	if not variant_config.is_empty():
		# Configured before the body enters the tree, so the visual is built once
		# in its variant colours instead of being re-tinted a frame later.
		creature.configure_variant(variant_config)
	add_child(creature)
	creature.global_position = position_value
	if drawn_to_hunt:
		creature.set_hunt_lure(HUNT_BAIT_SPOT)
	burrowers.append(creature)
	_play_sfx(HIT_SFX, -12.0, 0.55)
	return creature

# ---------------------------------------------------------------- menus & save

func toggle_pause_menu() -> void:
	if menu == null:
		return
	if menu.visible and menu.current_screen == "pause":
		menu.close_menu()
	elif menu.visible and menu.current_screen != "title":
		menu.open_pause()
	elif not menu.visible:
		menu.open_pause()

func _start_wake_sequence() -> void:
	if player == null:
		return
	if opening_tween != null and opening_tween.is_valid():
		opening_tween.kill()
	opening_state = "wake"
	player.global_position = WAKE_BED_SPOT
	player.velocity = Vector3.ZERO
	var wake_direction := FURNACE_SPOT - WAKE_STAND_SPOT
	wake_direction.y = 0.0
	player.rotation.y = atan2(-wake_direction.x, -wake_direction.z)
	player.head.position.y = 0.38
	player.head.rotation.x = deg_to_rad(12.0)
	player.set_cinematic_locked(true)
	player.set_flashlight_enabled(false)
	_set_wake_lids(0.72, 0.68)
	opening_tween = create_tween()
	opening_tween.set_parallel(true)
	opening_tween.tween_property(wake_veil, "color", Color(0.0, 0.0, 0.0, 0.0), 1.65).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	opening_tween.tween_property(wake_top_lid, "offset_bottom", 0.0, 1.90).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	opening_tween.tween_property(wake_bottom_lid, "offset_top", 0.0, 1.90).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	opening_tween.tween_property(player, "global_position", WAKE_STAND_SPOT, 1.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	opening_tween.tween_property(player.head, "position:y", 1.55, 1.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	opening_tween.tween_property(player.head, "rotation:x", 0.0, 1.50).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	opening_tween.chain().tween_callback(_finish_wake_sequence)


func _finish_wake_sequence() -> void:
	if opening_state != "wake":
		return
	opening_tween = null
	_set_wake_lids(0.0, 0.0)
	if wake_overlay != null:
		wake_overlay.visible = false
	if player != null:
		player.global_position = WAKE_STAND_SPOT
		player.velocity = Vector3.ZERO
		player.head.position.y = 1.55
		player.head.rotation.x = 0.0
		player.set_cinematic_locked(false)
	opening_state = "tend_fire"
	show_message("COLD ROOM // TEND THE FURNACE", 3.8)


func finish_opening_sequence_for_test() -> void:
	# The production intro is real-time. Automated gameplay tests use this
	# explicit fast-forward so physics checks never depend on wall-clock time.
	if opening_tween != null and opening_tween.is_valid():
		opening_tween.kill()
	if opening_state == "wake":
		_finish_wake_sequence()


func new_shift(play_opening: bool = true) -> void:
	_cancel_chain_install()
	Engine.time_scale = 1.0
	if rail != null and rail.riding:
		rail._release_player()
		rail.riding = false
	if opening_tween != null and opening_tween.is_valid():
		opening_tween.kill()
	opening_tween = null
	farm.new_game()
	_restore_world_pickups()
	if rail != null: rail.reset(false)
	# A new game starts as a lesson in heat management, not in a warm, lit room.
	# The player has enough fuel for a mistake, but must physically open and feed
	# the firebox before the room begins to recover.
	farm.temperature = 15.0
	farm.fuel = 3.0
	farm.furnace_lit = false
	# The bolt driver arrives in the bedside kit, but the first shift has no
	# ammunition: the blade has to earn the first kill before bolts exist.
	bolts = 0
	bedside_kit_lid_open = false
	farm.carried_remains.clear()
	cinder_cooldown = 0.0
	cinder_serial = 0
	cinder_split_serial = 0
	breach_linger = 0.0
	shutter_open = false
	hunt_bulkhead_open = false
	story_enabled = play_opening
	story_wait = -1.0
	story_bang_clock = 0.0
	story_bangs = 0
	story_line_index = 0
	story_shudder = 0.0
	story_pair.clear()
	lure_left = 0.0
	hunt_snare_sprung = false
	breach_day = 0
	warmth = 0.46
	furnace_door_open = false
	_set_furnace_door(false, false)
	_move_shutter(0.0)
	_move_hunt_bulkhead(0.0)
	if shutter_body != null:
		shutter_body.position.z = OUTER_HUNT_SHUTTER_SPOT.z
	_sync_levers_instant()
	for creature in burrowers.duplicate():
		if is_instance_valid(creature):
			creature.queue_free()
	burrowers.clear()
	for node in interactables.duplicate():
		if is_instance_valid(node) and str(node.get_meta("kind", "")) == "carcass":
			interactables.erase(node)
			node.queue_free()
	for remains in slime_guts.duplicate():
		if is_instance_valid(remains):
			remains.queue_free()
	slime_guts.clear()
	player_downed = false
	down_serial += 1
	hurt_flash = 0.0
	if down_overlay != null:
		down_overlay.color.a = 0.0
	if hurt_overlay != null:
		hurt_overlay.color.a = 0.0
	if player != null:
		player.set_cinematic_locked(false)
		player.set_downed(false)
		player.heal_to_full()
		player.flashlight_charge = 100.0
		player.set_flashlight_acquired(false)
		player.set_machete_equipped(false)
		player.set_riveter_equipped(false)
		player.set_flashlight_enabled(false)
		player.set_lantern_on(false)
		if play_opening:
			_start_wake_sequence()
		else:
			player.restore_at(START_SPOT)
			player.set_flashlight_enabled(false)
			opening_state = "tend_fire"
			_set_wake_lids(0.0, 0.0)
			if wake_overlay != null:
				wake_overlay.visible = false
	_refresh_trays()
	_refresh_net_prop()
	_refresh_bedside_kit()
	_refresh_gap_patch_visuals()
	_refresh_hunt_snare_visual()
	_refresh_storage_rack_visual()
	_refresh_heat_reclaimer_visual()
	_refresh_cave_regulator_pickup()
	_refresh_kitchen_state()
	_update_furnace_fx(0.0)
	if not play_opening:
		show_message("COLD ROOM // TEND THE FURNACE", 3.0)

func save_game() -> void:
	_cancel_chain_install()
	if rail != null and not rail.can_save():
		show_message("STOP AT A RAIL PLATFORM BEFORE SAVING", 2.5)
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(farm.to_save()))
	file.close()
	if rail != null: rail.checkpoint(true)
	show_message("SHIFT SAVED", 1.6)

func load_game() -> bool:
	var candidates: Array[String] = [SAVE_PATH, RailSystem.CHECKPOINT]
	if FileAccess.get_modified_time(RailSystem.CHECKPOINT) >= FileAccess.get_modified_time(SAVE_PATH): candidates.reverse()
	for path in candidates:
		if not FileAccess.file_exists(path): continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null: continue
		var parsed: Variant = JSON.parse_string(file.get_as_text())
		file.close()
		if parsed is Dictionary and restore_snapshot(parsed):
			return true
	return false


# Shared by disk loading and automated save/load round trips; never writes a save.
func restore_snapshot(data: Dictionary) -> bool:
	if not farm.from_save(data):
		return false
	_cancel_chain_install()
	_restore_world_pickups()
	_sync_levers_instant()
	breach_day = int(farm.day) if farm.clock >= 20.0 else 0
	hunt_snare_sprung = false
	player.restore_at(START_SPOT)
	player.set_flashlight_acquired(farm.bedside_kit_opened)
	player.set_lantern_on(farm.lantern_on)
	player.set_lantern_carried(farm.lantern_crafted)
	player.set_net_carried(farm.net_crafted)
	player.set_link_carried(farm.chain_links > 0)
	player.set_machete_equipped(farm.bedside_kit_opened)
	player.set_riveter_equipped(farm.bedside_kit_opened)
	bedside_kit_lid_open = farm.bedside_kit_opened
	if farm.bedside_kit_opened:
		opening_state = "complete"
	elif farm.furnace_lit:
		opening_state = "kit"
	else:
		opening_state = "tend_fire"
	_refresh_trays()
	_refresh_bedside_kit()
	_refresh_gap_patch_visuals()
	_refresh_hunt_snare_visual()
	_refresh_storage_rack_visual()
	_refresh_heat_reclaimer_visual()
	_refresh_cave_regulator_pickup()
	_refresh_kitchen_state()
	if rail != null: rail.reset(true)
	show_message("SHIFT RESTORED // day %d, %s" % [int(farm.day), farm.clock_text()], 2.6)
	return true

func set_master_volume(value: float) -> void:
	master_volume_db = value
	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, master_volume_db)

# ---------------------------------------------------------------- helpers

func _attach_model_to_body(body: StaticBody3D, scene: PackedScene, local_position: Vector3, scale_value: Vector3 = Vector3.ONE, rotation_y: float = 0.0) -> Node3D:
	for child in body.get_children():
		if child is MeshInstance3D:
			(child as MeshInstance3D).visible = false
	var model: Node3D = scene.instantiate() as Node3D
	if model == null:
		return null
	body.add_child(model)
	model.position = local_position
	model.scale = scale_value
	model.rotation.y = rotation_y
	return model


func _build_rolling_gate(position_value: Vector3, visual_name: String) -> Node3D:
	# Both the outer shutter and inner bulkhead are real moving collision doors.
	# A static frame stays in the wall while only the panel lifts.
	var gate := Node3D.new()
	gate.name = visual_name + "Body"
	gate.position = position_value
	add_child(gate)
	var static_body := StaticBody3D.new()
	static_body.name = visual_name + "Collision"
	var placeholder := MeshInstance3D.new()
	var placeholder_mesh := BoxMesh.new()
	placeholder_mesh.size = Vector3(0.30, 3.0, 1.8)
	placeholder.mesh = placeholder_mesh
	placeholder.position = Vector3(0.0, 1.5, 0.0)
	placeholder.material_override = _material(Color(0.16, 0.15, 0.14), 0.60, 0.60)
	static_body.add_child(placeholder)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.30, 3.0, 1.8)
	collision.shape = shape
	collision.position = Vector3(0.0, 1.5, 0.0)
	static_body.add_child(collision)
	gate.add_child(static_body)
	var visual: Node3D = _attach_model_to_body(static_body, SHUTTER_PANEL_MODEL, Vector3.ZERO)
	if visual != null:
		visual.name = visual_name
	_add_prop(SHUTTER_FRAME_MODEL, position_value)
	return gate


func _add_furnace_smoke() -> void:
	furnace_smoke = GPUParticles3D.new()
	furnace_smoke.name = "FurnaceSmoke"
	# Start just above the cap, then let the smoke crawl across the low ceiling
	# rather than disappearing inside the chimney or clipping through the roof.
	furnace_smoke.position = FURNACE_SPOT + Vector3(0.32, 2.84, 0.0)
	furnace_smoke.amount = 22
	furnace_smoke.lifetime = 3.8
	furnace_smoke.preprocess = 3.8
	furnace_smoke.randomness = 0.72
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 1.0, 0.0)
	process.spread = 20.0
	process.gravity = Vector3(0.03, 0.16, -0.03)
	process.initial_velocity_min = 0.22
	process.initial_velocity_max = 0.55
	process.scale_min = 0.42
	process.scale_max = 1.18
	process.color = Color(0.52, 0.44, 0.34, 0.78)
	furnace_smoke.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.86, 0.86)
	var smoke_mat := StandardMaterial3D.new()
	smoke_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smoke_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smoke_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	smoke_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	smoke_mat.albedo_color = Color(0.72, 0.62, 0.48, 0.84)
	smoke_mat.albedo_texture = SMOKE_TEXTURE
	smoke_mat.vertex_color_use_as_albedo = true
	quad.material = smoke_mat
	furnace_smoke.draw_pass_1 = quad
	add_child(furnace_smoke)
	# Compatibility renderers can make fine transparent particles disappear
	# against a black ceiling. These low-poly soot puffs are a deliberately
	# readable fallback, animated with the same firing state as the particle bed.
	var puff_mat := StandardMaterial3D.new()
	puff_mat.albedo_color = Color(0.20, 0.19, 0.17, 0.82)
	puff_mat.roughness = 1.0
	puff_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	puff_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	puff_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for index in 5:
		var puff := MeshInstance3D.new()
		puff.name = "FurnaceSootPuff_%d" % index
		var puff_mesh := SphereMesh.new()
		puff_mesh.radius = 0.23
		puff_mesh.height = 0.38
		puff_mesh.radial_segments = 8
		puff_mesh.rings = 4
		puff.mesh = puff_mesh
		puff.material_override = puff_mat
		puff.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(puff)
		furnace_smoke_puffs.append(puff)


func _static_box(position_value: Vector3, size_value: Vector3, material: Material) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = position_value
	var mesh_instance := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	mesh_instance.mesh = mesh
	mesh_instance.material_override = material
	body.add_child(mesh_instance)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size_value
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	return body


func _make_interactable_non_blocking(body: StaticBody3D) -> void:
	# Interaction finds this node by distance and metadata rather than physics.
	# Removing it from collision layers keeps a visible switch/chute usable while
	# guaranteeing it cannot snag the player in a doorway or route bottleneck.
	if body == null:
		return
	body.collision_layer = 0
	body.collision_mask = 0

func _box_visual(size_value: Vector3, color: Color, emissive: bool = false, energy: float = 1.0) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size_value
	piece.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if emissive:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = energy
	piece.material_override = material
	return piece

func _add_prop(scene: PackedScene, position_value: Vector3, scale_value: Vector3 = Vector3.ONE, rotation_y: float = 0.0) -> void:
	var prop := scene.instantiate()
	prop.position = position_value
	prop.scale = scale_value
	prop.rotation.y = rotation_y
	add_child(prop)

func _light_node(position_value: Vector3, color: Color, energy: float, range_value: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.position = position_value
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	return light

func _add_light(position_value: Vector3, color: Color, energy: float, range_value: float) -> void:
	var light := _light_node(position_value, color, energy, range_value)
	add_child(light)

func _material(color: Color, roughness_value: float, metallic_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	material.metallic = metallic_value
	return material

func _floor_material() -> StandardMaterial3D:
	var material := _material(Color(0.44, 0.40, 0.36), 0.88, 0.04)
	material.albedo_texture = FLOOR_TEXTURE
	material.uv1_scale = Vector3(0.25, 0.25, 1.0)
	return material

func _play_sfx(sound: AudioStream, volume_db: float = -6.0, pitch: float = 1.0) -> void:
	if sfx_player == null:
		return
	sfx_player.stream = sound
	sfx_player.volume_db = volume_db
	sfx_player.pitch_scale = pitch
	sfx_player.play()

func show_message(text_value: String, duration: float) -> void:
	if message_label == null:
		return
	message_label.text = text_value
	if message_panel != null:
		message_panel.visible = not text_value.is_empty()
	var shown := text_value
	await get_tree().create_timer(duration).timeout
	if message_label != null and message_label.text == shown:
		message_label.text = ""
		if message_panel != null:
			message_panel.visible = false
