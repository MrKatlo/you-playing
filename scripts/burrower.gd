class_name Burrower
extends CharacterBody3D

# The thing that comes through the bait room is not another animal-shaped
# enemy. It is a heat-seeking basement slime. The visual is a generated,
# rigged, animated asset; this script connects its living behaviour to clips.

const SLIME_MODEL := preload("res://assets/models/basement/generated/creatures/slime/basement_slime.glb")
const CINDER_MODEL := preload("res://assets/models/basement/generated/creatures/cinder_burrower/cinder_burrower.glb")

var game: Node
var player: Node3D
var health := 2
# Variant configuration (M6). The plain basement slime is the default; the cinder
# burrower is the same body and brain with a heavier set of numbers and one extra
# death rule. Nothing here changes the AI: a variant is data, not a second script.
var variant := "slime"
var max_health := 2
var knockback_on_hit := 0.0
var splits_on_death := false
var loot_table: Dictionary = {}
var body_colour := Color(0.0, 0.0, 0.0, 0.0)
# C2.12 // a painted variant replaces the authored material colour instead of
# multiplying it (green times red is mud), so a red lure reads as red.
var body_paint := false
var body_scale := 1.0
# A leashed creature gives up the hunt and walks home instead of towing the
# player through the whole map. Zero radius means no leash (the base slime).
var leash_center := Vector3.ZERO
var leash_radius := 0.0
var _tinted := false
# Two gaits. A still hunter is stalked at 1.35 m/s, which is slow enough that the
# pounce telegraph still happens and the fight keeps its A2-A4 shape. The moment
# the hunter moves, the slime pours itself forward at 4.2 m/s: faster than a walk
# (3.4), slower than a sprint (5.8), so backing away or circling no longer works
# while a sprint still breaks contact.
const STALK_SPEED := 1.35
var speed := 4.2
var dead := false
var attack_cooldown := 0.0
var stagger := 0.0
var tether_left := 0.0
var lure_target := Vector3.ZERO
var lure_active := false
var visual: Node3D
var tell_ring: MeshInstance3D
var tell_material: StandardMaterial3D
var animation_player: AnimationPlayer
var collision_shape: CollisionShape3D
var clock := 0.0
var animation_lock := 0.0
var death_left := 0.0
var knockback_velocity := Vector3.ZERO
var hit_recoil := 0.0
var hit_direction := Vector3.ZERO
# Combat state. crawl is the default hunt, crouch is the leap telegraph, leap is
# the airborne committed attack, and recover is the landing pause that lets the
# player punish a missed pounce.
const STATE_CRAWL := "crawl"
const STATE_CROUCH := "crouch"
const STATE_LEAP := "leap"
const STATE_RECOVER := "recover"
const SENSE_RANGE := 7.5
# Engagement is sticky on purpose: a hunter is taken as prey the moment the slime
# can sense it, and the fight is only dropped once it has lost the hunter for over
# a second (a bulkhead closing, a wall) or the hunter is well past sense range. A
# single lost ray or one step over the doorway line does not flip feeding on.
const LOSE_SIGHT_TIME := 1.2
const DISENGAGE_RANGE := 9.5
# The body spheres can never get closer than ~0.82 m, so a bite has to reach
# past that contact gap or a slime can only ever pounce and then hover.
const BITE_RANGE := 1.14
const BITE_CONTACT := 1.02
const LEAP_MIN_RANGE := 1.55
const LEAP_MAX_RANGE := 4.40
const LEAP_WINDUP := 0.46
const LEAP_RECOVER := 0.78
# A pounce that misses still lands coiled over its own mass. The first stretch of
# the recovery is a guard rather than a gift: a blade that arrives inside it is
# swept aside and answered with a short counterbite, so the landing pause has to
# be waited out instead of reflex-swung. The guard only covers close range, which
# keeps the punish honest for a hunter who swings at the end of the blade.
const RECOVER_ARMED := 0.34
# The guard covers the whole blade: a step out of a pounce leaves the hunter about
# 1.9 m away, which is exactly machete range, so anything shorter would make the
# guard a decoration that a dodging hunter could never actually feel.
const REFLEX_REACH := 2.00
# Tuning knobs, measured with tools/balance_probe.tscn: how long the landing stays
# guarded, and what the guard bite costs.
var recover_armed := RECOVER_ARMED
var reflex_bite := 12.0
var state := STATE_CRAWL
var state_time := 0.0
var leap_hit_done := false
var reflex_armed := false
var leap_cooldown := 0.0
var crouch_amount := 0.0
var provoked := false
# True while the slime has the hunter as prey. Kept across the whole fight; the
# bait chute never outranks it.
var engaged := false
var lost_sight := 0.0
var facing := 0.0
var sight_check := 0.0
var sight_clear := true
const SIGHT_INTERVAL := 0.12


