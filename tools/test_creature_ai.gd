extends Node

## Dedicated regression test for the hunt creature's whole gameplay loop.
##
## Run with:
##   Godot --headless --path . res://tools/test_creature_ai.tscn
##
## It drives the real production basement scene and the real creature, then reads
## the creature's own state back out: engagement, facing, pounce count, world
## position, parent, cooldowns, health and death. Nothing here waits a fixed time
## and calls that a pass.

const BASEMENT_SCENE: PackedScene = preload("res://scenes/basement.tscn")

const SAFE_SPOT := Vector3(4.5, 0.9, -2.0)
const CHAMBER_SPOT := Vector3(7.0, 0.9, -0.2)
const COT_SPOT := Vector3(0.0, 0.9, 2.0)

var game
var player
var creature
var checks := 0
var fails := 0
var leap_count := 0
var _was_leaping := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _ok(condition: bool, label: String, detail: String = "") -> void:
	checks += 1
	if condition:
		print("  PASS  ", label)
	else:
		fails += 1
		print("  FAIL  ", label, "  ", detail)


func _run() -> void:
	game = BASEMENT_SCENE.instantiate()
	add_child(game)
	_ok(game.player != null, "creature test: production scene is live")
	game.new_shift(false)
	game.menu.close_menu()
	await _frames(2)
	game.finish_opening_sequence_for_test()
	Engine.time_scale = 1.0
	player = game.player
	player.can_move = false
	player.velocity = Vector3.ZERO
	player.heal_to_full()
	player.invulnerable = 0.0
	# The bait chute and the outer shutter wheel are both on the safe side.
	player.global_position = SAFE_SPOT
	player.rotation.y = -PI * 0.5
	await _frames(3)

	await _test_feeding_routine()
	await _test_detect_and_pounce()
	await _test_second_pounce_without_repositioning()
	await _test_bite_leaves_room()
	await _test_retreat_inside_range()
	await _test_disengage_and_return()
	await _test_death_and_respawn_persistence()
	await _test_reengage_after_respawn()
	await _test_machete_kill()

	print("\nCREATURE AI RESULT: %d checks, %d failures" % [checks, fails])
	if game != null and is_instance_valid(game):
		if player != null and is_instance_valid(player) and player.footstep_player != null:
			player.footstep_player.stop()
		if game.sfx_player != null:
			game.sfx_player.stop()
		game.queue_free()
	await get_tree().process_frame
	get_tree().quit(1 if fails > 0 else 0)


# ---------------------------------------------------------------- B1.1 feeding

func _test_feeding_routine() -> void:
	game.farm.fuel = 2.0
	game.farm.snare_armed = false
	game.farm.venom_seconds = 0.0
	game._bait_hook()
	_ok(float(game.lure_left) > 0.0, "B1.1 the bait chute loads a lure window")
	game._crank()
	await _frames(2)
	_ok(bool(game.shutter_open), "B1.1 the outer shutter opens")
	_ok(game.burrowers.size() == 1, "B1.1 the bait draws exactly one creature")
	if game.burrowers.is_empty():
		return
	creature = game.burrowers[0]
	_ok(bool(creature.lure_active) and not bool(creature.engaged),
		"B1.1 the drawn creature starts on its feeding routine, not on the hunter")

	var first: float = _bait_distance()
	await _frames(30)
	var second: float = _bait_distance()
	_ok(second < first - 0.30,
		"B1.1 it walks toward its feeding location", "%.2f -> %.2f m" % [first, second])

	var reached := false
	for _frame in 500:
		await _frames(1)
		if not is_instance_valid(creature):
			break
		if _bait_distance() <= 1.20:
			reached = true
			break
	_ok(reached, "B1.1 it reaches its feeding location", "%.2f m from the chute" % _bait_distance())
	await _frames(20)
	_ok(is_instance_valid(creature) and _speed() < 0.20 and creature.state == creature.STATE_CRAWL,
		"B1.1 it settles into its feeding/idle routine", "%.2f m/s in %s" % [_speed(), str(creature.state)])


# ------------------------------------------------- B1.2/B1.3 detect, face, pounce

