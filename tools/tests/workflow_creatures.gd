extends "res://tools/tests/test_base.gd"

## Animal husbandry and hostile creatures
##
## The animal and creature half: live tray animals move and grow,
## the burrower's senses are gated by the sealed bulkhead, its pounce telegraph and
## landing are real, the step-dodge and landing guard answer a swung blade, and the
## hunt loop survives a player death without losing the creature.
##
## Run alone:
##   Godot --headless --path . res://tools/tests/workflow_creatures.tscn


func _init() -> void:
	suite_name = "workflow_creatures"
	suite_level = "workflow"


func run_phases() -> void:
	await _test_cricket_and_gecko_motion()
	await _test_phase_a2_creature_combat()
	await _test_phase_a3_step_dodge()
	await _test_phase_a4_landing_guard()
	await _test_hunt_pressure()
	await _test_slime_facing_and_revive()

func _test_cricket_and_gecko_motion() -> void:
	if game.tray_crickets.is_empty():
		_ok(false, "cricket colony supplies an animated cricket")
		return
	var cricket: Dictionary = game.tray_crickets[0] as Dictionary
	var root: Node3D = cricket.get("root") as Node3D
	var animation: AnimationPlayer = cricket.get("animation") as AnimationPlayer
	_ok(root != null and animation != null, "imported cricket has an animation controller")
	_ok(animation != null and animation.has_animation("idle") and animation.has_animation("hop") and animation.has_animation("feed"), "cricket keeps Riverborn idle, hop, and feed clips")
	if root == null:
		return
	var start_position: Vector3 = root.global_position
	await _frames(16)
	_ok(root.global_position.distance_to(start_position) > 0.005, "cricket hops around its culture tray")
	_ok(animation != null and not animation.current_animation.is_empty(), "cricket is actively playing a supplied animation clip")

	var gecko_start: Vector3 = game.house_gecko.global_position if game.house_gecko != null else Vector3.ZERO
	game.gecko_wait = 0.0
	await _frames(24)
	_ok(game.house_gecko != null and game.house_gecko.global_position.distance_to(gecko_start) > 0.005, "house gecko crawls its warm-room route")
	_ok(game.house_gecko_animation != null and game.house_gecko_animation.has_animation("rest") and game.house_gecko_animation.has_animation("slither"), "gecko keeps Riverborn rest and slither clips")