## Called before the body enters the tree, so the visual is built with the variant
## already known (tint, size) rather than re-tinted afterwards.
func configure_variant(config: Dictionary) -> void:
	variant = str(config.get("variant", "cinder"))
	max_health = maxi(1, int(config.get("max_health", 3)))
	health = max_health
	speed = float(config.get("speed", 4.8))
	knockback_on_hit = maxf(0.0, float(config.get("knockback_on_hit", 0.0)))
	splits_on_death = bool(config.get("splits_on_death", false))
	loot_table = config.get("loot_table", {}) as Dictionary
	body_colour = config.get("body_colour", Color(0.62, 0.24, 0.05))
	body_paint = bool(config.get("body_paint", false))
	body_scale = float(config.get("body_scale", 1.0))
	leash_center = config.get("leash_center", Vector3.ZERO)
	leash_radius = float(config.get("leash_radius", 0.0))


func _ready() -> void:
	name = "HuntSlime"
	collision_shape = CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.48 * body_scale
	collision_shape.shape = sphere
	collision_shape.position.y = 0.29 * body_scale
	add_child(collision_shape)
	_build_visual()


func _build_visual() -> void:
	# The cinder variant has its own generated body: same rig and clips, burnt
	# orange materials with hot seams, so it is not a runtime tint over the slime.
	var cinder := variant == "cinder"
	visual = (CINDER_MODEL if cinder else SLIME_MODEL).instantiate() as Node3D
	visual.name = "GeneratedCinderBurrower" if cinder else "GeneratedBasementSlime"
	add_child(visual)
	animation_player = _find_animation(visual)
	_play_clip("idle")
	_apply_body_tint()
	_build_tell_ring()


## The variant is a recolour, not a new model: every surface keeps its texture and
## gets a dark-orange tint plus a low emission, which reads as the seams glowing
## once the light is a failing strip. Ordinary bodies are left untouched.
func _apply_body_tint() -> void:
	# Only the plain body is touched here; the cinder variant carries its own
	# generated materials and must not be multiplied a second time. A plain body
	# with no colour keeps the palette it was authored with, which is the green
	# home-base slime rather than a forced orange.
	if _tinted or variant != "slime" or visual == null:
		return
	if not body_paint and body_colour.a <= 0.0:
		return
	_tinted = true
	for node in visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_instance := node as MeshInstance3D
		var mesh := mesh_instance.mesh
		if mesh == null:
			continue
		for surface in mesh.get_surface_count():
			var source := mesh.surface_get_material(surface) as StandardMaterial3D
			var material: StandardMaterial3D = source.duplicate() if source != null else StandardMaterial3D.new()
			if body_paint:
				material.albedo_color = body_colour
			else:
				material.albedo_color = material.albedo_color * body_colour
			material.emission_enabled = true
			material.emission = Color(0.95, 0.26, 0.02) if not body_paint else Color(0.70, 0.08, 0.03)
			material.emission_energy_multiplier = 0.5 if not body_paint else 0.35
			mesh_instance.set_surface_override_material(surface, material)


func _build_tell_ring() -> void:
	# The crouch is the tell, but a squash alone is easy to miss when the hunter is
	# backing away. A ring on the floor closes in as the body coils, so the warning
	# is legible from any camera angle and shows where the pounce starts.
	var torus := TorusMesh.new()
	torus.inner_radius = 0.60
	torus.outer_radius = 0.70
	torus.rings = 24
	torus.ring_segments = 6
	tell_material = StandardMaterial3D.new()
	tell_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tell_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tell_material.albedo_color = Color(0.78, 0.16, 0.10, 0.0)
	tell_material.no_depth_test = false
	tell_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	tell_ring = MeshInstance3D.new()
	tell_ring.name = "PounceTell"
	tell_ring.mesh = torus
	tell_ring.material_override = tell_material
	tell_ring.position.y = 0.03
	tell_ring.scale = Vector3(1.0, 0.05, 1.0)
	tell_ring.visible = false
	add_child(tell_ring)


