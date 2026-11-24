extends Node3D

const BASE_ACCEL := 2.1
const BASE_SPEED := 6.0
const BASE_BRAKE := 5.2
var speed := 0.0
var distance := 0.0
var headlight_on := false
var accelerating := false
var lamp: SpotLight3D
var curve: Curve3D

func _ready() -> void:
	add_child(load("res://assets/models/basement/generated/rail/mining_cart.glb").instantiate())
	lamp = SpotLight3D.new()
	lamp.position = Vector3(0, 1.0, -1.12)
	lamp.light_color = Color(0.93, 0.85, 0.63)
	lamp.light_energy = 6.0
	lamp.spot_range = 26.0
	lamp.spot_angle = 34.0
	lamp.shadow_enabled = true
	lamp.visible = false
	add_child(lamp)

func performance(upgraded: bool) -> Dictionary:
	return {"accel": BASE_ACCEL * (1.25 if upgraded else 1.0),
		"max_speed": BASE_SPEED * (1.10 if upgraded else 1.0),
		"brake": BASE_BRAKE * (1.15 if upgraded else 1.0),
		"drag": 0.09 if upgraded else 0.14, "noise": 1.20 if upgraded else 1.0}

func step(delta: float, throttle: bool, brake: bool, upgraded: bool, flooded: bool) -> float:
	var p := performance(upgraded)
	accelerating = throttle and not brake
	if brake: speed = move_toward(speed, 0.0, float(p.brake) * delta)
	elif throttle: speed = minf(float(p.max_speed), speed + float(p.accel) * (0.42 if flooded else 1.0) * delta)
	else: speed = move_toward(speed, 0.0, float(p.drag) * delta)
	if speed < 0.025: speed = 0.0
	var travel := speed * delta
	distance = fposmod(distance + travel, curve.get_baked_length())
	place()
	return travel

func place() -> void:
	if curve == null: return
	position = curve.sample_baked(distance)
	var ahead := curve.sample_baked(fposmod(distance + 0.2, curve.get_baked_length()))
	if position.distance_squared_to(ahead) > 0.001: look_at(ahead)

func toggle_headlight() -> void:
	headlight_on = not headlight_on
	lamp.visible = headlight_on
