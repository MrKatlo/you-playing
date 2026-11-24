extends Node

## Headless import test for Basement-owned static base props.
## Run with:
##   Godot --headless --path . res://tools/test_basement_workbench_asset.tscn

const WORKBENCH_SCENE: PackedScene = preload("res://assets/models/basement/generated/props/salvaged_workbench.glb")
const INSULATION_PATCH_SCENE: PackedScene = preload("res://assets/models/basement/generated/props/wall_insulation_patch.glb")
const HUNT_SNARE_SCENE: PackedScene = preload("res://assets/models/basement/generated/props/hunt_snare.glb")
const WARM_STORAGE_RACK_SCENE: PackedScene = preload("res://assets/models/basement/generated/props/warm_storage_rack.glb")
const FURNACE_HEAT_RECLAIMER_SCENE: PackedScene = preload("res://assets/models/basement/generated/props/furnace_heat_reclaimer.glb")
const CAVE_TRADE_DROP_SCENE: PackedScene = preload("res://assets/models/basement/generated/props/cave_trade_drop.glb")
const NEST_BREACH_SCENE: PackedScene = preload("res://assets/models/basement/generated/props/nest_breach.glb")
const KITCHEN_BENCH_SCENE: PackedScene = preload("res://assets/models/basement/generated/props/kitchen_bench.glb")

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
	var workbench: Node3D = WORKBENCH_SCENE.instantiate() as Node3D
	_check(workbench != null, "generated workbench GLB instantiates")
	if workbench == null:
		_finish()
		return
	add_child(workbench)
	var meshes: Array[MeshInstance3D] = _find_meshes(workbench)
	_check(not meshes.is_empty(), "generated workbench contains mesh geometry")
	var total_surfaces := 0
	var material_surfaces := 0
	for mesh_node in meshes:
		if mesh_node.mesh == null:
			continue
		var surface_count: int = mesh_node.mesh.get_surface_count()
		total_surfaces += surface_count
		for surface in surface_count:
			if mesh_node.get_active_material(surface) != null:
				material_surfaces += 1
	_check(total_surfaces >= 6, "workbench keeps separate authored material surfaces", "found %d" % total_surfaces)
	_check(material_surfaces >= 6, "workbench imports its generated PBR materials", "found %d" % material_surfaces)
	_check(_find_skeleton(workbench) == null, "workbench remains static rather than carrying an unused creature rig")
	workbench.queue_free()
	var insulation_patch: Node3D = INSULATION_PATCH_SCENE.instantiate() as Node3D
	_check(insulation_patch != null, "generated insulation patch GLB instantiates")
	if insulation_patch != null:
		add_child(insulation_patch)
		var patch_meshes: Array[MeshInstance3D] = _find_meshes(insulation_patch)
		_check(not patch_meshes.is_empty(), "generated insulation patch contains mesh geometry")
		var patch_surfaces := 0
		var patch_material_surfaces := 0
		for mesh_node in patch_meshes:
			if mesh_node.mesh == null:
				continue
			var surface_count: int = mesh_node.mesh.get_surface_count()
			patch_surfaces += surface_count
			for surface in surface_count:
				if mesh_node.get_active_material(surface) != null:
					patch_material_surfaces += 1
		_check(patch_surfaces >= 5, "insulation patch keeps layered material surfaces", "found %d" % patch_surfaces)
		_check(patch_material_surfaces >= 5, "insulation patch imports its generated PBR materials", "found %d" % patch_material_surfaces)
		_check(_find_skeleton(insulation_patch) == null, "insulation patch remains a static wall upgrade")
		insulation_patch.queue_free()
	var hunt_snare: Node3D = HUNT_SNARE_SCENE.instantiate() as Node3D
	_check(hunt_snare != null, "generated hunt snare GLB instantiates")
	if hunt_snare != null:
		add_child(hunt_snare)
		var snare_meshes: Array[MeshInstance3D] = _find_meshes(hunt_snare)
		_check(not snare_meshes.is_empty(), "generated hunt snare contains mesh geometry")
		var snare_surfaces := 0
		var snare_material_surfaces := 0
		for mesh_node in snare_meshes:
			if mesh_node.mesh == null:
				continue
			var surface_count: int = mesh_node.mesh.get_surface_count()
			snare_surfaces += surface_count
			for surface in surface_count:
				if mesh_node.get_active_material(surface) != null:
					snare_material_surfaces += 1
		_check(snare_surfaces >= 4, "hunt snare keeps wire, bait, anchor, and spool surfaces", "found %d" % snare_surfaces)
		_check(snare_material_surfaces >= 4, "hunt snare imports its generated PBR materials", "found %d" % snare_material_surfaces)
		_check(_find_skeleton(hunt_snare) == null, "hunt snare remains a static tactical prop")
		hunt_snare.queue_free()
	var storage_rack: Node3D = WARM_STORAGE_RACK_SCENE.instantiate() as Node3D
	_check(storage_rack != null, "generated warm storage rack GLB instantiates")
	if storage_rack != null:
		add_child(storage_rack)
		var rack_meshes: Array[MeshInstance3D] = _find_meshes(storage_rack)
		_check(not rack_meshes.is_empty(), "generated warm storage rack contains mesh geometry")
		var rack_surfaces := 0
		var rack_material_surfaces := 0
		for mesh_node in rack_meshes:
			if mesh_node.mesh == null:
				continue
			var surface_count: int = mesh_node.mesh.get_surface_count()
			rack_surfaces += surface_count
			for surface in surface_count:
				if mesh_node.get_active_material(surface) != null:
					rack_material_surfaces += 1
		_check(rack_surfaces >= 6, "warm storage rack keeps shelf, supplies, frame, and lamp surfaces", "found %d" % rack_surfaces)
		_check(rack_material_surfaces >= 6, "warm storage rack imports its generated PBR materials", "found %d" % rack_material_surfaces)
		_check(_find_skeleton(storage_rack) == null, "warm storage rack remains a static base upgrade")
		storage_rack.queue_free()
	var heat_reclaimer: Node3D = FURNACE_HEAT_RECLAIMER_SCENE.instantiate() as Node3D
	_check(heat_reclaimer != null, "generated furnace heat reclaimer GLB instantiates")
	if heat_reclaimer != null:
		add_child(heat_reclaimer)
		var reclaimer_meshes: Array[MeshInstance3D] = _find_meshes(heat_reclaimer)
		_check(not reclaimer_meshes.is_empty(), "heat reclaimer contains mesh geometry")
		var reclaimer_surfaces := 0
		var reclaimer_material_surfaces := 0
		for mesh_node in reclaimer_meshes:
			if mesh_node.mesh == null:
				continue
			var surface_count: int = mesh_node.mesh.get_surface_count()
			reclaimer_surfaces += surface_count
			for surface in surface_count:
				if mesh_node.get_active_material(surface) != null:
					reclaimer_material_surfaces += 1
		_check(reclaimer_surfaces >= 5, "heat reclaimer keeps exchanger, pipes, valves, and gauge surfaces", "found %d" % reclaimer_surfaces)
		_check(reclaimer_material_surfaces >= 5, "heat reclaimer imports its generated PBR materials", "found %d" % reclaimer_material_surfaces)
		_check(_find_skeleton(heat_reclaimer) == null, "heat reclaimer remains a static expedition upgrade")
		heat_reclaimer.queue_free()
	var kitchen: Node3D = KITCHEN_BENCH_SCENE.instantiate() as Node3D
	_check(kitchen != null, "generated kitchen bench GLB instantiates")
	if kitchen != null:
		add_child(kitchen)
		var kitchen_meshes: Array[MeshInstance3D] = _find_meshes(kitchen)
		_check(not kitchen_meshes.is_empty(), "kitchen bench contains mesh geometry")
		var kitchen_surfaces := 0
		var kitchen_material_surfaces := 0
		for mesh_node in kitchen_meshes:
			if mesh_node.mesh == null:
				continue
			var surface_count: int = mesh_node.mesh.get_surface_count()
			kitchen_surfaces += surface_count
			for surface in surface_count:
				if mesh_node.get_active_material(surface) != null:
					kitchen_material_surfaces += 1
		_check(kitchen_surfaces >= 10, "kitchen bench keeps its dressing, cooking and curing surfaces", "found %d" % kitchen_surfaces)
		_check(kitchen_material_surfaces >= 10, "kitchen bench imports its aged PBR materials", "found %d" % kitchen_material_surfaces)
		# The wear pass is part of the asset contract: greyed grain, splinters, water
		# rings, soot, chalk and enamel each own a material surface of their own,
		# so the aging survives the export instead of flattening into one tone.
		var aged_surfaces := 0
		var palette := {}
		for mesh_node in kitchen_meshes:
			if mesh_node.mesh == null:
				continue
			for surface in mesh_node.mesh.get_surface_count():
				var material := mesh_node.get_active_material(surface) as StandardMaterial3D
				if material == null:
					continue
				var key := material.albedo_color.to_html(false)
				if palette.has(key):
					continue
				palette[key] = true
				if key in ["5a5044", "8a5b33", "2b1c12", "141210", "b9b3a2", "7c7e6e"]:
					aged_surfaces += 1
		_check(aged_surfaces >= 6, "kitchen bench ships its wear palette, not one clean tone", "found %d of 6" % aged_surfaces)
		_check(_find_skeleton(kitchen) == null, "kitchen bench remains a static station")
		kitchen.queue_free()
	# M4 cave props: both are static fixtures hung in the pocket, so they get the
	# same instantiate / surfaces / static contract as the base props.
	for entry in [
		{"scene": CAVE_TRADE_DROP_SCENE, "name": "cave trade drop", "role": "static drop fixture", "surfaces": 4},
		{"scene": NEST_BREACH_SCENE, "name": "nest breach", "role": "static cave scar", "surfaces": 4},
	]:
		var prop: Node3D = (entry["scene"] as PackedScene).instantiate() as Node3D
		_check(prop != null, "generated %s GLB instantiates" % entry["name"])
		if prop == null:
			continue
		add_child(prop)
		var prop_meshes: Array[MeshInstance3D] = _find_meshes(prop)
		_check(not prop_meshes.is_empty(), "generated %s contains mesh geometry" % entry["name"])
		var prop_surfaces := 0
		var prop_material_surfaces := 0
		for mesh_node in prop_meshes:
			if mesh_node.mesh == null:
				continue
			var surface_count: int = mesh_node.mesh.get_surface_count()
			prop_surfaces += surface_count
			for surface in surface_count:
				if mesh_node.get_active_material(surface) != null:
					prop_material_surfaces += 1
		_check(prop_surfaces >= int(entry["surfaces"]),
			"%s keeps its authored surfaces" % entry["name"], "found %d" % prop_surfaces)
		_check(prop_material_surfaces >= int(entry["surfaces"]),
			"%s imports its generated PBR materials" % entry["name"], "found %d" % prop_material_surfaces)
		_check(_find_skeleton(prop) == null, "%s remains a %s" % [entry["name"], entry["role"]])
		prop.queue_free()
	_finish()


func _find_meshes(node: Node) -> Array[MeshInstance3D]:
	var result: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		result.append(node as MeshInstance3D)
	for child in node.get_children():
		result.append_array(_find_meshes(child))
	return result


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found != null:
			return found
	return null


func _finish() -> void:
	print("BASEMENT PROP ASSET RESULT: %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures > 0 else 0)
