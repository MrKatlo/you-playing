extends Node3D

## A blind rail ambusher. Headlamp state is intentionally absent from sensing.
var animation: AnimationPlayer
var lunging := false
var rest_position := Vector3.ZERO

func _ready() -> void:
	var model: Node3D = load("res://assets/models/basement/generated/rail/echo_hunter.glb").instantiate()
	add_child(model)
	animation = find_animation(model)
	if animation != null: animation.play("listen")

static func hears_motor(distance_value: float, accelerating: bool, upgraded: bool) -> bool:
	return accelerating and distance_value < 8.0 * (1.20 if upgraded else 1.0)

func ambush(target: Vector3) -> void:
	if lunging: return
	lunging = true
	rest_position = position
	if animation != null: animation.play("ambush")
	var tween := create_tween()
	tween.tween_property(self, "position", target, .28).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(.16)
	tween.tween_property(self, "position", rest_position, .42)
	tween.tween_callback(func():
		lunging = false
		if animation != null: animation.play("listen"))

static func find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer: return node
	for child in node.get_children():
		var found := find_animation(child)
		if found != null: return found
	return null
