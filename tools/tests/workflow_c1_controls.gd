extends "res://tools/tests/test_base.gd"

## C1 // physical door levers, shutter lever and snare lever
##
## The old controls were invisible-bodied cubes: the nearest object inside a
## 2.4 m bubble won, whatever the player was looking at. This suite proves the
## replacement end to end: a visible worn mechanism, a real throw that moves, a
## linked door or trap, sound, anti-spam, a use range, and the old click boxes
## gone. Nothing here fakes an interaction: every operation goes through
## game.player_interact() or the mechanism's own entry point.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/workflow_c1_controls.tscn

# The levers are bolted to the warm room's east wall, whose inner face is at
# x = 5.825. The player stands about 1.2 m back, where a wall control belongs.
const WALL_FACE_X := 5.825
const INNER_LEVER_SPOT := Vector3(5.80, 1.10, -3.30)
const SHUTTER_LEVER_SPOT := Vector3(5.80, 1.10, -0.62)
const SNARE_LEVER_SPOT := Vector3(5.80, 1.10, -4.00)
const LEVER_STANCE_X := 5.00


func _init() -> void:
	suite_name = "workflow_c1_controls"
	suite_level = "workflow"


func run_phases() -> void:
	await _prepare_world()
	await _test_levers_are_physical()
	await _test_inner_door_crank()
	await _test_outer_shutter_lever()
	await _test_unrelated_wall()
	await _test_snare_lever()
	await _test_use_range()
	await _test_sound_and_state_sync()


func _prepare_world() -> void:
	# The intro tutorial gates interaction behind its own prompts. It is covered
	# by workflow_interaction; here the subject is the mechanism, so stand the
	# shift up and take the tutorial lock off.
	game.finish_opening_sequence_for_test()
	game.opening_state = ""
	game.player.is_hidden = false
	game.shutter_open = false
	game.hunt_bulkhead_open = false
	game.farm.snare_armed = false
	game.farm.snares = 0
	game.hunt_snare_sprung = false
	game._move_shutter(0.0)
	game._move_hunt_bulkhead(0.0)
	game._sync_levers_instant()
	await _frames(3)


# --------------------------------------------------------------------- helpers

func _stand_at(spot: Vector3, look_target: Vector3) -> void:
	game.player.global_position = spot
	game.player.velocity = Vector3.ZERO
	_aim_player_at(look_target)
	await _frames(2)
	# The HUD prompt is written on the idle frame; wait for it before asserting on it.
	await get_tree().process_frame


## The prompt is written on the HUD's own frame; wait for it instead of guessing
## a frame count, then assert on what the player would actually see.
## Hold the interact action at the crank until a turn completes, then let go.
## The hold is driven by the same polled input the player uses, not by calling
## the crank's completion path.
func _hold_crank(max_frames: int = 300) -> void:
	Input.action_press("interact")
	for _i in max_frames:
		await _frames(1)
		if game.bulkhead_crank.is_moving():
			break
	Input.action_release("interact")
	await _frames(2)


func _wait_prompt(expected: String, max_frames: int = 40) -> void:
	for _i in range(max_frames):
		if game.prompt_label.text == expected:
			return
		await _frames(1)


## Bounds of a part in the lever's own space, from its mesh and local transform.
func _part_bounds(part: MeshInstance3D) -> AABB:
	var mesh_box: AABB = part.mesh.get_aabb()
	var xform: Transform3D = part.transform
	var bounds := AABB(xform * mesh_box.position, Vector3.ZERO)
	for corner_index in 8:
		var corner := mesh_box.position + mesh_box.size * Vector3(
			float(corner_index & 1), float((corner_index >> 1) & 1), float((corner_index >> 2) & 1))
		bounds = bounds.expand(xform * corner)
	return bounds


## Any two overlapping parts sharing a front face plane will z-fight, which is what
## made the streaks and stencil flicker. Returns a description of the first pair.
func _first_coplanar_pair(lever: Node) -> String:
	var parts: Array[MeshInstance3D] = []
	for child in lever.get_children():
		if child is MeshInstance3D:
			parts.append(child as MeshInstance3D)
	for i in parts.size():
		var a := _part_bounds(parts[i])
		for j in range(i + 1, parts.size()):
			var b := _part_bounds(parts[j])
			if absf(a.position.z - b.position.z) > 0.0004:
				continue
			var overlap_x: bool = a.position.x < b.end.x - 0.001 and b.position.x < a.end.x - 0.001
			var overlap_y: bool = a.position.y < b.end.y - 0.001 and b.position.y < a.end.y - 0.001
			if overlap_x and overlap_y:
				return "%s / %s at z %.4f" % [parts[i].name if parts[i].name else "part", parts[j].name if parts[j].name else "part", a.position.z]
	return ""


