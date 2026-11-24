extends Node

## Headless import and animation test for the Basement-owned generated slime.
## Run with:
##   Godot --headless --path . res://tools/test_basement_slime_asset.tscn

const SLIME_SCENE: PackedScene = preload("res://assets/models/basement/generated/creatures/slime/basement_slime.glb")
const EXPECTED_CLIPS := ["idle", "crawl", "lure", "strike", "crouch", "leap", "hurt", "death"]
const CRAWL_BONES := ["front", "back", "core", "tail", "skirt_L", "skirt_R"]

var checks := 0
var failures := 0


func _ready() -> void:
	_run.call_deferred()


func _check(condition: bool, label: String, detail: String = "") -> void:
	checks += 1
	if condition:
		print("  PASS  ", label)
	else:
		failures += 1
		print("  FAIL  ", label, "  ", detail)


func _run() -> void:
	var slime: Node3D = SLIME_SCENE.instantiate() as Node3D
	_check(slime != null, "generated slime GLB instantiates")
	if slime == null:
		_finish()
		return
	add_child(slime)
	var skeleton := _find_skeleton(slime)
	var animation := _find_animation(slime)
	var meshes := _find_meshes(slime)
	_check(not meshes.is_empty(), "generated slime contains mesh geometry")
	_check(skeleton != null, "generated slime imports a Skeleton3D")
	_check(skeleton != null and skeleton.get_bone_count() == 7,
		"generated slime imports all seven authored bones",
		"found %d" % (skeleton.get_bone_count() if skeleton != null else 0))
	_check(animation != null, "generated slime imports an AnimationPlayer")
	if animation != null:
		for clip in EXPECTED_CLIPS:
			_check(animation.has_animation(clip), "GLB contains '%s' clip" % clip)
		if animation.has_animation("crawl"):
			for bone in CRAWL_BONES:
				_check(_track_moves_bone(animation.get_animation("crawl"), bone),
					"crawl clip animates '%s'" % bone)
			animation.play("crawl")
			await get_tree().process_frame
			_check(animation.current_animation == "crawl", "Godot plays the generated crawl clip")
		if animation.has_animation("crouch"):
			# The pounce telegraph has to be a real pose in the clip, not just a
			# node scale in gameplay code.
			_check(_track_moves_bone(animation.get_animation("crouch"), "front")
				and _track_moves_bone(animation.get_animation("crouch"), "skirt_L"),
				"crouch clip coils the mantle and tucks the skirts")
		if animation.has_animation("leap"):
			_check(_track_moves_bone(animation.get_animation("leap"), "tail")
				and _track_moves_bone(animation.get_animation("leap"), "skirt_R"),
				"leap clip stretches the body and trails the skirts")
	slime.queue_free()
	_finish()


func _finish() -> void:
	print("BASEMENT SLIME ASSET RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


func _find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation(child)
		if found != null:
			return found
	return null


func _find_meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node as MeshInstance3D)
	for child in node.get_children():
		result.append_array(_find_meshes(child))
	return result


func _track_moves_bone(animation: Animation, bone: String) -> bool:
	for track in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_ROTATION_3D:
			continue
		var path := animation.track_get_path(track)
		var names := String(path.get_concatenated_subnames())
		if not names.ends_with(bone):
			continue
		if animation.track_get_key_count(track) < 2:
			return false
		var first: Quaternion = animation.track_get_key_value(track, 0)
		for key in animation.track_get_key_count(track):
			var value: Quaternion = animation.track_get_key_value(track, key)
			if absf(first.dot(value)) < 0.99995:
				return true
	return false
