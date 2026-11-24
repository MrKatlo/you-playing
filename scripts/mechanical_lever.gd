class_name MechanicalLever
extends StaticBody3D

## A worn, wall-mounted mechanical lever.
##
## The lever is the interaction point itself: the player sees a bolted steel
## plate, a boss, a throw arm with a wooden grip, and a stencilled tag, and pulls
## that. It owns no game rules. The owner calls `set_engaged()` whenever the real
## mechanism changes state, so the arm can never drift out of sync with the door
## or the trap it operates.
##
## Local space: the plate lies in the XY plane and the mechanism reaches toward
## -Z. Rotate the node to face the room it is mounted in, and place the origin so
## the backing plate's rear face sits against the wall surface.

signal throw_started(down: bool)
signal throw_finished(down: bool)

# Depth layout in local space; negative Z is toward the room. Every piece sits a
# few millimetres clear of the one behind it. Coincident faces z-fight, which made
# the streaks, nameplate and stencil shimmer across the plate as the camera moved.
const PLATE_THICKNESS := 0.045
const LIP_THICKNESS := 0.020
const LIP_FRONT := -0.040
const DECAL_Z := -0.0425
const DECAL_THICKNESS := 0.006
const SEAT_Z := -0.0455
const SEAT_THICKNESS := 0.012
const BOLT_Z := -0.055
const BOLT_THICKNESS := 0.008
const NAMEPLATE_Z := -0.0465
const NAMEPLATE_THICKNESS := 0.014
const LAMP_Z := -0.0435
const LAMP_THICKNESS := 0.008
const TEXT_Z := -0.058
const ARM_PIVOT_Z := -0.215

const UP_ANGLE := 0.18
const DOWN_ANGLE := -2.10
const TRAVEL_TIME := 0.18
const SETTLE_TIME := 0.07
const CREAK_SFX := preload("res://assets/audio/furnace_door_creak.ogg")
const CLUNK_SFX := preload("res://assets/audio/metal_hit.ogg")

## Counts of emitted sounds, so an automated test can prove the mechanism is
## audible without a sound card.
var sound_plays := 0
var last_sound := ""

var tag_color := Color(0.62, 0.32, 0.10)
var plate_text := ""
var engaged := false

var _arm_pivot: Node3D
var _grip: MeshInstance3D
var _tag: MeshInstance3D
var _tag_material: StandardMaterial3D
var _travel_player: AudioStreamPlayer3D
var _clunk_player: AudioStreamPlayer3D
var _moving := false
var _tween: Tween
var _built := false


func configure(color: Color, text: String) -> void:
	tag_color = color
	plate_text = text


func _ready() -> void:
	if _built:
		return
	_built = true
	# The owner names it (BulkheadLever, ShutterLever, SnareLever); do not rename
	# here or Godot suffixes the duplicates and the scene loses its handles.
	collision_layer = 0
	collision_mask = 0
	_build_body()
	_build_sounds()
	set_engaged(engaged, true)


# ------------------------------------------------------------------ building