func _test_detect_and_pounce() -> void:
	if not is_instance_valid(creature):
		_ok(false, "B1.3 detection: no creature to test")
		return
	game.set_hunt_bulkhead_for_test(true)
	await _frames(2)
	# Step inside the chamber: well inside the sense range, and no longer behind
	# the bulkhead, so the sightline is real rather than assumed.
	player.global_position = CHAMBER_SPOT
	player.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	player.invulnerable = 0.0
	await _frames(10)
	_ok(bool(creature.engaged), "B1.3 the creature notices a hunter inside its sense range")

	# Start counting pounces here, before the telegraph can begin, so the first
	# pounce is a transition this test actually observed.
	leap_count = 0
	_was_leaping = creature.state == creature.STATE_LEAP
	await _frames(14)
	var to_player: Vector3 = player.global_position - creature.global_position
	var wanted := atan2(to_player.x, to_player.z)
	var off: float = absf(angle_difference(creature.rotation.y, wanted))
	_ok(off < 0.35, "B1.3 it turns to face the hunter before attacking", "%.2f rad off" % off)

	var pounced := await _wait_leaps(1, 180)
	_ok(pounced, "B1.1 the creature pounces at the hunter", "leaps %d" % leap_count)


# ------------------------------------------- B1.2 pounce again without moving

func _test_second_pounce_without_repositioning() -> void:
	if not is_instance_valid(creature):
		return
	# The hunter is deliberately not touched here: no teleport, no input, no
	# walking around to the front of the body.
	var second := await _wait_leaps(2, 480)
	_ok(second, "B1.2 a second pounce follows on the creature's own cooldown",
		"leaps %d" % leap_count)

	# The instant a pounce lands, move the hunter sideways. A body that is really
	# an independent world entity cannot follow that: it is committed to its own
	# landing spot for the whole recovery.
	if is_instance_valid(creature):
		for _frame in 120:
			await _frames(1)
			if not is_instance_valid(creature) or creature.state == creature.STATE_RECOVER:
				break
		if is_instance_valid(creature) and creature.state == creature.STATE_RECOVER:
			var landed_at: Vector3 = creature.global_position
			player.global_position += Vector3(1.6, 0.0, 0.0)
			await _frames(3)
			var slipped: float = Vector2(creature.global_position.x - landed_at.x,
				creature.global_position.z - landed_at.z).length()
			_ok(slipped < 0.06,
				"B1.4 a landed creature keeps its own world position", "%.2f m" % slipped)
			_ok(creature.get_parent() == game and creature.get_parent() != player,
				"B1.4 the creature is parented to the world, not to the hunter")


# ------------------------------------------- B1.4 the bite must not glue it on

func _test_bite_leaves_room() -> void:
	# The live report was specific: on "Teeth. Venom in the arm." the body stayed
	# stuck to the hunter, and backing away pulled it along. The bite has to end
	# with the creature out of contact, and the pause afterwards must not follow.
	if not is_instance_valid(creature):
		return
	player.global_position = Vector3(7.2, 0.9, -3.2)
	player.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	player.heal_to_full()
	player.invulnerable = 0.0
	game.farm.venom_seconds = 0.0
	creature.global_position = Vector3(7.2, 0.0, -2.25)
	creature.velocity = Vector3.ZERO
	creature.state = creature.STATE_CRAWL
	creature.attack_cooldown = 0.0
	# Hold the pounce so this is the close-range bite and not a leap.
	creature.leap_cooldown = 6.0
	await _frames(3)
	_ok(creature.attack_cooldown > 1.0 and player.health < player.MAX_HEALTH,
		"B1.4 the creature bites a hunter who stands in its face",
		"cooldown %.2f, health %.0f" % [creature.attack_cooldown, player.health])

	await _frames(20)
	var after_bite: float = _gap()
	_ok(after_bite >= 1.40,
		"B1.4 the body recoils out of contact after the bite", "%.2f m" % after_bite)

	# Back away during the bite recovery. It is allowed to pounce across the gap
	# afterwards; it is not allowed to creep after the hunter. The step is taken
	# away from the body and clamped to the room, so it measures the creature and
	# not a wall.
	var body_before: Vector3 = creature.global_position
	var step_from: Vector3 = player.global_position
	var away: Vector3 = step_from - creature.global_position
	away.y = 0.0
	away = away.normalized() if away.length() > 0.01 else Vector3.BACK
	var destination: Vector3 = step_from + away * 2.0
	destination.x = clampf(destination.x, 6.35, 9.65)
	destination.z = clampf(destination.z, -3.65, -0.35)
	destination.y = step_from.y
	player.global_position = destination
	var step: float = Vector2(destination.x - step_from.x, destination.z - step_from.z).length()
	await _frames(25)
	var body_moved: float = Vector2(creature.global_position.x - body_before.x,
		creature.global_position.z - body_before.z).length()
	_ok(_gap() >= after_bite + step * 0.6,
		"B1.4 a retreat during the bite recovery opens the gap",
		"%.2f -> %.2f m for a %.2f m step" % [after_bite, _gap(), step])
	_ok(body_moved < step * 0.4,
		"B1.4 the creature does not walk back with the hunter",
		"creature moved %.2f m of the hunter's %.2f m" % [body_moved, step])
	creature.leap_cooldown = 0.0
	player.invulnerable = 0.0