func _test_phase_a2_creature_combat() -> void:
	# A2 is the creatures' half of the fight: what they can sense, the telegraphed
	# pounce, and what a hit actually costs the player. Everything below drives the
	# real Burrower and the real HUD rather than a stand-in.
	var player = game.player
	Engine.time_scale = 1.0
	_clear_burrowers()
	player.set_downed(false)
	player.heal_to_full()
	player.global_position = Vector3(0.0, 0.9, 2.0)
	player.velocity = Vector3.ZERO
	game.hurt_flash = 0.0
	await _frames(2)

	# Sight, not just distance: the chamber bulkhead is a solid static body, so a
	# slime standing behind a sealed one must not be aware of a hunter two metres
	# away even though the hunter is well inside sense range.
	game.hunt_bulkhead_open = false
	game._move_hunt_bulkhead(0.0)
	await _frames(60)
	player.global_position = Vector3(5.2, 0.9, -2.0)
	await _frames(2)
	game._spawn_burrower(Vector3(7.4, 0.0, -2.0), false)
	var behind_wall: Burrower = game.burrowers[game.burrowers.size() - 1] as Burrower
	var wall_start: Vector3 = behind_wall.global_position
	await _frames(45)
	_ok(behind_wall.state == behind_wall.STATE_CRAWL and behind_wall.global_position.distance_to(wall_start) < 0.12,
		"A2 a sealed bulkhead blocks the slime's awareness of the hunter",
		"state=%s moved=%.2f" % [behind_wall.state, behind_wall.global_position.distance_to(wall_start)])

	# Same pair of bodies, same distance, bulkhead raised: now it senses.
	game.hunt_bulkhead_open = true
	game._move_hunt_bulkhead(2.6)
	await _frames(60)
	var door_reacted := false
	for _frame in 45:
		if behind_wall.state != behind_wall.STATE_CRAWL or behind_wall.global_position.distance_to(wall_start) > 0.12:
			door_reacted = true
			break
		await _frames(1)
	_ok(door_reacted,
		"A2 the same slime senses the hunter once the bulkhead is raised",
		"state=%s moved=%.2f" % [behind_wall.state, behind_wall.global_position.distance_to(wall_start)])
	_clear_burrowers()
	game.hunt_bulkhead_open = false
	game._move_hunt_bulkhead(0.0)
	await _frames(60)

	# A creature that cannot sense the hunter does not track it across the room.
	game._spawn_burrower(Vector3(8.25, 0.0, -2.0), false)
	var distant: Burrower = game.burrowers[game.burrowers.size() - 1] as Burrower
	var distant_start: Vector3 = distant.global_position
	await _frames(40)
	_ok(distant.global_position.distance_to(distant_start) < 0.15 and distant.state == distant.STATE_CRAWL,
		"A2 a slime out of sense range does not home in on the hunter",
		"distance=%.2f state=%s" % [distant.global_position.distance_to(distant_start), distant.state])

	# Move into the hunt chamber and let a live pounce play out end to end.
	player.global_position = Vector3(8.0, 0.9, -1.0)
	player.velocity = Vector3.ZERO
	distant.global_position = Vector3(9.0, 0.0, -3.0)
	distant.speed = 0.0
	distant.attack_cooldown = 0.0
	distant.leap_cooldown = 0.0
	distant.provoked = true
	distant.state = distant.STATE_CRAWL
	await _frames(2)
	var saw_crouch := false
	var crouch_frames := 0
	var saw_ring := false
	for _frame in 90:
		if distant.state == distant.STATE_CROUCH:
			saw_crouch = true
			crouch_frames += 1
			# The floor ring is the tell a hunter sees while backing away.
			if distant.tell_ring != null and distant.tell_ring.visible and distant.tell_material.albedo_color.a > 0.15:
				saw_ring = true
		await _frames(1)
		if distant.state == distant.STATE_LEAP:
			break
	_ok(saw_crouch and crouch_frames >= 16,
		"A2 the pounce crouches into a readable telegraph before it jumps",
		"saw_crouch=%s frames=%d" % [str(saw_crouch), crouch_frames])
	_ok(distant.state == distant.STATE_LEAP and distant.crouch_amount > 0.2,
		"A2 the telegraph resolves into an airborne leap", "state=%s" % distant.state)
	await _frames(2)
	_ok(saw_ring and distant.tell_ring != null and not distant.tell_ring.visible,
		"A2 the wind-up draws a closing warning ring that clears on launch",
		"saw_ring=%s" % str(saw_ring))

	var health_before: float = player.health
	var saw_airborne := distant.global_position.y > 0.05
	var saw_leap_clip := false
	for _frame in 90:
		saw_airborne = saw_airborne or distant.global_position.y > 0.05
		if distant.animation_player != null and distant.animation_player.current_animation == "leap":
			saw_leap_clip = true
		if distant.state == distant.STATE_RECOVER or distant.state == distant.STATE_CRAWL:
			break
		await _frames(1)
	_ok(saw_airborne, "A2 the leap actually leaves the floor")
	_ok(saw_leap_clip, "A2 the airborne phase plays the dedicated leap clip")
	_ok(player.health < health_before,
		"A2 a landed pounce damages the player",
		"before=%.1f after=%.1f" % [health_before, player.health])
	_ok(distant.state == distant.STATE_RECOVER,
		"A2 a landed pounce commits the slime to a recovery pause", "state=%s" % distant.state)

	# The telegraph is a real commitment: a blade during the crouch cancels it.
	distant.state = distant.STATE_CRAWL
	distant.stagger = 0.0
	distant.attack_cooldown = 0.0
	distant.leap_cooldown = 0.0
	distant.global_position = Vector3(9.0, 0.0, -3.0)
	player.global_position = Vector3(8.0, 0.9, -1.0)
	player.heal_to_full()
	var crouched_again := false
	for _frame in 90:
		if distant.state == distant.STATE_CROUCH:
			crouched_again = true
			break
		await _frames(1)
	_ok(crouched_again, "A2 a recovered slime starts a second wind-up", "state=%s" % distant.state)
	distant.take_hit(1, "melee", Vector3(0.0, 0.0, 1.0), 2.0)
	_ok(distant.stagger > 0.0 and distant.provoked,
		"A2 a blade during the wind-up staggers the slime out of the pounce",
		"state=%s stagger=%.2f" % [distant.state, distant.stagger])
	await _frames(3)
	_ok(distant.state == distant.STATE_CRAWL, "A2 the interrupted pounce snaps back to crawling", "state=%s" % distant.state)

	# Player damage feedback: one wound costs health, kicks the camera, flashes the
	# hurt overlay and buys a short window where a second bite cannot land.
	_clear_burrowers()
	player.heal_to_full()
	player.invulnerable = 0.0
	game.hurt_flash = 0.0
	var health_start: float = player.health
	game._damage_player(14.0, player.global_position + Vector3(1.0, 0.0, 0.0), 3.0)
	_ok(is_equal_approx(player.health, health_start - 14.0),
		"A2 creature damage removes health", "health=%.1f" % player.health)
	_ok(game.hurt_flash > 0.5 and game.hurt_overlay != null and game.hurt_overlay.color.a > 0.05,
		"A2 a wound flashes the hurt overlay")
	_ok(player.camera_recoil.length() > 0.01, "A2 a wound kicks the camera", str(player.camera_recoil))
	var health_after_hit: float = player.health
	game._damage_player(14.0, player.global_position + Vector3(1.0, 0.0, 0.0), 3.0)
	_ok(is_equal_approx(player.health, health_after_hit),
		"A2 the hurt window blocks a second bite from landing instantly", "health=%.1f" % player.health)

	# The bite path itself, not just the shared damage helper: a bite has to cost
	# health and dose venom in the same contact.
	var bite_source := Node3D.new()
	game.add_child(bite_source)
	bite_source.global_position = player.global_position + Vector3(1.0, 0.0, 0.0)
	player.invulnerable = 0.0
	game.farm.venom_seconds = 0.0
	var health_before_bite: float = player.health
	game.player_bitten(bite_source)
	_ok(player.health < health_before_bite and game.farm.venom_seconds > 0.0,
		"A2 a bite costs health and doses venom",
		"health=%.1f venom=%.1f" % [player.health, game.farm.venom_seconds])
	bite_source.queue_free()
	game.farm.venom_seconds = 0.0

	game._update_hud()
	_ok(game.health_bar != null and game.health_bar.size.x < 171.0 and game.health_bar.size.x > 1.0,
		"A2 the survival HUD shows the player's remaining health", "width=%.1f" % game.health_bar.size.x)

	# Down and back up: the body recovers at the cot, the shift's haul does not.
	await get_tree().create_timer(player.HURT_INVULNERABLE + 0.05).timeout
	player.health = 5.0
	player.invulnerable = 0.0
	game._damage_player(14.0, player.global_position + Vector3(1.0, 0.0, 0.0), 3.0)
	_ok(game.player_downed and player.downed,
		"A2 enough damage puts the player down", "downed=%s" % str(game.player_downed))
	await _frames(4)
	_ok(game.down_overlay.color.a > 0.05, "A2 going down fades the screen", "alpha=%.2f" % game.down_overlay.color.a)
	var revived := false
	for _frame in 420:
		if not game.player_downed and player.health > 99.0:
			revived = true
			break
		await _frames(1)
	_ok(revived, "A2 the player comes back at the cot at full health", "health=%.1f" % player.health)
	_ok(player.global_position.distance_to(game.START_SPOT) < 0.6,
		"A2 revival returns the player to the cot", str(player.global_position))
	_ok(player.can_move and not player.downed,
		"A2 revival hands control back to the player")

	# Each combat moment has its own cue instead of a repitched clank or swing.
	game.creature_leap_telegraph(distant)
	_ok(game.sfx_player.stream != null and game.sfx_player.stream.resource_path.ends_with("slime_coil.wav"),
		"A2 the wind-up plays the coil cue")
	game.creature_leap_landed(distant, false)
	_ok(game.sfx_player.stream != null and game.sfx_player.stream.resource_path.ends_with("slime_slam.wav"),
		"A2 the landing plays the body-slam cue")
	player.invulnerable = 0.0
	game._damage_player(6.0, player.global_position + Vector3(1.0, 0.0, 0.0), 1.0)
	_ok(game.sfx_player.stream != null and game.sfx_player.stream.resource_path.ends_with("player_hurt.wav"),
		"A2 a wound plays the hunter's hurt cue")

	_clear_burrowers()
	game.hurt_flash = 0.0
	game.down_overlay.color.a = 0.0
	player.heal_to_full()
	player.set_downed(false)
	player.global_position = Vector3(0.0, 0.9, 2.0)
	game._update_hud()


