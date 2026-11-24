extends Node3D

## Windowed visual QA for Basement Farm's generated static props.
## Run with:
##   Godot --path . res://tools/basement_props_asset_shots.tscn

const INSULATION_PATCH_SCENE: PackedScene = preload("res://assets/models/basement/generated/props/wall_insulation_patch.glb")
const WARM_STORAGE_RACK_SCENE: PackedScene = preload("res://assets/models/basement/generated/props/warm_storage_rack.glb")
const FURNACE_HEAT_RECLAIMER_SCENE: PackedScene = preload("res://assets/models/basement/generated/props/furnace_heat_reclaimer.glb")
const OUT := "res://tools/shots/basement_assets/"


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_build_stage()
	var patch: Node3D = INSULATION_PATCH_SCENE.instantiate() as Node3D
	if patch != null:
		patch.name = "InsulationPatchPreview"
		add_child(patch)
	await _frames(8)
	_capture("07_insulation_patch")
	if patch != null:
		patch.visible = false
	var rack: Node3D = WARM_STORAGE_RACK_SCENE.instantiate() as Node3D
	if rack != null:
		rack.name = "WarmStorageRackPreview"
		add_child(rack)
	await _frames(8)
	_capture("08_warm_storage_rack")
	if rack != null:
		rack.visible = false
	var reclaimer: Node3D = FURNACE_HEAT_RECLAIMER_SCENE.instantiate() as Node3D
	if reclaimer != null:
		reclaimer.name = "FurnaceHeatReclaimerPreview"
		add_child(reclaimer)
	await _frames(8)
	_capture("09_furnace_heat_reclaimer")
	print("BASEMENT PROP SCREENSHOTS: ", ProjectSettings.globalize_path(OUT))
	get_tree().quit()


func _build_stage() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("080A0D")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("303845")
	environment.ambient_light_energy = 0.45
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)

	var wall := MeshInstance3D.new()
	var wall_mesh := BoxMesh.new()
	wall_mesh.size = Vector3(3.1, 2.65, 0.12)
	wall.mesh = wall_mesh
	wall.position = Vector3(0.0, 1.325, 0.11)
	var wall_material := StandardMaterial3D.new()
	wall_material.albedo_color = Color("3A342E")
	wall_material.roughness = 0.96
	wall.material_override = wall_material
	add_child(wall)

	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(4.0, 4.0)
	floor.mesh = floor_mesh
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("17191B")
	floor_material.roughness = 0.98
	floor.material_override = floor_material
	add_child(floor)

	var key := OmniLight3D.new()
	key.position = Vector3(-1.15, 2.20, -2.20)
	key.light_color = Color("F3B66E")
	key.light_energy = 3.4
	key.omni_range = 5.0
	add_child(key)
	var rim := OmniLight3D.new()
	rim.position = Vector3(1.35, 1.45, -1.80)
	rim.light_color = Color("637E9C")
	rim.light_energy = 1.8
	rim.omni_range = 4.5
	add_child(rim)

	var camera := Camera3D.new()
	camera.fov = 46.0
	camera.position = Vector3(0.18, 1.30, -3.35)
	add_child(camera)
	camera.look_at(Vector3(0.0, 1.00, 0.0), Vector3.UP)


func _frames(count: int) -> void:
	for _frame in count:
		await get_tree().process_frame


func _capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var path := OUT + name + ".png"
	var result := image.save_png(ProjectSettings.globalize_path(path))
	print("  %s (%s)" % [path, "ok" if result == OK else "error %d" % result])
