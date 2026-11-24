extends Node3D

var curve := Curve3D.new()
var lights: Array[OmniLight3D] = []
var station_lights: Array[OmniLight3D] = []
var hazard_lights: Array[OmniLight3D] = []
var switches: Array[Node3D] = []
var switch_indicators: Array[MeshInstance3D] = []
var gate: StaticBody3D
var flood: MeshInstance3D
var restored_lighting := false
var warning_system := false
var warning_flash := 0.0

func build() -> void:
	curve.bake_interval = 0.25
	curve.add_point(Vector3(26, 0, -7))
	curve.add_point(Vector3(80, 0, -7))
	for i in range(1, 17):
		var angle := PI * 0.5 - PI * float(i) / 16.0
		curve.add_point(Vector3(80 + cos(angle) * 6, 0, -13 + sin(angle) * 6))
	curve.add_point(Vector3(26, 0, -19))
	for i in range(1, 17):
		var angle := -PI * 0.5 - PI * float(i) / 16.0
		curve.add_point(Vector3(26 + cos(angle) * 6, 0, -13 + sin(angle) * 6))
	var floor_mat := material(Color(0.20, 0.22, 0.21), 0.96)
	floor_mat.albedo_texture = load("res://assets/textures/station_floor_concrete.png")
	var wall_mat := material(Color(0.29, 0.31, 0.30), 0.96)
	wall_mat.albedo_texture = load("res://assets/textures/basement_wall_grit.png")
	wall_mat.uv1_triplanar = true
	wall_mat.uv1_scale = Vector3.ONE * .6
	var iron := material(Color(0.18, 0.21, 0.22), 0.55, 0.8)
	var rust := material(Color(0.28, 0.14, 0.07), 0.9, 0.3)
	var total := curve.get_baked_length()
	# Short modules follow the same sampled centerline as the cart, including bends.
	for index in int(ceil(total / 2.0)):
		var d := float(index) * 2.0
		var a := curve.sample_baked(d)
		var b := curve.sample_baked(minf(total, d + 2.0))
		var module := Node3D.new()
		add_child(module)
		module.position = (a + b) * 0.5
		module.look_at(b if b.distance_squared_to(module.position) > .001 else a + Vector3.RIGHT)
		var length := a.distance_to(b) + 0.12
		box(module, Vector3(0, -.14, 0), Vector3(4.4, .28, length), floor_mat, true)
		box(module, Vector3(0, 3.35, 0), Vector3(4.4, .22, length), wall_mat, true)
		var platform := a.z > -8 and ((a.x >= 21 and a.x <= 33) or (a.x >= 64 and a.x <= 76))
		box(module, Vector3(-2.15, 1.6, 0), Vector3(.2, 3.2, length), wall_mat, true)
		if not platform: box(module, Vector3(2.15, 1.6, 0), Vector3(.2, 3.2, length), wall_mat, true)
		for x in [-.71, .71]: box(module, Vector3(x, .07, 0), Vector3(.075, .13, length), iron)
		for z in [-.65, .2]: box(module, Vector3(0, .025, z), Vector3(1.95, .06, .18), rust)
		if index % 3 == 0:
			for x in [-1.94, 1.94]:
				if platform and x > 0: continue
				box(module, Vector3(x, 1.6, 0), Vector3(.13, 3.2, .17), iron)
			box(module, Vector3(0, 3.14, 0), Vector3(4.0, .16, .18), iron)
		if index % 7 == 0:
			var light := OmniLight3D.new()
			light.position = Vector3(-1.65, 2.7, 0)
			light.light_color = Color(.7, .78, .66) if index % 2 == 0 else Color(1, .58, .24)
			light.light_energy = .45
			light.omni_range = 8
			module.add_child(light)
			lights.append(light)
			box(module, Vector3(-1.65, 2.85, 0), Vector3(.32, .12, .55), rust)
		if index % 9 == 0:
			box(module, Vector3(-1.8, .35, .3), Vector3(.35, .7, .8), rust, true)
		if index % 6 == 3 and not platform:
			var portal: Node3D = load("res://assets/models/basement/generated/props/frozen_maintenance_portal.glb").instantiate()
			portal.scale.x = 1.06
			module.add_child(portal)
	# Platforms and short passages sit alongside the tracks, outside the cart lane.
	for x in [28.0, 70.0]:
		box(self, Vector3(x, -.10, -4.55), Vector3(10 if x == 28 else 12, .20, 1.3), floor_mat, true)
		box(self, Vector3(x, 3.3, -4.55), Vector3(10 if x == 28 else 12, .2, 1.3), wall_mat, true)
		for offset in range(-4, 5): box(self, Vector3(x + offset, .015, -5.1), Vector3(.48, .025, .17), material(Color(.68, .41, .12)))
		var platform_light := OmniLight3D.new()
		platform_light.position = Vector3(x, 2.7, -4.5)
		platform_light.light_color = Color(1, .70, .40)
		platform_light.light_energy = 1.7
		platform_light.omni_range = 9
		add_child(platform_light)
		station_lights.append(platform_light)
		var track_light := OmniLight3D.new()
		track_light.position = Vector3(x, 2.8, -7.7)
		track_light.light_color = Color(.62, .78, .80)
		track_light.light_energy = 1.5
		track_light.omni_range = 7
		add_child(track_light)
		add_sign("C-4 CORRIDOR" if x == 28 else "DEPOSIT EXCHANGE", Vector3(x, 2.75, -4.05), PI, 34)
	# Corridor access: dog-leg walkway clear of the cold-store entrance at x16.
	box(self, Vector3(24, -.12, -4.5), Vector3(6, .24, 1.6), floor_mat, true)
	box(self, Vector3(22, -.12, -3.95), Vector3(2, .24, 2), floor_mat, true)
	box(self, Vector3(21, 1.5, -4.5), Vector3(.12, 3, 1.2), wall_mat, true)
	var entry_light := OmniLight3D.new()
	entry_light.position = Vector3(22.5, 2.6, -4.5)
	entry_light.light_color = Color(.55, .72, .75)
	entry_light.light_energy = .8
	entry_light.omni_range = 4
	add_child(entry_light)
	box(self, Vector3(28, 1.5, -3.9), Vector3(10, 3, .15), wall_mat, true)
	box(self, Vector3(33, 1.5, -4.5), Vector3(.15, 3, 1.3), wall_mat, true)
	for x in [66.5, 73.5]: box(self, Vector3(x, 1.5, -3.9), Vector3(5, 3, .15), wall_mat, true)
	for x in [64, 76]: box(self, Vector3(x, 1.5, -4.5), Vector3(.15, 3, 1.3), wall_mat, true)
	box(self, Vector3(70, -.12, -2.55), Vector3(2, .24, 3), floor_mat, true)
	box(self, Vector3(70, 3.3, -2.55), Vector3(2, .2, 3), wall_mat, true)
	for x in [69.0, 71.0]: box(self, Vector3(x, 1.6, -2.55), Vector3(.12, 3.2, 3), wall_mat, true)
	gate = box(self, Vector3(70, 1.4, -1.05), Vector3(1.9, 2.8, .12), iron, true) as StaticBody3D
	gate.name = "RailArrivalGate"
	add_sign("RAIL ARRIVALS ONLY", Vector3(70, 2.55, -.94), 0, 24)
	var water := material(Color(.08, .22, .25, .72), .18, .45)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flood = box(self, Vector3(54, .10, -7), Vector3(10, .05, 3.8), water) as MeshInstance3D
	flood.name = "PersistentRailFlood"
	add_sign("FLOOD  /  COAST", Vector3(47, 2.2, -8.8), -PI * .5, 27)
	add_sign("UNSTABLE ROOF", Vector3(37, 2.2, -8.8), -PI * .5, 27)
	for x in [35, 47]:
		var beacon := OmniLight3D.new()
		beacon.position = Vector3(x, 2.5, -8.7)
		beacon.light_color = Color(1, .33, .055)
		beacon.omni_range = 5
		beacon.light_energy = 0
		add_child(beacon)
		hazard_lights.append(beacon)
		box(self, beacon.position, Vector3(.18, .28, .18), material(Color(.54, .24, .07)))
	# Bent shoring and fallen material leave the running rails legible.
	for index in 6:
		var rubble := box(self, Vector3(40 + index*.42, .25, -8.5), Vector3(.55, .5, .65), wall_mat)
		rubble.rotation = Vector3(.13*index, .31*index, .17)
	for x in [38, 54, 68]:
		box(self, Vector3(x, .5, -20.6), Vector3(1.4, 1, .55), iron)
		add_sign("SERVICE / DISUSED", Vector3(x, 2.1, -20.75), 0, 20)