func _find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation(child)
		if found != null:
			return found
	return null


func _play_clip(clip: String, force_restart: bool = false) -> void:
	if animation_player == null or not animation_player.has_animation(clip):
		return
	if force_restart or animation_player.current_animation != clip:
		animation_player.play(clip)


func set_hunt_lure(target: Vector3) -> void:
	lure_target = target
	lure_active = true


func _physics_process(delta: float) -> void:
	clock += delta
	hit_recoil = maxf(0.0, hit_recoil - delta)
	crouch_amount = move_toward(crouch_amount, 1.0 if state == STATE_CROUCH else 0.0, delta * 5.5)
	_update_visual()
	if dead:
		death_left -= delta
		if death_left <= 0.0:
			queue_free()
		return
	animation_lock = maxf(0.0, animation_lock - delta)
	if tether_left > 0.0:
		tether_left = maxf(0.0, tether_left - delta)
		state = STATE_CRAWL
		velocity = Vector3.ZERO
		if animation_lock <= 0.0:
			_play_clip("lure")
		return
	if stagger > 0.0:
		stagger = maxf(0.0, stagger - delta)
		state = STATE_CRAWL
		# A machete impact moves the mass only a short distance, then friction
		# catches it. This reads as a heavy gel body recoiling, not ragdoll launch.
		velocity.x = knockback_velocity.x
		velocity.z = knockback_velocity.z
		velocity.y = -0.1
		knockback_velocity = knockback_velocity.move_toward(Vector3.ZERO, delta * 10.5)
		move_and_slide()
		if animation_lock <= 0.0:
			_play_clip("idle")
		return
	if player == null:
		player = game.get("player") as Node3D if game != null else null
	if player == null:
		return
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	leap_cooldown = maxf(0.0, leap_cooldown - delta)
	state_time += delta
	if leash_radius > 0.0:
		var home: Vector3 = leash_center - global_position
		home.y = 0.0
		if home.length() > leash_radius:
			# Out of its pocket: the hunt is dropped and the body runs the wall
			# line home, so the threat stays where the papers are.
			engaged = false
			provoked = false
			lost_sight = 0.0
			state = STATE_CRAWL
			state_time = 0.0
			reflex_armed = false
			leap_hit_done = false
			var home_direction := home.normalized()
			facing = lerp_angle(facing, atan2(home_direction.x, home_direction.z), minf(1.0, delta * 8.0))
			rotation.y = facing
			velocity = Vector3(home_direction.x * speed, -0.1, home_direction.z * speed)
			if animation_player != null:
				animation_player.speed_scale = 1.7
			if animation_lock <= 0.0:
				_play_clip("crawl")
			move_and_slide()
			_try_snare()
			return
	# Engagement is tracked in every state, not just the crawl: a hunt has to end
	# when the hunter shuts a bulkhead behind them even if the last thing the slime
	# did was leave the floor.
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var player_distance: float = to_player.length()
	_update_engagement(player_distance, delta)
	if player_distance > DISENGAGE_RANGE:
		provoked = false

	if state == STATE_CROUCH:
		# Commit nothing yet: the coiled body is the tell that a pounce is coming.
		velocity = Vector3.ZERO
		_try_snare()
		if animation_lock <= 0.0:
			_play_clip("crouch")
		if state_time >= LEAP_WINDUP:
			_launch_leap()
		return

	if state == STATE_LEAP:
		velocity.y -= 18.0 * delta
		move_and_slide()
		_check_leap_contact()
		if global_position.y < 0.02 or (is_on_floor() and velocity.y <= 0.0):
			_land_leap()
		return

	if state == STATE_RECOVER:
		velocity.x = move_toward(velocity.x, 0.0, delta * 9.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 9.0)
		velocity.y = -0.1
		move_and_slide()
		if state_time >= LEAP_RECOVER:
			state = STATE_CRAWL
			state_time = 0.0
			reflex_armed = false
			attack_cooldown = maxf(attack_cooldown, 0.7)
		if animation_lock <= 0.0:
			_play_clip("idle")
		return

	if lure_active and game != null and float(game.get("lure_left")) <= 0.0:
		# The lure is bait, not magic. Once it is spent the slime stops guarding
		# the chute, but a closed bulkhead still physically protects the farm room.
		lure_active = false
	# The bait is the creature's routine, not its combat brain. Anything it can
	# actually sense outranks the chute, or the slime abandons a fight mid-pounce to
	# walk back and feed while the hunter is standing in front of it.
	var hunting_player: bool = engaged
	if not hunting_player and provoked:
		# A cut creature keeps hunting, but it still has to be able to place the
		# hunter; a wall is a wall.
		hunting_player = player_distance <= SENSE_RANGE and _see_through_to(player.global_position, delta)
	var target_position: Vector3 = player.global_position if hunting_player else lure_target
	var to_target: Vector3 = target_position - global_position
	to_target.y = 0.0
	var distance: float = to_target.length()

	if not hunting_player and not lure_active:
		# Nothing to hunt and no bait in front of it: hold its ground and wait.
		velocity = Vector3.ZERO
		_try_snare()
		if animation_lock <= 0.0:
			_play_clip("idle")
		return

	# Face the target in every grounded state, not just while closing. A pounce lands
	# aimed at where the hunter stood, so without this the slime keeps biting and
	# coiling at empty air while the hunter walks around in front of it.
	var direction: Vector3 = to_target.normalized() if distance > 0.01 else Vector3(sin(facing), 0.0, cos(facing))
	# Turn toward the target instead of snapping, so the approach reads as a
	# body changing its mind rather than a model teleporting its facing.
	facing = lerp_angle(facing, atan2(direction.x, direction.z), minf(1.0, delta * 8.0))
	rotation.y = facing

	if not hunting_player:
		# Bait routine: crawl to the chute and settle on it.
		if distance > BITE_RANGE:
			velocity = Vector3(direction.x * STALK_SPEED, -0.1, direction.z * STALK_SPEED)
			if animation_lock <= 0.0:
				_play_clip("lure")
			move_and_slide()
			_try_snare()
			return
		velocity = Vector3.ZERO
		_try_snare()
		if animation_lock <= 0.0:
			_play_clip("lure")
		return

	# Hunt. The pounce is the attack, so pounce range is the only distance the body
	# settles at. It never parks against the hunter: the bite is the punishment for
	# walking into its face, and the body recoils out of reach straight afterwards
	# whether or not the next leap is loaded yet.
	if distance <= BITE_RANGE and attack_cooldown <= 0.0 and leap_cooldown > 0.5 and game != null:
		attack_cooldown = 2.4
		animation_lock = 0.42
		_play_clip("strike", true)
		game.call("player_bitten", self)
		return
	# A bite is coming: it is only held off by the short tail of its own landing, so
	# the body stays put for that beat rather than recoiling out of a bite it had
	# already earned. Anything longer than that and it gathers back instead.
	var bite_pending: bool = leap_cooldown > 0.5 and attack_cooldown <= 0.8
	if distance < LEAP_MIN_RANGE + 0.10 and not bite_pending:
		# Gather back out to pounce range. This is not a gap held against the
		# hunter's movement: it stops the moment it has room to leap, so backing
		# away still opens real space instead of towing the creature along.
		velocity = Vector3(-direction.x * speed, -0.1, -direction.z * speed)
		if animation_player != null:
			animation_player.speed_scale = 1.7
		if animation_lock <= 0.0:
			_play_clip("crawl")
		move_and_slide()
		_try_snare()
		return
	if _should_leap(distance):
		_begin_crouch()
		return
	if attack_cooldown > 0.0 and distance <= LEAP_MAX_RANGE:
		# Waiting out its own bite recovery at pounce range, not leaning on the
		# hunter: the whole silhouette stays in frame and the next move is a pounce.
		# It also does not creep after a hunter who backs off during this pause - it
		# waits, then covers the whole gap with one leap.
		velocity = Vector3.ZERO
		_try_snare()
		if animation_lock <= 0.0:
			_play_clip("idle")
		return
	var gait: float = speed if _hunter_moving() else STALK_SPEED
	velocity = Vector3(direction.x * gait, -0.1, direction.z * gait)
	# The body visibly pours forward instead of gliding at a constant rate.
	if animation_player != null:
		animation_player.speed_scale = 1.0 if gait <= STALK_SPEED + 0.01 else 1.7
	if animation_lock <= 0.0:
		_play_clip("crawl")
	move_and_slide()
	_try_snare()