func _mesh_count(node: Node) -> int:
	var total := 0
	for child in node.get_children():
		if child is MeshInstance3D:
			total += 1
		total += _mesh_count(child)
	return total


func _lever_of(kind: String):
	match kind:
		"crank": return game.shutter_lever
		"snare": return game.snare_lever
	return null


func _count_kind(kind: String) -> int:
	var total := 0
	for item in game.interactables:
		if is_instance_valid(item) and str(item.get_meta("kind", "")) == kind:
			total += 1
	return total


# -------------------------------------------------------------- the mechanisms

func _test_levers_are_physical() -> void:
	begin_case("controls_present", "bolted levers and a mounted crank drive the hunt")
	var crank = game.bulkhead_crank
	_ok(crank != null and is_instance_valid(crank), "the inner door is a mounted crank node")
	_ok(crank is StaticBody3D and int((crank as StaticBody3D).collision_layer) == 0,
		"the crank stays non-blocking in the doorway")
	_ok(crank.has_node("GeneratedCrankHousing") and crank.has_node("CrankWheel/GeneratedCastWheel"), "the crank has its validated housing and separate cast wheel")
	_ok(crank.get_node_or_null("PlateText") != null, "the crank carries a stencilled identity plate")
	_ok(crank.get_node_or_null("CrankWheel") != null, "the crank has a wheel that can actually turn")
	_ok(bool(crank.get_meta("requires_look", false)) and float(crank.get_meta("reach", 0.0)) > 0.0,
		"the crank declares a facing and a use range")
	_ok(_count_kind("bulkhead") == 1, "exactly one bulkhead control exists in the room")
	_ok(_count_kind("crank") == 1 and _count_kind("snare") == 1,
		"the shutter and the snare keep one lever each")
	# Bolted to the warm room's east wall like the levers: the plate is 45 mm thick,
	# so its rear face has to reach the wall at x = 5.825.
	var plate_back: float = crank.global_position.x + 0.0225
	_ok(absf(plate_back - WALL_FACE_X) < 0.02,
		"the crank is bolted against the wall (%.3f vs %.3f)" % [plate_back, WALL_FACE_X])
	_ok(absf(crank.global_position.x - INNER_LEVER_SPOT.x) < 0.01,
		"the crank hangs on the same mounting plane as the levers")
	_ok(crank.plate_text != game.shutter_lever.plate_text
		and crank.tag_color != game.shutter_lever.tag_color,
		"the crank is labelled and colour-coded apart from the shutter lever")

	for kind in ["crank", "snare"]:
		var lever = _lever_of(kind)
		_ok(lever != null and is_instance_valid(lever), "hunt control %s is a mounted lever node" % kind)
		if lever == null:
			continue
		_ok(lever is StaticBody3D and int((lever as StaticBody3D).collision_layer) == 0,
			"lever %s stays non-blocking in the doorway" % kind)
		_ok(_mesh_count(lever) >= 12, "lever %s is a built mechanism, not a single box (%d parts)" % [kind, _mesh_count(lever)])
		_ok(lever.get_node_or_null("PlateText") != null, "lever %s carries a stencilled identity plate" % kind)
		_ok(bool(lever.get_meta("requires_look", false)) and float(lever.get_meta("reach", 0.0)) > 0.0,
			"lever %s declares a facing and a use range" % kind)
		_ok(_count_kind(kind) == 1, "exactly one %s control exists in the room" % kind)
		var lever_back: float = lever.global_position.x + 0.0225
		_ok(absf(lever_back - WALL_FACE_X) < 0.02,
			"lever %s is bolted against the wall (%.3f vs %.3f)" % [kind, lever_back, WALL_FACE_X])
		_ok(absf(lever.global_position.x - INNER_LEVER_SPOT.x) < 0.01,
			"lever %s hangs on the same mounting plane as the crank" % kind)
		var clash: String = _first_coplanar_pair(lever)
		_ok(clash.is_empty(), "lever %s has no coplanar parts to flicker (%s)" % [kind, clash])
		var arm: Node3D = lever.get_node_or_null("ThrowArm")
		_ok(arm != null and arm.position.z < -0.19,
			"lever %s carries its throw arm clear of the housing" % kind)
	# Placement and colour make the two doors tellable apart at a glance.
	var inner_sep: Vector3 = game.bulkhead_crank.global_position - game.shutter_lever.global_position
	_ok(absf(inner_sep.z) > 1.2, "the inner and outer controls are mounted at separate points on the wall")
	_ok(game.snare_lever.tag_color != game.shutter_lever.tag_color, "the snare control is marked apart from the doors")