func _test_phase_a3_step_dodge() -> void:
	# A3 is the hunter's answer to the telegraph: a committed step with a short
	# invulnerability window, paid for in noise and a cooldown. It is tested on
	# the live player and a live slime, because the point is that a real pounce
	# passing a real player body does no damage.
	var player = game.player
	Engine.time_scale = 1.0
	_clear_burrowers()
	player.heal_to_full()
	player.set_downed(false)
	player.can_move = true
	player.global_position = Vector3(0.0, 0.05, 1.6)
	player.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	player.dodge_left = 0.0
	player.dodge_cooldown = 0.0
	player.invulnerable = 0.0
	await _frames(4)

	_ok(InputMap.has_action("dodge"), "A3 exposes a dedicated step input")
	var start: Vector3 = player.global_position
	var stepped: bool = player.try_dodge()
	_ok(stepped, "A3 the hunter can step from a standstill")
	_ok(player.dodge_direction.z > 0.9, "A3 a step with no stick input goes backwards")
	_ok(player.invulnerable > 0.0, "A3 the step opens an invulnerability window")
	await _frames(22)
	var travelled := Vector2(player.global_position.x - start.x, player.global_position.z - start.z).length()
	_ok(travelled > 1.4, "A3 the step carries the body", "%.2f m" % travelled)
	_ok(player.dodge_left <= 0.0 and player.global_position.y < 0.3,
		"A3 the step ends on the floor rather than leaving the hunter airborne")

	_ok(not player.try_dodge(), "A3 the step cannot be repeated while it is cooling down")
	await _frames(45)
	_ok(player.try_dodge(), "A3 the step is available again once the cooldown ends")

	# A pounce that reaches a stepping hunter is refused, and the slime still pays
	# for it: contact is consumed, so the animal lands in its recovery window.
	# Let the step bleed off completely first, so the contact distance below is
	# set by the test rather than by leftover momentum.
	await _frames(30)
	player.heal_to_full()
	player.invulnerable = 0.0
	player.dodge_cooldown = 0.0
	game._spawn_burrower(player.global_position + Vector3(0.0, 0.0, -3.0))
	var slime = game.burrowers[game.burrowers.size() - 1]
	slime.player = player
	slime.provoked = true
	await _frames(2)
	slime.state = slime.STATE_LEAP
	slime.state_time = 0.0
	slime.leap_hit_done = false
	# Put the airborne body exactly on the hunter instead of relying on a spawn
	# position that two frames of walking would drift out of reach.
	slime.global_position = player.global_position + Vector3(0.0, 0.0, -0.9)
	var stepped_into_pounce: bool = player.try_dodge()
	var health_before: float = player.health
	slime._check_leap_contact()
	_ok(stepped_into_pounce and slime.leap_hit_done,
		"A3 a pounce still registers contact against a stepping hunter")
	_ok(is_equal_approx(player.health, health_before),
		"A3 the step refuses the pounce damage", "health %.0f -> %.0f" % [health_before, player.health])
	_clear_burrowers()

	# A downed hunter cannot step, so the down state is still a real loss.
	await _frames(40)
	player.dodge_cooldown = 0.0
	player.set_downed(true)
	_ok(not player.try_dodge(), "A3 a downed hunter cannot step")
	player.set_downed(false)
	player.can_move = true
	player.heal_to_full()


