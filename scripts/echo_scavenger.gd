class_name EchoScavenger
extends CharacterBody3D

# Small blind animals that nest around the Resonant's old service tunnels.
# They react to nearby movement, but are a local obstacle—not a second boss.

var player: SignalRunner
var game: Node
var active := false
var stunned_timer := 0.0
var alert_timer := 0.0
var bite_cooldown := 0.0
var patrol_index := 0
var animation_clock := 0.0
var patrol_points: Array[Vector3] = []
var alert_position := Vector3.ZERO
var collision_shape: CollisionShape3D
var body: Node3D
var head: Node3D
var legs: Array[Node3D] = []
var shell_material: StandardMaterial3D
var pulse_material: StandardMaterial3D
var health := 2
var dead := false
var knockback := Vector3.ZERO
var damage_flash := 0.0

func _ready() -> void:
	name = "EchoScavenger"
	collision_shape = CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.23
	shape.height = 0.52
	collision_shape.shape = shape
	collision_shape.position.y = 0.26
	add_child(collision_shape)
	_build_visual()
	set_active(false)

func configure(points: Array[Vector3]) -> void:
	patrol_points = points
	if not patrol_points.is_empty():
		global_position = patrol_points[0]

func set_active(value: bool) -> void:
	active = value
	visible = value
	if collision_shape != null:
		collision_shape.set_deferred("disabled", not value)

func can_receive_pulse(origin: Vector3, forward: Vector3) -> bool:
	if not active or stunned_timer > 0.0:
		return false
	var offset := global_position - origin
	var distance := offset.length()
	if distance > 4.6 or distance < 0.05:
		return false
	return forward.dot(offset.normalized()) > 0.12

func stun(duration: float = 7.5) -> void:
	stunned_timer = maxf(0.5, duration)
	velocity = Vector3.ZERO
	if shell_material != null:
		shell_material.emission_enabled = true
		shell_material.emission = Color(0.08, 0.82, 0.72)
		shell_material.emission_energy_multiplier = 2.1

func take_rivet_hit(damage: int, from_position: Vector3) -> void:
	if dead:
		return
	health -= damage
	damage_flash = 0.24
	stunned_timer = maxf(stunned_timer, 0.4)
	knockback = (global_position - from_position).normalized() * 3.6
	if shell_material != null:
		shell_material.emission_enabled = true
		shell_material.emission = Color(0.92, 0.10, 0.05)
		shell_material.emission_energy_multiplier = 3.4
	if health <= 0:
		_die()

func _die() -> void:
	dead = true
	active = false
	alert_timer = 0.0
	velocity = Vector3.ZERO
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if game != null:
		game.scavenger_killed(global_position)
	if body != null:
		var tween := create_tween()
		tween.tween_property(body, "rotation:z", PI * 0.5, 0.32).set_trans(Tween.TRANS_QUAD)
		tween.parallel().tween_property(body, "position:y", 0.09, 0.32)
		tween.tween_interval(1.2)
		tween.tween_callback(queue_free)

func scurry_away() -> void:
	alert_timer = 0.0
	bite_cooldown = 2.6
	if not patrol_points.is_empty():
		patrol_index = (patrol_index + 1) % patrol_points.size()