# ---------------------------------------------------- B1.6 retreat inside range

func _test_retreat_inside_range() -> void:
	if not is_instance_valid(creature):
		return
	# Re-anchor inside the chamber: the pounces before this knocked the hunter
	# around, and a body shoved through a wall would be measuring the wall.
	player.global_position = Vector3(7.0, 0.9, -1.0)
	player.velocity = Vector3.ZERO
	player.heal_to_full()
	player.invulnerable = 0.0
	game.farm.venom_seconds = 0.0
	await _frames(3)
	# Wait for it to commit to a landing. A body in the middle of its own recovery
	# is the clearest case: nothing in the world may move it when the hunter does.
	var landed := false
	for _frame in 420:
		await _frames(1)
		if not is_instance_valid(creature):
			break
		if creature.state == creature.STATE_RECOVER:
			landed = true
			break
	_ok(landed, "B1.1 the creature commits to the landing")
	if not landed:
		_diag("no landing")

	if is_instance_valid(creature) and creature.state == creature.STATE_RECOVER:
		var gap_before: float = _gap()
		var body_before: Vector3 = creature.global_position
		# Straight away from the body, not through it, and held inside the room so
		# the measurement is about the creature and not about clipping a wall.
		var away: Vector3 = player.global_position - creature.global_position
		away.y = 0.0
		away = away.normalized() if away.length() > 0.01 else Vector3.BACK
		var step_from: Vector3 = player.global_position
		var destination: Vector3 = step_from + away * 2.0
		destination.x = clampf(destination.x, 6.35, 9.65)
		destination.z = clampf(destination.z, -3.65, -0.35)
		destination.y = step_from.y
		player.global_position = destination
		var step: float = Vector2(destination.x - step_from.x, destination.z - step_from.z).length()
		await _frames(3)
		var gap_after: float = _gap()
		var body_moved: float = Vector2(creature.global_position.x - body_before.x,
			creature.global_position.z - body_before.z).length()
		_ok(gap_after >= gap_before + step * 0.6,
			"B1.4 the hunter backs away without dragging the creature along",
			"%.2f -> %.2f m for a %.2f m step" % [gap_before, gap_after, step])
		_ok(body_moved < step * 0.4,
			"B1.4 the creature does not travel with the hunter",
			"creature moved %.2f m of the hunter's %.2f m" % [body_moved, step])
		_ok(bool(creature.engaged) and gap_after <= creature.SENSE_RANGE,
			"B1.6 it keeps tracking a hunter who backs away inside range", "%.2f m" % gap_after)

	player.velocity = Vector3.ZERO
	player.invulnerable = 0.0
	var resumed := await _wait_leaps(leap_count + 1, 480)
	_ok(resumed, "B1.6 it attacks again after the retreat", "leaps %d" % leap_count)