func _test_phase_a4_landing_guard() -> void:
	# A4 makes the A3 punish a read rather than a reflex: a missed pounce lands
	# coiled for its first RECOVER_ARMED, and a swing that arrives inside that
	# tail is swept aside and answered with a counterbite. Everything here runs
	# against a live slime so the negation, the bite and the spent guard are the
	# real code paths, not a mock.
	var player = game.player
	Engine.time_scale = 1.0
	_clear_burrowers()
	player.heal_to_full()
	player.set_downed(false)
	player.can_move = true
	player.global_position = Vector3(0.0, 0.05, 1.6)
	player.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	player.dodge_left = 0.0
	player.invulnerable = 0.0
	await _frames(4)

	# Land the pounce from a distance so the slime's own bite cannot colour the
	# setup, then put the hunter inside the guard's reach by hand.
	game._spawn_burrower(player.global_position + Vector3(0.0, 0.0, -3.0))
	var slime = game.burrowers[game.burrowers.size() - 1]
	slime.player = player
	slime.provoked = true
	await _frames(2)
	slime.state = slime.STATE_LEAP
	slime.leap_hit_done = false
	slime._land_leap()
	player.global_position = slime.global_position + Vector3(0.0, 0.05, 1.1)
	player.velocity = Vector3.ZERO
	player.invulnerable = 0.0
	await _frames(2)
	_ok(slime.reflex_armed, "A4 a pounce that missed lands guarded")
	_ok(slime._reflex_threat(), "A4 the guard is live while the hunter stands inside its reach")
	_ok(slime.tell_ring.visible, "A4 the guarded tail is shown on the floor tell ring")

	# Greedy swing: the blade is swept aside and the swinging arm is bitten.
	var slime_health: int = slime.health
	var player_health: float = player.health
	slime.take_hit(1, "melee", Vector3(0.0, 0.0, 1.0), 3.0)
	_ok(int(slime.health) == slime_health,
		"A4 a swing into the guarded tail does no damage", "health %d -> %d" % [slime_health, slime.health])
	_ok(player.health < player_health,
		"A4 the guarded tail answers the swing with a counterbite", "%.0f -> %.0f" % [player_health, player.health])
	_ok(not slime.reflex_armed, "A4 the counterbite spends the guard")

	# The guard is spent, so the rest of the same landing pause is a real opening.
	slime.take_hit(1, "melee", Vector3(0.0, 0.0, 1.0), 3.0)
	_ok(int(slime.health) < slime_health,
		"A4 the rest of the landing pause still takes the blade", "health %d -> %d" % [slime_health, slime.health])
	_clear_burrowers()

	# A pounce that connected has already been paid for, so it lands open.
	game._spawn_burrower(player.global_position + Vector3(0.0, 0.0, -1.5))
	var connected = game.burrowers[game.burrowers.size() - 1]
	connected.player = player
	await _frames(2)
	connected.state = connected.STATE_LEAP
	connected.leap_hit_done = true
	connected._land_leap()
	_ok(not connected.reflex_armed, "A4 a pounce that connected lands without a guard")
	_clear_burrowers()

	# The guard is a close-range answer, not a shield: from the end of the blade it
	# still takes damage on the first swing.
	game._spawn_burrower(player.global_position + Vector3(0.0, 0.0, -2.7))
	var distant = game.burrowers[game.burrowers.size() - 1]
	distant.player = player
	await _frames(2)
	distant.state = distant.STATE_RECOVER
	distant.state_time = 0.0
	distant.reflex_armed = true
	_ok(not distant._reflex_threat(), "A4 the guard does not reach past the blade")
	var distant_health: int = distant.health
	distant.take_hit(1, "melee", Vector3(0.0, 0.0, 1.0), 3.0)
	_ok(int(distant.health) < distant_health, "A4 a swing from outside the guard lands normally")
	_clear_burrowers()

	# The guard closes on its own: waiting out the tail is what opens the punish.
	game._spawn_burrower(player.global_position + Vector3(0.0, 0.0, -1.2))
	var patient = game.burrowers[game.burrowers.size() - 1]
	patient.player = player
	patient.provoked = true
	await _frames(2)
	patient.state = patient.STATE_RECOVER
	patient.state_time = 0.0
	patient.reflex_armed = true
	_ok(patient._reflex_threat(), "A4 the guard is live at the start of the landing pause")
	await _frames(26)
	_ok(not patient._reflex_threat(),
		"A4 the guard closes by itself once the tail has passed", "%.2fs" % patient.state_time)
	_clear_burrowers()
	player.heal_to_full()
	player.invulnerable = 0.0