func _test_inner_door_crank() -> void:
	begin_case("inner_door", "the bulkhead is wound open, and springs back if released")
	game.hunt_bulkhead_open = false
	game._move_hunt_bulkhead(0.0)
	game._sync_levers_instant()
	await _frames(3)
	await _stand_at(Vector3(LEVER_STANCE_X, 0.9, INNER_LEVER_SPOT.z), INNER_LEVER_SPOT)
	var crank = game.bulkhead_crank
	_ok(game._nearest_interactable() == crank, "approaching the wall plate selects the bulkhead crank")
	_ok(not crank.is_engaged(), "the gate starts sealed")
	await _wait_prompt("HOLD E — CRANK")
	_ok(game.prompt_label.text == "HOLD E — CRANK", "the HUD offers the crank hold, not a pull")
	_ok(game.prompt_panel != null and game.prompt_panel.visible,
		"the contextual prompt panel is shown while the player is at the crank")

	# One tap is the point of the beat: a press must not open the door.
	game.player_interact()
	await _frames(30)
	_ok(not game.hunt_bulkhead_open and crank.progress == 0.0,
		"a single press does nothing; the crank has to be held")

	# Hold and let go early: the wheel springs all the way back.
	var sounds_before: int = crank.sound_plays
	Input.action_press("interact")
	await _frames(30)
	var mid_progress: float = crank.progress
	var mid_angle: float = crank.wheel_angle()
	Input.action_release("interact")
	await _frames(30)
	_ok(mid_progress > 0.0 and mid_progress < 1.0, "the wheel winds while the key is held (%.2f)" % mid_progress)
	_ok(absf(mid_angle) > 0.5, "and visibly turns (%.2f rad)" % absf(mid_angle))
	_ok(crank.progress == 0.0 and absf(crank.wheel_angle()) < 0.01,
		"releasing early springs it back to rest")
	_ok(not game.hunt_bulkhead_open and absf(game.hunt_bulkhead_body.position.y) < 0.05,
		"so an early release leaves the bulkhead sealed")
	_ok(crank.sound_plays > sounds_before, "the ratchet clicked while it wound (%d)" % (crank.sound_plays - sounds_before))

	# Hold to the stop.
	sounds_before = crank.sound_plays
	await _hold_crank()
	_ok(crank.is_engaged() and game.hunt_bulkhead_open, "holding to the stop raises the inner door")
	_ok(crank.sound_plays >= sounds_before + 5,
		"four ratchet clicks and a stop clunk played (%d)" % (crank.sound_plays - sounds_before))
	_ok(crank.is_moving(), "the wheel stays locked while the gate travels")
	_ok(not crank.begin_hold(), "and refuses a second hold mid-travel")
	await _frames(60)
	_ok(game.hunt_bulkhead_body.position.y > 2.0, "the door body itself lifted, not just a flag")
	_ok(not crank.is_moving(), "the lock clears once the gate has settled")

	# Wind it back down.
	await _hold_crank()
	await _frames(60)
	_ok(not game.hunt_bulkhead_open and absf(game.hunt_bulkhead_body.position.y) < 0.10,
		"holding again seats the inner door")
	_ok(not crank.is_engaged(), "the wheel reports the sealed gate")