# ------------------------------------------------------ B1.6 disengage, return

func _test_disengage_and_return() -> void:
	if not is_instance_valid(creature):
		return
	# Keep the bait window open so "back to its routine" is observable rather than
	# already expired by the time this phase runs.
	game.lure_left = 45.0
	player.global_position = COT_SPOT
	player.velocity = Vector3.ZERO
	player.heal_to_full()
	game.farm.venom_seconds = 0.0
	# The hunter leaves the way the room intends: through the bulkhead, and shuts it
	# behind them. The slime then has no sightline and no hunter to chase.
	if game.hunt_bulkhead_open:
		game.set_hunt_bulkhead_for_test(false)
	await _frames(110)
	_ok(not bool(creature.engaged), "B1.6 it disengages once the hunter is well out of range",
		"%.2f m" % _gap())
	_ok(not bool(creature.provoked), "B1.6 it drops the grudge when the hunter leaves")

	var before: float = _bait_distance()
	await _frames(45)
	var after: float = _bait_distance()
	var idle: bool = _speed() < 0.20
	_ok(after < before - 0.10 or idle,
		"B1.6 it returns to feeding instead of guarding the hunt room",
		"%.2f -> %.2f m, %.2f m/s" % [before, after, _speed()])
	_ok(not bool(creature.engaged), "B1.6 it does not re-engage a hunter it left behind")


# ------------------------------------- B1.5 death, respawn, surviving creature

func _test_death_and_respawn_persistence() -> void:
	if not is_instance_valid(creature):
		return
	# Bring the fight back on, then let the creature land a real killing blow
	# through the production damage path.
	player.global_position = CHAMBER_SPOT
	player.velocity = Vector3.ZERO
	await _frames(12)
	var before_down: int = game.burrowers.size()
	player.health = 1.0
	player.invulnerable = 0.0
	game.player_bitten(creature)
	await _frames(3)
	_ok(bool(game.player_downed), "B1.5 the hunter goes down when health reaches zero")

	var woke := false
	for _frame in 420:
		await _frames(1)
		if not bool(game.player_downed):
			woke = true
			break
	_ok(woke, "B1.5 the hunter respawns")
	await _frames(10)

	_ok(is_instance_valid(creature) and creature in game.burrowers,
		"B1.5 the creature that killed the hunter is still in the world")
	_ok(game.burrowers.size() == before_down,
		"B1.5 the respawn neither deletes nor duplicates the creature",
		"%d -> %d" % [before_down, game.burrowers.size()])
	if is_instance_valid(creature):
		_ok(creature.get_parent() == game and creature.get_parent() != player,
			"B1.5 it is still an independent world entity")
		_ok(_gap() > 3.0, "B1.5 it is not attached to the respawned hunter", "%.2f m" % _gap())
		_ok(creature.global_position.distance_to(COT_SPOT) > 3.0,
			"B1.5 it stayed at its own world location, not on the body")
		# Frame-exact reset: check it on the same frame the revive lands, before any
		# physics frame can legitimately re-engage a hunter standing in range.
		creature.engaged = true
		creature.provoked = true
		game._revive_player()
		_ok(is_instance_valid(creature) and not bool(creature.engaged) and not bool(creature.provoked),
			"B1.5 going down drops the hunt without dropping the creature")
		_ok(creature in game.burrowers, "B1.5 the survivor is still on the hunt list after the revive")


# --------------------------------------------------- B1.6 re-engage after death

func _test_reengage_after_respawn() -> void:
	if not is_instance_valid(creature):
		return
	leap_count = 0
	_was_leaping = creature.state == creature.STATE_LEAP
	player.global_position = CHAMBER_SPOT
	player.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	player.heal_to_full()
	player.invulnerable = 0.0
	await _frames(12)
	_ok(bool(creature.engaged), "B1.5 the surviving creature detects the hunter again")
	_ok(await _wait_leaps(1, 240), "B1.5 the surviving creature attacks again")


# ------------------------------------------------------------- B1.7 machete kill