func _build_body() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.34, 0.68, 0.24)
	collision.shape = shape
	collision.position = Vector3(0.0, 0.0, -0.06)
	add_child(collision)

	# Backing plate: heavy, painted once, chipped since. Its rear face is the
	# mounting surface, so the owner places the node flush with the wall.
	_add_mesh(self, BoxMesh.new(), Vector3(0.34, 0.68, PLATE_THICKNESS), Vector3.ZERO,
		_steel(Color(0.21, 0.20, 0.18), 0.58, 0.86))
	# Lip around the plate so it reads as forged rather than a flat card. Everything
	# mounted on the face is laid out from LIP_FRONT downwards.
	_add_mesh(self, BoxMesh.new(), Vector3(0.30, 0.64, LIP_THICKNESS), Vector3(0.0, 0.0, LIP_FRONT + LIP_THICKNESS * 0.5),
		_steel(Color(0.26, 0.24, 0.21), 0.5, 0.92))
	# Housing that the throw arm pivots inside.
	_add_mesh(self, BoxMesh.new(), Vector3(0.15, 0.20, 0.13), Vector3(0.0, 0.06, -0.09),
		_steel(Color(0.17, 0.16, 0.15), 0.7, 0.8))
	# Pivot boss, standing proud of the housing so the arm has somewhere to turn.
	var boss := CylinderMesh.new()
	boss.top_radius = 0.052
	boss.bottom_radius = 0.052
	boss.height = 0.07
	_add_mesh(self, boss, Vector3.ZERO, Vector3(0.0, 0.06, -0.175), _rust(Color(0.34, 0.21, 0.12)),
		Vector3(PI * 0.5, 0.0, 0.0))

	# Four bolts seated on the lip, each with a rusty washer underneath.
	for corner in [Vector2(-0.12, 0.27), Vector2(0.12, 0.27), Vector2(-0.12, -0.27), Vector2(0.12, -0.27)]:
		var seat := CylinderMesh.new()
		seat.top_radius = 0.028
		seat.bottom_radius = 0.028
		seat.height = SEAT_THICKNESS
		_add_mesh(self, seat, Vector3.ZERO, Vector3(corner.x, corner.y, SEAT_Z), _rust(Color(0.33, 0.20, 0.11)),
			Vector3(PI * 0.5, 0.0, 0.0))
		var bolt := CylinderMesh.new()
		bolt.top_radius = 0.016
		bolt.bottom_radius = 0.016
		bolt.height = BOLT_THICKNESS
		_add_mesh(self, bolt, Vector3.ZERO, Vector3(corner.x, corner.y, BOLT_Z), _steel(Color(0.29, 0.27, 0.24), 0.85, 0.55),
			Vector3(PI * 0.5, 0.0, 0.0))

	# Rust bleed and a long grease streak: years of hands and a bad seal. They share
	# one depth, so they are kept apart in the plane instead of overlapping.
	_add_mesh(self, BoxMesh.new(), Vector3(0.14, 0.06, DECAL_THICKNESS), Vector3(-0.06, 0.02, DECAL_Z),
		_rust(Color(0.36, 0.19, 0.09)), Vector3(0.0, 0.0, 0.10))
	_add_mesh(self, BoxMesh.new(), Vector3(0.12, 0.035, DECAL_THICKNESS), Vector3(-0.07, 0.20, DECAL_Z),
		_rust(Color(0.31, 0.17, 0.08)), Vector3(0.0, 0.0, -0.06))
	_add_mesh(self, BoxMesh.new(), Vector3(0.03, 0.20, DECAL_THICKNESS), Vector3(0.10, 0.16, DECAL_Z),
		_grease(Color(0.09, 0.08, 0.06)))
	# Riveted nameplate, tinted with the control's colour so the three read apart.
	var tag_plate := BoxMesh.new()
	_add_mesh(self, tag_plate, Vector3(0.28, 0.09, NAMEPLATE_THICKNESS), Vector3(0.0, -0.20, NAMEPLATE_Z),
		_steel(tag_color * 0.42, 0.45, 0.7))
	# State lamp above the plate: dull while clear, lit while engaged.
	_tag_material = _steel(tag_color * 0.55, 0.35, 0.9)
	_tag_material.emission_enabled = true
	_tag_material.emission = tag_color
	_tag_material.emission_energy_multiplier = 0.22
	_tag = _add_mesh(self, BoxMesh.new(), Vector3(0.05, 0.05, LAMP_THICKNESS), Vector3(0.0, -0.10, LAMP_Z), _tag_material)

	if not plate_text.is_empty():
		var label := Label3D.new()
		label.text = plate_text
		# Sized to stay inside the nameplate: 14 characters at 32 px * 1 mm.
		label.font_size = 32
		label.pixel_size = 0.001
		label.modulate = Color(0.90, 0.86, 0.74)
		label.outline_modulate = Color(0.06, 0.05, 0.04, 0.9)
		label.outline_size = 5
		# Stand the glyphs clear of the nameplate so the text does not shimmer
		# against the metal behind it, and keep it one-sided so it cannot read
		# backwards through the plate.
		label.position = Vector3(0.0, -0.20, TEXT_Z)
		label.rotation = Vector3(0.0, PI, 0.0)
		label.double_sided = false
		label.no_depth_test = false
		label.name = "PlateText"
		add_child(label)

	# Throw arm: pivots on the boss's face, clear of the housing, so the handle is
	# visible at rest instead of buried inside the mechanism box.
	_arm_pivot = Node3D.new()
	_arm_pivot.name = "ThrowArm"
	_arm_pivot.position = Vector3(0.0, 0.06, ARM_PIVOT_Z)
	add_child(_arm_pivot)
	_add_mesh(_arm_pivot, BoxMesh.new(), Vector3(0.055, 0.34, 0.05), Vector3(0.0, 0.17, 0.0),
		_steel(Color(0.30, 0.28, 0.25), 0.8, 0.62))
	# Wear collar where the arm passes through the housing.
	var collar := CylinderMesh.new()
	collar.top_radius = 0.045
	collar.bottom_radius = 0.045
	collar.height = 0.035
	_add_mesh(_arm_pivot, collar, Vector3.ZERO, Vector3(0.0, 0.02, 0.0), _rust(Color(0.30, 0.18, 0.10)))
	# Wooden grip, darkened by handling.
	var grip_mesh := CylinderMesh.new()
	grip_mesh.top_radius = 0.046
	grip_mesh.bottom_radius = 0.046
	grip_mesh.height = 0.18
	_grip = _add_mesh(_arm_pivot, grip_mesh, Vector3.ZERO, Vector3(0.0, 0.36, 0.0),
		_grip_material(), Vector3(0.0, 0.0, PI * 0.5))
	var cap := CylinderMesh.new()
	cap.top_radius = 0.050
	cap.bottom_radius = 0.050
	cap.height = 0.02
	_add_mesh(_arm_pivot, cap, Vector3.ZERO, Vector3(-0.09, 0.36, 0.0), _rust(Color(0.26, 0.16, 0.09)),
		Vector3(0.0, 0.0, PI * 0.5))

	_arm_pivot.rotation.x = UP_ANGLE if not engaged else DOWN_ANGLE