## The hunter has to be somewhere the creature can actually sense it before the
## fight starts, and the fight is only dropped once it is well out of sense range.
## Feeding never wins over an engaged hunt.
func _update_engagement(player_distance: float, delta: float) -> void:
	var seen := _see_through_to(player.global_position, delta)
	if not engaged:
		if player_distance <= SENSE_RANGE and seen:
			engaged = true
			lost_sight = 0.0
		return
	if seen:
		lost_sight = 0.0
	else:
		lost_sight += delta
	if player_distance > DISENGAGE_RANGE or lost_sight >= LOSE_SIGHT_TIME:
		engaged = false
		lost_sight = 0.0


## Movement is what a slime can taste. A hunter who stands still is stalked slowly
## enough to keep the pounce readable; a hunter who walks, strafes or circles is
## chased at full speed, so distance can only be kept by sprinting.
func _hunter_moving() -> bool:
	if player == null:
		return false
	var body := player as CharacterBody3D
	if body == null:
		return false
	return Vector2(body.velocity.x, body.velocity.z).length() > 0.8


func _try_snare() -> bool:
	if game != null and game.has_method("try_trigger_hunt_snare"):
		return bool(game.try_trigger_hunt_snare(self))
	return false


func _see_through_to(target_position: Vector3, delta: float) -> bool:
	# Sense should not pass through a bulkhead. The basement's walls are static
	# bodies, so anything else the ray touches (the hunter, other creatures, props
	# on the non-blocking layer) is not allowed to break the sightline.
	sight_check -= delta
	if sight_check > 0.0:
		return sight_clear
	sight_check = SIGHT_INTERVAL
	var space := get_world_3d().direct_space_state
	if space == null:
		sight_clear = true
		return true
	var from := global_position + Vector3(0.0, 0.46, 0.0)
	var to := target_position + Vector3(0.0, 1.25, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_rid()]
	var hit := space.intersect_ray(query)
	sight_clear = hit.is_empty() or not (hit.get("collider") is StaticBody3D)
	return sight_clear