func _test_outer_shutter_lever() -> void:
	begin_case("outer_shutter", "the shutter has its own lever and keeps its motion")
	game.shutter_open = false
	game.crank_cooldown = 0.0
	game._move_shutter(0.0)
	game._sync_levers_instant()
	await _frames(3)
	await _stand_at(Vector3(LEVER_STANCE_X, 0.9, SHUTTER_LEVER_SPOT.z), SHUTTER_LEVER_SPOT)
	_ok(game._nearest_interactable() == game.shutter_lever,
		"the shutter lever, not a patch of wall, is the interaction point")
	game.player_interact()
	await _wait_lever(game.shutter_lever)
	await _frames(50)
	_ok(game.shutter_open and game.shutter_body.position.y > 2.0,
		"the lever lifts the outer shutter through its existing mechanism")
	_ok(game.shutter_lever.is_engaged(), "the handle reports the lifted shutter")
	_ok(game.crank_cooldown > 0.0, "operating the shutter lever starts its cooldown")
	game.player_interact()
	_ok(game.shutter_open, "a pull inside the cooldown does not reverse the shutter")
	game.crank_cooldown = 0.0
	game.player_interact()
	await _wait_lever(game.shutter_lever)
	await _frames(50)
	_ok(not game.shutter_open and absf(game.shutter_body.position.y) < 0.10,
		"a second throw seats the shutter again")
	_ok(not game.shutter_lever.is_engaged(), "the handle follows the shutter back up")

	var gate_body: Node = game.shutter_body.get_node_or_null("OuterHuntShutterModelCollision")
	_ok(gate_body is StaticBody3D and int((gate_body as StaticBody3D).collision_layer) != 0,
		"the shutter still blocks the doorway with real collision")
	var keeps_shape := false
	if gate_body != null:
		for child in gate_body.get_children():
			if child is CollisionShape3D and (child as CollisionShape3D).shape is BoxShape3D:
				keeps_shape = true
	_ok(keeps_shape, "the shutter keeps its existing box collision shape")


func _test_unrelated_wall() -> void:
	begin_case("unrelated_wall", "looking at the wall never operates the shutter")
	game.shutter_open = false
	game.crank_cooldown = 0.0
	game._move_shutter(0.0)
	game._sync_levers_instant()
	await _frames(3)
	# Same stance, aimed at blank wall two metres along the same wall.
	await _stand_at(Vector3(LEVER_STANCE_X, 0.9, SHUTTER_LEVER_SPOT.z), Vector3(WALL_FACE_X, 1.60, 1.60))
	_ok(game._nearest_interactable() != game.shutter_lever,
		"blank wall beside the lever is not a clickable shutter control")
	game.player_interact()
	await _frames(10)
	_ok(not game.shutter_open, "interacting with the wall leaves the shutter shut")
	# Facing away from the lever entirely.
	await _stand_at(Vector3(LEVER_STANCE_X, 0.9, SHUTTER_LEVER_SPOT.z), Vector3(LEVER_STANCE_X, 0.9, -8.0))
	_ok(game._nearest_interactable() != game.shutter_lever,
		"facing away from the lever does not select it")
	game.farm.fuel = 5.0
	game.player_interact()
	await _frames(6)
	_ok(not game.shutter_open, "no unrelated interaction can operate the shutter")
	_ok(not game.shutter_lever.is_moving() and not game.shutter_lever.is_engaged(),
		"the handle never moved for an unrelated interaction")


func _test_snare_lever() -> void:
	begin_case("snare_lever", "the trap is armed and disarmed by its own control")
	game.farm.snare_armed = false
	game.farm.snares = 0
	game.hunt_snare_sprung = false
	game._refresh_hunt_snare_visual()
	game._sync_levers_instant()
	await _frames(2)
	await _stand_at(Vector3(LEVER_STANCE_X, 0.9, SNARE_LEVER_SPOT.z), SNARE_LEVER_SPOT)
	_ok(game._nearest_interactable() == game.snare_lever, "the snare plate is the arming control")

	# The preparation requirement that already existed is preserved: no built
	# trap, no arming, and the handle must not fake an armed state.
	game.player_interact()
	_ok(not game.farm.snare_armed and not game.snare_lever.is_engaged(),
		"an unbuilt trap cannot be armed and the lever does not move")
	_ok(game.message_label.text.contains("Need a floor snare"),
		"the refusal still explains the workbench preparation")

	game.farm.snares = 1
	game.player_interact()
	await _wait_lever(game.snare_lever)
	_ok(game.farm.snare_armed and game.snare_lever.is_engaged(), "pulling the lever arms the floor snare")
	_ok(game.hunt_snare_visual.visible, "the trap itself is visible at the bait mark once armed")
	_ok(game.farm.snares == 0, "arming consumes the built trap exactly once")

	game.player_interact()
	await _wait_lever(game.snare_lever)
	_ok(not game.farm.snare_armed and not game.snare_lever.is_engaged(),
		"pulling it back returns the mechanism to its inactive state")
	_ok(not game.hunt_snare_visual.visible, "the disarmed trap is folded away again")
	_ok(game.farm.snares == 1, "disarming returns the trap to the pack")