func _test_hunt_pressure() -> void:
	# The hunt used to leak: a crawling slime was slower than a walk, so any hunter
	# could keep a metre of floor forever and pick it off. The fix is two gaits -
	# a slow stalk that keeps the pounce readable, and a surge that only starts once
	# the hunter moves. Both are measured off the live slime rather than restated.
	var player = game.player
	Engine.time_scale = 1.0
	_clear_burrowers()
	player.heal_to_full()
	player.set_downed(false)
	player.global_position = Vector3(0.0, 0.05, 1.6)
	player.rotation.y = 0.0
	player.can_move = false
	player.velocity = Vector3.ZERO
	player.invulnerable = 0.0
	await _frames(2)

	game._spawn_burrower(player.global_position + Vector3(0.0, 0.0, -4.0))
	var slime = game.burrowers[game.burrowers.size() - 1]
	slime.player = player
	slime.provoked = true
	await _frames(2)
	# Hold it in the crawl branch for the whole sample: at this range it would
	# otherwise crouch straight away and stand still on the telegraph. Only the
	# leap is pinned - a held bite cooldown would park it at pounce range instead
	# of letting it crawl, which is the gait this check is about.
	slime.state = slime.STATE_CRAWL
	slime.leap_cooldown = 99.0
	await _frames(3)
	var stalk_gait: float = Vector2(slime.velocity.x, slime.velocity.z).length()
	_ok(absf(stalk_gait - slime.STALK_SPEED) < 0.05,
		"a still hunter is stalked, so the pounce telegraph still happens", "%.2f m/s" % stalk_gait)

	# A hunter who is walking away: the slime reads the velocity and pours on speed.
	player.velocity = Vector3(0.0, 0.0, 3.4)
	await _frames(3)
	var surge_gait: float = Vector2(slime.velocity.x, slime.velocity.z).length()
	_ok(absf(surge_gait - slime.speed) < 0.05,
		"a moving hunter is chased at the surge speed", "%.2f m/s" % surge_gait)
	_ok(surge_gait > player.WALK_SPEED + 0.5,
		"walking away no longer gains ground", "%.2f vs walk %.2f" % [surge_gait, player.WALK_SPEED])
	_ok(surge_gait < player.RUN_SPEED,
		"a sprint still breaks contact", "%.2f vs sprint %.2f" % [surge_gait, player.RUN_SPEED])

	# Standing back up stops the surge again, so a fight keeps its old pacing.
	player.velocity = Vector3.ZERO
	await _frames(3)
	var settled_gait: float = Vector2(slime.velocity.x, slime.velocity.z).length()
	_ok(absf(settled_gait - slime.STALK_SPEED) < 0.05,
		"the surge drops back to a stalk when the hunter stops", "%.2f m/s" % settled_gait)
	_clear_burrowers()
	player.can_move = true
	player.velocity = Vector3.ZERO
	player.heal_to_full()
	player.invulnerable = 0.0