func refresh(state: Dictionary) -> void:
	gate.position.y = 5.0 if state.first_ride_completed else 1.4
	restored_lighting = state.safety_switches[0]
	warning_system = state.safety_switches[1]
	station_lights[1].light_energy = 2.5 if state.station_restored else .75
	for i in lights.size():
		lights[i].light_energy = 1.15 if state.safety_switches[0] else .40
	for i in switches.size():
		switches[i].rotation.z = -.6 if state.safety_switches[i] else .35
	for i in switch_indicators.size():
		var mat := switch_indicators[i].material_override as StandardMaterial3D
		mat.albedo_color = Color(.20, .9, .55) if state.safety_switches[i] else Color(.65, .12, .05)
		mat.emission = mat.albedo_color
		mat.emission_enabled = true
	for light in hazard_lights: light.light_energy = 1.8 if warning_system else 0

func flicker_warning() -> void:
	warning_flash = .75

func _process(delta: float) -> void:
	if warning_flash <= 0: return
	warning_flash = maxf(0, warning_flash - delta)
	for light in lights:
		light.light_energy = (1.15 if restored_lighting else .4) * (.15 if sin(warning_flash * 70) > 0 else 1.0)
	if warning_flash == 0:
		for light in lights: light.light_energy = 1.15 if restored_lighting else .4