func _physics_process(delta: float) -> void:
	if not active:
		return
	animation_clock += delta
	bite_cooldown = maxf(0.0, bite_cooldown - delta)
	if damage_flash > 0.0:
		damage_flash -= delta
		if damage_flash <= 0.0 and stunned_timer <= 0.0 and shell_material != null:
			shell_material.emission_enabled = false
	if knockback.length() > 0.06:
		velocity = knockback
		knockback = knockback.move_toward(Vector3.ZERO, delta * 14.0)
		move_and_slide()
		_animate(1.0, false)
		return
	if stunned_timer > 0.0:
		stunned_timer = maxf(0.0, stunned_timer - delta)
		velocity = Vector3.ZERO
		if stunned_timer <= 0.0 and shell_material != null:
			shell_material.emission_enabled = false
		_animate(0.0, true)
		return

	var destination := global_position
	var move_speed := 1.25
	if player != null:
		var player_distance := global_position.distance_to(player.global_position)
		if player.is_hidden:
			alert_timer = 0.0
		else:
			var player_speed := Vector2(player.velocity.x, player.velocity.z).length()
			if player_distance < 5.0 and player_speed > 0.32:
				alert_position = player.global_position
				alert_timer = 2.4
		if alert_timer > 0.0:
			alert_timer -= delta
			destination = alert_position
			move_speed = 3.05
		elif not patrol_points.is_empty():
			destination = patrol_points[patrol_index]
			if global_position.distance_to(destination) < 0.38:
				patrol_index = (patrol_index + 1) % patrol_points.size()
				destination = patrol_points[patrol_index]
		if not player.is_hidden and player_distance < 0.78 and bite_cooldown <= 0.0 and game != null:
			bite_cooldown = 3.0
			game.scavenger_hit(self)

	var flat_destination := Vector3(destination.x, global_position.y, destination.z)
	var direction := global_position.direction_to(flat_destination)
	var moving := Vector2(direction.x, direction.z).length() > 0.05 and global_position.distance_to(destination) > 0.34
	if moving:
		velocity = Vector3(direction.x * move_speed, -0.1, direction.z * move_speed)
		look_at(flat_destination, Vector3.UP, true)
		move_and_slide()
	else:
		velocity = Vector3.ZERO
	_animate(move_speed if moving else 0.0, false)

func _build_visual() -> void:
	shell_material = _material(Color(0.055, 0.075, 0.09), 0.38, 0.32)
	pulse_material = _material(Color(0.18, 0.74, 0.63), 0.26, 0.18)
	pulse_material.emission_enabled = true
	pulse_material.emission = Color(0.02, 0.28, 0.20)
	pulse_material.emission_energy_multiplier = 1.6
	var scar_material := _material(Color(0.19, 0.075, 0.08), 0.62, 0.04)
	body = Node3D.new()
	body.position.y = 0.25
	add_child(body)
	_add_part(body, SphereMesh.new(), Vector3(0.46, 0.25, 0.60), Vector3(0, 0, 0.04), shell_material)
	head = Node3D.new()
	head.position = Vector3(0, 0.01, -0.34)
	body.add_child(head)
	_add_part(head, SphereMesh.new(), Vector3(0.29, 0.20, 0.25), Vector3.ZERO, shell_material)
	_add_part(head, SphereMesh.new(), Vector3(0.095, 0.06, 0.085), Vector3(0, 0.01, -0.20), pulse_material)
	for index in range(3):
		_add_part(body, SphereMesh.new(), Vector3(0.28 - index * 0.045, 0.10, 0.11), Vector3(0, 0.19, 0.19 - index * 0.15), scar_material)
	for side in [-1.0, 1.0]:
		for row in range(3):
			var leg := Node3D.new()
			leg.position = Vector3(side * 0.25, -0.03, -0.16 + row * 0.17)
			body.add_child(leg)
			leg.rotation.z = side * 0.72
			_add_part(leg, CylinderMesh.new(), Vector3(0.045, 0.19, 0.045), Vector3(0, -0.12, 0), shell_material)
			legs.append(leg)

func _animate(move_speed: float, stunned: bool) -> void:
	if body == null:
		return
	if stunned:
		body.rotation.z = sin(animation_clock * 18.0) * 0.18
		body.position.y = 0.19
		return
	body.rotation.z = 0.0
	var intensity := 0.0 if move_speed <= 0.0 else 1.0
	body.position.y = 0.25 + absf(sin(animation_clock * (4.0 + move_speed))) * 0.035 * intensity
	if head != null:
		head.rotation.y = sin(animation_clock * 2.1) * (0.10 if intensity <= 0.0 else 0.025)
	for index in legs.size():
		var phase := -1.0 if index % 2 == 0 else 1.0
		legs[index].rotation.x = sin(animation_clock * (6.0 + move_speed * 2.0) + index * 0.45) * 0.48 * intensity * phase

func _add_part(parent: Node3D, mesh: PrimitiveMesh, part_scale: Vector3, offset: Vector3, material: Material) -> void:
	var part := MeshInstance3D.new()
	part.mesh = mesh
	part.scale = part_scale
	part.position = offset
	part.material_override = material
	parent.add_child(part)

func _material(color: Color, roughness_value: float, metallic_value: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness_value
	material.metallic = metallic_value
	return material
