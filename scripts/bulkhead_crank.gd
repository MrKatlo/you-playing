class_name BulkheadCrank
extends StaticBody3D

## A geared hand crank for the inner bulkhead.
##
## The bulkhead cannot be thrown: it is raised by turning this wheel, and turning
## it takes both hands and time. Pressing E does nothing on its own; the owner
## feeds `begin_hold()` / `end_hold()` from the held interact input and the wheel
## winds up while the key is down. Letting go early springs the wheel back and
## leaves the gate exactly where it started, so a crank is never half a door.
##
## The wheel is the interaction point: bolted plate, stencilled tag, gear housing,
## a spoked hand wheel with a knob. Local space follows MechanicalLever: the plate
## lies in the XY plane and the mechanism reaches toward -Z, so the owner rotates
## the node to face the room it is mounted in.

signal turned(down: bool)
signal ratchet

const PLATE_THICKNESS := 0.045
const LIP_FRONT := -0.040
const LIP_THICKNESS := 0.020
const DECAL_Z := -0.0425
const DECAL_THICKNESS := 0.006
const SEAT_Z := -0.0455
const BOLT_Z := -0.055
const BOLT_THICKNESS := 0.008
const NAMEPLATE_Z := -0.0465
const NAMEPLATE_THICKNESS := 0.014
const LAMP_Z := -0.0435
const TEXT_Z := -0.058

## Two full turns of the wheel raise or seat the gate. Long enough to feel like
## work with something banging on the far side, short enough to retry.
const HOLD_SECONDS := 1.35
## Spring-back when the player lets go early: visible, not sluggish.
const SPRING_SECONDS := 0.25
## The gate itself travels for ~0.72 s after the crank completes; the wheel is
## locked for that long so the door can never be asked to go two ways at once.
const LOCK_SECONDS := 0.78
const WHEEL_TURNS := 2.0

const CREAK_SFX := preload("res://assets/audio/furnace_door_creak.ogg")
const CLUNK_SFX := preload("res://assets/audio/metal_hit.ogg")

var tag_color := Color(0.80, 0.56, 0.16)
var plate_text := "INNER BULKHEAD — CRANK"
## The gate's real state: true while the bulkhead is raised.
var engaged := false
## 0.0 at rest, 1.0 when the wheel has been fully wound.
var progress := 0.0
## Counts of emitted sounds, so a test can prove the mechanism is audible without
## a sound card.
var sound_plays := 0
var last_sound := ""

var _wheel: Node3D
var _tag_material: StandardMaterial3D
var _tick_player: AudioStreamPlayer3D
var _clunk_player: AudioStreamPlayer3D
var _holding := false
var _lock_left := 0.0
var _next_tick := 0.25
var _built := false


func configure(color: Color, text: String) -> void:
	tag_color = color
	plate_text = text


func _ready() -> void:
	if _built:
		return
	_built = true
	# The owner names it (BulkheadCrank); do not rename it here.
	collision_layer = 0
	collision_mask = 0
	_build_body()
	_build_sounds()
	set_engaged(engaged, true)


# ------------------------------------------------------------------ building

func _build_body() -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.36, 0.70, 0.38)
	collision.shape = shape
	collision.position = Vector3(0.0, 0.0, -0.13)
	add_child(collision)
	var base := preload("res://assets/models/basement/generated/props/bulkhead_crank.glb").instantiate()
	base.name = "GeneratedCrankHousing"
	add_child(base)
	_wheel = Node3D.new()
	_wheel.name = "CrankWheel"
	_wheel.position = Vector3(0.0, -0.02, -0.225)
	add_child(_wheel)
	var wheel := preload("res://assets/models/basement/generated/props/bulkhead_crank_wheel.glb").instantiate()
	wheel.name = "GeneratedCastWheel"
	_wheel.add_child(wheel)
	_tag_material = _steel(tag_color * 0.55, 0.35, 0.9)
	_tag_material.emission_enabled = true
	_tag_material.emission = tag_color
	_tag_material.emission_energy_multiplier = 0.22
	_add_mesh(self, Vector3(0.05, 0.05, 0.008), Vector3(0.0, 0.29, -0.03), _tag_material)
	var label := Label3D.new()
	label.text = plate_text
	label.font_size = 32
	label.pixel_size = 0.001
	label.modulate = Color(0.90, 0.86, 0.74)
	label.outline_size = 5
	label.position = Vector3(0.0, -0.20, -0.054)
	label.rotation.y = PI
	label.double_sided = false
	label.name = "PlateText"
	add_child(label)


