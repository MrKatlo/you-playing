class_name TunnelRat
extends Node3D

var player: SignalRunner
var body: Node3D
var traded := false
var wander_phase := 0.0

func _ready() -> void:
	name = "Nix"
	body = Node3D.new()
	body.position.y = 0.28
	add_child(body)
	_add_part(SphereMesh.new(), Vector3(0.42, 0.23, 0.58), Vector3.ZERO, Color(0.07, 0.08, 0.11))
	_add_part(SphereMesh.new(), Vector3(0.28, 0.24, 0.26), Vector3(0, 0.03, -0.34), Color(0.10, 0.11, 0.15))
	for x in [-0.09, 0.09]:
		_add_part(SphereMesh.new(), Vector3(0.05, 0.05, 0.05), Vector3(x, 0.08, -0.47), Color(0.15, 0.95, 0.78), true)

func _process(delta: float) -> void:
	wander_phase += delta
	body.position.y = 0.28 + sin(wander_phase * 3.2) * 0.025
	if player != null and global_position.distance_to(player.global_position) < 4.0:
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP, true)
	else:
		rotation.y += delta * 0.18

func trade() -> bool:
	if traded:
		return false
	traded = true
	return true

func _add_part(mesh: PrimitiveMesh, part_scale: Vector3, offset: Vector3, color: Color, emit := false) -> void:
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.scale = part_scale
	piece.position = offset
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.7
	if emit:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = 2.4
	piece.material_override = material
	body.add_child(piece)