func _should_leap(distance: float) -> bool:
	if player == null or bool(player.get("downed")):
		return false
	if leap_cooldown > 0.0 or attack_cooldown > 0.0:
		return false
	if distance < LEAP_MIN_RANGE or distance > LEAP_MAX_RANGE:
		return false
	# The telegraph has to be aimed. A body that coils while still facing its old
	# heading reads as a sideways hop that snaps to the hunter at launch, and a
	# pounce aimed off-axis is how the old build ended up "attacking backward".
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() <= 0.01:
		return true
	return absf(angle_difference(facing, atan2(to_player.x, to_player.z))) <= 0.35


func _begin_crouch() -> void:
	state = STATE_CROUCH
	state_time = 0.0
	reflex_armed = false
	velocity = Vector3.ZERO
	animation_lock = LEAP_WINDUP + 0.02
	# The generated crouch clip holds its deepest coil on the final frame, so it
	# reads as a spring loading rather than as a squash held in code.
	_play_clip("crouch", true)
	if game != null and game.has_method("creature_leap_telegraph"):
		game.creature_leap_telegraph(self)


func _launch_leap() -> void:
	if player == null:
		return
	state = STATE_LEAP
	state_time = 0.0
	leap_hit_done = false
	# Pounces are the punctuating threat, not the default gait: the recovery plus
	# this cooldown gives the player a window to close the distance or flee.
	leap_cooldown = 2.6
	var to_player: Vector3 = player.global_position - global_position
	to_player.y = 0.0
	var direction: Vector3 = to_player.normalized() if to_player.length() > 0.01 else Vector3.FORWARD
	# The pounce is aimed at where the hunter stood when it left the floor. It
	# does not steer in mid-air, so stepping aside beats it. Horizontal speed is
	# solved from the jump's airtime so short hops and long pounces both land on
	# the spot rather than undershooting the target.
	const LEAP_LIFT := 4.35
	const LEAP_GRAVITY := 18.0
	var airtime: float = 2.0 * LEAP_LIFT / LEAP_GRAVITY
	var travel: float = clampf((to_player.length() + 0.12) / airtime, 1.4, 9.0)
	velocity = Vector3(direction.x * travel, LEAP_LIFT, direction.z * travel)
	facing = atan2(direction.x, direction.z)
	rotation.y = facing
	animation_lock = 0.9
	# A dedicated airborne clip: stretched mantle, trailing skirts, landing tuck.
	_play_clip("leap", true)
	if game != null and game.has_method("creature_leap_started"):
		game.creature_leap_started(self)


