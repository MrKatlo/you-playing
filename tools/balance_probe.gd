extends Node

## Headless combat-balance probe for Phases A2, A3 and A4.
##
## Run with:
##   Godot --headless --path . --fixed-fps 60 res://tools/balance_probe.tscn
##
## It does not assert anything. It puts the player on their feet in an open part
## of the basement, drops one slime at a known distance, lets the fight happen
## with no input, and prints the timeline plus derived numbers so the damage and
## timing constants can be judged against real measurements instead of guesses.

const BASEMENT_SCENE: PackedScene = preload("res://scenes/basement.tscn")

var game
var slime
var last_health := 0.0
var last_state := ""
var t := 0.0
var hits: Array = []
var state_changes: Array = []
var down_at := -1.0
var kill_at := -1.0
var steps_taken := 0
var last_step_at := -1.0
var last_step_state := ""
var last_step_distance := 0.0
var last_result := {}
var quiet := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_run.call_deferred()


func _frames(count: int) -> void:
	for _i in range(count):
		await get_tree().physics_frame


func _run() -> void:
	game = BASEMENT_SCENE.instantiate()
	add_child(game)
	game.new_shift(false)
	game.menu.close_menu()
	await _frames(3)

	print("")
	print("=== A2 BALANCE PROBE: player stands still, one slime ===")
	print("player health %.0f | bite %.0f | pounce %.0f | hurt window %.2fs"
		% [game.player.MAX_HEALTH, 14.0, 22.0, game.player.HURT_INVULNERABLE])
	await _duel("slime starts 4.6 m away (approach + pounce range)", Vector3(0.0, 0.0, -3.1))

	print("")
	print("=== A2 BALANCE PROBE: already in biting range ===")
	await _duel("slime starts 1.4 m away (bite, then it makes room to pounce)", Vector3(0.0, 0.0, 0.2))

	print("")
	print("=== A3 BALANCE PROBE: hunter steps out of every pounce ===")
	print("step: %.2f m/s over %.2fs, %.2fs of invulnerability, %.2fs cooldown"
		% [game.player.DODGE_SPEED, game.player.DODGE_TIME,
			game.player.DODGE_INVULNERABLE, game.player.DODGE_COOLDOWN])
	await _duel("same 4.6 m approach, but the hunter steps on each telegraph",
		Vector3(0.0, 0.0, -3.1), true)

	print("")
	print("=== A4 BALANCE PROBE: swing the instant the pounce lands ===")
	print("landing guard: %.2fs armed tail, %.2f m reach"
		% [slime.RECOVER_ARMED if slime != null else 0.34, slime.REFLEX_REACH if slime != null else 1.30])
	await _duel("hunter steps the pounce and swings the frame it lands (greedy)",
		Vector3(0.0, 0.0, -3.1), true, true)

	print("")
	print("=== A4 BALANCE PROBE: let the guarded tail settle, then punish ===")
	await _duel("hunter steps, waits out the guard, then swings (patient)",
		Vector3(0.0, 0.0, -3.1), true, true, 0.38)

	await _run_kiting_sweep()
	await _run_a4_sweep()

	get_tree().quit(0)


## Does the hunt actually hold a walking hunter? The probe drives the hunter at a
## fixed speed straight away from the slime and lets the slime's own chase code
## close. Walls are ignored on purpose: this is the best case for the hunter, so
## a slime that still closes here closes anywhere in a 4 x 4 m chamber.
func _run_kiting_sweep() -> void:
	print("")
	print("=== KITING SWEEP: the two gaits ===")
	print("measured crawl from 4 m of clear floor, 0.5 s, pouncing disabled")
	print("hunter state  set  | measured | vs walk 3.40     | vs sprint 5.80")
	var still: float = await _measure_crawl(4.2, 0.0)
	print("  still        -   |   %4.2f   | %+5.2f m/s %-8s | %+5.2f m/s %-8s" % [
		still, still - 3.4, _rate_verdict(still - 3.4), still - 5.8, _rate_verdict(still - 5.8)])
	for surge in [3.40, 3.80, 4.20, 4.60, 5.00]:
		var moving: float = await _measure_crawl(surge, 3.4)
		print("  walking      %4.2f |   %4.2f   | %+5.2f m/s %-8s | %+5.2f m/s %-8s" % [
			surge, moving, moving - 3.4, _rate_verdict(moving - 3.4),
			moving - 5.8, _rate_verdict(moving - 5.8)])


func _rate_verdict(rate: float) -> String:
	if rate > 0.05:
		return "closes"
	if rate < -0.05:
		return "escapes"
	return "dead heat"