func _build_sounds() -> void:
	_tick_player = AudioStreamPlayer3D.new()
	_tick_player.name = "CrankRatchet"
	_tick_player.stream = CLUNK_SFX
	_tick_player.unit_size = 2.0
	_tick_player.max_distance = 7.0
	_tick_player.volume_db = -17.0
	add_child(_tick_player)
	_clunk_player = AudioStreamPlayer3D.new()
	_clunk_player.name = "CrankStop"
	_clunk_player.stream = CLUNK_SFX
	_clunk_player.unit_size = 2.5
	_clunk_player.max_distance = 9.0
	_clunk_player.volume_db = -9.0
	add_child(_clunk_player)


func _add_mesh(parent: Node3D, size: Vector3, position_value: Vector3, material: Material,
		primitive: PrimitiveMesh = null, rotation_value: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	if size != Vector3.ZERO:
		var box := BoxMesh.new()
		box.size = size
		piece.mesh = box
	else:
		piece.mesh = primitive
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
	return _steel(color, 0.95, 0.35)


func _grease(color: Color) -> StandardMaterial3D:
	return _steel(color, 1.0, 0.0)


func _grip_material() -> StandardMaterial3D:
	return _steel(Color(0.24, 0.15, 0.085), 0.92, 0.0)


# ----------------------------------------------------------------- behaviour

## True while the gate is travelling or the wheel is locked after a turn. The
## owner treats this as "do not operate the mechanism".
func is_moving() -> bool:
	return _lock_left > 0.0


func is_holding() -> bool:
	return _holding


func is_engaged() -> bool:
	return engaged


func wheel_angle() -> float:
	return _wheel.rotation.z if _wheel != null else 0.0


## Start winding. Refused while the gate is travelling or the wheel is already
## held, which is what keeps input spam from stacking two turns.
func begin_hold() -> bool:
	if _holding or _lock_left > 0.0:
		return false
	_holding = true
	return true


func end_hold() -> void:
	_holding = false


func hold_seconds_left() -> float:
	return maxf(0.0, HOLD_SECONDS * (1.0 - progress))


func _process(delta: float) -> void:
	if _lock_left > 0.0:
		_lock_left = maxf(0.0, _lock_left - delta)
	if _holding:
		progress = minf(1.0, progress + delta / HOLD_SECONDS)
		_tick_ratchet()
		if progress >= 1.0:
			_complete_turn()
		_apply_wheel()
		return
	if progress > 0.0:
		progress = maxf(0.0, progress - delta / SPRING_SECONDS)
		_apply_wheel()
		if is_zero_approx(progress):
			_next_tick = 0.25


func _apply_wheel() -> void:
	if _wheel == null:
		return
	# Small periodic resistance at each ratchet tooth, with the same hold time.
	var resisted := progress - 0.009 * sin(progress * TAU * 8.0)
	_wheel.rotation.z = -resisted * TAU * WHEEL_TURNS


## A ratchet click each quarter turn, so the hold is audible and the player can
## tell the wheel is actually winding rather than frozen.
func _tick_ratchet() -> void:
	if progress < _next_tick:
		return
	_next_tick += 0.25
	if _tick_player == null:
		return
	_tick_player.pitch_scale = 1.42
	_tick_player.play()
	sound_plays += 1
	last_sound = "ratchet"
	ratchet.emit()


func _complete_turn() -> void:
	_holding = false
	progress = 0.0
	_next_tick = 0.25
	_lock_left = LOCK_SECONDS
	if _wheel != null:
		_wheel.rotation.z = 0.0
	engaged = not engaged
	if _clunk_player != null:
		_clunk_player.pitch_scale = 0.82 if engaged else 1.1
		_clunk_player.play()
		sound_plays += 1
		last_sound = "stop_down" if engaged else "stop_up"
	_refresh_lamp()
	turned.emit(engaged)


## Shows the gate's real state. `instant` is used at boot, on a new shift and
## after a load: the player never turned it, so it must not click.
func set_engaged(down: bool, instant: bool = true) -> void:
	engaged = down
	_holding = false
	_lock_left = 0.0
	progress = 0.0
	_next_tick = 0.25
	if _wheel != null:
		if instant:
			_wheel.rotation.z = 0.0
		else:
			var tween := create_tween()
			tween.tween_property(_wheel, "rotation:z", 0.0, 0.12)
	_refresh_lamp()


func _refresh_lamp() -> void:
	if _tag_material == null:
		return
	_tag_material.emission_energy_multiplier = 0.85 if engaged else 0.22
	_tag_material.emission = tag_color