func _test_slime_facing_and_revive() -> void:
	# Two things the live hunt got wrong: a slime kept its pounce facing at close
	# range (so a hunter who walked around it was bitten at empty air), and a slime
	# that killed the hunter was thrown away with the body instead of staying in the
	# world. Both are measured off the live body here.
	var player = game.player
	Engine.time_scale = 1.0
	_clear_burrowers()
	player.heal_to_full()
	player.set_downed(false)
	player.can_move = false
	player.global_position = Vector3(0.0, 0.05, 1.6)
	player.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	player.invulnerable = 0.0
	await _frames(2)

	game._spawn_burrower(player.global_position + Vector3(0.0, 0.0, -1.0))
	var slime = game.burrowers[game.burrowers.size() - 1]
	slime.player = player
	slime.engaged = true
	# Hold both attacks: this is about facing, not about the bite.
	slime.attack_cooldown = 99.0
	slime.leap_cooldown = 99.0
	slime.rotation.y = PI
	slime.facing = PI
	await _frames(45)
	var off_axis: float = absf(angle_difference(slime.rotation.y, 0.0))
	_ok(off_axis < 0.4,
		"the slime turns back to face a hunter in front of it", "%.2f rad off" % off_axis)

	# It is its own body in the world: nothing in the transform tree or the physics
	# ties it to the hunter, so a pinned slime must not be dragged by a teleport.
	_ok(slime.get_parent() == game and slime.get_parent() != player,
		"the slime is parented to the world, not to the hunter")
	slime.stagger = 9.0
	var anchored: Vector3 = slime.global_position
	player.global_position += Vector3(0.0, 0.0, -3.0)
	await _frames(6)
	var dragged: float = Vector2(slime.global_position.x - anchored.x,
		slime.global_position.z - anchored.z).length()
	_ok(dragged < 0.05, "a pinned slime is not dragged along when the hunter moves", "%.2f m" % dragged)
	slime.stagger = 0.0
	_clear_burrowers()
	player.global_position = Vector3(0.0, 0.05, 1.6)

	# Going down ends the hunt but must not end the creature: it stays alive and
	# exactly where it stood, and it drops its grudge.
	game._spawn_burrower(player.global_position + Vector3(0.0, 0.0, -2.0))
	var survivor = game.burrowers[game.burrowers.size() - 1]
	survivor.player = player
	survivor.engaged = true
	survivor.provoked = true
	await _frames(2)
	var stood_at: Vector3 = survivor.global_position
	game._revive_player()
	# Read the reset on the revive frame itself: a later frame may legitimately
	# re-engage a hunter who is standing in range, and that is not this check.
	_ok(not bool(survivor.engaged) and not bool(survivor.provoked),
		"the revive ends the hunt instead of the creature")
	var moved: float = Vector2(survivor.global_position.x - stood_at.x,
		survivor.global_position.z - stood_at.z).length()
	_ok(moved < 0.05, "the survivor stays at its own world position across a revive", "%.2f m" % moved)
	await _frames(3)
	_ok(game.burrowers.size() == 1 and is_instance_valid(survivor),
		"going down and waking up leaves the surviving creature in the world")
	_ok(survivor.global_position.distance_to(player.global_position) > 2.0,
		"the survivor is not moved onto the respawned hunter")
	_clear_burrowers()
	player.can_move = true
	player.heal_to_full()
	player.invulnerable = 0.0