## The slime's own chase code, measured on clear floor against a stationary
## hunter: the room is only 4 x 4 m, so a retreating-hunter test would measure the
## walls rather than the animal. Closing rates are derived from this one number.
func _measure_crawl(prey_speed: float, hunter_velocity: float) -> float:
	for creature in game.burrowers.duplicate():
		if is_instance_valid(creature):
			creature.queue_free()
	game.burrowers.clear()
	game.player.heal_to_full()
	game.player_downed = false
	game.player.invulnerable = 0.0
	game.player.can_move = false
	game.player.global_position = Vector3(0.0, 0.05, 1.6)
	# The slime only reads the hunter's velocity, so a held velocity is enough to
	# put it into its fast gait without the probe having to walk the body anywhere.
	game.player.velocity = Vector3(0.0, 0.0, hunter_velocity)
	await _frames(2)
	game._spawn_burrower(game.player.global_position + Vector3(0.0, 0.0, -4.0))
	slime = game.burrowers[game.burrowers.size() - 1]
	slime.player = game.player
	slime.provoked = true
	slime.speed = prey_speed
	# Only the crawl is under test here; the pounce is the separate anti-flee tool.
	# The bite cooldown is left alone on purpose - a slime that is close enough to
	# bite walks itself in for the bite, so a held cooldown would measure that walk
	# in rather than the gait.
	slime.leap_cooldown = 999.0
	await _frames(4)
	var start: Vector3 = slime.global_position
	var gap0: float = _planar_gap()
	await _frames(30)
	var moved: float = Vector2(slime.global_position.x - start.x,
		slime.global_position.z - start.z).length()
	var gap1: float = _planar_gap()
	var measured: float = moved / 0.5
	# A chaser that stopped (sense, wall, snare) would report zero speed, so make the
	# failure loud instead of printing a quiet 0.00.
	if gap1 > gap0 - 0.05 and prey_speed > 0.1:
		print("   !! no chase measured at %.2f m/s (gap %.2f -> %.2f)" % [prey_speed, gap0, gap1])
	game.player.velocity = Vector3.ZERO
	game.player.can_move = true
	for creature in game.burrowers.duplicate():
		if is_instance_valid(creature):
			creature.queue_free()
	game.burrowers.clear()
	return measured


func _planar_gap() -> float:
	return Vector2(game.player.global_position.x - slime.global_position.x,
		game.player.global_position.z - slime.global_position.z).length()


## A4 tuning: sweep the length of the landing guard and the cost of its bite
## against a greedy hunter (swings the frame the body lands) and a patient one
## (waits out the guard). The target is stated up front so the numbers can be
## judged rather than admired.
func _run_a4_sweep() -> void:
	print("")
	print("=== A4 TUNING SWEEP: armed-tail length (counterbite held at 12) ===")
	print("target: greedy takes >= 1 guard bite | patient takes 0 | patient kill <= 3.20 s | greedy kill > patient")
	print("a swing pressed on the landing frame lands ~0.25 s later, so the tail has") 
	print("to outlast that for the guard to fire at all; below it greed simply wins.")
	print("guard | greedy kill  guard bites | patient kill  guard bites | ratio | verdict")
	for guard in [0.10, 0.16, 0.22, 0.28, 0.34, 0.42, 0.50]:
		var bite := 12.0
		quiet = true
		await _duel("", Vector3(0.0, 0.0, -3.1), true, true, 0.0, guard, bite)
		var greedy := last_result.duplicate()
		await _duel("", Vector3(0.0, 0.0, -3.1), true, true, 0.38, guard, bite)
		var patient := last_result.duplicate()
		quiet = false
		var greedy_guard := int(greedy.get("guard_hits", 0))
		var patient_guard := int(patient.get("guard_hits", 0))
		var ratio: float = _kill_or_zero(greedy) / maxf(_kill_or_zero(patient), 0.01)
		var ok: bool = greedy_guard >= 1 and patient_guard == 0 and ratio > 1.0 and _kill_or_zero(patient) <= 3.20
		print(" %4.2f |   %5.2fs        %d     |   %5.2fs        %d     | %5.2f | %s" % [
			guard, _kill_or_zero(greedy), greedy_guard,
			_kill_or_zero(patient), patient_guard, ratio,
			"meets target" if ok else "fails"])


func _kill_or_zero(result: Dictionary) -> float:
	if result.is_empty() or float(result.get("kill", -1.0)) < 0.0:
		return 30.0
	return float(result["kill"])