func _test_machete_kill() -> void:
	if not is_instance_valid(creature):
		return
	player.set_machete_equipped(true)
	player.select_slot(player.SLOT_MACHETE)
	game.farm.venom_seconds = 0.0
	player.heal_to_full()
	player.invulnerable = 99.0
	# Park it in front of the hunter, in the crawl, so the blade is not answering a
	# landing guard.
	player.global_position = Vector3(7.0, 0.9, -0.6)
	creature.global_position = Vector3(7.0, 0.0, -1.8)
	creature.velocity = Vector3.ZERO
	creature.state = creature.STATE_CRAWL
	creature.attack_cooldown = 99.0
	creature.leap_cooldown = 99.0
	player.rotation.y = 0.0
	await _frames(4)
	_ok(player.machete_equipped and player.active_slot == player.SLOT_MACHETE,
		"B1.7 the hunter can draw the machete at the creature")

	var full_health: int = int(creature.health)
	game.player_machete_strike("horizontal")
	await _frames(2)
	Engine.time_scale = 1.0
	game.hit_stop_serial += 1
	_ok(int(creature.health) == full_health - 1,
		"B1.7 the machete damages the creature", "%d -> %d" % [full_health, int(creature.health)])

	# The hit knocks it back; walk up to it again for the second cut.
	await _frames(30)
	creature.attack_cooldown = 99.0
	creature.leap_cooldown = 99.0
	creature.state = creature.STATE_CRAWL
	creature.global_position = player.global_position + Vector3(0.0, -0.9, -1.2)
	await _frames(2)
	game.player_machete_strike("horizontal")
	await _frames(2)
	Engine.time_scale = 1.0
	game.hit_stop_serial += 1
	_ok(int(creature.health) <= 0 and bool(creature.dead),
		"B1.7 the second cut kills the creature", "health %d" % int(creature.health))
	await _frames(60)
	_ok(game.burrowers.is_empty(), "B1.7 the dead creature leaves the hunt list")
	_ok(_has_interactable("carcass"), "B1.7 death leaves remains to gather")


# ----------------------------------------------------------------------- helpers

func _frames(count: int) -> void:
	for _frame in count:
		await get_tree().physics_frame


func _poll() -> void:
	if not is_instance_valid(creature):
		return
	var leaping: bool = creature.state == creature.STATE_LEAP
	if leaping and not _was_leaping:
		leap_count += 1
	_was_leaping = leaping


func _wait_leaps(target: int, max_frames: int) -> bool:
	for _frame in max_frames:
		await _frames(1)
		if not is_instance_valid(creature):
			return false
		_poll()
		if leap_count >= target:
			return true
	_diag("no pounce %d" % target)
	return leap_count >= target


func _diag(label: String) -> void:
	if not is_instance_valid(creature):
		print("   [diag] ", label, " creature gone")
		return
	var to_player: Vector3 = player.global_position - creature.global_position
	var off: float = absf(angle_difference(creature.rotation.y, atan2(to_player.x, to_player.z)))
	print("   [diag] %s | state=%s atk=%.2f leap=%.2f eng=%s lost=%.2f gap=%.2f off=%.2f hp=%.0f downed=%s pos=%s" % [
		label, str(creature.state), creature.attack_cooldown, creature.leap_cooldown,
		str(creature.engaged), creature.lost_sight, _gap(), off, player.health,
		str(player.downed), str(creature.global_position)])


func _gap() -> float:
	if not is_instance_valid(creature):
		return 999.0
	return Vector2(player.global_position.x - creature.global_position.x,
		player.global_position.z - creature.global_position.z).length()


func _bait_distance() -> float:
	if not is_instance_valid(creature):
		return 999.0
	var offset: Vector3 = creature.global_position - game.HUNT_BAIT_SPOT
	offset.y = 0.0
	return offset.length()


func _speed() -> float:
	if not is_instance_valid(creature):
		return 0.0
	return Vector2(creature.velocity.x, creature.velocity.z).length()


func _has_interactable(kind: String) -> bool:
	for item in game.interactables:
		if item is Node and is_instance_valid(item):
			if str((item as Node).get_meta("kind", "")) == kind:
				return true
	return false
