extends Node3D

## Windowed, code-driven visual QA for the generated slime asset.
## Run with:
##   Godot --path . res://tools/basement_slime_asset_shots.tscn

const SLIME_SCENE: PackedScene = preload("res://assets/models/basement/generated/creatures/slime/basement_slime.glb")
const OUT := "res://tools/shots/basement_assets/"

var slime: Node3D
var animation: AnimationPlayer


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_build_stage()
	slime = SLIME_SCENE.instantiate() as Node3D
	slime.position = Vector3(0.0, 0.0, 0.0)
	add_child(slime)
	animation = _find_animation(slime)
	await _frames(6)
	_capture("01_slime_idle", "idle")
	await _frames(14)
	_capture("02_slime_crawl", "crawl")
	await _frames(14)
	_capture("03_slime_lure", "lure")
	await _frames(6)
	_capture("04_slime_strike", "strike")
	await _frames(8)
	_capture("05_slime_hurt", "hurt")
	await _frames(8)
	_capture("06_slime_death", "death")
	print("BASEMENT SLIME SCREENSHOTS: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()


func _build_stage() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("091009")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("243023")
	environment.ambient_light_energy = 0.55
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(5.0, 5.0)
	floor.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("283026")
	floor_material.roughness = 0.92
	floor.material_override = floor_material
	add_child(floor)

	var key := OmniLight3D.new()
	key.position = Vector3(-1.0, 1.85, 1.30)
	key.light_color = Color("E2B982")
	key.light_energy = 3.3
	key.omni_range = 6.0
	add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(1.45, 0.95, -1.35)
	rim.light_color = Color("6FBE75")
	rim.light_energy = 2.0
	rim.omni_range = 4.0
	add_child(rim)

	var camera := Camera3D.new()
	camera.fov = 48.0
	camera.position = Vector3(1.12, 0.72, -1.52)
	add_child(camera)
	camera.look_at(Vector3(0.0, 0.28, -0.08), Vector3.UP)


func _capture(name: String, clip: String) -> void:
	if animation != null and animation.has_animation(clip):
		animation.play(clip)
		if clip == "strike":
			animation.seek(0.18, true)
		elif clip == "hurt":
			animation.seek(0.16, true)
		elif clip == "death":
			animation.seek(0.84, true)
		else:
			animation.seek(0.35, true)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := OUT + name + ".png"
	var result := image.save_png(ProjectSettings.globalize_path(path))
	print("  %s (%s)" % [path, "ok" if result == OK else "error %d" % result])


func _frames(count: int) -> void:
	for _frame in count:
		await get_tree().process_frame


func _find_animation(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node as AnimationPlayer
	for child in node.get_children():
		var found := _find_animation(child)
		if found != null:
			return found
	return null