func _test_use_range() -> void:
	begin_case("use_range", "the crank needs the player to stand at it")
	game.hunt_bulkhead_open = false
	game._move_hunt_bulkhead(0.0)
	game._sync_levers_instant()
	await _frames(3)
	await _stand_at(Vector3(LEVER_STANCE_X, 0.9, INNER_LEVER_SPOT.z), INNER_LEVER_SPOT)
	_ok(game._nearest_interactable() == game.bulkhead_crank,
		"the crank is usable from arm's length")
	await _stand_at(Vector3(LEVER_STANCE_X - 1.6, 0.9, INNER_LEVER_SPOT.z), INNER_LEVER_SPOT)
	_ok(game._nearest_interactable() != game.bulkhead_crank,
		"the crank cannot be selected from across the room")
	await _wait_prompt("")
	# Something else may stand within reach here; what matters is that the wall
	# control is no longer offered at this distance.
	_ok(game.prompt_label.text != "HOLD E — CRANK" and game._nearest_interactable() != game.bulkhead_crank,
		"the crank prompt disappears once the player steps out of reach",
		"prompt '%s'" % game.prompt_label.text)
	Input.action_press("interact")
	await _frames(60)
	Input.action_release("interact")
	await _frames(2)
	_ok(not game.hunt_bulkhead_open and not game.bulkhead_crank.is_moving()
		and game.bulkhead_crank.progress == 0.0,
		"holding from an unrealistic distance does nothing at all")


func _test_sound_and_state_sync() -> void:
	begin_case("sound_state", "sound, silence and handle/mechanism sync")
	game.crank_cooldown = 0.0
	game.shutter_open = true
	game._move_shutter(2.6)
	game._sync_levers_instant()
	await _frames(3)
	var plays_before: int = game.shutter_lever.sound_plays
	game._crank()
	await _wait_lever(game.shutter_lever)
	_ok(game.shutter_lever.sound_plays == plays_before + 2,
		"a completed throw plays exactly two mechanical sounds, never repeats")
	_ok(game.shutter_lever.last_sound == "stop_up", "the closing throw reports its upward stop")

	var silent_before: int = game.shutter_lever.sound_plays
	game._crank()
	_ok(game.shutter_lever.sound_plays == silent_before, "a throw refused by cooldown makes no sound")
	game._sync_levers_instant()
	_ok(game.shutter_lever.sound_plays == silent_before,
		"a state sync moves the handle without clicking")

	# The cave-side wheel is a second physical control on the same shutter: the
	# inside handle has to follow it or it would lie about the door.
	game.shutter_open = false
	game._move_shutter(0.0)
	game._sync_levers_instant()
	await _frames(2)
	game._use_cave_return_wheel()
	await _frames(2)
	_ok(game.shutter_open and game.shutter_lever.is_engaged(),
		"the cave-side wheel moves the inside handle to match the shutter")

	var total_sounds: int = (game.shutter_lever.sound_plays + game.bulkhead_crank.sound_plays
		+ game.snare_lever.sound_plays)
	game.farm.snares = 1
	game.farm.snare_armed = true
	game._sync_levers_instant()
	_ok(game.snare_lever.is_engaged(), "the snare handle can be synced to an armed save state")
	game.new_shift(false)
	await _frames(3)
	_ok(not game.shutter_lever.is_engaged() and not game.bulkhead_crank.is_engaged()
		and not game.snare_lever.is_engaged(),
		"a new shift syncs every handle to the reset mechanisms")
	_ok(game.shutter_lever.sound_plays + game.bulkhead_crank.sound_plays
		+ game.snare_lever.sound_plays == total_sounds,
		"resetting the shift is silent")