func _check_leap_contact() -> void:
	if leap_hit_done or player == null or game == null:
		return
	var offset: Vector3 = player.global_position - global_position
	var flat := Vector2(offset.x, offset.z).length()
	if flat <= BITE_CONTACT and absf(offset.y) <= 1.35:
		leap_hit_done = true
		if game.has_method("player_leap_hit"):
			game.player_leap_hit(self)


func _land_leap() -> void:
	state = STATE_RECOVER
	state_time = 0.0
	# Only a pounce that missed has anything left to prove; one that connected has
	# already taken its payment.
	reflex_armed = not leap_hit_done
	velocity = Vector3.ZERO
	animation_lock = 0.0
	_play_clip("idle")
	if game != null and game.has_method("creature_leap_landed"):
		game.creature_leap_landed(self, leap_hit_done)


func _update_visual() -> void:
	if visual == null:
		return
	# The rig carries the main movement. This restrained scale pulse supplies the
	# soft gel weight without falling back to the old primitive sphere bounce.
	var moving := Vector2(velocity.x, velocity.z).length() > 0.08
	var pulse_rate := 7.8 if moving else 3.8
	var pulse := sin(clock * pulse_rate)
	var recoil: float = clampf(hit_recoil / 0.24, 0.0, 1.0)
	var coil: float = crouch_amount
	# The landing guard reads as weight held low over the floor, so the silhouette
	# itself says "not yet" before the ring does.
	var guard: float = 1.0 if _reflex_threat() else 0.0
	var horizontal := 1.0 + pulse * (0.018 if moving else 0.010) + recoil * 0.10 + coil * 0.20 + guard * 0.07
	var vertical := 1.0 - pulse * (0.024 if moving else 0.012) - recoil * 0.13 - coil * 0.26 - guard * 0.12
	visual.scale = Vector3(horizontal, vertical, horizontal) * body_scale
	visual.position = Vector3(0.0, -0.028 * recoil - 0.045 * coil, 0.0)
	visual.rotation.z = -0.14 * recoil
	# The coil leans back before it springs, then the body stretches out in flight.
	visual.rotation.x = -0.18 * coil + (0.22 if state == STATE_LEAP else 0.0)
	visual.position.z = 0.06 * coil - (0.10 if state == STATE_LEAP else 0.0)
	_update_tell_ring()


func _update_tell_ring() -> void:
	if tell_ring == null or tell_material == null:
		return
	var winding := state == STATE_CROUCH
	var guarded := _reflex_threat()
	tell_ring.visible = winding or guarded
	if winding:
		# A coil closes in on the body: this is the pounce, leave now.
		var charge: float = clampf(state_time / LEAP_WINDUP, 0.0, 1.0)
		var close_in: float = lerpf(1.35, 0.62, charge * charge)
		tell_ring.scale = Vector3(close_in, 0.05, close_in)
		tell_material.albedo_color = Color(0.78, 0.16, 0.10, 0.10 + 0.55 * charge)
	elif guarded:
		# The landing guard pushes the same ring outwards as a pale, pulsing line:
		# the opposite motion of the coil, so the two warnings cannot be confused.
		var tail: float = clampf(state_time / maxf(recover_armed, 0.01), 0.0, 1.0)
		var spread: float = lerpf(1.05, 1.55, tail)
		tell_ring.scale = Vector3(spread, 0.05, spread)
		tell_material.albedo_color = Color(0.92, 0.84, 0.66, 0.30 + 0.18 * (0.5 + 0.5 * sin(clock * 24.0)))