func _build_sounds() -> void:
	_travel_player = AudioStreamPlayer3D.new()
	_travel_player.name = "LeverTravel"
	_travel_player.stream = CREAK_SFX
	_travel_player.unit_size = 2.5
	_travel_player.max_distance = 9.0
	_travel_player.volume_db = -12.0
	add_child(_travel_player)
	_clunk_player = AudioStreamPlayer3D.new()
	_clunk_player.name = "LeverStop"
	_clunk_player.stream = CLUNK_SFX
	_clunk_player.unit_size = 2.5
	_clunk_player.max_distance = 9.0
	_clunk_player.volume_db = -9.0
	add_child(_clunk_player)


func _add_mesh(parent: Node3D, mesh: PrimitiveMesh, size: Vector3, position_value: Vector3,
		material: Material, rotation_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	if size != Vector3.ZERO:
		var box := BoxMesh.new()
		box.size = size
		piece.mesh = box
	else:
		piece.mesh = mesh
	piece.material_override = material
	piece.position = position_value
	piece.rotation = rotation_value
	parent.add_child(piece)
	return piece


func _steel(color: Color, roughness: float, metallic: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	material.metallic = metallic
	return material


func _rust(color: Color) -> StandardMaterial3D:
	var material := _steel(color, 0.95, 0.35)
	material.albedo_color = color
	return material


func _grease(color: Color) -> StandardMaterial3D:
	return _steel(color, 1.0, 0.0)


# A fixed chain guide beside the shutter handle. Only the repair link changes.
var _chain_tell: Node3D
var _chain_whole: Node3D
var _chain_root: Node3D
var chain_socket: Marker3D
var _fit_tween: Tween

func set_chain_snapped(snapped: bool) -> void:
	if _chain_root == null:
		_chain_root = Node3D.new()
		_chain_root.name = "ShutterChain"
		_chain_root.position = Vector3(0.23, 0.0, -0.10)
		add_child(_chain_root)
		_chain_tell = preload("res://assets/models/basement/generated/props/shutter_chain_broken.glb").instantiate() as Node3D
		_chain_tell.name = "BrokenChain"
		_chain_root.add_child(_chain_tell)
		_chain_whole = preload("res://assets/models/basement/generated/props/shutter_chain_repaired.glb").instantiate() as Node3D
		_chain_whole.name = "RepairedChain"
		_chain_root.add_child(_chain_whole)
		chain_socket = Marker3D.new()
		chain_socket.name = "LinkSocket"
		_chain_root.add_child(chain_socket)
	_chain_tell.visible = snapped
	_chain_whole.visible = not snapped


func play_chain_fit() -> void:
	set_chain_snapped(false)
	if _fit_tween != null and _fit_tween.is_running():
		_fit_tween.kill()
	_chain_root.rotation.z = 0.06
	_fit_tween = create_tween()
	_fit_tween.tween_property(_chain_root, "rotation:z", 0.0, 0.22).set_trans(Tween.TRANS_BACK)


func _grip_material() -> StandardMaterial3D:
	return _steel(Color(0.24, 0.15, 0.085), 0.92, 0.0)


# ----------------------------------------------------------------- behaviour

func is_moving() -> bool:
	return _moving


func is_engaged() -> bool:
	return engaged


## Current arm rotation in radians. Lets a test prove the handle physically moved
## rather than trusting a boolean.
func arm_angle() -> float:
	return _arm_pivot.rotation.x if _arm_pivot != null else 0.0


func grip_position() -> Vector3:
	if _grip == null:
		return global_position
	return _grip.global_position


## Moves the arm to the given throw. Returns false when the lever refuses:
## already there, or still travelling. The owner must treat a refusal as "do not
## operate the mechanism", which is what stops input spam from double-toggling a
## door while the handle is in motion.
func pull(down: bool) -> bool:
	if _moving or down == engaged:
		return false
	engaged = down
	_moving = true
	throw_started.emit(down)
	_play_travel(down)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	var target: float = DOWN_ANGLE if down else UP_ANGLE
	_tween = create_tween()
	# Mechanical resistance: a long, heavy give, then the arm drops onto its stop.
	_tween.tween_property(_arm_pivot, "rotation:x", target, TRAVEL_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_tween.tween_callback(_on_stop.bind(down))
	_tween.tween_property(_arm_pivot, "rotation:x", target, SETTLE_TIME).set_ease(Tween.EASE_OUT)
	_tween.tween_callback(_on_settled)
	return true


## Shows the mechanism's real state. `instant` is used at boot, on a new shift and
## after a load: the lever was never pulled by the player, so it must not click.
func set_engaged(down: bool, instant: bool = true) -> void:
	engaged = down
	_moving = false
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if _arm_pivot != null:
		var target: float = DOWN_ANGLE if down else UP_ANGLE
		if instant:
			_arm_pivot.rotation.x = target
		else:
			var tween := create_tween()
			tween.tween_property(_arm_pivot, "rotation:x", target, 0.12)
	if _tag_material != null:
		_tag_material.emission_energy_multiplier = 0.85 if down else 0.22
		_tag_material.emission = tag_color


func _play_travel(down: bool) -> void:
	if _travel_player != null:
		_travel_player.pitch_scale = 0.82 if down else 1.06
		_travel_player.play()
		sound_plays += 1
		last_sound = "travel_down" if down else "travel_up"


func _on_stop(down: bool) -> void:
	if _clunk_player != null:
		_clunk_player.pitch_scale = 0.78 if down else 1.12
		_clunk_player.play()
		sound_plays += 1
		last_sound = "stop_down" if down else "stop_up"


func _on_settled() -> void:
	_moving = false
	throw_finished.emit(engaged)