func _duel(label: String, slime_start: Vector3, bot_steps := false, bot_fights := false, patience := 0.0, guard := -1.0, bite := -1.0) -> void:
	for creature in game.burrowers.duplicate():
		if is_instance_valid(creature):
			creature.queue_free()
	game.burrowers.clear()
	# A duel that ended in a down leaves its revive timer in the air. Let it resolve
	# here, or it fires mid-duel and clears the slime this duel is measuring.
	if game.down_serial > 0:
		game._revive_player()
	game.player.heal_to_full()
	game.player_downed = false
	game.player.global_position = Vector3(0.0, 0.05, 1.6)
	await _frames(2)

	game._spawn_burrower(slime_start)
	slime = game.burrowers[game.burrowers.size() - 1]
	slime.provoked = true
	if guard > 0.0:
		slime.recover_armed = guard
	if bite > 0.0:
		slime.reflex_bite = bite
	if bot_fights:
		game.player.set_machete_equipped(true)
		game.player.select_slot(game.player.SLOT_MACHETE)

	last_health = game.player.health
	last_state = ""
	t = 0.0
	hits.clear()
	state_changes.clear()
	down_at = -1.0
	kill_at = -1.0
	steps_taken = 0
	last_step_at = -1.0
	last_step_state = ""
	last_step_distance = 0.0

	# 30 simulated seconds is more than enough to resolve both cases.
	for step in range(1800):
		await _frames(1)
		t += 1.0 / 60.0
		if not is_instance_valid(slime):
			break
		if slime.state != last_state:
			last_state = slime.state
			state_changes.append([t, slime.state])
		if game.player.health < last_health - 0.01:
			hits.append([t, last_health - game.player.health, slime.state])
			last_health = game.player.health
		if bot_fights:
			_face_and_fight(slime, patience)
		if bot_steps:
			_maybe_step(slime)
		if is_instance_valid(slime) and slime.dead and kill_at < 0.0:
			kill_at = t
		if down_at < 0.0 and game.player.health <= 0.0:
			down_at = t
		if game.player.health <= 0.0 and t > down_at + 1.0:
			break

	var total := 0.0
	var guard_hits := 0
	for entry in hits:
		total += float(entry[1])
		# A hit taken while the slime is inside its landing recovery is a guard bite;
		# every other hit is an ordinary bite or a pounce.
		if str(entry[2]) == "recover":
			guard_hits += 1
	last_result = {"kill": kill_at, "damage": total, "down": down_at,
		"steps": steps_taken, "guard_hits": guard_hits}
	if quiet:
		return
	print("")
	print("-- ", label)
	print("first pounce wind-up at %.2fs, first contact at %.2fs" % [
		_first_time("crouch"), _first_time("hit")])
	var running := 0.0
	for entry in hits:
		running += float(entry[1])
		print("   t=%5.2fs  -%4.0f health  during %-8s -> %.0f left"
			% [entry[0], entry[1], entry[2], game.player.MAX_HEALTH - running])
	print("   hits taken: %d | total damage %.0f | time to down: %s"
		% [hits.size(), total, "%.2fs" % down_at if down_at >= 0.0 else "never within 30s"])
	if down_at > 0.0:
		print("   survival verdict: %.0fs of standing still (damage per second %.1f)"
			% [down_at, total / max(down_at, 0.01)])
	if kill_at >= 0.0:
		print("   slime killed at %.2fs with %.0f health left" % [kill_at, game.player.health])
	if bot_steps:
		print("   steps landed: %d | last step at %.2fs during %s from %.2f m"
			% [steps_taken, last_step_at, last_step_state, last_step_distance])
	print("   states seen: %s" % _state_summary())


## Turn to face the animal and swing whenever it is inside machete reach, which
## is what a hunter who has learned the recovery window does.
func _face_and_fight(creature, patience := 0.0) -> void:
	if not is_instance_valid(creature):
		return
	var to_target: Vector3 = creature.global_position - game.player.global_position
	game.player.rotation.y = atan2(-to_target.x, -to_target.z)
	if Vector2(to_target.x, to_target.z).length() > 2.1:
		return
	if creature.dead:
		return
	# Patience models a hunter who has learned the landing guard: the blade is
	# held until the armed tail has passed, so the swing is not swept aside. A
	# blade already in the air when the body lands would still be swept, so the
	# patient bot simply refuses to swing at an airborne animal.
	if creature.state == creature.STATE_LEAP:
		return
	if creature.state == creature.STATE_RECOVER and creature.state_time < patience:
		return
	game.player_melee()


## A crude stand-in for a player who has learned the tell: step as soon as the
## body coils while it is close enough to matter. The cooldown is real, so this
## is not freedom from damage, just the ability to refuse the pounce.
func _maybe_step(creature) -> void:
	if not is_instance_valid(creature):
		return
	# Step on the launch, not on the coil: a pounce that has not left the floor yet
	# re-aims at wherever the hunter is standing when it goes, so an early step is
	# bought and paid for with nothing gained.
	if creature.state != creature.STATE_LEAP:
		return
	if game.player.global_position.distance_to(creature.global_position) > 3.6:
		return
	var stepped: bool = game.player.try_dodge()
	if stepped:
		steps_taken += 1
		last_step_at = t
		last_step_state = creature.state
		last_step_distance = game.player.global_position.distance_to(creature.global_position)


func _first_time(kind: String) -> float:
	if kind == "hit":
		return float(hits[0][0]) if hits.size() > 0 else -1.0
	for entry in state_changes:
		if entry[1] == kind:
			return float(entry[0])
	return -1.0


func _state_summary() -> String:
	var counts := {}
	for entry in state_changes:
		counts[entry[1]] = int(counts.get(entry[1], 0)) + 1
	return str(counts)