## True while the landing guard can actually answer a blade: the body is in the
## armed tail of a missed pounce and the hunter is close enough to be bitten.
func _reflex_threat() -> bool:
	if not reflex_armed or state != STATE_RECOVER or state_time > recover_armed:
		return false
	if player == null:
		return false
	var offset: Vector3 = player.global_position - global_position
	return Vector2(offset.x, offset.z).length() <= REFLEX_REACH


## Sweep the blade aside and bite the arm that swung it. The guard is spent, so
## the rest of the landing pause is still a real opening.
func _fire_reflex() -> void:
	reflex_armed = false
	animation_lock = 0.42
	hit_recoil = 0.10
	_play_clip("strike", true)
	if game != null and game.has_method("creature_reflex_bite"):
		game.creature_reflex_bite(self)


func take_hit(damage: int, method: String, impact_direction: Vector3 = Vector3.ZERO, impact_strength: float = 0.0) -> void:
	if dead:
		return
	if _reflex_threat():
		_fire_reflex()
		return
	health -= damage
	provoked = true
	if knockback_on_hit > 0.0 and game != null and game.has_method("variant_knockback_player"):
		# The cinder variant's weight answers the blade: the hunter is thrown back
		# 1.2 m, so melee means closing again after every landing hit.
		game.call("variant_knockback_player", self, knockback_on_hit)
	# A blade landing during the crouch cancels the pounce: the telegraph is a
	# real commitment the player can beat, not animation window dressing.
	if state == STATE_CROUCH:
		state = STATE_CRAWL
		state_time = 0.0
	stagger = 0.38
	animation_lock = 0.38
	hit_recoil = 0.24
	if impact_direction.length_squared() > 0.001 and impact_strength > 0.0:
		hit_direction = impact_direction.normalized()
		knockback_velocity = Vector3(hit_direction.x * impact_strength, 0.0, hit_direction.z * impact_strength)
	if health <= 0:
		dead = true
		death_left = 0.72
		if tell_ring != null:
			tell_ring.visible = false
		velocity = Vector3.ZERO
		collision_shape.set_deferred("disabled", true)
		_play_clip("death", true)
		if game != null:
			game.on_burrower_killed(self, method, global_position)
		return
	_play_clip("hurt", true)


## The hunter going down ends the fight, not the creature. It stays alive exactly
## where it is standing (so a death cannot delete or duplicate it), but the hunt it
## was running dies with the body it killed: no target, no grudge, no leftover leap
## or tether state. When the hunter comes back it has to be sensed all over again.
func reset_after_player_death() -> void:
	engaged = false
	provoked = false
	lost_sight = 0.0
	state = STATE_CRAWL
	state_time = 0.0
	reflex_armed = false
	leap_hit_done = false
	leap_cooldown = 0.0
	attack_cooldown = 0.0
	stagger = 0.0
	tether_left = 0.0
	knockback_velocity = Vector3.ZERO
	hit_recoil = 0.0
	animation_lock = 0.0
	velocity = Vector3.ZERO
	if animation_player != null:
		animation_player.speed_scale = 1.0
	_play_clip("idle")


func apply_tether(seconds: float) -> void:
	if dead:
		return
	tether_left = maxf(tether_left, seconds)
	stagger = 0.0
	attack_cooldown = maxf(attack_cooldown, 0.65)
	animation_lock = 0.24
	velocity = Vector3.ZERO
	knockback_velocity = Vector3.ZERO
	_play_clip("hurt", true)


func apply_stagger(seconds: float) -> void:
	stagger = maxf(stagger, seconds)
	animation_lock = maxf(animation_lock, minf(seconds, 0.36))
	hit_recoil = maxf(hit_recoil, minf(seconds, 0.24))
	_play_clip("hurt", true)