func falling_concrete(point: Vector3) -> void:
	# Visual fragments cannot accumulate collision on the running rails.
	for i in 8:
		var chunk := box(self, point + Vector3((i % 3 - 1) * .5, 3.0, (i % 2 - .5) * .9), Vector3(.13, .18, .16), material(Color(.37, .38, .34)))
		var tween := create_tween()
		tween.tween_property(chunk, "position:y", .18, .28 + i * .025).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_interval(.4)
		tween.tween_property(chunk, "scale", Vector3.ONE * .01, .5)
		tween.tween_callback(chunk.queue_free)

func water_splash(point: Vector3) -> void:
	for i in 7:
		var drop := box(self, point + Vector3(.9, .2, (i-3)*.12), Vector3(.035, .09, .035), material(Color(.25, .48, .49), .12))
		var tween := create_tween()
		tween.tween_property(drop, "position:y", .65 + (i%3)*.1, .15)
		tween.tween_property(drop, "position:y", .11, .25)
		tween.tween_callback(drop.queue_free)

static func material(color: Color, roughness: float = .85, metal: float = .0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = roughness
	mat.metallic = metal
	return mat

static func box(parent: Node3D, offset: Vector3, size_value: Vector3, mat: Material, solid: bool = false) -> Node3D:
	var mesh := MeshInstance3D.new()
	var shape := BoxMesh.new()
	shape.size = size_value
	mesh.mesh = shape
	mesh.material_override = mat
	if not solid:
		parent.add_child(mesh)
		mesh.position = offset
		return mesh
	var body := StaticBody3D.new()
	parent.add_child(body)
	body.position = offset
	body.add_child(mesh)
	var collider := CollisionShape3D.new()
	var bounds := BoxShape3D.new()
	bounds.size = size_value
	collider.shape = bounds
	body.add_child(collider)
	return body

func add_sign(text_value: String, point: Vector3, yaw: float, font_size: int = 30) -> void:
	var label := Label3D.new()
	label.text = text_value
	label.position = point
	label.rotation.y = yaw
	label.font_size = font_size
	label.pixel_size = .004
	label.double_sided = false
	label.modulate = Color(.95, .72, .36)
	add_child(label)
	var lines := text_value.split("\n")
	var widest := 0
	for line in lines: widest = maxi(widest, line.length())
	var board := box(self, point + Vector3(0, 0, -.025).rotated(Vector3.UP, yaw), Vector3(widest * font_size * .0024 + .12, lines.size() * font_size * .005 + .08, .035), material(Color(.055, .08, .08), .95, .35))
	board.rotation.y = yaw
